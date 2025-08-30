/// Test Configuration for FitTrack Application
/// 
/// This file contains centralized configuration for all testing in the FitTrack
/// application, including test data generation, performance benchmarks, and
/// common utilities used across different test categories.

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/program.dart';

/// Centralized configuration constants for testing
class TestConfig {
  // Test user configurations
  static const String testUserId = 'fittrack_test_user_12345';
  static const String testProgramId = 'test_program_12345';
  static const String testWeekId = 'test_week_12345';
  static const String testWorkoutId = 'test_workout_12345';
  static const String testExerciseId = 'test_exercise_12345';
  
  // Performance benchmarks (in milliseconds)
  static const int standardPerformanceThreshold = 100;
  static const int complexOperationThreshold = 500;
  static const int largeDatasetThreshold = 1000;
  static const int uiRenderingThreshold = 16; // 60 FPS target
  
  // Test data sizes
  static const int smallDatasetSize = 10;
  static const int mediumDatasetSize = 100;
  static const int largeDatasetSize = 1000;
  static const int performanceDatasetSize = 10000;
  
  // Date ranges for testing
  static DateTime get testStartDate => DateTime(2024, 1, 1);
  static DateTime get testEndDate => DateTime(2024, 12, 31);
  static Duration get testDateRange => testEndDate.difference(testStartDate);
  
  /// Creates a standardized test date range for analytics testing
  static DateRange createTestDateRange({int days = 365}) {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(Duration(days: days)),
      end: now,
    );
  }
  
  /// Validates that a test completed within performance thresholds
  static void validatePerformance(Stopwatch stopwatch, String testName, {int? customThreshold}) {
    final threshold = customThreshold ?? standardPerformanceThreshold;
    final elapsed = stopwatch.elapsedMilliseconds;
    expect(elapsed, lessThan(threshold),
        reason: '$testName took ${elapsed}ms (expected < ${threshold}ms)');
  }
  
  /// Creates consistent test dates for reproducible testing
  static DateTime createTestDate({int daysFromNow = 0}) {
    return DateTime.now().add(Duration(days: daysFromNow));
  }
}

/// Test data generators for consistent mock data across tests
class TestDataGenerator {
  /// Generates a test program with predictable data
  static Program createTestProgram({
    String? id,
    String? name,
    String? userId,
    int? duration,
  }) {
    return Program(
      id: id ?? TestConfig.testProgramId,
      name: name ?? 'Test Program',
      userId: userId ?? TestConfig.testUserId,
      createdAt: TestConfig.createTestDate(),
      updatedAt: TestConfig.createTestDate(),
    );
  }
  
  /// Generates a test week with predictable data
  static Week createTestWeek({
    String? id,
    String? name,
    String? programId,
    String? userId,
    int? orderIndex,
  }) {
    return Week(
      id: id ?? TestConfig.testWeekId,
      name: name ?? 'Test Week',
      programId: programId ?? TestConfig.testProgramId,
      userId: userId ?? TestConfig.testUserId,
      order: orderIndex ?? 0,
      createdAt: TestConfig.createTestDate(),
      updatedAt: TestConfig.createTestDate(),
    );
  }
  
  /// Generates a test workout with predictable data
  static Workout createTestWorkout({
    String? id,
    String? name,
    String? weekId,
    String? programId,
    String? userId,
    int? orderIndex,
  }) {
    return Workout(
      id: id ?? TestConfig.testWorkoutId,
      name: name ?? 'Test Workout',
      weekId: weekId ?? TestConfig.testWeekId,
      programId: programId ?? TestConfig.testProgramId,
      userId: userId ?? TestConfig.testUserId,
      orderIndex: orderIndex ?? 0,
      createdAt: TestConfig.createTestDate(),
      updatedAt: TestConfig.createTestDate(),
    );
  }
  
  /// Generates a test exercise with predictable data
  static Exercise createTestExercise({
    String? id,
    String? name,
    ExerciseType? exerciseType,
    String? workoutId,
    String? weekId,
    String? programId,
    String? userId,
    int? orderIndex,
  }) {
    return Exercise(
      id: id ?? TestConfig.testExerciseId,
      name: name ?? 'Test Exercise',
      exerciseType: exerciseType ?? ExerciseType.strength,
      workoutId: workoutId ?? TestConfig.testWorkoutId,
      weekId: weekId ?? TestConfig.testWeekId,
      programId: programId ?? TestConfig.testProgramId,
      userId: userId ?? TestConfig.testUserId,
      orderIndex: orderIndex ?? 0,
      createdAt: TestConfig.createTestDate(),
      updatedAt: TestConfig.createTestDate(),
    );
  }
  
  /// Generates a test exercise set with predictable data
  static ExerciseSet createTestSet({
    String? id,
    String? exerciseId,
    String? workoutId,
    String? weekId,
    String? programId,
    String? userId,
    int? reps,
    double? weight,
    int? orderIndex,
    bool? checked,
  }) {
    return ExerciseSet(
      id: id ?? 'test_set_12345',
      exerciseId: exerciseId ?? TestConfig.testExerciseId,
      workoutId: workoutId ?? TestConfig.testWorkoutId,
      weekId: weekId ?? TestConfig.testWeekId,
      programId: programId ?? TestConfig.testProgramId,
      userId: userId ?? TestConfig.testUserId,
      reps: reps ?? 10,
      weight: weight ?? 135.0,
      setNumber: orderIndex ?? 0,
      checked: checked ?? false,
      createdAt: TestConfig.createTestDate(),
      updatedAt: TestConfig.createTestDate(),
    );
  }
  
