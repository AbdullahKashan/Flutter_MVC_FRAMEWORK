import 'package:flutter/material.dart';

/// A polished, customizable loading indicator widget with optional text and progress.
class LoadingView extends StatelessWidget {
  /// Optional message to display underneath the spinner.
  final String? message;

  /// Optional progress fraction (0.0 to 1.0). If null, an indeterminate spinner is shown.
  final double? progress;

  /// Custom color for the spinner and text.
  final Color? color;

  /// Diameter of the spinner.
  final double size;

  /// Custom widget to use instead of the default spinner.
  final Widget? customIndicator;

  const LoadingView({
    super.key,
    this.message,
    this.progress,
    this.color,
    this.size = 36.0,
    this.customIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            customIndicator ??
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator.adaptive(
                    value: progress,
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                  ),
                ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
