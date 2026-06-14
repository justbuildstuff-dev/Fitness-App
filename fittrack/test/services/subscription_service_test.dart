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

  group('SubscriptionService - Stripe Price ID constants', () {
    test('monthlyPriceId is set', () {
      expect(SubscriptionService.monthlyPriceId, isNotEmpty);
    });

    test('annualPriceId is set', () {
      expect(SubscriptionService.annualPriceId, isNotEmpty);
    });

    test('lifetimePriceId is set', () {
      expect(SubscriptionService.lifetimePriceId, isNotEmpty);
    });

    test('stripePortalUrl starts with https', () {
      expect(SubscriptionService.stripePortalUrl, startsWith('https://'));
    });
  });

  group('SubscriptionService - loadFromFirestore', () {
    test('returns SubscriptionInfo.free when no subscriptions exist', () async {
      final result = await service.loadFromFirestore('user-1');
      expect(result.isPro, isFalse);
      expect(result.status, SubscriptionStatus.free);
    });

    test('returns pro when active Stripe subscription exists', () async {
      final expiry = DateTime(2027, 1, 1);
      await fakeFirestore
          .collection('customers')
          .doc('user-1')
          .collection('subscriptions')
          .doc('sub-1')
          .set({
        'status': 'active',
        'items': [
          {
            'price': {'id': SubscriptionService.annualPriceId}
          }
        ],
        'current_period_end': Timestamp.fromDate(expiry),
      });

      final result = await service.loadFromFirestore('user-1');
      expect(result.isPro, isTrue);
      expect(result.tier, SubscriptionTier.pro);
      expect(result.status, SubscriptionStatus.active);
      expect(result.productId, SubscriptionService.annualPriceId);
      expect(result.platform, 'web');
      expect(result.expiresAt, expiry);
    });

    test('returns pro when trialing Stripe subscription exists', () async {
      await fakeFirestore
          .collection('customers')
          .doc('user-2')
          .collection('subscriptions')
          .doc('sub-trial')
          .set({
        'status': 'trialing',
        'items': [
          {
            'price': {'id': SubscriptionService.monthlyPriceId}
          }
        ],
        'current_period_end': null,
      });

      final result = await service.loadFromFirestore('user-2');
      expect(result.isPro, isTrue);
      expect(result.tier, SubscriptionTier.pro);
    });

    test('returns free when only cancelled subscription exists', () async {
      await fakeFirestore
          .collection('customers')
          .doc('user-3')
          .collection('subscriptions')
          .doc('sub-cancelled')
          .set({
        'status': 'canceled',
        'items': [],
        'current_period_end': null,
      });

      final result = await service.loadFromFirestore('user-3');
      expect(result.isPro, isFalse);
    });
  });

  group('SubscriptionService - subscriptionStream', () {
    test('emits SubscriptionInfo.free when no subscriptions', () async {
      final stream = service.subscriptionStream('user-stream');
      final info = await stream.first;
      expect(info.isPro, isFalse);
    });

    test('emits pro info when active subscription added', () async {
      final stream = service.subscriptionStream('user-stream-2');

      await fakeFirestore
          .collection('customers')
          .doc('user-stream-2')
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

      final info = await stream.first;
      expect(info.isPro, isTrue);
    });
  });

  group('SubscriptionService - createCheckoutSession', () {
    test('writes checkout session document with correct fields', () async {
      // Simulate extension responding with a url immediately
      fakeFirestore
          .collection('customers')
          .doc('user-checkout')
          .collection('checkout_sessions')
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          if (doc.data()['price'] != null && doc.data()['url'] == null) {
            await doc.reference.update({'url': 'https://checkout.stripe.com/test'});
          }
        }
      });

      final url = await service.createCheckoutSession(
        userId: 'user-checkout',
        priceId: SubscriptionService.annualPriceId,
        successUrl: 'https://fittrack-app.web.app/?checkout=success',
        cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
      );

      expect(url, 'https://checkout.stripe.com/test');

      // Verify session document was written with correct fields
      final sessions = await fakeFirestore
          .collection('customers')
          .doc('user-checkout')
          .collection('checkout_sessions')
          .get();
      expect(sessions.docs.length, 1);
      final data = sessions.docs.first.data();
      expect(data['price'], SubscriptionService.annualPriceId);
      expect(data['mode'], 'subscription');
      expect(data['allow_promotion_codes'], isTrue);
    });

    test('uses payment mode for lifetime price ID', () async {
      fakeFirestore
          .collection('customers')
          .doc('user-lifetime')
          .collection('checkout_sessions')
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          if (doc.data()['price'] != null && doc.data()['url'] == null) {
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

    test('throws when extension returns error', () async {
      fakeFirestore
          .collection('customers')
          .doc('user-error')
          .collection('checkout_sessions')
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          if (doc.data()['price'] != null && doc.data()['error'] == null) {
            await doc.reference
                .update({'error': 'No such price: bad_price_id'});
          }
        }
      });

      expect(
        () => service.createCheckoutSession(
          userId: 'user-error',
          priceId: 'bad_price_id',
          successUrl: 'https://fittrack-app.web.app/?checkout=success',
          cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
