import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';
import '../../data/models/message_model.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatBloc _chatBloc;
  late final MatchBloc _matchBloc;
  final _scrollController = ScrollController();
  final _editController = TextEditingController();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _chatBloc = GetIt.instance<ChatBloc>();
    _matchBloc = GetIt.instance<MatchBloc>();

    // Get current user ID directly from FirebaseService (the source of truth)
    // DO NOT use GetIt.instance<AuthBloc>() - it creates a new instance!
    final firebaseService = GetIt.instance<FirebaseService>();
    _currentUserId = firebaseService.currentUser?.uid ?? '';

    _chatBloc.add(ChatMessagesRequested(widget.matchId));
    _matchBloc.add(MatchDetailsRequested(widget.matchId));

    // Mark messages as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatBloc.add(ChatMarkAsReadRequested(widget.matchId));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSendText(String text) {
    _chatBloc.add(ChatSendMessageRequested(
      matchId: widget.matchId,
      content: text,
    ));
  }

  void _handleSendImage(File image) {
    _chatBloc.add(ChatSendImageRequested(
      matchId: widget.matchId,
      imageFile: image,
    ));
  }

  void _handleDeleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _chatBloc.add(ChatDeleteMessageRequested(
                matchId: widget.matchId,
                messageId: message.id,
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleEditMessage(MessageModel message) {
    _editController.text = message.content;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: _editController,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newContent = _editController.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                _chatBloc.add(ChatEditMessageRequested(
                  matchId: widget.matchId,
                  messageId: message.id,
                  newContent: newContent,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _chatBloc),
        BlocProvider.value(value: _matchBloc),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchDetailsLoaded) {
            final match = state.match;
            final otherName = match.getOtherParticipantName(_currentUserId);
            final otherPhoto = match.getOtherParticipantPhoto(_currentUserId);

            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: otherPhoto.isNotEmpty
                      ? ClipOval(
                          child: CachedImage(
                            url: CloudinaryService.getProfileThumbUrl(otherPhoto),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(otherName.isNotEmpty ? otherName[0] : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        match.itemTitle,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Text('Chat');
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatMessagesLoaded || state is ChatMessageSent) {
          _scrollToBottom();
        }
        if (state is ChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        List<MessageModel> messages = [];

        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChatMessagesLoaded) {
          messages = state.messages;
        } else if (state is ChatSendingMessage ||
            state is ChatSendingImage ||
            state is ChatMessageSent) {
          messages = (state as dynamic).messages;
        } else if (state is ChatError) {
          messages = state.messages;
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return BlocBuilder<MatchBloc, MatchState>(
          builder: (context, matchState) {
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final showDateSeparator = _shouldShowDateSeparator(
                  messages,
                  index,
                );

                return Column(
                  children: [
                    if (showDateSeparator) _buildDateSeparator(message.createdAt),
                    MessageBubble(
                      message: message,
                      isMine: message.senderId == _currentUserId,
                      onImageTap: message.type == MessageType.image
                          ? () => _showFullImage(message.imageUrl!)
                          : null,
                      onEdit: message.senderId == _currentUserId && message.canModify && message.type == MessageType.text
                          ? () => _handleEditMessage(message)
                          : null,
                      onDelete: message.senderId == _currentUserId && message.canModify
                          ? () => _handleDeleteMessage(message)
                          : null,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == 0) return true;

    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;

    return !_isSameDay(current, previous);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String text;

    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = DateFormat.yMMMd().format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedImage(
                url: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isSending =
            state is ChatSendingMessage || state is ChatSendingImage;

        return ChatInput(
          onSendText: _handleSendText,
          onSendImage: _handleSendImage,
          isSending: isSending,
        );
      },
    );
  }
}
