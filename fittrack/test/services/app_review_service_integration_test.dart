/// Integration tests for AppReviewService.
///
/// AppReviewService uses SharedPreferences only (no Firebase).
/// These tests exercise real SharedPreferences lifecycle end-to-end —
/// persistence across re-initialisation, workout count accumulation, and
/// eligibility gate logic. Firebase emulators are not required.
///
/// InAppReview (platform channel) is mocked so tests run in CI without a
/// device. The "integration" value is the SharedPreferences persistence
/// lifecycle, not the platform review API.

@Timeout(Duration(seconds: 30))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/app_review_service.dart';

import 'app_review_service_integration_test.mocks.dart';

@GenerateMocks([InAppReview])
void main() {
  late MockInAppReview mockReview;

  const firstLaunchKey = 'overload_first_launch_date';
  const workoutCountKey = 'overload_workout_count';

  setUp(() {
    mockReview = MockInAppReview();
    when(mockReview.isAvailable()).thenAnswer((_) async => true);
    when(mockReview.requestReview()).thenAnswer((_) async {});
  });

  Future<AppReviewService> makeService({
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return AppReviewService.forTest(prefs, mockReview);
  }

  group('AppReviewService - Integration (SharedPreferences lifecycle)', () {
    test('first launch date is written and persists across re-initialisation',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      AppReviewService.forTest(prefs, mockReview);

      // Re-initialise from same prefs (simulates app restart)
      final prefs2 = await SharedPreferences.getInstance();
      final s2 = AppReviewService.forTest(prefs2, mockReview);

      expect(s2.daysSinceFirstLaunch, greaterThanOrEqualTo(0),
          reason: 'Launch date should survive re-initialisation');
      expect(prefs2.getString(firstLaunchKey), isNotNull);
    });

    test('workout count accumulates and persists across re-initialisation',
        () async {
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      final s1 = AppReviewService.forTest(prefs, mockReview);
      s1.recordWorkoutStarted();
      s1.recordWorkoutStarted();
      s1.recordWorkoutStarted();

      // Re-initialise — simulates app restart
      prefs = await SharedPreferences.getInstance();
      final s2 = AppReviewService.forTest(prefs, mockReview);

      expect(s2.workoutCount, 3,
          reason: 'Workout count must survive app restart');
      expect(prefs.getInt(workoutCountKey), 3);
    });

    test('review is not requested when below workout count threshold', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final s = await makeService(prefsValues: {
        firstLaunchKey: tenDaysAgo,
        workoutCountKey: 4, // one short of threshold
      });

      await s.maybeRequestReview();

      verifyNever(mockReview.requestReview());
    });

    test('review is not requested when below days-since-launch threshold',
        () async {
      final threeDaysAgo =
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
      final s = await makeService(prefsValues: {
        firstLaunchKey: threeDaysAgo,
        workoutCountKey: 10,
      });

      await s.maybeRequestReview();

      verifyNever(mockReview.requestReview());
    });

    test('hasBeenRequested flag persists after review is triggered', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        firstLaunchKey: tenDaysAgo,
        workoutCountKey: 5,
      });
      var prefs = await SharedPreferences.getInstance();
      final s1 = AppReviewService.forTest(prefs, mockReview);
      await s1.maybeRequestReview();
      expect(s1.hasBeenRequested, isTrue);

      // Re-initialise — review should not fire again
      prefs = await SharedPreferences.getInstance();
      final s2 = AppReviewService.forTest(prefs, mockReview);
      expect(s2.hasBeenRequested, isTrue,
          reason: 'Requested flag must persist across app restarts');
      expect(s2.isEligible, isFalse,
          reason: 'Should not be eligible again once requested');
    });

    test('full review lifecycle: accumulate workouts → wait → prompt → not again',
        () async {
      // Simulate a user who has had the app for 10 days
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      SharedPreferences.setMockInitialValues({firstLaunchKey: tenDaysAgo});
      var prefs = await SharedPreferences.getInstance();
      var s = AppReviewService.forTest(prefs, mockReview);

      // Log 5 workouts
      for (int i = 0; i < 5; i++) {
        s.recordWorkoutStarted();
      }
      expect(s.isEligible, isTrue);

      // Review fires on first eligible call
      await s.maybeRequestReview();
      verify(mockReview.requestReview()).called(1);

      // Re-initialise (next app session) — no longer eligible
      prefs = await SharedPreferences.getInstance();
      s = AppReviewService.forTest(prefs, mockReview);
      expect(s.isEligible, isFalse,
          reason: 'hasBeenRequested flag persists — should not be eligible again');

      // Reset mock interactions, then confirm no second request
      clearInteractions(mockReview);
      await s.maybeRequestReview();
      verifyNever(mockReview.requestReview());
    });
  });
}
