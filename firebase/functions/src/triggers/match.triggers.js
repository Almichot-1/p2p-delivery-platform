/**
 * Match Triggers
 * Handles match document events
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");

/**
 * Triggered when a new match is created
 */
exports.onMatchCreated = functions.firestore
  .document(`${collections.MATCHES}/{matchId}`)
  .onCreate(async (snap, context) => {
    const matchId = context.params.matchId;
    const match = snap.data();
    
    console.log(`New match created: ${matchId}`);
    
    // Notifications are sent by the matching service
    void match;
    return { success: true };
  });

/**
 * Triggered when a match is updated
 */
exports.onMatchUpdated = functions.firestore
  .document(`${collections.MATCHES}/{matchId}`)
  .onUpdate(async (change, context) => {
    const matchId = context.params.matchId;
    const before = change.before.data();
    const after = change.after.data();
    
    console.log(`Match updated: ${matchId}`);
    
    try {
      // Status changed to completed
      if (before.status !== "completed" && after.status === "completed") {
        // Update both users' completed delivery count
        const batch = db.batch();
        
        for (const userId of after.participants) {
          const userRef = db.collection(collections.USERS).doc(userId);
          batch.update(userRef, {
            completedDeliveries: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        console.log("Updated completed delivery counts");
      }
      
      // Status changed to rejected
      if (before.status === "pending" && after.status === "rejected") {
        // Optional: notify the other user that the match was rejected.
        // (Kept as a placeholder; notifications are generally handled in services.)
        void matchId;
      }
      
      return { success: true };
    } catch (error) {
      console.error("Error processing match update:", error);
      throw error;
    }
  });