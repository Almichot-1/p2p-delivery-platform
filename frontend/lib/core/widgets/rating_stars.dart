import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;
  final int totalReviews;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.showValue = true,
    this.totalReviews = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star;
            color = activeColor ?? AppColors.secondary;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
            color = activeColor ?? AppColors.secondary;
          } else {
            icon = Icons.star_border;
            color = inactiveColor ?? AppColors.grey300;
          }

          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          if (totalReviews > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($totalReviews)',
              style: TextStyle(
                fontSize: size * 0.6,
                color: AppColors.grey500,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              rating >= starValue ? Icons.star : Icons.star_border,
              size: size,
              color:
                  rating >= starValue ? AppColors.secondary : AppColors.grey300,
            ),
          ),
        );
      }),
    );
  }
}
