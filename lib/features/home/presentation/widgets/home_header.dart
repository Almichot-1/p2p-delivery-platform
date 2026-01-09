import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../notifications/bloc/notification_bloc.dart';
import '../../../notifications/bloc/notification_event.dart';
import '../../../notifications/bloc/notification_state.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final firstName = _firstName(user.fullName);

    return BlocProvider(
      create: (_) => GetIt.instance<NotificationBloc>()
        ..add(NotificationsLoadRequested(user.uid)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              scheme.primaryContainer,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => context.push(RoutePaths.profile),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ProfileImage(
                          displayName: user.fullName,
                          imageUrl: user.photoUrl,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: scheme.onPrimaryContainer),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _NotificationButton(scheme: scheme),
                  ],
                ),
                const SizedBox(height: 14),
                _SearchBarPlaceholder(onTap: () => context.push(RoutePaths.search)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'There';
    return parts.first;
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;

        return Stack(
          children: [
            IconButton(
              onPressed: () => context.push(RoutePaths.notifications),
              icon: Icon(Icons.notifications_outlined, color: scheme.onPrimaryContainer),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchBarPlaceholder extends StatelessWidget {
  const _SearchBarPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withAlpha((0.18 * 255).round()),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              Icon(Icons.tune, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
