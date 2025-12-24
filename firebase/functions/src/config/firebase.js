/**
 * Firebase Admin SDK Configuration
 */

const admin = require("firebase-admin");

const db = admin.firestore();
const auth = admin.auth();
const messaging = admin.messaging();
const storage = admin.storage();

// Firestore settings
db.settings({
  ignoreUndefinedProperties: true,
});

// Collection references
const collections = {
  USERS: "users",
  TRIPS: "trips",
  REQUESTS: "requests",
  MATCHES: "matches",
  REVIEWS: "reviews",
  NOTIFICATIONS: "notifications",
  REPORTS: "reports",
  SYSTEM: "system",
};

module.exports = {
  admin,
  db,
  auth,
  messaging,
  storage,
  collections,
  FieldValue: admin.firestore.FieldValue,
  Timestamp: admin.firestore.Timestamp,
};