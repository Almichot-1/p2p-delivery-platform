import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';
import '../widgets/image_carousel.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestBloc>(
      create: (_) => GetIt.instance<RequestBloc>()
        ..add(RequestDetailsRequested(requestId)),
      child: BlocConsumer<RequestBloc, RequestState>(
        listenWhen: (_, s) => s is RequestError || s is RequestCancelled,
        listener: (context, state) {
          if (state is RequestError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is RequestCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request cancelled')),
            );
          }
        },
        builder: (context, state) {
          final request = state is RequestDetailsLoaded ? state.request : null;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Request Details'),
              actions: [
                if (request != null) _buildOwnerActions(context, request),
              ],
            ),
            body: switch (state) {
              RequestLoading() =>
                const Center(child: CircularProgressIndicator()),
              RequestError() => Center(child: Text(state.message)),
              RequestDetailsLoaded() =>
                _RequestDetailsBody(request: state.request),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        },
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context, RequestModel request) {
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated &&
        authState.user.uid == request.requesterId;

    if (!isOwner) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'edit') {
          context.push(RoutePaths.requestsCreate, extra: request);
          return;
        }
        if (v == 'cancel') {
          context.read<RequestBloc>().add(RequestCancelRequested(request.id));
        }
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Edit'),
          ),
          if (request.status == RequestStatus.active)
            const PopupMenuItem<String>(
              value: 'cancel',
              child: Text('Cancel'),
            ),
        ];
      },
    );
  }
}

class _RequestDetailsBody extends StatelessWidget {
  const _RequestDetailsBody({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated &&
        authState.user.uid == request.requesterId;

    final dateFmt = DateFormat('MMM d, y');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (request.imageUrls.isNotEmpty)
          ImageCarousel(urls: request.imageUrls)
        else
          Container(
            height: 240,
            color: scheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(text: request.categoryDisplay, icon: Icons.category_outlined),
                  _MetaChip(
                    text: '${request.weightKg.toStringAsFixed(1)} kg',
                    icon: Icons.scale_outlined,
                  ),
                  if (request.isUrgent)
                    _MetaChip(
                      text: 'Urgent',
                      icon: Icons.bolt,
                      emphasize: true,
                    ),
                  if (request.offeredPrice != null)
                    _MetaChip(
                      text: '${request.offeredPrice!.toStringAsFixed(2)}',
                      icon: Icons.payments_outlined,
                    ),
                  if (request.preferredDeliveryDate != null)
                    _MetaChip(
                      text: dateFmt.format(request.preferredDeliveryDate!.toLocal()),
                      icon: Icons.event_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ProfileImage(
                        displayName: request.requesterName,
                        imageUrl: request.requesterPhoto,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.requesterName,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  request.requesterRating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Posted ${dateFmt.format(request.createdAt.toLocal())}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Route',
                child: Column(
                  children: [
                    _RouteRow(
                      icon: Icons.my_location_outlined,
                      title: 'Pickup',
                      city: request.pickupCity,
                      country: request.pickupCountry,
                      address: request.pickupAddress,
                    ),
                    const SizedBox(height: 12),
                    _RouteRow(
                      icon: Icons.location_on_outlined,
                      title: 'Delivery',
                      city: request.deliveryCity,
                      country: request.deliveryCountry,
                      address: request.deliveryAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Recipient',
                child: Column(
                  children: [
                    _InfoRow(label: 'Name', value: request.recipientName),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Phone', value: request.recipientPhone),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (request.description.trim().isNotEmpty)
                _SectionCard(
                  title: 'Notes',
                  child: Text(
                    request.description.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              if (request.description.trim().isNotEmpty) const SizedBox(height: 12),
              _SectionCard(
                title: 'Details',
                child: Column(
                  children: [
                    _InfoRow(label: 'Status', value: _statusLabel(request.status)),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Last updated', value: dateFmt.format(request.updatedAt.toLocal())),
                    if (request.matchedTripId != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Matched trip', value: request.matchedTripId!),
                    ],
                    if (request.matchedTravelerId != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Matched traveler', value: request.matchedTravelerId!),
                    ],
                  ],
                ),
              ),
              if (isOwner && request.status == RequestStatus.active) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      '${RoutePaths.requests}/${request.id}/matching-trips',
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text('Find a Traveler'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _statusLabel(RequestStatus s) {
  return switch (s) {
    RequestStatus.active => 'Active',
    RequestStatus.matched => 'Matched',
    RequestStatus.inProgress => 'In progress',
    RequestStatus.completed => 'Completed',
    RequestStatus.cancelled => 'Cancelled',
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
        _statusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.title,
    required this.city,
    required this.country,
    required this.address,
  });

  final IconData icon;
  final String title;
  final String city;
  final String country;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final cityText = city.trim().isEmpty ? '—' : city.trim();
    final countryText = country.trim().isEmpty ? '—' : country.trim();
    final addressText = address.trim().isEmpty ? '—' : address.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(
                countryText,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                cityText,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                addressText,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.icon,
    this.emphasize = false,
  });

  final String text;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = emphasize ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = emphasize ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
