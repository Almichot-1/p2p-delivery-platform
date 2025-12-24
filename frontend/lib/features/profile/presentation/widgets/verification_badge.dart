import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/models/user_model.dart';

class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final bool showLabel;
  final double size;

  const VerificationBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return _buildIcon();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColor().withAlpha(77),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 4),
          Text(
            _getLabel(),
            style: AppTextStyles.labelSmall.copyWith(
              color: _getColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      _getIcon(),
      size: size,
      color: _getColor(),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.pending:
        return Icons.hourglass_empty;
      case VerificationStatus.unverified:
        return Icons.gpp_maybe;
      case VerificationStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getColor() {
    switch (status) {
      case VerificationStatus.verified:
        return AppColors.success;
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.unverified:
        return AppColors.grey500;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }

  String _getLabel() {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.unverified:
        return 'Not Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }
}
