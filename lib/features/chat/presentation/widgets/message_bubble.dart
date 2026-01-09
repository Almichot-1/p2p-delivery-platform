import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onImageTap,
    this.onEdit,
    this.onDelete,
  });

  final MessageModel message;
  final bool isMine;
  final VoidCallback? onImageTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // System messages are centered
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: isMine && message.canModify ? () => _showOptions(context) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isMine
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildContent(context),
                    _buildTimestamp(context),
                  ],
                ),
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit message'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    if (message.type == MessageType.image && message.imageUrl != null) {
      final imageUrl = CloudinaryService.getChatImageUrl(message.imageUrl!);
      return GestureDetector(
        onTap: onImageTap,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isMine
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    final timeStr = DateFormat.jm().format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isEdited) ...[
            Text(
              'edited',
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            timeStr,
            style: theme.textTheme.labelSmall?.copyWith(color: textColor),
          ),
          if (isMine) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead
                  ? (isMine ? Colors.lightBlueAccent : Colors.blue)
                  : textColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
