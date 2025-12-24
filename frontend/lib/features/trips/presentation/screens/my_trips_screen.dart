import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';
import '../widgets/trip_card.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TripBloc>()..add(MyTripsLoadRequested()),
      child: const _MyTripsView(),
    );
  }
}

class _MyTripsView extends StatefulWidget {
  const _MyTripsView();

  @override
  State<_MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<_MyTripsView>
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
        title: const Text('My Trips'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const LoadingWidget();
          }

          if (state is TripsLoaded) {
            final activeTrips = state.trips
                .where((t) =>
                    t.status == TripStatus.active ||
                    t.status == TripStatus.draft)
                .toList();
            final completedTrips = state.trips
                .where((t) => t.status == TripStatus.completed)
                .toList();
            final cancelledTrips = state.trips
                .where((t) => t.status == TripStatus.cancelled)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList(activeTrips, 'No active trips'),
                _buildTripsList(completedTrips, 'No completed trips'),
                _buildTripsList(cancelledTrips, 'No cancelled trips'),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteConstants.createTrip),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  Widget _buildTripsList(List<TripModel> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.flight_outlined,
        title: emptyMessage,
        subtitle: 'Your trips will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TripCard(
            trip: trip,
            onTap: () => context.push(
              RouteConstants.tripDetails.replaceFirst(':id', trip.id),
            ),
          ),
        );
      },
    );
  }
}
