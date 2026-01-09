import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/firebase_service.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatRepository chatRepository,
    required FirebaseService firebaseService,
  })  : _chatRepository = chatRepository,
        _firebaseService = firebaseService,
        super(const ChatInitial()) {
    on<ChatMessagesRequested>(_onMessagesRequested);
    on<ChatSendMessageRequested>(_onSendMessageRequested);
    on<ChatSendImageRequested>(_onSendImageRequested);
    on<ChatMarkAsReadRequested>(_onMarkAsReadRequested);
    on<ChatDeleteMessageRequested>(_onDeleteMessageRequested);
    on<ChatEditMessageRequested>(_onEditMessageRequested);
    on<_MessagesStreamUpdated>(_onMessagesStreamUpdated);
    on<_MessagesStreamFailed>(_onMessagesStreamFailed);
  }

  final ChatRepository _chatRepository;
  final FirebaseService _firebaseService;

  StreamSubscription<List<MessageModel>>? _messagesSub;
  List<MessageModel> _lastMessages = const [];

  String? get _currentUserId => _firebaseService.currentUser?.uid;
  String get _currentUserName =>
      _firebaseService.currentUser?.displayName ?? 'User';

  Future<void> _onMessagesRequested(
    ChatMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    await _messagesSub?.cancel();
    _messagesSub = _chatRepository.getMessages(event.matchId).listen(
          (messages) => add(_MessagesStreamUpdated(messages)),
          onError: (e) => add(_MessagesStreamFailed(e.toString())),
        );
  }


  Future<void> _onSendMessageRequested(
    ChatSendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final uid = _currentUserId;
    if (uid == null) {
      emit(ChatError('You must be logged in', _lastMessages));
      return;
    }

    emit(ChatSendingMessage(_lastMessages));

    try {
      await _chatRepository.sendMessage(
        matchId: event.matchId,
        senderId: uid,
        senderName: _currentUserName,
        content: event.content,
      );
      emit(ChatMessageSent(_lastMessages));
    } catch (e) {
      emit(ChatError(
        e.toString().replaceFirst('Exception: ', ''),
        _lastMessages,
      ));
    }
  }

  Future<void> _onSendImageRequested(
    ChatSendImageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final uid = _currentUserId;
    if (uid == null) {
      emit(ChatError('You must be logged in', _lastMessages));
      return;
    }

    emit(ChatSendingImage(_lastMessages));

    try {
      await _chatRepository.sendImageMessage(
        matchId: event.matchId,
        senderId: uid,
        senderName: _currentUserName,
        imageFile: event.imageFile,
      );
      emit(ChatMessageSent(_lastMessages));
    } catch (e) {
      emit(ChatError(
        e.toString().replaceFirst('Exception: ', ''),
        _lastMessages,
      ));
    }
  }

  Future<void> _onMarkAsReadRequested(
    ChatMarkAsReadRequested event,
    Emitter<ChatState> emit,
  ) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      await _chatRepository.markMessagesAsRead(event.matchId, uid);
    } catch (_) {
      // Silent fail for mark as read
    }
  }

  Future<void> _onDeleteMessageRequested(
    ChatDeleteMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final uid = _currentUserId;
    if (uid == null) {
      emit(ChatError('You must be logged in', _lastMessages));
      return;
    }

    try {
      await _chatRepository.deleteMessage(
        matchId: event.matchId,
        messageId: event.messageId,
        senderId: uid,
      );
      // Stream will update automatically
    } catch (e) {
      emit(ChatError(
        e.toString().replaceFirst('Exception: ', ''),
        _lastMessages,
      ));
    }
  }

  Future<void> _onEditMessageRequested(
    ChatEditMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final uid = _currentUserId;
    if (uid == null) {
      emit(ChatError('You must be logged in', _lastMessages));
      return;
    }

    try {
      await _chatRepository.editMessage(
        matchId: event.matchId,
        messageId: event.messageId,
        senderId: uid,
        newContent: event.newContent,
      );
      // Stream will update automatically
    } catch (e) {
      emit(ChatError(
        e.toString().replaceFirst('Exception: ', ''),
        _lastMessages,
      ));
    }
  }

  void _onMessagesStreamUpdated(
    _MessagesStreamUpdated event,
    Emitter<ChatState> emit,
  ) {
    _lastMessages = event.messages;
    emit(ChatMessagesLoaded(event.messages));
  }

  void _onMessagesStreamFailed(
    _MessagesStreamFailed event,
    Emitter<ChatState> emit,
  ) {
    emit(ChatError(
      event.message.replaceFirst('Exception: ', ''),
      _lastMessages,
    ));
  }

  @override
  Future<void> close() async {
    await _messagesSub?.cancel();
    return super.close();
  }
}

class _MessagesStreamUpdated extends ChatEvent {
  const _MessagesStreamUpdated(this.messages);

  final List<MessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

class _MessagesStreamFailed extends ChatEvent {
  const _MessagesStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
