import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/firebase_service.dart';
import '../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final FirebaseService _firebaseService;
  StreamSubscription? _messagesSubscription;

  ChatBloc(this._chatRepository)
      : _firebaseService = FirebaseService(),
        super(ChatInitial()) {
    on<ChatMessagesRequested>(_onMessagesRequested);
    on<ChatSendMessageRequested>(_onSendMessageRequested);
    on<ChatSendImageRequested>(_onSendImageRequested);
    on<ChatMarkAsReadRequested>(_onMarkAsReadRequested);
  }

  Future<void> _onMessagesRequested(
    ChatMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());

    await _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.getMessages(event.matchId).listen(
          (messages) => emit(ChatMessagesLoaded(messages)),
          onError: (error) => emit(ChatError(error.toString())),
        );
  }

  Future<void> _onSendMessageRequested(
    ChatSendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      await _chatRepository.sendMessage(
        matchId: event.matchId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        content: event.content,
      );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendImageRequested(
    ChatSendImageRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatImageSending());

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      await _chatRepository.sendImageMessage(
        matchId: event.matchId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'User',
        imageFile: event.imageFile,
      );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onMarkAsReadRequested(
    ChatMarkAsReadRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentUserId = _firebaseService.currentUserId;
      if (currentUserId == null) return;

      await _chatRepository.markMessagesAsRead(event.matchId, currentUserId);
    } catch (e) {
      // Silent fail for read receipts
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
