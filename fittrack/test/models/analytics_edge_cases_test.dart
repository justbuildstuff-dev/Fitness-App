import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/workout.dart';

void main() {
  setUpAll(() async {
    // No Firebase initialization needed for fake firestore
  });

  group('Analytics Edge Cases & Performance', () {
    group('Large Dataset Handling', () {
      test('handles large number of workouts efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Create 1000 workouts
        final workouts = List.generate(1000, (index) => Workout(
          id: 'workout_$index',
          name: 'Workout $index',
          orderIndex: index,
          createdAt: DateTime.now().subtract(Duration(days: index % 365)),
          updatedAt: DateTime.now().subtract(Duration(days: index % 365)),
          userId: 'test_user',
          weekId: 'week_${index % 10}',
          programId: 'program_${index % 5}',
        ));

        // Create corresponding exercises and sets
        final exercises = <Exercise>[];
        final sets = <ExerciseSet>[];
        
        for (int i = 0; i < 1000; i++) {
          exercises.add(Exercise(
            id: 'exercise_$i',
            name: 'Exercise $i',
            exerciseType: ExerciseType.values[i % ExerciseType.values.length],
            orderIndex: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            workoutId: 'workout_$i',
            weekId: 'week_${i % 10}',
            programId: 'program_${i % 5}',
          ));

          // Add 3 sets per exercise
          for (int j = 0; j < 3; j++) {
            sets.add(ExerciseSet(
              id: 'set_${i}_$j',
              setNumber: j + 1,
              reps: 8 + j,
              weight: 50.0 + i,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userId: 'test_user',
              exerciseId: 'exercise_$i',
              workoutId: 'workout_$i',
              weekId: 'week_${i % 10}',
              programId: 'program_${i % 5}',
            ));
          }
        }

        // Compute analytics
        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime.now().subtract(const Duration(days: 365)),
          endDate: DateTime.now(),
          workouts: workouts,
          exercises: exercises,
          sets: sets,
        );

        stopwatch.stop();
        
        // Verify results
        expect(analytics.totalWorkouts, equals(1000));
        expect(analytics.totalSets, equals(3000));
        expect(analytics.totalVolume, greaterThan(0));
        
        // Performance check - should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second
        
        print('Large dataset processing took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('handles large heatmap data efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Create workouts for entire year with varying frequencies
        final workouts = <Workout>[];
        final startDate = DateTime(2024, 1, 1);
        
        for (int day = 0; day < 365; day++) {
          final date = startDate.add(Duration(days: day));
          final workoutsPerDay = (day % 7 == 0 || day % 7 == 1) ? 0 : (day % 3 + 1);
          
          for (int w = 0; w < workoutsPerDay; w++) {
            workouts.add(Workout(
              id: 'workout_${day}_$w',
              name: 'Workout $day-$w',
              orderIndex: w,
              createdAt: date.add(Duration(hours: w)),
              updatedAt: date.add(Duration(hours: w)),
              userId: 'test_user',
              weekId: 'week_${day ~/ 7}',
              programId: 'program_1',
            ));
          }
        }

        // Generate heatmap data
        final heatmapData = ActivityHeatmapData.fromWorkouts(
          userId: 'test_user',
          year: 2024,
          workouts: workouts,
        );

        stopwatch.stop();
        
        // Verify results
        expect(heatmapData.year, equals(2024));
        expect(heatmapData.totalWorkouts, equals(workouts.length));
        expect(heatmapData.dailyWorkoutCounts.length, greaterThan(200)); // Should have many days with workouts
        
        // Generate all heatmap days (366 for leap year)
        final heatmapDays = heatmapData.getHeatmapDays();
        expect(heatmapDays.length, equals(366));
        
        // Performance check
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        
        print('Heatmap generation took: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Edge Case Data Handling', () {
      test('handles workouts with missing data', () {
        final workouts = [
          Workout(
            id: '1',
            name: '',
            orderIndex: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final exercises = [
          Exercise(
            id: '1',
            name: '',
            exerciseType: ExerciseType.custom,
            orderIndex: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            workoutId: '1',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final sets = [
          ExerciseSet(
            id: '1',
            setNumber: 1,
            // Missing reps, weight, duration, etc.
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            exerciseId: '1',
            workoutId: '1',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          workouts: workouts,
          exercises: exercises,
          sets: sets,
        );

        // Should handle gracefully without throwing
        expect(analytics.totalWorkouts, equals(1));
        expect(analytics.totalSets, equals(1));
        expect(analytics.totalVolume, equals(0.0));
        expect(analytics.averageWorkoutDuration, equals(0.0));
      });

      test('handles extreme date ranges', () {
        final now = DateTime.now();
        
        // Very long date range
        final analytics1 = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime(1900, 1, 1),
          endDate: DateTime(2100, 12, 31),
          workouts: [],
          exercises: [],
          sets: [],
        );
        
        expect(analytics1.totalWorkouts, equals(0));
        
        // Very short date range (same day)
        final analytics2 = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          workouts: [],
          exercises: [],
          sets: [],
        );
        
        expect(analytics2.totalWorkouts, equals(0));
        
        // Future date range
        final analytics3 = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: now.add(const Duration(days: 30)),
          endDate: now.add(const Duration(days: 60)),
          workouts: [],
          exercises: [],
          sets: [],
        );
        
        expect(analytics3.totalWorkouts, equals(0));
      });

      test('handles leap year correctly in heatmap', () {
        // Test leap year (2024)
        final heatmapData2024 = ActivityHeatmapData.fromWorkouts(
          userId: 'test_user',
          year: 2024,
          workouts: [],
        );
        
        final days2024 = heatmapData2024.getHeatmapDays();
        expect(days2024.length, equals(366)); // Leap year has 366 days
        
        // Test non-leap year (2023)
        final heatmapData2023 = ActivityHeatmapData.fromWorkouts(
          userId: 'test_user',
          year: 2023,
          workouts: [],
        );
        
        final days2023 = heatmapData2023.getHeatmapDays();
        expect(days2023.length, equals(365)); // Non-leap year has 365 days
        
        // Verify February 29th handling
        final feb29_2024 = days2024.firstWhere(
          (day) => day.date.month == 2 && day.date.day == 29,
        );
        expect(feb29_2024.date.year, equals(2024));
        
        // Verify no February 29th in non-leap year
        final feb29Count = days2023.where(
          (day) => day.date.month == 2 && day.date.day == 29,
        ).length;
        expect(feb29Count, equals(0));
      });

      test('handles extreme workout volumes', () {
        final sets = [
          // Very heavy set
          ExerciseSet(
            id: '1',
            setNumber: 1,
            reps: 1,
            weight: 1000.0, // 1000kg
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            exerciseId: '1',
            workoutId: '1',
            weekId: 'week1',
            programId: 'prog1',
          ),
          // Very light set with many reps
          ExerciseSet(
            id: '2',
            setNumber: 1,
            reps: 1000,
            weight: 0.5, // 0.5kg
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            exerciseId: '2',
            workoutId: '2',
            weekId: 'week1',
            programId: 'prog1',
          ),
          // Zero values
          ExerciseSet(
            id: '3',
            setNumber: 1,
            reps: 0,
            weight: 0.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'test_user',
            exerciseId: '3',
            workoutId: '3',
            weekId: 'week1',
            programId: 'prog1',
          ),
        ];

        final analytics = WorkoutAnalytics.fromWorkoutData(
          userId: 'test_user',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          workouts: [],
          exercises: [],
          sets: sets,
        );

        expect(analytics.totalSets, equals(3));
        expect(analytics.totalVolume, equals(1500.0)); // 1000*1 + 0.5*1000 + 0*0
      });
    });

    group('Personal Records Edge Cases', () {
      test('handles identical values correctly', () {
        final pr1 = PersonalRecord(
          id: 'pr1',
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          prType: PRType.maxWeight,
          value: 100.0,
          previousValue: 100.0, // Same value
          achievedAt: DateTime.now(),
          workoutId: 'w1',
          setId: 's1',
        );

        expect(pr1.improvement, equals(0.0));
        expect(pr1.improvementString, equals('0'));
      });

      test('handles negative improvements correctly', () {
        final pr = PersonalRecord(
          id: 'pr1',
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          prType: PRType.maxWeight,
          value: 95.0,
          previousValue: 100.0, // Went down
          achievedAt: DateTime.now(),
          workoutId: 'w1',
          setId: 's1',
        );

        expect(pr.improvement, equals(-5.0));
        expect(pr.improvementString, equals('-5'));
      });

      test('handles all PR types display values', () {
        final prTypes = [
          (PRType.maxWeight, 100.0, '100kg'),
          (PRType.maxReps, 12.0, '12 reps'),
          (PRType.maxDuration, 1800.0, '30m 0s'),
          (PRType.maxDuration, 90.0, '90s'),
          (PRType.maxDistance, 5000.0, '5.00km'),
          (PRType.maxDistance, 800.0, '800m'),
          (PRType.maxVolume, 1200.0, '1200 vol'),
          (PRType.oneRepMax, 120.0, '120kg (1RM)'),
        ];

        for (final (prType, value, expectedDisplay) in prTypes) {
          final pr = PersonalRecord(
            id: 'pr1',
            userId: 'test_user',
            exerciseId: 'ex1',
            exerciseName: 'Test Exercise',
            exerciseType: ExerciseType.strength,
            prType: prType,
            value: value,
            previousValue: null,
            achievedAt: DateTime.now(),
            workoutId: 'w1',
            setId: 's1',
          );

          expect(pr.displayValue, equals(expectedDisplay));
        }
      });
    });

    group('DateRange Edge Cases', () {
      test('handles invalid date ranges gracefully', () {
        // End date before start date
        final invalidRange = DateRange(
          start: DateTime(2024, 12, 31),
          end: DateTime(2024, 1, 1),
        );

        expect(invalidRange.durationInDays, lessThan(0));
        
        // Very small range
        final tinyRange = DateRange(
          start: DateTime(2024, 1, 1, 12, 0, 0),
          end: DateTime(2024, 1, 1, 12, 0, 1),
        );
        
        expect(tinyRange.durationInDays, equals(1)); // Should be at least 1
      });

      test('contains method handles edge cases', () {
        final range = DateRange(
          start: DateTime(2024, 1, 1, 0, 0, 0),
          end: DateTime(2024, 1, 1, 23, 59, 59),
        );

        // Exact boundary cases
        expect(range.contains(DateTime(2024, 1, 1, 0, 0, 0)), isTrue);
        expect(range.contains(DateTime(2024, 1, 1, 23, 59, 59)), isTrue);
        expect(range.contains(DateTime(2023, 12, 31, 23, 59, 59)), isFalse);
        expect(range.contains(DateTime(2024, 1, 2, 0, 0, 0)), isFalse);
      });

      test('factory methods create valid ranges', () {
        final thisWeek = DateRange.thisWeek();
        final thisMonth = DateRange.thisMonth();
        final thisYear = DateRange.thisYear();
        final last30Days = DateRange.last30Days();

        // All ranges should have end after start
        expect(thisWeek.end.isAfter(thisWeek.start), isTrue);
        expect(thisMonth.end.isAfter(thisMonth.start), isTrue);
        expect(thisYear.end.isAfter(thisYear.start), isTrue);
        expect(last30Days.end.isAfter(last30Days.start), isTrue);

        // Check durations are reasonable
        expect(thisWeek.durationInDays, equals(7));
        expect(last30Days.durationInDays, equals(30));
        expect(thisYear.durationInDays, greaterThan(360));
        expect(thisMonth.durationInDays, greaterThan(25));
      });
    });

    group('Memory and Performance Tests', () {
      test('heatmap intensity calculation is efficient', () {
        final stopwatch = Stopwatch()..start();
        
        final heatmapData = ActivityHeatmapData(
          userId: 'test_user',
          year: 2024,
          dailyWorkoutCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalWorkouts: 0,
        );

        // Test intensity calculation for many dates
        for (int day = 1; day <= 366; day++) {
          final date = DateTime(2024, 1, 1).add(Duration(days: day - 1));
          final intensity = heatmapData.getIntensityForDate(date);
          expect(intensity, equals(HeatmapIntensity.none));
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        
        print('Intensity calculations took: ${stopwatch.elapsedMilliseconds}ms');
      });

      test('analytics computation scales linearly', () {
        // Test with different dataset sizes to ensure linear scaling
        final sizes = [10, 100, 500];
        final times = <int>[];

        for (final size in sizes) {
          final stopwatch = Stopwatch()..start();
          
          final workouts = List.generate(size, (i) => Workout(
            id: 'w$i',
            name: 'Workout $i',
            orderIndex: i,
            createdAt: DateTime.now().subtract(Duration(days: i)),
            updatedAt: DateTime.now().subtract(Duration(days: i)),
            userId: 'test_user',
            weekId: 'week1',
            programId: 'prog1',
          ));

          final analytics = WorkoutAnalytics.fromWorkoutData(
            userId: 'test_user',
            startDate: DateTime.now().subtract(const Duration(days: 365)),
            endDate: DateTime.now(),
            workouts: workouts,
            exercises: [],
            sets: [],
          );

          expect(analytics.totalWorkouts, equals(size));
          
          stopwatch.stop();
          times.add(stopwatch.elapsedMilliseconds);
          
          print('Size $size took: ${stopwatch.elapsedMilliseconds}ms');
        }

        // Verify roughly linear scaling (allow for some variation)
        expect(times[1], lessThan(times[0] * 15)); // 100x data shouldn't take 100x time
        expect(times[2], lessThan(times[1] * 10)); // 5x data shouldn't take 10x time
      });
    });
  });
}