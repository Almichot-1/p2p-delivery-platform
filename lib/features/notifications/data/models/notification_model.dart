import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  matchRequest,    // Someone requested to match with your trip/request
  matchAccepted,   // Your match request was accepted
  matchRejected,   // Your match request was rejected
  matchConfirmed,  // Match was confirmed
  newMessage,      // New chat message
  statusUpdate,    // Delivery status changed
  system,          // System notification
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.matchId,
    this.tripId,
    this.requestId,
    this.senderId,
    this.senderName,
    this.senderPhoto,
    this.data,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? matchId;
  final String? tripId;
  final String? requestId;
  final String? senderId;
  final String? senderName;
  final String? senderPhoto;
  final Map<String, dynamic>? data;

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return NotificationModel(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      type: _parseType(d['type']?.toString()),
      title: d['title']?.toString() ?? '',
      body: d['body']?.toString() ?? '',
      isRead: d['isRead'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      matchId: d['matchId']?.toString(),
      tripId: d['tripId']?.toString(),
      requestId: d['requestId']?.toString(),
      senderId: d['senderId']?.toString(),
      senderName: d['senderName']?.toString(),
      senderPhoto: d['senderPhoto']?.toString(),
      data: d['data'] is Map ? Map<String, dynamic>.from(d['data']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.name,
    'title': title,
    'body': body,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    if (matchId != null) 'matchId': matchId,
    if (tripId != null) 'tripId': tripId,
    if (requestId != null) 'requestId': requestId,
    if (senderId != null) 'senderId': senderId,
    if (senderName != null) 'senderName': senderName,
    if (senderPhoto != null) 'senderPhoto': senderPhoto,
    if (data != null) 'data': data,
  };

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    String? matchId,
    String? tripId,
    String? requestId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      matchId: matchId ?? this.matchId,
      tripId: tripId ?? this.tripId,
      requestId: requestId ?? this.requestId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      data: data ?? this.data,
    );
  }

  static NotificationType _parseType(String? s) {
    return NotificationType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => NotificationType.system,
    );
  }
}
