import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stat_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeHeader(user: user),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 10),
                      _QuickActions(user: user),
                      const SizedBox(height: 18),
                      const SectionHeader(title: 'Your Stats'),
                      const SizedBox(height: 10),
                      _StatsSection(user: user),
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Recent Activity',
                        actionText: 'See All',
                        onActionTap: () {},
                      ),
                      const SizedBox(height: 10),
                      const _RecentActivityPlaceholder(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        QuickActionCard(
          icon: Icons.flight,
          title: 'Post a Trip',
          subtitle: 'Earn by delivering items',
          color: scheme.primary,
          onTap: () => context.push(RoutePaths.tripsCreate),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          icon: Icons.inventory_2,
          title: 'Send Item',
          subtitle: 'Create a delivery request',
          color: scheme.secondary,
          onTap: () => context.push(RoutePaths.requestsCreate),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final allZero = user.completedDeliveries == 0 && user.rating == 0 && user.totalReviews == 0;

    if (allZero) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Complete your first delivery to see your stats',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline,
            value: user.completedDeliveries.toString(),
            label: 'Completed Deliveries',
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.star_border,
            value: user.rating.toStringAsFixed(1),
            label: 'Rating',
            color: scheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.rate_review_outlined,
            value: user.totalReviews.toString(),
            label: 'Reviews',
            color: scheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityPlaceholder extends StatelessWidget {
  const _RecentActivityPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.history, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No recent activity',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
