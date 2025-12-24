/**
 * Chat Callable Functions
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");
const { validateAuth, handleError, throwError } = require("../utils/errors");
const { ERROR_CODES, MATCH_STATUS } = require("../utils/constants");
const validationService = require("../services/validation.service");

/**
 * Send a message
 */
exports.sendMessage = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { matchId, content, attachmentUrl } = data;
    
    if (!matchId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Match ID is required");
    }
    
    // Validate message
    const validation = validationService.validateMessage(content);
    if (!validation.isValid && !attachmentUrl) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, validation.errors.join(", "));
    }
    
    // Verify user is participant
    const matchDoc = await db.collection(collections.MATCHES).doc(matchId).get();
    
    if (!matchDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Match not found");
    }
    
    const match = matchDoc.data();
    
    if (!match.participants.includes(auth.uid)) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You are not a participant in this chat");
    }
    
    // Only allow chat for accepted matches
    if (match.status !== MATCH_STATUS.ACCEPTED && match.status !== MATCH_STATUS.COMPLETED) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "Chat is only available for accepted matches");
    }
    
    // Create message
    const message = {
      senderId: auth.uid,
      content: content || "",
      attachmentUrl: attachmentUrl || null,
      timestamp: FieldValue.serverTimestamp(),
      isRead: false,
    };
    
    const messageRef = await db
      .collection(collections.MATCHES)
      .doc(matchId)
      .collection("messages")
      .add(message);
    
    return { 
      success: true, 
      messageId: messageRef.id 
    };
  } catch (error) {
    handleError(error, "sendMessage");
  }
});

/**
 * Get messages for a match
 */
exports.getMessages = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { matchId, limit = 50, beforeMessageId } = data;
    
    if (!matchId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Match ID is required");
    }
    
    // Verify user is participant
    const matchDoc = await db.collection(collections.MATCHES).doc(matchId).get();
    
    if (!matchDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Match not found");
    }
    
    if (!matchDoc.data().participants.includes(auth.uid)) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You are not a participant in this chat");
    }
    
    let query = db
      .collection(collections.MATCHES)
      .doc(matchId)
      .collection("messages")
      .orderBy("timestamp", "desc");
    
    if (beforeMessageId) {
      const beforeDoc = await db
        .collection(collections.MATCHES)
        .doc(matchId)
        .collection("messages")
        .doc(beforeMessageId)
        .get();
      
      if (beforeDoc.exists) {
        query = query.startAfter(beforeDoc);
      }
    }
    
    query = query.limit(limit);
    
    const snapshot = await query.get();
    
    const messages = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    return { 
      success: true, 
      messages: messages.reverse(), // Return in chronological order
      hasMore: snapshot.docs.length === limit
    };
  } catch (error) {
    handleError(error, "getMessages");
  }
});

/**
 * Mark messages as read
 */
exports.markMessagesRead = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { matchId, messageIds } = data;
    
    if (!matchId || !messageIds || messageIds.length === 0) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Match ID and message IDs are required");
    }
    
    // Verify user is participant
    const matchDoc = await db.collection(collections.MATCHES).doc(matchId).get();
    
    if (!matchDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Match not found");
    }
    
    if (!matchDoc.data().participants.includes(auth.uid)) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You are not a participant in this chat");
    }
    
    // Update messages in batch
    const batch = db.batch();
    
    for (const messageId of messageIds) {
      const messageRef = db
        .collection(collections.MATCHES)
        .doc(matchId)
        .collection("messages")
        .doc(messageId);
      
      batch.update(messageRef, { isRead: true });
    }
    
    await batch.commit();
    
    return { success: true };
  } catch (error) {
    handleError(error, "markMessagesRead");
  }
});