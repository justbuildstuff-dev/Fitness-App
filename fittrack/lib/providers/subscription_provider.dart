import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';

/// Manages subscription state and exposes computed limits used throughout
/// the app to gate premium features.
///
/// IAP purchase stream removed for PWA transition. Subscription status is
/// loaded from Firestore on sign-in. Full Stripe billing is added in Task #480.
///
/// Registered as a [ChangeNotifierProxyProvider] so it reacts to auth state
/// changes — resetting when the user signs out and re-initialising when they
/// sign in.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionInfo _subscriptionInfo = SubscriptionInfo.free();
  bool _isProOverride = false;
  bool _isLoading = false;
  String? _error;
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

  // Stub product getters — replaced with Stripe price data in Task #480.
  List<Map<String, dynamic>> get products =>
      SubscriptionService.instance.products;
  Map<String, dynamic>? get monthlyProduct =>
      SubscriptionService.instance.monthlyProduct;
  Map<String, dynamic>? get annualProduct =>
      SubscriptionService.instance.annualProduct;

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
    final cached =
        await SubscriptionService.instance.loadFromFirestore(userId);
    if (cached != null) {
      _subscriptionInfo = cached;
      _safeNotify();
    }
  }

  // --- Purchase action stubs (replaced by Stripe checkout in Task #480) ---

  Future<void> purchaseMonthly() async {}
  Future<void> purchaseAnnual() async {}
  Future<void> restorePurchases() async {}

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
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
