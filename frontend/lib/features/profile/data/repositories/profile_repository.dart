import 'dart:io';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRepository {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  ProfileRepository(this._firebaseService, this._storageService);

  // Get user profile
  Stream<UserModel?> getUserProfile(String userId) {
    return _firebaseService.usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update profile
  Future<void> updateProfile(UserModel user) async {
    await _firebaseService.usersCollection
        .doc(user.uid)
        .update(user.toFirestore());
  }

  // Update profile photo
  Future<String> updateProfilePhoto(File photo) async {
    final url = await _storageService.uploadProfileImage(photo);

    final userId = _firebaseService.currentUserId;
    if (userId != null) {
      await _firebaseService.usersCollection.doc(userId).update({
        'photoUrl': url,
      });
    }

    return url;
  }

  // Upload verification document
  Future<void> uploadVerificationDocument(File document) async {
    final url = await _storageService.uploadVerificationDoc(document);

    final userId = _firebaseService.currentUserId;
    if (userId != null) {
      await _firebaseService.usersCollection.doc(userId).update({
        'verificationDocUrl': url,
        'verificationStatus': VerificationStatus.pending.name,
      });
    }
  }

  // Update user role
  Future<void> updateUserRole(UserRole role) async {
    final userId = _firebaseService.currentUserId;
    if (userId != null) {
      await _firebaseService.usersCollection.doc(userId).update({
        'role': role.name,
      });
    }
  }
}
