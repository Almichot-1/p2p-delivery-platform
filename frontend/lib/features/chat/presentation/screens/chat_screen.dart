import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;

  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    context.read<ChatBloc>().add(ChatMarkAsReadRequested(widget.matchId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;

    context.read<ChatBloc>().add(
          ChatSendMessageRequested(
            matchId: widget.matchId,
            content: content.trim(),
          ),
        );

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickAndSendImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (pickedFile != null) {
      context.read<ChatBloc>().add(
            ChatSendImageRequested(
              matchId: widget.matchId,
              imageFile: File(pickedFile.path),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ChatBloc>()..add(ChatMessagesRequested(widget.matchId)),
        ),
        BlocProvider(
          create: (_) =>
              getIt<MatchBloc>()..add(MatchDetailsRequested(widget.matchId)),
        ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatMessagesLoaded) {
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      _scrollToBottom,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const LoadingWidget();
                  }

                  if (state is ChatError) {
                    return Center(child: Text(state.message));
                  }

                  if (state is ChatMessagesLoaded) {
                    if (state.messages.isEmpty) {
                      return _buildEmptyChat();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isMine = message.senderId == currentUserId;

                        // Check if we should show date separator
                        bool showDate = false;
                        if (index == 0) {
                          showDate = true;
                        } else {
                          final prevMessage = state.messages[index - 1];
                          showDate = !_isSameDay(
                            message.createdAt,
                            prevMessage.createdAt,
                          );
                        }

                        return Column(
                          children: [
                            if (showDate)
                              _buildDateSeparator(message.createdAt),
                            MessageBubble(
                              message: message,
                              isMine: isMine,
                            ),
                          ],
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Image sending indicator
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatImageSending) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    color: AppColors.grey100,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Sending image...'),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Input field
            ChatInput(
              onSend: _sendMessage,
              onImagePick: _pickAndSendImage,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchDetailsLoaded) {
            final match = state.match;
            final authState = context.read<AuthBloc>().state;
            final currentUserId =
                authState is AuthAuthenticated ? authState.user.uid : '';

            final otherName = match.getOtherParticipantName(currentUserId);
            final otherPhoto = match.getOtherParticipantPhoto(currentUserId);

            return Row(
              children: [
                UserAvatar(
                  imageUrl: otherPhoto,
                  name: otherName,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        match.itemTitle,
                        style: AppTextStyles.caption,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            // Show match details
          },
        ),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.h5.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: AppTextStyles.caption,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
