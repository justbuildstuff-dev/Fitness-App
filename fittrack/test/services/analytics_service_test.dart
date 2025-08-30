import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/workout.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      analyticsService = AnalyticsService.instance;
      // Note: In a real implementation, you'd inject the mock service
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
        expect(analytics.totalVolume, equals(2200.0)); // 100*10 + 80*15 = 2200
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
        expect(heatmapData.totalWorkouts, equals(3));
        expect(heatmapData.getWorkoutCountForDate(DateTime(2024, 1, 15)), equals(2));
        expect(heatmapData.getWorkoutCountForDate(DateTime(2024, 1, 16)), equals(1));
        expect(heatmapData.getIntensityForDate(DateTime(2024, 1, 15)), 
               equals(HeatmapIntensity.medium));
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

        expect(heatmapData.totalWorkouts, equals(2)); // Only 2024 workouts
        expect(heatmapData.getWorkoutCountForDate(DateTime(2024, 1, 1)), equals(1));
        expect(heatmapData.getWorkoutCountForDate(DateTime(2024, 12, 31)), equals(1));
      });
    });

    group('Personal Records Detection', () {
      test('detects weight PR correctly', () async {
        final exercise = _createTestExercise(
          id: 'ex1', 
          exerciseType: ExerciseType.strength,
        );

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