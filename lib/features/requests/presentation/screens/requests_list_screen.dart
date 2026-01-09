import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';
import '../widgets/request_card.dart';
import '../widgets/request_filter.dart';

class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({super.key});

  @override
  State<RequestsListScreen> createState() => _RequestsListScreenState();
}

class _RequestsListScreenState extends State<RequestsListScreen> {
  RequestFilters _filters = const RequestFilters();

  void _load(BuildContext blocContext) {
    blocContext.read<RequestBloc>().add(
          RequestsLoadRequested(
            deliveryCity: _filters.deliveryCity,
            category: _filters.category,
          ),
        );
  }

  Future<void> _refresh(BuildContext blocContext) async {
    _load(blocContext);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  void _openFilter(BuildContext blocContext) {
    showModalBottomSheet<void>(
      context: blocContext,
      isScrollControlled: true,
      builder: (context) {
        return RequestFilterSheet(
          initial: _filters,
          onApply: (f) {
            setState(() => _filters = f);
            _load(blocContext);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestBloc>(
      create: (_) => GetIt.instance<RequestBloc>()
        ..add(
          RequestsLoadRequested(
            deliveryCity: _filters.deliveryCity,
            category: _filters.category,
          ),
        ),
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
          final requests =
              state is RequestsLoaded ? state.requests : const <RequestModel>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Requests'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'My Requests',
                  onPressed: () => context.push(RoutePaths.myRequests),
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filter',
                  onPressed: () => _openFilter(context),
                ),
              ],
            ),
            body: Column(
              children: [
                if (!_filters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_filters.deliveryCity != null &&
                              _filters.deliveryCity!.trim().isNotEmpty)
                            InputChip(
                              label: Text('City: ${_filters.deliveryCity}'),
                              onDeleted: () {
                                setState(() {
                                  _filters = RequestFilters(
                                    deliveryCity: null,
                                    category: _filters.category,
                                  );
                                });
                                _load(context);
                              },
                            ),
                          if (_filters.category != null)
                            InputChip(
                              label:
                                  Text('Category: ${_filters.category!.name}'),
                              onDeleted: () {
                                setState(() {
                                  _filters = RequestFilters(
                                    deliveryCity: _filters.deliveryCity,
                                    category: null,
                                  );
                                });
                                _load(context);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: switch (state) {
                      RequestLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      RequestsLoaded() => requests.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text('No requests found.')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: requests.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final r = requests[i];
                                return RequestCard(
                                  request: r,
                                  onTap: () => context
                                      .push('${RoutePaths.requests}/${r.id}'),
                                );
                              },
                            ),
                      RequestError() => ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(child: Text(state.message)),
                            const SizedBox(height: 12),
                            Center(
                              child: FilledButton(
                                onPressed: () => _load(context),
                                child: const Text('Retry'),
                              ),
                            ),
                          ],
                        ),
                      _ => ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: CircularProgressIndicator()),
                          ],
                        ),
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'requests_list_fab',
              onPressed: () => context.push(RoutePaths.requestsCreate),
              icon: const Icon(Icons.add),
              label: const Text('Create Request'),
            ),
          );
        },
      ),
    );
  }
}
