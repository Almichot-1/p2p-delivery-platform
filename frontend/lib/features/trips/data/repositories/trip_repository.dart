import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/trip_model.dart';

class TripRepository {
  final FirebaseService _firebaseService;

  TripRepository(this._firebaseService);

  // Get all active trips
  Stream<List<TripModel>> getActiveTrips({
    String? destinationCity,
    DateTime? afterDate,
    int limit = 20,
  }) {
    Query query = _firebaseService.tripsCollection
        .where('status', isEqualTo: TripStatus.active.name)
        .where('departureDate',
            isGreaterThan: Timestamp.fromDate(DateTime.now()));

    if (destinationCity != null) {
      query = query.where('destinationCity', isEqualTo: destinationCity);
    }

    query = query.orderBy('departureDate').limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList());
  }

  // Get trips by traveler
  Stream<List<TripModel>> getTripsByTraveler(String travelerId) {
    return _firebaseService.tripsCollection
        .where('travelerId', isEqualTo: travelerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList());
  }

  // Get single trip
  Stream<TripModel?> getTripById(String tripId) {
    return _firebaseService.tripsCollection
        .doc(tripId)
        .snapshots()
        .map((doc) => doc.exists ? TripModel.fromFirestore(doc) : null);
  }

  // Create trip
  Future<String> createTrip(TripModel trip) async {
    final docRef =
        await _firebaseService.tripsCollection.add(trip.toFirestore());
    return docRef.id;
  }

  // Update trip
  Future<void> updateTrip(TripModel trip) async {
    await _firebaseService.tripsCollection
        .doc(trip.id)
        .update(trip.toFirestore());
  }

  // Cancel trip
  Future<void> cancelTrip(String tripId) async {
    await _firebaseService.tripsCollection.doc(tripId).update({
      'status': TripStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Complete trip
  Future<void> completeTrip(String tripId) async {
    await _firebaseService.tripsCollection.doc(tripId).update({
      'status': TripStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Search trips
  Future<List<TripModel>> searchTrips({
    required String destinationCity,
    DateTime? departureDate,
    double? minCapacity,
  }) async {
    Query query = _firebaseService.tripsCollection
        .where('status', isEqualTo: TripStatus.active.name)
        .where('destinationCity', isEqualTo: destinationCity);

    if (departureDate != null) {
      final startOfDay = DateTime(
        departureDate.year,
        departureDate.month,
        departureDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      query = query
          .where('departureDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('departureDate', isLessThan: Timestamp.fromDate(endOfDay));
    }

    final snapshot = await query.get();
    var trips =
        snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();

    if (minCapacity != null) {
      trips = trips.where((t) => t.availableCapacityKg >= minCapacity).toList();
    }

    return trips;
  }

  // Delete trip
  Future<void> deleteTrip(String tripId) async {
    await _firebaseService.tripsCollection.doc(tripId).delete();
  }
}
