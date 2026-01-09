import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripBloc>(
      create: (_) => GetIt.instance<TripBloc>()..add(TripDetailsRequested(tripId)),
      child: BlocConsumer<TripBloc, TripState>(
        listenWhen: (_, s) => s is TripError || s is TripCancelled,
        listener: (context, state) {
          if (state is TripError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is TripCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip cancelled')),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            TripLoading() => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            TripDetailsLoaded() => _TripDetailsBody(trip: state.trip),
            TripError() => Scaffold(
                appBar: AppBar(title: const Text('Trip')),
                body: Center(child: Text(state.message)),
              ),
            _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
          };
        },
      ),
    );
  }
}

class _TripDetailsBody extends StatelessWidget {
  const _TripDetailsBody({required this.trip});

  final TripModel trip;

  Future<void> _cancelTrip(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel trip'),
          content: const Text('Are you sure you want to cancel this trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Trip'),
            ),
          ],
        );
      },
    );

    if (ok != true || !context.mounted) return;
    context.read<TripBloc>().add(TripCancelRequested(trip.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final dateFmt = DateFormat('EEE, MMM d');

    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated && authState.user.uid == trip.travelerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            title: Text(trip.routeDisplay),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    _StatusBadge(status: trip.status),
                    const SizedBox(width: 10),
                    Text(
                      trip.routeDisplay,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      context.push(RoutePaths.tripsCreate, extra: trip);
                    }
                    if (v == 'cancel') {
                      _cancelTrip(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text('Cancel'),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          ProfileImage(
                            displayName: trip.travelerName,
                            imageUrl: trip.travelerPhoto,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trip.travelerName, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16),
                                    const SizedBox(width: 4),
                                    Text(trip.travelerRating.toStringAsFixed(1)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Traveler profile (coming soon)')),
                              );
                            },
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'View profile',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trip info', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Departure',
                            value: dateFmt.format(trip.departureDate),
                          ),
                          if (trip.returnDate != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.event_repeat_outlined,
                              label: 'Return',
                              value: dateFmt.format(trip.returnDate!),
                            ),
                          ],
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.scale_outlined,
                            label: 'Capacity',
                            value: '${trip.availableCapacityKg.toStringAsFixed(1)} kg',
                          ),
                          if (trip.pricePerKg != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.payments_outlined,
                              label: 'Price',
                              value: '${trip.pricePerKg!.toStringAsFixed(2)}/kg',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (trip.acceptedItemTypes.isNotEmpty) ...[
                    Text('Accepted item types', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in trip.acceptedItemTypes)
                          InputChip(
                            label: Text(t),
                            onPressed: null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (trip.notes != null && trip.notes!.trim().isNotEmpty) ...[
                    Text('Notes', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(trip.notes!, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                  ],
                  if (isOwner && trip.status == TripStatus.active) ...[
                    FilledButton.icon(
                      onPressed: trip.isUpcoming
                          ? () => context.push(
                                '${RoutePaths.trips}/${trip.id}/matching-requests',
                              )
                          : null,
                      icon: const Icon(Icons.link),
                      label: const Text('Find Requests to Carry'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  if (!isOwner)
                    FilledButton.icon(
                      onPressed: () {
                        // To contact a traveler, user needs to have a request first
                        // Navigate to create a request or show info
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Contact Traveler'),
                            content: const Text(
                              'To contact this traveler, you need to create a delivery request first. '
                              'Once you have a request, you can match it with this trip and start chatting after the match is confirmed.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.push(RoutePaths.requestsCreate);
                                },
                                child: const Text('Create Request'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Contact Traveler'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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

    String text;
    switch (status) {
      case TripStatus.active:
        text = 'Active';
      case TripStatus.completed:
        text = 'Completed';
      case TripStatus.cancelled:
        text = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 86,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
