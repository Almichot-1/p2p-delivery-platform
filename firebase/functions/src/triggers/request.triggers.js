/**
 * Request Triggers
 * Handles request document events
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");
const matchingService = require("../services/matching.service");

/**
 * Triggered when a new request is created
 */
exports.onRequestCreated = functions.firestore
  .document(`${collections.REQUESTS}/{requestId}`)
  .onCreate(async (snap, context) => {
    const requestId = context.params.requestId;
    const request = snap.data();
    
    console.log(`New request created: ${requestId}`);
    
    try {
      // Update user's request count
      await db.collection(collections.USERS).doc(request.requesterId).update({
        requestsCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      
      // Find and create matches
      const matchCount = await matchingService.processNewRequest(requestId, request);
      console.log(`Created ${matchCount} matches for request ${requestId}`);
      
      return { success: true, matchCount };
    } catch (error) {
      console.error("Error processing new request:", error);
      throw error;
    }
  });

/**
 * Triggered when a request is updated
 */
exports.onRequestUpdated = functions.firestore
  .document(`${collections.REQUESTS}/{requestId}`)
  .onUpdate(async (change, context) => {
    const requestId = context.params.requestId;
    const before = change.before.data();
    const after = change.after.data();
    
    console.log(`Request updated: ${requestId}`);
    
    try {
      // If request was cancelled, cancel pending matches
      if (before.status === "active" && after.status === "cancelled") {
        const matchesSnapshot = await db
          .collection(collections.MATCHES)
          .where("requestId", "==", requestId)
          .where("status", "==", "pending")
          .get();
        
        const batch = db.batch();
        matchesSnapshot.docs.forEach((doc) => {
          batch.update(doc.ref, {
            status: "cancelled",
            cancelReason: "Request cancelled",
            updatedAt: FieldValue.serverTimestamp(),
          });
        });
        
        await batch.commit();
        console.log(`Cancelled ${matchesSnapshot.size} pending matches`);
      }
      
      return { success: true };
    } catch (error) {
      console.error("Error processing request update:", error);
      throw error;
    }
  });