import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseService _firebaseService;

  NotificationService(this._firebaseService);

  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('NotificationService.initialize marker: 2025-12-24');
    }
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        try {
          await _saveToken(token);
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'Failed to save initial FCM token (non-fatal): $error\n$stackTrace',
            );
          }
        }
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) async {
        try {
          await _saveToken(token);
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              'Failed to save refreshed FCM token (non-fatal): $error\n$stackTrace',
            );
          }
        }
      });
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  Future<void> _saveToken(String token) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return;

    try {
      await _firebaseService.usersCollection.doc(userId).set(
        {
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to save FCM token: $error\n$stackTrace');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
    if (kDebugMode) {
      debugPrint('Background message: ${message.messageId}');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on message data
    final data = message.data;
    final type = data['type'];

    // Handle navigation based on notification type
    switch (type) {
      case 'match':
        // Navigate to match details
        break;
      case 'message':
        // Navigate to chat
        break;
      case 'request':
        // Navigate to request details
        break;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle local notification tap
    if (response.payload != null) {
      // Parse payload and navigate
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'diaspora_delivery',
      'Diaspora Delivery',
      channelDescription: 'Notifications for Diaspora Delivery app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
