import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../../requests/bloc/request_bloc.dart';
import '../../../requests/bloc/request_event.dart';
import '../../../requests/bloc/request_state.dart';
import '../../../requests/data/models/request_model.dart';
import '../../../requests/presentation/widgets/request_card.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';

class MatchingRequestsScreen extends StatefulWidget {
  const MatchingRequestsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<MatchingRequestsScreen> createState() => _MatchingRequestsScreenState();
}

class _MatchingRequestsScreenState extends State<MatchingRequestsScreen> {
  String? _sendingForRequestId;

  bool get _isSending => _sendingForRequestId != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TripBloc>(
          create: (_) => GetIt.instance<TripBloc>()
            ..add(TripDetailsRequested(widget.tripId)),
        ),
        BlocProvider<MatchBloc>(
          create: (_) => GetIt.instance<MatchBloc>(),
        ),
      ],
      child: BlocListener<MatchBloc, MatchState>(
        listenWhen: (_, s) => s is MatchError || s is MatchCreated,
        listener: (context, state) {
          if (state is MatchError) {
            setState(() => _sendingForRequestId = null);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is MatchCreated) {
            setState(() => _sendingForRequestId = null);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Match created! Waiting for requester response'),
              ),
            );
            Navigator.of(context).pop();
          }
        },
        child: BlocBuilder<TripBloc, TripState>(
          builder: (context, tripState) {
            if (tripState is TripLoading || tripState is TripInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (tripState is TripError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Matching Requests')),
                body: Center(child: Text(tripState.message)),
              );
            }

            if (tripState is! TripDetailsLoaded) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final trip = tripState.trip;

            return BlocProvider<RequestBloc>(
              create: (_) => GetIt.instance<RequestBloc>()
                ..add(
                  RequestsLoadRequested(
                    deliveryCity: trip.destinationCity,
                    category: null,
                  ),
                ),
              child: _MatchingRequestsBody(
                trip: trip,
                sendingForRequestId: _sendingForRequestId,
                isSending: _isSending,
                onSendStarted: (requestId) {
                  setState(() => _sendingForRequestId = requestId);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MatchingRequestsBody extends StatelessWidget {
  const _MatchingRequestsBody({
    required this.trip,
    required this.sendingForRequestId,
    required this.isSending,
    required this.onSendStarted,
  });

  final TripModel trip;
  final String? sendingForRequestId;
  final bool isSending;
  final void Function(String requestId) onSendStarted;

  bool _isOwner(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.uid == trip.travelerId;
  }

  Future<bool> _confirmOffer(
    BuildContext context, {
    required String itemTitle,
    required String deliveryCity,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Offer to Deliver?'),
          content: Text(
            "You’re offering to deliver '$itemTitle' to $deliveryCity. The requester can accept or decline.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send Offer'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d');

    final isOwner = _isOwner(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Matching Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip summary', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Destination', value: trip.destinationCity),
                    _SummaryRow(label: 'Date', value: dateFmt.format(trip.departureDate)),
                    _SummaryRow(
                      label: 'Capacity',
                      value: '${trip.availableCapacityKg.toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<RequestBloc, RequestState>(
              builder: (context, requestState) {
                final requests = requestState is RequestsLoaded
                    ? requestState.requests
                    : const <RequestModel>[];

                final eligible = requests
                    .where((r) => r.status == RequestStatus.active)
                    .where((r) => r.weightKg <= trip.availableCapacityKg)
                    .toList(growable: false);

                if (!isOwner) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Only the trip owner can create matches.')),
                    ],
                  );
                }

                if (trip.status != TripStatus.active) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Trip is not active.')),
                    ],
                  );
                }

                if (!trip.isUpcoming) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Trip date already passed.')),
                    ],
                  );
                }

                return switch (requestState) {
                  RequestLoading() => const Center(child: CircularProgressIndicator()),
                  RequestError() => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text(requestState.message)),
                        const SizedBox(height: 12),
                        Center(
                          child: FilledButton(
                            onPressed: () {
                              context.read<RequestBloc>().add(
                                    RequestsLoadRequested(
                                      deliveryCity: trip.destinationCity,
                                      category: null,
                                    ),
                                  );
                            },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  _ => eligible.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No matching requests found.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: eligible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final r = eligible[i];

                            final isThisSending = sendingForRequestId == r.id;
                            final disabled = isSending && !isThisSending;

                            return RequestCard(
                              request: r,
                              onTap: null,
                              action: FilledButton(
                                onPressed: disabled
                                    ? null
                                    : () async {
                                        if (r.status != RequestStatus.active) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Request already matched.'),
                                            ),
                                          );
                                          return;
                                        }

                                        if (r.weightKg > trip.availableCapacityKg) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Trip capacity is insufficient.'),
                                            ),
                                          );
                                          return;
                                        }

                                        if (!trip.isUpcoming) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Trip date already passed.'),
                                            ),
                                          );
                                          return;
                                        }

                                        final ok = await _confirmOffer(
                                          context,
                                          itemTitle: r.title,
                                          deliveryCity: r.deliveryCity,
                                        );
                                        if (!ok || !context.mounted) return;

                                        onSendStarted(r.id);

                                        context.read<MatchBloc>().add(
                                              MatchCreateRequested(
                                                tripId: trip.id,
                                                requestId: r.id,
                                                travelerId: trip.travelerId,
                                                travelerName: trip.travelerName,
                                                travelerPhoto: trip.travelerPhoto,
                                                requesterId: r.requesterId,
                                                requesterName: r.requesterName,
                                                requesterPhoto: r.requesterPhoto,
                                                itemTitle: r.title,
                                                route: r.routeDisplay,
                                                tripDate: trip.departureDate,
                                              ),
                                            );
                                      },
                                child: isThisSending
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('I Can Deliver This'),
                              ),
                            );
                          },
                        ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
