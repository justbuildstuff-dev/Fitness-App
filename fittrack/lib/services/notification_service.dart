/// No-op stub for notification_service — local notifications deferred to
/// a post-launch PWA web-push PRD. All methods return immediately without
/// scheduling or displaying any notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  Future<void> initialize() async {}

  Future<void> scheduleWorkoutReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}

  Future<void> scheduleRecurringWorkoutReminder({
    required int id,
    required String title,
    required String body,
    required Time scheduledTime,
    required List<Day> days,
    String? payload,
  }) async {}

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

  Future<void> cancelNotification(int id) async {}

  Future<void> cancelAllNotifications() async {}

  Future<List<Map<String, dynamic>>> getPendingNotifications() async => const [];
}

/// Days of the week for recurring notifications.
enum Day {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const Day(this.value);
  final int value;
}

/// Time of day for scheduling recurring notifications.
class Time {
  final int hour;
  final int minute;

  const Time(this.hour, this.minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
