import 'package:equatable/equatable.dart';

import '../data/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatMessagesLoaded extends ChatState {
  const ChatMessagesLoaded(this.messages);

  final List<MessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatSendingMessage extends ChatState {
  const ChatSendingMessage(this.messages);

  final List<MessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatSendingImage extends ChatState {
  const ChatSendingImage(this.messages);

  final List<MessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatMessageSent extends ChatState {
  const ChatMessageSent(this.messages);

  final List<MessageModel> messages;

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  const ChatError(this.message, [this.messages = const []]);

  final String message;
  final List<MessageModel> messages;

  @override
  List<Object?> get props => [message, messages];
}
