import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/subscription.dart';

/// Manages subscription billing via a Cloudflare Worker that proxies Stripe.
///
/// Checkout sessions are created by calling the Worker's
/// /create-checkout-session endpoint directly. Subscription state is written
/// to `customers/{userId}/subscriptions` by the Worker's webhook handler and
/// read back via a real-time Firestore stream.
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();

  // Stripe Price IDs — set these after creating products in the Stripe Dashboard.
  // Format: price_XXXXXXXXXXXXXXXXXXXXXXXX
  static const String monthlyPriceId = 'price_monthly_placeholder';
  static const String annualPriceId = 'price_annual_placeholder';

  // Cloudflare Worker base URL — set after deploying the Worker via `wrangler deploy`.
  // Format: https://fittrack-stripe-worker.<account>.workers.dev
  static const String _workerBaseUrl = 'https://fittrack-stripe-worker.placeholder.workers.dev';

  // Stripe Customer Portal shareable link — configured in Stripe Dashboard →
  // Settings → Billing → Customer Portal.
  static const String stripePortalUrl =
      'https://billing.stripe.com/p/login/placeholder';

  final FirebaseFirestore? _injectedFirestore;
  final http.Client? _injectedHttpClient;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  http.Client get _httpClient => _injectedHttpClient ?? http.Client();

  SubscriptionService._()
      : _injectedFirestore = null,
        _injectedHttpClient = null;

  @visibleForTesting
  SubscriptionService.forTest(
    FirebaseFirestore firestore,
    http.Client httpClient,
  )   : _injectedFirestore = firestore,
        _injectedHttpClient = httpClient;

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

  /// Creates a Stripe Checkout session via the Cloudflare Worker and returns
  /// the hosted Checkout URL. Throws if the Worker returns a non-200 response.
  Future<String> createCheckoutSession({
    required String userId,
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_workerBaseUrl/create-checkout-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': userId,
        'priceId': priceId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Checkout failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }
}
