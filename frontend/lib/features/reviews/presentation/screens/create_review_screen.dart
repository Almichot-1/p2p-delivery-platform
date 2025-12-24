import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../matches/bloc/match_bloc.dart';
import '../../../matches/bloc/match_event.dart';
import '../../../matches/bloc/match_state.dart';
import '../../bloc/review_bloc.dart';
import '../../bloc/review_event.dart';
import '../../bloc/review_state.dart';
import '../../data/models/review_model.dart';

class CreateReviewScreen extends StatefulWidget {
  final String matchId;

  const CreateReviewScreen({super.key, required this.matchId});

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<MatchBloc>()..add(MatchDetailsRequested(widget.matchId)),
        ),
        BlocProvider(create: (_) => getIt<ReviewBloc>()),
      ],
      child: BlocListener<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewCreated) {
            Helpers.showSuccessSnackBar(context, 'Review submitted!');
            context.pop();
          } else if (state is ReviewError) {
            Helpers.showErrorSnackBar(context, state.message);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Leave a Review'),
          ),
          body: BlocBuilder<MatchBloc, MatchState>(
            builder: (context, state) {
              if (state is MatchDetailsLoaded) {
                return _buildContent(context, state.match);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, match) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final currentUserId = authState.user.uid;
    final otherName = match.getOtherParticipantName(currentUserId);
    final otherPhoto = match.getOtherParticipantPhoto(currentUserId);
    final isTraveler = currentUserId == match.travelerId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User being reviewed
          UserAvatar(
            imageUrl: otherPhoto,
            name: otherName,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(otherName, style: AppTextStyles.h4),
          Text(
            isTraveler ? 'Requester' : 'Traveler',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            match.itemTitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 32),

          // Rating
          const Text('How was your experience?', style: AppTextStyles.h6),
          const SizedBox(height: 16),
          InteractiveRatingStars(
            rating: _rating,
            onRatingChanged: (rating) {
              setState(() => _rating = rating);
            },
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingText(_rating),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // Comment
          CustomTextField(
            label: 'Write a review (optional)',
            hint: 'Share your experience...',
            controller: _commentController,
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Submit button
          BlocBuilder<ReviewBloc, ReviewState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Submit Review',
                onPressed: _rating > 0
                    ? () => _submitReview(context, match, authState.user)
                    : null,
                isLoading: state is ReviewLoading,
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent!';
  }

  void _submitReview(BuildContext context, match, user) {
    final currentUserId = user.uid;
    final isTraveler = currentUserId == match.travelerId;

    final review = ReviewModel(
      id: '',
      matchId: match.id,
      reviewerId: currentUserId,
      reviewerName: user.fullName,
      reviewerPhoto: user.photoUrl,
      revieweeId: isTraveler ? match.requesterId : match.travelerId,
      revieweeName: isTraveler ? match.requesterName : match.travelerName,
      rating: _rating,
      comment: _commentController.text.trim(),
      isTravelerReview: !isTraveler,
      createdAt: DateTime.now(),
    );

    context.read<ReviewBloc>().add(ReviewCreateRequested(review));
  }
}
