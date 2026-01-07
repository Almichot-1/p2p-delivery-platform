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
import '../widgets/request_card.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view your requests.')),
          );
        }

        return BlocProvider<RequestBloc>(
          create: (_) => GetIt.instance<RequestBloc>()
            ..add(
              MyRequestsLoadRequested(authState.user.uid),
            ),
          child: DefaultTabController(
            length: 5,
            child: BlocConsumer<RequestBloc, RequestState>(
              listenWhen: (_, s) => s is RequestError,
              listener: (context, state) {
                if (state is RequestError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                final all = state is RequestsLoaded
                    ? state.requests
                    : const <RequestModel>[];

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('My Requests'),
                    bottom: const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Active'),
                        Tab(text: 'Matched'),
                        Tab(text: 'In Progress'),
                        Tab(text: 'Completed'),
                        Tab(text: 'Cancelled'),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Create Request',
                        onPressed: () =>
                            context.push(RoutePaths.requestsCreate),
                      ),
                    ],
                  ),
                  body: switch (state) {
                    RequestLoading() =>
                      const Center(child: CircularProgressIndicator()),
                    RequestError() => Center(child: Text(state.message)),
                    RequestsLoaded() => TabBarView(
                        children: [
                          _RequestsTab(
                            requests: _filterBy(all, RequestStatus.active),
                          ),
                          _RequestsTab(
                            requests: _filterBy(all, RequestStatus.matched),
                          ),
                          _RequestsTab(
                            requests: _filterBy(all, RequestStatus.inProgress),
                          ),
                          _RequestsTab(
                            requests: _filterBy(all, RequestStatus.completed),
                          ),
                          _RequestsTab(
                            requests: _filterBy(all, RequestStatus.cancelled),
                          ),
                        ],
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  static List<RequestModel> _filterBy(
      List<RequestModel> all, RequestStatus status) {
    return all.where((r) => r.status == status).toList(growable: false);
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.requests});

  final List<RequestModel> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No requests.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = requests[i];
        return RequestCard(
          request: r,
          onTap: () => context.push('${RoutePaths.requests}/${r.id}'),
        );
      },
    );
  }
}
