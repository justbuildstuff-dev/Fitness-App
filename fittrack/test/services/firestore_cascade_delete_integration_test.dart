/// Real Firebase Integration Test for Cascade Delete Counts
///
/// **IMPORTANT: This test connects to Firebase emulators and validates REAL Firebase operations.**
/// - Connects to Firebase Auth emulator (localhost:9099)
/// - Connects to Firestore emulator (localhost:8080)
/// - Creates real data in Firestore
/// - Validates actual Firebase count operations
/// - Runs on Ubuntu CI runner (NOT Android emulator)

@Timeout(Duration(seconds: 120))
library;

import 'package:test/test.dart';
import 'package:fittrack/services/firestore_service.dart';
import '../helpers/firebase_integration_test_helper.dart';

void main() {
  // Connect to Firebase emulators before any tests run
  setUpAll(() async {
    await FirebaseIntegrationTestHelper.initializeFirebaseEmulators();
  });

  // Clear Firestore data before each test for isolation
  setUp(() async {
    await FirebaseIntegrationTestHelper.clearFirestore();
  });

  // Sign out after each test for cleanup
  tearDown(() async {
    await FirebaseIntegrationTestHelper.signOut();
  });

  group('Cascade Delete Counts - REAL Firebase Integration', () {
    late FirestoreService firestoreService;
    late String userId;

    setUp(() async {
      // Create test user with unique email
      final user = await FirebaseIntegrationTestHelper.createTestUser();
      userId = user.uid;

      // Initialize Firestore service (singleton instance)
      firestoreService = FirestoreService.instance;
    });

    test('getCascadeDeleteCounts - deleting week returns correct counts', () async {
      /// Test Purpose: Validate that deleting a week returns accurate counts of workouts, exercises, and sets
      /// Expected: CascadeDeleteCounts with workouts=3, exercises=6, sets=18 (3 workouts × 2 exercises × 3 sets)

      // Seed test data: Program → 2 weeks → 3 workouts per week → 2 exercises per workout → 3 sets per exercise
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 2,
        workoutsPerWeek: 3,
        exercisesPerWorkout: 2,
        setsPerExercise: 3,
      );

      final programId = testData['programId']!;
      final weekIds = testData['weekIds'] as List<String>;
      final weekId = weekIds.first;

      // Call actual service method
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: userId,
        programId: programId,
        weekId: weekId,
      );

      // Verify counts against REAL Firebase data
      expect(counts.workouts, equals(3), reason: 'Should count 3 workouts in week');
      expect(counts.exercises, equals(6), reason: 'Should count 6 exercises (3 workouts × 2 exercises)');
      expect(counts.sets, equals(18), reason: 'Should count 18 sets (3 workouts × 2 exercises × 3 sets)');
    });

    test('getCascadeDeleteCounts - deleting workout returns correct counts', () async {
      /// Test Purpose: Validate that deleting a workout returns accurate counts of exercises and sets
      /// Expected: CascadeDeleteCounts with exercises=2, sets=6 (2 exercises × 3 sets)

      // Seed test data
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 1,
        workoutsPerWeek: 2,
        exercisesPerWorkout: 2,
        setsPerExercise: 3,
      );

      final programId = testData['programId']!;
      final weekIds = testData['weekIds'] as List<String>;
      final weekId = weekIds.first;
      final workoutIds = testData['workoutIds'] as Map<String, List<String>>;
      final workoutId = workoutIds[weekId]!.first;

      // Call actual service method
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: userId,
        programId: programId,
        weekId: weekId,
        workoutId: workoutId,
      );

      // Verify counts
      expect(counts.workouts, equals(0), reason: 'Should not count workouts when deleting workout');
      expect(counts.exercises, equals(2), reason: 'Should count 2 exercises in workout');
      expect(counts.sets, equals(6), reason: 'Should count 6 sets (2 exercises × 3 sets)');
    });

    test('getCascadeDeleteCounts - deleting exercise returns correct set count', () async {
      /// Test Purpose: Validate that deleting an exercise returns accurate count of sets
      /// Expected: CascadeDeleteCounts with sets=3

      // Seed test data
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 1,
        workoutsPerWeek: 1,
        exercisesPerWorkout: 2,
        setsPerExercise: 3,
      );

      final programId = testData['programId']!;
      final weekIds = testData['weekIds'] as List<String>;
      final weekId = weekIds.first;
      final workoutIds = testData['workoutIds'] as Map<String, List<String>>;
      final workoutId = workoutIds[weekId]!.first;
      final exerciseIds = testData['exerciseIds'] as Map<String, Map<String, List<String>>>;
      final exerciseId = exerciseIds[weekId]![workoutId]!.first;

      // Call actual service method
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: userId,
        programId: programId,
        weekId: weekId,
        workoutId: workoutId,
        exerciseId: exerciseId,
      );

      // Verify counts
      expect(counts.workouts, equals(0), reason: 'Should not count workouts when deleting exercise');
      expect(counts.exercises, equals(0), reason: 'Should not count exercises when deleting exercise');
      expect(counts.sets, equals(3), reason: 'Should count 3 sets in exercise');
    });

    test('getCascadeDeleteCounts - empty week returns zero counts', () async {
      /// Test Purpose: Validate graceful handling of empty week (no workouts)
      /// Expected: CascadeDeleteCounts with all zeros

      // Seed minimal test data (program with empty week)
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 1,
        workoutsPerWeek: 0, // Empty week
      );

      final programId = testData['programId']!;
      final weekIds = testData['weekIds'] as List<String>;
      final weekId = weekIds.first;

      // Call actual service method
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: userId,
        programId: programId,
        weekId: weekId,
      );

      // Verify zero counts
      expect(counts.workouts, equals(0), reason: 'Should return 0 workouts for empty week');
      expect(counts.exercises, equals(0), reason: 'Should return 0 exercises for empty week');
      expect(counts.sets, equals(0), reason: 'Should return 0 sets for empty week');
    });

    test('getCascadeDeleteCounts - handles non-existent week gracefully', () async {
      /// Test Purpose: Validate error handling for non-existent week ID
      /// Expected: Returns zero counts instead of throwing exception

      // Seed minimal test data
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 1,
        workoutsPerWeek: 1,
      );

      final programId = testData['programId']!;

      // Call with non-existent week ID
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: userId,
        programId: programId,
        weekId: 'non-existent-week-id',
      );

      // Verify graceful degradation to zero counts
      expect(counts.workouts, equals(0), reason: 'Should return 0 for non-existent week');
      expect(counts.exercises, equals(0), reason: 'Should return 0 for non-existent week');
      expect(counts.sets, equals(0), reason: 'Should return 0 for non-existent week');
    });

    test('getCascadeDeleteCounts - validates actual Firestore count() operations', () async {
      /// Test Purpose: Ensure the test actually connects to Firestore emulators and uses real count() queries
      /// Expected: Counts match the actual documents created in Firestore

      // Seed test data with specific counts
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 1,
        workoutsPerWeek: 2,
        exercisesPerWorkout: 3,
        setsPerExercise: 4,
      );

      final programId = testData['programId']!;
      final weekIds = testData['weekIds'] as List<String>;
      final weekId = weekIds.first;

      // Call actual service method
      final counts = await firestoreService.getCascadeDeleteCounts(
        userId: userId,
        programId: programId,
        weekId: weekId,
      );

      // Verify counts match seeded data
      expect(counts.workouts, equals(2), reason: 'Should match seeded workout count');
      expect(counts.exercises, equals(6), reason: 'Should match seeded exercise count (2 workouts × 3 exercises)');
      expect(counts.sets, equals(24), reason: 'Should match seeded set count (2 × 3 × 4)');
    });
  });
}
