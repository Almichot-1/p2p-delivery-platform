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
import '../widgets/request_card.dart';

class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestBloc>()..add(const RequestsLoadRequested()),
      child: const _RequestsListView(),
    );
  }
}

class _RequestsListView extends StatelessWidget {
  const _RequestsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
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
            if (state.requests.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: 'No Requests Yet',
                subtitle: 'Be the first to post a delivery request',
                buttonText: 'Create Request',
                onButtonPressed: () =>
                    context.push(RouteConstants.createRequest),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<RequestBloc>().add(const RequestsLoadRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.requests.length,
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RequestCard(
                      request: request,
                      onTap: () => context.push(
                        RouteConstants.requestDetails
                            .replaceFirst(':id', request.id),
                      ),
                    ),
                  );
                },
              ),
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
}
