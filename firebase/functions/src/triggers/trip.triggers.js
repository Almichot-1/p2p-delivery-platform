/**
 * Trip Triggers
 * Handles trip document events
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");
const matchingService = require("../services/matching.service");

/**
 * Triggered when a new trip is created
 */
exports.onTripCreated = functions.firestore
  .document(`${collections.TRIPS}/{tripId}`)
  .onCreate(async (snap, context) => {
    const tripId = context.params.tripId;
    const trip = snap.data();
    
    console.log(`New trip created: ${tripId}`);
    
    try {
      // Update user's trip count
      await db.collection(collections.USERS).doc(trip.travelerId).update({
        tripsCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      
      // Find and create matches
      const matchCount = await matchingService.processNewTrip(tripId, trip);
      console.log(`Created ${matchCount} matches for trip ${tripId}`);
      
      return { success: true, matchCount };
    } catch (error) {
      console.error("Error processing new trip:", error);
      throw error;
    }
  });

/**
 * Triggered when a trip is updated
 */
exports.onTripUpdated = functions.firestore
  .document(`${collections.TRIPS}/{tripId}`)
  .onUpdate(async (change, context) => {
    const tripId = context.params.tripId;
    const before = change.before.data();
    const after = change.after.data();
    
    console.log(`Trip updated: ${tripId}`);
    
    try {
      // If trip was cancelled, cancel pending matches
      if (before.status === "active" && after.status === "cancelled") {
        const matchesSnapshot = await db
          .collection(collections.MATCHES)
          .where("tripId", "==", tripId)
          .where("status", "==", "pending")
          .get();
        
        const batch = db.batch();
        matchesSnapshot.docs.forEach((doc) => {
          batch.update(doc.ref, {
            status: "cancelled",
            cancelReason: "Trip cancelled",
            updatedAt: FieldValue.serverTimestamp(),
          });
        });
        
        await batch.commit();
        console.log(`Cancelled ${matchesSnapshot.size} pending matches`);
      }
      
      // If capacity increased, check for new matches
      if (after.availableWeight > before.availableWeight && after.status === "active") {
        const matchCount = await matchingService.processNewTrip(tripId, after);
        console.log(`Created ${matchCount} new matches after capacity increase`);
      }
      
      return { success: true };
    } catch (error) {
      console.error("Error processing trip update:", error);
      throw error;
    }
  });