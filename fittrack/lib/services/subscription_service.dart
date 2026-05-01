import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription.dart';

/// Singleton that wraps InAppPurchase for product queries, purchase flow,
/// and syncing subscription status to/from Firestore.
///
/// Purchase stream handling and state management live in [SubscriptionProvider].
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();

  // Null means "use FirebaseFirestore.instance" — resolved lazily so the
  // static singleton can be constructed in tests without Firebase initialised.
  final FirebaseFirestore? _injectedFirestore;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  SubscriptionService._() : _injectedFirestore = null;

  @visibleForTesting
  SubscriptionService.forTest(FirebaseFirestore firestore)
      : _injectedFirestore = firestore;

  static const String monthlyId = 'fittrack_pro_monthly';
  static const String annualId = 'fittrack_pro_annual';
  static const Set<String> productIds = {monthlyId, annualId};

  List<ProductDetails> _products = [];

  List<ProductDetails> get products => List.unmodifiable(_products);

  ProductDetails? get monthlyProduct =>
      _products.cast<ProductDetails?>().firstWhere(
            (p) => p?.id == monthlyId,
            orElse: () => null,
          );

  ProductDetails? get annualProduct =>
      _products.cast<ProductDetails?>().firstWhere(
            (p) => p?.id == annualId,
            orElse: () => null,
          );

  Stream<List<PurchaseDetails>> get purchaseStream =>
      InAppPurchase.instance.purchaseStream;

  /// Initialises the IAP plugin and loads product details from the store.
  /// Returns false if the store is unavailable (e.g. no network, simulator).
  Future<bool> initialize() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return false;
    final response =
        await InAppPurchase.instance.queryProductDetails(productIds);
    _products = response.productDetails;
    return true;
  }

  Future<void> buySubscription(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchase);
    }
  }

  /// Writes the subscription map to the user's Firestore document.
  Future<void> syncToFirestore(String userId, SubscriptionInfo info) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'subscription': info.toFirestore()});
  }

  /// Loads the subscription map from the user's Firestore document.
  /// Returns null if no subscription data exists yet.
  Future<SubscriptionInfo?> loadFromFirestore(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data()?['subscription'] as Map<String, dynamic>?;
    if (data == null) return null;
    return SubscriptionInfo.fromFirestore(data);
  }
}
