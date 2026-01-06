import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../auth/data/models/user_model.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../widgets/profile_image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in to view your profile.')),
          );
        }

        final uid = authState.user.uid;

        return BlocProvider<ProfileBloc>(
          create: (_) => GetIt.instance<ProfileBloc>()..add(ProfileLoadRequested(uid)),
          child: _ProfileView(uid: uid),
        );
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (_, current) => current is ProfileError || current is ProfileUpdated,
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is ProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go(RoutePaths.settings),
              ),
            ],
          ),
          body: switch (state) {
            ProfileLoading() => const Center(child: CircularProgressIndicator()),
            ProfileLoaded() => _ProfileBody(user: state.user),
            ProfileError() => _ProfileErrorView(
                message: state.message,
                onRetry: () => context.read<ProfileBloc>().add(ProfileLoadRequested(uid)),
              ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 44, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text('Could not load profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
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
          child: ProfileImagePicker(
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
          child: Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: _RatingRow(
            rating: user.rating,
            reviews: user.totalReviews,
          ),
        ),
        const SizedBox(height: 16),
        _StatsRow(user: user),
        const SizedBox(height: 20),
        _MenuTile(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () => context.go(RoutePaths.profileEdit),
        ),
        _MenuTile(
          icon: Icons.flight_takeoff,
          title: 'My Trips',
          onTap: () => context.go(RoutePaths.myTrips),
        ),
        _MenuTile(
          icon: Icons.inventory_2_outlined,
          title: 'My Requests',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            );
          },
        ),
        _MenuTile(
          icon: Icons.rate_review_outlined,
          title: 'My Reviews',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('My Reviews (coming soon)')),
            );
          },
        ),
        _MenuTile(
          icon: Icons.verified_outlined,
          title: 'Verification',
          trailing: _VerificationBadge(verified: user.verified),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(user.verified ? 'Verified' : 'Not verified yet')),
            );
          },
        ),
        const SizedBox(height: 8),
        _MenuTile(
          icon: Icons.logout,
          title: 'Logout',
          destructive: true,
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                );
              },
            );

            if (ok != true) return;
            context.read<AuthBloc>().add(const AuthLogoutRequested());
            if (context.mounted) context.go(RoutePaths.login);
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
        item('Completed Deliveries', user.completedDeliveries.toString()),
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
      stars.add(Icon(icon, size: 18));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 8),
        Text('($reviews)'),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        verified ? 'Verified' : 'Pending',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
