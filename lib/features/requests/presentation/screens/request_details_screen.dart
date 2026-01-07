import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
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

    return ListView(
      children: [
        if (request.imageUrls.isNotEmpty)
          ImageCarousel(urls: request.imageUrls)
        else
          Container(
            height: 240,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(text: request.categoryDisplay),
                  const SizedBox(width: 8),
                  _Chip(text: '${request.weightKg.toStringAsFixed(1)} kg'),
                  if (request.isUrgent) ...[
                    const SizedBox(width: 8),
                    _Chip(text: 'Urgent'),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(request.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              _SectionTitle(text: 'Route'),
              const SizedBox(height: 8),
              _KeyValue(
                  label: 'Pickup',
                  value: '${request.pickupCity}, ${request.pickupCountry}'),
              _KeyValue(label: 'Pickup address', value: request.pickupAddress),
              const SizedBox(height: 8),
              _KeyValue(
                  label: 'Delivery',
                  value: '${request.deliveryCity}, ${request.deliveryCountry}'),
              _KeyValue(
                  label: 'Delivery address', value: request.deliveryAddress),
              const SizedBox(height: 16),
              _SectionTitle(text: 'Recipient'),
              const SizedBox(height: 8),
              _KeyValue(label: 'Name', value: request.recipientName),
              _KeyValue(label: 'Phone', value: request.recipientPhone),
              const SizedBox(height: 16),
              _SectionTitle(text: 'Other'),
              const SizedBox(height: 8),
              _KeyValue(label: 'Status', value: request.status.name),
              if (request.offeredPrice != null)
                _KeyValue(
                    label: 'Offered price',
                    value: request.offeredPrice!.toStringAsFixed(2)),
              if (request.preferredDeliveryDate != null)
                _KeyValue(
                  label: 'Preferred delivery date',
                  value: request.preferredDeliveryDate!
                      .toLocal()
                      .toString()
                      .split(' ')
                      .first,
                ),
              if (request.matchedTripId != null)
                _KeyValue(label: 'Matched trip', value: request.matchedTripId!),
              if (request.matchedTravelerId != null)
                _KeyValue(
                    label: 'Matched traveler',
                    value: request.matchedTravelerId!),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
