import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseService _firebaseService;

  AuthRepository(this._firebaseService);

  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  // Current user
  User? get currentUser => _firebaseService.currentUser;
  String? get currentUserId => _firebaseService.currentUserId;

  // Register with email and password
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Create auth user
      final credential =
          await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Registration failed');
      }

      // Update display name
      await user.updateDisplayName(fullName);

      // Create user document
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        phone: phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.usersCollection
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login with email and password
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      // Update online status
      await _updateOnlineStatus(true);

      // Get user data
      return await getUserData(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Phone authentication - Send OTP
  Future<void> sendPhoneOTP({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    await _firebaseService.auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerify,
      verificationFailed: (e) => onError(e.message ?? 'Verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // Phone authentication - Verify OTP
  Future<UserModel> verifyPhoneOTP({
    required String verificationId,
    required String otp,
    required String fullName,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
          await _firebaseService.auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Phone verification failed');
      }

      // Check if user exists
      final doc = await _firebaseService.usersCollection.doc(user.uid).get();

      if (doc.exists) {
        await _updateOnlineStatus(true);
        return UserModel.fromFirestore(doc);
      }

      // Create new user
      final userModel = UserModel(
        uid: user.uid,
        email: '',
        fullName: fullName,
        phone: user.phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.usersCollection
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data
  Future<UserModel> getUserData(String uid) async {
    final doc = await _firebaseService.usersCollection.doc(uid).get();
    if (!doc.exists) {
      throw Exception('User not found');
    }
    return UserModel.fromFirestore(doc);
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return await getUserData(uid);
  }

  // Stream current user data
  Stream<UserModel?> streamCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);

    return _firebaseService.usersCollection
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update online status
  Future<void> _updateOnlineStatus(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _firebaseService.usersCollection.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Logout
  Future<void> logout() async {
    await _updateOnlineStatus(false);
    await _firebaseService.auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    // Delete user document
    await _firebaseService.usersCollection.doc(user.uid).delete();

    // Delete auth user
    await user.delete();
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
