/// Integration tests for Firestore cascade delete count functionality
///
/// These tests validate that FirestoreService.getCascadeDeleteCounts()
/// correctly counts nested documents in Firestore when preparing for
/// cascade delete operations.
///
/// IMPORTANT: These are TRUE integration tests that:
/// - Connect to Firebase emulators (Auth + Firestore)
/// - Create real test data in Firestore
/// - Verify counts match actual Firestore data
/// - Test all context scenarios (week/workout/exercise deletion)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/models/cascade_delete_counts.dart';

/// Test configuration for Firebase emulators
/// Must match the ports used in GitHub Actions workflow
const String kAuthEmulatorHost = 'localhost';
const int kAuthEmulatorPort = 9099;
const String kFirestoreEmulatorHost = 'localhost';
const int kFirestoreEmulatorPort = 8080;

void main() {
  group('Firestore Cascade Delete Count Integration Tests', () {
    late FirestoreService firestoreService;
    late String testUserId;
    String? testProgramId;
    String? testWeekId;
    String? testWorkoutId;
    String? testExerciseId;

    setUpAll(() async {
      // Initialize Flutter binding for Firebase
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase for testing
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'fitness-app-8505e',
          ),
        );
      } catch (e) {
        if (!e.toString().contains('duplicate-app')) {
          rethrow;
        }
      }

      // Configure emulators
      try {
        FirebaseAuth.instance.useAuthEmulator(kAuthEmulatorHost, kAuthEmulatorPort);
        FirebaseFirestore.instance.useFirestoreEmulator(kFirestoreEmulatorHost, kFirestoreEmulatorPort);
      } catch (e) {
        // Already configured
        print('Emulators already configured: $e');
      }

      print('✅ Firebase emulators configured for integration tests');
    });

    setUp(() async {
      // Create fresh test user for each test
      final email = 'test-${DateTime.now().millisecondsSinceEpoch}@fittrack.test';
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'testpassword123',
      );
      testUserId = userCredential.user!.uid;

      // Initialize service with test Firestore instance
      firestoreService = FirestoreService.withFirestore(FirebaseFirestore.instance);

      print('✅ Test user created: $testUserId ($email)');
    });

    tearDown(() async {
      // Clean up test data
      try {
        if (testProgramId != null) {
          final programRef = FirebaseFirestore.instance
              .collection('users')
              .doc(testUserId)
              .collection('programs')
              .doc(testProgramId);

          // Delete all nested collections
          await _deleteCollection(programRef.collection('weeks'));
          await programRef.delete();
        }

        // Sign out user
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        print('Cleanup error: $e');
      }
    });

    test('counts workouts, exercises, and sets when deleting a week', () async {
      /// Test Purpose: Verify getCascadeDeleteCounts() correctly counts all nested
      /// documents when preparing to delete a week
      ///
      /// Scenario:
      /// - Week contains 2 workouts
      /// - First workout has 2 exercises
      /// - Second workout has 1 exercise
      /// - Exercises have 3, 2, and 1 sets respectively
      ///
      /// Expected: 2 workouts, 3 exercises, 6 sets

      // Create test program
      final programRef = await _createTestProgram(testUserId);
      testProgramId = programRef.id;

      // Create test week
      final weekRef = await programRef.collection('weeks').add({
        'name': 'Test Week',
        'order': 1,
        'notes': 'Test notes',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
      });
      testWeekId = weekRef.id;

      // Create first workout with 2 exercises
      final workout1Ref = await weekRef.collection('workouts').add({
        'name': 'Workout 1',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
      });

      final exercise1Ref = await workout1Ref.collection('exercises').add({
        'name': 'Exercise 1',
        'order': 1,
        'exerciseType': 'strength',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': workout1Ref.id,
      });

      // Add 3 sets to exercise 1
      for (int i = 0; i < 3; i++) {
        await exercise1Ref.collection('sets').add({
          'reps': 10,
          'weight': 100.0,
          'order': i + 1,
          'checked': false,
          'createdAt': DateTime.now(),
          'userId': testUserId,
        });
      }

      final exercise2Ref = await workout1Ref.collection('exercises').add({
        'name': 'Exercise 2',
        'order': 2,
        'exerciseType': 'strength',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': workout1Ref.id,
      });

      // Add 2 sets to exercise 2
      for (int i = 0; i < 2; i++) {
        await exercise2Ref.collection('sets').add({
          'reps': 10,
          'weight': 100.0,
          'order': i + 1,
          'checked': false,
          'createdAt': DateTime.now(),
          'userId': testUserId,
        });
      }

      // Create second workout with 1 exercise
      final workout2Ref = await weekRef.collection('workouts').add({
        'name': 'Workout 2',
        'order': 2,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
      });

      final exercise3Ref = await workout2Ref.collection('exercises').add({
        'name': 'Exercise 3',
        'order': 1,
        'exerciseType': 'strength',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': workout2Ref.id,
      });

      // Add 1 set to exercise 3
      await exercise3Ref.collection('sets').add({
        'reps': 10,
        'weight': 100.0,
        'order': 1,
        'checked': false,
        'createdAt': DateTime.now(),
        'userId': testUserId,
      });

      // Wait for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));

      // Call getCascadeDeleteCounts for week deletion
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: testUserId,
        programId: testProgramId!,
        weekId: testWeekId,
      );

      // Verify counts
      expect(counts.workouts, equals(2), reason: 'Should count 2 workouts');
      expect(counts.exercises, equals(3), reason: 'Should count 3 exercises across both workouts');
      expect(counts.sets, equals(6), reason: 'Should count 6 sets total (3+2+1)');
      expect(counts.totalItems, equals(11), reason: 'Total should be 2+3+6=11');
      expect(counts.hasItems, isTrue);

      // Verify summary message
      final summary = counts.getSummary();
      expect(summary, contains('2 workouts'));
      expect(summary, contains('3 exercises'));
      expect(summary, contains('6 sets'));
    });

    test('counts exercises and sets when deleting a workout', () async {
      /// Test Purpose: Verify getCascadeDeleteCounts() correctly counts exercises
      /// and sets when preparing to delete a workout
      ///
      /// Scenario:
      /// - Workout contains 2 exercises
      /// - First exercise has 4 sets
      /// - Second exercise has 3 sets
      ///
      /// Expected: 0 workouts, 2 exercises, 7 sets

      // Create test program and week
      final programRef = await _createTestProgram(testUserId);
      testProgramId = programRef.id;

      final weekRef = await programRef.collection('weeks').add({
        'name': 'Test Week',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
      });
      testWeekId = weekRef.id;

      // Create workout
      final workoutRef = await weekRef.collection('workouts').add({
        'name': 'Test Workout',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
      });
      testWorkoutId = workoutRef.id;

      // Create first exercise with 4 sets
      final exercise1Ref = await workoutRef.collection('exercises').add({
        'name': 'Exercise 1',
        'order': 1,
        'exerciseType': 'strength',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': testWorkoutId,
      });

      for (int i = 0; i < 4; i++) {
        await exercise1Ref.collection('sets').add({
          'reps': 10,
          'weight': 100.0,
          'order': i + 1,
          'checked': false,
          'createdAt': DateTime.now(),
          'userId': testUserId,
        });
      }

      // Create second exercise with 3 sets
      final exercise2Ref = await workoutRef.collection('exercises').add({
        'name': 'Exercise 2',
        'order': 2,
        'exerciseType': 'cardio',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': testWorkoutId,
      });

      for (int i = 0; i < 3; i++) {
        await exercise2Ref.collection('sets').add({
          'duration': 300,
          'distance': 5.0,
          'order': i + 1,
          'checked': false,
          'createdAt': DateTime.now(),
          'userId': testUserId,
        });
      }

      // Wait for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));

      // Call getCascadeDeleteCounts for workout deletion
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: testUserId,
        programId: testProgramId!,
        weekId: testWeekId,
        workoutId: testWorkoutId,
      );

      // Verify counts
      expect(counts.workouts, equals(0), reason: 'Should not count workouts');
      expect(counts.exercises, equals(2), reason: 'Should count 2 exercises');
      expect(counts.sets, equals(7), reason: 'Should count 7 sets total (4+3)');
      expect(counts.totalItems, equals(9), reason: 'Total should be 0+2+7=9');

      // Verify summary message
      final summary = counts.getSummary();
      expect(summary, contains('2 exercises'));
      expect(summary, contains('7 sets'));
      expect(summary, isNot(contains('workout')));
    });

    test('counts only sets when deleting an exercise', () async {
      /// Test Purpose: Verify getCascadeDeleteCounts() correctly counts only sets
      /// when preparing to delete an exercise
      ///
      /// Scenario:
      /// - Exercise contains 5 sets
      ///
      /// Expected: 0 workouts, 0 exercises, 5 sets

      // Create test hierarchy
      final programRef = await _createTestProgram(testUserId);
      testProgramId = programRef.id;

      final weekRef = await programRef.collection('weeks').add({
        'name': 'Test Week',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
      });
      testWeekId = weekRef.id;

      final workoutRef = await weekRef.collection('workouts').add({
        'name': 'Test Workout',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
      });
      testWorkoutId = workoutRef.id;

      final exerciseRef = await workoutRef.collection('exercises').add({
        'name': 'Test Exercise',
        'order': 1,
        'exerciseType': 'strength',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': testWorkoutId,
      });
      testExerciseId = exerciseRef.id;

      // Create 5 sets
      for (int i = 0; i < 5; i++) {
        await exerciseRef.collection('sets').add({
          'reps': 10 + i,
          'weight': 100.0 + (i * 5),
          'order': i + 1,
          'checked': false,
          'createdAt': DateTime.now(),
          'userId': testUserId,
        });
      }

      // Wait for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));

      // Call getCascadeDeleteCounts for exercise deletion
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: testUserId,
        programId: testProgramId!,
        weekId: testWeekId,
        workoutId: testWorkoutId,
        exerciseId: testExerciseId,
      );

      // Verify counts
      expect(counts.workouts, equals(0), reason: 'Should not count workouts');
      expect(counts.exercises, equals(0), reason: 'Should not count exercises');
      expect(counts.sets, equals(5), reason: 'Should count 5 sets');
      expect(counts.totalItems, equals(5), reason: 'Total should be 5');

      // Verify summary message
      final summary = counts.getSummary();
      expect(summary, equals('5 sets'));
      expect(summary, isNot(contains('workout')));
      expect(summary, isNot(contains('exercise')));
    });

    test('returns zero counts when deleting empty week', () async {
      /// Test Purpose: Verify getCascadeDeleteCounts() returns zeros for
      /// a week with no workouts

      // Create test program and empty week
      final programRef = await _createTestProgram(testUserId);
      testProgramId = programRef.id;

      final weekRef = await programRef.collection('weeks').add({
        'name': 'Empty Week',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
      });
      testWeekId = weekRef.id;

      // Wait for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));

      // Call getCascadeDeleteCounts for empty week
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: testUserId,
        programId: testProgramId!,
        weekId: testWeekId,
      );

      // Verify all counts are zero
      expect(counts.workouts, equals(0));
      expect(counts.exercises, equals(0));
      expect(counts.sets, equals(0));
      expect(counts.totalItems, equals(0));
      expect(counts.hasItems, isFalse);

      // Verify summary is empty
      final summary = counts.getSummary();
      expect(summary, isEmpty);
    });

    test('returns zero counts when deleting exercise with no sets', () async {
      /// Test Purpose: Verify getCascadeDeleteCounts() returns zeros for
      /// an exercise with no sets

      // Create test hierarchy
      final programRef = await _createTestProgram(testUserId);
      testProgramId = programRef.id;

      final weekRef = await programRef.collection('weeks').add({
        'name': 'Test Week',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
      });
      testWeekId = weekRef.id;

      final workoutRef = await weekRef.collection('workouts').add({
        'name': 'Test Workout',
        'order': 1,
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
      });
      testWorkoutId = workoutRef.id;

      final exerciseRef = await workoutRef.collection('exercises').add({
        'name': 'Empty Exercise',
        'order': 1,
        'exerciseType': 'strength',
        'notes': '',
        'createdAt': DateTime.now(),
        'userId': testUserId,
        'programId': testProgramId,
        'weekId': testWeekId,
        'workoutId': testWorkoutId,
      });
      testExerciseId = exerciseRef.id;

      // Don't add any sets

      // Wait for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));

      // Call getCascadeDeleteCounts for empty exercise
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: testUserId,
        programId: testProgramId!,
        weekId: testWeekId,
        workoutId: testWorkoutId,
        exerciseId: testExerciseId,
      );

      // Verify all counts are zero
      expect(counts.workouts, equals(0));
      expect(counts.exercises, equals(0));
      expect(counts.sets, equals(0));
      expect(counts.totalItems, equals(0));
      expect(counts.hasItems, isFalse);
    });
  });
}

/// Helper: Create a test program document
Future<DocumentReference> _createTestProgram(String userId) async {
  final programRef = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('programs')
      .add({
    'name': 'Test Program',
    'description': 'Integration test program',
    'createdAt': DateTime.now(),
    'updatedAt': DateTime.now(),
    'userId': userId,
    'isArchived': false,
  });

  return programRef;
}

/// Helper: Delete all documents in a collection
Future<void> _deleteCollection(CollectionReference collection) async {
  try {
    final snapshots = await collection.get();
    for (final doc in snapshots.docs) {
      // Recursively delete subcollections
      final subcollections = ['weeks', 'workouts', 'exercises', 'sets'];
      for (final subcoll in subcollections) {
        await _deleteCollection(doc.reference.collection(subcoll));
      }
      await doc.reference.delete();
    }
  } catch (e) {
    print('Error deleting collection: $e');
  }
}
