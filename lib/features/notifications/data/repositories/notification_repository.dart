import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firebase_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._firebaseService);

  final FirebaseService _firebaseService;

  CollectionReference<Map<String, dynamic>> get _ref => _firebaseService.notifications;

  /// Stream of notifications for a user, ordered by newest first
  Stream<List<NotificationModel>> getNotifications(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    return _ref
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  /// Stream of unread count for a user
  Stream<int> getUnreadCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);

    return _ref
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _ref.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;

    final snap = await _ref
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _firebaseService.firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    if (notificationId.isEmpty) return;
    await _ref.doc(notificationId).delete();
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    if (userId.isEmpty) return;

    final snap = await _ref.where('userId', isEqualTo: userId).get();

    if (snap.docs.isEmpty) return;

    final batch = _firebaseService.firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Create a notification (typically called from backend/cloud functions,
  /// but useful for local testing or specific scenarios)
  Future<void> createNotification(NotificationModel notification) async {
    final docRef = _ref.doc();
    final n = NotificationModel(
      id: docRef.id,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      isRead: false,
      createdAt: DateTime.now(),
      matchId: notification.matchId,
      tripId: notification.tripId,
      requestId: notification.requestId,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderPhoto: notification.senderPhoto,
      data: notification.data,
    );
    await docRef.set(n.toFirestore());
  }

  /// Helper to create match request notification
  Future<void> notifyMatchRequest({
    required String recipientId,
    required String matchId,
    required String senderName,
    String? senderPhoto,
    required String itemTitle,
    required bool isForTraveler,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: recipientId,
      type: NotificationType.matchRequest,
      title: 'New Match Request',
      body: isForTraveler
          ? '$senderName wants you to deliver "$itemTitle"'
          : '$senderName wants to deliver your item "$itemTitle"',
      isRead: false,
      createdAt: DateTime.now(),
      matchId: matchId,
      senderId: null,
      senderName: senderName,
      senderPhoto: senderPhoto,
    );
    await createNotification(notification);
  }

  /// Helper to create match accepted notification
  Future<void> notifyMatchAccepted({
    required String recipientId,
    required String matchId,
    required String accepterName,
    String? accepterPhoto,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: recipientId,
      type: NotificationType.matchAccepted,
      title: 'Match Accepted!',
      body: '$accepterName accepted your match request',
      isRead: false,
      createdAt: DateTime.now(),
      matchId: matchId,
      senderName: accepterName,
      senderPhoto: accepterPhoto,
    );
    await createNotification(notification);
  }

  /// Helper to create match rejected notification
  Future<void> notifyMatchRejected({
    required String recipientId,
    required String matchId,
    required String rejecterName,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: recipientId,
      type: NotificationType.matchRejected,
      title: 'Match Declined',
      body: '$rejecterName declined your match request',
      isRead: false,
      createdAt: DateTime.now(),
      matchId: matchId,
      senderName: rejecterName,
    );
    await createNotification(notification);
  }

  /// Helper to create new message notification
  Future<void> notifyNewMessage({
    required String recipientId,
    required String matchId,
    required String senderName,
    String? senderPhoto,
    required String messagePreview,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: recipientId,
      type: NotificationType.newMessage,
      title: 'New Message',
      body: '$senderName: $messagePreview',
      isRead: false,
      createdAt: DateTime.now(),
      matchId: matchId,
      senderName: senderName,
      senderPhoto: senderPhoto,
    );
    await createNotification(notification);
  }

  /// Helper to create status update notification
  Future<void> notifyStatusUpdate({
    required String recipientId,
    required String matchId,
    required String status,
    required String itemTitle,
  }) async {
    final statusText = switch (status) {
      'confirmed' => 'has been confirmed',
      'pickedUp' => 'has been picked up',
      'inTransit' => 'is now in transit',
      'delivered' => 'has been delivered',
      'completed' => 'is complete',
      _ => 'status updated',
    };

    final notification = NotificationModel(
      id: '',
      userId: recipientId,
      type: NotificationType.statusUpdate,
      title: 'Delivery Update',
      body: '"$itemTitle" $statusText',
      isRead: false,
      createdAt: DateTime.now(),
      matchId: matchId,
    );
    await createNotification(notification);
  }
}
