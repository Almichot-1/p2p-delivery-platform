import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/storage_service.dart';
import '../models/message_model.dart';

class ChatRepository {
  final FirebaseService _firebaseService;
  final StorageService _storageService;

  ChatRepository(this._firebaseService, this._storageService);

  // Get messages for a match
  Stream<List<MessageModel>> getMessages(String matchId) {
    return _firebaseService.matchesCollection
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send text message
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final message = MessageModel(
      id: '',
      matchId: matchId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: MessageType.text,
      createdAt: DateTime.now(),
    );

    await _firebaseService.matchesCollection
        .doc(matchId)
        .collection('messages')
        .add(message.toFirestore());

    // Update last message in match
    await _firebaseService.matchesCollection.doc(matchId).update({
      'lastMessage': content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });
  }

  // Send image message
  Future<void> sendImageMessage({
    required String matchId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    // Upload image
    final imageUrl = await _storageService.uploadChatImage(imageFile, matchId);

    final message = MessageModel(
      id: '',
      matchId: matchId,
      senderId: senderId,
      senderName: senderName,
      content: '📷 Image',
      type: MessageType.image,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    await _firebaseService.matchesCollection
        .doc(matchId)
        .collection('messages')
        .add(message.toFirestore());

    // Update last message
    await _firebaseService.matchesCollection.doc(matchId).update({
      'lastMessage': '📷 Image',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String matchId, String currentUserId) async {
    final batch = _firebaseService.firestore.batch();

    final unreadMessages = await _firebaseService.matchesCollection
        .doc(matchId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Get unread count
  Stream<int> getUnreadCount(String matchId, String currentUserId) {
    return _firebaseService.matchesCollection
        .doc(matchId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
