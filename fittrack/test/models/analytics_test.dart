import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/muscle_group.dart';
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

    group('MonthHeatmapData', () {
      test('getSetCountForDay returns correct count for existing day', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {
            1: 8,
            2: 12,
            5: 6,
            15: 20,
          },
          totalSets: 46,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getSetCountForDay(1), equals(8));
        expect(monthData.getSetCountForDay(2), equals(12));
        expect(monthData.getSetCountForDay(5), equals(6));
        expect(monthData.getSetCountForDay(15), equals(20));
      });

      test('getSetCountForDay returns 0 for day with no data', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {
            1: 8,
            2: 12,
          },
          totalSets: 20,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getSetCountForDay(3), equals(0));
        expect(monthData.getSetCountForDay(10), equals(0));
        expect(monthData.getSetCountForDay(25), equals(0));
      });

      test('getIntensityForDay returns correct intensity levels', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {
            1: 0,   // none
            2: 3,   // low (1-5)
            3: 8,   // medium (6-15)
            4: 20,  // high (16-25)
            5: 30,  // veryHigh (26+)
          },
          totalSets: 61,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getIntensityForDay(1), equals(HeatmapIntensity.none));
        expect(monthData.getIntensityForDay(2), equals(HeatmapIntensity.low));
        expect(monthData.getIntensityForDay(3), equals(HeatmapIntensity.medium));
        expect(monthData.getIntensityForDay(4), equals(HeatmapIntensity.high));
        expect(monthData.getIntensityForDay(5), equals(HeatmapIntensity.veryHigh));
      });

      test('getIntensityForDay returns none for days with no data', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {
            1: 10,
          },
          totalSets: 10,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getIntensityForDay(2), equals(HeatmapIntensity.none));
        expect(monthData.getIntensityForDay(15), equals(HeatmapIntensity.none));
      });

      test('isCacheValid returns true for recent data', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {},
          totalSets: 0,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.isCacheValid, isTrue);
      });

      test('isCacheValid returns true for data fetched 4 minutes ago', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {},
          totalSets: 0,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 4)),
        );

        expect(monthData.isCacheValid, isTrue);
      });

      test('isCacheValid returns false for data older than 5 minutes', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {},
          totalSets: 0,
          fetchedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        );

        expect(monthData.isCacheValid, isFalse);
      });

      test('handles empty dailySetCounts map', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {},
          totalSets: 0,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getSetCountForDay(1), equals(0));
        expect(monthData.getSetCountForDay(15), equals(0));
        expect(monthData.getSetCountForDay(31), equals(0));
        expect(monthData.getIntensityForDay(10), equals(HeatmapIntensity.none));
      });

      test('handles full month of data', () {
        final Map<int, int> dailySetCounts = {};
        for (int day = 1; day <= 31; day++) {
          dailySetCounts[day] = day * 2; // Increasing set counts
        }

        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: dailySetCounts,
          totalSets: dailySetCounts.values.reduce((a, b) => a + b),
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getSetCountForDay(1), equals(2));
        expect(monthData.getSetCountForDay(15), equals(30));
        expect(monthData.getSetCountForDay(31), equals(62));
        expect(monthData.getIntensityForDay(1), equals(HeatmapIntensity.low));
        expect(monthData.getIntensityForDay(15), equals(HeatmapIntensity.veryHigh));
      });

      test('handles months with varying days (28, 30, 31)', () {
        // February (28 days in non-leap year)
        final febData = MonthHeatmapData(
          year: 2023,
          month: 2,
          dailySetCounts: {
            28: 10,
          },
          totalSets: 10,
          fetchedAt: DateTime.now(),
        );

        expect(febData.getSetCountForDay(28), equals(10));
        expect(febData.getSetCountForDay(29), equals(0)); // No Feb 29 in 2023

        // April (30 days)
        final aprData = MonthHeatmapData(
          year: 2024,
          month: 4,
          dailySetCounts: {
            30: 15,
          },
          totalSets: 15,
          fetchedAt: DateTime.now(),
        );

        expect(aprData.getSetCountForDay(30), equals(15));
        expect(aprData.getSetCountForDay(31), equals(0)); // No April 31
      });

      test('intensity boundary cases', () {
        final monthData = MonthHeatmapData(
          year: 2024,
          month: 12,
          dailySetCounts: {
            1: 1,   // low boundary (1-5)
            2: 5,   // low boundary (1-5)
            3: 6,   // medium boundary (6-15)
            4: 15,  // medium boundary (6-15)
            5: 16,  // high boundary (16-25)
            6: 25,  // high boundary (16-25)
            7: 26,  // veryHigh boundary (26+)
          },
          totalSets: 94,
          fetchedAt: DateTime.now(),
        );

        expect(monthData.getIntensityForDay(1), equals(HeatmapIntensity.low));
        expect(monthData.getIntensityForDay(2), equals(HeatmapIntensity.low));
        expect(monthData.getIntensityForDay(3), equals(HeatmapIntensity.medium));
        expect(monthData.getIntensityForDay(4), equals(HeatmapIntensity.medium));
        expect(monthData.getIntensityForDay(5), equals(HeatmapIntensity.high));
        expect(monthData.getIntensityForDay(6), equals(HeatmapIntensity.high));
        expect(monthData.getIntensityForDay(7), equals(HeatmapIntensity.veryHigh));
      });
    });

    group('DateRange - new factories', () {
      test('lastMonth creates ~30 day range ending today', () {
        final range = DateRange.lastMonth();
        final now = DateTime.now();
        expect(range.end.year, equals(now.year));
        expect(range.end.month, equals(now.month));
        expect(range.end.day, equals(now.day));
        // Start should be roughly 1 month ago
        expect(range.durationInDays, greaterThanOrEqualTo(28));
        expect(range.durationInDays, lessThanOrEqualTo(32));
      });

      test('last3Months creates ~90 day range ending today', () {
        final range = DateRange.last3Months();
        final now = DateTime.now();
        expect(range.end.year, equals(now.year));
        expect(range.end.month, equals(now.month));
        expect(range.end.day, equals(now.day));
        expect(range.durationInDays, greaterThanOrEqualTo(89));
        expect(range.durationInDays, lessThanOrEqualTo(93));
      });

      test('last6Months creates ~180 day range ending today', () {
        final range = DateRange.last6Months();
        final now = DateTime.now();
        expect(range.end.year, equals(now.year));
        expect(range.end.month, equals(now.month));
        expect(range.end.day, equals(now.day));
        expect(range.durationInDays, greaterThanOrEqualTo(181));
        expect(range.durationInDays, lessThanOrEqualTo(185));
      });

      test('allTime starts from Jan 1 2020 and ends today', () {
        final range = DateRange.allTime();
        final now = DateTime.now();
        expect(range.start.year, equals(2020));
        expect(range.start.month, equals(1));
        expect(range.start.day, equals(1));
        expect(range.end.year, equals(now.year));
        expect(range.end.month, equals(now.month));
        expect(range.end.day, equals(now.day));
      });

      test('last3Months contains dates within range', () {
        final range = DateRange.last3Months();
        final now = DateTime.now();
        expect(range.contains(now), isTrue);
        expect(range.contains(now.subtract(const Duration(days: 30))), isTrue);
        expect(range.contains(now.subtract(const Duration(days: 60))), isTrue);
      });

      test('last3Months does not contain dates outside range', () {
        final range = DateRange.last3Months();
        final now = DateTime.now();
        // A date well outside 3 months ago
        expect(range.contains(now.subtract(const Duration(days: 200))), isFalse);
      });
    });

    group('ExerciseProgressPoint', () {
      test('creates with all fields', () {
        final point = ExerciseProgressPoint(
          date: DateTime(2024, 6, 15),
          workoutId: 'w1',
          maxWeight: 100.0,
          maxReps: 10,
          totalVolume: 1500.0,
          totalDuration: 300,
          totalDistance: 5000.0,
          estimated1RM: 133.3,
        );

        expect(point.date, equals(DateTime(2024, 6, 15)));
        expect(point.workoutId, equals('w1'));
        expect(point.maxWeight, equals(100.0));
        expect(point.maxReps, equals(10));
        expect(point.totalVolume, equals(1500.0));
        expect(point.totalDuration, equals(300));
        expect(point.totalDistance, equals(5000.0));
        expect(point.estimated1RM, equals(133.3));
      });

      test('creates with nullable fields as null', () {
        final point = ExerciseProgressPoint(
          date: DateTime(2024, 6, 15),
          workoutId: 'w1',
        );

        expect(point.maxWeight, isNull);
        expect(point.maxReps, isNull);
        expect(point.totalVolume, isNull);
        expect(point.totalDuration, isNull);
        expect(point.totalDistance, isNull);
        expect(point.estimated1RM, isNull);
      });

      test('equality works correctly', () {
        final point1 = ExerciseProgressPoint(
          date: DateTime(2024, 6, 15),
          workoutId: 'w1',
          maxWeight: 100.0,
        );
        final point2 = ExerciseProgressPoint(
          date: DateTime(2024, 6, 15),
          workoutId: 'w1',
          maxWeight: 100.0,
        );
        final point3 = ExerciseProgressPoint(
          date: DateTime(2024, 6, 16),
          workoutId: 'w1',
          maxWeight: 100.0,
        );

        expect(point1, equals(point2));
        expect(point1, isNot(equals(point3)));
      });
    });

    group('ExerciseProgressData', () {
      test('creates with data points', () {
        final data = ExerciseProgressData(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dataPoints: [
            ExerciseProgressPoint(
              date: DateTime(2024, 6, 1),
              workoutId: 'w1',
              maxWeight: 80.0,
            ),
            ExerciseProgressPoint(
              date: DateTime(2024, 6, 8),
              workoutId: 'w2',
              maxWeight: 85.0,
            ),
          ],
          dateRange: DateRange(
            start: DateTime(2024, 6, 1),
            end: DateTime(2024, 6, 30),
          ),
        );

        expect(data.exerciseId, equals('ex1'));
        expect(data.exerciseName, equals('Bench Press'));
        expect(data.exerciseType, equals(ExerciseType.strength));
        expect(data.dataPoints.length, equals(2));
        expect(data.isEmpty, isFalse);
        expect(data.isSinglePoint, isFalse);
      });

      test('isEmpty returns true for empty data points', () {
        final data = ExerciseProgressData(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dataPoints: [],
          dateRange: DateRange(
            start: DateTime(2024, 6, 1),
            end: DateTime(2024, 6, 30),
          ),
        );

        expect(data.isEmpty, isTrue);
        expect(data.isSinglePoint, isFalse);
      });

      test('isSinglePoint returns true for exactly one data point', () {
        final data = ExerciseProgressData(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dataPoints: [
            ExerciseProgressPoint(
              date: DateTime(2024, 6, 1),
              workoutId: 'w1',
              maxWeight: 80.0,
            ),
          ],
          dateRange: DateRange(
            start: DateTime(2024, 6, 1),
            end: DateTime(2024, 6, 30),
          ),
        );

        expect(data.isEmpty, isFalse);
        expect(data.isSinglePoint, isTrue);
      });
    });

    group('MuscleGroupVolume', () {
      test('creates with muscle group', () {
        final volume = MuscleGroupVolume(
          muscleGroup: MuscleGroup.chest,
          label: 'Chest',
          totalSets: 45,
          percentage: 25.0,
        );

        expect(volume.muscleGroup, equals(MuscleGroup.chest));
        expect(volume.label, equals('Chest'));
        expect(volume.totalSets, equals(45));
        expect(volume.percentage, equals(25.0));
      });

      test('creates Other category with null muscle group', () {
        final volume = MuscleGroupVolume(
          muscleGroup: null,
          label: 'Other',
          totalSets: 10,
          percentage: 5.5,
        );

        expect(volume.muscleGroup, isNull);
        expect(volume.label, equals('Other'));
      });

      test('equality works correctly', () {
        final v1 = MuscleGroupVolume(
          muscleGroup: MuscleGroup.back,
          label: 'Back',
          totalSets: 30,
          percentage: 20.0,
        );
        final v2 = MuscleGroupVolume(
          muscleGroup: MuscleGroup.back,
          label: 'Back',
          totalSets: 30,
          percentage: 20.0,
        );

        expect(v1, equals(v2));
      });
    });

    group('WeeklyTrendPoint', () {
      test('creates with correct fields', () {
        final monday = DateTime(2024, 6, 10); // A Monday
        final point = WeeklyTrendPoint(
          weekStart: monday,
          totalVolume: 15000.0,
          workoutCount: 4,
        );

        expect(point.weekStart, equals(monday));
        expect(point.totalVolume, equals(15000.0));
        expect(point.workoutCount, equals(4));
      });

      test('weekEnd returns correct Sunday', () {
        final monday = DateTime(2024, 6, 10);
        final point = WeeklyTrendPoint(
          weekStart: monday,
          totalVolume: 0,
          workoutCount: 0,
        );

        expect(point.weekEnd, equals(DateTime(2024, 6, 16)));
      });

      test('weekRangeString formats correctly', () {
        final point = WeeklyTrendPoint(
          weekStart: DateTime(2024, 6, 10),
          totalVolume: 0,
          workoutCount: 0,
        );

        expect(point.weekRangeString, equals('Jun 10 - Jun 16'));
      });

      test('weekRangeString handles month boundary', () {
        final point = WeeklyTrendPoint(
          weekStart: DateTime(2024, 6, 27),
          totalVolume: 0,
          workoutCount: 0,
        );

        // June 27 (Thu) + 6 days = July 3
        expect(point.weekRangeString, equals('Jun 27 - Jul 3'));
      });

      test('equality works correctly', () {
        final p1 = WeeklyTrendPoint(
          weekStart: DateTime(2024, 6, 10),
          totalVolume: 15000.0,
          workoutCount: 4,
        );
        final p2 = WeeklyTrendPoint(
          weekStart: DateTime(2024, 6, 10),
          totalVolume: 15000.0,
          workoutCount: 4,
        );

        expect(p1, equals(p2));
      });
    });

    group('ConfigurableStreak', () {
      test('creates with correct fields', () {
        final streak = ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 12,
          longestStreak: 15,
        );

        expect(streak.weeklyTarget, equals(3));
        expect(streak.currentStreak, equals(12));
        expect(streak.longestStreak, equals(15));
      });

      test('currentStreakString formats correctly', () {
        expect(
          ConfigurableStreak(weeklyTarget: 3, currentStreak: 0, longestStreak: 0)
              .currentStreakString,
          equals('No streak'),
        );
        expect(
          ConfigurableStreak(weeklyTarget: 3, currentStreak: 1, longestStreak: 1)
              .currentStreakString,
          equals('1-week streak'),
        );
        expect(
          ConfigurableStreak(weeklyTarget: 3, currentStreak: 12, longestStreak: 15)
              .currentStreakString,
          equals('12-week streak'),
        );
      });

      test('longestStreakString formats correctly', () {
        expect(
          ConfigurableStreak(weeklyTarget: 3, currentStreak: 0, longestStreak: 0)
              .longestStreakString,
          equals('No record'),
        );
        expect(
          ConfigurableStreak(weeklyTarget: 3, currentStreak: 0, longestStreak: 1)
              .longestStreakString,
          equals('1 week'),
        );
        expect(
          ConfigurableStreak(weeklyTarget: 3, currentStreak: 5, longestStreak: 15)
              .longestStreakString,
          equals('15 weeks'),
        );
      });

      test('equality works correctly', () {
        final s1 = ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 5,
          longestStreak: 10,
        );
        final s2 = ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 5,
          longestStreak: 10,
        );
        final s3 = ConfigurableStreak(
          weeklyTarget: 4,
          currentStreak: 5,
          longestStreak: 10,
        );

        expect(s1, equals(s2));
        expect(s1, isNot(equals(s3)));
      });
    });
  });
}