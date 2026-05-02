import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/subscription_provider.dart';

/// Paywall modal bottom sheet shown when a user hits a feature gate.
///
/// Display via [PaywallScreen.show] — never push directly as a route.
class PaywallScreen extends StatelessWidget {
  final String headline;
  final String? subtext;

  const PaywallScreen({
    super.key,
    required this.headline,
    this.subtext,
  });

  static Future<void> show(
    BuildContext context, {
    required String headline,
    String? subtext,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaywallScreen(headline: headline, subtext: subtext),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Overload Pro',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Context headline
                Text(
                  headline,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtext != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtext!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // Benefits list
                ..._benefits.map(
                  (b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(b, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (sub.isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Annual plan card (recommended)
                  _PlanCard(
                    label: 'Annual',
                    badge: 'RECOMMENDED',
                    savings: 'Save 52% vs monthly',
                    price: sub.annualProduct?.price ?? '\$39.99/year',
                    detail: 'Billed annually · 14-day free trial',
                    isRecommended: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      sub.purchaseAnnual();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Monthly plan card
                  _PlanCard(
                    label: 'Monthly',
                    price: sub.monthlyProduct?.price ?? '\$6.99/month',
                    detail: '14-day free trial',
                    isRecommended: false,
                    onTap: () {
                      Navigator.of(context).pop();
                      sub.purchaseMonthly();
                    },
                  ),
                ],

                if (sub.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    sub.error!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),

                // Restore purchases
                TextButton(
                  onPressed: sub.isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          sub.restorePurchases();
                        },
                  child: const Text('Already subscribed? Restore purchases'),
                ),

                // Legal footnote with tappable links
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'By subscribing you agree to our ',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _launchUrl('https://overloadapp.com/terms'),
                      child: Text(
                        'Terms of Service',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' and ',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _launchUrl('https://overloadapp.com/privacy'),
                      child: Text(
                        'Privacy Policy',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      '.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

const List<String> _benefits = [
  'Unlimited programs',
  'Full analytics history — all time',
  'Exercise progress charts & 1RM trends',
  'Muscle group volume breakdown',
  'Training trend charts',
  'Access all pre-built program templates',
  'Save unlimited custom templates',
  'Up to 50 custom exercises',
];

class _PlanCard extends StatelessWidget {
  final String label;
  final String? badge;
  final String? savings;
  final String price;
  final String detail;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.label,
    this.badge,
    this.savings,
    required this.price,
    required this.detail,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isRecommended ? 2 : 1,
          ),
          color: isRecommended
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (savings != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      savings!,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
