import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder notifications
    final notifications = <NotificationModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications',
              subtitle: 'You\'re all caught up!',
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getTypeColor(notification.type).withAlpha(26),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getTypeIcon(notification.type),
          color: _getTypeColor(notification.type),
        ),
      ),
      title: Text(
        notification.title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, HH:mm').format(notification.createdAt),
            style: AppTextStyles.caption,
          ),
        ],
      ),
      trailing: !notification.isRead
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      tileColor: notification.isRead ? null : AppColors.primary.withAlpha(13),
      onTap: () {
        // Handle notification tap
      },
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return Icons.handshake;
      case NotificationType.message:
        return Icons.chat;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return AppColors.success;
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.review:
        return AppColors.secondary;
      case NotificationType.system:
        return AppColors.info;
    }
  }
}
