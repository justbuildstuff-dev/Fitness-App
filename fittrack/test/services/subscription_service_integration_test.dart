/// Integration tests for SubscriptionService.
///
/// Tests the subscription read/stream lifecycle using FakeFirebaseFirestore,
/// verifying that subscription reads and stream emissions behave correctly.
/// Checkout session creation is tested in subscription_service_test.dart
/// via MockClient.

@Timeout(Duration(seconds: 30))
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fittrack/models/subscription.dart';
import 'package:fittrack/services/subscription_service.dart';

SubscriptionService _makeService(FakeFirebaseFirestore firestore, {http.Client? httpClient}) {
  return SubscriptionService.forTest(
    firestore,
    httpClient ?? MockClient((_) async => http.Response('', 200)),
  );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late SubscriptionService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = _makeService(fakeFirestore);
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

  group('SubscriptionService - checkout session via Cloudflare Worker', () {
    test('createCheckoutSession returns url from Worker response', () async {
      final mockClient = MockClient((_) async => http.Response(
            jsonEncode({'url': 'https://checkout.stripe.com/session-xyz'}),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final svc = _makeService(fakeFirestore, httpClient: mockClient);

      final url = await svc.createCheckoutSession(
        userId: 'user-checkout',
        priceId: SubscriptionService.annualPriceId,
        successUrl: 'https://fittrack-app.web.app/?checkout=success',
        cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
      );

      expect(url, 'https://checkout.stripe.com/session-xyz');
    });

    test('throws Exception when Worker returns non-200', () async {
      final mockClient = MockClient((_) async => http.Response('server error', 500));
      final svc = _makeService(fakeFirestore, httpClient: mockClient);

      await expectLater(
        svc.createCheckoutSession(
          userId: 'user-error',
          priceId: SubscriptionService.annualPriceId,
          successUrl: 'https://fittrack-app.web.app/?checkout=success',
          cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
        ),
        throwsA(isA<Exception>()),
      );
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
