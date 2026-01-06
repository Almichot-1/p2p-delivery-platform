import 'package:flutter/material.dart';

enum CustomButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (isLoading || icon != null) const SizedBox(width: 10),
        Text(label),
      ],
    );

    switch (type) {
      case CustomButtonType.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            child: child,
          ),
        );
      case CustomButtonType.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: FilledButton.tonal(
            onPressed: isDisabled ? null : onPressed,
            child: child,
          ),
        );
      case CustomButtonType.outline:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isDisabled ? null : onPressed,
            child: child,
          ),
        );
      case CustomButtonType.text:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: isDisabled ? null : onPressed,
            child: child,
          ),
        );
    }
  }
}
