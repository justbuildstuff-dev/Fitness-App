import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, pro }

enum SubscriptionStatus { unknown, free, trial, active, expired, cancelled }

class SubscriptionInfo {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final String? productId;
  final String? platform;

  const SubscriptionInfo({
    required this.tier,
    required this.status,
    this.expiresAt,
    this.productId,
    this.platform,
  });

  bool get isPro => tier == SubscriptionTier.pro;

  factory SubscriptionInfo.free() => const SubscriptionInfo(
        tier: SubscriptionTier.free,
        status: SubscriptionStatus.free,
      );

  Map<String, dynamic> toFirestore() => {
        'status': status.name,
        'productId': productId,
        'platform': platform,
        'expiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory SubscriptionInfo.fromFirestore(Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'free';
    final status = SubscriptionStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => SubscriptionStatus.unknown,
    );
    final isActive = status == SubscriptionStatus.active ||
        status == SubscriptionStatus.trial;
    return SubscriptionInfo(
      tier: isActive ? SubscriptionTier.pro : SubscriptionTier.free,
      status: status,
      productId: data['productId'] as String?,
      platform: data['platform'] as String?,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}
