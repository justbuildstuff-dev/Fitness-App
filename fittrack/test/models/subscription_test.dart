import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/models/subscription.dart';

void main() {
  group('SubscriptionInfo', () {
    group('free() factory', () {
      test('creates free tier with free status', () {
        final info = SubscriptionInfo.free();
        expect(info.tier, SubscriptionTier.free);
        expect(info.status, SubscriptionStatus.free);
        expect(info.isPro, isFalse);
        expect(info.expiresAt, isNull);
        expect(info.productId, isNull);
        expect(info.platform, isNull);
      });
    });

    group('isPro getter', () {
      test('returns true for pro tier', () {
        const info = SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
        );
        expect(info.isPro, isTrue);
      });

      test('returns false for free tier', () {
        expect(SubscriptionInfo.free().isPro, isFalse);
      });
    });

    group('fromFirestore', () {
      test('deserializes active subscription correctly', () {
        final expiry = DateTime(2026, 12, 31);
        final data = <String, dynamic>{
          'status': 'active',
          'productId': 'fittrack_pro_annual',
          'platform': 'ios',
          'expiresAt': Timestamp.fromDate(expiry),
        };

        final info = SubscriptionInfo.fromFirestore(data);

        expect(info.status, SubscriptionStatus.active);
        expect(info.tier, SubscriptionTier.pro);
        expect(info.isPro, isTrue);
        expect(info.productId, 'fittrack_pro_annual');
        expect(info.platform, 'ios');
        expect(info.expiresAt, expiry);
      });

      test('deserializes trial subscription as pro', () {
        final data = <String, dynamic>{
          'status': 'trial',
          'productId': 'fittrack_pro_monthly',
          'platform': 'android',
          'expiresAt': null,
        };

        final info = SubscriptionInfo.fromFirestore(data);

        expect(info.status, SubscriptionStatus.trial);
        expect(info.tier, SubscriptionTier.pro);
        expect(info.isPro, isTrue);
      });

      test('deserializes expired subscription as free tier', () {
        final data = <String, dynamic>{
          'status': 'expired',
          'productId': 'fittrack_pro_monthly',
          'platform': 'ios',
        };

        final info = SubscriptionInfo.fromFirestore(data);

        expect(info.status, SubscriptionStatus.expired);
        expect(info.tier, SubscriptionTier.free);
        expect(info.isPro, isFalse);
      });

      test('deserializes cancelled subscription as free tier', () {
        final data = <String, dynamic>{
          'status': 'cancelled',
        };

        final info = SubscriptionInfo.fromFirestore(data);

        expect(info.status, SubscriptionStatus.cancelled);
        expect(info.tier, SubscriptionTier.free);
        expect(info.isPro, isFalse);
      });

      test('defaults to unknown status for unrecognized value', () {
        final data = <String, dynamic>{
          'status': 'something_new',
        };

        final info = SubscriptionInfo.fromFirestore(data);

        expect(info.status, SubscriptionStatus.unknown);
        expect(info.tier, SubscriptionTier.free);
      });

      test('defaults to free status when status field is absent', () {
        final info = SubscriptionInfo.fromFirestore({});
        expect(info.status, SubscriptionStatus.free);
        expect(info.tier, SubscriptionTier.free);
        expect(info.isPro, isFalse);
      });

      test('handles null expiresAt gracefully', () {
        final data = <String, dynamic>{
          'status': 'active',
          'expiresAt': null,
        };

        final info = SubscriptionInfo.fromFirestore(data);
        expect(info.expiresAt, isNull);
      });
    });

    group('toFirestore', () {
      test('serializes all fields correctly', () {
        final expiry = DateTime(2026, 12, 31);
        final info = SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
          productId: 'fittrack_pro_annual',
          platform: 'ios',
          expiresAt: expiry,
        );

        final map = info.toFirestore();

        expect(map['status'], 'active');
        expect(map['productId'], 'fittrack_pro_annual');
        expect(map['platform'], 'ios');
        expect((map['expiresAt'] as Timestamp).toDate(), expiry);
        expect(map['updatedAt'], isA<FieldValue>());
      });

      test('serializes null expiresAt correctly', () {
        const info = SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
        );

        final map = info.toFirestore();
        expect(map['expiresAt'], isNull);
      });

      test('round-trips key fields through map serialization', () {
        // Tests toFirestore → fromFirestore parity without writing to Firestore,
        // because FieldValue.serverTimestamp() is a server-only sentinel that
        // cannot be stored in FakeFirebaseFirestore in unit tests.
        final expiry = DateTime(2026, 6, 15);
        final original = SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
          productId: 'fittrack_pro_monthly',
          platform: 'android',
          expiresAt: expiry,
        );

        final map = original.toFirestore();
        // Replace server timestamp sentinel with a real Timestamp for fromFirestore
        final roundTripMap = Map<String, dynamic>.from(map)
          ..['updatedAt'] = Timestamp.fromDate(DateTime.now())
          ..['expiresAt'] = Timestamp.fromDate(expiry);

        final restored = SubscriptionInfo.fromFirestore(roundTripMap);

        expect(restored.status, original.status);
        expect(restored.tier, original.tier);
        expect(restored.productId, original.productId);
        expect(restored.platform, original.platform);
        expect(restored.expiresAt, expiry);
      });
    });
  });

  group('SubscriptionTier enum', () {
    test('has free and pro values', () {
      expect(SubscriptionTier.values, hasLength(2));
      expect(SubscriptionTier.values, contains(SubscriptionTier.free));
      expect(SubscriptionTier.values, contains(SubscriptionTier.pro));
    });
  });

  group('SubscriptionStatus enum', () {
    test('has expected status values', () {
      expect(
        SubscriptionStatus.values,
        containsAll([
          SubscriptionStatus.unknown,
          SubscriptionStatus.free,
          SubscriptionStatus.trial,
          SubscriptionStatus.active,
          SubscriptionStatus.expired,
          SubscriptionStatus.cancelled,
        ]),
      );
    });
  });
}
