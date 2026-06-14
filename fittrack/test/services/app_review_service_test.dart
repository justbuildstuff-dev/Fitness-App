import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/app_review_service.dart';

/// Unit tests for AppReviewService.
///
/// Verifies eligibility logic, workout count persistence, first-launch tracking,
/// and that the hasBeenRequested flag is set when conditions are met.
///
/// InAppReview has been removed (web platform). The eligibility gate and
/// analytics event persist; the actual review dialog is a no-op.
void main() {
  const firstLaunchKey = 'overload_first_launch_date';
  const workoutCountKey = 'overload_workout_count';
  const reviewRequestedKey = 'overload_review_requested';

  Future<AppReviewService> makeService({
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return AppReviewService.forTest(prefs);
  }

  Future<AppReviewService> eligibleService() => makeService(prefsValues: {
        firstLaunchKey: DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
        workoutCountKey: 5,
      });

  group('recordWorkoutStarted', () {
    test('increments workout count from 0', () async {
      final s = await makeService();
      s.recordWorkoutStarted();
      expect(s.workoutCount, 1);
    });

    test('increments cumulatively across multiple calls', () async {
      final s = await makeService();
      s.recordWorkoutStarted();
      s.recordWorkoutStarted();
      s.recordWorkoutStarted();
      expect(s.workoutCount, 3);
    });

    test('persists count to SharedPreferences', () async {
      final s = await makeService();
      s.recordWorkoutStarted();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(workoutCountKey), 1,
          reason: 'Count must survive app restart');
    });
  });

  group('daysSinceFirstLaunch', () {
    test('records first launch date on initialisation when absent', () async {
      final s = await makeService();
      expect(s.daysSinceFirstLaunch, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(firstLaunchKey), isNotNull);
    });

    test('does not overwrite an existing first launch date', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final s = await makeService(prefsValues: {firstLaunchKey: tenDaysAgo});
      expect(s.daysSinceFirstLaunch, greaterThanOrEqualTo(10),
          reason: 'Prior launch date must be preserved');
    });
  });

  group('isEligible', () {
    test('false when workout count is below threshold (5)', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final s = await makeService(prefsValues: {
        firstLaunchKey: tenDaysAgo,
        workoutCountKey: 4,
      });
      expect(s.isEligible, isFalse,
          reason: 'Requires at least 5 workouts');
    });

    test('false when fewer than 7 days have passed since first launch', () async {
      final threeDaysAgo =
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
      final s = await makeService(prefsValues: {
        firstLaunchKey: threeDaysAgo,
        workoutCountKey: 10,
      });
      expect(s.isEligible, isFalse,
          reason: 'Requires at least 7 days since first launch');
    });

    test('false when review has already been requested', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final s = await makeService(prefsValues: {
        firstLaunchKey: tenDaysAgo,
        workoutCountKey: 10,
        reviewRequestedKey: true,
      });
      expect(s.isEligible, isFalse,
          reason: 'Should not prompt again after first request');
    });

    test('true when all conditions met (>= 5 workouts, >= 7 days, not yet requested)',
        () async {
      final s = await eligibleService();
      expect(s.isEligible, isTrue);
    });

    test('true at exactly the minimum thresholds (5 workouts, 7 days)', () async {
      final sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final s = await makeService(prefsValues: {
        firstLaunchKey: sevenDaysAgo,
        workoutCountKey: 5,
      });
      expect(s.isEligible, isTrue,
          reason: 'Boundary values must be inclusive');
    });
  });

  group('maybeRequestReview', () {
    test('sets hasBeenRequested when eligible', () async {
      final s = await eligibleService();
      await s.maybeRequestReview();
      expect(s.hasBeenRequested, isTrue);
    });

    test('does not set hasBeenRequested when ineligible', () async {
      final s = await makeService(); // 0 workouts, 0 days
      await s.maybeRequestReview();
      expect(s.hasBeenRequested, isFalse);
    });

    test('does not set flag twice in the same session', () async {
      final s = await eligibleService();
      await s.maybeRequestReview();
      // After first call, isEligible is false (hasBeenRequested=true);
      // calling again must not throw and flag stays true
      await s.maybeRequestReview();
      expect(s.hasBeenRequested, isTrue);
    });

    test('marks hasBeenRequested true and persists to SharedPreferences', () async {
      final s = await eligibleService();
      await s.maybeRequestReview();
      expect(s.hasBeenRequested, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(reviewRequestedKey), isTrue);
    });

    test('isEligible becomes false after first call', () async {
      final s = await eligibleService();
      expect(s.isEligible, isTrue);
      await s.maybeRequestReview();
      expect(s.isEligible, isFalse,
          reason: 'Once requested, should not be eligible again');
    });
  });
}
