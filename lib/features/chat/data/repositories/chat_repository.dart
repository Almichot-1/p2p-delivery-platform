import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../models/message_model.dart';

/// Valid match statuses that allow chat access.
const _chatAllowedStatuses = <String>{
  'confirmed',
  'pickedUp',
  'inTransit',
  'delivered',
  'completed',
};

class ChatRepository {
  ChatRepository(this._firebaseService, this._cloudinaryService);

  final FirebaseService _firebaseService;
  final CloudinaryService _cloudinaryService;

  CollectionReference<Map<String, dynamic>> _messagesRef(String matchId) {
    return _firebaseService.matches.doc(matchId).collection('messages');
  }

  /// Validates that the match exists, is in a chat-allowed status,
  /// and the sender is a participant.
  Future<void> _validateChatAccess(String matchId, String senderId) async {
    final matchDoc = await _firebaseService.matches.doc(matchId).get();
    
    if (!matchDoc.exists) {
      throw Exception('Match not found');
    }

    final data = matchDoc.data() ?? <String, dynamic>{};
    final status = data['status']?.toString() ?? '';
    final participants = List<String>.from(data['participants'] ?? <String>[]);

    if (!_chatAllowedStatuses.contains(status)) {
      throw Exception('Chat is only available for confirmed matches');
    }

    if (!participants.contains(senderId)) {
      throw Exception('You are not a participant in this match');
    }
  }

  Stream<List<MessageModel>> getMessages(String matchId) {
    final id = matchId.trim();
    if (id.isEmpty) return const Stream.empty();

    return _messagesRef(id)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final mId = matchId.trim();
    final sId = senderId.trim();
    final text = content.trim();

    if (mId.isEmpty) throw Exception('Match ID is required');
    if (sId.isEmpty) throw Exception('Sender ID is required');
    if (text.isEmpty) throw Exception('Message cannot be empty');

    // Validate chat access before sending
    await _validateChatAccess(mId, sId);

    final msgRef = _messagesRef(mId).doc();
    final now = DateTime.now();

    final message = MessageModel(
      id: msgRef.id,
      matchId: mId,
      senderId: sId,
      senderName: senderName,
      content: text,
      type: MessageType.text,
      isRead: false,
      createdAt: now,
    );

    await msgRef.set(message.toFirestore());

    // Update match with last message info
    await _firebaseService.matches.doc(mId).set(
      <String, dynamic>{
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }


  Future<void> sendImageMessage({
    required String matchId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    final mId = matchId.trim();
    final sId = senderId.trim();

    if (mId.isEmpty) throw Exception('Match ID is required');
    if (sId.isEmpty) throw Exception('Sender ID is required');

    // Validate chat access before sending
    await _validateChatAccess(mId, sId);

    // Upload to Cloudinary first
    final imageUrl = await _cloudinaryService.uploadChatImage(imageFile, mId);

    final msgRef = _messagesRef(mId).doc();
    final now = DateTime.now();

    final message = MessageModel(
      id: msgRef.id,
      matchId: mId,
      senderId: sId,
      senderName: senderName,
      content: '📷 Photo',
      type: MessageType.image,
      imageUrl: imageUrl,
      isRead: false,
      createdAt: now,
    );

    await msgRef.set(message.toFirestore());

    // Update match with last message info
    await _firebaseService.matches.doc(mId).set(
      <String, dynamic>{
        'lastMessage': '📷 Photo',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markMessagesAsRead(String matchId, String currentUserId) async {
    final mId = matchId.trim();
    final uid = currentUserId.trim();

    if (mId.isEmpty || uid.isEmpty) return;

    // Get all unread messages not from current user
    final snap = await _messagesRef(mId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _firebaseService.firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String matchId, String currentUserId) {
    final mId = matchId.trim();
    final uid = currentUserId.trim();

    if (mId.isEmpty || uid.isEmpty) return Stream.value(0);

    return _messagesRef(mId)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> sendSystemMessage({
    required String matchId,
    required String content,
  }) async {
    final mId = matchId.trim();
    if (mId.isEmpty) return;

    final msgRef = _messagesRef(mId).doc();
    final now = DateTime.now();

    final message = MessageModel(
      id: msgRef.id,
      matchId: mId,
      senderId: 'system',
      senderName: 'System',
      content: content,
      type: MessageType.system,
      isRead: true,
      createdAt: now,
    );

    await msgRef.set(message.toFirestore());
  }

  /// Delete a message (only within 12 hours of sending)
  Future<void> deleteMessage({
    required String matchId,
    required String messageId,
    required String senderId,
  }) async {
    final mId = matchId.trim();
    final msgId = messageId.trim();
    final sId = senderId.trim();

    if (mId.isEmpty || msgId.isEmpty || sId.isEmpty) {
      throw Exception('Invalid parameters');
    }

    final msgRef = _messagesRef(mId).doc(msgId);
    final msgDoc = await msgRef.get();

    if (!msgDoc.exists) {
      throw Exception('Message not found');
    }

    final data = msgDoc.data() ?? {};
    final msgSenderId = data['senderId']?.toString() ?? '';
    
    if (msgSenderId != sId) {
      throw Exception('You can only delete your own messages');
    }

    // Check 12-hour window
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      final messageTime = createdAt.toDate();
      final hoursSince = DateTime.now().difference(messageTime).inHours;
      if (hoursSince >= 12) {
        throw Exception('Messages can only be deleted within 12 hours');
      }
    }

    await msgRef.delete();
  }

  /// Edit a message (only within 12 hours of sending)
  Future<void> editMessage({
    required String matchId,
    required String messageId,
    required String senderId,
    required String newContent,
  }) async {
    final mId = matchId.trim();
    final msgId = messageId.trim();
    final sId = senderId.trim();
    final content = newContent.trim();

    if (mId.isEmpty || msgId.isEmpty || sId.isEmpty) {
      throw Exception('Invalid parameters');
    }

    if (content.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final msgRef = _messagesRef(mId).doc(msgId);
    final msgDoc = await msgRef.get();

    if (!msgDoc.exists) {
      throw Exception('Message not found');
    }

    final data = msgDoc.data() ?? {};
    final msgSenderId = data['senderId']?.toString() ?? '';
    final msgType = data['type']?.toString() ?? '';
    
    if (msgSenderId != sId) {
      throw Exception('You can only edit your own messages');
    }

    if (msgType != 'text') {
      throw Exception('Only text messages can be edited');
    }

    // Check 12-hour window
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      final messageTime = createdAt.toDate();
      final hoursSince = DateTime.now().difference(messageTime).inHours;
      if (hoursSince >= 12) {
        throw Exception('Messages can only be edited within 12 hours');
      }
    }

    await msgRef.update({
      'content': content,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }
}
