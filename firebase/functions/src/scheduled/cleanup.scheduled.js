/**
 * Scheduled Functions
 * Periodic cleanup / reminders / stats.
 */

const functions = require("firebase-functions/v1");

const { db, FieldValue, collections } = require("../config/firebase");
const { TRIP_STATUS, REQUEST_STATUS } = require("../utils/constants");

exports.cleanupExpiredTrips = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const now = new Date();
    const batch = db.batch();
    let writes = 0;

    // Expire trips whose departureDate is in the past and are still active.
    const tripsSnap = await db
      .collection(collections.TRIPS)
      .where("status", "==", TRIP_STATUS.ACTIVE)
      .limit(500)
      .get();

    for (const doc of tripsSnap.docs) {
      const trip = doc.data();
      const departureDate =
        trip.departureDate && trip.departureDate.toDate ?
          trip.departureDate.toDate() :
          trip.departureDate;
      const departure = departureDate ? new Date(departureDate) : null;
      if (departure && departure < now) {
        batch.update(doc.ref, {
          status: TRIP_STATUS.EXPIRED,
          updatedAt: FieldValue.serverTimestamp(),
        });
        writes += 1;
      }
    }

    // Expire requests that are still active and have an expiryDate in the past.
    const requestsSnap = await db
      .collection(collections.REQUESTS)
      .where("status", "==", REQUEST_STATUS.ACTIVE)
      .limit(500)
      .get();

    for (const doc of requestsSnap.docs) {
      const req = doc.data();
      const expiryDate = req.expiryDate && req.expiryDate.toDate ? req.expiryDate.toDate() : req.expiryDate;
      const expiry = expiryDate ? new Date(expiryDate) : null;
      if (expiry && expiry < now) {
        batch.update(doc.ref, {
          status: REQUEST_STATUS.EXPIRED,
          updatedAt: FieldValue.serverTimestamp(),
        });
        writes += 1;
      }
    }

    if (writes === 0) return null;
    await batch.commit();
    return null;
  });

exports.sendReminders = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    // Placeholder: implement trip/request reminders.
    return null;
  });

exports.generateDailyStats = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    // Placeholder: store a daily stats doc.
    await db.collection(collections.SYSTEM).doc("dailyStats").set(
      {
        lastRunAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return null;
  });
