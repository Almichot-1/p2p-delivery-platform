import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../widgets/trip_card.dart';
import '../widgets/trip_filter.dart';

class TripsListScreen extends StatelessWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TripBloc>()..add(const TripsLoadRequested()),
      child: const _TripsListView(),
    );
  }
}

class _TripsListView extends StatefulWidget {
  const _TripsListView();

  @override
  State<_TripsListView> createState() => _TripsListViewState();
}

class _TripsListViewState extends State<_TripsListView> {
  String? _selectedCity;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          if (_selectedCity != null || _selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_selectedCity != null)
                    _buildFilterChip(
                      label: _selectedCity!,
                      onRemove: () {
                        setState(() => _selectedCity = null);
                        _applyFilters();
                      },
                    ),
                  if (_selectedDate != null)
                    _buildFilterChip(
                      label: '${_selectedDate!.day}/${_selectedDate!.month}',
                      onRemove: () {
                        setState(() => _selectedDate = null);
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),

          // Trips list
          Expanded(
            child: BlocBuilder<TripBloc, TripState>(
              builder: (context, state) {
                if (state is TripLoading) {
                  return const LoadingWidget();
                }

                if (state is TripError) {
                  return Center(
                    child: Text(state.message),
                  );
                }

                if (state is TripsLoaded) {
                  if (state.trips.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.flight_outlined,
                      title: 'No Trips Available',
                      subtitle: 'Check back later for new trips',
                      buttonText: 'Post a Trip',
                      onButtonPressed: () =>
                          context.push(RouteConstants.createTrip),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TripBloc>().add(TripsLoadRequested(
                            destinationCity: _selectedCity,
                            afterDate: _selectedDate,
                          ));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.trips.length,
                      itemBuilder: (context, index) {
                        final trip = state.trips[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TripCard(
                            trip: trip,
                            onTap: () => context.push(
                              RouteConstants.tripDetails
                                  .replaceFirst(':id', trip.id),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.createTrip),
        icon: const Icon(Icons.add),
        label: const Text('Post Trip'),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onRemove,
        backgroundColor: AppColors.primary.withAlpha(26),
        labelStyle: const TextStyle(color: AppColors.primary),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TripFilter(
        selectedCity: _selectedCity,
        selectedDate: _selectedDate,
        onApply: (city, date) {
          setState(() {
            _selectedCity = city;
            _selectedDate = date;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _applyFilters() {
    context.read<TripBloc>().add(TripsLoadRequested(
          destinationCity: _selectedCity,
          afterDate: _selectedDate,
        ));
  }
}
