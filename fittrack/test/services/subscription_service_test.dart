@Timeout(Duration(seconds: 30))
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/subscription.dart';
import 'package:fittrack/services/subscription_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late SubscriptionService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = SubscriptionService.forTest(fakeFirestore);
  });

  group('SubscriptionService - product getters', () {
    test('monthlyProduct returns null before initialization', () {
      expect(service.monthlyProduct, isNull);
    });

    test('annualProduct returns null before initialization', () {
      expect(service.annualProduct, isNull);
    });

    test('products is empty before initialization', () {
      expect(service.products, isEmpty);
    });
  });

  group('SubscriptionService - loadFromFirestore', () {
    test('returns null when user document has no subscription field', () async {
      await fakeFirestore.collection('users').doc('user-1').set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'createdAt': Timestamp.now(),
      });

      final result = await service.loadFromFirestore('user-1');
      expect(result, isNull);
    });

    test('returns null when user document does not exist', () async {
      final result = await service.loadFromFirestore('nonexistent-user');
      expect(result, isNull);
    });

    test('returns SubscriptionInfo.free() for free status', () async {
      await fakeFirestore.collection('users').doc('user-1').set({
        'subscription': {
          'status': 'free',
          'productId': null,
          'platform': null,
          'expiresAt': null,
          'updatedAt': Timestamp.now(),
        },
      });

      final result = await service.loadFromFirestore('user-1');
      expect(result, isNotNull);
      expect(result!.status, SubscriptionStatus.free);
      expect(result.isPro, isFalse);
    });

    test('returns pro SubscriptionInfo for active status', () async {
      final expiry = DateTime(2027, 1, 1);
      await fakeFirestore.collection('users').doc('user-1').set({
        'subscription': {
          'status': 'active',
          'productId': 'fittrack_pro_annual',
          'platform': 'ios',
          'expiresAt': Timestamp.fromDate(expiry),
          'updatedAt': Timestamp.now(),
        },
      });

      final result = await service.loadFromFirestore('user-1');
      expect(result, isNotNull);
      expect(result!.status, SubscriptionStatus.active);
      expect(result.tier, SubscriptionTier.pro);
      expect(result.isPro, isTrue);
      expect(result.productId, 'fittrack_pro_annual');
      expect(result.platform, 'ios');
      expect(result.expiresAt, expiry);
    });

    test('returns pro SubscriptionInfo for trial status', () async {
      await fakeFirestore.collection('users').doc('user-1').set({
        'subscription': {
          'status': 'trial',
          'productId': 'fittrack_pro_monthly',
          'platform': 'android',
          'expiresAt': null,
          'updatedAt': Timestamp.now(),
        },
      });

      final result = await service.loadFromFirestore('user-1');
      expect(result!.tier, SubscriptionTier.pro);
      expect(result.isPro, isTrue);
    });

    test('returns free tier for expired status', () async {
      await fakeFirestore.collection('users').doc('user-1').set({
        'subscription': {
          'status': 'expired',
          'productId': 'fittrack_pro_monthly',
          'platform': 'ios',
          'expiresAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'updatedAt': Timestamp.now(),
        },
      });

      final result = await service.loadFromFirestore('user-1');
      expect(result!.tier, SubscriptionTier.free);
      expect(result.isPro, isFalse);
    });
  });

  group('SubscriptionService - product ID constants', () {
    test('product IDs match expected store identifiers', () {
      expect(SubscriptionService.monthlyId, 'fittrack_pro_monthly');
      expect(SubscriptionService.annualId, 'fittrack_pro_annual');
      expect(SubscriptionService.productIds,
          containsAll(['fittrack_pro_monthly', 'fittrack_pro_annual']));
    });
  });
}
