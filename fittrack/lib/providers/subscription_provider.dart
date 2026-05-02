import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';

/// Manages subscription state and exposes computed limits used throughout
/// the app to gate premium features.
///
/// Registered as a [ChangeNotifierProxyProvider] so it reacts to auth state
/// changes — resetting when the user signs out and re-initialising when they
/// sign in.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionInfo _subscriptionInfo = SubscriptionInfo.free();
  bool _isProOverride = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _disposed = false;

  // --- Public getters ---

  /// True when the user has an active Pro subscription or the developer bypass.
  bool get isPro => _isProOverride || _subscriptionInfo.isPro;
  bool get isFree => !isPro;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SubscriptionInfo get subscriptionInfo => _subscriptionInfo;
  bool get isProOverride => _isProOverride;

  // Computed limits used by gating logic throughout the app.
  int get maxPrograms => isPro ? 999 : 3;
  int get maxCustomExercises => isPro ? 50 : 5;

  List<ProductDetails> get products => SubscriptionService.instance.products;
  ProductDetails? get monthlyProduct =>
      SubscriptionService.instance.monthlyProduct;
  ProductDetails? get annualProduct =>
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
    // Fast path: load cached Firestore status before IAP initialises.
    final cached =
        await SubscriptionService.instance.loadFromFirestore(userId);
    if (cached != null) {
      _subscriptionInfo = cached;
      _safeNotify();
    }

    // Initialise IAP plugin and load store products.
    await SubscriptionService.instance.initialize();

    // Start listening to purchase stream.
    _purchaseSubscription?.cancel();
    _purchaseSubscription = SubscriptionService.instance.purchaseStream
        .listen((purchases) => _handlePurchaseUpdates(purchases, userId));

    // Silent restore to pick up any active subscriptions on sign-in / re-launch.
    await SubscriptionService.instance.restorePurchases();
  }

  // --- Purchase stream handler ---

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases, String userId) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final info = SubscriptionInfo(
            tier: SubscriptionTier.pro,
            status: SubscriptionStatus.active,
            productId: purchase.productID,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
          _subscriptionInfo = info;
          await SubscriptionService.instance.syncToFirestore(userId, info);
          await SubscriptionService.instance.completePurchase(purchase);
          _isLoading = false;
          _safeNotify();

        case PurchaseStatus.error:
          _error = purchase.error?.message ?? 'Purchase failed';
          _isLoading = false;
          _safeNotify();

        case PurchaseStatus.pending:
          _isLoading = true;
          _safeNotify();

        case PurchaseStatus.canceled:
          _isLoading = false;
          _safeNotify();
      }
    }
  }

  // --- Purchase actions ---

  Future<void> purchaseMonthly() async {
    final product = monthlyProduct;
    if (product == null) return;
    _error = null;
    _isLoading = true;
    _safeNotify();
    await SubscriptionService.instance.buySubscription(product);
  }

  Future<void> purchaseAnnual() async {
    final product = annualProduct;
    if (product == null) return;
    _error = null;
    _isLoading = true;
    _safeNotify();
    await SubscriptionService.instance.buySubscription(product);
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    _safeNotify();
    await SubscriptionService.instance.restorePurchases();
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  /// Sets subscription state directly without triggering IAP — for tests only.
  @visibleForTesting
  void setSubscriptionInfoForTest(SubscriptionInfo info) {
    _subscriptionInfo = info;
    _safeNotify();
  }

  /// Sets the pro override flag directly — for tests only.
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
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
