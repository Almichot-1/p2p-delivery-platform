import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/request_model.dart';

class RequestRepository {
  RequestRepository(this._firebaseService, this._cloudinaryService);

  final FirebaseService _firebaseService;
  final CloudinaryService _cloudinaryService;

  final StreamController<double> _uploadProgressController =
      StreamController<double>.broadcast();

  Stream<double> get uploadProgressStream => _uploadProgressController.stream;

  Stream<List<RequestModel>> getActiveRequests({
    String? deliveryCity,
    RequestCategory? category,
    int? limit,
  }) {
    final normalizedCity = deliveryCity?.trim();

    Query<Map<String, dynamic>> q = _firebaseService.requests
        .where('status', isEqualTo: RequestStatus.active.name);

    if (limit != null && limit > 0) {
      q = q.limit(limit);
    }

    return q.snapshots().map((snap) {
      final all =
          snap.docs.map(RequestModel.fromFirestore).toList(growable: false);

      Iterable<RequestModel> filtered = all;

      if (normalizedCity != null && normalizedCity.isNotEmpty) {
        filtered = filtered.where(
          (r) =>
              r.deliveryCity.trim().toLowerCase() ==
              normalizedCity.toLowerCase(),
        );
      }

      if (category != null) {
        filtered = filtered.where((r) => r.category == category);
      }

      final list = filtered.toList(growable: false);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<RequestModel>> getRequestsByRequester(String requesterId) {
    final id = requesterId.trim();
    if (id.isEmpty) return const Stream<List<RequestModel>>.empty();

    final q = _firebaseService.requests.where('requesterId', isEqualTo: id);

    return q.snapshots().map((snap) {
      final list =
          snap.docs.map(RequestModel.fromFirestore).toList(growable: false);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<RequestModel?> getRequestById(String requestId) {
    final id = requestId.trim();
    if (id.isEmpty) return const Stream<RequestModel?>.empty();

    return _firebaseService.requests.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RequestModel.fromFirestore(doc);
    });
  }

  Future<String> createRequest(RequestModel request, List<File> images) async {
    if (images.length > 5) {
      throw Exception('You can upload up to 5 images');
    }

    _uploadProgressController.add(0);

    final docRef = _firebaseService.requests.doc();
    final now = DateTime.now();

    // Create Firestore document first (required)
    final initial = request.copyWith(
      id: docRef.id,
      imageUrls: const <String>[],
      status: RequestStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(initial.toFirestore());

    try {
      if (images.isNotEmpty) {
        final folder = 'requests/${docRef.id}';
        final urls = <String>[];

        for (var i = 0; i < images.length; i++) {
          final publicId =
              '${docRef.id}-$i-${DateTime.now().millisecondsSinceEpoch}';
          final url =
              await _cloudinaryService.uploadImage(images[i], folder, publicId);
          urls.add(url);
          _uploadProgressController.add((i + 1) / images.length);
        }

        // Only write URLs after ALL uploads succeed (required)
        await docRef.set(
          <String, dynamic>{
            'imageUrls': urls,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          },
          SetOptions(merge: true),
        );
      }

      return docRef.id;
    } catch (e) {
      // Avoid leaving half-written documents.
      try {
        await docRef.delete();
      } catch (_) {
        // Ignore cleanup errors.
      }
      rethrow;
    } finally {
      _uploadProgressController.add(0);
    }
  }

  Future<void> updateRequest(RequestModel request) async {
    final id = request.id.trim();
    if (id.isEmpty) throw Exception('Request id is missing');

    final now = DateTime.now();
    final map = request.copyWith(updatedAt: now).toFirestore();

    // createdAt must only be set once.
    map.remove('createdAt');

    await _firebaseService.requests.doc(id).set(
          map,
          SetOptions(merge: true),
        );
  }

  Future<void> cancelRequest(String requestId) async {
    final id = requestId.trim();
    if (id.isEmpty) return;

    await _firebaseService.requests.doc(id).set(
      <String, dynamic>{
        'status': RequestStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> dispose() async {
    await _uploadProgressController.close();
  }
}
