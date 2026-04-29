/// Integration tests for ReturningUserService.
///
/// ReturningUserService relies solely on SharedPreferences for all state
/// (last workout date, last active program ID, dismissal timestamp).
/// These tests exercise the real SharedPreferences lifecycle end-to-end —
/// recording a program, dismissing the prompt, and re-initialising across
/// simulated app restarts — with no Firebase dependency.

@Timeout(Duration(seconds: 30))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/returning_user_service.dart';

void main() {
  const lastWorkoutKey = 'overload_lifecycle_last_workout_date';
  const lastProgramKey = 'overload_returning_last_program_id';
  const dismissedKey = 'overload_returning_dismissed_at';

  group('ReturningUserService - SharedPreferences lifecycle', () {
    test('lastActiveProgramId persists across re-initialisation', () async {
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);

      ReturningUserService.recordLastActiveProgram('prog-xyz');
      expect(ReturningUserService.lastActiveProgramId, 'prog-xyz');

      // Simulate app restart with same prefs store
      prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);
      expect(ReturningUserService.lastActiveProgramId, 'prog-xyz',
          reason: 'Program ID must survive re-initialisation');
    });

    test('dismissal persists across re-initialisation', () async {
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
      });
      var prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);

      expect(ReturningUserService.shouldShowPrompt, isTrue);
      ReturningUserService.dismiss();
      expect(ReturningUserService.shouldShowPrompt, isFalse);

      // Simulate app restart
      prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);
      expect(ReturningUserService.shouldShowPrompt, isFalse,
          reason: 'Dismissal must survive re-initialisation');
      expect(prefs.getString(dismissedKey), isNotNull);
    });

    test('shouldShowPrompt state is consistent after re-initialisation', () async {
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
      });

      var prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);
      expect(ReturningUserService.shouldShowPrompt, isTrue);

      // Re-initialise without dismissing — prompt remains
      prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);
      expect(ReturningUserService.shouldShowPrompt, isTrue,
          reason: 'Undismissed prompt must still show after re-initialisation');
    });

    test('new workout resets inactivity cycle across re-initialisation',
        () async {
      // User was inactive 31 days, then logs a workout
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      final dismissedNow = DateTime.now().toIso8601String();
      final workoutYesterday =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();

      SharedPreferences.setMockInitialValues({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
        dismissedKey: dismissedNow,
      });
      var prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);
      expect(ReturningUserService.shouldShowPrompt, isFalse,
          reason: 'Already dismissed for this cycle');

      // New workout resets lastWorkoutDate to yesterday
      SharedPreferences.setMockInitialValues({
        lastWorkoutKey: workoutYesterday,
        lastProgramKey: 'prog-1',
        dismissedKey: dismissedNow, // dismissal is now before last workout
      });
      prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);

      // Yesterday workout means < 30 days inactive — prompt still false
      expect(ReturningUserService.shouldShowPrompt, isFalse,
          reason: 'Only 1 day since last workout — below 30 day threshold');
    });
  });
}
