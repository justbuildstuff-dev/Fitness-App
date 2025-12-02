import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/workout.dart';

void main() {
  group('Analytics Models', () {
    final now = DateTime.now();
    
    group('WorkoutAnalytics', () {
      test('computes analytics from workout data correctly', () {
        // Create test data
        final workouts = [
          Workout(
            id: '1',
            name: 'Chest Day',
            orderIndex: 0,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(days: 1)),
            userId: 'user123',
            weekId: 'week1',
            programId: 'prog1',
          ),
          Workout(
            id: '2',
            name: 'Back Day',
            orderIndex: 1,
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(days: 2)),
            userId: 'user123',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final exercises = [
          Exercise(
            id: '1',
            name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            createdAt: now,
            updatedAt: now,
            userId: 'user123',
            workoutId: '1',
            weekId: 'week1',
            programId: 'prog1',
          ),
          Exercise(
            id: '2',
            name: 'Pull-ups',
            exerciseType: ExerciseType.bodyweight,
            orderIndex: 0,
            createdAt: now,
            updatedAt: now,
            userId: 'user123',
            workoutId: '2',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final sets = [
          ExerciseSet(
            id: '1',
            setNumber: 1,
            reps: 10,
            weight: 100.0,
            createdAt: now,
            updatedAt: now,
            userId: 'user123',
            exerciseId: '1',
            workoutId: '1',
            weekId: 'week1',
            programId: 'prog1',
          ),
          ExerciseSet(
            id: '2',
            setNumber: 1,
            reps: 8,
            createdAt: now,
            updatedAt: now,
            userId: 'user123',
            exerciseId: '2',
            workoutId: '2',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'user123',
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now,
          workouts: workouts,
          exercises: exercises,
          sets: sets,
        );

        expect(analytics.totalWorkouts, equals(2));
        expect(analytics.totalSets, equals(2));
        expect(analytics.totalVolume, equals(1000.0)); // 100kg * 10 reps
        expect(analytics.exerciseTypeBreakdown[ExerciseType.strength], equals(1));
        expect(analytics.exerciseTypeBreakdown[ExerciseType.bodyweight], equals(1));
        expect(analytics.mostUsedExerciseType, isNotNull);
      });
    });

    group('ActivityHeatmapData', () {
      test('computes heatmap data from workouts', () {
        final workouts = [
          Workout(
            id: '1',
            name: 'Workout 1',
            orderIndex: 0,
            createdAt: DateTime(2024, 1, 15),
            updatedAt: DateTime(2024, 1, 15),
            userId: 'user123',
            weekId: 'week1',
            programId: 'prog1',
          ),
          Workout(
            id: '2',
            name: 'Workout 2',
            orderIndex: 1,
            createdAt: DateTime(2024, 1, 15), // Same day
            updatedAt: DateTime(2024, 1, 15),
            userId: 'user123',
            weekId: 'week1',
            programId: 'prog1',
          ),
          Workout(
            id: '3',
            name: 'Workout 3',
            orderIndex: 2,
            createdAt: DateTime(2024, 1, 16),
            updatedAt: DateTime(2024, 1, 16),
            userId: 'user123',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final heatmapData = ActivityHeatmapData.fromWorkouts(
          userId: 'user123',
          year: 2024,
          workouts: workouts,
        );

        expect(heatmapData.year, equals(2024));
        expect(heatmapData.totalSets, greaterThan(0)); // Should have sets from workouts
        expect(heatmapData.getSetCountForDate(DateTime(2024, 1, 15)), greaterThan(0));
        expect(heatmapData.getSetCountForDate(DateTime(2024, 1, 16)), greaterThan(0));
        expect(heatmapData.getSetCountForDate(DateTime(2024, 1, 17)), equals(0));

        expect(heatmapData.getIntensityForDate(DateTime(2024, 1, 15)),
               isNot(equals(HeatmapIntensity.none))); // Has sets
        expect(heatmapData.getIntensityForDate(DateTime(2024, 1, 16)),
               isNot(equals(HeatmapIntensity.none))); // Has sets
        expect(heatmapData.getIntensityForDate(DateTime(2024, 1, 17)),
               equals(HeatmapIntensity.none)); // 0 sets
      });

      test('generates heatmap days correctly', () {
        final heatmapData = ActivityHeatmapData(
          userId: 'user123',
          year: 2024,
          dailySetCounts: {
            DateTime(2024, 1, 1): 1,
            DateTime(2024, 1, 2): 2,
          },
          currentStreak: 5,
          longestStreak: 10,
          totalSets: 3,
        );

        final heatmapDays = heatmapData.getHeatmapDays();
        expect(heatmapDays.length, equals(366)); // 2024 is a leap year

        final jan1 = heatmapDays.firstWhere((day) =>
            day.date.year == 2024 && day.date.month == 1 && day.date.day == 1);
        expect(jan1.workoutCount, equals(1)); // workoutCount field now stores set count
        expect(jan1.intensity, equals(HeatmapIntensity.low));
      });
    });

    group('DateRange', () {
      test('creates date ranges correctly', () {
        final thisWeek = DateRange.thisWeek();
        final thisMonth = DateRange.thisMonth();
        final thisYear = DateRange.thisYear();
        final last30Days = DateRange.last30Days();

        expect(thisWeek.durationInDays, equals(7));
        expect(thisMonth.start.day, equals(1));
        expect(thisYear.start.month, equals(1));
        expect(thisYear.start.day, equals(1));
        expect(last30Days.durationInDays, equals(30));
      });

      test('checks if date is contained in range', () {
        final range = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31, 23, 59, 59),
        );

        expect(range.contains(DateTime(2024, 1, 15)), isTrue);
        expect(range.contains(DateTime(2024, 2, 1)), isFalse);
        expect(range.contains(DateTime(2023, 12, 31)), isFalse);
      });
    });

    group('PersonalRecord', () {
      test('calculates improvement correctly', () {
        final pr = PersonalRecord(
          id: 'pr1',
          userId: 'user123',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          prType: PRType.maxWeight,
          value: 105.0,
          previousValue: 100.0,
          achievedAt: DateTime.now(),
          workoutId: 'w1',
          setId: 's1',
        );

        expect(pr.improvement, equals(5.0));
        expect(pr.improvementString, equals('+5'));
        expect(pr.displayValue, equals('105kg'));
      });

      test('handles first PR correctly', () {
        final pr = PersonalRecord(
          id: 'pr1',
          userId: 'user123',
          exerciseId: 'ex1',
          exerciseName: 'Pull-ups',
          exerciseType: ExerciseType.bodyweight,
          prType: PRType.maxReps,
          value: 12.0,
          previousValue: null,
          achievedAt: DateTime.now(),
          workoutId: 'w1',
          setId: 's1',
        );

        expect(pr.improvement, equals(12.0));
        expect(pr.improvementString, equals('New PR!'));
        expect(pr.displayValue, equals('12 reps'));
      });
    });
  });
}