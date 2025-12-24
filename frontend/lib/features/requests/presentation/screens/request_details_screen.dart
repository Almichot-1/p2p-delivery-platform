import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';
import '../widgets/item_images_carousel.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RequestBloc>()..add(RequestDetailsRequested(requestId)),
      child: const _RequestDetailsView(),
    );
  }
}

class _RequestDetailsView extends StatelessWidget {
  const _RequestDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RequestBloc, RequestState>(
        listener: (context, state) {
          if (state is RequestCancelled) {
            Helpers.showSuccessSnackBar(context, 'Request cancelled');
            context.pop();
          } else if (state is RequestError) {
            Helpers.showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is RequestLoading) {
            return const LoadingWidget();
          }

          if (state is RequestError) {
            return Center(child: Text(state.message));
          }

          if (state is RequestDetailsLoaded) {
            return _buildContent(context, state.request);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, RequestModel request) {
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is AuthAuthenticated &&
        authState.user.uid == request.requesterId;

    return CustomScrollView(
      slivers: [
        // App Bar with images
        SliverAppBar(
          expandedHeight: request.imageUrls.isNotEmpty ? 300 : 150,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: request.imageUrls.isNotEmpty
                ? ItemImagesCarousel(imageUrls: request.imageUrls)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(request.category),
                        size: 60,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ),
          ),
          actions: [
            if (isOwner && request.status == RequestStatus.active)
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, request),
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
                        Text('Cancel Request',
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
                // Title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(request.title, style: AppTextStyles.h4),
                    ),
                    StatusBadge(status: request.status.name),
                  ],
                ),
                const SizedBox(height: 8),

                // Urgent badge
                if (request.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Urgent Delivery',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Description
                Text(
                  request.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Requester card
                _buildRequesterCard(context, request),
                const SizedBox(height: 24),

                // Route section
                _buildSection(
                  title: 'Delivery Route',
                  child: _buildRouteCard(request),
                ),
                const SizedBox(height: 24),

                // Item details
                _buildSection(
                  title: 'Item Details',
                  child: _buildItemDetails(request),
                ),
                const SizedBox(height: 24),

                // Recipient info
                _buildSection(
                  title: 'Recipient Information',
                  child: _buildRecipientInfo(request),
                ),
                const SizedBox(height: 24),

                // Price
                if (request.offeredPrice != null)
                  _buildSection(
                    title: 'Offered Compensation',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.attach_money,
                              color: AppColors.success),
                          Text(
                            '\$${request.offeredPrice!.toStringAsFixed(2)}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRequesterCard(BuildContext context, RequestModel request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: request.requesterPhoto,
              name: request.requesterName,
              size: 60,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.requesterName, style: AppTextStyles.h5),
                  const SizedBox(height: 4),
                  RatingStars(
                    rating: request.requesterRating,
                    size: 16,
                    showValue: true,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // View profile
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

  Widget _buildRouteCard(RequestModel request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(height: 8),
                      const Text('Pickup', style: AppTextStyles.caption),
                      const SizedBox(height: 4),
                      Text(
                        request.pickupCity,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        request.pickupCountry,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.arrow_forward,
                          color: AppColors.grey400, size: 32),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.flag, color: AppColors.success),
                      const SizedBox(height: 8),
                      const Text('Delivery', style: AppTextStyles.caption),
                      const SizedBox(height: 4),
                      Text(
                        request.deliveryCity,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        request.deliveryCountry,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.preferredDeliveryDate != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.grey600),
                  const SizedBox(width: 8),
                  Text(
                    'Preferred by ${DateFormat('MMM dd, yyyy').format(request.preferredDeliveryDate!)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetails(RequestModel request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Icons.category,
              label: 'Category',
              value: request.categoryDisplay,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.fitness_center,
              label: 'Weight',
              value: '${request.weightKg.toStringAsFixed(1)} kg',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Posted',
              value: DateFormat('MMM dd, yyyy').format(request.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientInfo(RequestModel request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Icons.person,
              label: 'Name',
              value: request.recipientName,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.phone,
              label: 'Phone',
              value: request.recipientPhone,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Address',
              value: request.deliveryAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
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

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.documents:
        return Icons.description;
      case ItemCategory.electronics:
        return Icons.devices;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.food:
        return Icons.restaurant;
      case ItemCategory.medicine:
        return Icons.medical_services;
      case ItemCategory.gifts:
        return Icons.card_giftcard;
      case ItemCategory.other:
        return Icons.inventory_2;
    }
  }

  void _handleMenuAction(
      BuildContext context, String action, RequestModel request) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'cancel':
        _showCancelDialog(context, request);
        break;
    }
  }

  void _showCancelDialog(BuildContext context, RequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<RequestBloc>()
                  .add(RequestCancelRequested(request.id));
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
