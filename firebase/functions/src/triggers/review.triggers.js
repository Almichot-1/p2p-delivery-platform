/**
 * Review Triggers
 * Handles review document events
 */

const functions = require("firebase-functions/v1");
const { collections } = require("../config/firebase");
const ratingService = require("../services/rating.service");

/**
 * Triggered when a new review is created
 */
exports.onReviewCreated = functions.firestore
  .document(`${collections.REVIEWS}/{reviewId}`)
  .onCreate(async (snap, context) => {
    const reviewId = context.params.reviewId;
    const review = snap.data();
    
    console.log(`New review created: ${reviewId}`);
    
    try {
      // Update user's rating (done by rating service, but double-check here)
      await ratingService.updateUserRating(review.revieweeId);
      
      return { success: true };
    } catch (error) {
      console.error("Error processing new review:", error);
      throw error;
    }
  });