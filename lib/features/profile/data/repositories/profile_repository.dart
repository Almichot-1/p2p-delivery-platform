import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRepository {
  ProfileRepository(
    FirebaseService firebaseService,
    CloudinaryService cloudinaryService,
  )   : _firebaseService = firebaseService,
        _cloudinaryService = cloudinaryService;

  final FirebaseService _firebaseService;
  final CloudinaryService _cloudinaryService;

  Stream<UserModel?> getUserProfile(String uid) {
    return _firebaseService.users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateProfile(UserModel user) async {
    await _firebaseService.users.doc(user.uid).set(
      user.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<String> updateProfilePhoto(File photo, String uid) async {
    final url = await _cloudinaryService.uploadProfileImage(photo, uid);
    await _firebaseService.users.doc(uid).set(
      <String, dynamic>{
        'photoUrl': url,
        'lastActiveAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return url;
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    await _firebaseService.users.doc(user.uid).set(
      <String, dynamic>{
        'isOnline': isOnline,
        'lastActiveAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
