import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/models/user_model.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../../../core/widgets/cached_image.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => GetIt.instance<ProfileBloc>()..add(ProfileLoadRequested(uid)),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Traveler Profile')),
            body: switch (state) {
              ProfileLoading() => const Center(child: CircularProgressIndicator()),
              ProfileLoaded() => _ProfileBody(user: state.user),
              ProfileError() => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            context.read<ProfileBloc>().add(ProfileLoadRequested(uid)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ProfileImage(
            displayName: user.fullName,
            imageUrl: user.photoUrl,
            size: 120,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.fullName,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: _VerificationBadge(verified: user.verified),
        ),
        const SizedBox(height: 4),
        if (user.createdAt != null)
          Center(
            child: Text(
              'Joined ${DateFormat.yMMMM().format(user.createdAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            user.bio!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 24),
        Center(
          child: _RatingRow(
            rating: user.rating,
            reviews: user.totalReviews,
          ),
        ),
        const SizedBox(height: 24),
        _StatsRow(user: user),
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          title: const Text('Reviews'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reviews coming soon')),
            );
          },
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, String value) {
      return Expanded(
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return Row(
      children: [
        item('Deliveries', user.completedDeliveries.toString()),
        item('Reviews', user.totalReviews.toString()),
        item('Rating', user.rating.toStringAsFixed(1)),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor().clamp(0, 5);
    final halfStar = (rating - fullStars) >= 0.5;

    final stars = <Widget>[];
    for (var i = 0; i < 5; i++) {
      IconData icon;
      if (i < fullStars) {
        icon = Icons.star;
      } else if (i == fullStars && halfStar) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }
      stars.add(Icon(icon, size: 18, color: Colors.amber));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text('($reviews reviews)'),
      ],
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = verified ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = verified ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        verified ? 'Verified Traveler' : 'Unverified',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
