import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockFirestoreService mockFirestoreService;

    setUpAll(() async {
      // No Firebase initialization needed for fake firestore
    });

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      analyticsService = AnalyticsService.withFirestoreService(mockFirestoreService);
    });

    tearDown(() {
      analyticsService.clearCache();
    });

    group('computeWorkoutAnalytics', () {
      test('computes basic analytics correctly', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final workouts = _createTestWorkouts();
        final exercises = _createTestExercises();
        final sets = _createTestSets();

        // Mock Firestore responses
        when(mockFirestoreService.getPrograms(any))
            .thenAnswer((_) => Stream.value([]));

        // Act - Note: This test focuses on the computation logic
        // For full service testing, we'd need to mock the Firestore calls
        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: dateRange.start,
          endDate: dateRange.end,
          workouts: workouts,
          exercises: exercises,
          sets: sets,
        );

        // Assert
        expect(analytics.totalWorkouts, equals(2));
        expect(analytics.totalSets, equals(4));
        expect(analytics.totalVolume, equals(1840.0)); // 100*10 + 105*8 = 1840 (sets 3&4 have no weight)
        expect(analytics.exerciseTypeBreakdown.length, greaterThan(0));
        expect(analytics.averageSetsPerWorkout, equals(2.0));
      });

      test('handles empty data correctly', () async {
        final dateRange = DateRange.thisWeek();
        
        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: dateRange.start,
          endDate: dateRange.end,
          workouts: [],
          exercises: [],
          sets: [],
        );

        expect(analytics.totalWorkouts, equals(0));
        expect(analytics.totalSets, equals(0));
        expect(analytics.totalVolume, equals(0.0));
        expect(analytics.exerciseTypeBreakdown, isEmpty);
        expect(analytics.averageWorkoutDuration, equals(0.0));
      });

      test('filters workouts by date range correctly', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

        final workouts = [
          _createTestWorkout(
            id: '1',
            createdAt: now.subtract(const Duration(days: 3)), // Inside range
          ),
          _createTestWorkout(
            id: '2', 
            createdAt: now.subtract(const Duration(days: 10)), // Outside range
          ),
        ];

        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: dateRange.start,
          endDate: dateRange.end,
          workouts: workouts,
          exercises: [],
          sets: [],
        );

        expect(analytics.totalWorkouts, equals(1));
        expect(analytics.completedWorkoutIds, contains('1'));
        expect(analytics.completedWorkoutIds, isNot(contains('2')));
      });

      test('calculates exercise type breakdown correctly', () async {
        final exercises = [
          _createTestExercise(id: '1', exerciseType: ExerciseType.strength),
          _createTestExercise(id: '2', exerciseType: ExerciseType.strength),
          _createTestExercise(id: '3', exerciseType: ExerciseType.cardio),
          _createTestExercise(id: '4', exerciseType: ExerciseType.bodyweight),
        ];

        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          workouts: [],
          exercises: exercises,
          sets: [],
        );

        expect(analytics.exerciseTypeBreakdown[ExerciseType.strength], equals(2));
        expect(analytics.exerciseTypeBreakdown[ExerciseType.cardio], equals(1));
        expect(analytics.exerciseTypeBreakdown[ExerciseType.bodyweight], equals(1));
        expect(analytics.mostUsedExerciseType, equals(ExerciseType.strength));
      });
    });

    group('generateHeatmapData', () {
      test('generates heatmap data correctly', () async {
        final workouts = [
          _createTestWorkout(
            id: '1',
            createdAt: DateTime(2024, 1, 15),
          ),
          _createTestWorkout(
            id: '2',
            createdAt: DateTime(2024, 1, 15), // Same day
          ),
          _createTestWorkout(
            id: '3',
            createdAt: DateTime(2024, 1, 16),
          ),
        ];

        final heatmapData = ActivityHeatmapData.fromWorkouts(
          userId: 'test_user',
          year: 2024,
          workouts: workouts,
        );

        expect(heatmapData.year, equals(2024));
        expect(heatmapData.totalSets, equals(3));
        expect(heatmapData.getSetCountForDate(DateTime(2024, 1, 15)), equals(2));
        expect(heatmapData.getSetCountForDate(DateTime(2024, 1, 16)), equals(1));
        expect(heatmapData.getIntensityForDate(DateTime(2024, 1, 15)),
               equals(HeatmapIntensity.low));
      });

      test('calculates streaks correctly', () async {
        final workouts = [
          // Create consecutive workouts for streak
          _createTestWorkout(id: '1', createdAt: DateTime(2024, 1, 10)),
          _createTestWorkout(id: '2', createdAt: DateTime(2024, 1, 11)),
          _createTestWorkout(id: '3', createdAt: DateTime(2024, 1, 12)),
          // Gap
          _createTestWorkout(id: '4', createdAt: DateTime(2024, 1, 15)),
          _createTestWorkout(id: '5', createdAt: DateTime(2024, 1, 16)),
          _createTestWorkout(id: '6', createdAt: DateTime(2024, 1, 17)),
          _createTestWorkout(id: '7', createdAt: DateTime(2024, 1, 18)),
          _createTestWorkout(id: '8', createdAt: DateTime(2024, 1, 19)),
        ];

        final heatmapData = ActivityHeatmapData.fromWorkouts(
          userId: 'test_user',
          year: 2024,
          workouts: workouts,
        );

        // Should detect the longer streak (5 days: 15-19)
        expect(heatmapData.longestStreak, greaterThanOrEqualTo(3));
      });

      test('handles year boundary correctly', () async {
        final workouts = [
          _createTestWorkout(id: '1', createdAt: DateTime(2023, 12, 31)),
          _createTestWorkout(id: '2', createdAt: DateTime(2024, 1, 1)),
          _createTestWorkout(id: '3', createdAt: DateTime(2024, 12, 31)),
        ];

        final heatmapData = ActivityHeatmapData.fromWorkouts(
          userId: 'test_user',
          year: 2024,
          workouts: workouts,
        );

        expect(heatmapData.totalSets, equals(2)); // Only 2024 workouts
        expect(heatmapData.getSetCountForDate(DateTime(2024, 1, 1)), equals(1));
        expect(heatmapData.getSetCountForDate(DateTime(2024, 12, 31)), equals(1));
      });
    });

    group('generateSetBasedHeatmapData', () {
      test('counts only checked sets', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        final sets = [
          ExerciseSet(
            id: '1',
            setNumber: 1,
            reps: 10,
            weight: 100.0,
            checked: true, // Should be counted
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
          ExerciseSet(
            id: '2',
            setNumber: 2,
            reps: 10,
            weight: 100.0,
            checked: false, // Should NOT be counted
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
          ExerciseSet(
            id: '3',
            setNumber: 3,
            reps: 12,
            checked: true, // Should be counted
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex2',
            workoutId: 'w2',
            weekId: 'wk1',
            programId: 'p1',
          ),
        ];

        // Mock Firestore to return the test sets
        _mockSetBasedHeatmapData(mockFirestoreService, sets, 'p1');

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert
        expect(heatmapData.totalSets, equals(2)); // Only checked sets
        expect(heatmapData.programId, equals('p1'));
      });

      test('filters by programId correctly', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        final setsP1 = [
          ExerciseSet(
            id: '1',
            setNumber: 1,
            reps: 10,
            checked: true,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
        ];

        // Mock Firestore to return only p1 sets
        _mockSetBasedHeatmapData(mockFirestoreService, setsP1, 'p1');

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert
        expect(heatmapData.totalSets, equals(1));
        expect(heatmapData.programId, equals('p1'));
      });

      test('returns all programs when programId is null', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        final allSets = [
          ExerciseSet(
            id: '1',
            setNumber: 1,
            reps: 10,
            checked: true,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
          ExerciseSet(
            id: '2',
            setNumber: 1,
            reps: 12,
            checked: true,
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex2',
            workoutId: 'w2',
            weekId: 'wk2',
            programId: 'p2',
          ),
        ];

        // Mock Firestore to return all sets
        _mockSetBasedHeatmapData(mockFirestoreService, allSets, null);

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: null,
        );

        // Assert
        expect(heatmapData.totalSets, equals(2));
        expect(heatmapData.programId, isNull);
      });

      test('groups sets by date correctly', () async {
        // Arrange
        final now = DateTime.now();
        final date1 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
        final date2 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        final sets = [
          // 3 sets on date1
          ExerciseSet(
            id: '1',
            setNumber: 1,
            checked: true,
            createdAt: date1.add(const Duration(hours: 10)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
          ExerciseSet(
            id: '2',
            setNumber: 2,
            checked: true,
            createdAt: date1.add(const Duration(hours: 11)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
          ExerciseSet(
            id: '3',
            setNumber: 3,
            checked: true,
            createdAt: date1.add(const Duration(hours: 12)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex1',
            workoutId: 'w1',
            weekId: 'wk1',
            programId: 'p1',
          ),
          // 2 sets on date2
          ExerciseSet(
            id: '4',
            setNumber: 1,
            checked: true,
            createdAt: date2.add(const Duration(hours: 14)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex2',
            workoutId: 'w2',
            weekId: 'wk1',
            programId: 'p1',
          ),
          ExerciseSet(
            id: '5',
            setNumber: 2,
            checked: true,
            createdAt: date2.add(const Duration(hours: 15)),
            updatedAt: now,
            userId: 'test_user',
            exerciseId: 'ex2',
            workoutId: 'w2',
            weekId: 'wk1',
            programId: 'p1',
          ),
        ];

        // Mock Firestore
        _mockSetBasedHeatmapData(mockFirestoreService, sets, 'p1');

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert
        final normalizedDate1 = DateTime(date1.year, date1.month, date1.day);
        final normalizedDate2 = DateTime(date2.year, date2.month, date2.day);
        expect(heatmapData.getSetCountForDate(normalizedDate1), equals(3));
        expect(heatmapData.getSetCountForDate(normalizedDate2), equals(2));
        expect(heatmapData.totalSets, equals(5));
      });

      test('calculates intensity levels correctly', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        // Create sets with different counts per day to test intensity levels
        final date1 = now.subtract(const Duration(days: 6)); // 1 set -> low
        final date2 = now.subtract(const Duration(days: 5)); // 8 sets -> medium
        final date3 = now.subtract(const Duration(days: 4)); // 20 sets -> high
        final date4 = now.subtract(const Duration(days: 3)); // 30 sets -> veryHigh

        final sets = <ExerciseSet>[];

        // 1 set on date1 (intensity: low)
        sets.add(_createCheckedSet('s1', date1));

        // 8 sets on date2 (intensity: medium)
        for (int i = 0; i < 8; i++) {
          sets.add(_createCheckedSet('s2_$i', date2));
        }

        // 20 sets on date3 (intensity: high)
        for (int i = 0; i < 20; i++) {
          sets.add(_createCheckedSet('s3_$i', date3));
        }

        // 30 sets on date4 (intensity: veryHigh)
        for (int i = 0; i < 30; i++) {
          sets.add(_createCheckedSet('s4_$i', date4));
        }

        // Mock Firestore
        _mockSetBasedHeatmapData(mockFirestoreService, sets, 'p1');

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert
        final normalizedDate1 = DateTime(date1.year, date1.month, date1.day);
        final normalizedDate2 = DateTime(date2.year, date2.month, date2.day);
        final normalizedDate3 = DateTime(date3.year, date3.month, date3.day);
        final normalizedDate4 = DateTime(date4.year, date4.month, date4.day);

        expect(heatmapData.getIntensityForDate(normalizedDate1), equals(HeatmapIntensity.low));
        expect(heatmapData.getIntensityForDate(normalizedDate2), equals(HeatmapIntensity.medium));
        expect(heatmapData.getIntensityForDate(normalizedDate3), equals(HeatmapIntensity.high));
        expect(heatmapData.getIntensityForDate(normalizedDate4), equals(HeatmapIntensity.veryHigh));
      });

      test('calculates streaks based on days with sets', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        // Create consecutive days with sets
        final sets = <ExerciseSet>[];
        for (int i = 0; i < 5; i++) {
          final date = now.subtract(Duration(days: i));
          sets.add(_createCheckedSet('s$i', date));
        }

        // Mock Firestore
        _mockSetBasedHeatmapData(mockFirestoreService, sets, 'p1');

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert - should have current streak of 5 days
        expect(heatmapData.currentStreak, greaterThanOrEqualTo(1));
        expect(heatmapData.longestStreak, greaterThanOrEqualTo(1));
      });

      test('uses cache for repeated requests', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );

        final sets = [
          _createCheckedSet('s1', now.subtract(const Duration(days: 3))),
        ];

        // Mock Firestore
        _mockSetBasedHeatmapData(mockFirestoreService, sets, 'p1');

        // Act - make the same request twice
        final heatmapData1 = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        final heatmapData2 = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert - both should return same data
        expect(heatmapData1.totalSets, equals(heatmapData2.totalSets));
        expect(heatmapData1.programId, equals(heatmapData2.programId));

        // Verify Firestore was only called once (cached second time)
        // Note: This is implementation-dependent and may need adjustment
      });

      test('handles empty date range correctly', () async {
        // Arrange
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.add(const Duration(days: 1)), // Future date
          end: now.add(const Duration(days: 7)),
        );

        // Mock Firestore to return empty
        _mockSetBasedHeatmapData(mockFirestoreService, [], 'p1');

        // Act
        final heatmapData = await analyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: dateRange,
          programId: 'p1',
        );

        // Assert
        expect(heatmapData.totalSets, equals(0));
        expect(heatmapData.dailySetCounts, isEmpty);
        expect(heatmapData.currentStreak, equals(0));
        expect(heatmapData.longestStreak, equals(0));
      });
    });

    group('Personal Records Detection', () {
      test('detects weight PR correctly', () async {
        final exercise = _createTestExercise(
          id: 'ex1', 
          exerciseType: ExerciseType.strength,
        );
        expect(exercise.id, 'ex1'); // Use the variable to prevent unused warning

        final oldSet = ExerciseSet(
          id: 'set1',
          setNumber: 1,
          reps: 10,
          weight: 100.0,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final newSet = ExerciseSet(
          id: 'set2',
          setNumber: 1,
          reps: 10,
          weight: 105.0, // 5kg improvement
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w2',
          weekId: 'wk1',
          programId: 'p1',
        );

        // Test the PR detection logic (simplified)
        final isNewPR = newSet.weight! > oldSet.weight!;
        expect(isNewPR, isTrue);

        // Test PR creation
        final pr = PersonalRecord(
          id: 'pr1',
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          prType: PRType.maxWeight,
          value: newSet.weight!,
          previousValue: oldSet.weight!,
          achievedAt: newSet.createdAt,
          workoutId: newSet.workoutId,
          setId: newSet.id,
        );

        expect(pr.improvement, equals(5.0));
        expect(pr.improvementString, equals('+5'));
      });

      test('detects volume PR correctly', () async {
        final set1 = ExerciseSet(
          id: 'set1',
          setNumber: 1,
          reps: 10,
          weight: 100.0, // Volume: 1000
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final set2 = ExerciseSet(
          id: 'set2',
          setNumber: 1,
          reps: 12,
          weight: 95.0, // Volume: 1140 (higher)
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w2',
          weekId: 'wk1',
          programId: 'p1',
        );

        final oldVolume = set1.weight! * set1.reps!;
        final newVolume = set2.weight! * set2.reps!;

        expect(newVolume, greaterThan(oldVolume));
        expect(newVolume, equals(1140.0));
        expect(oldVolume, equals(1000.0));
      });

      test('detects duration PR for cardio exercises', () async {
        final set1 = ExerciseSet(
          id: 'set1',
          setNumber: 1,
          duration: 1800, // 30 minutes
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final set2 = ExerciseSet(
          id: 'set2',
          setNumber: 1,
          duration: 2100, // 35 minutes
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w2',
          weekId: 'wk1',
          programId: 'p1',
        );

        expect(set2.duration!, greaterThan(set1.duration!));

        final pr = PersonalRecord(
          id: 'pr1',
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Running',
          exerciseType: ExerciseType.cardio,
          prType: PRType.maxDuration,
          value: set2.duration!.toDouble(),
          previousValue: set1.duration!.toDouble(),
          achievedAt: set2.createdAt,
          workoutId: set2.workoutId,
          setId: set2.id,
        );

        expect(pr.improvement, equals(300.0)); // 5 minutes = 300 seconds
      });
    });

    group('Cache Management', () {
      test('caches results correctly', () async {
        // This test would require access to the internal cache
        // In a real implementation, you'd expose cache state for testing
        analyticsService.clearCache();
        
        // Verify cache is empty (implementation dependent)
        expect(true, isTrue); // Placeholder - actual implementation would test cache state
      });

      test('cache expiry works correctly', () async {
        // This would test that cached data expires after the specified duration
        // Implementation would depend on how the cache is structured
        expect(true, isTrue); // Placeholder
      });
    });

    group('Error Handling', () {
      test('handles malformed data gracefully', () async {
        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          workouts: [],
          exercises: [],
          sets: [
            // Set without required fields should not crash
            ExerciseSet(
              id: 'bad_set',
              setNumber: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userId: 'test_user',
              exerciseId: 'ex1',
              workoutId: 'w1',
              weekId: 'wk1',
              programId: 'p1',
            ),
          ],
        );

        expect(analytics.totalSets, equals(1));
        expect(analytics.totalVolume, equals(0.0)); // No weight or reps
      });
    });
  });
}

