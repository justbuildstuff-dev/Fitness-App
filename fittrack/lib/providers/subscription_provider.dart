import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';

/// Manages subscription state sourced from the Firebase Stripe Extension.
///
/// Listens to `customers/{userId}/subscriptions` in real time and exposes
/// computed limits used throughout the app to gate premium features.
///
/// Registered as a [ChangeNotifierProxyProvider] so it reacts to auth state
/// changes — resetting when the user signs out and re-initialising when they
/// sign in.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionInfo _subscriptionInfo = SubscriptionInfo.free();
  bool _isProOverride = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<SubscriptionInfo>? _subscriptionStream;
  bool _disposed = false;

  // --- Public getters ---

  bool get isPro => _isProOverride || _subscriptionInfo.isPro;
  bool get isFree => !isPro;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SubscriptionInfo get subscriptionInfo => _subscriptionInfo;
  bool get isProOverride => _isProOverride;

  int get maxPrograms => isPro ? 999 : 3;
  int get maxCustomExercises => isPro ? 50 : 5;

  // --- ProxyProvider update ---

  void update(AuthProvider auth) {
    final userId = auth.user?.uid;
    final profile = auth.userProfile;
    if (userId == null) {
      _reset();
      return;
    }
    _isProOverride = profile?.isProOverride ?? false;
    _initialize(userId);
  }

  // --- Initialisation ---

  Future<void> _initialize(String userId) async {
    // Load cached status immediately so the UI has a value before stream fires.
    final cached = await SubscriptionService.instance.loadFromFirestore(userId);
    _subscriptionInfo = cached;
    _safeNotify();

    // Start real-time listener for live Stripe webhook updates.
    _subscriptionStream?.cancel();
    _subscriptionStream =
        SubscriptionService.instance.subscriptionStream(userId).listen(
      (info) {
        _subscriptionInfo = info;
        _safeNotify();
      },
      onError: (_) {}, // silent — cached value remains valid
    );
  }

  // --- Stripe Checkout ---

  /// Redirects the browser to a Stripe Checkout session for [priceId].
  /// Returns true if the URL launched successfully.
  Future<bool> startCheckout(String userId, String priceId) async {
    _error = null;
    _isLoading = true;
    _safeNotify();
    try {
      final url = await SubscriptionService.instance.createCheckoutSession(
        userId: userId,
        priceId: priceId,
        successUrl:
            'https://overload-workouts.web.app/?checkout=success',
        cancelUrl:
            'https://overload-workouts.web.app/?checkout=cancelled',
      );
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      _isLoading = false;
      _safeNotify();
      return launched;
    } catch (e) {
      _error = 'Could not start checkout. Please try again.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Opens the Stripe Customer Portal for subscription management.
  Future<void> openCustomerPortal() async {
    final uri = Uri.parse(SubscriptionService.stripePortalUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  @visibleForTesting
  void setSubscriptionInfoForTest(SubscriptionInfo info) {
    _subscriptionInfo = info;
    _safeNotify();
  }

  @visibleForTesting
  void setProOverrideForTest({required bool value}) {
    _isProOverride = value;
    _safeNotify();
  }

  // --- Reset on sign-out ---

  void _reset() {
    _subscriptionInfo = SubscriptionInfo.free();
    _isProOverride = false;
    _isLoading = false;
    _error = null;
    _subscriptionStream?.cancel();
    _subscriptionStream = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
