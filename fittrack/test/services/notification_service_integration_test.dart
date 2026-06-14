/// Integration tests for NotificationService.
///
/// NotificationService is a no-op stub for the PWA — local notifications are
/// deferred to a post-launch web-push PRD. These integration tests verify
/// that the stub API is safe to call in sequence (simulating realistic
/// app flow), and that no state leaks between calls.
///
/// No Firebase emulators required — no platform channels or external
/// dependencies are exercised.

@Timeout(Duration(seconds: 30))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/services/notification_service.dart';

void main() {
  group('NotificationService - Integration (stub API lifecycle)', () {
    test('initialize followed by scheduleWorkoutReminder completes cleanly',
        () async {
      final service = NotificationService.instance;
      await service.initialize();
      await service.scheduleWorkoutReminder(
        id: 100,
        title: 'Reminder',
        body: 'Time to train',
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
      );
      // No error — stub is safe to call in sequence
    });

    test('multiple initialize calls are idempotent', () async {
      final service = NotificationService.instance;
      await service.initialize();
      await service.initialize();
      await service.initialize();
      // Should complete without error
    });

    test('cancel after schedule completes without error', () async {
      final service = NotificationService.instance;
      await service.initialize();
      await service.scheduleWorkoutReminder(
        id: 200,
        title: 'Cancellable',
        body: 'Will be cancelled',
        scheduledDate: DateTime.now().add(const Duration(days: 7)),
      );
      await service.cancelNotification(200);
    });

    test('cancelAllNotifications after multiple schedules completes without error',
        () async {
      final service = NotificationService.instance;
      await service.initialize();
      for (int i = 0; i < 5; i++) {
        await service.showNotification(
          id: 300 + i,
          title: 'Notification $i',
          body: 'Body $i',
        );
      }
      await service.cancelAllNotifications();
    });

    test('getPendingNotifications always returns empty list', () async {
      final service = NotificationService.instance;
      await service.initialize();
      await service.scheduleWorkoutReminder(
        id: 400,
        title: 'Pending check',
        body: 'body',
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
      );
      final pending = await service.getPendingNotifications();
      expect(pending, isEmpty,
          reason: 'Stub always returns empty — no real scheduling occurs');
    });
  });
}
