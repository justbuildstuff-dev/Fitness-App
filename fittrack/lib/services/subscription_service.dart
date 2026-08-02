import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const String monthlyPriceId = 'price_1TkLIOCQsbNjPXf4upMfkVHi';
  static const String annualPriceId = 'price_1TkLJCCQsbNjPXf4Ry70HEkO';

  // Cloudflare Worker base URL — set after deploying the Worker via `wrangler deploy`.
  // Format: https://fittrack-stripe-worker.<account>.workers.dev
  static const String _workerBaseUrl = 'https://fittrack-stripe-worker.justbuildstuff-dev.workers.dev';

  // Stripe Customer Portal shareable link — configured in Stripe Dashboard →
  // Settings → Billing → Customer Portal.
  static const String stripePortalUrl =
      'https://billing.stripe.com/p/login/placeholder';

  final FirebaseFirestore? _injectedFirestore;
  final http.Client? _injectedHttpClient;
  final FirebaseAuth? _injectedAuth;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  http.Client get _httpClient => _injectedHttpClient ?? http.Client();

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  SubscriptionService._()
      : _injectedFirestore = null,
        _injectedHttpClient = null,
        _injectedAuth = null;

  @visibleForTesting
  SubscriptionService.forTest(
    FirebaseFirestore firestore,
    http.Client httpClient, [
    FirebaseAuth? auth,
  ])  : _injectedFirestore = firestore,
        _injectedHttpClient = httpClient,
        _injectedAuth = auth;

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
  ///
  /// The current user's Firebase ID token is sent so the Worker can verify
  /// the caller is actually authenticated as [userId] before starting a
  /// Stripe payment flow on their behalf.
  Future<String> createCheckoutSession({
    required String userId,
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final idToken = await _auth.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Checkout failed: no authenticated user');
    }

    final response = await _httpClient.post(
      Uri.parse('$_workerBaseUrl/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
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
