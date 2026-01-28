import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/match_model.dart';

class MatchRepository {
  final FirebaseService _firebaseService;

  MatchRepository(this._firebaseService);

  // Get user's matches
  Stream<List<MatchModel>> getUserMatches(String userId) {
    return _firebaseService.matchesCollection
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MatchModel.fromFirestore(doc)).toList());
  }

  // Get single match
  Stream<MatchModel?> getMatchById(String matchId) {
    return _firebaseService.matchesCollection
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchModel.fromFirestore(doc) : null);
  }

  // Create match
  Future<String> createMatch(MatchModel match) async {
    throw UnsupportedError(
      'Matches are created by backend matching logic; client-side creation is disabled.',
    );
  }

  // Update match status
  Future<void> updateMatchStatus(String matchId, MatchStatus status) async {
    final updateData = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == MatchStatus.confirmed) {
      updateData['confirmedAt'] = FieldValue.serverTimestamp();
    } else if (status == MatchStatus.completed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firebaseService.matchesCollection.doc(matchId).update(updateData);
  }

  // Accept match (by traveler)
  Future<void> acceptMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.accepted);
  }

  // Reject match
  Future<void> rejectMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.rejected);
  }

  // Confirm match (final confirmation by both parties)
  Future<void> confirmMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.confirmed);
  }

  // Update delivery status
  Future<void> markAsPickedUp(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.pickedUp);
  }

  Future<void> markAsInTransit(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.inTransit);
  }

  Future<void> markAsDelivered(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.delivered);
  }

  Future<void> completeMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.completed);
  }

  // Cancel match
  Future<void> cancelMatch(String matchId) async {
    await updateMatchStatus(matchId, MatchStatus.cancelled);
  }

  // Update agreed price
  Future<void> updateAgreedPrice(String matchId, double price) async {
    await _firebaseService.matchesCollection.doc(matchId).update({
      'agreedPrice': price,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
