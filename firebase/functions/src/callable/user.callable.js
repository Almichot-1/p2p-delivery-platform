/**
 * User Callable Functions
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");
const { validateAuth, handleError, throwError } = require("../utils/errors");
const { ERROR_CODES } = require("../utils/constants");
const validationService = require("../services/validation.service");

/**
 * Update user profile
 */
exports.updateUserProfile = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    // Validate input
    const validation = validationService.validateUserProfile(data);
    if (!validation.isValid) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, validation.errors.join(", "));
    }
    
    // Filter allowed fields
    const allowedFields = ["displayName", "phone", "bio", "languages", "photoURL"];
    const updateData = {};
    
    allowedFields.forEach((field) => {
      if (data[field] !== undefined) {
        updateData[field] = data[field];
      }
    });
    
    updateData.updatedAt = FieldValue.serverTimestamp();
    
    await db.collection(collections.USERS).doc(auth.uid).update(updateData);
    
    return { success: true, message: "Profile updated successfully" };
  } catch (error) {
    handleError(error, "updateUserProfile");
  }
});

/**
 * Submit verification documents
 */
exports.submitVerification = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { documentType, documentUrl } = data;
    
    if (!documentType || !documentUrl) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Document type and URL are required");
    }
    
    const validTypes = ["passport", "national_id", "drivers_license"];
    if (!validTypes.includes(documentType)) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Invalid document type");
    }
    
    // Save verification request
    await db.collection(collections.USERS).doc(auth.uid).update({
      verification: {
        documentType,
        documentUrl,
        status: "pending",
        submittedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    return { success: true, message: "Verification submitted for review" };
  } catch (error) {
    handleError(error, "submitVerification");
  }
});

/**
 * Register FCM token for push notifications
 */
exports.registerFCMToken = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { token, platform } = data;
    
    if (!token) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "FCM token is required");
    }
    
    // Save token
    await db
      .collection(collections.USERS)
      .doc(auth.uid)
      .collection("tokens")
      .doc(token)
      .set({
        token,
        platform: platform || "unknown",
        createdAt: FieldValue.serverTimestamp(),
        lastUsed: FieldValue.serverTimestamp(),
      });
    
    return { success: true };
  } catch (error) {
    handleError(error, "registerFCMToken");
  }
});