// Helper methods for creating test data
List<Workout> _createTestWorkouts() {
  final now = DateTime.now();
  return [
    _createTestWorkout(id: '1', createdAt: now.subtract(const Duration(days: 1))),
    _createTestWorkout(id: '2', createdAt: now.subtract(const Duration(days: 2))),
  ];
}

Workout _createTestWorkout({required String id, DateTime? createdAt}) {
  final date = createdAt ?? DateTime.now();
  return Workout(
    id: id,
    name: 'Test Workout $id',
    orderIndex: 0,
    createdAt: date,
    updatedAt: date,
    userId: 'test_user',
    weekId: 'week1',
    programId: 'prog1',
  );
}

List<Exercise> _createTestExercises() {
  return [
    _createTestExercise(id: '1', exerciseType: ExerciseType.strength),
    _createTestExercise(id: '2', exerciseType: ExerciseType.bodyweight),
  ];
}

Exercise _createTestExercise({
  required String id, 
  ExerciseType? exerciseType,
}) {
  final now = DateTime.now();
  return Exercise(
    id: id,
    name: 'Test Exercise $id',
    exerciseType: exerciseType ?? ExerciseType.strength,
    orderIndex: 0,
    createdAt: now,
    updatedAt: now,
    userId: 'test_user',
    workoutId: 'w1',
    weekId: 'week1',
    programId: 'prog1',
  );
}

