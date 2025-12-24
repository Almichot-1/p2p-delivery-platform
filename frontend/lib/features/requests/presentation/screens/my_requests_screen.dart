import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';
import '../widgets/request_card.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestBloc>()..add(MyRequestsLoadRequested()),
      child: const _MyRequestsView(),
    );
  }
}

class _MyRequestsView extends StatefulWidget {
  const _MyRequestsView();

  @override
  State<_MyRequestsView> createState() => _MyRequestsViewState();
}

class _MyRequestsViewState extends State<_MyRequestsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('My Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Matched'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: BlocBuilder<RequestBloc, RequestState>(
        builder: (context, state) {
          if (state is RequestLoading) {
            return const LoadingWidget();
          }

          if (state is RequestError) {
            return Center(child: Text(state.message));
          }

          if (state is RequestsLoaded) {
            final activeRequests = state.requests
                .where((r) => r.status == RequestStatus.active)
                .toList();
            final matchedRequests = state.requests
                .where((r) =>
                    r.status == RequestStatus.matched ||
                    r.status == RequestStatus.inProgress)
                .toList();
            final completedRequests = state.requests
                .where((r) => r.status == RequestStatus.completed)
                .toList();
            final cancelledRequests = state.requests
                .where((r) => r.status == RequestStatus.cancelled)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(activeRequests, 'No active requests'),
                _buildRequestsList(matchedRequests, 'No matched requests'),
                _buildRequestsList(completedRequests, 'No completed requests'),
                _buildRequestsList(cancelledRequests, 'No cancelled requests'),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.createRequest),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildRequestsList(List<RequestModel> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: emptyMessage,
        subtitle: 'Your requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<RequestBloc>().add(MyRequestsLoadRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RequestCard(
              request: request,
              onTap: () => context.push(
                RouteConstants.requestDetails.replaceFirst(':id', request.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
