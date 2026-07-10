import 'package:flutter/material.dart';

/// In-memory flag set once at app startup when `?checkout=success` is detected
/// in the URL. Cleared on dismiss so the banner never re-appears in the same
/// session (though a hard refresh that retains the URL will re-show it, which
/// is benign — the user paid and "Welcome to Pro" is harmless to see twice).
class CheckoutSuccessService {
  static bool pendingWelcome = false;
  static void dismiss() => pendingWelcome = false;
}

/// Shown at the top of the programs list when the user returns to the app
/// after a successful Stripe Checkout (`?checkout=success` in the URL).
///
/// Invisible (SizedBox.shrink) when conditions are not met.
class CheckoutSuccessBanner extends StatefulWidget {
  const CheckoutSuccessBanner({super.key});

  @override
  State<CheckoutSuccessBanner> createState() => _CheckoutSuccessBannerState();
}

class _CheckoutSuccessBannerState extends State<CheckoutSuccessBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !CheckoutSuccessService.pendingWelcome) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: colorScheme.onPrimaryContainer, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Welcome to Overload Pro!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Dismiss',
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your subscription is now active. All Pro features are unlocked.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismiss() {
    CheckoutSuccessService.dismiss();
    setState(() => _dismissed = true);
  }
}
