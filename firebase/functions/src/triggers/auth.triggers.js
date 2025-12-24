/**
 * Authentication Triggers
 * Handles user creation and deletion events
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, collections } = require("../config/firebase");

/**
 * Triggered when a new user signs up
 */
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  console.log(`New user created: ${user.uid}`);
  
  try {
    // Create user document in Firestore
    const userData = {
      uid: user.uid,
      email: user.email || null,
      phone: user.phoneNumber || null,
      displayName: user.displayName || user.email?.split("@")[0] || "User",
      photoURL: user.photoURL || null,
      role: "user",
      isVerified: false,
      rating: 0,
      reviewCount: 0,
      tripsCount: 0,
      requestsCount: 0,
      completedDeliveries: 0,
      languages: [],
      bio: "",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      lastLoginAt: FieldValue.serverTimestamp(),
    };
    
    await db.collection(collections.USERS).doc(user.uid).set(userData);
    
    console.log(`User document created for ${user.uid}`);
    return { success: true };
  } catch (error) {
    console.error("Error creating user document:", error);
    throw error;
  }
});

/**
 * Triggered when a user is deleted
 */
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  console.log(`User deleted: ${user.uid}`);
  
  try {
    const batch = db.batch();
    
    // Mark user document as deleted (soft delete)
    const userRef = db.collection(collections.USERS).doc(user.uid);
    batch.update(userRef, {
      isDeleted: true,
      deletedAt: FieldValue.serverTimestamp(),
      email: null,
      phone: null,
    });
    
    // Cancel active trips
    const tripsSnapshot = await db
      .collection(collections.TRIPS)
      .where("travelerId", "==", user.uid)
      .where("status", "==", "active")
      .get();
    
    tripsSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "cancelled" });
    });
    
    // Cancel active requests
    const requestsSnapshot = await db
      .collection(collections.REQUESTS)
      .where("requesterId", "==", user.uid)
      .where("status", "==", "active")
      .get();
    
    requestsSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "cancelled" });
    });
    
    await batch.commit();
    
    console.log(`Cleanup completed for user ${user.uid}`);
    return { success: true };
  } catch (error) {
    console.error("Error cleaning up user data:", error);
    throw error;
  }
});