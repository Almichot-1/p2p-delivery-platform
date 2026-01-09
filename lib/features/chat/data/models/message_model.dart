import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType { text, image, system }

class MessageModel extends Equatable {
  const MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.isRead,
    this.isEdited = false,
    required this.createdAt,
  });

  final String id;
  final String matchId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final String? imageUrl;
  final bool isRead;
  final bool isEdited;
  final DateTime createdAt;

  /// Check if message can be edited/deleted (within 12 hours)
  bool get canModify {
    final hoursSince = DateTime.now().difference(createdAt).inHours;
    return hoursSince < 12;
  }

  static MessageType _parseType(dynamic v) {
    final s = (v ?? '').toString();
    for (final t in MessageType.values) {
      if (t.name == s) return t;
    }
    return MessageType.text;
  }

  static DateTime _tsToDate(dynamic v, {required DateTime fallback}) {
    if (v is Timestamp) return v.toDate();
    return fallback;
  }

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Message document is empty for id=${doc.id}');
    }

    final fallback = DateTime.now();

    return MessageModel(
      id: data['id']?.toString() ?? doc.id,
      matchId: data['matchId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      type: _parseType(data['type']),
      imageUrl: data['imageUrl']?.toString(),
      isRead: data['isRead'] == true,
      isEdited: data['isEdited'] == true,
      createdAt: _tsToDate(data['createdAt'], fallback: fallback),
    );
  }


  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'matchId': matchId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'isEdited': isEdited,
      'createdAt': Timestamp.fromDate(createdAt),
    }..removeWhere((_, v) => v == null);
  }

  MessageModel copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    String? imageUrl,
    bool? isRead,
    bool? isEdited,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isMine(String currentUserId) => senderId == currentUserId;

  @override
  List<Object?> get props => [
        id,
        matchId,
        senderId,
        senderName,
        content,
        type,
        imageUrl,
        isRead,
        isEdited,
        createdAt,
      ];
}
