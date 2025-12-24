/**
 * Notification Service
 * Stores in-app notifications and sends FCM pushes (if tokens exist).
 */

const { db, messaging, FieldValue, collections } = require("../config/firebase");

class NotificationService {
  async getUserTokens(userId) {
    const tokensSnap = await db
      .collection(collections.USERS)
      .doc(userId)
      .collection("tokens")
      .limit(500)
      .get();

    if (tokensSnap.empty) return [];
    return tokensSnap.docs
      .map((d) => d.data() && d.data().token)
      .filter(Boolean);
  }

  async createInAppNotification(userId, notification) {
    const doc = {
      userId,
      read: false,
      ...notification,
      createdAt: FieldValue.serverTimestamp(),
    };

    await db.collection(collections.NOTIFICATIONS).add(doc);
  }

  async sendPushToUser(userId, title, body, data = {}) {
    const tokens = await this.getUserTokens(userId);
    if (!tokens.length) return;

    await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, typeof v === "string" ? v : JSON.stringify(v)])
      ),
    });
  }

  async notifyUser(userId, { title, body, type, data = {} }) {
    await this.createInAppNotification(userId, { title, body, type, data });
    await this.sendPushToUser(userId, title, body, data);
  }

  async sendMatchNotification(match, trip, request) {
    const travelerId = match.travelerId;
    const requesterId = match.requesterId;

    const title = "New match found";
    const body = `Trip to ${trip.destinationCity} matches request: ${request.title}`;

    const data = { matchId: match.id, tripId: match.tripId, requestId: match.requestId };

    await Promise.all([
      this.notifyUser(travelerId, { type: "match_created", title, body, data }),
      this.notifyUser(requesterId, { type: "match_created", title, body, data }),
    ]);
  }

  async sendMatchAcceptedNotification(match, acceptedByName, otherUserId) {
    await this.notifyUser(otherUserId, {
      type: "match_accepted",
      title: "Match accepted",
      body: `${acceptedByName} accepted the match.`,
      data: { matchId: match.id },
    });
  }

  async sendDeliveryCompletedNotification(match, otherUserId) {
    await this.notifyUser(otherUserId, {
      type: "delivery_completed",
      title: "Delivery completed",
      body: "The delivery has been marked as completed.",
      data: { matchId: match.id },
    });
  }

  async sendMessageNotification(matchId, senderId, senderName, recipientId, messageContent) {
    await this.notifyUser(recipientId, {
      type: "message",
      title: `New message from ${senderName}`,
      body: (messageContent || "").substring(0, 120),
      data: { matchId, senderId },
    });
  }

  async sendReviewNotification(userId, reviewerName, rating) {
    await this.notifyUser(userId, {
      type: "review",
      title: "New review received",
      body: `${reviewerName} left you a ${rating}-star review.`,
      data: { rating: String(rating) },
    });
  }
}

module.exports = new NotificationService();