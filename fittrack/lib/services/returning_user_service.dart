import 'package:shared_preferences/shared_preferences.dart';

/// Detects when a user returns after 30+ days of inactivity and manages
/// the state of the contextual "pick up where you left off" prompt.
///
/// Reads the last workout date written by [LifecycleNotificationService] so
/// the two services stay in sync without coupling. ReturningUserService owns
/// its own prefs keys for program tracking and dismissal state.
class ReturningUserService {
  // Read-only — key is written by LifecycleNotificationService.
  static const _lastWorkoutDateKey = 'overload_lifecycle_last_workout_date';

  static const _lastProgramIdKey = 'overload_returning_last_program_id';
  static const _dismissedAtKey = 'overload_returning_dismissed_at';

  static const int inactivityThresholdDays = 30;

  static SharedPreferences? _prefs;

  static void initialize(SharedPreferences prefs) => _prefs = prefs;

  /// Records which program was active when a workout was logged.
  /// Call from [ConsolidatedWorkoutScreen] on every workout open.
  static void recordLastActiveProgram(String programId) =>
      _prefs?.setString(_lastProgramIdKey, programId);

  /// Returns true when the returning-user prompt should be shown:
  ///   • A workout was previously logged
  ///   • 30+ days have passed since that workout
  ///   • A last-active program is on record
  ///   • The prompt has not been dismissed since the last workout
  static bool get shouldShowPrompt {
    if (_prefs == null) return false;
    final lastWorkout = _lastWorkoutDate;
    if (lastWorkout == null) return false;
    if (DateTime.now().difference(lastWorkout).inDays < inactivityThresholdDays) {
      return false;
    }
    if (lastActiveProgramId == null) return false;

    // Already dismissed during this inactivity cycle?
    final dismissed = _dismissedAt;
    if (dismissed != null && dismissed.isAfter(lastWorkout)) return false;

    return true;
  }

  /// Suppress the prompt for the current inactivity cycle.
  static void dismiss() =>
      _prefs?.setString(_dismissedAtKey, DateTime.now().toIso8601String());

  /// Program ID of the last program in which a workout was logged.
  static String? get lastActiveProgramId =>
      _prefs?.getString(_lastProgramIdKey);

  /// Whole days since the last logged workout (0 if never logged).
  static int get daysSinceLastWorkout {
    final lastWorkout = _lastWorkoutDate;
    if (lastWorkout == null) return 0;
    return DateTime.now().difference(lastWorkout).inDays;
  }

  static DateTime? get _lastWorkoutDate {
    final s = _prefs?.getString(_lastWorkoutDateKey);
    return s == null ? null : DateTime.parse(s);
  }

  static DateTime? get _dismissedAt {
    final s = _prefs?.getString(_dismissedAtKey);
    return s == null ? null : DateTime.parse(s);
  }
}