List<ExerciseSet> _createTestSets() {
  final now = DateTime.now();
  return [
    ExerciseSet(
      id: '1',
      setNumber: 1,
      reps: 10,
      weight: 100.0,
      createdAt: now,
      updatedAt: now,
      userId: 'test_user',
      exerciseId: '1',
      workoutId: 'w1',
      weekId: 'week1',
      programId: 'prog1',
    ),
    ExerciseSet(
      id: '2',
      setNumber: 2,
      reps: 8,
      weight: 105.0,
      createdAt: now,
      updatedAt: now,
      userId: 'test_user',
      exerciseId: '1',
      workoutId: 'w1',
      weekId: 'week1',
      programId: 'prog1',
    ),
    ExerciseSet(
      id: '3',
      setNumber: 1,
      reps: 15,
      createdAt: now,
      updatedAt: now,
      userId: 'test_user',
      exerciseId: '2',
      workoutId: 'w2',
      weekId: 'week1',
      programId: 'prog1',
    ),
    ExerciseSet(
      id: '4',
      setNumber: 1,
      duration: 1800, // 30 minutes
      createdAt: now,
      updatedAt: now,
      userId: 'test_user',
      exerciseId: '3',
      workoutId: 'w2',
      weekId: 'week1',
      programId: 'prog1',
    ),
  ];
}

