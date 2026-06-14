/// Integration tests for SubscriptionService.
///
/// Tests the full Stripe-via-Firestore subscription lifecycle using
/// FakeFirebaseFirestore, verifying that subscription reads, stream emissions,
/// and checkout session creation all behave correctly end-to-end.

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

  group('SubscriptionService - subscription read lifecycle', () {
    test('new user has no subscription — returns free', () async {
      final result = await service.loadFromFirestore('new-user');
      expect(result.isPro, isFalse);
      expect(result.tier, SubscriptionTier.free);
    });

    test('active subscription transitions user to pro', () async {
      await fakeFirestore
          .collection('customers')
          .doc('user-a')
          .collection('subscriptions')
          .doc('sub-1')
          .set({
        'status': 'active',
        'items': [
          {
            'price': {'id': SubscriptionService.annualPriceId}
          }
        ],
        'current_period_end': Timestamp.fromDate(DateTime(2027, 12, 31)),
      });

      final result = await service.loadFromFirestore('user-a');

      expect(result.isPro, isTrue);
      expect(result.status, SubscriptionStatus.active);
      expect(result.productId, SubscriptionService.annualPriceId);
      expect(result.platform, 'web');
      expect(result.expiresAt, DateTime(2027, 12, 31));
    });

    test('expired/cancelled subscription returns free tier', () async {
      await fakeFirestore
          .collection('customers')
          .doc('user-b')
          .collection('subscriptions')
          .doc('sub-old')
          .set({
        'status': 'canceled',
        'items': [],
        'current_period_end': Timestamp.fromDate(DateTime(2025, 1, 1)),
      });

      final result = await service.loadFromFirestore('user-b');
      expect(result.isPro, isFalse);
    });

    test('multiple users have independent subscription state', () async {
      await fakeFirestore
          .collection('customers')
          .doc('free-user')
          .collection('subscriptions')
          .get(); // no documents

      await fakeFirestore
          .collection('customers')
          .doc('pro-user')
          .collection('subscriptions')
          .doc('sub-1')
          .set({
        'status': 'active',
        'items': [
          {
            'price': {'id': SubscriptionService.monthlyPriceId}
          }
        ],
        'current_period_end': Timestamp.fromDate(DateTime(2027, 1, 1)),
      });

      final freeResult = await service.loadFromFirestore('free-user');
      final proResult = await service.loadFromFirestore('pro-user');

      expect(freeResult.isPro, isFalse);
      expect(proResult.isPro, isTrue);
    });
  });

  group('SubscriptionService - checkout session lifecycle', () {
    test('checkout session document is written with required fields', () async {
      // Simulate extension: write url when session created
      fakeFirestore
          .collection('customers')
          .doc('user-checkout')
          .collection('checkout_sessions')
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['price'] != null && data['url'] == null && data['error'] == null) {
            await doc.reference
                .update({'url': 'https://checkout.stripe.com/session-xyz'});
          }
        }
      });

      final url = await service.createCheckoutSession(
        userId: 'user-checkout',
        priceId: SubscriptionService.annualPriceId,
        successUrl: 'https://fittrack-app.web.app/?checkout=success',
        cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
      );

      expect(url, 'https://checkout.stripe.com/session-xyz');

      final sessions = await fakeFirestore
          .collection('customers')
          .doc('user-checkout')
          .collection('checkout_sessions')
          .get();

      final data = sessions.docs.first.data();
      expect(data['price'], SubscriptionService.annualPriceId);
      expect(data['success_url'],
          'https://fittrack-app.web.app/?checkout=success');
      expect(data['cancel_url'],
          'https://fittrack-app.web.app/?checkout=cancelled');
      expect(data['mode'], 'subscription');
      expect(data['allow_promotion_codes'], isTrue);
    });

    test('lifetime plan uses payment mode', () async {
      fakeFirestore
          .collection('customers')
          .doc('user-lifetime')
          .collection('checkout_sessions')
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          final data = doc.data();
          if (data['price'] != null && data['url'] == null && data['error'] == null) {
            await doc.reference.update({'url': 'https://checkout.stripe.com/lifetime'});
          }
        }
      });

      await service.createCheckoutSession(
        userId: 'user-lifetime',
        priceId: SubscriptionService.lifetimePriceId,
        successUrl: 'https://fittrack-app.web.app/?checkout=success',
        cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
      );

      final sessions = await fakeFirestore
          .collection('customers')
          .doc('user-lifetime')
          .collection('checkout_sessions')
          .get();
      expect(sessions.docs.first.data()['mode'], 'payment');
    });
  });

  group('SubscriptionService - stream lifecycle', () {
    test('stream emits free before any subscriptions exist', () async {
      final info = await service.subscriptionStream('stream-user-1').first;
      expect(info.isPro, isFalse);
    });

    test('stream emits pro after active subscription written', () async {
      await fakeFirestore
          .collection('customers')
          .doc('stream-user-2')
          .collection('subscriptions')
          .doc('sub-1')
          .set({
        'status': 'active',
        'items': [
          {
            'price': {'id': SubscriptionService.annualPriceId}
          }
        ],
        'current_period_end': null,
      });

      final info =
          await service.subscriptionStream('stream-user-2').first;
      expect(info.isPro, isTrue);
    });
  });
}
