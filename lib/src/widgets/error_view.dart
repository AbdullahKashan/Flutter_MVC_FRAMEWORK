import 'package:flutter/material.dart';
import '../network/api_exception.dart';

/// A user-friendly error view displaying an error icon, explanatory message,
/// and an optional retry button.
class ErrorView extends StatelessWidget {
  /// The error object or exception that occurred.
  final dynamic error;

  /// Custom error message to override the default parsed error message.
  final String? message;

  /// Callback executed when the user taps the retry button.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryText;

  /// Custom icon or illustration to display.
  final Widget? icon;

  const ErrorView({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.retryText = 'Try Again',
    this.icon,
  });

  String _resolveMessage() {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    if (error is ApiException) {
      return (error as ApiException).message;
    }
    if (error != null) {
      final str = error.toString();
      if (str.startsWith('Exception: ')) {
        return str.substring('Exception: '.length);
      }
      return str;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMessage = _resolveMessage();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon ??
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
