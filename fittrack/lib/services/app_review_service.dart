import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_analytics_service.dart';

/// Manages the app review prompt lifecycle.
///
/// On web, native review dialogs are not available. The eligibility check and
/// analytics event are preserved so the data pipeline is intact. The actual
/// review call is a no-op until a platform-appropriate replacement is added.
///
/// Eligible if: workouts started ≥ 5 AND days since first launch ≥ 7
/// AND review has not already been requested on this install.
class AppReviewService {
  static const String _firstLaunchKey = 'overload_first_launch_date';
  static const String _workoutCountKey = 'overload_workout_count';
  static const String _reviewRequestedKey = 'overload_review_requested';

  static const int _minWorkouts = 5;
  static const int _minDaysSinceLaunch = 7;

  static AppReviewService? _instance;
  static AppReviewService get instance => _instance!;

  final SharedPreferences _prefs;

  bool _requestedThisSession = false;

  AppReviewService._internal(this._prefs) {
    _recordFirstLaunchIfNeeded();
  }

  @visibleForTesting
  AppReviewService.forTest(SharedPreferences prefs) : _prefs = prefs {
    _recordFirstLaunchIfNeeded();
  }

  static void initialize(SharedPreferences prefs) {
    _instance = AppReviewService._internal(prefs);
  }

  static void tryRecordWorkoutStarted() => _instance?.recordWorkoutStarted();

  static void tryMaybeRequestReview() {
    _instance?.maybeRequestReview();
  }

  void _recordFirstLaunchIfNeeded() {
    if (_prefs.getString(_firstLaunchKey) == null) {
      _prefs.setString(_firstLaunchKey, DateTime.now().toIso8601String());
    }
  }

  void recordWorkoutStarted() {
    final count = _prefs.getInt(_workoutCountKey) ?? 0;
    _prefs.setInt(_workoutCountKey, count + 1);
  }

  int get workoutCount => _prefs.getInt(_workoutCountKey) ?? 0;

  int get daysSinceFirstLaunch {
    final stored = _prefs.getString(_firstLaunchKey);
    if (stored == null) return 0;
    return DateTime.now().difference(DateTime.parse(stored)).inDays;
  }

  bool get hasBeenRequested => _prefs.getBool(_reviewRequestedKey) ?? false;

  bool get isEligible =>
      workoutCount >= _minWorkouts &&
      daysSinceFirstLaunch >= _minDaysSinceLaunch &&
      !hasBeenRequested;

  /// Checks eligibility and logs the review prompt analytics event.
  ///
  /// The actual review dialog is omitted on web — this preserves the
  /// eligibility gate and analytics so the data pipeline remains intact.
  Future<void> maybeRequestReview() async {
    if (!isEligible || _requestedThisSession) return;
    _requestedThisSession = true;

    try {
      await AppAnalyticsService.instance.logReviewPromptTriggered();
      await _prefs.setBool(_reviewRequestedKey, true);
    } catch (e) {
      _requestedThisSession = false;
      debugPrint('[AppReview] Failed to log review prompt: $e');
    }
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    await _prefs.remove(_reviewRequestedKey);
    _requestedThisSession = false;
  }
}
