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
  // Onboarding skip events
  // ---------------------------------------------------------------------------

  Future<void> logOnboardingSkipped() =>
      _log(() => _analytics.logEvent(name: 'onboarding_skipped'));

  Future<void> logProgramSetupSkipped() =>
      _log(() => _analytics.logEvent(name: 'program_setup_skipped'));

  // ---------------------------------------------------------------------------
  // Activation milestone events
  // ---------------------------------------------------------------------------

  /// Fired the first time a user logs a workout.
  /// [daysSinceInstall] allows cohort analysis (did they work out on day 0, 1, etc.)
  Future<void> logFirstWorkoutLogged(int daysSinceInstall) =>
      _log(() => _analytics.logEvent(
            name: 'first_workout_logged',
            parameters: {'days_since_install': daysSinceInstall},
          ));

  /// Fired when a workout count milestone is reached (e.g., 5th workout).
  Future<void> logWorkoutMilestone(int count) =>
      _log(() => _analytics.logEvent(
            name: 'workout_milestone',
            parameters: {'workout_count': count},
          ));

  // ---------------------------------------------------------------------------
  // Retention cohort events
  // ---------------------------------------------------------------------------

  Future<void> logDayOneSession() =>
      _log(() => _analytics.logEvent(name: 'day_1_session'));

  Future<void> logDaySevenSession() =>
      _log(() => _analytics.logEvent(name: 'day_7_session'));

  Future<void> logDayThirtySession() =>
      _log(() => _analytics.logEvent(name: 'day_30_session'));

  /// Fired when a user logs a workout after 10+ days of inactivity.
  /// [daysSinceLastWorkout] is captured before the new workout resets the clock.
  Future<void> logUserReactivated(int daysSinceLastWorkout) =>
      _log(() => _analytics.logEvent(
            name: 'user_reactivated',
            parameters: {'days_since_last_workout': daysSinceLastWorkout},
          ));

  // ---------------------------------------------------------------------------
  // Lifecycle notification events
  // ---------------------------------------------------------------------------

  /// Fired when a lifecycle notification is scheduled (local or FCM).
  /// [trigger] is the channel ID / trigger label, e.g. 'lifecycle_activation'.
  Future<void> logLifecycleNotificationScheduled(String trigger) =>
      _log(() => _analytics.logEvent(
            name: 'lifecycle_notification_scheduled',
            parameters: {'trigger': trigger},
          ));

  /// Fired when the user taps a lifecycle notification to open the app.
  /// [payload] is the notification's deep-link payload string.
  Future<void> logLifecycleNotificationOpened(String payload) =>
      _log(() => _analytics.logEvent(
            name: 'lifecycle_notification_opened',
            parameters: {'payload': payload},
          ));

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