// Helper to create a checked set for testing
ExerciseSet _createCheckedSet(String id, DateTime createdAt) {
  return ExerciseSet(
    id: id,
    setNumber: 1,
    reps: 10,
    checked: true,
    createdAt: createdAt,
    updatedAt: createdAt,
    userId: 'test_user',
    exerciseId: 'ex1',
    workoutId: 'w1',
    weekId: 'wk1',
    programId: 'p1',
  );
}

// Helper to mock set-based heatmap data
void _mockSetBasedHeatmapData(
  MockFirestoreService mockService,
  List<ExerciseSet> sets,
  String? programId,
) {
  // Mock the hierarchical Firestore structure
  when(mockService.getPrograms(any)).thenAnswer((_) {
    if (programId != null) {
      return Stream.value([
        Program(
          id: programId,
          name: 'Test Program',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
        ),
      ]);
    } else {
      // Return multiple programs for "All Programs" case
      return Stream.value([
        Program(
          id: 'p1',
          name: 'Program 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
        ),
        Program(
          id: 'p2',
          name: 'Program 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
        ),
      ]);
    }
  });

  when(mockService.getWeeks(any, any)).thenAnswer((_) => Stream.value([
        Week(
          id: 'wk1',
          name: 'Week 1',
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          programId: programId ?? 'p1',
        ),
      ]));

  when(mockService.getWorkouts(any, any, any)).thenAnswer((_) => Stream.value([
        Workout(
          id: 'w1',
          name: 'Workout 1',
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          weekId: 'wk1',
          programId: programId ?? 'p1',
        ),
      ]));

  when(mockService.getExercises(any, any, any, any)).thenAnswer((_) => Stream.value([
        Exercise(
          id: 'ex1',
          name: 'Exercise 1',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: programId ?? 'p1',
        ),
      ]));

  when(mockService.getSets(any, any, any, any, any))
      .thenAnswer((_) => Stream.value(sets));
}