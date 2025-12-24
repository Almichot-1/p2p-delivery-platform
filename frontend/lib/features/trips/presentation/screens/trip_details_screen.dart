import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';

class TripDetailsScreen extends StatelessWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TripBloc>()..add(TripDetailsRequested(tripId)),
      child: const _TripDetailsView(),
    );
  }
}

class _TripDetailsView extends StatelessWidget {
  const _TripDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading) {
            return const LoadingWidget();
          }

          if (state is TripError) {
            return Center(child: Text(state.message));
          }

          if (state is TripDetailsLoaded) {
            return _buildContent(context, state.trip);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TripModel trip) {
    final authState = context.read<AuthBloc>().state;
    final isOwner =
        authState is AuthAuthenticated && authState.user.uid == trip.travelerId;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.flight,
                      size: 60,
                      color: Colors.white.withAlpha(230),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trip.routeDisplay,
                      style: AppTextStyles.h4.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (isOwner)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, trip),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Cancel Trip',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status
                Center(child: StatusBadge(status: trip.status.name)),
                const SizedBox(height: 24),

                // Traveler Card
                _buildTravelerCard(context, trip),
                const SizedBox(height: 24),

                // Route Details
                _buildSection(
                  title: 'Route Details',
                  child: _buildRouteDetails(trip),
                ),
                const SizedBox(height: 24),

                // Trip Details
                _buildSection(
                  title: 'Trip Information',
                  child: _buildTripInfo(trip),
                ),
                const SizedBox(height: 24),

                // Accepted Items
                if (trip.acceptedItemTypes.isNotEmpty)
                  _buildSection(
                    title: 'Accepted Item Types',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: trip.acceptedItemTypes.map((type) {
                        return Chip(
                          label: Text(type),
                          backgroundColor: AppColors.primary.withAlpha(26),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 24),

                // Notes
                if (trip.notes != null && trip.notes!.isNotEmpty)
                  _buildSection(
                    title: 'Additional Notes',
                    child: Text(
                      trip.notes!,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerCard(BuildContext context, TripModel trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: trip.travelerPhoto,
              name: trip.travelerName,
              size: 60,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.travelerName, style: AppTextStyles.h5),
                  const SizedBox(height: 4),
                  RatingStars(
                    rating: trip.travelerRating,
                    size: 16,
                    showValue: true,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // View profile
                context.push('/profile/${trip.travelerId}');
              },
              icon: const Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h6),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildRouteDetails(TripModel trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.flight_takeoff, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text('From', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    trip.originCity,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    trip.originCountry,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 2,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd').format(trip.departureDate),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.flight_land, color: AppColors.success),
                  const SizedBox(height: 8),
                  const Text('To', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    trip.destinationCity,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    trip.destinationCountry,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo(TripModel trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Departure Date',
              value:
                  DateFormat('EEEE, MMM dd, yyyy').format(trip.departureDate),
            ),
            if (trip.returnDate != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.event_available,
                label: 'Return Date',
                value:
                    DateFormat('EEEE, MMM dd, yyyy').format(trip.returnDate!),
              ),
            ],
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.fitness_center,
              label: 'Available Capacity',
              value: '${trip.availableCapacityKg.toStringAsFixed(1)} kg',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Price per kg',
              value: trip.pricePerKg > 0
                  ? '\$${trip.pricePerKg.toStringAsFixed(2)}'
                  : 'Free / Negotiable',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action, TripModel trip) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'cancel':
        _showCancelDialog(context, trip);
        break;
    }
  }

  void _showCancelDialog(BuildContext context, TripModel trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Trip'),
        content: const Text(
          'Are you sure you want to cancel this trip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TripBloc>().add(TripCancelRequested(trip.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
