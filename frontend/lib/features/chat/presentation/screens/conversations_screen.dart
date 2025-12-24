import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../../matches/data/models/match_model.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return BlocProvider(
      create: (_) =>
          getIt<MatchBloc>()..add(MatchesLoadRequested(authState.user.uid)),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const LoadingWidget();
          }

          if (state is MatchError) {
            return Center(child: Text(state.message));
          }

          if (state is MatchesLoaded) {
            // Filter only matches with chat enabled (confirmed or later)
            final chatMatches = state.matches
                .where((m) =>
                    m.status == MatchStatus.confirmed ||
                    m.status == MatchStatus.pickedUp ||
                    m.status == MatchStatus.inTransit ||
                    m.status == MatchStatus.delivered ||
                    m.status == MatchStatus.completed)
                .toList();

            if (chatMatches.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.chat_bubble_outline,
                title: 'No Conversations',
                subtitle: 'Your conversations will appear here after matching',
              );
            }

            return ListView.separated(
              itemCount: chatMatches.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final match = chatMatches[index];
                return _ConversationTile(
                  match: match,
                  onTap: () => context.push(
                    RouteConstants.chat.replaceFirst(':matchId', match.id),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.uid : '';

    final otherName = match.getOtherParticipantName(currentUserId);
    final otherPhoto = match.getOtherParticipantPhoto(currentUserId);

    return ListTile(
      onTap: onTap,
      leading: UserAvatar(
        imageUrl: otherPhoto,
        name: otherName,
        size: 50,
      ),
      title: Text(
        otherName,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        match.itemTitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.grey600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(match.updatedAt ?? match.createdAt),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(match.status).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match.status.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: _getStatusColor(match.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.confirmed:
        return AppColors.success;
      case MatchStatus.pickedUp:
      case MatchStatus.inTransit:
        return AppColors.info;
      case MatchStatus.delivered:
      case MatchStatus.completed:
        return AppColors.success;
      default:
        return AppColors.grey500;
    }
  }
}
