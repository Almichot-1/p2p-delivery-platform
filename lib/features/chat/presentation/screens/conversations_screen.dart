import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../../matches/data/models/match_model.dart';
import '../widgets/conversation_tile.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final MatchBloc _matchBloc;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
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
    
    if (userId != _currentUserId && userId.isNotEmpty) {
      _currentUserId = userId;
      _matchBloc.add(MatchesLoadRequested(userId));
    }
  }

  @override
  void dispose() {
    _matchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _matchBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Center(child: Text('Please log in'));
            }

            final currentUserId = authState.user.uid;
            
            // Reload if user changed
            if (currentUserId != _currentUserId && currentUserId.isNotEmpty) {
              _currentUserId = currentUserId;
              _matchBloc.add(MatchesLoadRequested(currentUserId));
            }

            return BlocBuilder<MatchBloc, MatchState>(
              builder: (context, state) {
                if (state is MatchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MatchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMatchesForCurrentUser,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is MatchesLoaded) {
                  // Filter to only show matches with status >= confirmed
                  final conversations = state.matches.where((m) {
                    return m.status == MatchStatus.confirmed ||
                        m.status == MatchStatus.pickedUp ||
                        m.status == MatchStatus.inTransit ||
                        m.status == MatchStatus.delivered ||
                        m.status == MatchStatus.completed;
                  }).toList();

                  if (conversations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final match = conversations[index];
                      return ConversationTile(
                        match: match,
                        currentUserId: currentUserId,
                        unreadCount: 0, // TODO: Implement unread count
                        onTap: () => context.push('/chat/${match.id}'),
                      );
                    },
                  );
                }

                return _buildEmptyState();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Once you confirm a match, you can chat with the other party here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
