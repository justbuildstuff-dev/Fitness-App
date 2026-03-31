import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fittrack/main.dart' as app;
import 'package:fittrack/screens/programs/programs_screen.dart';
import 'package:fittrack/screens/programs/program_detail_screen.dart';
import 'package:fittrack/screens/weeks/weeks_screen.dart';
import 'package:fittrack/screens/workouts/create_workout_screen.dart';

import 'firebase_emulator_setup.dart';

/// End-to-End Integration Tests for Workout Creation Functionality
/// 
/// These tests verify the complete workout creation workflow by:
/// 1. Starting Firebase emulators with production-equivalent configuration
/// 2. Running the actual Flutter app against emulated Firebase services
/// 3. Simulating real user interactions through the complete workflow
/// 4. Verifying data persistence and UI state changes
/// 
/// CRITICAL SETUP REQUIREMENTS:
/// - Firebase emulators MUST be running before tests start
/// - Tests use actual Firebase SDKs, not mocks
/// - Emulator data is isolated from production
/// 
/// If tests fail, check:
/// 1. Are Firebase emulators running? (firebase emulators:start --only auth,firestore)
/// 2. Are emulator ports accessible? (Auth: 9099, Firestore: 8080)
/// 3. Do Firestore security rules allow the operations?
/// 4. Is the app UI rendering correctly?
/// 
/// These tests provide confidence that the complete user workflow works
/// exactly as users would experience it in production.
void main() {
  // Enable Flutter integration test driver
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Workout Creation End-to-End Integration Tests', () {
    late TestDataSeeds testData;
    late UserCredential testUser;

    /// Set up Firebase emulators and test data before all tests
    /// This runs once at the start of the entire test suite
    setUpAll(() async {
      print('\n🚀 Setting up Firebase emulators for integration tests...');
      
      try {
        // Step 1: Initialize Firebase emulators with production-equivalent config
        await FirebaseEmulatorSetup.initializeFirebaseForTesting();
        print('✅ Firebase emulators initialized');

        // Step 2: Create test user account for authentication
        testUser = await FirebaseEmulatorSetup.createTestUser(
          email: 'workout-test@example.com',
          password: 'testpassword123',
        );
        print('✅ Test user created: ${testUser.user!.uid}');

        // Step 3: Seed baseline test data (program and week)
        testData = await FirebaseEmulatorSetup.seedTestData(testUser.user!.uid);
        print('✅ Test data seeded: $testData');

        print('🎯 Integration test environment ready!\n');
        
      } catch (e) {
        print('❌ Integration test setup failed: $e');
        print('\nEnsure Firebase emulators are running:');
        print('firebase emulators:start --only auth,firestore\n');
        rethrow;
      }
    });

    tearDown(() async {
      /// FIX: Add per-test cleanup to reset authentication state
      /// Problem: Tests were staying authenticated, causing state conflicts
      /// Solution: Sign out after each test to ensure clean state

      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          print('DEBUG: Signing out user ${auth.currentUser!.email} after test');
          await auth.signOut();
          // Allow time for provider cleanup
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        print('Teardown error: $e');
      }
    });

    /// Clean up test data and sign out users after all tests
    /// This ensures clean state for subsequent test runs
    tearDownAll(() async {
      print('\n🧹 Cleaning up integration test environment...');
      await FirebaseEmulatorSetup.cleanupAfterTests();
      print('✅ Integration test cleanup completed\n');
    });

    /// Reset emulator state between test groups for isolation
    /// Prevents test data from one group affecting another
    setUp(() async {
      // Sign in the test user for each test
      //
      // IMPORTANT: We don't call signOut() first because:
      // - Previous test's widget tree may still have active Firestore listeners
      // - signOut() would trigger PERMISSION_DENIED on those listeners
      // - Firebase Auth is a singleton, so signing in again replaces the current session
      //
      // The user is already authenticated from setUpAll() or previous test
      // Just ensure we're signed in with the correct account
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email != 'workout-test@example.com') {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'workout-test@example.com',
          password: 'testpassword123',
        );
      }
      // Force a token refresh so the Firestore SDK has a valid auth token before
      // pumpWidget. Without this, the Firestore gRPC connection may use a stale
      // unauthenticated credential and return permission-denied on the first write.
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      // Delete all workouts from the shared test week before each test so that:
      //  • 'No Workouts Yet' empty state is reliable (real-time sync test)
      //  • Workout count assertions (e.g. '3') aren't skewed by previous tests
      //  • Data from earlier tests doesn't appear in later test navigation
      final workoutsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(testData.userId)
          .collection('programs')
          .doc(testData.programId)
          .collection('weeks')
          .doc(testData.weekId)
          .collection('workouts');
      final existing = await workoutsRef.get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
    });

    group('Complete Workout Creation Workflow', () {
      testWidgets('create workout with all fields through full app navigation', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify the complete end-to-end workout creation workflow
        /// This test simulates a real user journey:
        /// 1. Launch app (already authenticated)
        /// 2. Navigate to Programs → Program Detail → Week → Create Workout
        /// 3. Fill out complete workout form
        /// 4. Save workout and verify it appears in the list
        /// 5. Verify data is persisted in Firestore
        /// 
        /// This is the most critical test - if this passes, the core functionality works!
        
        print('\n📱 Testing complete workout creation workflow...');

        // Step 1: Launch the app
        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);
        print('✅ App launched');

        // Step 3: Find and tap the test program
        final programTile = find.text('Integration Test Program');
        expect(programTile, findsOneWidget,
          reason: 'Should find the seeded test program');
        
        await tester.tap(programTile);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        print('✅ Navigated to program detail');

        // Step 4: Navigate to program detail and find test week
        expect(find.byType(ProgramDetailScreen), findsOneWidget,
          reason: 'Should be on program detail screen');

        final weekTile = find.text('Integration Test Week');
        expect(weekTile, findsOneWidget,
          reason: 'Should find the seeded test week');

        await tester.tap(weekTile);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        print('✅ Navigated to week detail');

        // Step 5: Verify we're on the weeks screen and it shows empty state
        expect(find.byType(WeeksScreen), findsOneWidget,
          reason: 'Should be on weeks screen');

        expect(find.text('No Workouts Yet'), findsOneWidget,
          reason: 'Should show empty state for new week');

        // Step 6: Tap FAB to create workout
        final createWorkoutFAB = find.byType(FloatingActionButton);
        expect(createWorkoutFAB, findsOneWidget,
          reason: 'Should have create workout FAB');

        await tester.tap(createWorkoutFAB);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
        if (find.text('Start Fresh').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start Fresh'));
          await tester.pumpAndSettle();
        }

        print('✅ Navigated to create workout screen');

        // Step 7: Verify we're on create workout screen
        expect(find.byType(CreateWorkoutScreen), findsOneWidget,
          reason: 'Should be on create workout screen');

        expect(find.text('Create Workout'), findsOneWidget,
          reason: 'Should show create workout title');

        // Step 8: Fill out workout form with all fields
        // Wait for form to fully render on slow emulators before accessing fields.
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byType(TextFormField), findsWidgets,
            reason: 'Workout form must be rendered before entering data');

        // Fill workout name
        final nameField = find.widgetWithText(TextFormField, '').first;
        await tester.enterText(nameField, 'Upper Body Strength Training');
        print('✅ Entered workout name');

        // Select day of week (Tuesday)
        final dayDropdown = find.byType(DropdownButtonFormField<int?>);
        await tester.tap(dayDropdown);
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Tuesday').last);
        await tester.pumpAndSettle();
        print('✅ Selected day of week');

        // Add notes
        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'Focus on progressive overload and proper form');
        print('✅ Added workout notes');

        // Step 9: Save the workout
        final saveButton = find.text('CREATE');
        expect(saveButton, findsOneWidget,
          reason: 'Should have save button');

        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('✅ Submitted workout creation form');

        // Step 10: Verify success feedback and navigation back to weeks screen
        expect(find.text('Workout created successfully!'), findsOneWidget,
          reason: 'Should show success message');

        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.byType(WeeksScreen), findsOneWidget,
          reason: 'Should navigate back to weeks screen');

        // Step 11: Verify the workout appears in the list
        expect(find.text('Upper Body Strength Training'), findsOneWidget,
          reason: 'Should display the created workout in the list');

        expect(find.text('Tuesday'), findsOneWidget,
          reason: 'Should display the workout day');

        expect(find.textContaining('Focus on progressive overload'), findsOneWidget,
          reason: 'Should display workout notes');

        print('✅ Workout displayed in list');

        // Step 12: Verify data persistence in Firestore
        await FirebaseEmulatorSetup.waitForFirestoreSync();
        
        final workoutsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(testData.userId)
            .collection('programs') 
            .doc(testData.programId)
            .collection('weeks')
            .doc(testData.weekId)
            .collection('workouts')
            .get();

        expect(workoutsSnapshot.docs, hasLength(1),
          reason: 'Should have exactly one workout in Firestore');

        final workoutData = workoutsSnapshot.docs.first.data();
        expect(workoutData['name'], equals('Upper Body Strength Training'),
          reason: 'Workout name should be persisted correctly');
        expect(workoutData['dayOfWeek'], equals(2),
          reason: 'Day of week should be persisted correctly');
        expect(workoutData['notes'], equals('Focus on progressive overload and proper form'),
          reason: 'Notes should be persisted correctly');
        expect(workoutData['userId'], equals(testData.userId),
          reason: 'User ID should be set correctly for security');

        print('✅ Workout data verified in Firestore');
        print('🎉 Complete workout creation workflow test PASSED!\n');
      });

      testWidgets('create workout with minimal data (name only)', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify workout creation works with only required fields
        /// Users should be able to create simple workouts quickly without filling all fields
        /// This tests the "quick creation" use case and optional field handling
        
        print('\n📱 Testing minimal workout creation...');

        // Launch app and navigate to create workout screen
        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);

        // Navigate through the app to create workout screen
        // (Similar navigation steps as above, condensed for brevity)
        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
        if (find.text('Start Fresh').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start Fresh'));
          await tester.pumpAndSettle();
        }

        // Fill only the required name field
        expect(find.byType(TextFormField), findsWidgets,
            reason: 'Workout form must be rendered before entering data');
        final nameField = find.widgetWithText(TextFormField, '').first;
        await tester.enterText(nameField, 'Quick Workout');

        // Save without filling optional fields
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify success and workout appears
        expect(find.text('Workout created successfully!'), findsOneWidget,
          reason: 'Should succeed with minimal data');

        await tester.pumpAndSettle();

        expect(find.text('Quick Workout'), findsOneWidget,
          reason: 'Should display workout with minimal data');

        // Verify Firestore data has null values for optional fields
        await FirebaseEmulatorSetup.waitForFirestoreSync();
        
        final workoutsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(testData.userId)
            .collection('programs')
            .doc(testData.programId)
            .collection('weeks')
            .doc(testData.weekId)
            .collection('workouts')
            .where('name', isEqualTo: 'Quick Workout')
            .get();

        expect(workoutsSnapshot.docs, hasLength(1));
        
        final workoutData = workoutsSnapshot.docs.first.data();
        expect(workoutData['dayOfWeek'], isNull,
          reason: 'Optional dayOfWeek should be null when not provided');
        expect(workoutData['notes'], isNull,
          reason: 'Optional notes should be null when not provided');

        print('✅ Minimal workout creation test PASSED!\n');
      });

      testWidgets('handles workout creation errors gracefully', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify error handling when workout creation fails
        /// This simulates network issues, validation errors, or permission problems
        /// Users should get clear feedback when operations fail
        
        print('\n📱 Testing workout creation error handling...');

        // Launch app and navigate to create workout screen
        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);

        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
        if (find.text('Start Fresh').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start Fresh'));
          await tester.pumpAndSettle();
        }

        // Test validation error - try to save without entering name
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Should show validation error, not navigate away
        expect(find.text('Please enter a workout name'), findsOneWidget,
          reason: 'Should show validation error for empty name');

        expect(find.byType(CreateWorkoutScreen), findsOneWidget,
          reason: 'Should remain on create workout screen when validation fails');

        // Test name too long validation
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byType(TextFormField), findsWidgets,
            reason: 'Workout form must be rendered before entering data');
        final nameField = find.widgetWithText(TextFormField, '').first;
        final tooLongName = 'A' * 201; // Exceeds 200 character limit
        await tester.enterText(nameField, tooLongName);

        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        expect(find.text('Workout name must be 200 characters or less'), findsOneWidget,
          reason: 'Should show validation error for name too long');

        print('✅ Workout creation error handling test PASSED!\n');
      });
    });

    group('Multiple Workouts Management', () {
      testWidgets('create multiple workouts and verify list ordering', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify multiple workout creation and list management
        /// Users typically create several workouts per week - list should handle this correctly
        /// Tests ordering, display, and data consistency with multiple items
        
        print('\n📱 Testing multiple workouts creation and management...');

        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);

        // Navigate to weeks screen
        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle();

        final workoutNames = ['Push Day', 'Pull Day', 'Leg Day'];
        
        // Create multiple workouts
        for (int i = 0; i < workoutNames.length; i++) {
          print('Creating workout ${i + 1}: ${workoutNames[i]}');
          
          // Tap FAB to create workout
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
          if (find.text('Start Fresh').evaluate().isNotEmpty) {
            await tester.tap(find.text('Start Fresh'));
            await tester.pumpAndSettle();
          }

          // Fill workout name
          expect(find.byType(TextFormField), findsWidgets,
              reason: 'Workout form must be rendered before entering data');
          final nameField = find.widgetWithText(TextFormField, '').first;
          await tester.enterText(nameField, workoutNames[i]);

          // Save workout
          await tester.tap(find.text('CREATE'));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Verify success and return to weeks screen
          expect(find.text('Workout created successfully!'), findsOneWidget);
          await tester.pumpAndSettle();
        }

        // Wait for the Firestore stream to deliver all created workouts (up to 20 s).
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.text(workoutNames.last).evaluate().isNotEmpty) break;
        }

        // Verify all workouts appear in the list
        for (final name in workoutNames) {
          expect(find.text(name), findsOneWidget,
            reason: 'Should display workout: $name');
        }

        // Verify workout count is updated
        expect(find.text('3'), findsAtLeastNWidgets(1),
          reason: 'Should show correct workout count (3) in header');

        // Verify no empty state is shown
        expect(find.text('No Workouts Yet'), findsNothing,
          reason: 'Should not show empty state when workouts exist');

        print('✅ Multiple workouts management test PASSED!\n');
      });
    });

    group('Data Persistence and Reload', () {
      testWidgets('workout data persists across app restarts', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify workout data survives app restarts
        /// Users expect their workouts to be saved permanently
        /// This tests offline/online sync and data persistence
        
        print('\n📱 Testing workout data persistence across app restarts...');

        // First app session - create a workout
        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);

        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
        if (find.text('Start Fresh').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start Fresh'));
          await tester.pumpAndSettle();
        }

        const persistentWorkoutName = 'Persistent Test Workout';
        expect(find.byType(TextFormField), findsWidgets,
            reason: 'Workout form must be rendered before entering data');
        final nameField = find.widgetWithText(TextFormField, '').first;
        await tester.enterText(nameField, persistentWorkoutName);

        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify workout was created
        expect(find.text(persistentWorkoutName), findsOneWidget);
        print('✅ Workout created in first app session');

        // Wait for Firestore sync
        await FirebaseEmulatorSetup.waitForFirestoreSync();

        // Simulate app restart by creating new app instance
        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        // Reuse prefs variable from earlier in test scope
        await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);

        // Navigate back to the weeks screen
        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Wait for Firestore stream to deliver the workout list after restart (up to 20 s).
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.text(persistentWorkoutName).evaluate().isNotEmpty) break;
        }

        // Verify workout data persisted across restart
        expect(find.text(persistentWorkoutName), findsOneWidget,
          reason: 'Workout should persist across app restarts');

        print('✅ Workout persistence test PASSED!\n');
      });
    });

    group('Security and Authorization', () {
      testWidgets('workouts are isolated per user', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify user data isolation and security
        /// Users should only see their own workouts, never other users' data
        /// This tests the security model implementation
        
        print('\n📱 Testing user data isolation and security...');

        // Create a second test user
        final secondUser = await FirebaseEmulatorSetup.createTestUser(
          email: 'second-user@example.com',
          password: 'testpassword456',
        );

        // Seed data for second user
        final secondUserData = await FirebaseEmulatorSetup.seedTestData(
          secondUser.user!.uid);

        // Sign in as second user and create workout
        // NOTE: Must sign out to switch users, then wait for auth state to propagate
        await FirebaseAuth.instance.signOut();

        // Wait for sign-out to complete and active listeners to be cancelled
        // This prevents PERMISSION_DENIED errors on previous user's listeners
        await Future.delayed(const Duration(milliseconds: 500));

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'second-user@example.com',
          password: 'testpassword456',
        );
        // Force token refresh so Firestore SDK has auth credentials before pumpWidget
        await FirebaseAuth.instance.currentUser?.getIdToken(true);

        // Wait for sign-in to complete and propagate to providers
        await Future.delayed(const Duration(milliseconds: 500));

        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(
          tester,
          email: 'second-user@example.com',
          password: 'testpassword456',
        );

        // Navigate and create workout as second user
        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
        if (find.text('Start Fresh').evaluate().isNotEmpty) {
          await tester.tap(find.text('Start Fresh'));
          await tester.pumpAndSettle();
        }

        const secondUserWorkout = 'Second User Workout';
        expect(find.byType(TextFormField), findsWidgets,
            reason: 'Workout form must be rendered before entering data');
        final nameField = find.widgetWithText(TextFormField, '').first;
        await tester.enterText(nameField, secondUserWorkout);

        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text(secondUserWorkout), findsOneWidget);
        print('✅ Second user workout created');

        // Switch back to first user
        // NOTE: Must sign out to switch users, then wait for auth state to propagate
        await FirebaseAuth.instance.signOut();

        // Wait for sign-out to complete and active listeners to be cancelled
        // This prevents PERMISSION_DENIED errors on previous user's listeners
        await Future.delayed(const Duration(milliseconds: 500));

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'workout-test@example.com',
          password: 'testpassword123',
        );
        // Force token refresh so Firestore SDK has auth credentials before pumpWidget
        await FirebaseAuth.instance.currentUser?.getIdToken(true);

        // Wait for sign-in to complete and propagate to providers
        await Future.delayed(const Duration(milliseconds: 500));

        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs2 = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs2));
        await _ensureOnProgramsScreen(tester);

        // Navigate to first user's workouts
        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify first user cannot see second user's workout
        expect(find.text(secondUserWorkout), findsNothing,
          reason: 'Users should not see other users\' workouts');

        print('✅ User data isolation test PASSED!\n');
      });
    });

    group('Real-time Data Sync', () {
      testWidgets('workout list updates in real-time when data changes', 
          (WidgetTester tester) async {
        /// Test Purpose: Verify real-time sync functionality
        /// When data changes in Firestore, the UI should update automatically
        /// This tests the stream-based data loading implementation
        
        print('\n📱 Testing real-time data synchronization...');

        // Initialize SharedPreferences for testing
        SharedPreferences.setMockInitialValues({'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
        await _ensureOnProgramsScreen(tester);

        // Navigate to weeks screen
        await tester.tap(find.text('Integration Test Program'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Integration Test Week'));
        await tester.pumpAndSettle();

        // Verify initial empty state
        expect(find.text('No Workouts Yet'), findsOneWidget);

        // Directly add workout to Firestore (simulating external change)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(testData.userId)
            .collection('programs')
            .doc(testData.programId)
            .collection('weeks')
            .doc(testData.weekId)
            .collection('workouts')
            .add({
          'name': 'Real-time Sync Workout',
          'dayOfWeek': null,
          'orderIndex': 1,
          'notes': null,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'userId': testData.userId,
          'weekId': testData.weekId,
          'programId': testData.programId,
        });

        print('✅ Added workout directly to Firestore');

        // Wait for real-time update to propagate
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify workout appears in UI automatically
        expect(find.text('Real-time Sync Workout'), findsOneWidget,
          reason: 'UI should update automatically when Firestore data changes');

        expect(find.text('No Workouts Yet'), findsNothing,
          reason: 'Empty state should disappear when workouts exist');

        print('✅ Real-time data sync test PASSED!\n');
      });
    });
  });
}

/// Additional test helper methods can be added here for common operations
/// like navigating to specific screens, creating test workouts, etc.

/// Wait for auth state to propagate and assert the app is on ProgramsScreen.
///
/// This mirrors the `_ensureSignedIn` pattern from the analytics tests.
/// After pumping the widget, the AuthProvider's `authStateChanges()` listener
/// fires asynchronously (it calls `await user.reload()` internally). On a slow
/// CI Android emulator the round-trip can exceed the naive pump window,
/// leaving the app on SignInScreen.  This helper:
///   1. Pumps for 3 s to let the auth listener complete.
///   2. If still on SignInScreen, signs back in via Firebase Auth directly
///      using the supplied [email]/[password] credentials.
///   3. Polls up to 20 s for ProgramsScreen to appear.
///   4. Polls up to 20 s for the seeded 'Integration Test Program' to appear.
///
/// Pass [email] and [password] when calling from a test that has signed in as
/// a user other than the default 'workout-test@example.com' (e.g. the
/// isolation test that operates as 'second-user@example.com').
Future<void> _ensureOnProgramsScreen(
  WidgetTester tester, {
  String email = 'workout-test@example.com',
  String password = 'testpassword123',
}) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();

  if (find.text('Sign In').evaluate().isNotEmpty) {
    print('DEBUG [_ensureOnProgramsScreen]: On SignInScreen — signing in as $email');
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Force token refresh so Firestore SDK has auth token before UI renders
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  // Poll for ProgramsScreen — auth state propagation to the widget tree is
  // async and may lag behind pumpWidget on a slow CI emulator (up to 20 s).
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(ProgramsScreen).evaluate().isNotEmpty) break;
  }

  expect(
    find.byType(ProgramsScreen), findsOneWidget,
    reason: 'Should be on ProgramsScreen for authenticated user',
  );

  // ProgramsScreen is visible but ProgramProvider's Firestore query may still
  // be in-flight. Poll up to 20 s for the seeded program to appear before
  // returning, so tests can immediately tap the program tile.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('Integration Test Program').evaluate().isNotEmpty) break;
  }

  expect(
    find.text('Integration Test Program'), findsOneWidget,
    reason: 'Seeded program should be visible after Firestore load',
  );
}

/// Helper method to navigate through the complete app flow to create workout screen
/// This reduces duplication in tests that need to reach the create workout screen
Future<void> navigateToCreateWorkoutScreen(
    WidgetTester tester, TestDataSeeds testData) async {
  
  await tester.tap(find.text(testData.programName));
  await tester.pumpAndSettle();
  
  await tester.tap(find.text(testData.weekName));
  await tester.pumpAndSettle();

  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // Handle CreateOptionsSheet - tap "Start Fresh" to proceed to form
  if (find.text('Start Fresh').evaluate().isNotEmpty) {
    await tester.tap(find.text('Start Fresh'));
    await tester.pumpAndSettle();
  }
}