import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { requester, traveler, both }

class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.email,
    this.phone,
    required this.fullName,
    this.bio,
    this.languages = const <String>[],
    this.photoUrl,
    this.role = UserRole.requester,
    this.verified = false,
    this.isOnline = false,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.completedDeliveries = 0,
    this.createdAt,
    this.lastActiveAt,
  });

  final String uid;
  final String email;
  final String? phone;
  final String fullName;
  final String? bio;
  final List<String> languages;
  final String? photoUrl;
  final UserRole role;
  final bool verified;
  final bool isOnline;
  final double rating;
  final int totalReviews;
  final int completedDeliveries;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('User document is empty for uid=${doc.id}');
    }

    DateTime? tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    UserRole parseRole(dynamic v) {
      final s = (v ?? '').toString();
      switch (s) {
        case 'traveler':
          return UserRole.traveler;
        case 'both':
          return UserRole.both;
        case 'requester':
        default:
          return UserRole.requester;
      }
    }

    return UserModel(
      uid: data['uid']?.toString() ?? doc.id,
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString(),
      fullName: data['fullName']?.toString() ?? '',
      bio: data['bio']?.toString(),
      languages: (data['languages'] is Iterable)
          ? (data['languages'] as Iterable).map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      photoUrl: data['photoUrl']?.toString(),
      role: parseRole(data['role']),
      verified: (data['verified'] as bool?) ?? false,
      isOnline: (data['isOnline'] as bool?) ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (data['totalReviews'] as num?)?.toInt() ?? 0,
      completedDeliveries: (data['completedDeliveries'] as num?)?.toInt() ?? 0,
      createdAt: tsToDate(data['createdAt']),
      lastActiveAt: tsToDate(data['lastActiveAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'bio': bio,
      'languages': languages,
      'photoUrl': photoUrl,
      'role': role.name,
      'verified': verified,
      'isOnline': isOnline,
      'rating': rating,
      'totalReviews': totalReviews,
      'completedDeliveries': completedDeliveries,
      // Timestamps are managed by repository with FieldValue.serverTimestamp().
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'lastActiveAt': lastActiveAt == null ? null : Timestamp.fromDate(lastActiveAt!),
    }..removeWhere((key, value) => value == null);
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? phone,
    String? fullName,
    String? bio,
    List<String>? languages,
    String? photoUrl,
    UserRole? role,
    bool? verified,
    bool? isOnline,
    double? rating,
    int? totalReviews,
    int? completedDeliveries,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      verified: verified ?? this.verified,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        uid,
        email,
        phone,
        fullName,
      bio,
      languages,
        photoUrl,
        role,
        verified,
      isOnline,
        rating,
        totalReviews,
        completedDeliveries,
        createdAt,
        lastActiveAt,
      ];
}
