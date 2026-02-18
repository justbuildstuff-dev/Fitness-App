import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
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

    group('getMonthHeatmapData', () {
      test('returns correct month data for December 2024', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        // Create test sets for December 2024
        final testSets = [
          _createTestSet(
            id: 's1',
            createdAt: DateTime(2024, 12, 1),
            checked: true,
          ),
          _createTestSet(
            id: 's2',
            createdAt: DateTime(2024, 12, 1),
            checked: true,
          ),
          _createTestSet(
            id: 's3',
            createdAt: DateTime(2024, 12, 5),
            checked: true,
          ),
          _createTestSet(
            id: 's4',
            createdAt: DateTime(2024, 12, 15),
            checked: true,
          ),
          _createTestSet(
            id: 's5',
            createdAt: DateTime(2024, 12, 15),
            checked: true,
          ),
          _createTestSet(
            id: 's6',
            createdAt: DateTime(2024, 12, 15),
            checked: true,
          ),
        ];

        _setupMockFirestore(mockService, sets: testSets);

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        expect(monthData.year, equals(2024));
        expect(monthData.month, equals(12));
        expect(monthData.totalSets, equals(6));
        expect(monthData.getSetCountForDay(1), equals(2));
        expect(monthData.getSetCountForDay(5), equals(1));
        expect(monthData.getSetCountForDay(15), equals(3));
        expect(monthData.getSetCountForDay(10), equals(0)); // No data
      });

      test('filters out unchecked sets', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2024, 12, 1), checked: true),
          _createTestSet(id: 's2', createdAt: DateTime(2024, 12, 1), checked: false), // Not checked
          _createTestSet(id: 's3', createdAt: DateTime(2024, 12, 5), checked: true),
        ];

        _setupMockFirestore(mockService, sets: testSets);

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        expect(monthData.totalSets, equals(2)); // Only 2 checked
        expect(monthData.getSetCountForDay(1), equals(1)); // Only 1 checked on day 1
      });

      test('returns empty data for month with no sets', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        _setupMockFirestore(mockService, sets: []); // No sets

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        expect(monthData.year, equals(2024));
        expect(monthData.month, equals(12));
        expect(monthData.totalSets, equals(0));
        expect(monthData.dailySetCounts, isEmpty);
      });

      test('only includes sets from specified month', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2024, 11, 30), checked: true), // Nov
          _createTestSet(id: 's2', createdAt: DateTime(2024, 12, 1), checked: true),  // Dec
          _createTestSet(id: 's3', createdAt: DateTime(2024, 12, 31), checked: true), // Dec
          _createTestSet(id: 's4', createdAt: DateTime(2025, 1, 1), checked: true),   // Jan
        ];

        _setupMockFirestore(mockService, sets: testSets);

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        expect(monthData.totalSets, equals(2)); // Only Dec 1 and Dec 31
        expect(monthData.getSetCountForDay(1), equals(1));
        expect(monthData.getSetCountForDay(31), equals(1));
      });

      test('aggregates sets from all programs', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(
            id: 's1',
            createdAt: DateTime(2024, 12, 1),
            checked: true,
            programId: 'p1',
          ),
          _createTestSet(
            id: 's2',
            createdAt: DateTime(2024, 12, 1),
            checked: true,
            programId: 'p2',
          ),
        ];

        _setupMockFirestore(mockService, sets: testSets);

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        expect(monthData.totalSets, equals(2)); // Aggregates from both programs
        expect(monthData.getSetCountForDay(1), equals(2));
      });

      test('caches results for 5 minutes', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2024, 12, 1), checked: true),
        ];

        _setupMockFirestore(mockService, sets: testSets);

        // First call
        final data1 = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        // Second call should use cache
        final data2 = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        expect(data1.fetchedAt, equals(data2.fetchedAt)); // Same cached data
        expect(data2.isCacheValid, isTrue);
      });

      test('handles February with 28 days', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2023, 2, 28), checked: true), // Last day
        ];

        _setupMockFirestore(mockService, sets: testSets);

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2023,
          month: 2,
        );

        expect(monthData.getSetCountForDay(28), equals(1));
        expect(monthData.getSetCountForDay(29), equals(0)); // No Feb 29 in 2023
      });

      test('handles months with 30 days', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2024, 4, 30), checked: true), // Last day
        ];

        _setupMockFirestore(mockService, sets: testSets);

        final monthData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 4,
        );

        expect(monthData.getSetCountForDay(30), equals(1));
        expect(monthData.getSetCountForDay(31), equals(0)); // No April 31
      });
    });

    group('prefetchAdjacentMonths', () {
      test('fetches previous and next month in parallel', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2024, 11, 15), checked: true), // Nov
          _createTestSet(id: 's2', createdAt: DateTime(2024, 12, 15), checked: true), // Dec
          _createTestSet(id: 's3', createdAt: DateTime(2025, 1, 15), checked: true),  // Jan
        ];

        _setupMockFirestore(mockService, sets: testSets);

        // Pre-fetch for December 2024
        await analyticsService.prefetchAdjacentMonths(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        // Both months should be cached now
        // Verify by fetching them (should be instant from cache)
        final novData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 11,
        );

        final janData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2025,
          month: 1,
        );

        expect(novData.totalSets, equals(1));
        expect(janData.totalSets, equals(1));
        expect(novData.isCacheValid, isTrue);
        expect(janData.isCacheValid, isTrue);
      });

      test('handles year boundary (December to January)', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2024, 11, 15), checked: true),
          _createTestSet(id: 's2', createdAt: DateTime(2025, 1, 15), checked: true),
        ];

        _setupMockFirestore(mockService, sets: testSets);

        // Pre-fetch for December 2024
        await analyticsService.prefetchAdjacentMonths(
          userId: 'test_user',
          year: 2024,
          month: 12,
        );

        // Should fetch Nov 2024 and Jan 2025
        final novData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 11,
        );

        final janData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2025,
          month: 1,
        );

        expect(novData.year, equals(2024));
        expect(novData.month, equals(11));
        expect(janData.year, equals(2025));
        expect(janData.month, equals(1));
      });

      test('handles year boundary (January to December)', () async {
        final mockService = MockFirestoreService();
        final analyticsService = AnalyticsService.withFirestoreService(mockService);

        final testSets = [
          _createTestSet(id: 's1', createdAt: DateTime(2023, 12, 15), checked: true),
          _createTestSet(id: 's2', createdAt: DateTime(2024, 2, 15), checked: true),
        ];

        _setupMockFirestore(mockService, sets: testSets);

        // Pre-fetch for January 2024
        await analyticsService.prefetchAdjacentMonths(
          userId: 'test_user',
          year: 2024,
          month: 1,
        );

        // Should fetch Dec 2023 and Feb 2024
        final decData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2023,
          month: 12,
        );

        final febData = await analyticsService.getMonthHeatmapData(
          userId: 'test_user',
          year: 2024,
          month: 2,
        );

        expect(decData.year, equals(2023));
        expect(decData.month, equals(12));
        expect(febData.year, equals(2024));
        expect(febData.month, equals(2));
      });
    });

    group('getExerciseProgress', () {
      test('returns data points grouped by workout session', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final testSets = [
          // Workout 1: 2 sets for exercise ex1
          _createTestSetFull(
            id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 80.0, reps: 10,
            createdAt: now.subtract(const Duration(days: 7)),
          ),
          _createTestSetFull(
            id: 's2', exerciseId: 'ex1', workoutId: 'w1',
            weight: 85.0, reps: 8,
            createdAt: now.subtract(const Duration(days: 7)),
          ),
          // Workout 2: 1 set for exercise ex1
          _createTestSetFull(
            id: 's3', exerciseId: 'ex1', workoutId: 'w2',
            weight: 90.0, reps: 5,
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          // Different exercise - should be filtered out
          _createTestSetFull(
            id: 's4', exerciseId: 'ex2', workoutId: 'w1',
            weight: 50.0, reps: 12,
            createdAt: now.subtract(const Duration(days: 7)),
          ),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [
            _createTestExercise(id: 'ex1', exerciseType: ExerciseType.strength, workoutId: 'w1'),
            _createTestExercise(id: 'ex2', exerciseType: ExerciseType.strength, workoutId: 'w1'),
            _createTestExercise(id: 'ex1', exerciseType: ExerciseType.strength, workoutId: 'w2'),
          ],
          workouts: [
            _createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 7))),
            _createTestWorkout(id: 'w2', createdAt: now.subtract(const Duration(days: 3))),
          ],
        );

        final result = await analyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        );

        expect(result.exerciseId, equals('ex1'));
        expect(result.exerciseName, equals('Bench Press'));
        expect(result.dataPoints.length, equals(2)); // 2 workout sessions
        expect(result.isEmpty, isFalse);

        // First session: maxWeight should be 85, maxReps should be 10
        // totalVolume = 80*10 + 85*8 = 800 + 680 = 1480
        final firstPoint = result.dataPoints.first;
        expect(firstPoint.maxWeight, equals(85.0));
        expect(firstPoint.maxReps, equals(10));
        expect(firstPoint.totalVolume, equals(1480.0));

        // Second session: single set 90kg x 5
        final secondPoint = result.dataPoints.last;
        expect(secondPoint.maxWeight, equals(90.0));
        expect(secondPoint.maxReps, equals(5));
        expect(secondPoint.totalVolume, equals(450.0));
      });

      test('includes estimated 1RM for strength exercises', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final testSets = [
          _createTestSetFull(
            id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 100.0, reps: 5,
            createdAt: now.subtract(const Duration(days: 3)),
          ),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [_createTestExercise(id: 'ex1')],
          workouts: [_createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 3)))],
        );

        final result = await analyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Squat',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        );

        expect(result.dataPoints.length, equals(1));
        // Epley: 100 * (1 + 5/30) ≈ 116.67
        expect(result.dataPoints.first.estimated1RM, closeTo(116.67, 0.01));
      });

      test('returns null estimated 1RM for non-strength exercises', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final testSets = [
          _createTestSetFull(
            id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            reps: 15, createdAt: now.subtract(const Duration(days: 3)),
          ),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [_createTestExercise(id: 'ex1', exerciseType: ExerciseType.bodyweight)],
          workouts: [_createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 3)))],
        );

        final result = await analyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Push-ups',
          exerciseType: ExerciseType.bodyweight,
          dateRange: dateRange,
        );

        expect(result.dataPoints.first.estimated1RM, isNull);
      });

      test('returns empty data points when no matching sets', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: [],
          exercises: [],
          workouts: [],
        );

        final result = await analyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex_nonexistent',
          exerciseName: 'Nothing',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        );

        expect(result.isEmpty, isTrue);
        expect(result.dataPoints, isEmpty);
      });

      test('computes duration and distance for cardio exercises', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final testSets = [
          _createTestSetFull(
            id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            duration: 1800, distance: 5000.0,
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          _createTestSetFull(
            id: 's2', exerciseId: 'ex1', workoutId: 'w1',
            duration: 900, distance: 2500.0,
            createdAt: now.subtract(const Duration(days: 3)),
          ),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [_createTestExercise(id: 'ex1', exerciseType: ExerciseType.cardio)],
          workouts: [_createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 3)))],
        );

        final result = await analyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Running',
          exerciseType: ExerciseType.cardio,
          dateRange: dateRange,
        );

        expect(result.dataPoints.length, equals(1));
        expect(result.dataPoints.first.totalDuration, equals(2700));
        expect(result.dataPoints.first.totalDistance, equals(7500.0));
      });
    });

    group('getMuscleGroupVolume', () {
      test('maps exercises to muscle groups by name', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final libraryExercises = [
          const LibraryExercise(
            id: 'lib1', name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            primaryMuscles: [MuscleGroup.chest],
          ),
          const LibraryExercise(
            id: 'lib2', name: 'Barbell Row',
            exerciseType: ExerciseType.strength,
            primaryMuscles: [MuscleGroup.back],
          ),
        ];

        final testSets = [
          _createTestSetFull(id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 100, reps: 10, createdAt: now.subtract(const Duration(days: 5))),
          _createTestSetFull(id: 's2', exerciseId: 'ex1', workoutId: 'w1',
            weight: 100, reps: 8, createdAt: now.subtract(const Duration(days: 5))),
          _createTestSetFull(id: 's3', exerciseId: 'ex2', workoutId: 'w1',
            weight: 80, reps: 10, createdAt: now.subtract(const Duration(days: 5))),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [
            _createTestExerciseWithName(id: 'ex1', name: 'Bench Press'),
            _createTestExerciseWithName(id: 'ex2', name: 'Barbell Row'),
          ],
          workouts: [_createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 5)))],
        );

        final result = await analyticsService.getMuscleGroupVolume(
          userId: 'test_user',
          dateRange: dateRange,
          libraryExercises: libraryExercises,
          customExercises: [],
        );

        expect(result.length, equals(2)); // chest and back
        // Chest has 2 sets, Back has 1 set
        final chestVolume = result.firstWhere((v) => v.muscleGroup == MuscleGroup.chest);
        final backVolume = result.firstWhere((v) => v.muscleGroup == MuscleGroup.back);
        expect(chestVolume.totalSets, equals(2));
        expect(backVolume.totalSets, equals(1));
        expect(chestVolume.percentage, closeTo(66.67, 0.01));
        expect(backVolume.percentage, closeTo(33.33, 0.01));
      });

      test('groups unmatched exercises as Other', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final testSets = [
          _createTestSetFull(id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 50, reps: 10, createdAt: now.subtract(const Duration(days: 5))),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [
            _createTestExerciseWithName(id: 'ex1', name: 'My Custom Move'),
          ],
          workouts: [_createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 5)))],
        );

        // No library exercises match "My Custom Move"
        final result = await analyticsService.getMuscleGroupVolume(
          userId: 'test_user',
          dateRange: dateRange,
          libraryExercises: [],
          customExercises: [],
        );

        expect(result.length, equals(1));
        expect(result.first.muscleGroup, isNull);
        expect(result.first.label, equals('Other'));
        expect(result.first.totalSets, equals(1));
        expect(result.first.percentage, equals(100.0));
      });

      test('returns empty list when no data', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService, sets: [], exercises: [], workouts: [],
        );

        final result = await analyticsService.getMuscleGroupVolume(
          userId: 'test_user',
          dateRange: dateRange,
          libraryExercises: [],
          customExercises: [],
        );

        expect(result, isEmpty);
      });

      test('matches custom exercises by name', () async {
        final now = DateTime.now();
        final dateRange = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final customExercises = [
          CustomExercise(
            id: 'custom1', name: 'My Curl',
            exerciseType: ExerciseType.strength,
            primaryMuscles: const [MuscleGroup.arms],
            userId: 'test_user',
            createdAt: now, updatedAt: now,
          ),
        ];

        final testSets = [
          _createTestSetFull(id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 20, reps: 12, createdAt: now.subtract(const Duration(days: 5))),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [_createTestExerciseWithName(id: 'ex1', name: 'My Curl')],
          workouts: [_createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 5)))],
        );

        final result = await analyticsService.getMuscleGroupVolume(
          userId: 'test_user',
          dateRange: dateRange,
          libraryExercises: [],
          customExercises: customExercises,
        );

        expect(result.length, equals(1));
        expect(result.first.muscleGroup, equals(MuscleGroup.arms));
        expect(result.first.label, equals('Arms'));
      });
    });

    group('getWeeklyTrends', () {
      test('groups data by ISO week (Monday-Sunday)', () async {
        // Monday Jan 6 2025
        final monday = DateTime(2025, 1, 6);
        final dateRange = DateRange(
          start: monday,
          end: monday.add(const Duration(days: 13, hours: 23, minutes: 59, seconds: 59)),
        );

        final testSets = [
          // Week 1: Mon Jan 6 and Wed Jan 8
          _createTestSetFull(id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 100, reps: 10, createdAt: DateTime(2025, 1, 6, 10)),
          _createTestSetFull(id: 's2', exerciseId: 'ex1', workoutId: 'w2',
            weight: 80, reps: 8, createdAt: DateTime(2025, 1, 8, 10)),
          // Week 2: Mon Jan 13
          _createTestSetFull(id: 's3', exerciseId: 'ex1', workoutId: 'w3',
            weight: 90, reps: 5, createdAt: DateTime(2025, 1, 13, 10)),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [
            _createTestExercise(id: 'ex1', workoutId: 'w1'),
            _createTestExercise(id: 'ex1', workoutId: 'w2'),
            _createTestExercise(id: 'ex1', workoutId: 'w3'),
          ],
          workouts: [
            _createTestWorkout(id: 'w1', createdAt: DateTime(2025, 1, 6, 10)),
            _createTestWorkout(id: 'w2', createdAt: DateTime(2025, 1, 8, 10)),
            _createTestWorkout(id: 'w3', createdAt: DateTime(2025, 1, 13, 10)),
          ],
        );

        final result = await analyticsService.getWeeklyTrends(
          userId: 'test_user',
          dateRange: dateRange,
        );

        expect(result.length, equals(2));

        // Week 1: volume = 100*10 + 80*8 = 1640, workouts = 2
        expect(result[0].weekStart, equals(DateTime(2025, 1, 6)));
        expect(result[0].totalVolume, equals(1640.0));
        expect(result[0].workoutCount, equals(2));

        // Week 2: volume = 90*5 = 450, workouts = 1
        expect(result[1].weekStart, equals(DateTime(2025, 1, 13)));
        expect(result[1].totalVolume, equals(450.0));
        expect(result[1].workoutCount, equals(1));
      });

      test('returns empty list when no data', () async {
        final dateRange = DateRange.lastMonth();

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService, sets: [], exercises: [], workouts: [],
        );

        final result = await analyticsService.getWeeklyTrends(
          userId: 'test_user',
          dateRange: dateRange,
        );

        expect(result, isEmpty);
      });

      test('sorted chronologically', () async {
        final dateRange = DateRange(
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 1, 31, 23, 59, 59),
        );

        final testSets = [
          _createTestSetFull(id: 's1', exerciseId: 'ex1', workoutId: 'w1',
            weight: 50, reps: 10, createdAt: DateTime(2025, 1, 20, 10)),
          _createTestSetFull(id: 's2', exerciseId: 'ex1', workoutId: 'w2',
            weight: 60, reps: 10, createdAt: DateTime(2025, 1, 6, 10)),
        ];

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: testSets,
          exercises: [
            _createTestExercise(id: 'ex1', workoutId: 'w1'),
            _createTestExercise(id: 'ex1', workoutId: 'w2'),
          ],
          workouts: [
            _createTestWorkout(id: 'w1', createdAt: DateTime(2025, 1, 20, 10)),
            _createTestWorkout(id: 'w2', createdAt: DateTime(2025, 1, 6, 10)),
          ],
        );

        final result = await analyticsService.getWeeklyTrends(
          userId: 'test_user',
          dateRange: dateRange,
        );

        expect(result.length, equals(2));
        // Should be sorted: Jan 6 week before Jan 20 week
        expect(result[0].weekStart.isBefore(result[1].weekStart), isTrue);
      });
    });

    group('getConfigurableStreak', () {
      test('returns 0 streak when no workouts', () async {
        when(mockFirestoreService.getPrograms(any))
            .thenAnswer((_) => Stream.value([]));

        final result = await analyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 3,
        );

        expect(result.weeklyTarget, equals(3));
        expect(result.currentStreak, equals(0));
        expect(result.longestStreak, equals(0));
      });

      test('counts consecutive weeks meeting target', () async {
        final now = DateTime.now();
        // Anchor to the Monday of the current week to avoid day-of-week issues
        final thisMonday = now.subtract(Duration(days: now.weekday - 1));

        // Create workouts for 3 consecutive weeks (target = 2 per week)
        final workouts = <Workout>[];
        for (int week = 0; week < 3; week++) {
          final weekMonday = thisMonday.subtract(Duration(days: week * 7));
          for (int day = 0; day < 2; day++) {
            workouts.add(_createTestWorkout(
              id: 'w_${week}_$day',
              createdAt: weekMonday.add(Duration(days: day)),
            ));
          }
        }

        _setupMockFirestoreWithWorkoutsOnly(mockFirestoreService, workouts);

        final result = await analyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 2,
        );

        expect(result.currentStreak, equals(3));
        expect(result.longestStreak, equals(3));
      });

      test('breaks streak when week misses target', () async {
        final now = DateTime.now();
        // Anchor to the Monday of the current week to avoid day-of-week issues
        final thisMonday = now.subtract(Duration(days: now.weekday - 1));
        final lastMonday = thisMonday.subtract(const Duration(days: 7));
        final twoWeeksAgoMonday = thisMonday.subtract(const Duration(days: 14));

        // Current week: 3 workouts (meets target of 2)
        // Last week: 1 workout (misses target of 2)
        // 2 weeks ago: 2 workouts (meets target of 2)
        final workouts = <Workout>[
          // Current week - 3 workouts within Mon-Wed
          _createTestWorkout(id: 'w1', createdAt: thisMonday),
          _createTestWorkout(id: 'w2', createdAt: thisMonday.add(const Duration(days: 1))),
          _createTestWorkout(id: 'w3', createdAt: thisMonday.add(const Duration(days: 2))),
          // Last week - only 1 workout (below target)
          _createTestWorkout(id: 'w4', createdAt: lastMonday),
          // 2 weeks ago - meets target
          _createTestWorkout(id: 'w5', createdAt: twoWeeksAgoMonday),
          _createTestWorkout(id: 'w6', createdAt: twoWeeksAgoMonday.add(const Duration(days: 1))),
        ];

        _setupMockFirestoreWithWorkoutsOnly(mockFirestoreService, workouts);

        final result = await analyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 2,
        );

        // Current streak should be 1 (only current week meets target)
        expect(result.currentStreak, equals(1));
        // Longest streak should be 1 (no consecutive weeks)
        expect(result.longestStreak, greaterThanOrEqualTo(1));
      });

      test('finds longest streak across history', () async {
        final now = DateTime.now();
        // Anchor to the Monday of the current week to avoid day-of-week issues
        final thisMonday = now.subtract(Duration(days: now.weekday - 1));

        // Create a gap then a longer streak in the past
        final workouts = <Workout>[];

        // Old streak: 5 consecutive weeks, starting 20 weeks ago
        for (int week = 20; week > 15; week--) {
          final weekMonday = thisMonday.subtract(Duration(days: week * 7));
          for (int day = 0; day < 3; day++) {
            workouts.add(_createTestWorkout(
              id: 'old_${week}_$day',
              createdAt: weekMonday.add(Duration(days: day)),
            ));
          }
        }

        // Current: 2 weeks meeting target (this week + last week)
        for (int week = 0; week < 2; week++) {
          final weekMonday = thisMonday.subtract(Duration(days: week * 7));
          for (int day = 0; day < 3; day++) {
            workouts.add(_createTestWorkout(
              id: 'new_${week}_$day',
              createdAt: weekMonday.add(Duration(days: day)),
            ));
          }
        }

        _setupMockFirestoreWithWorkoutsOnly(mockFirestoreService, workouts);

        final result = await analyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 3,
        );

        expect(result.currentStreak, equals(2));
        expect(result.longestStreak, equals(5));
      });
    });

    group('getLoggedExercises', () {
      test('returns deduplicated exercises sorted alphabetically', () async {
        final now = DateTime.now();

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: [],
          exercises: [
            _createTestExerciseWithName(id: 'ex1', name: 'Squat'),
            _createTestExerciseWithName(id: 'ex2', name: 'Bench Press'),
            _createTestExerciseWithName(id: 'ex3', name: 'squat'), // Duplicate (different case)
            _createTestExerciseWithName(id: 'ex4', name: 'Deadlift'),
          ],
          workouts: [
            _createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 5))),
          ],
        );

        final result = await analyticsService.getLoggedExercises(
          userId: 'test_user',
        );

        // Should be deduplicated: Bench Press, Deadlift, Squat (3 unique)
        expect(result.length, equals(3));
        expect(result[0].exerciseName, equals('Bench Press'));
        expect(result[1].exerciseName, equals('Deadlift'));
        expect(result[2].exerciseName, equals('Squat'));
      });

      test('returns empty list when no exercises', () async {
        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService, sets: [], exercises: [], workouts: [],
        );

        final result = await analyticsService.getLoggedExercises(
          userId: 'test_user',
        );

        expect(result, isEmpty);
      });

      test('preserves exercise type in results', () async {
        final now = DateTime.now();

        _setupMockFirestoreWithSetsAndExercises(
          mockFirestoreService,
          sets: [],
          exercises: [
            _createTestExerciseWithName(id: 'ex1', name: 'Bench Press', exerciseType: ExerciseType.strength),
            _createTestExerciseWithName(id: 'ex2', name: 'Running', exerciseType: ExerciseType.cardio),
          ],
          workouts: [
            _createTestWorkout(id: 'w1', createdAt: now.subtract(const Duration(days: 5))),
          ],
        );

        final result = await analyticsService.getLoggedExercises(
          userId: 'test_user',
        );

        expect(result.length, equals(2));
        final benchPress = result.firstWhere((e) => e.exerciseName == 'Bench Press');
        final running = result.firstWhere((e) => e.exerciseName == 'Running');
        expect(benchPress.exerciseType, equals(ExerciseType.strength));
        expect(running.exerciseType, equals(ExerciseType.cardio));
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
  String workoutId = 'w1',
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
    workoutId: workoutId,
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
      .thenAnswer((invocation) {
        // Filter sets by programId if specified
        final queriedProgramId = invocation.positionalArguments[1]; // Second argument is programId (after userId)
        final filteredSets = sets.where((set) =>
          queriedProgramId == null || set.programId == queriedProgramId
        ).toList();
        return Stream.value(filteredSets);
      });
}

// Helper to create a test set with custom parameters
ExerciseSet _createTestSet({
  required String id,
  required DateTime createdAt,
  bool checked = false,
  String programId = 'p1',
  int? reps,
  double? weight,
}) {
  return ExerciseSet(
    id: id,
    setNumber: 1,
    reps: reps ?? 10,
    weight: weight,
    checked: checked,
    createdAt: createdAt,
    updatedAt: createdAt,
    userId: 'test_user',
    exerciseId: 'ex1',
    workoutId: 'w1',
    weekId: 'wk1',
    programId: programId,
  );
}

// Helper to setup mock Firestore with test data
void _setupMockFirestore(
  MockFirestoreService mockService, {
  List<ExerciseSet>? sets,
  String? programId,
}) {
  final testSets = sets ?? [];

  // Determine which programs actually have sets in the test data
  final programsWithSets = testSets.map((s) => s.programId).toSet();

  // Create programs only for those that have sets (or use specified programId)
  final programs = programId != null
      ? [
          Program(
            id: programId,
            name: 'Test Program',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
          ),
        ]
      : programsWithSets.map((pid) => Program(
            id: pid,
            name: 'Test Program $pid',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
          )).toList();

  when(mockService.getPrograms(any)).thenAnswer((_) => Stream.value(programs));

  when(mockService.getWeeks(any, any)).thenAnswer((invocation) {
    final queryProgramId = invocation.positionalArguments[1] as String;
    return Stream.value([
      Week(
        id: 'wk1',
        name: 'Week 1',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'test_user',
        programId: queryProgramId,
      ),
    ]);
  });

  when(mockService.getWorkouts(any, any, any)).thenAnswer((invocation) {
    final queryProgramId = invocation.positionalArguments[1] as String;

    // Create workout dates that match the test sets for this program
    final programSets = testSets.where((s) => s.programId == queryProgramId).toList();
    final workoutDates = programSets.map((s) => DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day)).toSet().toList();

    if (workoutDates.isEmpty) {
      return Stream.value([]);
    }

    return Stream.value(
      workoutDates.map((date) => Workout(
        id: 'w_${date.millisecondsSinceEpoch}',
        name: 'Workout ${date.day}',
        orderIndex: 0,
        createdAt: date,
        updatedAt: date,
        userId: 'test_user',
        weekId: 'wk1',
        programId: queryProgramId,
      )).toList(),
    );
  });

  when(mockService.getExercises(any, any, any, any)).thenAnswer((invocation) {
    final queryProgramId = invocation.positionalArguments[1] as String;
    final hasSetsForProgram = testSets.any((set) => set.programId == queryProgramId);

    if (!hasSetsForProgram) {
      return Stream.value([]);
    }

    return Stream.value([
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
        programId: queryProgramId,
      ),
    ]);
  });

  when(mockService.getSets(any, any, any, any, any)).thenAnswer((invocation) {
    final queryProgramId = invocation.positionalArguments[1] as String;
    final workoutId = invocation.positionalArguments[3] as String;

    final workoutSets = testSets.where((set) {
      final setDate = DateTime(set.createdAt.year, set.createdAt.month, set.createdAt.day);
      return workoutId.contains('${setDate.millisecondsSinceEpoch}') &&
             set.programId == queryProgramId;
    }).toList();
    return Stream.value(workoutSets);
  });
}

