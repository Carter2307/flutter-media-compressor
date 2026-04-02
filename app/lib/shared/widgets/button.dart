import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

enum AppButtonVariant { elevated, outlined, text }

enum AppButtonSize {
  sm(36),
  md(48),
  lg(56);

  const AppButtonSize(this.height);
  final double height;
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = AppButtonVariant.elevated,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.elevated
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          )
        : Text(label);

    final pillShape = RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusFull,
    );

    final button = switch (variant) {
      AppButtonVariant.elevated => icon != null && !isLoading
          ? ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: child,
              style: ElevatedButton.styleFrom(shape: pillShape),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(shape: pillShape),
              child: child,
            ),
      AppButtonVariant.outlined => icon != null && !isLoading
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: Icon(icon, size: 18),
              label: child,
              style: OutlinedButton.styleFrom(shape: pillShape),
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(shape: pillShape),
              child: child,
            ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      height: size.height,
      child: button,
    );
  }
}
