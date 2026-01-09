import 'package:flutter/material.dart';

import '../../data/models/match_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.currentUserId,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  final MatchModel match;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  bool get _isTraveler => currentUserId == match.travelerId;

  String get _roleLabel {
    // Show the OTHER person's role, not the current user's role
    return _isTraveler ? 'Requester' : 'Traveler';
  }

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    return switch (match.status) {
      MatchStatus.pending => theme.colorScheme.tertiary,
      MatchStatus.accepted => theme.colorScheme.primary,
      MatchStatus.confirmed => theme.colorScheme.primary,
      MatchStatus.pickedUp => theme.colorScheme.primary,
      MatchStatus.inTransit => theme.colorScheme.primary,
      MatchStatus.delivered => theme.colorScheme.primary,
      MatchStatus.completed => theme.colorScheme.secondary,
      MatchStatus.cancelled => theme.colorScheme.error,
      MatchStatus.rejected => theme.colorScheme.error,
    };
  }

  String _statusLabel() {
    return switch (match.status) {
      MatchStatus.pending => 'Pending',
      MatchStatus.accepted => 'Accepted',
      MatchStatus.confirmed => 'Confirmed',
      MatchStatus.pickedUp => 'Picked Up',
      MatchStatus.inTransit => 'In Transit',
      MatchStatus.delivered => 'Delivered',
      MatchStatus.completed => 'Completed',
      MatchStatus.cancelled => 'Cancelled',
      MatchStatus.rejected => 'Rejected',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final otherName = match.getOtherParticipantName(currentUserId);
    final otherPhoto = match.getOtherParticipantPhoto(currentUserId);

    final showInlineActions =
        match.status == MatchStatus.pending && _isTraveler;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: otherPhoto.trim().isEmpty
                        ? null
                        : NetworkImage(otherPhoto),
                    child: otherPhoto.trim().isEmpty
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _roleLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _statusColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                match.itemTitle,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.flight_takeoff, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.route,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(match.tripDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (match.agreedPrice != null)
                    Text(
                      '\$${match.agreedPrice!.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall,
                    ),
                ],
              ),
              if (showInlineActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onAccept,
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        child: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
