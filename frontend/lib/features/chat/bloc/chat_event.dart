import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatMessagesRequested extends ChatEvent {
  final String matchId;

  const ChatMessagesRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class ChatSendMessageRequested extends ChatEvent {
  final String matchId;
  final String content;

  const ChatSendMessageRequested({
    required this.matchId,
    required this.content,
  });

  @override
  List<Object> get props => [matchId, content];
}

class ChatSendImageRequested extends ChatEvent {
  final String matchId;
  final File imageFile;

  const ChatSendImageRequested({
    required this.matchId,
    required this.imageFile,
  });

  @override
  List<Object> get props => [matchId, imageFile];
}

class ChatMarkAsReadRequested extends ChatEvent {
  final String matchId;

  const ChatMarkAsReadRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}
