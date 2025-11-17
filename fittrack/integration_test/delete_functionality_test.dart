/// Integration tests for cascade delete functionality
///
/// Test Coverage:
/// - Week cascade deletion (week → workouts → exercises → sets)
/// - Workout cascade deletion (workout → exercises → sets)
/// - Exercise cascade deletion (exercise → sets)
/// - Cascade delete count accuracy verification
/// - Error scenarios (permissions, network)
/// - Data integrity verification after cascade deletes
///
/// If any test fails, it indicates issues with:
/// - Cascade delete implementation in FirestoreService
/// - Data integrity during multi-collection operations
/// - Batched write operations
/// - Error handling in delete flows
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';

import 'firebase_emulator_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Delete Functionality Integration Tests', () {
    late String testUserId;
    late String testEmail;
    late String testPassword;

    setUpAll(() async {
      /// Test Purpose: Initialize Firebase emulators and test environment
      /// This sets up isolated testing environment with real Firebase functionality

      await setupFirebaseEmulators();
      testPassword = 'TestPassword123!';
    });

    setUp(() async {
      /// Test Purpose: Create fresh test user for each test
      /// This ensures test isolation and prevents data contamination

      final timestamp = DateTime.now().microsecondsSinceEpoch;
      testEmail = 'test$timestamp@fittrack.test';

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      testUserId = userCredential.user!.uid;

      await FirestoreService.instance.createUserProfile(
        userId: testUserId,
        displayName: 'Test User',
        email: testEmail,
      );
    });

    tearDown(() async {
      /// Test Purpose: Clean up test data after each test
      /// This ensures clean state for subsequent tests

      try {
        await _cleanupTestData(testUserId);
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print('Cleanup error: $e');
      }
    });

    group('Week Cascade Delete', () {
      test('deletes week with all child workouts, exercises, and sets', () async {
        /// Test Purpose: Verify complete cascade delete for week deletion
        /// Users expect that deleting a week removes ALL nested data
        /// Failure indicates incomplete cascade deletion or batch write issues

        // Arrange: Create complete week hierarchy
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workout1Id = await _createTestWorkout(testUserId, programId, weekId);
        final workout2Id = await _createTestWorkout(testUserId, programId, weekId, name: 'Test Workout 2');

        final exercise1Id = await _createTestExercise(testUserId, programId, weekId, workout1Id);
        final exercise2Id = await _createTestExercise(testUserId, programId, weekId, workout1Id, name: 'Test Exercise 2');
        final exercise3Id = await _createTestExercise(testUserId, programId, weekId, workout2Id, name: 'Test Exercise 3');

        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise2Id);
        await _createTestSet(testUserId, programId, weekId, workout2Id, exercise3Id);
        await _createTestSet(testUserId, programId, weekId, workout2Id, exercise3Id);

        // Act: Delete week
        await FirestoreService.instance.deleteWeek(testUserId, programId, weekId);

        // Assert: Verify all child data deleted
        final weekExists = await _weekExists(testUserId, programId, weekId);
        expect(weekExists, isFalse, reason: 'Week should be deleted');

        final workoutCount = await _countWorkouts(testUserId, programId, weekId);
        expect(workoutCount, equals(0), reason: 'All workouts should be deleted');

        final exercise1Exists = await _exerciseExists(testUserId, programId, weekId, workout1Id, exercise1Id);
        final exercise2Exists = await _exerciseExists(testUserId, programId, weekId, workout1Id, exercise2Id);
        final exercise3Exists = await _exerciseExists(testUserId, programId, weekId, workout2Id, exercise3Id);
        expect(exercise1Exists, isFalse, reason: 'Exercise 1 should be deleted');
        expect(exercise2Exists, isFalse, reason: 'Exercise 2 should be deleted');
        expect(exercise3Exists, isFalse, reason: 'Exercise 3 should be deleted');

        final setCount1 = await _countSets(testUserId, programId, weekId, workout1Id, exercise1Id);
        final setCount2 = await _countSets(testUserId, programId, weekId, workout1Id, exercise2Id);
        final setCount3 = await _countSets(testUserId, programId, weekId, workout2Id, exercise3Id);
        expect(setCount1, equals(0), reason: 'All sets in exercise 1 should be deleted');
        expect(setCount2, equals(0), reason: 'All sets in exercise 2 should be deleted');
        expect(setCount3, equals(0), reason: 'All sets in exercise 3 should be deleted');
      });

      test('handles empty week deletion (no workouts)', () async {
        /// Test Purpose: Verify deletion works for empty weeks
        /// Edge case: Week with zero workouts should delete cleanly
        /// Failure indicates issues with empty collection handling

        // Arrange: Create week with no workouts
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);

        // Act: Delete empty week
        await FirestoreService.instance.deleteWeek(testUserId, programId, weekId);

        // Assert: Week deleted successfully
        final weekExists = await _weekExists(testUserId, programId, weekId);
        expect(weekExists, isFalse, reason: 'Empty week should be deleted');
      });

      test('does not affect other weeks in same program', () async {
        /// Test Purpose: Verify deletion is properly scoped to single week
        /// Users expect only the selected week to be deleted
        /// Failure indicates over-deletion or incorrect batch operations

        // Arrange: Create program with two weeks
        final programId = await _createTestProgram(testUserId);
        final week1Id = await _createTestWeek(testUserId, programId, name: 'Week 1');
        final week2Id = await _createTestWeek(testUserId, programId, name: 'Week 2');

        await _createTestWorkout(testUserId, programId, week1Id);
        final workout2Id = await _createTestWorkout(testUserId, programId, week2Id);

        // Act: Delete only week 1
        await FirestoreService.instance.deleteWeek(testUserId, programId, week1Id);

        // Assert: Week 1 deleted, Week 2 intact
        final week1Exists = await _weekExists(testUserId, programId, week1Id);
        final week2Exists = await _weekExists(testUserId, programId, week2Id);

        expect(week1Exists, isFalse, reason: 'Week 1 should be deleted');
        expect(week2Exists, isTrue, reason: 'Week 2 should NOT be deleted');

        final workout2Exists = await _workoutExists(testUserId, programId, week2Id, workout2Id);
        expect(workout2Exists, isTrue, reason: 'Week 2 workout should NOT be deleted');
      });
    });

    group('Workout Cascade Delete', () {
      test('deletes workout with all child exercises and sets', () async {
        /// Test Purpose: Verify complete cascade delete for workout deletion
        /// Users expect that deleting a workout removes all exercises and sets
        /// Failure indicates incomplete cascade deletion

        // Arrange: Create workout with exercises and sets
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);

        final exercise1Id = await _createTestExercise(testUserId, programId, weekId, workoutId);
        final exercise2Id = await _createTestExercise(testUserId, programId, weekId, workoutId, name: 'Test Exercise 2');

        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise2Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise2Id);

        // Act: Delete workout
        await FirestoreService.instance.deleteWorkout(testUserId, programId, weekId, workoutId);

        // Assert: Verify all child data deleted
        final workoutExists = await _workoutExists(testUserId, programId, weekId, workoutId);
        expect(workoutExists, isFalse, reason: 'Workout should be deleted');

        final exerciseCount = await _countExercises(testUserId, programId, weekId, workoutId);
        expect(exerciseCount, equals(0), reason: 'All exercises should be deleted');

        final setCount1 = await _countSets(testUserId, programId, weekId, workoutId, exercise1Id);
        final setCount2 = await _countSets(testUserId, programId, weekId, workoutId, exercise2Id);
        expect(setCount1, equals(0), reason: 'All sets in exercise 1 should be deleted');
        expect(setCount2, equals(0), reason: 'All sets in exercise 2 should be deleted');
      });

      test('handles empty workout deletion (no exercises)', () async {
        /// Test Purpose: Verify deletion works for empty workouts
        /// Edge case: Workout with zero exercises should delete cleanly
        /// Failure indicates issues with empty collection handling

        // Arrange: Create workout with no exercises
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);

        // Act: Delete empty workout
        await FirestoreService.instance.deleteWorkout(testUserId, programId, weekId, workoutId);

        // Assert: Workout deleted successfully
        final workoutExists = await _workoutExists(testUserId, programId, weekId, workoutId);
        expect(workoutExists, isFalse, reason: 'Empty workout should be deleted');
      });

      test('does not affect other workouts in same week', () async {
        /// Test Purpose: Verify deletion is properly scoped to single workout
        /// Users expect only the selected workout to be deleted
        /// Failure indicates over-deletion or incorrect batch operations

        // Arrange: Create week with two workouts
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workout1Id = await _createTestWorkout(testUserId, programId, weekId, name: 'Workout 1');
        final workout2Id = await _createTestWorkout(testUserId, programId, weekId, name: 'Workout 2');

        await _createTestExercise(testUserId, programId, weekId, workout1Id);
        final exercise2Id = await _createTestExercise(testUserId, programId, weekId, workout2Id);

        // Act: Delete only workout 1
        await FirestoreService.instance.deleteWorkout(testUserId, programId, weekId, workout1Id);

        // Assert: Workout 1 deleted, Workout 2 intact
        final workout1Exists = await _workoutExists(testUserId, programId, weekId, workout1Id);
        final workout2Exists = await _workoutExists(testUserId, programId, weekId, workout2Id);

        expect(workout1Exists, isFalse, reason: 'Workout 1 should be deleted');
        expect(workout2Exists, isTrue, reason: 'Workout 2 should NOT be deleted');

        final exercise2Exists = await _exerciseExists(testUserId, programId, weekId, workout2Id, exercise2Id);
        expect(exercise2Exists, isTrue, reason: 'Workout 2 exercise should NOT be deleted');
      });
    });

    group('Exercise Cascade Delete', () {
      test('deletes exercise with all child sets', () async {
        /// Test Purpose: Verify complete cascade delete for exercise deletion
        /// Users expect that deleting an exercise removes all sets
        /// Failure indicates incomplete cascade deletion

        // Arrange: Create exercise with sets
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);
        final exerciseId = await _createTestExercise(testUserId, programId, weekId, workoutId);

        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);

        // Act: Delete exercise
        await FirestoreService.instance.deleteExercise(testUserId, programId, weekId, workoutId, exerciseId);

        // Assert: Verify all child data deleted
        final exerciseExists = await _exerciseExists(testUserId, programId, weekId, workoutId, exerciseId);
        expect(exerciseExists, isFalse, reason: 'Exercise should be deleted');

        final setCount = await _countSets(testUserId, programId, weekId, workoutId, exerciseId);
        expect(setCount, equals(0), reason: 'All sets should be deleted');
      });

      test('handles empty exercise deletion (no sets)', () async {
        /// Test Purpose: Verify deletion works for empty exercises
        /// Edge case: Exercise with zero sets should delete cleanly
        /// Failure indicates issues with empty collection handling

        // Arrange: Create exercise with no sets
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);
        final exerciseId = await _createTestExercise(testUserId, programId, weekId, workoutId);

        // Act: Delete empty exercise
        await FirestoreService.instance.deleteExercise(testUserId, programId, weekId, workoutId, exerciseId);

        // Assert: Exercise deleted successfully
        final exerciseExists = await _exerciseExists(testUserId, programId, weekId, workoutId, exerciseId);
        expect(exerciseExists, isFalse, reason: 'Empty exercise should be deleted');
      });

      test('does not affect other exercises in same workout', () async {
        /// Test Purpose: Verify deletion is properly scoped to single exercise
        /// Users expect only the selected exercise to be deleted
        /// Failure indicates over-deletion or incorrect batch operations

        // Arrange: Create workout with two exercises
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);
        final exercise1Id = await _createTestExercise(testUserId, programId, weekId, workoutId, name: 'Exercise 1');
        final exercise2Id = await _createTestExercise(testUserId, programId, weekId, workoutId, name: 'Exercise 2');

        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise2Id);

        // Act: Delete only exercise 1
        await FirestoreService.instance.deleteExercise(testUserId, programId, weekId, workoutId, exercise1Id);

        // Assert: Exercise 1 deleted, Exercise 2 intact
        final exercise1Exists = await _exerciseExists(testUserId, programId, weekId, workoutId, exercise1Id);
        final exercise2Exists = await _exerciseExists(testUserId, programId, weekId, workoutId, exercise2Id);

        expect(exercise1Exists, isFalse, reason: 'Exercise 1 should be deleted');
        expect(exercise2Exists, isTrue, reason: 'Exercise 2 should NOT be deleted');

        final setCount2 = await _countSets(testUserId, programId, weekId, workoutId, exercise2Id);
        expect(setCount2, equals(1), reason: 'Exercise 2 sets should NOT be deleted');
      });
    });

    group('Cascade Delete Count Accuracy', () {
      test('accurately counts cascade deletes for week deletion', () async {
        /// Test Purpose: Verify cascade count calculation is accurate for weeks
        /// Users rely on accurate counts in confirmation dialogs
        /// Failure indicates incorrect count queries or logic

        // Arrange: Create week with known hierarchy
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);

        // 2 workouts
        final workout1Id = await _createTestWorkout(testUserId, programId, weekId);
        final workout2Id = await _createTestWorkout(testUserId, programId, weekId, name: 'Workout 2');

        // 3 exercises total (2 in workout1, 1 in workout2)
        final exercise1Id = await _createTestExercise(testUserId, programId, weekId, workout1Id);
        final exercise2Id = await _createTestExercise(testUserId, programId, weekId, workout1Id, name: 'Exercise 2');
        final exercise3Id = await _createTestExercise(testUserId, programId, weekId, workout2Id);

        // 7 sets total (3 + 2 + 2)
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise2Id);
        await _createTestSet(testUserId, programId, weekId, workout1Id, exercise2Id);
        await _createTestSet(testUserId, programId, weekId, workout2Id, exercise3Id);
        await _createTestSet(testUserId, programId, weekId, workout2Id, exercise3Id);

        // Act: Get cascade counts
        final counts = await FirestoreService.instance.getCascadeDeleteCounts(
          userId: testUserId,
          programId: programId,
          weekId: weekId,
        );

        // Assert: Counts are accurate
        expect(counts.workouts, equals(2), reason: 'Should count 2 workouts');
        expect(counts.exercises, equals(3), reason: 'Should count 3 exercises');
        expect(counts.sets, equals(7), reason: 'Should count 7 sets');
      });

      test('accurately counts cascade deletes for workout deletion', () async {
        /// Test Purpose: Verify cascade count calculation is accurate for workouts
        /// Users rely on accurate counts in confirmation dialogs
        /// Failure indicates incorrect count queries or logic

        // Arrange: Create workout with known hierarchy
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);

        // 2 exercises
        final exercise1Id = await _createTestExercise(testUserId, programId, weekId, workoutId);
        final exercise2Id = await _createTestExercise(testUserId, programId, weekId, workoutId, name: 'Exercise 2');

        // 5 sets total (3 + 2)
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise1Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise2Id);
        await _createTestSet(testUserId, programId, weekId, workoutId, exercise2Id);

        // Act: Get cascade counts
        final counts = await FirestoreService.instance.getCascadeDeleteCounts(
          userId: testUserId,
          programId: programId,
          weekId: weekId,
          workoutId: workoutId,
        );

        // Assert: Counts are accurate
        expect(counts.workouts, equals(0), reason: 'Workout deletion should not count workouts');
        expect(counts.exercises, equals(2), reason: 'Should count 2 exercises');
        expect(counts.sets, equals(5), reason: 'Should count 5 sets');
      });

      test('accurately counts cascade deletes for exercise deletion', () async {
        /// Test Purpose: Verify cascade count calculation is accurate for exercises
        /// Users rely on accurate counts in confirmation dialogs
        /// Failure indicates incorrect count queries or logic

        // Arrange: Create exercise with known number of sets
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workoutId = await _createTestWorkout(testUserId, programId, weekId);
        final exerciseId = await _createTestExercise(testUserId, programId, weekId, workoutId);

        // 4 sets
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);
        await _createTestSet(testUserId, programId, weekId, workoutId, exerciseId);

        // Act: Get cascade counts
        final counts = await FirestoreService.instance.getCascadeDeleteCounts(
          userId: testUserId,
          programId: programId,
          weekId: weekId,
          workoutId: workoutId,
          exerciseId: exerciseId,
        );

        // Assert: Counts are accurate
        expect(counts.workouts, equals(0), reason: 'Exercise deletion should not count workouts');
        expect(counts.exercises, equals(0), reason: 'Exercise deletion should not count exercises');
        expect(counts.sets, equals(4), reason: 'Should count 4 sets');
      });

      test('returns zero counts for empty hierarchy', () async {
        /// Test Purpose: Verify cascade counts return zeros for empty collections
        /// Edge case: Empty week/workout/exercise should return zero counts
        /// Failure indicates incorrect handling of empty collections

        // Arrange: Create empty week
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);

        // Act: Get cascade counts for empty week
        final counts = await FirestoreService.instance.getCascadeDeleteCounts(
          userId: testUserId,
          programId: programId,
          weekId: weekId,
        );

        // Assert: All counts are zero
        expect(counts.workouts, equals(0), reason: 'Empty week should have 0 workouts');
        expect(counts.exercises, equals(0), reason: 'Empty week should have 0 exercises');
        expect(counts.sets, equals(0), reason: 'Empty week should have 0 sets');
        expect(counts.hasItems, isFalse, reason: 'Empty week should report no items');
      });
    });

    group('Error Scenarios', () {
      test('handles deletion with invalid user ID gracefully', () async {
        /// Test Purpose: Verify error handling for invalid user ID
        /// Security: Users should not be able to delete other users' data
        /// Failure indicates potential security vulnerability

        // Arrange: Create week with valid user
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);

        // Act & Assert: Attempt deletion with different user ID should fail
        expect(
          () => FirestoreService.instance.deleteWeek('invalid-user-id', programId, weekId),
          throwsException,
          reason: 'Should reject deletion with invalid user ID',
        );

        // Verify week still exists
        final weekExists = await _weekExists(testUserId, programId, weekId);
        expect(weekExists, isTrue, reason: 'Week should NOT be deleted with invalid user ID');
      });

      test('handles deletion with invalid program ID gracefully', () async {
        /// Test Purpose: Verify error handling for invalid program ID
        /// Edge case: Invalid IDs should fail gracefully without crashes
        /// Failure indicates poor error handling

        // Act & Assert: Attempt deletion with invalid program ID
        expect(
          () => FirestoreService.instance.deleteWeek(testUserId, 'invalid-program-id', 'invalid-week-id'),
          throwsException,
          reason: 'Should handle invalid program ID gracefully',
        );
      });

      test('handles concurrent delete operations correctly', () async {
        /// Test Purpose: Verify concurrent deletes don't cause data corruption
        /// Race condition: Multiple deletes in parallel should complete safely
        /// Failure indicates potential data corruption or deadlock

        // Arrange: Create week with multiple workouts
        final programId = await _createTestProgram(testUserId);
        final weekId = await _createTestWeek(testUserId, programId);
        final workout1Id = await _createTestWorkout(testUserId, programId, weekId);
        final workout2Id = await _createTestWorkout(testUserId, programId, weekId, name: 'Workout 2');
        final workout3Id = await _createTestWorkout(testUserId, programId, weekId, name: 'Workout 3');

        // Act: Delete workouts concurrently
        await Future.wait([
          FirestoreService.instance.deleteWorkout(testUserId, programId, weekId, workout1Id),
          FirestoreService.instance.deleteWorkout(testUserId, programId, weekId, workout2Id),
          FirestoreService.instance.deleteWorkout(testUserId, programId, weekId, workout3Id),
        ]);

        // Assert: All workouts deleted successfully
        final workoutCount = await _countWorkouts(testUserId, programId, weekId);
        expect(workoutCount, equals(0), reason: 'All concurrent deletes should complete successfully');
      });
    });
  });
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Clean up all test data for a user
Future<void> _cleanupTestData(String userId) async {
  try {
    final programs = await FirestoreService.instance.getPrograms(userId).first;
    for (final program in programs) {
      await FirestoreService.instance.deleteProgram(userId, program.id);
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  } catch (e) {
    print('Cleanup error: $e');
  }
}

/// Create a test program
Future<String> _createTestProgram(String userId, {String name = 'Test Program'}) async {
  final programId = await FirestoreService.instance.createProgram(
    Program(
      id: '',
      name: name,
      description: 'Integration test program',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
    ),
  );
  return programId;
}

/// Create a test week
Future<String> _createTestWeek(String userId, String programId, {String name = 'Test Week'}) async {
  final weekId = await FirestoreService.instance.createWeek(
    Week(
      id: '',
      name: name,
      order: 1,
      notes: 'Integration test week',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      programId: programId,
    ),
  );
  return weekId;
}

/// Create a test workout
Future<String> _createTestWorkout(
  String userId,
  String programId,
  String weekId, {
  String name = 'Test Workout',
}) async {
  final workoutId = await FirestoreService.instance.createWorkout(
    Workout(
      id: '',
      name: name,
      dayOfWeek: 1,
      orderIndex: 0,
      notes: 'Integration test workout',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      weekId: weekId,
      programId: programId,
    ),
  );
  return workoutId;
}

/// Create a test exercise
Future<String> _createTestExercise(
  String userId,
  String programId,
  String weekId,
  String workoutId, {
  String name = 'Test Exercise',
}) async {
  final exerciseId = await FirestoreService.instance.createExercise(
    Exercise(
      id: '',
      name: name,
      exerciseType: ExerciseType.strength,
      orderIndex: 0,
      notes: 'Integration test exercise',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    ),
  );
  return exerciseId;
}

/// Create a test set
Future<String> _createTestSet(
  String userId,
  String programId,
  String weekId,
  String workoutId,
  String exerciseId,
) async {
  final setId = await FirestoreService.instance.createSet(
    ExerciseSet(
      id: '',
      setNumber: 1,
      reps: 10,
      weight: 100.0,
      checked: false,
      restTime: 60,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: userId,
      exerciseId: exerciseId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    ),
  );
  return setId;
}

/// Check if a week exists
Future<bool> _weekExists(String userId, String programId, String weekId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .get();
    return doc.exists;
  } catch (e) {
    return false;
  }
}

/// Check if a workout exists
Future<bool> _workoutExists(String userId, String programId, String weekId, String workoutId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .get();
    return doc.exists;
  } catch (e) {
    return false;
  }
}

/// Check if an exercise exists
Future<bool> _exerciseExists(
  String userId,
  String programId,
  String weekId,
  String workoutId,
  String exerciseId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .get();
    return doc.exists;
  } catch (e) {
    return false;
  }
}

/// Count workouts in a week
Future<int> _countWorkouts(String userId, String programId, String weekId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .get();
    return snapshot.docs.length;
  } catch (e) {
    return 0;
  }
}

/// Count exercises in a workout
Future<int> _countExercises(String userId, String programId, String weekId, String workoutId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .get();
    return snapshot.docs.length;
  } catch (e) {
    return 0;
  }
}

/// Count sets in an exercise
Future<int> _countSets(
  String userId,
  String programId,
  String weekId,
  String workoutId,
  String exerciseId,
) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .get();
    return snapshot.docs.length;
  } catch (e) {
    return 0;
  }
}
