import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/match_bloc.dart';
import '../../bloc/match_event.dart';
import '../../bloc/match_state.dart';
import '../../data/models/match_model.dart';
import '../widgets/match_status_timeline.dart';

class MatchDetailsScreen extends StatelessWidget {
  const MatchDetailsScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchBloc>(
      create: (_) => GetIt.instance<MatchBloc>()..add(MatchDetailsRequested(matchId)),
      child: BlocConsumer<MatchBloc, MatchState>(
        listenWhen: (_, s) => s is MatchError || s is MatchActionSuccess,
        listener: (context, state) {
          if (state is MatchError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is MatchActionSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final match = state is MatchDetailsLoaded ? state.match : null;

          return Scaffold(
            appBar: AppBar(title: const Text('Match Details')),
            body: switch (state) {
              MatchLoading() => const Center(child: CircularProgressIndicator()),
              MatchError() => Center(child: Text(state.message)),
              MatchDetailsLoaded() => _MatchDetailsBody(match: state.match),
              _ => const Center(child: CircularProgressIndicator()),
            },
            bottomNavigationBar: match == null
                ? null
                : _ActionBar(match: match),
          );
        },
      ),
    );
  }
}

class _MatchDetailsBody extends StatelessWidget {
  const _MatchDetailsBody({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthBloc>().state;
    final currentUserId = auth is AuthAuthenticated ? auth.user.uid : '';

    final otherName = match.getOtherParticipantName(currentUserId);
    final otherPhoto = match.getOtherParticipantPhoto(currentUserId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: otherPhoto.trim().isEmpty ? null : NetworkImage(otherPhoto),
              child: otherPhoto.trim().isEmpty ? const Icon(Icons.person_outline) : null,
            ),
            title: Text(otherName),
            subtitle: Text(match.route),
            onTap: () {
              // Tappable → profile (best-effort).
              // Current app's profile route is for the current user.
              if (otherName.trim().isNotEmpty && currentUserId.trim().isNotEmpty) {
                context.push(RoutePaths.profile);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile view coming soon')),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.itemTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _KeyValue(label: 'Route', value: match.route),
                _KeyValue(label: 'Trip date', value: _formatDate(match.tripDate)),
                _KeyValue(label: 'Status', value: match.status.name),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MatchStatusTimeline(status: match.status),
        const SizedBox(height: 12),
        _AgreedPriceCard(match: match),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat'),
            subtitle: Text(
              match.status == MatchStatus.confirmed ||
                      match.status == MatchStatus.pickedUp ||
                      match.status == MatchStatus.inTransit ||
                      match.status == MatchStatus.delivered ||
                      match.status == MatchStatus.completed
                  ? 'Message the other party'
                  : 'Available after confirmation',
            ),
            onTap: () {
              if (match.status == MatchStatus.confirmed ||
                  match.status == MatchStatus.pickedUp ||
                  match.status == MatchStatus.inTransit ||
                  match.status == MatchStatus.delivered ||
                  match.status == MatchStatus.completed) {
                context.push('/chat/${match.id}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat available after match is confirmed')),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _AgreedPriceCard extends StatefulWidget {
  const _AgreedPriceCard({required this.match});

  final MatchModel match;

  @override
  State<_AgreedPriceCard> createState() => _AgreedPriceCardState();
}

class _AgreedPriceCardState extends State<_AgreedPriceCard> {
  late final TextEditingController _ctrl;

  bool get _editable =>
      widget.match.status == MatchStatus.pending ||
      widget.match.status == MatchStatus.accepted;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.match.agreedPrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _AgreedPriceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.agreedPrice != widget.match.agreedPrice) {
      _ctrl.text = widget.match.agreedPrice?.toStringAsFixed(2) ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agreed price', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              enabled: _editable,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Enter agreed price',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 10),
            if (_editable)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    final v = double.tryParse(_ctrl.text.trim());
                    if (v == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid price')),
                      );
                      return;
                    }
                    context
                        .read<MatchBloc>()
                        .add(MatchAgreedPriceUpdateRequested(widget.match.id, v));
                  },
                  child: const Text('Save'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final currentUserId = auth is AuthAuthenticated ? auth.user.uid : '';

    final isTraveler = currentUserId == match.travelerId;
    final isParticipant = match.isParticipant(currentUserId);

    if (!isParticipant) return const SizedBox.shrink();

    final actions = <Widget>[];

    void addFull(Widget w) => actions.add(Expanded(child: w));

    // Pending – Traveler: Accept / Decline
    if (match.status == MatchStatus.pending && isTraveler) {
      addFull(
        FilledButton(
          onPressed: () => context.read<MatchBloc>().add(MatchAcceptRequested(match.id)),
          child: const Text('Accept'),
        ),
      );
      actions.add(const SizedBox(width: 10));
      addFull(
        OutlinedButton(
          onPressed: () => context.read<MatchBloc>().add(MatchRejectRequested(match.id)),
          child: const Text('Decline'),
        ),
      );
      return _bar(actions);
    }

    // Accepted – Both: Confirm / Cancel
    if (match.status == MatchStatus.accepted) {
      addFull(
        FilledButton(
          onPressed: () => context.read<MatchBloc>().add(MatchConfirmRequested(match.id)),
          child: const Text('Confirm'),
        ),
      );
      actions.add(const SizedBox(width: 10));
      addFull(
        OutlinedButton(
          onPressed: () => context.read<MatchBloc>().add(MatchCancelRequested(match.id)),
          child: const Text('Cancel'),
        ),
      );
      return _bar(actions);
    }

    // Confirmed – Traveler: Picked up
    if (match.status == MatchStatus.confirmed && isTraveler) {
      addFull(
        FilledButton(
          onPressed: () => context.read<MatchBloc>().add(
                MatchStatusUpdateRequested(match.id, MatchStatus.pickedUp),
              ),
          child: const Text('Mark Picked Up'),
        ),
      );
      return _bar(actions);
    }

    // PickedUp – Traveler: Mark In Transit
    if (match.status == MatchStatus.pickedUp && isTraveler) {
      addFull(
        FilledButton(
          onPressed: () => context.read<MatchBloc>().add(
                MatchStatusUpdateRequested(match.id, MatchStatus.inTransit),
              ),
          child: const Text('Mark In Transit'),
        ),
      );
      return _bar(actions);
    }

    // PickedUp – Requester: Just info
    if (match.status == MatchStatus.pickedUp && !isTraveler) {
      return _bar([
        Expanded(
          child: Text(
            'Waiting for traveler to start transit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ]);
    }

    // InTransit – Traveler: Delivered
    if (match.status == MatchStatus.inTransit && isTraveler) {
      addFull(
        FilledButton(
          onPressed: () => context.read<MatchBloc>().add(
                MatchStatusUpdateRequested(match.id, MatchStatus.delivered),
              ),
          child: const Text('Mark Delivered'),
        ),
      );
      return _bar(actions);
    }

    // Delivered – Both: Complete
    if (match.status == MatchStatus.delivered) {
      addFull(
        FilledButton(
          onPressed: () => context.read<MatchBloc>().add(
                MatchStatusUpdateRequested(match.id, MatchStatus.completed),
              ),
          child: const Text('Complete'),
        ),
      );
      return _bar(actions);
    }

    // Any – Both: Cancel when allowed
    final canCancel = match.status != MatchStatus.cancelled &&
        match.status != MatchStatus.rejected &&
        match.status != MatchStatus.completed &&
        match.status != MatchStatus.delivered;

    if (canCancel) {
      addFull(
        OutlinedButton(
          onPressed: () => context.read<MatchBloc>().add(MatchCancelRequested(match.id)),
          child: const Text('Cancel'),
        ),
      );
      return _bar(actions);
    }

    return const SizedBox.shrink();
  }

  Widget _bar(List<Widget> children) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(children: children),
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
