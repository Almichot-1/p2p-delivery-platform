import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../trips/bloc/trip_bloc.dart';
import '../../../trips/bloc/trip_event.dart';
import '../../../trips/bloc/trip_state.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../../trips/presentation/widgets/trip_card.dart';
import '../../../requests/bloc/request_bloc.dart';
import '../../../requests/bloc/request_event.dart';
import '../../../requests/bloc/request_state.dart';
import '../../../requests/data/models/request_model.dart';
import '../../../requests/presentation/widgets/request_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.instance<TripBloc>()..add(const TripsLoadRequested())),
        BlocProvider(create: (_) => GetIt.instance<RequestBloc>()..add(const RequestsLoadRequested())),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search trips or requests...',
              border: InputBorder.none,
            ),
            onChanged: _onSearch,
          ),
          actions: [
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  _onSearch('');
                },
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Trips'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _TripsSearchResults(query: _searchQuery),
            _RequestsSearchResults(query: _searchQuery),
          ],
        ),
      ),
    );
  }
}

class _TripsSearchResults extends StatelessWidget {
  const _TripsSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripBloc, TripState>(
      builder: (context, state) {
        if (state is TripLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final trips = state is TripsLoaded ? state.trips : <TripModel>[];
        
        // Filter by query
        final filtered = query.isEmpty
            ? trips
            : trips.where((t) {
                final searchable = '${t.originCity} ${t.destinationCity} ${t.destinationCountry} ${t.travelerName}'.toLowerCase();
                return searchable.contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flight, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  query.isEmpty ? 'No trips available' : 'No trips found for "$query"',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final trip = filtered[i];
            return TripCard(
              trip: trip,
              onTap: () => context.push('${RoutePaths.trips}/${trip.id}'),
            );
          },
        );
      },
    );
  }
}

class _RequestsSearchResults extends StatelessWidget {
  const _RequestsSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestBloc, RequestState>(
      builder: (context, state) {
        if (state is RequestLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = state is RequestsLoaded ? state.requests : <RequestModel>[];
        
        // Filter by query
        final filtered = query.isEmpty
            ? requests
            : requests.where((r) {
                final searchable = '${r.title} ${r.pickupCity} ${r.deliveryCity} ${r.requesterName}'.toLowerCase();
                return searchable.contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  query.isEmpty ? 'No requests available' : 'No requests found for "$query"',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final request = filtered[i];
            return RequestCard(
              request: request,
              onTap: () => context.push('${RoutePaths.requests}/${request.id}'),
            );
          },
        );
      },
    );
  }
}
