import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../auth/data/models/user_model.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final firstName = _firstName(user.fullName);

    return Container(
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
                  IconButton(
                    onPressed: () => context.push(RoutePaths.notifications),
                    icon: Icon(Icons.notifications_outlined, color: scheme.onPrimaryContainer),
                    tooltip: 'Notifications',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SearchBarPlaceholder(onTap: () {}),
            ],
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
