import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';
import '../widgets/trip_card.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view your trips.')),
          );
        }

        final uid = authState.user.uid;

        return BlocProvider<TripBloc>(
          create: (_) => GetIt.instance<TripBloc>()..add(MyTripsLoadRequested(uid)),
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('My Trips'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
              body: BlocConsumer<TripBloc, TripState>(
                listenWhen: (_, s) => s is TripError,
                listener: (context, state) {
                  if (state is TripError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  final all = state is TripsLoaded ? state.trips : const <TripModel>[];

                  List<TripModel> byStatus(TripStatus status) {
                    return all.where((t) => t.status == status).toList(growable: false);
                  }

                  Widget tabList(List<TripModel> trips, String empty) {
                    if (state is TripLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (trips.isEmpty) {
                      return Center(child: Text(empty));
                    }

                    return ListView.separated(
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
                    );
                  }

                  return TabBarView(
                    children: [
                      tabList(byStatus(TripStatus.active), 'No active trips.'),
                      tabList(byStatus(TripStatus.completed), 'No completed trips.'),
                      tabList(byStatus(TripStatus.cancelled), 'No cancelled trips.'),
                    ],
                  );
                },
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => context.push(RoutePaths.tripsCreate),
                icon: const Icon(Icons.add),
                label: const Text('Post Trip'),
              ),
            ),
          ),
        );
      },
    );
  }
}
