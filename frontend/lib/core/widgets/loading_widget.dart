import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';

enum LoadingType { circular, dots, wave, pulse }

class LoadingWidget extends StatelessWidget {
  final LoadingType type;
  final double size;
  final Color? color;
  final String? message;

  const LoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.size = 40,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? AppColors.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoader(loadingColor),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.grey600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoader(Color loadingColor) {
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
          ),
        );
      case LoadingType.dots:
        return SpinKitThreeBounce(
          color: loadingColor,
          size: size,
        );
      case LoadingType.wave:
        return SpinKitWave(
          color: loadingColor,
          size: size,
        );
      case LoadingType.pulse:
        return SpinKitPulse(
          color: loadingColor,
          size: size,
        );
    }
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingWidget(
        type: LoadingType.dots,
        message: message ?? 'Loading...',
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(128),
            child: LoadingWidget(
              color: AppColors.white,
              message: message,
            ),
          ),
      ],
    );
  }
}
