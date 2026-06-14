import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

/// Manages subscription billing via the Firebase Stripe Extension.
///
/// The Firebase Stripe Extension syncs Stripe subscription state to Firestore
/// under `customers/{userId}/subscriptions`. Checkout sessions are created by
/// writing to `customers/{userId}/checkout_sessions`; the extension populates
/// the Stripe Checkout URL asynchronously.
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();

  // Stripe Price IDs — set these after creating products in the Stripe Dashboard.
  // Format: price_XXXXXXXXXXXXXXXXXXXXXXXX
  static const String monthlyPriceId = 'price_monthly_placeholder';
  static const String annualPriceId = 'price_annual_placeholder';
  static const String lifetimePriceId = 'price_lifetime_placeholder';

  // Stripe Customer Portal shareable link — configured in Stripe Dashboard →
  // Settings → Billing → Customer Portal.
  static const String stripePortalUrl =
      'https://billing.stripe.com/p/login/placeholder';

  final FirebaseFirestore? _injectedFirestore;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  SubscriptionService._() : _injectedFirestore = null;

  @visibleForTesting
  SubscriptionService.forTest(FirebaseFirestore firestore)
      : _injectedFirestore = firestore;

  /// Real-time stream of active Stripe subscriptions for [userId].
  /// Emits [SubscriptionInfo.free] when no active/trialing subscriptions exist.
  Stream<SubscriptionInfo> subscriptionStream(String userId) {
    return _firestore
        .collection('customers')
        .doc(userId)
        .collection('subscriptions')
        .where('status', whereIn: ['active', 'trialing'])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return SubscriptionInfo.free();
          return SubscriptionInfo.fromStripeFirestore(
              snapshot.docs.first.data());
        });
  }

  /// One-shot read of subscription status for [userId].
  /// Returns [SubscriptionInfo.free] when no active subscriptions exist.
  Future<SubscriptionInfo> loadFromFirestore(String userId) async {
    final snapshot = await _firestore
        .collection('customers')
        .doc(userId)
        .collection('subscriptions')
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return SubscriptionInfo.free();
    return SubscriptionInfo.fromStripeFirestore(snapshot.docs.first.data());
  }

  /// Creates a Stripe Checkout session and returns the hosted Checkout URL.
  ///
  /// Writes a session document to `customers/{userId}/checkout_sessions`;
  /// the Firebase Stripe Extension creates the Stripe session and writes back
  /// the `url` field. Throws if the extension returns an error or times out.
  Future<String> createCheckoutSession({
    required String userId,
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final sessionRef = await _firestore
        .collection('customers')
        .doc(userId)
        .collection('checkout_sessions')
        .add({
      'price': priceId,
      'success_url': successUrl,
      'cancel_url': cancelUrl,
      'mode': priceId == lifetimePriceId ? 'payment' : 'subscription',
      'allow_promotion_codes': true,
    });

    // Extension populates 'url' (or 'error') asynchronously — wait up to 10s.
    final snapshot = await sessionRef
        .snapshots()
        .firstWhere((snap) =>
            snap.data()?['url'] != null || snap.data()?['error'] != null)
        .timeout(const Duration(seconds: 10));

    final error = snapshot.data()?['error'] as String?;
    if (error != null) throw Exception('Stripe checkout error: $error');

    return snapshot.data()!['url'] as String;
  }
}