  /// Generates multiple test workouts for analytics testing
  static List<Workout> createTestWorkouts(int count) {
    return List.generate(count, (index) {
      return createTestWorkout(
        id: 'test_workout_$index',
        name: 'Test Workout ${index + 1}',
        orderIndex: index,
      );
    });
  }
  
  /// Generates multiple test exercises for performance testing
  static List<Exercise> createTestExercises(int count, {ExerciseType? exerciseType}) {
    return List.generate(count, (index) {
      return createTestExercise(
        id: 'test_exercise_$index',
        name: 'Test Exercise ${index + 1}',
        exerciseType: exerciseType ?? ExerciseType.strength,
        orderIndex: index,
      );
    });
  }
  
  /// Generates multiple test sets for volume calculations
  static List<ExerciseSet> createTestSets(int count, {String? exerciseId}) {
    return List.generate(count, (index) {
      return createTestSet(
        id: 'test_set_$index',
        exerciseId: exerciseId,
        reps: 10 + (index % 5), // Vary reps: 10-14
        weight: 135.0 + (index * 2.5), // Progressive weight
        orderIndex: index,
        checked: index.isEven, // Alternate checked status
      );
    });
  }
}

/// Custom matchers for FitTrack testing
class FitTrackMatchers {
  /// Matcher for validating personal record improvements
  static Matcher isValidPRImprovement() {
    return predicate<PersonalRecord>((pr) {
      return pr.improvement >= 0 || pr.previousValue != null;
    }, 'is a valid personal record improvement');
  }
  
  /// Matcher for validating heatmap intensity consistency  
  static Matcher hasConsistentIntensity() {
    return predicate<HeatmapDay>((day) {
      switch (day.intensity) {
        case HeatmapIntensity.none:
          return day.workoutCount == 0;
        case HeatmapIntensity.low:
          return day.workoutCount == 1;
        case HeatmapIntensity.medium:
          return day.workoutCount >= 2 && day.workoutCount <= 3;
        case HeatmapIntensity.high:
          return day.workoutCount >= 4;
      }
    }, 'has intensity consistent with workout count');
  }
  
  /// Matcher for validating complete analytics data
  static Matcher isCompleteAnalytics() {
    return predicate<WorkoutAnalytics>((analytics) {
      return analytics.userId.isNotEmpty &&
             analytics.totalWorkouts >= 0 &&
             analytics.totalSets >= 0 &&
             analytics.totalVolume >= 0 &&
             analytics.exerciseTypeBreakdown.isNotEmpty;
    }, 'contains complete analytics data');
  }
  
  /// Matcher for validating exercise data integrity
  static Matcher isValidExercise() {
    return predicate<Exercise>((exercise) {
      return exercise.id.isNotEmpty &&
             exercise.name.isNotEmpty &&
             exercise.userId.isNotEmpty &&
             exercise.workoutId.isNotEmpty &&
             exercise.weekId.isNotEmpty &&
             exercise.programId.isNotEmpty;
    }, 'is a valid exercise with all required fields');
  }
  
  /// Matcher for validating workout data integrity
  static Matcher isValidWorkout() {
    return predicate<Workout>((workout) {
      return workout.id.isNotEmpty &&
             workout.name.isNotEmpty &&
             workout.userId.isNotEmpty &&
             workout.weekId.isNotEmpty &&
             workout.programId.isNotEmpty;
    }, 'is a valid workout with all required fields');
  }
}

/// Test utilities for common testing operations
class TestUtils {
  /// Prints test section headers for better organization
  static void printTestSection(String sectionName) {
    print('\n' + '=' * 60);
    print('  $sectionName');
    print('=' * 60);
  }
  
  /// Prints test subsection headers
  static void printTestSubsection(String subsectionName) {
    print('\n' + '-' * 40);
    print('  $subsectionName');
    print('-' * 40);
  }
  
  /// Creates a performance test wrapper
  static Future<T> measurePerformance<T>(
    String testName,
    Future<T> Function() testFunction, {
    int? customThreshold,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await testFunction();
    stopwatch.stop();
    
    TestConfig.validatePerformance(stopwatch, testName, customThreshold: customThreshold);
    return result;
  }
  
  /// Creates a memory usage test wrapper
  static Future<T> measureMemory<T>(
    String testName,
    Future<T> Function() testFunction,
  ) async {
    // Record initial memory state
    final initialMemory = _getMemoryUsage();
    
    final result = await testFunction();
    
    // Record final memory state
    final finalMemory = _getMemoryUsage();
    final memoryGrowth = finalMemory - initialMemory;
    
    // Log memory usage (could be made into an assertion if needed)
    print('Memory growth for $testName: ${memoryGrowth}MB');
    
    return result;
  }
  
  /// Mock implementation of memory usage measurement
  static double _getMemoryUsage() {
    // In a real implementation, this would use Platform-specific
    // memory measurement tools. For now, return a mock value.
    return 0.0;
  }
  
  /// Generates a range of test dates for time-based testing
  static List<DateTime> generateTestDates({
    required DateTime start,
    required DateTime end,
    int interval = 1, // days
  }) {
    final dates = <DateTime>[];
    var current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(Duration(days: interval));
    }
    
    return dates;
  }
}