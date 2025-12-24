import '../../../../core/services/firebase_service.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseService _firebaseService;

  ReviewRepository(this._firebaseService);

  // Get reviews for a user
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firebaseService.reviewsCollection
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  // Get reviews by a user
  Stream<List<ReviewModel>> getReviewsByUser(String userId) {
    return _firebaseService.reviewsCollection
        .where('reviewerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  // Check if user already reviewed this match
  Future<bool> hasReviewed(String matchId, String reviewerId) async {
    final snapshot = await _firebaseService.reviewsCollection
        .where('matchId', isEqualTo: matchId)
        .where('reviewerId', isEqualTo: reviewerId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Create review
  Future<void> createReview(ReviewModel review) async {
    await _firebaseService.reviewsCollection.add(review.toFirestore());

    // Update user's average rating
    await _updateUserRating(review.revieweeId);
  }

  // Update user's average rating
  Future<void> _updateUserRating(String userId) async {
    final reviews = await _firebaseService.reviewsCollection
        .where('revieweeId', isEqualTo: userId)
        .get();

    if (reviews.docs.isEmpty) return;

    double totalRating = 0;
    for (final doc in reviews.docs) {
      totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
    }

    final averageRating = totalRating / reviews.docs.length;

    await _firebaseService.usersCollection.doc(userId).update({
      'rating': averageRating,
      'totalReviews': reviews.docs.length,
    });
  }
}
