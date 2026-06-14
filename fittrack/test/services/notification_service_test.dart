import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/services/notification_service.dart';

/// Unit tests for NotificationService.
///
/// NotificationService is a no-op stub for the PWA — local notifications are
/// deferred to a post-launch web-push PRD. These tests verify that all public
/// API methods complete without errors and return the correct stub values.
void main() {
  late NotificationService service;

  setUp(() {
    service = NotificationService.instance;
  });

  group('NotificationService (no-op stub)', () {
    test('initialize completes without error', () async {
      await expectLater(service.initialize(), completes);
    });

    test('scheduleWorkoutReminder completes without error', () async {
      await expectLater(
        service.scheduleWorkoutReminder(
          id: 1,
          title: 'Test',
          body: 'Test body',
          scheduledDate: DateTime.now().add(const Duration(hours: 1)),
        ),
        completes,
      );
    });

    test('scheduleRecurringWorkoutReminder completes without error', () async {
      await expectLater(
        service.scheduleRecurringWorkoutReminder(
          id: 2,
          title: 'Recurring',
          body: 'Recurring body',
          scheduledTime: const Time(9, 0),
          days: [Day.monday, Day.wednesday],
        ),
        completes,
      );
    });

    test('showNotification completes without error', () async {
      await expectLater(
        service.showNotification(
          id: 3,
          title: 'Immediate',
          body: 'Immediate body',
        ),
        completes,
      );
    });

    test('cancelNotification completes without error', () async {
      await expectLater(service.cancelNotification(1), completes);
    });

    test('cancelAllNotifications completes without error', () async {
      await expectLater(service.cancelAllNotifications(), completes);
    });

    test('getPendingNotifications returns empty list', () async {
      final result = await service.getPendingNotifications();
      expect(result, isEmpty);
    });
  });

  group('Day enum', () {
    test('has correct values for all days', () {
      expect(Day.monday.value, 1);
      expect(Day.tuesday.value, 2);
      expect(Day.wednesday.value, 3);
      expect(Day.thursday.value, 4);
      expect(Day.friday.value, 5);
      expect(Day.saturday.value, 6);
      expect(Day.sunday.value, 7);
    });
  });

  group('Time class', () {
    test('formats correctly with padding', () {
      expect(const Time(9, 5).toString(), '09:05');
      expect(const Time(14, 30).toString(), '14:30');
      expect(const Time(0, 0).toString(), '00:00');
    });
  });
}
