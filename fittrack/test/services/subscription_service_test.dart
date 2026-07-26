@Timeout(Duration(seconds: 30))
library;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/models/subscription.dart';
import 'package:fittrack/services/subscription_service.dart';

import '../mocks/firebase_mocks.mocks.dart';

/// Builds a MockFirebaseAuth whose current user returns [idToken] from
/// getIdToken(), or has no current user when [idToken] is null.
MockFirebaseAuth _mockAuthWithToken(String? idToken) {
  final mockAuth = MockFirebaseAuth();
  if (idToken == null) {
    when(mockAuth.currentUser).thenReturn(null);
    return mockAuth;
  }
  final mockUser = MockUser();
  when(mockUser.getIdToken(any)).thenAnswer((_) async => idToken);
  when(mockAuth.currentUser).thenReturn(mockUser);
  return mockAuth;
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('SubscriptionService - Stripe Price ID constants', () {
    test('monthlyPriceId is set', () {
      expect(SubscriptionService.monthlyPriceId, isNotEmpty);
    });

    test('annualPriceId is set', () {
      expect(SubscriptionService.annualPriceId, isNotEmpty);
    });

    test('stripePortalUrl starts with https', () {
      expect(SubscriptionService.stripePortalUrl, startsWith('https://'));
    });
  });

  group('SubscriptionService - loadFromFirestore', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService.forTest(fakeFirestore, MockClient((_) async => http.Response('', 200)));
    });

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
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService.forTest(fakeFirestore, MockClient((_) async => http.Response('', 200)));
    });

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
    test('POSTs correct JSON body to Worker and returns url', () async {
      final capturedRequests = <http.Request>[];
      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response(
          jsonEncode({'url': 'https://checkout.stripe.com/test123'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SubscriptionService.forTest(
        fakeFirestore,
        mockClient,
        _mockAuthWithToken('fake-id-token'),
      );
      final url = await service.createCheckoutSession(
        userId: 'user-checkout',
        priceId: SubscriptionService.annualPriceId,
        successUrl: 'https://app.test/?checkout=success',
        cancelUrl: 'https://app.test/?checkout=cancelled',
      );

      expect(url, 'https://checkout.stripe.com/test123');
      expect(capturedRequests.length, 1);

      expect(
        capturedRequests.first.headers['Authorization'],
        'Bearer fake-id-token',
      );

      final body = jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
      expect(body['uid'], 'user-checkout');
      expect(body['priceId'], SubscriptionService.annualPriceId);
      expect(body['successUrl'], 'https://app.test/?checkout=success');
      expect(body['cancelUrl'], 'https://app.test/?checkout=cancelled');
    });

    test('throws Exception when no user is authenticated', () async {
      final mockClient = MockClient((_) async => http.Response('unreachable', 200));
      final service = SubscriptionService.forTest(
        fakeFirestore,
        mockClient,
        _mockAuthWithToken(null),
      );

      expect(
        () => service.createCheckoutSession(
          userId: 'user-error',
          priceId: SubscriptionService.annualPriceId,
          successUrl: 'https://app.test/?checkout=success',
          cancelUrl: 'https://app.test/?checkout=cancelled',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception when Worker returns non-200', () async {
      final mockClient = MockClient((_) async => http.Response('error', 502));
      final service = SubscriptionService.forTest(
        fakeFirestore,
        mockClient,
        _mockAuthWithToken('fake-id-token'),
      );

      expect(
        () => service.createCheckoutSession(
          userId: 'user-error',
          priceId: SubscriptionService.annualPriceId,
          successUrl: 'https://app.test/?checkout=success',
          cancelUrl: 'https://app.test/?checkout=cancelled',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sets Content-Type header to application/json', () async {
      final capturedRequests = <http.Request>[];
      final mockClient = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response(
          jsonEncode({'url': 'https://checkout.stripe.com/test'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SubscriptionService.forTest(
        fakeFirestore,
        mockClient,
        _mockAuthWithToken('fake-id-token'),
      );
      await service.createCheckoutSession(
        userId: 'u1',
        priceId: SubscriptionService.monthlyPriceId,
        successUrl: 'https://app.test/?checkout=success',
        cancelUrl: 'https://app.test/?checkout=cancelled',
      );

      expect(
        capturedRequests.first.headers['content-type'],
        contains('application/json'),
      );
    });
  });
}
