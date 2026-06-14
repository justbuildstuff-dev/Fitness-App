import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

/// Stub SubscriptionService — IAP removed for PWA transition.
///
/// Firestore sync methods are preserved so subscription state can be read
/// from Firestore. Full Stripe billing integration is added in Task #480.
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();

  final FirebaseFirestore? _injectedFirestore;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  SubscriptionService._() : _injectedFirestore = null;

  @visibleForTesting
  SubscriptionService.forTest(FirebaseFirestore firestore)
      : _injectedFirestore = firestore;

  // Product ID constants preserved for Task #480 migration.
  static const String monthlyId = 'fittrack_pro_monthly';
  static const String annualId = 'fittrack_pro_annual';
  static const Set<String> productIds = {monthlyId, annualId};

  // Stub getters — replaced with Stripe price data in Task #480.
  List<Map<String, dynamic>> get products => const [];
  Map<String, dynamic>? get monthlyProduct => null;
  Map<String, dynamic>? get annualProduct => null;

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
