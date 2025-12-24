import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => context.push(RouteConstants.settings),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Profile header
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                            imageUrl: user.photoUrl,
                            name: user.fullName,
                            size: 100,
                          ),
                          if (user.isVerified)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(user.fullName, style: AppTextStyles.h4),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RatingStars(
                        rating: user.rating,
                        totalReviews: user.totalReviews,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('${user.completedDeliveries}', 'Deliveries'),
                      _buildDivider(),
                      _buildStat('${user.totalReviews}', 'Reviews'),
                      _buildDivider(),
                      _buildStat(user.rating.toStringAsFixed(1), 'Rating'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Menu items
                _buildMenuItem(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  onTap: () => context.push(RouteConstants.editProfile),
                ),
                _buildMenuItem(
                  icon: Icons.flight,
                  title: 'My Trips',
                  onTap: () => context.push(RouteConstants.myTrips),
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2,
                  title: 'My Requests',
                  onTap: () => context.push(RouteConstants.myRequests),
                ),
                _buildMenuItem(
                  icon: Icons.star,
                  title: 'My Reviews',
                  onTap: () => context.push(
                    RouteConstants.reviews.replaceFirst(':userId', user.uid),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.verified_user,
                  title: 'Verification',
                  trailing: user.isVerified
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push(RouteConstants.verification),
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  textColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h4),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.grey300,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.grey700),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(color: textColor),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
