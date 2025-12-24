import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { requester, traveler, both }

enum VerificationStatus { unverified, pending, verified, rejected }

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String? phone;
  final String fullName;
  final String? photoUrl;
  final UserRole role;
  final VerificationStatus verificationStatus;
  final List<String> verificationDocs;
  final List<String> languages;
  final String? bio;
  final String? currentCity;
  final String? homeCity;
  final double rating;
  final int totalReviews;
  final int completedDeliveries;
  final int completedTrips;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.phone,
    required this.fullName,
    this.photoUrl,
    this.role = UserRole.both,
    this.verificationStatus = VerificationStatus.unverified,
    this.verificationDocs = const [],
    this.languages = const ['English'],
    this.bio,
    this.currentCity,
    this.homeCity,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.completedDeliveries = 0,
    this.completedTrips = 0,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'],
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.both,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == data['verificationStatus'],
        orElse: () => VerificationStatus.unverified,
      ),
      verificationDocs: List<String>.from(data['verificationDocs'] ?? []),
      languages: List<String>.from(data['languages'] ?? ['English']),
      bio: data['bio'],
      currentCity: data['currentCity'],
      homeCity: data['homeCity'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      completedDeliveries: data['completedDeliveries'] ?? 0,
      completedTrips: data['completedTrips'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'verificationDocs': verificationDocs,
      'languages': languages,
      'bio': bio,
      'currentCity': currentCity,
      'homeCity': homeCity,
      'rating': rating,
      'totalReviews': totalReviews,
      'completedDeliveries': completedDeliveries,
      'completedTrips': completedTrips,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phone,
    String? fullName,
    String? photoUrl,
    UserRole? role,
    VerificationStatus? verificationStatus,
    List<String>? verificationDocs,
    List<String>? languages,
    String? bio,
    String? currentCity,
    String? homeCity,
    double? rating,
    int? totalReviews,
    int? completedDeliveries,
    int? completedTrips,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationDocs: verificationDocs ?? this.verificationDocs,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      currentCity: currentCity ?? this.currentCity,
      homeCity: homeCity ?? this.homeCity,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      completedTrips: completedTrips ?? this.completedTrips,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  @override
  List<Object?> get props => [
        uid,
        email,
        phone,
        fullName,
        photoUrl,
        role,
        verificationStatus,
        verificationDocs,
        languages,
        bio,
        currentCity,
        homeCity,
        rating,
        totalReviews,
        completedDeliveries,
        completedTrips,
        isOnline,
        lastSeen,
        fcmToken,
        createdAt,
        updatedAt,
      ];
}
