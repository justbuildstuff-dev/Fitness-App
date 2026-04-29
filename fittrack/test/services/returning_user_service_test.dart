@Timeout(Duration(seconds: 30))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/returning_user_service.dart';

void main() {
  const lastWorkoutKey = 'overload_lifecycle_last_workout_date';
  const lastProgramKey = 'overload_returning_last_program_id';
  const dismissedKey = 'overload_returning_dismissed_at';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ReturningUserService.initialize(prefs);
  });

  Future<void> reinit(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    ReturningUserService.initialize(prefs);
  }

  group('ReturningUserService - shouldShowPrompt', () {
    test('returns false when no last workout date recorded', () async {
      await reinit({lastProgramKey: 'prog-1'});
      expect(ReturningUserService.shouldShowPrompt, isFalse);
    });

    test('returns false when inactive less than 30 days', () async {
      final twentyDaysAgo =
          DateTime.now().subtract(const Duration(days: 20)).toIso8601String();
      await reinit({
        lastWorkoutKey: twentyDaysAgo,
        lastProgramKey: 'prog-1',
      });
      expect(ReturningUserService.shouldShowPrompt, isFalse);
    });

    test('returns false when inactive exactly 29 days', () async {
      final twentyNineDaysAgo =
          DateTime.now().subtract(const Duration(days: 29)).toIso8601String();
      await reinit({
        lastWorkoutKey: twentyNineDaysAgo,
        lastProgramKey: 'prog-1',
      });
      expect(ReturningUserService.shouldShowPrompt, isFalse);
    });

    test('returns true when inactive 30+ days with program on record', () async {
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      await reinit({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
      });
      expect(ReturningUserService.shouldShowPrompt, isTrue);
    });

    test('returns false when inactive 30+ days but no program recorded',
        () async {
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      await reinit({lastWorkoutKey: thirtyOneDaysAgo});
      expect(ReturningUserService.shouldShowPrompt, isFalse);
    });

    test('returns false after dismissal in the same inactivity cycle', () async {
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      final dismissedNow = DateTime.now().toIso8601String();
      await reinit({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
        dismissedKey: dismissedNow,
      });
      expect(ReturningUserService.shouldShowPrompt, isFalse);
    });

    test('returns true again after a new workout resets the cycle', () async {
      // User dismissed, then came back and logged a workout yesterday —
      // they're within 30 days now so prompt is false for a different reason,
      // but the dismissal from the prior cycle is stale.
      final dismissedTwoMonthsAgo =
          DateTime.now().subtract(const Duration(days: 60)).toIso8601String();
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      // Last workout is AFTER the old dismissal — new inactivity cycle.
      await reinit({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
        // dismissedAt is before lastWorkout → stale, should be ignored
        dismissedKey: dismissedTwoMonthsAgo,
      });
      expect(ReturningUserService.shouldShowPrompt, isTrue);
    });
  });

  group('ReturningUserService - dismiss', () {
    test('dismiss suppresses the prompt', () async {
      final thirtyOneDaysAgo =
          DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      await reinit({
        lastWorkoutKey: thirtyOneDaysAgo,
        lastProgramKey: 'prog-1',
      });
      expect(ReturningUserService.shouldShowPrompt, isTrue);
      ReturningUserService.dismiss();
      expect(ReturningUserService.shouldShowPrompt, isFalse);
    });
  });

  group('ReturningUserService - recordLastActiveProgram', () {
    test('persists program ID in prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ReturningUserService.initialize(prefs);

      ReturningUserService.recordLastActiveProgram('prog-abc');
      expect(ReturningUserService.lastActiveProgramId, 'prog-abc');
      expect(prefs.getString(lastProgramKey), 'prog-abc');
    });

    test('overwrites previous program ID', () async {
      await reinit({lastProgramKey: 'prog-old'});
      ReturningUserService.recordLastActiveProgram('prog-new');
      expect(ReturningUserService.lastActiveProgramId, 'prog-new');
    });
  });

  group('ReturningUserService - daysSinceLastWorkout', () {
    test('returns 0 when no workout logged', () async {
      await reinit({});
      expect(ReturningUserService.daysSinceLastWorkout, 0);
    });

    test('returns correct days since last workout', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      await reinit({lastWorkoutKey: tenDaysAgo});
      expect(ReturningUserService.daysSinceLastWorkout, 10);
    });
  });
}
