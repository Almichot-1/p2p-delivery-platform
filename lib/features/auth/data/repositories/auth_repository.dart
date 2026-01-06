import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({required FirebaseService firebaseService})
      : _firebaseService = firebaseService {
    _authStateSub = authStateChanges.listen((user) {
      _subscribeToCurrentUserProfile(user);
    });
  }

  final FirebaseService _firebaseService;

  final StreamController<UserModel?> _profileController =
      StreamController<UserModel?>.broadcast();

  StreamSubscription<User?>? _authStateSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  Stream<User?> get authStateChanges {
    try {
      return _firebaseService.auth.authStateChanges();
    } catch (_) {
      // Allows app/tests to boot without Firebase native config.
      return Stream<User?>.value(null);
    }
  }

  Stream<UserModel?> get userProfileStream => _profileController.stream;

  User? getCurrentUser() {
    try {
      return _firebaseService.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firebaseService.users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String fullName,
    String? phone,
  ) async {
    try {
      final cred = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('Registration failed: user is null');
      }

      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? email.trim(),
        'phone': phone,
        'fullName': fullName.trim(),
        'photoUrl': null,
        'role': UserRole.requester.name,
        'verified': false,
        'rating': 0.0,
        'totalReviews': 0,
        'completedDeliveries': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }..removeWhere((key, value) => value == null);

      await _firebaseService.users
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      final model = await getUserById(user.uid);
      if (model == null) {
        throw Exception('Registration succeeded but profile missing');
      }

      return model;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final cred = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('Login failed: user is null');
      }

      await _firebaseService.users.doc(user.uid).set(
        <String, dynamic>{
          'lastActiveAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final model = await getUserById(user.uid);
      if (model == null) {
        throw Exception('No user profile found for this account');
      }

      return model;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> logout() async {
    await _cancelProfileSubscription();
    try {
      await _firebaseService.auth.signOut();
    } catch (_) {
      // no-op
    }
    _profileController.add(null);
  }

  Future<void> dispose() async {
    await _cancelProfileSubscription();
    await _authStateSub?.cancel();
    await _profileController.close();
  }

  void _subscribeToCurrentUserProfile(User? user) {
    _profileSub?.cancel();
    _profileSub = null;

    if (user == null) {
      _profileController.add(null);
      return;
    }

    _profileSub = _firebaseService.users.doc(user.uid).snapshots().listen(
      (doc) {
        if (!doc.exists) {
          _profileController.add(null);
          return;
        }
        _profileController.add(UserModel.fromFirestore(doc));
      },
      onError: (_) {
        _profileController.add(null);
      },
    );
  }

  Future<void> _cancelProfileSubscription() async {
    await _profileSub?.cancel();
    _profileSub = null;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    final msg = (e.message ?? '').toUpperCase();
    if (msg.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Auth is not fully configured for this Android build. Add your debug SHA-1/SHA-256 fingerprints in Firebase Console, then re-download android/app/google-services.json and rebuild.';
    }

    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication error. Please try again.';
    }
  }
}