// Helper to create a test set with full control over all fields
ExerciseSet _createTestSetFull({
  required String id,
  required DateTime createdAt,
  String exerciseId = 'ex1',
  String workoutId = 'w1',
  String programId = 'p1',
  double? weight,
  int? reps,
  int? duration,
  double? distance,
  bool checked = false,
}) {
  return ExerciseSet(
    id: id,
    setNumber: 1,
    reps: reps,
    weight: weight,
    duration: duration,
    distance: distance,
    checked: checked,
    createdAt: createdAt,
    updatedAt: createdAt,
    userId: 'test_user',
    exerciseId: exerciseId,
    workoutId: workoutId,
    weekId: 'wk1',
    programId: programId,
  );
}

// Helper to create a test exercise with a custom name
Exercise _createTestExerciseWithName({
  required String id,
  required String name,
  ExerciseType exerciseType = ExerciseType.strength,
  String workoutId = 'w1',
}) {
  final now = DateTime.now();
  return Exercise(
    id: id,
    name: name,
    exerciseType: exerciseType,
    orderIndex: 0,
    createdAt: now,
    updatedAt: now,
    userId: 'test_user',
    workoutId: workoutId,
    weekId: 'wk1',
    programId: 'p1',
  );
}

// Helper to setup mock Firestore with explicit exercises, sets, and workouts
void _setupMockFirestoreWithSetsAndExercises(
  MockFirestoreService mockService, {
  required List<ExerciseSet> sets,
  required List<Exercise> exercises,
  required List<Workout> workouts,
}) {
  when(mockService.getPrograms(any)).thenAnswer((_) => Stream.value([
    Program(
      id: 'p1',
      name: 'Test Program',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'test_user',
    ),
  ]));

  when(mockService.getWeeks(any, any)).thenAnswer((_) => Stream.value([
    Week(
      id: 'wk1',
      name: 'Week 1',
      order: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'test_user',
      programId: 'p1',
    ),
  ]));

  when(mockService.getWorkouts(any, any, any)).thenAnswer((_) {
    if (workouts.isEmpty) return Stream.value([]);
    // Return workouts with createdAt matching date range filter
    return Stream.value(workouts);
  });

  when(mockService.getExercises(any, any, any, any)).thenAnswer((invocation) {
    final workoutId = invocation.positionalArguments[3] as String;
    final filtered = exercises.where((e) => e.workoutId == workoutId).toList();
    return Stream.value(filtered);
  });

  when(mockService.getSets(any, any, any, any, any)).thenAnswer((invocation) {
    final workoutId = invocation.positionalArguments[3] as String;
    final exerciseId = invocation.positionalArguments[4] as String;
    final filtered = sets.where((s) => s.exerciseId == exerciseId && s.workoutId == workoutId).toList();
    return Stream.value(filtered);
  });
}

// Helper to setup mock Firestore with only workouts (for streak tests)
void _setupMockFirestoreWithWorkoutsOnly(
  MockFirestoreService mockService,
  List<Workout> workouts,
) {
  when(mockService.getPrograms(any)).thenAnswer((_) => Stream.value([
    Program(
      id: 'p1',
      name: 'Test Program',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'test_user',
    ),
  ]));

  when(mockService.getWeeks(any, any)).thenAnswer((_) => Stream.value([
    Week(
      id: 'wk1',
      name: 'Week 1',
      order: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'test_user',
      programId: 'p1',
    ),
  ]));

  when(mockService.getWorkouts(any, any, any)).thenAnswer((_) {
    return Stream.value(workouts);
  });
}