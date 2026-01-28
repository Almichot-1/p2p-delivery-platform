import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  FirebaseAuth get auth => _auth;

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  // Firestore Collections
  FirebaseFirestore get firestore => _firestore;
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get tripsCollection => _firestore.collection('trips');
  CollectionReference get requestsCollection =>
      _firestore.collection('requests');
  CollectionReference get matchesCollection => _firestore.collection('matches');
  CollectionReference get chatsCollection => _firestore.collection('chats');
  CollectionReference get reviewsCollection => _firestore.collection('reviews');
  CollectionReference get notificationsCollection =>
      _firestore.collection('notifications');

  // Storage References
  FirebaseStorage get storage => _storage;
  Reference get storageRoot => _storage.ref();

  // Storage roots aligned to backend storage rules
  Reference get usersStorageRef => _storage.ref().child('users');
  Reference get requestsStorageRef => _storage.ref().child('requests');
  Reference get matchesStorageRef => _storage.ref().child('matches');

  // Helper methods
  String getTimestamp() {
    return DateTime.now().toIso8601String();
  }

  DocumentReference getUserRef(String userId) {
    return usersCollection.doc(userId);
  }
}
