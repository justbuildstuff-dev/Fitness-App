import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show NavigatorObserver;

/// Thin wrapper around [FirebaseAnalytics] that instruments key user events.
///
/// All methods are fire-and-forget: failures are caught and logged to
/// [debugPrint] so analytics never crashes the app.
///
/// [FirebaseAnalytics.instance] is accessed lazily — only when the first log
/// call is made — so the service can be safely referenced before Firebase is
/// initialised (e.g. in widget tests).
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

  FirebaseAnalytics? _analyticsInstance;

  AppAnalyticsService._internal();

  /// Allows injecting a mock [FirebaseAnalytics] in tests.
  @visibleForTesting
  AppAnalyticsService.withAnalytics(FirebaseAnalytics analytics)
      : _analyticsInstance = analytics;

  // Lazy getter — FirebaseAnalytics.instance is only called on first log.
  // If Firebase is not yet initialised this throws, which is caught by _log.
  FirebaseAnalytics get _analytics =>
      _analyticsInstance ??= FirebaseAnalytics.instance;

  /// Navigator observer for automatic screen-view tracking.
  ///
  /// Returns a no-op [NavigatorObserver] if Firebase is not yet initialised
  /// (e.g. in tests), so [MaterialApp.navigatorObservers] never throws.
  NavigatorObserver get observer {
    try {
      return FirebaseAnalyticsObserver(analytics: _analytics);
    } catch (_) {
      return NavigatorObserver();
    }
  }

  // ---------------------------------------------------------------------------
  // Auth events
  // ---------------------------------------------------------------------------

  Future<void> logSignUp() =>
      _log(() => _analytics.logSignUp(signUpMethod: 'email'));

  Future<void> logLogin() =>
      _log(() => _analytics.logLogin(loginMethod: 'email'));

  Future<void> logSignOut() =>
      _log(() => _analytics.logEvent(name: 'sign_out'));

  // ---------------------------------------------------------------------------
  // Onboarding events
  // ---------------------------------------------------------------------------

  Future<void> logOnboardingStarted() =>
      _log(() => _analytics.logEvent(name: 'onboarding_started'));

  Future<void> logOnboardingCompleted() =>
      _log(() => _analytics.logTutorialComplete());

  // ---------------------------------------------------------------------------
  // Core workout-flow events
  // ---------------------------------------------------------------------------

  Future<void> logProgramCreated() =>
      _log(() => _analytics.logEvent(name: 'program_created'));

  Future<void> logWorkoutStarted() =>
      _log(() => _analytics.logEvent(name: 'workout_started'));

  /// Fired when the user checks a set as complete.
  Future<void> logSetCompleted() =>
      _log(() => _analytics.logEvent(name: 'set_completed'));

  /// Fired when review prompt eligibility conditions are met and the native
  /// review request is about to be triggered.
  Future<void> logReviewPromptTriggered() =>
      _log(() => _analytics.logEvent(name: 'review_prompt_triggered'));

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
