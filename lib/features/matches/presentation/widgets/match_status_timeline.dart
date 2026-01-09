import 'package:flutter/material.dart';

import '../../data/models/match_model.dart';

class MatchStatusTimeline extends StatelessWidget {
  const MatchStatusTimeline({
    super.key,
    required this.status,
  });

  final MatchStatus status;

  static const List<MatchStatus> _ordered = <MatchStatus>[
    MatchStatus.pending,
    MatchStatus.accepted,
    MatchStatus.confirmed,
    MatchStatus.pickedUp,
    MatchStatus.inTransit,
    MatchStatus.delivered,
    MatchStatus.completed,
  ];

  String _label(MatchStatus s) {
    return switch (s) {
      MatchStatus.pending => 'Pending',
      MatchStatus.accepted => 'Accepted',
      MatchStatus.confirmed => 'Confirmed',
      MatchStatus.pickedUp => 'Picked Up',
      MatchStatus.inTransit => 'In Transit',
      MatchStatus.delivered => 'Delivered',
      MatchStatus.completed => 'Completed',
      _ => s.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cancelled = status == MatchStatus.cancelled;
    final rejected = status == MatchStatus.rejected;

    int currentIndex = _ordered.indexOf(status);
    if (currentIndex < 0) currentIndex = 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (var i = 0; i < _ordered.length; i++)
              _TimelineRow(
                label: _label(_ordered[i]),
                isCompleted: !cancelled && !rejected && i < currentIndex,
                isCurrent: !cancelled && !rejected && i == currentIndex,
              ),
            if (cancelled) ...[
              const SizedBox(height: 8),
              Text(
                'Cancelled',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (rejected) ...[
              const SizedBox(height: 8),
              Text(
                'Rejected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String label;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color dotColor = isCompleted
        ? theme.colorScheme.primary
        : isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.outline;

    final Widget dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? Icon(
              Icons.check,
              size: 10,
              color: theme.colorScheme.onPrimary,
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          dot,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
