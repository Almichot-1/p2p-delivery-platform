import 'package:flutter/material.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../matches/data/models/match_model.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.match,
    required this.currentUserId,
    this.unreadCount = 0,
    this.onTap,
  });

  final MatchModel match;
  final String currentUserId;
  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherName = match.getOtherParticipantName(currentUserId);
    final otherPhoto = match.getOtherParticipantPhoto(currentUserId);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: otherPhoto.isNotEmpty
            ? ClipOval(
                child: CachedImage(
                  url: CloudinaryService.getProfileThumbUrl(otherPhoto),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Text(
                otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                style: theme.textTheme.titleLarge,
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatTimeAgo(match.updatedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: unreadCount > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.itemTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  _getLastMessagePreview(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      trailing: _buildStatusIndicator(context),
    );
  }

  String _getLastMessagePreview() {
    // Match model doesn't have lastMessage field yet, so we show a placeholder
    return 'Tap to start chatting';
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatusColor(theme);

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (match.status) {
      case MatchStatus.confirmed:
        return Colors.blue;
      case MatchStatus.pickedUp:
      case MatchStatus.inTransit:
        return Colors.orange;
      case MatchStatus.delivered:
        return Colors.green;
      case MatchStatus.completed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
