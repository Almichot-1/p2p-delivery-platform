import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatMessagesRequested extends ChatEvent {
  const ChatMessagesRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

class ChatSendMessageRequested extends ChatEvent {
  const ChatSendMessageRequested({
    required this.matchId,
    required this.content,
  });

  final String matchId;
  final String content;

  @override
  List<Object?> get props => [matchId, content];
}

class ChatSendImageRequested extends ChatEvent {
  const ChatSendImageRequested({
    required this.matchId,
    required this.imageFile,
  });

  final String matchId;
  final File imageFile;

  @override
  List<Object?> get props => [matchId, imageFile];
}

class ChatMarkAsReadRequested extends ChatEvent {
  const ChatMarkAsReadRequested(this.matchId);

  final String matchId;

  @override
  List<Object?> get props => [matchId];
}

class ChatDeleteMessageRequested extends ChatEvent {
  const ChatDeleteMessageRequested({
    required this.matchId,
    required this.messageId,
  });

  final String matchId;
  final String messageId;

  @override
  List<Object?> get props => [matchId, messageId];
}

class ChatEditMessageRequested extends ChatEvent {
  const ChatEditMessageRequested({
    required this.matchId,
    required this.messageId,
    required this.newContent,
  });

  final String matchId;
  final String messageId;
  final String newContent;

  @override
  List<Object?> get props => [matchId, messageId, newContent];
}
