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
import '../widgets/match_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MatchBloc _matchBloc;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchBloc = GetIt.instance<MatchBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMatchesForCurrentUser();
  }

  void _loadMatchesForCurrentUser() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    
    // Only reload if user changed
    if (userId != _currentUserId) {
      _currentUserId = userId;
      if (userId.isNotEmpty) {
        _matchBloc.add(MatchesLoadRequested(userId));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = authState is AuthAuthenticated ? authState.user.uid : '';
        
        // Reload matches if user changed
        if (userId != _currentUserId && userId.isNotEmpty) {
          _currentUserId = userId;
          _matchBloc.add(MatchesLoadRequested(userId));
        }

        return BlocProvider<MatchBloc>.value(
          value: _matchBloc,
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
              final matches =
                  state is MatchesLoaded ? state.matches : const <MatchModel>[];

              final active = matches.where((m) {
                return m.status == MatchStatus.confirmed ||
                    m.status == MatchStatus.pickedUp ||
                    m.status == MatchStatus.inTransit ||
                    m.status == MatchStatus.delivered;
              }).toList(growable: false);

              final pending = matches.where((m) {
                return m.status == MatchStatus.pending ||
                    m.status == MatchStatus.accepted;
              }).toList(growable: false);

              final completed = matches.where((m) {
                return m.status == MatchStatus.completed ||
                    m.status == MatchStatus.cancelled ||
                    m.status == MatchStatus.rejected;
              }).toList(growable: false);

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Matches'),
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Active'),
                      Tab(text: 'Pending'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
                body: switch (state) {
                  MatchLoading() => const Center(child: CircularProgressIndicator()),
                  MatchError() => Center(child: Text(state.message)),
                  _ => TabBarView(
                      controller: _tabController,
                      children: [
                        _MatchesList(matches: active, currentUserId: userId),
                        _MatchesList(matches: pending, currentUserId: userId),
                        _MatchesList(matches: completed, currentUserId: userId),
                      ],
                    ),
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({
    required this.matches,
    required this.currentUserId,
  });

  final List<MatchModel> matches;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No matches found.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final m = matches[i];
        final isTraveler = currentUserId == m.travelerId;

        return MatchCard(
          match: m,
          currentUserId: currentUserId,
          onTap: () => context.push('${RoutePaths.matches}/${m.id}'),
          onAccept: isTraveler
              ? () => context.read<MatchBloc>().add(MatchAcceptRequested(m.id))
              : null,
          onDecline: isTraveler
              ? () => context.read<MatchBloc>().add(MatchRejectRequested(m.id))
              : null,
        );
      },
    );
  }
}
