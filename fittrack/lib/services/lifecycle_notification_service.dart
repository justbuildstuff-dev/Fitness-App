import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'app_analytics_service.dart';

/// Lifecycle-triggered push notifications for activation and retention.
///
/// Triggers (Brand_Marketing_Strategy.md §9.2):
///   Day 1 after install, no workout → activation nudge
///   Day 3, 0 workouts logged        → reactivation nudge
///   Personal record achieved        → delight notification (immediate)
///   10-day inactivity               → retention nudge
///   30-day inactivity               → churn-reactivation nudge
///
/// Trial triggers (Trial Day 10, Trial expiry) are NOT implemented here —
/// they depend on the subscription feature (issue #448).
///
/// All on-device triggers use [FlutterLocalNotificationsPlugin] scheduled
/// notifications, which fire even when the app is closed. FCM is initialised
/// for permission handling and future server-side delivery.
class LifecycleNotificationService {
  static const String _installDateKey = 'overload_lifecycle_install_date';
  static const String _lastWorkoutDateKey = 'overload_lifecycle_last_workout_date';
  static const String _workoutCountKey = 'overload_lifecycle_workout_count';
  static const String _permissionRequestedKey = 'overload_notif_permission_requested';
  static const String _fcmTokenKey = 'overload_fcm_token';

  // Stable IDs — scheduling with the same ID replaces any existing notification
  // of that type so only one of each trigger is ever queued.
  static const int _day1NotifId = 1001;
  static const int _day3NotifId = 1002;
  static const int _day10NotifId = 1003;
  static const int _day30NotifId = 1004;
  static const int _prNotifBaseId = 2000;

  // Notification channel IDs / names
  static const String _activationChannelId = 'lifecycle_activation';
  static const String _retentionChannelId = 'lifecycle_retention';
  static const String _prChannelId = 'pr_achievement';

  // Deep-link payload values — read by the navigation layer on tap.
  static const String payloadWorkouts = 'route:workouts';
  static const String payloadHome = 'route:home';

  static LifecycleNotificationService? _instance;
  static bool get isInitialized => _instance != null;

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _messaging;

  LifecycleNotificationService._internal(
    this._prefs,
    this._localNotifications,
    this._messaging,
  ) {
    _recordInstallDateIfNeeded();
  }

  @visibleForTesting
  LifecycleNotificationService.forTest(
    SharedPreferences prefs,
    FlutterLocalNotificationsPlugin localNotifications,
    FirebaseMessaging messaging,
  )   : _prefs = prefs,
        _localNotifications = localNotifications,
        _messaging = messaging {
    _recordInstallDateIfNeeded();
  }

  /// Initialises the service and sets up local notification + FCM handlers.
  ///
  /// Call once from [main] after Firebase and SharedPreferences are ready.
  /// Non-blocking failures are logged but do not throw.
  static Future<void> initialize(SharedPreferences prefs) async {
    _instance = LifecycleNotificationService._internal(
      prefs,
      FlutterLocalNotificationsPlugin(),
      FirebaseMessaging.instance,
    );
    await _instance!._initLocalNotifications();
    await _instance!._initFCM();
  }

  // ─── Null-safe static helpers (widget code) ────────────────────────────────

  static void tryRecordWorkoutLogged() => _instance?.recordWorkoutLogged();

  static Future<void> tryRecordPRAchieved(
    String exerciseName,
    String valueDisplay,
  ) async =>
      _instance?.recordPRAchieved(exerciseName, valueDisplay);

  static Future<void> tryRequestPermissionIfEligible() async =>
      _instance?.requestPermissionIfEligible();

  static Future<void> tryOnAppLaunch() async => _instance?.onAppLaunch();

  // ─── Internal setup ────────────────────────────────────────────────────────

