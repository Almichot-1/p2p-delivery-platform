import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/notification_bloc.dart';
import '../../bloc/notification_event.dart';
import '../../bloc/notification_state.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in')),
          );
        }

        return BlocProvider(
          create: (_) => GetIt.instance<NotificationBloc>()
            ..add(NotificationsLoadRequested(authState.user.uid)),
          child: _NotificationsView(userId: authState.user.uid),
        );
      },
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      NotificationMarkAllAsReadRequested(userId),
                    );
                  },
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearDialog(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                        NotificationsLoadRequested(userId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(
                  NotificationsLoadRequested(userId),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, notification),
                    onDismiss: () {
                      context.read<NotificationBloc>().add(
                        NotificationDeleteRequested(notification.id),
                      );
                    },
                  );
                },
              ),
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see updates about your matches and deliveries here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationBloc>().add(
                NotificationDeleteAllRequested(userId),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        NotificationMarkAsReadRequested(notification.id),
      );
    }

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.matchRequest:
      case NotificationType.matchAccepted:
      case NotificationType.matchRejected:
      case NotificationType.matchConfirmed:
      case NotificationType.statusUpdate:
        if (notification.matchId != null) {
          context.push('${RoutePaths.matches}/${notification.matchId}');
        }
        break;
      case NotificationType.newMessage:
        if (notification.matchId != null) {
          context.push('${RoutePaths.chat}/${notification.matchId}');
        }
        break;
      case NotificationType.system:
        // No navigation for system notifications
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      child: ListTile(
        onTap: onTap,
        tileColor: isUnread ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
        leading: _buildIcon(context),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (notification.type) {
      NotificationType.matchRequest => (Icons.person_add, Colors.blue),
      NotificationType.matchAccepted => (Icons.check_circle, Colors.green),
      NotificationType.matchRejected => (Icons.cancel, Colors.red),
      NotificationType.matchConfirmed => (Icons.handshake, Colors.green),
      NotificationType.newMessage => (Icons.message, Colors.blue),
      NotificationType.statusUpdate => (Icons.local_shipping, Colors.orange),
      NotificationType.system => (Icons.info, theme.colorScheme.primary),
    };

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(time);
  }
}
