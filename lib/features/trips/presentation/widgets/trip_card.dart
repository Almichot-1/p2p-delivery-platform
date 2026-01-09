import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/cached_image.dart';
import '../../data/models/trip_model.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.action,
  });

  final TripModel trip;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final dateFmt = DateFormat('EEE, MMM d');

    final statusChip = _StatusChip(status: trip.status);

    final chips = trip.acceptedItemTypes.take(3).toList(growable: false);

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
                children: [
                  ProfileImage(
                    displayName: trip.travelerName,
                    imageUrl: trip.travelerPhoto,
                    size: 42,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.travelerName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              trip.travelerRating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  statusChip,
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.flight_takeoff, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.routeDisplay,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _InfoPill(
                    icon: Icons.calendar_today_outlined,
                    text: dateFmt.format(trip.departureDate),
                  ),
                  _InfoPill(
                    icon: Icons.scale_outlined,
                    text: '${trip.availableCapacityKg.toStringAsFixed(1)} kg',
                  ),
                  if (trip.pricePerKg != null)
                    _InfoPill(
                      icon: Icons.payments_outlined,
                      text: '${trip.pricePerKg!.toStringAsFixed(2)}/kg',
                    ),
                ],
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final t in chips)
                      InputChip(
                        label: Text(t),
                        onPressed: null,
                      ),
                  ],
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: action!,
                ),
              ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String label;
    switch (status) {
      case TripStatus.active:
        label = 'Active';
      case TripStatus.completed:
        label = 'Completed';
      case TripStatus.cancelled:
        label = 'Cancelled';
    }

    final bg = switch (status) {
      TripStatus.active => scheme.primaryContainer,
      TripStatus.completed => scheme.secondaryContainer,
      TripStatus.cancelled => scheme.errorContainer,
    };

    final fg = switch (status) {
      TripStatus.active => scheme.onPrimaryContainer,
      TripStatus.completed => scheme.onSecondaryContainer,
      TripStatus.cancelled => scheme.onErrorContainer,
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
