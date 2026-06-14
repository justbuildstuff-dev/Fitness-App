import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_analytics_service.dart';

/// Lifecycle event tracking for activation and retention analytics.
///
/// Local notification scheduling is deferred to a post-launch PWA web-push
/// PRD. FCM token storage and all analytics events are preserved so the
/// analytics pipeline remains intact.
///
/// Triggers tracked (analytics only — no notifications fired):
///   Day 1, Day 7, Day 30 session retention flags
///   First workout, workout milestone (5), reactivation (10-day inactivity)
///   PR achieved (analytics log only)
class LifecycleNotificationService {
  static const String _installDateKey = 'overload_lifecycle_install_date';
  static const String _lastWorkoutDateKey = 'overload_lifecycle_last_workout_date';
  static const String _workoutCountKey = 'overload_lifecycle_workout_count';
  static const String _permissionRequestedKey = 'overload_notif_permission_requested';
  static const String _fcmTokenKey = 'overload_fcm_token';

  // Analytics dedup flags — set once so session events fire only on first qualifying launch.
  static const String _d1FiredKey = 'overload_analytics_d1_session_fired';
  static const String _d7FiredKey = 'overload_analytics_d7_session_fired';
  static const String _d30FiredKey = 'overload_analytics_d30_session_fired';

  static LifecycleNotificationService? _instance;
  static bool get isInitialized => _instance != null;

  final SharedPreferences _prefs;
  final FirebaseMessaging _messaging;

  LifecycleNotificationService._internal(
    this._prefs,
    this._messaging,
  ) {
    _recordInstallDateIfNeeded();
  }

  @visibleForTesting
  LifecycleNotificationService.forTest(
    SharedPreferences prefs,
    FirebaseMessaging messaging,
  )   : _prefs = prefs,
        _messaging = messaging {
    _recordInstallDateIfNeeded();
  }

  /// Initialises the service and FCM token refresh listener.
  ///
  /// Call once from [main] after Firebase and SharedPreferences are ready.
  static Future<void> initialize(SharedPreferences prefs) async {
    _instance = LifecycleNotificationService._internal(
      prefs,
      FirebaseMessaging.instance,
    );
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

  Future<void> _initFCM() async {
    FirebaseMessaging.onMessage.listen(_onFCMMessageReceived);
    _messaging.onTokenRefresh.listen(_onFCMTokenRefresh);
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

  /// Call on every app launch. Fires retention session analytics.
  Future<void> onAppLaunch() async {
    _logRetentionSessions();
  }

  /// Call when the user completes a workout session.
  ///
  /// Increments the workout count and resets the inactivity window to today.
  void recordWorkoutLogged() {
    // Capture inactivity window BEFORE updating last workout date.
    final inactivityDays = daysSinceLastWorkout;
    final count = (_prefs.getInt(_workoutCountKey) ?? 0) + 1;
    _prefs.setInt(_workoutCountKey, count);
    _prefs.setString(_lastWorkoutDateKey, DateTime.now().toIso8601String());

    // Activation milestone events.
    if (count == 1) {
      AppAnalyticsService.instance.logFirstWorkoutLogged(daysSinceInstall);
    }
    if (count == 5) {
      AppAnalyticsService.instance.logWorkoutMilestone(5);
    }
    // Reactivation: only meaningful after the first workout (count > 1).
    if (count > 1 && inactivityDays >= 10) {
      AppAnalyticsService.instance.logUserReactivated(inactivityDays);
    }
  }

  /// Call when a personal record is detected. Logs analytics only.
  Future<void> recordPRAchieved(
    String exerciseName,
    String valueDisplay,
  ) async {
    AppAnalyticsService.instance.logLifecycleNotificationScheduled('pr_achieved');
  }

  /// Requests FCM permission after the user's first workout.
  ///
  /// No-op if permission was already requested or no workout has been logged.
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

  // ─── Retention session analytics ────────────────────────────────────────────

  void _logRetentionSessions() {
    final days = daysSinceInstall;
    if (days >= 1 && !(_prefs.getBool(_d1FiredKey) ?? false)) {
      _prefs.setBool(_d1FiredKey, true);
      AppAnalyticsService.instance.logDayOneSession();
    }
    if (days >= 7 && !(_prefs.getBool(_d7FiredKey) ?? false)) {
      _prefs.setBool(_d7FiredKey, true);
      AppAnalyticsService.instance.logDaySevenSession();
    }
    if (days >= 30 && !(_prefs.getBool(_d30FiredKey) ?? false)) {
      _prefs.setBool(_d30FiredKey, true);
      AppAnalyticsService.instance.logDayThirtySession();
    }
  }
}
