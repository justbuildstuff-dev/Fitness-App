import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [FirebaseAnalytics] that instruments key user events.
///
/// All methods are fire-and-forget: failures are caught and logged to
/// [debugPrint] so analytics never crashes the app.
///
/// Usage:
/// ```dart
/// AppAnalyticsService.instance.logSignUp();
/// ```
///
/// In [MaterialApp], add the observer for automatic screen tracking:
/// ```dart
/// navigatorObservers: [AppAnalyticsService.instance.observer],
/// ```
class AppAnalyticsService {
  static final AppAnalyticsService instance = AppAnalyticsService._internal();

  final FirebaseAnalytics _analytics;

  AppAnalyticsService._internal() : _analytics = FirebaseAnalytics.instance;

  /// Allows injecting a mock [FirebaseAnalytics] in tests.
  @visibleForTesting
  AppAnalyticsService.withAnalytics(this._analytics);

  /// Navigator observer for automatic screen-view tracking.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ---------------------------------------------------------------------------
  // Auth events
  // ---------------------------------------------------------------------------

  Future<void> logSignUp() => _log(() => _analytics.logSignUp(signUpMethod: 'email'));

  Future<void> logLogin() => _log(() => _analytics.logLogin(loginMethod: 'email'));

  Future<void> logSignOut() => _log(
        () => _analytics.logEvent(name: 'sign_out'),
      );

  // ---------------------------------------------------------------------------
  // Onboarding events
  // ---------------------------------------------------------------------------

  Future<void> logOnboardingStarted() => _log(
        () => _analytics.logEvent(name: 'onboarding_started'),
      );

  Future<void> logOnboardingCompleted() => _log(
        () => _analytics.logTutorialComplete(),
      );

  // ---------------------------------------------------------------------------
  // Core workout-flow events
  // ---------------------------------------------------------------------------

  Future<void> logProgramCreated() => _log(
        () => _analytics.logEvent(name: 'program_created'),
      );

  Future<void> logWorkoutStarted() => _log(
        () => _analytics.logEvent(name: 'workout_started'),
      );

  /// Fired when the user checks a set as complete.
  Future<void> logSetCompleted() => _log(
        () => _analytics.logEvent(name: 'set_completed'),
      );

  // ---------------------------------------------------------------------------
  // Internal helper
  // ---------------------------------------------------------------------------

  Future<void> _log(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('[AppAnalytics] Failed to log event: $e');
    }
  }
}
