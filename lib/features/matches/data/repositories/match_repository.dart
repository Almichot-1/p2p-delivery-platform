import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/firebase_service.dart';
import '../models/match_model.dart';

class MatchRepository {
  MatchRepository(this._firebaseService);

  final FirebaseService _firebaseService;

  Stream<List<MatchModel>> getUserMatches(String userId) {
    final id = userId.trim();
    if (id.isEmpty) {
      debugPrint('###MATCH_DEBUG### getUserMatches: userId is empty');
      return const Stream<List<MatchModel>>.empty();
    }

    debugPrint('###MATCH_DEBUG### getUserMatches: querying for userId=$id');
    final q = _firebaseService.matches.where('participants', arrayContains: id);

    return q.snapshots().map((snap) {
      debugPrint('###MATCH_DEBUG### getUserMatches: received ${snap.docs.length} matches');
      final matches =
          snap.docs.map(MatchModel.fromFirestore).toList(growable: true);
      matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      for (final m in matches) {
        debugPrint('###MATCH_DEBUG### Match: id=${m.id}, status=${m.status.name}, participants=${m.participants}');
      }
      return matches;
    });
  }

  Stream<MatchModel?> getMatchById(String matchId) {
    final id = matchId.trim();
    if (id.isEmpty) return const Stream<MatchModel?>.empty();

    return _firebaseService.matches.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MatchModel.fromFirestore(doc);
    });
  }

  Future<bool> matchExists(String tripId, String requestId) async {
    final t = tripId.trim();
    final r = requestId.trim();
    if (t.isEmpty || r.isEmpty) return false;

    final snap = await _firebaseService.matches
        .where('tripId', isEqualTo: t)
        .where('requestId', isEqualTo: r)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<String> createMatch({
    required String tripId,
    required String requestId,
    required String travelerId,
    required String travelerName,
    required String? travelerPhoto,
    required String requesterId,
    required String requesterName,
    required String? requesterPhoto,
    required String itemTitle,
    required String route,
    required DateTime tripDate,
  }) async {
    final tId = tripId.trim();
    final rId = requestId.trim();
    final travelerUid = travelerId.trim();
    final requesterUid = requesterId.trim();

    if (tId.isEmpty) throw Exception('Trip id is missing');
    if (rId.isEmpty) throw Exception('Request id is missing');
    if (travelerUid.isEmpty) throw Exception('Traveler id is missing');
    if (requesterUid.isEmpty) throw Exception('Requester id is missing');
    if (travelerUid == requesterUid) {
      throw Exception('Traveler and requester cannot be the same user');
    }
    if (itemTitle.trim().isEmpty) throw Exception('Item title is missing');
    if (route.trim().isEmpty) throw Exception('Route is missing');

    // Deterministic id for (tripId, requestId) to guarantee idempotency.
    final matchDocId = '${tId}__${rId}';
    final matchRef = _firebaseService.matches.doc(matchDocId);
    final requestRef = _firebaseService.requests.doc(rId);
    final tripRef = _firebaseService.trips.doc(tId);

    await _firebaseService.firestore.runTransaction((tx) async {
      final existing = await tx.get(matchRef);
      if (existing.exists) {
        throw Exception('A match already exists for this trip and request');
      }

      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) throw Exception('Request not found');

      final requestData = requestSnap.data() ?? <String, dynamic>{};
      final requestStatus = requestData['status']?.toString() ?? '';
      if (requestStatus != 'active') {
        throw Exception('Request already matched or unavailable');
      }

      final tripSnap = await tx.get(tripRef);
      if (!tripSnap.exists) throw Exception('Trip not found');
      final tripData = tripSnap.data() ?? <String, dynamic>{};
      final tripStatus = tripData['status']?.toString() ?? '';
      if (tripStatus != 'active') {
        throw Exception('Trip is not available');
      }

      final requestWeight = (requestData['weightKg'] as num?)?.toDouble() ?? 0.0;
      final tripCapacity =
          (tripData['availableCapacityKg'] as num?)?.toDouble() ?? 0.0;
      if (requestWeight > 0 && tripCapacity > 0 && requestWeight > tripCapacity) {
        throw Exception('Trip capacity is insufficient for this request');
      }

      // Validate trip date is not in the past using Firestore data.
      final dep = tripData['departureDate'];
      if (dep is Timestamp) {
        if (!dep.toDate().isAfter(DateTime.now())) {
          throw Exception('Trip date already passed');
        }
      } else {
        // Fallback to passed tripDate parameter if Firestore field missing
        if (!tripDate.isAfter(DateTime.now())) {
          throw Exception('Trip date already passed');
        }
      }

      final data = <String, dynamic>{
        'id': matchDocId,
        'tripId': tId,
        'requestId': rId,
        'travelerId': travelerUid,
        'travelerName': travelerName,
        'travelerPhoto': travelerPhoto,
        'requesterId': requesterUid,
        'requesterName': requesterName,
        'requesterPhoto': requesterPhoto,
        'itemTitle': itemTitle,
        'route': route,
        'tripDate': Timestamp.fromDate(tripDate),
        'status': MatchStatus.pending.name,
        'participants': <String>[travelerUid, requesterUid],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }..removeWhere((_, v) => v == null);

      debugPrint('###MATCH_DEBUG### createMatch: Creating match with id=$matchDocId');
      debugPrint('###MATCH_DEBUG### createMatch: travelerId=$travelerUid, requesterId=$requesterUid');
      debugPrint('###MATCH_DEBUG### createMatch: participants=[${travelerUid}, ${requesterUid}]');

      tx.set(matchRef, data, SetOptions(merge: true));

      tx.set(
        requestRef,
        <String, dynamic>{
          'status': 'matched',
          'matchedTripId': tId,
          'matchedTravelerId': travelerUid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Deduct request weight from trip capacity
      if (requestWeight > 0) {
        tx.set(
          tripRef,
          <String, dynamic>{
            'availableCapacityKg': tripCapacity - requestWeight,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    return matchDocId;
  }

  Future<void> updateMatchStatus(String matchId, MatchStatus status) async {
    switch (status) {
      case MatchStatus.accepted:
        return acceptMatch(matchId);
      case MatchStatus.rejected:
        return rejectMatch(matchId);
      case MatchStatus.confirmed:
        return confirmMatch(matchId);
      case MatchStatus.pickedUp:
        return markAsPickedUp(matchId);
      case MatchStatus.inTransit:
        return markAsInTransit(matchId);
      case MatchStatus.delivered:
        return markAsDelivered(matchId);
      case MatchStatus.completed:
        return completeMatch(matchId);
      case MatchStatus.cancelled:
        return cancelMatch(matchId);
      case MatchStatus.pending:
        throw Exception('Cannot set match back to pending');
    }
  }

  Future<void> acceptMatch(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (userId != match.travelerId) {
      throw Exception('Only the traveler can accept a match');
    }

    _validateTransition(match.status, MatchStatus.accepted);

    await _update(
        matchId, <String, dynamic>{'status': MatchStatus.accepted.name});
  }

  Future<void> rejectMatch(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (userId != match.travelerId) {
      throw Exception('Only the traveler can reject a match');
    }

    _validateTransition(match.status, MatchStatus.rejected);

    final matchRef = _firebaseService.matches.doc(matchId);
    final requestRef = _firebaseService.requests.doc(match.requestId);
    final tripRef = _firebaseService.trips.doc(match.tripId);

    await _firebaseService.firestore.runTransaction((tx) async {
      // Get request to restore capacity
      final requestSnap = await tx.get(requestRef);
      final requestData = requestSnap.data() ?? <String, dynamic>{};
      final requestWeight = (requestData['weightKg'] as num?)?.toDouble() ?? 0.0;

      // Get trip to restore capacity
      final tripSnap = await tx.get(tripRef);
      final tripData = tripSnap.data() ?? <String, dynamic>{};
      final currentCapacity =
          (tripData['availableCapacityKg'] as num?)?.toDouble() ?? 0.0;

      // Update match status to rejected
      tx.set(
        matchRef,
        <String, dynamic>{
          'status': MatchStatus.rejected.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Revert request status to active
      tx.set(
        requestRef,
        <String, dynamic>{
          'status': 'active',
          'matchedTripId': FieldValue.delete(),
          'matchedTravelerId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Restore trip capacity
      if (requestWeight > 0) {
        tx.set(
          tripRef,
          <String, dynamic>{
            'availableCapacityKg': currentCapacity + requestWeight,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> confirmMatch(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (!match.isParticipant(userId)) throw Exception('Not a participant');

    _validateTransition(match.status, MatchStatus.confirmed);

    final update = <String, dynamic>{
      'status': MatchStatus.confirmed.name,
    };

    // confirmedAt set only once.
    if (match.confirmedAt == null) {
      update['confirmedAt'] = FieldValue.serverTimestamp();
    }

    await _update(matchId, update);
  }

  Future<void> markAsPickedUp(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (userId != match.travelerId) {
      throw Exception('Only the traveler can mark as picked up');
    }

    _validateTransition(match.status, MatchStatus.pickedUp);

    await _update(
        matchId, <String, dynamic>{'status': MatchStatus.pickedUp.name});
  }

  Future<void> markAsInTransit(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (userId != match.travelerId) {
      throw Exception('Only the traveler can mark as in transit');
    }

    _validateTransition(match.status, MatchStatus.inTransit);

    await _update(
        matchId, <String, dynamic>{'status': MatchStatus.inTransit.name});
  }

  Future<void> markAsDelivered(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (userId != match.travelerId) {
      throw Exception('Only the traveler can mark as delivered');
    }

    _validateTransition(match.status, MatchStatus.delivered);

    await _update(
        matchId, <String, dynamic>{'status': MatchStatus.delivered.name});
  }

  Future<void> completeMatch(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (!match.isParticipant(userId)) throw Exception('Not a participant');

    _validateTransition(match.status, MatchStatus.completed);

    final update = <String, dynamic>{
      'status': MatchStatus.completed.name,
    };

    // completedAt set only once.
    if (match.completedAt == null) {
      update['completedAt'] = FieldValue.serverTimestamp();
    }

    await _update(matchId, update);
  }

  Future<void> cancelMatch(String matchId) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (!match.isParticipant(userId)) throw Exception('Not a participant');

    _validateTransition(match.status, MatchStatus.cancelled);

    final matchRef = _firebaseService.matches.doc(matchId);
    final requestRef = _firebaseService.requests.doc(match.requestId);
    final tripRef = _firebaseService.trips.doc(match.tripId);

    await _firebaseService.firestore.runTransaction((tx) async {
      // Get request to restore capacity
      final requestSnap = await tx.get(requestRef);
      final requestData = requestSnap.data() ?? <String, dynamic>{};
      final requestWeight = (requestData['weightKg'] as num?)?.toDouble() ?? 0.0;

      // Get trip to restore capacity
      final tripSnap = await tx.get(tripRef);
      final tripData = tripSnap.data() ?? <String, dynamic>{};
      final currentCapacity =
          (tripData['availableCapacityKg'] as num?)?.toDouble() ?? 0.0;

      // Update match status to cancelled
      tx.set(
        matchRef,
        <String, dynamic>{
          'status': MatchStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Revert request status to active
      tx.set(
        requestRef,
        <String, dynamic>{
          'status': 'active',
          'matchedTripId': FieldValue.delete(),
          'matchedTravelerId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Restore trip capacity
      if (requestWeight > 0) {
        tx.set(
          tripRef,
          <String, dynamic>{
            'availableCapacityKg': currentCapacity + requestWeight,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> updateAgreedPrice(String matchId, double price) async {
    final match = await _getMatchOrThrow(matchId);
    final userId = _currentUserIdOrThrow();

    if (!match.isParticipant(userId)) throw Exception('Not a participant');

    if (price.isNaN || price < 0) throw Exception('Price cannot be negative');
    if (price > 100000) throw Exception('Price exceeds maximum allowed');
    if (price == 0) throw Exception('Please enter a valid price');

    // Editable before confirmed.
    if (match.status != MatchStatus.pending &&
        match.status != MatchStatus.accepted) {
      throw Exception('Agreed price can only be edited before confirmation');
    }

    await _update(matchId, <String, dynamic>{
      'agreedPrice': price,
    });
  }

  String _currentUserIdOrThrow() {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('You must be logged in');
    return user.uid;
  }

  Future<MatchModel> _getMatchOrThrow(String matchId) async {
    final id = matchId.trim();
    if (id.isEmpty) throw Exception('Match id is missing');

    final doc = await _firebaseService.matches.doc(id).get();
    if (!doc.exists) throw Exception('Match not found');
    return MatchModel.fromFirestore(doc);
  }

  Future<void> _update(String matchId, Map<String, dynamic> data) async {
    final id = matchId.trim();
    if (id.isEmpty) throw Exception('Match id is missing');

    await _firebaseService.matches.doc(id).set(
      <String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _validateTransition(MatchStatus from, MatchStatus to) {
    if (from == to) return;

    // Terminal states.
    if (from == MatchStatus.rejected ||
        from == MatchStatus.cancelled ||
        from == MatchStatus.completed) {
      throw Exception('This match can no longer be updated');
    }

    // Cancellation is allowed up to delivered.
    if (to == MatchStatus.cancelled) {
      if (from == MatchStatus.delivered) {
        throw Exception('Cannot cancel after delivery');
      }
      return;
    }

    // Allowed linear flow.
    final allowedNext = switch (from) {
      MatchStatus.pending => <MatchStatus>{
          MatchStatus.accepted,
          MatchStatus.rejected
        },
      MatchStatus.accepted => <MatchStatus>{MatchStatus.confirmed},
      MatchStatus.confirmed => <MatchStatus>{MatchStatus.pickedUp},
      MatchStatus.pickedUp => <MatchStatus>{MatchStatus.inTransit},
      MatchStatus.inTransit => <MatchStatus>{MatchStatus.delivered},
      MatchStatus.delivered => <MatchStatus>{MatchStatus.completed},
      _ => <MatchStatus>{},
    };

    if (!allowedNext.contains(to)) {
      throw Exception('Illegal status transition: ${from.name} → ${to.name}');
    }
  }
}
