import '../../../../core/services/firebase_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseService _firebaseService;

  NotificationRepository(this._firebaseService);

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _firebaseService.notificationsCollection
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firebaseService.firestore.batch();

    final unreadNotifications = await _firebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firebaseService.notificationsCollection.doc(notificationId).delete();
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    final batch = _firebaseService.firestore.batch();

    final notifications = await _firebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Create notification (usually called from Cloud Functions)
  Future<void> createNotification(NotificationModel notification) async {
    await _firebaseService.notificationsCollection
        .add(notification.toFirestore());
  }
}
