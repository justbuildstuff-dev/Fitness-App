import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_analytics_service.dart';

/// Manages the in-app review prompt lifecycle.
///
/// Eligible if: workouts started ≥ 5 AND days since first launch ≥ 7
/// AND review has not already been requested on this install.
///
/// The platform (iOS/Android) applies its own rate limiting on top —
/// calling [requestReview] does not guarantee the dialog appears.
class AppReviewService {
  static const String _firstLaunchKey = 'overload_first_launch_date';
  static const String _workoutCountKey = 'overload_workout_count';
  static const String _reviewRequestedKey = 'overload_review_requested';

  static const int _minWorkouts = 5;
  static const int _minDaysSinceLaunch = 7;

  static AppReviewService? _instance;
  static AppReviewService get instance => _instance!;

  final SharedPreferences _prefs;
  final InAppReview _inAppReview;

  // Guards against firing twice in one app session (e.g. navigating back from
  // multiple workouts in the same session).
  bool _requestedThisSession = false;

  AppReviewService._internal(this._prefs, this._inAppReview) {
    _recordFirstLaunchIfNeeded();
  }

  @visibleForTesting
  AppReviewService.forTest(SharedPreferences prefs, InAppReview inAppReview)
      : _prefs = prefs,
        _inAppReview = inAppReview {
    _recordFirstLaunchIfNeeded();
  }

  static void initialize(SharedPreferences prefs) {
    _instance = AppReviewService._internal(prefs, InAppReview.instance);
  }

  /// Null-safe wrapper for use in widget code.
  ///
  /// Widget tests that don't go through [main] or [OverloadApp] never call
  /// [initialize], so [_instance] is null. These static helpers no-op
  /// in that case instead of throwing.
  static void tryRecordWorkoutStarted() => _instance?.recordWorkoutStarted();

  /// Null-safe wrapper for use in widget code. See [tryRecordWorkoutStarted].
  static void tryMaybeRequestReview() {
    _instance?.maybeRequestReview();
  }

  void _recordFirstLaunchIfNeeded() {
    if (_prefs.getString(_firstLaunchKey) == null) {
      _prefs.setString(_firstLaunchKey, DateTime.now().toIso8601String());
    }
  }

  /// Called each time the user opens a workout. Increments the counter used
  /// for review eligibility.
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

  /// Checks eligibility and requests a review if conditions are met.
  ///
  /// Safe to call speculatively — returns immediately if ineligible.
  /// Must NOT be called from within an active workout screen.
  Future<void> maybeRequestReview() async {
    if (!isEligible || _requestedThisSession) return;
    _requestedThisSession = true;

    try {
      await AppAnalyticsService.instance.logReviewPromptTriggered();

      final available = await _inAppReview.isAvailable();
      if (available) {
        await _prefs.setBool(_reviewRequestedKey, true);
        await _inAppReview.requestReview();
      }
    } catch (e) {
      _requestedThisSession = false;
      debugPrint('[AppReview] Failed to request review: $e');
    }
  }

  /// Resets persisted review state. For testing and debug use only.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _prefs.remove(_reviewRequestedKey);
    _requestedThisSession = false;
  }
}
