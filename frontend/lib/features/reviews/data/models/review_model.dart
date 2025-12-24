import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String matchId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhoto;
  final String revieweeId;
  final String revieweeName;
  final double rating;
  final String comment;
  final bool isTravelerReview; // true if reviewing traveler
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.matchId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhoto,
    required this.revieweeId,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    required this.isTravelerReview,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      reviewerPhoto: data['reviewerPhoto'],
      revieweeId: data['revieweeId'] ?? '',
      revieweeName: data['revieweeName'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      isTravelerReview: data['isTravelerReview'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhoto': reviewerPhoto,
      'revieweeId': revieweeId,
      'revieweeName': revieweeName,
      'rating': rating,
      'comment': comment,
      'isTravelerReview': isTravelerReview,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, matchId, reviewerId, revieweeId, rating];
}
