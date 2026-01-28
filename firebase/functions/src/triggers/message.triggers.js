/**
 * Message Triggers
 * Handles message events for real-time chat
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");
const notificationService = require("../services/notification.service");

/**
 * Triggered when a new message is created
 */
exports.onMessageCreated = functions.firestore
  .document(`${collections.MATCHES}/{matchId}/messages/{messageId}`)
  .onCreate(async (snap, context) => {
    const matchId = context.params.matchId;
    const messageId = context.params.messageId;
    const message = snap.data();
    
    console.log(`New message in match ${matchId}: ${messageId}`);
    
    try {
      // Get match to find recipient
      const matchDoc = await db.collection(collections.MATCHES).doc(matchId).get();
      
      if (!matchDoc.exists) {
        console.error("Match not found");
        return;
      }
      
      const match = matchDoc.data();
      const recipientId = match.participants.find((p) => p !== message.senderId);
      
      // Get sender info
      const senderDoc = await db.collection(collections.USERS).doc(message.senderId).get();
      const senderName = senderDoc.exists ? senderDoc.data().displayName : "Someone";
      
      // Send notification
      await notificationService.sendMessageNotification(
        matchId,
        message.senderId,
        senderName,
        recipientId,
        message.content
      );
      
      // Update match's last message info
      await db.collection(collections.MATCHES).doc(matchId).update({
        lastMessage: (message.content || "").substring(0, 100),
        // Prefer Flutter schema field `createdAt`; fall back to legacy `timestamp`; else server time.
        lastMessageAt: message.createdAt || message.timestamp || FieldValue.serverTimestamp(),
        lastMessageSenderId: message.senderId,
      });
      
      return { success: true };
    } catch (error) {
      console.error("Error processing new message:", error);
      throw error;
    }
  });