import 'package:flutter/material.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../data/models/request_model.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
  });

  final RequestModel request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final thumbUrl = request.imageUrls.isNotEmpty
        ? CloudinaryService.getItemThumbUrl(request.imageUrls.first)
        : null;

    final timeAgo = formatTimeAgo(request.createdAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thumbUrl == null)
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined),
                    )
                  else
                    CachedImage(
                      url: thumbUrl,
                      height: 72,
                      width: 72,
                      borderRadius: BorderRadius.circular(12),
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(status: request.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.description,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: scheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.routeDisplay,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (request.isUrgent) ...[
                              const SizedBox(width: 8),
                              _UrgentBadge(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _InfoPill(
                    icon: Icons.category_outlined,
                    text: request.categoryDisplay,
                  ),
                  _InfoPill(
                    icon: Icons.scale_outlined,
                    text: '${request.weightKg.toStringAsFixed(1)} kg',
                  ),
                  if (request.offeredPrice != null)
                    _InfoPill(
                      icon: Icons.payments_outlined,
                      text: request.offeredPrice!.toStringAsFixed(2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ProfileImage(
                    displayName: request.requesterName,
                    imageUrl: request.requesterPhoto,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requesterName,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.star, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    request.requesterRating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _UrgentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Urgent',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onErrorContainer,
            ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String label;
    switch (status) {
      case RequestStatus.active:
        label = 'Active';
      case RequestStatus.matched:
        label = 'Matched';
      case RequestStatus.inProgress:
        label = 'In progress';
      case RequestStatus.completed:
        label = 'Completed';
      case RequestStatus.cancelled:
        label = 'Cancelled';
    }

    final bg = switch (status) {
      RequestStatus.active => scheme.primaryContainer,
      RequestStatus.matched => scheme.secondaryContainer,
      RequestStatus.inProgress => scheme.tertiaryContainer,
      RequestStatus.completed => scheme.secondaryContainer,
      RequestStatus.cancelled => scheme.errorContainer,
    };

    final fg = switch (status) {
      RequestStatus.active => scheme.onPrimaryContainer,
      RequestStatus.matched => scheme.onSecondaryContainer,
      RequestStatus.inProgress => scheme.onTertiaryContainer,
      RequestStatus.completed => scheme.onSecondaryContainer,
      RequestStatus.cancelled => scheme.onErrorContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
