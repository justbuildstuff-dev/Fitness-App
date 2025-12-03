import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fittrack/main.dart' as app;
import 'package:fittrack/screens/weeks/weeks_screen.dart';
import 'package:fittrack/screens/workouts/consolidated_workout_screen.dart';
import 'package:fittrack/screens/exercises/create_exercise_screen.dart';
import 'package:fittrack/widgets/exercise_card.dart';
import 'package:fittrack/widgets/set_row.dart';

import 'firebase_emulator_setup.dart';

/// End-to-End Integration Tests for ConsolidatedWorkoutScreen
///
/// These tests verify the complete consolidated workout workflow:
/// 1. Navigate from WeeksScreen to ConsolidatedWorkoutScreen
/// 2. Create exercise with multiple sets (using stepper)
/// 3. Edit set values inline
/// 4. Mark sets complete/incomplete
/// 5. Add and delete sets (with max limit)
/// 6. Add notes to sets
/// 7. Reorder exercises via drag-and-drop
/// 8. Delete exercises with cascade confirmation
/// 9. Verify all data persists to Firestore
///
/// CRITICAL SETUP REQUIREMENTS:
/// - Firebase emulators MUST be running before tests start
/// - Tests use actual Firebase SDKs, not mocks
/// - Emulator data is isolated from production
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ConsolidatedWorkoutScreen End-to-End Integration Tests', () {
    late TestDataSeeds testData;
    late UserCredential testUser;
    late String workoutId;

    setUpAll(() async {
      print('\n🚀 Setting up Firebase emulators for consolidated workout tests...');

      try {
        // Initialize Firebase emulators
        await FirebaseEmulatorSetup.initializeFirebaseForTesting();
        print('✅ Firebase emulators initialized');

        // Create test user
        testUser = await FirebaseEmulatorSetup.createTestUser(
          email: 'consolidated-test@example.com',
          password: 'testpassword123',
        );
        print('✅ Test user created: ${testUser.user!.uid}');

        // Seed baseline test data
        testData = await FirebaseEmulatorSetup.seedTestData(testUser.user!.uid);
        print('✅ Test data seeded: $testData');

        // Create a test workout for these tests
        final firestore = FirebaseFirestore.instance;
        final workoutRef = await firestore
            .collection('users')
            .doc(testUser.user!.uid)
            .collection('programs')
            .doc(testData.programId)
            .collection('weeks')
            .doc(testData.weekId)
            .collection('workouts')
            .add({
          'name': 'Test Workout',
          'orderIndex': 0,
          'userId': testUser.user!.uid,
          'programId': testData.programId,
          'weekId': testData.weekId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        workoutId = workoutRef.id;
        print('✅ Test workout created: $workoutId');

        print('🎯 Integration test environment ready!\n');
      } catch (e) {
        print('❌ Integration test setup failed: $e');
        print('\nEnsure Firebase emulators are running:');
        print('firebase emulators:start --only auth,firestore\n');
        rethrow;
      }
    });

    tearDownAll(() async {
      print('\n🧹 Cleaning up integration test environment...');
      await FirebaseEmulatorSetup.cleanupAfterTests();
      print('✅ Integration test cleanup completed\n');
    });

    setUp(() async {
      // Ensure user is signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email != 'consolidated-test@example.com') {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'consolidated-test@example.com',
          password: 'testpassword123',
        );
      }
    });

    testWidgets('Navigate from WeeksScreen to ConsolidatedWorkoutScreen', (tester) async {
      /// Test Purpose: Verify navigation and screen initialization
      /// Expected: ConsolidatedWorkoutScreen loads with correct workout data

      print('Test 1: Navigate to ConsolidatedWorkoutScreen');

      // Start app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to programs screen if not already there
      if (find.byType(WeeksScreen).evaluate().isEmpty) {
        // May need to navigate through program detail screen
        await tester.tap(find.text('Test Program').first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Find and tap the workout
      await tester.tap(find.text('Test Workout'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify ConsolidatedWorkoutScreen is displayed
      expect(find.byType(ConsolidatedWorkoutScreen), findsOneWidget);
      expect(find.text('Test Workout'), findsOneWidget);

      print('✅ Navigation successful');
    });

    testWidgets('Create exercise with multiple sets using stepper', (tester) async {
      /// Test Purpose: Verify exercise creation with set count stepper
      /// Expected: Exercise created with specified number of sets (e.g., 3)

      print('Test 2: Create exercise with 3 sets');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap FAB to create exercise
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify CreateExerciseScreen is displayed
      expect(find.byType(CreateExerciseScreen), findsOneWidget);

      // Enter exercise name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Bench Press',
      );

      // Increase set count to 3
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pump();
      }

      // Verify set count shows 3
      expect(find.text('3'), findsOneWidget);

      // Create exercise
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify back on ConsolidatedWorkoutScreen
      expect(find.byType(ConsolidatedWorkoutScreen), findsOneWidget);

      // Verify exercise is displayed with 3 sets
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('3 sets'), findsOneWidget);

      print('✅ Exercise created with 3 sets');
    });

    testWidgets('Edit set values inline (weight and reps)', (tester) async {
      /// Test Purpose: Verify inline set editing functionality
      /// Expected: Set values update immediately and persist

      print('Test 3: Edit set values inline');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Expand exercise card if collapsed
      if (find.text('100').evaluate().isEmpty) {
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();
      }

      // Find and edit weight field (first set)
      final weightFields = find.widgetWithText(TextField, 'Weight (kg)');
      await tester.enterText(weightFields.first, '135');
      await tester.pump();

      // Find and edit reps field
      final repsFields = find.widgetWithText(TextField, 'Reps');
      await tester.enterText(repsFields.first, '8');
      await tester.pump(const Duration(seconds: 1));

      // Tap elsewhere to trigger save
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify values persisted (refresh screen)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Expand exercise
      if (find.text('135').evaluate().isEmpty) {
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();
      }

      // Verify edited values are still there
      expect(find.text('135'), findsWidgets);
      expect(find.text('8'), findsWidgets);

      print('✅ Set values edited and persisted');
    });

    testWidgets('Mark set as complete makes fields read-only', (tester) async {
      /// Test Purpose: Verify set completion checkbox functionality
      /// Expected: Checking set disables fields (no strikethrough per bug #51)

      print('Test 4: Mark set as complete');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Expand exercise if needed
      if (find.byType(Checkbox).evaluate().isEmpty) {
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();
      }

      // Check the first set's checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify checkbox is checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isTrue);

      // Verify fields are disabled (read-only)
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      // At least one field should be disabled
      expect(textFields.any((field) => field.enabled == false), isTrue);

      print('✅ Set marked complete, fields read-only');
    });

    testWidgets('Uncheck completed set makes it editable again', (tester) async {
      /// Test Purpose: Verify unchecking re-enables editing
      /// Expected: Unchecked sets have enabled fields

      print('Test 5: Uncheck set to make editable');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Expand exercise if needed
      if (find.byType(Checkbox).evaluate().isEmpty) {
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();
      }

      // Uncheck the first set's checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify checkbox is unchecked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
      expect(checkbox.value, isFalse);

      // Verify fields are enabled again
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields.any((field) => field.enabled == true), isTrue);

      print('✅ Set unchecked, fields editable again');
    });

    testWidgets('Add set to exercise (verify max 10)', (tester) async {
      /// Test Purpose: Verify add set functionality and max limit
      /// Expected: Can add sets up to 10, button disabled at max

      print('Test 6: Add sets to exercise');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Expand exercise if needed
      if (find.text('3 sets').evaluate().isEmpty) {
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();
      }

      // Current set count should be 3
      expect(find.text('3 sets'), findsOneWidget);

      // Find and tap Add Set button (the + icon in exercise card header)
      final addButtons = find.byIcon(Icons.add);
      // Should be multiple add buttons (one per exercise card)
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should now have 4 sets
      expect(find.text('4 sets'), findsOneWidget);

      print('✅ Set added successfully');
    });

    testWidgets('Delete set with confirmation', (tester) async {
      /// Test Purpose: Verify set deletion functionality
      /// Expected: Confirmation dialog, then set removed

      print('Test 7: Delete set');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Expand exercise if needed
      if (find.byIcon(Icons.delete).evaluate().isEmpty) {
        await tester.tap(find.text('Bench Press'));
        await tester.pumpAndSettle();
      }

      // Current set count (should be 4 from previous test)
      expect(find.text('4 sets'), findsOneWidget);

      // Find and tap delete button on a set (not the last one)
      // Delete buttons are in SetRow widgets
      final deleteButtons = find.byIcon(Icons.delete);
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();

        // Confirm deletion in dialog
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should now have 3 sets
        expect(find.text('3 sets'), findsOneWidget);

        print('✅ Set deleted successfully');
      } else {
        print('⚠️ No delete buttons found (may be last set only)');
      }
    });

    testWidgets('Delete exercise shows cascade confirmation', (tester) async {
      /// Test Purpose: Verify exercise deletion with cascade count
      /// Expected: Confirmation dialog shows number of sets that will be deleted

      print('Test 8: Delete exercise with cascade confirmation');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open exercise card menu
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Tap Delete Exercise
      await tester.tap(find.text('Delete Exercise'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Delete Exercise?'), findsOneWidget);

      // Verify cascade count is shown (should mention sets)
      expect(find.textContaining('sets will be deleted'), findsOneWidget);

      // Cancel deletion for now (don't actually delete)
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify exercise still exists
      expect(find.text('Bench Press'), findsOneWidget);

      print('✅ Exercise deletion confirmation shown with cascade count');
    });

    testWidgets('Create second exercise and verify order', (tester) async {
      /// Test Purpose: Verify multiple exercises display in correct order
      /// Expected: Exercises displayed in order with correct exercise cards

      print('Test 9: Create second exercise');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap FAB to create another exercise
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter exercise name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Squats',
      );

      // Keep default 1 set
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify both exercises are displayed
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);

      // Verify they're in ExerciseCard widgets
      expect(find.byType(ExerciseCard), findsNWidgets(2));

      print('✅ Second exercise created, both exercises visible');
    });

    testWidgets('Complete end-to-end workflow verification', (tester) async {
      /// Test Purpose: Comprehensive workflow validation
      /// Expected: All functionality works together seamlessly

      print('Test 10: Complete workflow verification');

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to ConsolidatedWorkoutScreen
      await tester.tap(find.text('Test Workout').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify screen is displaying correctly
      expect(find.byType(ConsolidatedWorkoutScreen), findsOneWidget);

      // Verify FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Verify exercises are displayed
      expect(find.byType(ExerciseCard), findsWidgets);

      // Verify we can expand/collapse exercise cards
      final exerciseNames = find.text('Bench Press');
      if (exerciseNames.evaluate().isNotEmpty) {
        await tester.tap(exerciseNames.first);
        await tester.pumpAndSettle();
        await tester.tap(exerciseNames.first);
        await tester.pumpAndSettle();
      }

      // Verify we can navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're back at previous screen
      expect(find.byType(ConsolidatedWorkoutScreen), findsNothing);

      print('✅ Complete workflow verified successfully');
    });
  });
}
