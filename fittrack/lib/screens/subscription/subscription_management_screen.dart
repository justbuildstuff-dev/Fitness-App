import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  static const _iosManageUrl = 'https://apps.apple.com/account/subscriptions';
  static const _androidManageUrl =
      'https://play.google.com/store/account/subscriptions';

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Plan header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Overload Pro',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sub.isProOverride) ...[
                  Text('Developer access', style: textTheme.bodyMedium),
                ] else ...[
                  Text(
                    _planLabel(sub.subscriptionInfo),
                    style: textTheme.bodyMedium,
                  ),
                  if (sub.subscriptionInfo.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _expiryLabel(sub.subscriptionInfo),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (!sub.isProOverride) ...[
            FilledButton.icon(
              onPressed: () => _openManageSubscription(),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Manage subscription'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
          ],

          OutlinedButton(
            onPressed: sub.isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                    sub.restorePurchases();
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: sub.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Restore purchases'),
          ),

          if (sub.error != null) ...[
            const SizedBox(height: 12),
            Text(
              sub.error!,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _planLabel(SubscriptionInfo info) {
    if (info.productId?.contains('annual') == true) return 'Annual plan';
    if (info.productId?.contains('monthly') == true) return 'Monthly plan';
    return 'Active subscription';
  }

  String _expiryLabel(SubscriptionInfo info) {
    if (info.expiresAt == null) return '';
    final d = info.expiresAt!;
    return 'Renews ${d.day}/${d.month}/${d.year}';
  }

  Future<void> _openManageSubscription() async {
    final url = Platform.isIOS ? _iosManageUrl : _androidManageUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
