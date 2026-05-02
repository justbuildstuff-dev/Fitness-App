/// Integration tests for SubscriptionService.
///
/// SubscriptionService has two concerns:
///   1. InAppPurchase interactions (platform channel — cannot be tested in CI)
///   2. Firestore read/write of the subscription map
///
/// These tests cover concern (2) using FakeFirebaseFirestore, verifying that
/// loadFromFirestore correctly deserialises subscription data across all status
/// values and that a missing/absent subscription field returns null.

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

  group('SubscriptionService - Firestore lifecycle', () {
    test('loadFromFirestore returns null for document with no subscription',
        () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'displayName': 'Joel',
        'createdAt': Timestamp.now(),
      });

      expect(await service.loadFromFirestore('u1'), isNull);
    });

    test('loadFromFirestore returns null for non-existent document', () async {
      expect(await service.loadFromFirestore('no-such-user'), isNull);
    });

    test(
        'loadFromFirestore returns correct SubscriptionInfo for active pro subscription',
        () async {
      final expiry = DateTime(2027, 6, 30);
      await fakeFirestore.collection('users').doc('u2').set({
        'subscription': {
          'status': 'active',
          'productId': 'fittrack_pro_annual',
          'platform': 'ios',
          'expiresAt': Timestamp.fromDate(expiry),
          'updatedAt': Timestamp.now(),
        },
      });

      final info = await service.loadFromFirestore('u2');

      expect(info, isNotNull);
      expect(info!.isPro, isTrue);
      expect(info.tier, SubscriptionTier.pro);
      expect(info.status, SubscriptionStatus.active);
      expect(info.productId, 'fittrack_pro_annual');
      expect(info.platform, 'ios');
      expect(info.expiresAt, expiry);
    });

    test('loadFromFirestore returns free tier for expired subscription',
        () async {
      await fakeFirestore.collection('users').doc('u3').set({
        'subscription': {
          'status': 'expired',
          'productId': 'fittrack_pro_monthly',
          'platform': 'android',
          'expiresAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
          'updatedAt': Timestamp.now(),
        },
      });

      final info = await service.loadFromFirestore('u3');

      expect(info!.isPro, isFalse);
      expect(info.tier, SubscriptionTier.free);
      expect(info.status, SubscriptionStatus.expired);
    });

    test('loadFromFirestore handles trial status as pro', () async {
      await fakeFirestore.collection('users').doc('u4').set({
        'subscription': {
          'status': 'trial',
          'productId': 'fittrack_pro_monthly',
          'platform': 'android',
          'expiresAt': null,
          'updatedAt': Timestamp.now(),
        },
      });

      final info = await service.loadFromFirestore('u4');

      expect(info!.isPro, isTrue);
      expect(info.tier, SubscriptionTier.pro);
      expect(info.status, SubscriptionStatus.trial);
    });

    test('multiple users have independent subscription state', () async {
      await fakeFirestore.collection('users').doc('free-user').set({
        'subscription': {
          'status': 'free',
          'productId': null,
          'platform': null,
          'expiresAt': null,
          'updatedAt': Timestamp.now(),
        },
      });
      await fakeFirestore.collection('users').doc('pro-user').set({
        'subscription': {
          'status': 'active',
          'productId': 'fittrack_pro_annual',
          'platform': 'ios',
          'expiresAt': Timestamp.fromDate(DateTime(2027, 1, 1)),
          'updatedAt': Timestamp.now(),
        },
      });

      final freeInfo = await service.loadFromFirestore('free-user');
      final proInfo = await service.loadFromFirestore('pro-user');

      expect(freeInfo!.isPro, isFalse);
      expect(proInfo!.isPro, isTrue);
    });
  });
}