  void _recordInstallDateIfNeeded() {
    if (_prefs.getString(_installDateKey) == null) {
      _prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initFCM() async {
    FirebaseMessaging.onMessage.listen(_onFCMMessageReceived);
    _messaging.onTokenRefresh.listen(_onFCMTokenRefresh);
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload ?? '';
    AppAnalyticsService.instance.logLifecycleNotificationOpened(payload);
    debugPrint('[LifecycleNotif] Tapped: $payload');
  }

  void _onFCMMessageReceived(RemoteMessage message) {
    final trigger = message.data['trigger'] as String? ?? 'unknown';
    AppAnalyticsService.instance.logLifecycleNotificationOpened(trigger);
    debugPrint('[LifecycleNotif] FCM foreground: $trigger');
  }

  void _onFCMTokenRefresh(String token) {
    _prefs.setString(_fcmTokenKey, token);
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Call on every app launch. Schedules or cancels lifecycle notifications
  /// based on the user's current install age and workout history.
  Future<void> onAppLaunch() async {
    await _scheduleActivationNotifications();
    await _scheduleRetentionNotifications();
  }

  /// Call when the user completes a workout session.
  ///
  /// Increments the workout count, cancels activation nudges, and resets the
  /// inactivity window to today.
  void recordWorkoutLogged() {
    final count = (_prefs.getInt(_workoutCountKey) ?? 0) + 1;
    _prefs.setInt(_workoutCountKey, count);
    _prefs.setString(_lastWorkoutDateKey, DateTime.now().toIso8601String());

    // User has engaged — cancel first-workout activation nudges.
    _localNotifications.cancel(_day1NotifId);
    _localNotifications.cancel(_day3NotifId);

    // Reset the inactivity window from today.
    _scheduleRetentionNotifications();
  }

  /// Call when a personal record is detected. Fires an immediate notification.
  Future<void> recordPRAchieved(
    String exerciseName,
    String valueDisplay,
  ) async {
    await _showPRNotification(exerciseName, valueDisplay);
    AppAnalyticsService.instance.logLifecycleNotificationScheduled('pr_achieved');
  }

  /// Requests notification permission after the user's first workout.
  ///
  /// No-op if permission was already requested or no workout has been logged.
  /// On iOS this shows the native permission dialog. On Android 13+ this
  /// shows the runtime permission prompt. On older Android it's a no-op.
  Future<void> requestPermissionIfEligible() async {
    if (permissionRequested) return;
    if (workoutCount < 1) return;

    await _prefs.setBool(_permissionRequestedKey, true);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[LifecycleNotif] Permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    if (token != null) {
      await _prefs.setString(_fcmTokenKey, token);
    }
  }

  // ─── Accessors ─────────────────────────────────────────────────────────────

  int get workoutCount => _prefs.getInt(_workoutCountKey) ?? 0;

  DateTime? get installDate {
    final s = _prefs.getString(_installDateKey);
    return s == null ? null : DateTime.parse(s);
  }

  DateTime? get lastWorkoutDate {
    final s = _prefs.getString(_lastWorkoutDateKey);
    return s == null ? null : DateTime.parse(s);
  }

  int get daysSinceInstall {
    final date = installDate;
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  int get daysSinceLastWorkout {
    final ref = lastWorkoutDate ?? installDate;
    if (ref == null) return 0;
    return DateTime.now().difference(ref).inDays;
  }

  bool get permissionRequested => _prefs.getBool(_permissionRequestedKey) ?? false;

  // ─── Scheduling ─────────────────────────────────────────────────────────────

  Future<void> _scheduleActivationNotifications() async {
    if (workoutCount > 0) {
      await _localNotifications.cancel(_day1NotifId);
      await _localNotifications.cancel(_day3NotifId);
      return;
    }

    final install = installDate;
    if (install == null) return;

    final now = DateTime.now();
    final day1Fire = install.add(const Duration(days: 1));
    final day3Fire = install.add(const Duration(days: 3));

    if (day1Fire.isAfter(now)) {
      await _scheduleLocalNotification(
        id: _day1NotifId,
        channelId: _activationChannelId,
        channelName: 'Activation',
        title: 'Your program is ready',
        body: 'Log your first workout and start tracking your progress.',
        scheduledAt: day1Fire,
        payload: payloadWorkouts,
      );
    }

    if (day3Fire.isAfter(now)) {
      await _scheduleLocalNotification(
        id: _day3NotifId,
        channelId: _activationChannelId,
        channelName: 'Activation',
        title: "Let's go — day 3 already",
        body: "Most users who don't log in 3 days churn. We'd rather you didn't.",
        scheduledAt: day3Fire,
        payload: payloadWorkouts,
      );
    }
  }

  Future<void> _scheduleRetentionNotifications() async {
    final reference = lastWorkoutDate ?? installDate;
    if (reference == null) return;

    final now = DateTime.now();
    final day10Fire = reference.add(const Duration(days: 10));
    final day30Fire = reference.add(const Duration(days: 30));

    if (day10Fire.isAfter(now)) {
      await _scheduleLocalNotification(
        id: _day10NotifId,
        channelId: _retentionChannelId,
        channelName: 'Retention',
        title: 'Still training?',
        body: "It's been a while. Your program is still here.",
        scheduledAt: day10Fire,
        payload: payloadWorkouts,
      );
    }

    if (day30Fire.isAfter(now)) {
      await _scheduleLocalNotification(
        id: _day30NotifId,
        channelId: _retentionChannelId,
        channelName: 'Retention',
        title: "Your data's still here. So are your PRs.",
        body: 'Pick up where you left off.',
        scheduledAt: day30Fire,
        payload: payloadWorkouts,
      );
    }
  }

  Future<void> _showPRNotification(
    String exerciseName,
    String valueDisplay,
  ) async {
    // Use a varying ID so multiple PR notifications can coexist.
    final id = _prNotifBaseId + (DateTime.now().millisecondsSinceEpoch % 1000);

    await _localNotifications.show(
      id,
      'New PR: $exerciseName',
      'You hit $valueDisplay — a new personal best.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prChannelId,
          'Personal Records',
          channelDescription:
              'Notifications when you achieve a new personal record',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: payloadHome,
    );
  }

  Future<void> _scheduleLocalNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    AppAnalyticsService.instance.logLifecycleNotificationScheduled(channelId);
  }
}
