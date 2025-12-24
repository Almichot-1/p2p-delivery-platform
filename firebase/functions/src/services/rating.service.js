/**
 * Rating Service
 * Handles user ratings and reviews
 */

const { db, FieldValue, collections } = require("../config/firebase");
const notificationService = require("./notification.service");

class RatingService {
  /**
   * Submit a review
   */
  async submitReview(matchId, reviewerId, revieweeId, rating, comment = "") {
    try {
      // Check if match exists and is completed
      const matchDoc = await db.collection(collections.MATCHES).doc(matchId).get();
      
      if (!matchDoc.exists) {
        throw new Error("Match not found");
      }
      
      const match = matchDoc.data();
      
      if (match.status !== "completed") {
        throw new Error("Can only review completed deliveries");
      }
      
      if (!match.participants.includes(reviewerId)) {
        throw new Error("Only participants can leave reviews");
      }
      
      // Check if already reviewed
      const existingReview = await db
        .collection(collections.REVIEWS)
        .where("matchId", "==", matchId)
        .where("reviewerId", "==", reviewerId)
        .get();
      
      if (!existingReview.empty) {
        throw new Error("You have already reviewed this delivery");
      }
      
      // Create review
      const review = {
        matchId,
        reviewerId,
        revieweeId,
        rating,
        comment,
        createdAt: FieldValue.serverTimestamp(),
      };
      
      await db.collection(collections.REVIEWS).add(review);
      
      // Update user's average rating
      await this.updateUserRating(revieweeId);
      
      // Send notification
      const reviewerDoc = await db.collection(collections.USERS).doc(reviewerId).get();
      const reviewerName = reviewerDoc.data().displayName;
      await notificationService.sendReviewNotification(revieweeId, reviewerName, rating);
      
      return true;
    } catch (error) {
      console.error("Error submitting review:", error);
      throw error;
    }
  }
  
  /**
   * Update user's average rating
   */
  async updateUserRating(userId) {
    try {
      const reviewsSnapshot = await db
        .collection(collections.REVIEWS)
        .where("revieweeId", "==", userId)
        .get();
      
      if (reviewsSnapshot.empty) {
        return;
      }
      
      let totalRating = 0;
      let count = 0;
      
      reviewsSnapshot.docs.forEach((doc) => {
        totalRating += doc.data().rating;
        count++;
      });
      
      const averageRating = totalRating / count;
      
      await db.collection(collections.USERS).doc(userId).update({
        rating: Math.round(averageRating * 10) / 10,
        reviewCount: count,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error("Error updating user rating:", error);
      throw error;
    }
  }
  
  /**
   * Get user's reviews
   */
  async getUserReviews(userId, limit = 20) {
    try {
      const reviewsSnapshot = await db
        .collection(collections.REVIEWS)
        .where("revieweeId", "==", userId)
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();
      
      const reviews = [];
      
      for (const doc of reviewsSnapshot.docs) {
        const review = doc.data();
        
        // Get reviewer info
        const reviewerDoc = await db.collection(collections.USERS).doc(review.reviewerId).get();
        
        reviews.push({
          id: doc.id,
          ...review,
          reviewer: reviewerDoc.exists ? {
            displayName: reviewerDoc.data().displayName,
            photoURL: reviewerDoc.data().photoURL,
          } : null,
        });
      }
      
      return reviews;
    } catch (error) {
      console.error("Error getting user reviews:", error);
      throw error;
    }
  }
}

module.exports = new RatingService();