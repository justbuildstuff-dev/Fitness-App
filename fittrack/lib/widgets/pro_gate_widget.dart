import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription/paywall_screen.dart';

/// Wraps a widget with a blur overlay and upgrade prompt when the user is on
/// the free tier. Renders the child directly for Pro subscribers.
class ProGateWidget extends StatelessWidget {
  final Widget child;
  final String paywallHeadline;
  final String? paywallSubtext;

  const ProGateWidget({
    super.key,
    required this.child,
    required this.paywallHeadline,
    this.paywallSubtext,
  });

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro) return child;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: IgnorePointer(child: child),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  paywallHeadline,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (paywallSubtext != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    paywallSubtext!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => PaywallScreen.show(
                    context,
                    headline: paywallHeadline,
                    subtext: paywallSubtext,
                  ),
                  child: const Text('Upgrade to Pro'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
