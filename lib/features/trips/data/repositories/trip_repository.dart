import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firebase_service.dart';
import '../models/trip_model.dart';

class TripRepository {
  TripRepository(this._firebaseService);

  final FirebaseService _firebaseService;

  int _compareDepartureAsc(TripModel a, TripModel b) => a.departureDate.compareTo(b.departureDate);

  int _compareDepartureDesc(TripModel a, TripModel b) => b.departureDate.compareTo(a.departureDate);

  Stream<List<TripModel>> getActiveTrips({
    String? destination,
    DateTime? afterDate,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q = _firebaseService.trips.where(
      'status',
      isEqualTo: TripStatus.active.name,
    );

    final normalizedDest = destination?.trim().toLowerCase();

    return q.snapshots().map((snap) {
      Iterable<TripModel> trips = snap.docs.map(TripModel.fromFirestore);

      if (normalizedDest != null && normalizedDest.isNotEmpty) {
        // Match against both country and city (case-insensitive)
        trips = trips.where(
          (t) => t.destinationCountry.toLowerCase() == normalizedDest || 
                 t.destinationCity.toLowerCase() == normalizedDest,
        );
      }

      if (afterDate != null) {
        trips = trips.where((t) => !t.departureDate.isBefore(afterDate));
      }

      final sorted = trips.toList(growable: true)..sort(_compareDepartureAsc);
      if (sorted.length <= limit) return sorted;
      return sorted.take(limit).toList(growable: false);
    });
  }

  Stream<List<TripModel>> getTripsByTraveler(String travelerId) {
    final q = _firebaseService.trips.where('travelerId', isEqualTo: travelerId);

    return q.snapshots().map((snap) {
      final trips = snap.docs.map(TripModel.fromFirestore).toList(growable: false);
      final sorted = trips.toList(growable: true)..sort(_compareDepartureDesc);
      return sorted;
    });
  }

  Stream<TripModel?> getTripById(String tripId) {
    return _firebaseService.trips.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TripModel.fromFirestore(doc);
    });
  }

  Future<String> createTrip(TripModel trip) async {
    // Validate capacity
    if (trip.availableCapacityKg <= 0) {
      throw Exception('Available capacity must be greater than 0');
    }
    if (trip.availableCapacityKg > 100) {
      throw Exception('Available capacity cannot exceed 100 kg');
    }

    final doc = _firebaseService.trips.doc();

    final data = trip
        .copyWith(
          id: doc.id,
          status: TripStatus.active,
          matchCount: trip.matchCount,
        )
        .toFirestore();

    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await doc.set(data, SetOptions(merge: true));
    return doc.id;
  }

  Future<void> updateTrip(TripModel trip) async {
    final doc = _firebaseService.trips.doc(trip.id);

    final data = trip.toFirestore()
      ..remove('createdAt')
      ..remove('updatedAt');

    data['updatedAt'] = FieldValue.serverTimestamp();

    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> cancelTrip(String tripId) async {
    await _firebaseService.trips.doc(tripId).set(
      <String, dynamic>{
        'status': TripStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<TripModel>> searchTrips({
    String? destination,
    DateTime? departureDate,
    double? minCapacity,
    int limit = 50,
  }) async {
    /// Non-streaming search used for one-off queries.
    ///
    /// MVP note: We intentionally avoid composite-index requirements by doing
    /// additional filtering/sorting client-side. For production-scale search,
    /// switch back to indexed Firestore queries or move search to a backend.
    final q = _firebaseService.trips.where('status', isEqualTo: TripStatus.active.name);

    final snap = await q.get();
    Iterable<TripModel> trips = snap.docs.map(TripModel.fromFirestore);

    final normalizedDest = destination?.trim().toLowerCase();
    if (normalizedDest != null && normalizedDest.isNotEmpty) {
      trips = trips.where(
        (t) => t.destinationCountry.toLowerCase() == normalizedDest || 
               t.destinationCity.toLowerCase() == normalizedDest,
      );
    }

    if (departureDate != null) {
      trips = trips.where((t) => !t.departureDate.isBefore(departureDate));
    }

    if (minCapacity != null) {
      trips = trips.where((t) => t.availableCapacityKg >= minCapacity);
    }

    final sorted = trips.toList(growable: true)..sort(_compareDepartureAsc);
    if (sorted.length <= limit) return sorted;
    return sorted.take(limit).toList(growable: false);
  }
}
