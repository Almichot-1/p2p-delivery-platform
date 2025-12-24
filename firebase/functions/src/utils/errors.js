/**
 * Custom Error Classes and Error Handling
 */

const functions = require("firebase-functions/v1");
const { ERROR_CODES } = require("./constants");

class AppError extends Error {
  constructor(code, message, details = null) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

const throwError = (code, message, details = null) => {
  throw new functions.https.HttpsError(code, message, details);
};

const handleError = (error, context = "") => {
  console.error(`Error in ${context}:`, error);
  
  if (error instanceof functions.https.HttpsError) {
    throw error;
  }
  
  if (error instanceof AppError) {
    throw new functions.https.HttpsError(error.code, error.message, error.details);
  }
  
  throw new functions.https.HttpsError(
    ERROR_CODES.INTERNAL,
    "An unexpected error occurred",
    { originalError: error.message }
  );
};

const validateAuth = (context) => {
  if (!context.auth) {
    throwError(ERROR_CODES.UNAUTHENTICATED, "User must be authenticated");
  }
  return context.auth;
};

const validateAdmin = async (context, db) => {
  const auth = validateAuth(context);
  const userDoc = await db.collection("users").doc(auth.uid).get();
  
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throwError(ERROR_CODES.PERMISSION_DENIED, "Admin access required");
  }
  
  return auth;
};

module.exports = {
  AppError,
  throwError,
  handleError,
  validateAuth,
  validateAdmin,
};