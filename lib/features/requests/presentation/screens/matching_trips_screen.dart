import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../../trips/bloc/trip_bloc.dart';
import '../../../trips/bloc/trip_event.dart';
import '../../../trips/bloc/trip_state.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../trips/presentation/widgets/trip_card.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';

class MatchingTripsScreen extends StatefulWidget {
  const MatchingTripsScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<MatchingTripsScreen> createState() => _MatchingTripsScreenState();
}

class _MatchingTripsScreenState extends State<MatchingTripsScreen> {
  String? _sendingForTripId;

  bool get _isSending => _sendingForTripId != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RequestBloc>(
          create: (_) => GetIt.instance<RequestBloc>()
            ..add(RequestDetailsRequested(widget.requestId)),
        ),
        BlocProvider<MatchBloc>(
          create: (_) => GetIt.instance<MatchBloc>(),
        ),
      ],
      child: BlocListener<MatchBloc, MatchState>(
        listenWhen: (_, s) => s is MatchError || s is MatchCreated,
        listener: (context, state) {
          if (state is MatchError) {
            setState(() => _sendingForTripId = null);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is MatchCreated) {
            setState(() => _sendingForTripId = null);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request sent! Waiting for traveler response'),
              ),
            );
            Navigator.of(context).pop();
          }
        },
        child: BlocBuilder<RequestBloc, RequestState>(
          builder: (context, requestState) {
            if (requestState is RequestLoading || requestState is RequestInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (requestState is RequestError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Matching Trips')),
                body: Center(child: Text(requestState.message)),
              );
            }

            if (requestState is! RequestDetailsLoaded) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final request = requestState.request;

            return BlocProvider<TripBloc>(
              create: (_) => GetIt.instance<TripBloc>()
                ..add(
                  TripsLoadRequested(
                    destination: request.deliveryCity,
                    afterDate: DateTime.now(),
                  ),
                ),
              child: _MatchingTripsBody(
                request: request,
                sendingForTripId: _sendingForTripId,
                isSending: _isSending,
                onSendStarted: (tripId) {
                  setState(() => _sendingForTripId = tripId);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MatchingTripsBody extends StatelessWidget {
  const _MatchingTripsBody({
    required this.request,
    required this.sendingForTripId,
    required this.isSending,
    required this.onSendStarted,
  });

  final RequestModel request;
  final String? sendingForTripId;
  final bool isSending;
  final void Function(String tripId) onSendStarted;

  bool _isOwner(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.uid == request.requesterId;
  }

  Future<bool> _confirmRequest(BuildContext context, {required String travelerName}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Delivery?'),
          content: Text(
            "You’re requesting $travelerName to deliver your item.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isOwner(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Matching Trips')),
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
                    Text('Request summary', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Item', value: request.title),
                    _SummaryRow(label: 'To', value: request.deliveryCity),
                    _SummaryRow(
                      label: 'Weight',
                      value: '${request.weightKg.toStringAsFixed(1)} kg',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<TripBloc, TripState>(
              builder: (context, tripState) {
                final trips = tripState is TripsLoaded ? tripState.trips : const <TripModel>[];

                final eligible = trips
                    .where((t) => t.status == TripStatus.active)
                    .where((t) => t.isUpcoming)
                    .where((t) => t.destinationCity.trim().toLowerCase() ==
                        request.deliveryCity.trim().toLowerCase())
                    .where((t) => t.availableCapacityKg >= request.weightKg)
                    .toList(growable: false);

                if (!isOwner) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Only the request owner can create matches.')),
                    ],
                  );
                }

                if (request.status != RequestStatus.active) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Request already matched or unavailable.')),
                    ],
                  );
                }

                return switch (tripState) {
                  TripLoading() => const Center(child: CircularProgressIndicator()),
                  TripError() => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 80),
                        Center(child: Text(tripState.message)),
                        const SizedBox(height: 12),
                        Center(
                          child: FilledButton(
                            onPressed: () {
                              context.read<TripBloc>().add(
                                    TripsLoadRequested(
                                      destination: request.deliveryCity,
                                      afterDate: DateTime.now(),
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
                            Center(child: Text('No matching trips found.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: eligible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final t = eligible[i];

                            final isThisSending = sendingForTripId == t.id;
                            final disabled = isSending && !isThisSending;

                            return TripCard(
                              trip: t,
                              onTap: null,
                              action: FilledButton(
                                onPressed: disabled
                                    ? null
                                    : () async {
                                        if (request.status != RequestStatus.active) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Request already matched.'),
                                            ),
                                          );
                                          return;
                                        }

                                        if (!t.isUpcoming) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Trip date already passed.'),
                                            ),
                                          );
                                          return;
                                        }

                                        if (t.availableCapacityKg < request.weightKg) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Trip capacity is insufficient.'),
                                            ),
                                          );
                                          return;
                                        }

                                        final ok = await _confirmRequest(
                                          context,
                                          travelerName: t.travelerName,
                                        );
                                        if (!ok || !context.mounted) return;

                                        onSendStarted(t.id);

                                        context.read<MatchBloc>().add(
                                              MatchCreateRequested(
                                                tripId: t.id,
                                                requestId: request.id,
                                                travelerId: t.travelerId,
                                                travelerName: t.travelerName,
                                                travelerPhoto: t.travelerPhoto,
                                                requesterId: request.requesterId,
                                                requesterName: request.requesterName,
                                                requesterPhoto: request.requesterPhoto,
                                                itemTitle: request.title,
                                                route: request.routeDisplay,
                                                tripDate: t.departureDate,
                                              ),
                                            );
                                      },
                                child: isThisSending
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Request This Traveler'),
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
