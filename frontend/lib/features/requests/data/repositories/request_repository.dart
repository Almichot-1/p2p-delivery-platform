import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/request_model.dart';

class RequestRepository {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  RequestRepository(this._firebaseService, this._storageService);

  // Get all active requests
  Stream<List<RequestModel>> getActiveRequests({
    String? deliveryCity,
    ItemCategory? category,
    int limit = 20,
  }) {
    Query query = _firebaseService.requestsCollection
        .where('status', isEqualTo: RequestStatus.active.name)
        .orderBy('createdAt', descending: true);

    if (deliveryCity != null) {
      query = query.where('deliveryCity', isEqualTo: deliveryCity);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList());
  }

  // Get requests by requester
  Stream<List<RequestModel>> getRequestsByRequester(String requesterId) {
    return _firebaseService.requestsCollection
        .where('requesterId', isEqualTo: requesterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromFirestore(doc))
            .toList());
  }

  // Get single request
  Stream<RequestModel?> getRequestById(String requestId) {
    return _firebaseService.requestsCollection
        .doc(requestId)
        .snapshots()
        .map((doc) => doc.exists ? RequestModel.fromFirestore(doc) : null);
  }

  // Create request with images
  Future<String> createRequest(
    RequestModel request, {
    List<File>? images,
  }) async {
    // Upload images first
    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      final tempDocRef = _firebaseService.requestsCollection.doc();
      imageUrls = await _storageService.uploadMultipleImages(
        images,
        tempDocRef.id,
      );
    }

    // Create request with image URLs
    final requestWithImages = request.copyWith(imageUrls: imageUrls);
    final docRef = await _firebaseService.requestsCollection
        .add(requestWithImages.toFirestore());

    return docRef.id;
  }

  // Update request
  Future<void> updateRequest(RequestModel request) async {
    await _firebaseService.requestsCollection
        .doc(request.id)
        .update(request.toFirestore());
  }

  // Cancel request
  Future<void> cancelRequest(String requestId) async {
    await _firebaseService.requestsCollection.doc(requestId).update({
      'status': RequestStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Search requests
  Future<List<RequestModel>> searchRequests({
    required String deliveryCity,
    double? maxWeight,
    ItemCategory? category,
  }) async {
    Query query = _firebaseService.requestsCollection
        .where('status', isEqualTo: RequestStatus.active.name)
        .where('deliveryCity', isEqualTo: deliveryCity);

    final snapshot = await query.get();
    var requests =
        snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList();

    // Client-side filtering for complex queries
    if (maxWeight != null) {
      requests = requests.where((r) => r.weightKg <= maxWeight).toList();
    }

    if (category != null) {
      requests = requests.where((r) => r.category == category).toList();
    }

    return requests;
  }

  // Delete request
  Future<void> deleteRequest(String requestId) async {
    // Get request to delete images
    final doc = await _firebaseService.requestsCollection.doc(requestId).get();
    if (doc.exists) {
      final request = RequestModel.fromFirestore(doc);
      // Delete associated images
      for (final url in request.imageUrls) {
        await _storageService.deleteFile(url);
      }
    }
    await _firebaseService.requestsCollection.doc(requestId).delete();
  }
}
