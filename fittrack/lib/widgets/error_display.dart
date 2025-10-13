import 'package:flutter/material.dart';

/// A consistent, user-friendly error display widget
/// Provides unified error presentation across the app
class ErrorDisplay extends StatelessWidget {
  /// User-friendly error message to display
  final String message;

  /// Optional technical error details (hidden from users in production)
  final String? technicalError;

  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  /// Optional custom icon (defaults to error_outline)
  final IconData? icon;

  /// Optional custom title (defaults to "Something went wrong")
  final String? title;

  const ErrorDisplay({
    super.key,
    required this.message,
    required this.onRetry,
    this.technicalError,
    this.icon,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title ?? 'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // User-friendly message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Retry Button
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
