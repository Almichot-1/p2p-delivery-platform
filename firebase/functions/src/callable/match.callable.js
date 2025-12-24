/**
 * Match Callable Functions
 */

const functions = require("firebase-functions/v1");
const { db, collections } = require("../config/firebase");
const { validateAuth, handleError, throwError } = require("../utils/errors");
const { ERROR_CODES } = require("../utils/constants");
const matchingService = require("../services/matching.service");
const ratingService = require("../services/rating.service");

/**
 * Respond to a match (accept/reject)
 */
exports.respondToMatch = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { matchId, response } = data;
    
    if (!matchId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Match ID is required");
    }
    
    if (!["accept", "reject"].includes(response)) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Response must be 'accept' or 'reject'");
    }
    
    if (response === "accept") {
      await matchingService.acceptMatch(matchId, auth.uid);
    } else {
      await matchingService.rejectMatch(matchId, auth.uid);
    }
    
    return { 
      success: true, 
      message: `Match ${response}ed successfully` 
    };
  } catch (error) {
    handleError(error, "respondToMatch");
  }
});

/**
 * Complete a delivery
 */
exports.completeDelivery = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { matchId } = data;
    
    if (!matchId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Match ID is required");
    }
    
    await matchingService.completeDelivery(matchId, auth.uid);
    
    return { 
      success: true, 
      message: "Delivery marked as complete" 
    };
  } catch (error) {
    handleError(error, "completeDelivery");
  }
});

/**
 * Get user's matches
 */
exports.getMyMatches = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { status, limit = 20, lastMatchId } = data;
    
    let query = db
      .collection(collections.MATCHES)
      .where("participants", "array-contains", auth.uid)
      .orderBy("createdAt", "desc");
    
    if (status) {
      query = query.where("status", "==", status);
    }
    
    if (lastMatchId) {
      const lastDoc = await db.collection(collections.MATCHES).doc(lastMatchId).get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }
    
    query = query.limit(limit);
    
    const snapshot = await query.get();
    
    const matches = await Promise.all(snapshot.docs.map(async (doc) => {
      const matchData = doc.data();
      const otherUserId = matchData.participants.find((p) => p !== auth.uid);
      
      // Get other user's info
      const otherUserDoc = await db.collection(collections.USERS).doc(otherUserId).get();
      const otherUser = otherUserDoc.exists ? {
        uid: otherUserDoc.id,
        displayName: otherUserDoc.data().displayName,
        photoURL: otherUserDoc.data().photoURL,
        rating: otherUserDoc.data().rating,
      } : null;
      
      return {
        id: doc.id,
        ...matchData,
        otherUser,
      };
    }));
    
    return { 
      success: true, 
      matches,
      hasMore: snapshot.docs.length === limit
    };
  } catch (error) {
    handleError(error, "getMyMatches");
  }
});

/**
 * Submit a review for a completed match
 */
exports.submitReview = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { matchId, rating, comment } = data;
    
    if (!matchId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Match ID is required");
    }
    
    // Validate review
    const validationService = require("../services/validation.service");
    const validation = validationService.validateReview(rating, comment);
    if (!validation.isValid) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, validation.errors.join(", "));
    }
    
    // Get match
    const matchDoc = await db.collection(collections.MATCHES).doc(matchId).get();
    if (!matchDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Match not found");
    }
    
    const match = matchDoc.data();
    const revieweeId = match.participants.find((p) => p !== auth.uid);
    
    await ratingService.submitReview(matchId, auth.uid, revieweeId, rating, comment);
    
    return { 
      success: true, 
      message: "Review submitted successfully" 
    };
  } catch (error) {
    handleError(error, "submitReview");
  }
});