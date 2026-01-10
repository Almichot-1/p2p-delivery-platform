import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';
import '../widgets/trip_card.dart';
import '../widgets/trip_filter.dart';

class TripsListScreen extends StatefulWidget {
  const TripsListScreen({super.key});

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  TripFilters _filters = const TripFilters();

  DateTime? _effectiveAfterDate(TripFilters f) {
    if (f.includePast) return f.afterDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = f.afterDate;
    if (picked == null) return today;
    return picked.isAfter(today) ? picked : today;
  }

  void _load(BuildContext blocContext) {
    blocContext.read<TripBloc>().add(
          TripsLoadRequested(
            destination: _filters.destinationCountry,
            afterDate: _effectiveAfterDate(_filters),
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
        return TripFilterSheet(
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
    return BlocProvider<TripBloc>(
      create: (_) => GetIt.instance<TripBloc>()
        ..add(
          TripsLoadRequested(
            destination: _filters.destinationCountry,
            afterDate: _effectiveAfterDate(_filters),
          ),
        ),
      child: BlocConsumer<TripBloc, TripState>(
        listenWhen: (_, s) => s is TripError,
        listener: (context, state) {
          if (state is TripError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final trips = state is TripsLoaded ? state.trips : const <TripModel>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Available Trips'),
              actions: [
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
                          if (_filters.destinationCountry != null &&
                              _filters.destinationCountry!.trim().isNotEmpty)
                            InputChip(
                              label: Text('Country: ${_filters.destinationCountry}'),
                              onDeleted: () {
                                setState(() {
                                  _filters = TripFilters(
                                    destinationCountry: null,
                                    afterDate: _filters.afterDate,
                                    includePast: _filters.includePast,
                                  );
                                });
                                _load(context);
                              },
                            ),
                          if (_filters.afterDate != null)
                            InputChip(
                              label: Text(
                                'After: ${_filters.afterDate!.toLocal().toString().split(' ').first}',
                              ),
                              onDeleted: () {
                                setState(() {
                                  _filters = TripFilters(
                                    destinationCountry: _filters.destinationCountry,
                                    afterDate: null,
                                    includePast: _filters.includePast,
                                  );
                                });
                                _load(context);
                              },
                            ),
                          if (_filters.includePast)
                            InputChip(
                              label: const Text('Including past trips'),
                              onDeleted: () {
                                setState(() {
                                  _filters = TripFilters(
                                    destinationCountry: _filters.destinationCountry,
                                    afterDate: _filters.afterDate,
                                    includePast: false,
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
                      TripLoading() => const Center(child: CircularProgressIndicator()),
                      TripsLoaded() => trips.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(child: Text('No trips found.')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: trips.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final t = trips[i];
                                return TripCard(
                                  trip: t,
                                  onTap: () => context.push('${RoutePaths.trips}/${t.id}'),
                                );
                              },
                            ),
                      TripError() => ListView(
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
              heroTag: 'trips_list_fab',
              onPressed: () => context.push(RoutePaths.tripsCreate),
              icon: const Icon(Icons.add),
              label: const Text('Post Trip'),
            ),
          );
        },
      ),
    );
  }
}
