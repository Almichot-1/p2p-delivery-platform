import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get trips =>
      firestore.collection('trips');
  CollectionReference<Map<String, dynamic>> get requests =>
      firestore.collection('requests');
  CollectionReference<Map<String, dynamic>> get matches =>
      firestore.collection('matches');
  CollectionReference<Map<String, dynamic>> get reviews =>
      firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get notifications =>
      firestore.collection('notifications');

  User? get currentUser => auth.currentUser;
}
