import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/match_bloc.dart';
import '../../bloc/match_event.dart';
import '../../bloc/match_state.dart';
import '../../data/models/match_model.dart';
import '../widgets/match_card.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return BlocProvider(
      create: (_) =>
          getIt<MatchBloc>()..add(MatchesLoadRequested(authState.user.uid)),
      child: const _MatchesView(),
    );
  }
}

class _MatchesView extends StatefulWidget {
  const _MatchesView();

  @override
  State<_MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<_MatchesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const LoadingWidget();
          }

          if (state is MatchError) {
            return Center(child: Text(state.message));
          }

          if (state is MatchesLoaded) {
            final activeMatches = state.matches
                .where((m) =>
                    m.status == MatchStatus.confirmed ||
                    m.status == MatchStatus.pickedUp ||
                    m.status == MatchStatus.inTransit ||
                    m.status == MatchStatus.delivered)
                .toList();

            final pendingMatches = state.matches
                .where((m) =>
                    m.status == MatchStatus.pending ||
                    m.status == MatchStatus.accepted)
                .toList();

            final completedMatches = state.matches
                .where((m) =>
                    m.status == MatchStatus.completed ||
                    m.status == MatchStatus.cancelled ||
                    m.status == MatchStatus.rejected)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesList(activeMatches, 'No active matches'),
                _buildMatchesList(pendingMatches, 'No pending matches'),
                _buildMatchesList(completedMatches, 'No completed matches'),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMatchesList(List<MatchModel> matches, String emptyMessage) {
    if (matches.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.handshake_outlined,
        title: emptyMessage,
        subtitle: 'Your matches will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MatchCard(
            match: match,
            onTap: () => context.push(
              RouteConstants.matchDetails.replaceFirst(':id', match.id),
            ),
          ),
        );
      },
    );
  }
}
