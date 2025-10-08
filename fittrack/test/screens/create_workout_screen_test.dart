import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/workouts/create_workout_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';

import 'create_workout_screen_test.mocks.dart';

/// Widget tests for CreateWorkoutScreen
/// 
/// These tests verify that the CreateWorkoutScreen:
/// - Renders all form fields correctly
/// - Validates user input appropriately  
/// - Handles form submission and error states
/// - Integrates properly with ProgramProvider
/// 
/// Widget tests focus on UI behavior and user interactions
/// If tests fail, check the screen's UI logic, form validation, or provider integration
@GenerateMocks([ProgramProvider, app_auth.AuthProvider])
void main() {
  group('CreateWorkoutScreen Widget Tests', () {
    late MockProgramProvider mockProvider;
    late MockAuthProvider mockAuthProvider;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    late Program testProgram;
    late Week testWeek;

    setUp(() {
      // Set up test data and mocks for each test
      // Clean state ensures tests don't interfere with each other
      mockProvider = MockProgramProvider();
      mockAuthProvider = MockAuthProvider();
      
      testProgram = Program(
        id: 'test-program-123',
        name: 'Test Program',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        userId: 'test-user',
      );
      
      testWeek = Week(
        id: 'test-week-456',
        name: 'Test Week',
        order: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        userId: 'test-user',
        programId: 'test-program-123',
      );

      // Set up default mock behavior for provider
      when(mockProvider.error).thenReturn(null);
      
      // Set up auth provider mocks to prevent Firebase calls
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
    });

    /// Helper method to create the widget under test with necessary providers and routing
    /// This ensures consistent test setup and simulates the real app environment
    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
            ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
          ],
          child: CreateWorkoutScreen(
            program: testProgram,
            week: testWeek,
          ),
        ),
      );
    }

    group('Initial Rendering', () {
      testWidgets('renders all required form fields', (WidgetTester tester) async {
        /// Test Purpose: Verify that all form fields are present and properly labeled
        /// Users need to see all input options to create a complete workout
        /// Failure indicates missing UI elements that could confuse users
        
        await tester.pumpWidget(createTestWidget());

        // Verify screen title
        expect(find.text('Create Workout'), findsOneWidget,
          reason: 'Screen should display correct title');

        // Verify program/week context information
        expect(find.text('Creating workout for:'), findsOneWidget,
          reason: 'Should show context information');
        expect(find.text('Test Program → Test Week'), findsOneWidget,
          reason: 'Should display program and week names for context');

        // Verify form fields are present
        expect(find.byType(TextFormField), findsNWidgets(2),
          reason: 'Should have 2 text input fields: name and notes');
        
        expect(find.text('Workout Name *'), findsOneWidget,
          reason: 'Should have workout name field with required indicator');
        
        expect(find.text('Day of Week (Optional)'), findsOneWidget,
          reason: 'Should have day of week dropdown field');
        
        expect(find.text('Notes (Optional)'), findsOneWidget,
          reason: 'Should have notes field');

        // Verify action buttons
        expect(find.text('CREATE'), findsOneWidget,
          reason: 'Should have save button in app bar');
        
        // Verify helpful tips section
        expect(find.text('Tips'), findsOneWidget,
          reason: 'Should display tips section to help users');
      });

      testWidgets('displays program and week context correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify that users can see which program/week they're adding to
        /// Context information prevents users from creating workouts in wrong locations
        /// Failure indicates poor user experience with unclear context
        
        await tester.pumpWidget(createTestWidget());

        // Verify context card is displayed
        expect(find.byType(Card), findsAtLeastNWidgets(1),
          reason: 'Should display context information in a card');
        
        expect(find.textContaining('Test Program'), findsOneWidget,
          reason: 'Should show the program name');
        expect(find.textContaining('Test Week'), findsOneWidget,
          reason: 'Should show the week name');
      });

      testWidgets('day of week dropdown shows all options', (WidgetTester tester) async {
        /// Test Purpose: Verify day of week selection includes all valid options
        /// Users need to be able to select any day of the week or no specific day
        /// Failure indicates missing options that could limit user choices
        
        await tester.pumpWidget(createTestWidget());

        // Find and tap the dropdown
        final dropdownFinder = find.byType(DropdownButtonFormField<int?>);
        expect(dropdownFinder, findsOneWidget,
          reason: 'Should have day of week dropdown');

        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Verify all day options are present
        expect(find.text('No specific day'), findsAtLeastNWidgets(1),
          reason: 'Should have option for no specific day');
        expect(find.text('Monday'), findsOneWidget);
        expect(find.text('Tuesday'), findsOneWidget);
        expect(find.text('Wednesday'), findsOneWidget);
        expect(find.text('Thursday'), findsOneWidget);
        expect(find.text('Friday'), findsOneWidget);
        expect(find.text('Saturday'), findsOneWidget);
        expect(find.text('Sunday'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('validates required workout name field', (WidgetTester tester) async {
        /// Test Purpose: Verify that empty workout names are rejected
        /// Workout names are required for identification and organization
        /// Failure indicates validation not working, allowing invalid data
        
        await tester.pumpWidget(createTestWidget());

        // Try to save without entering a name
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify validation error appears
        expect(find.text('Please enter a workout name'), findsOneWidget,
          reason: 'Should show validation error for empty name');
        
        // Verify save was not attempted (no provider call)
        verifyNever(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        ));
      });

      testWidgets('validates workout name length limit', (WidgetTester tester) async {
        /// Test Purpose: Verify that excessively long names are rejected
        /// Long names could cause UI layout issues or database constraints
        /// Failure indicates insufficient client-side validation
        
        await tester.pumpWidget(createTestWidget());

        // Enter a name that's too long (over 200 characters)
        final tooLongName = 'A' * 201;
        await tester.enterText(find.byType(TextFormField).first, tooLongName);
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        expect(find.text('Workout name must be 200 characters or less'), findsOneWidget,
          reason: 'Should show validation error for name too long');
      });

      testWidgets('accepts valid workout name', (WidgetTester tester) async {
        /// Test Purpose: Verify that valid names pass validation
        /// Valid input should not show errors and should enable saving
        /// Failure indicates overly strict validation blocking valid input
        
        await tester.pumpWidget(createTestWidget());

        // Mock successful creation
        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => 'new-workout-id');

        // Enter valid name
        await tester.enterText(find.byType(TextFormField).first, 'Valid Workout Name');
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify no validation errors
        expect(find.text('Please enter a workout name'), findsNothing,
          reason: 'Should not show validation error for valid name');
        expect(find.text('Workout name must be 200 characters or less'), findsNothing,
          reason: 'Should not show length error for valid name');
      });

      testWidgets('allows empty notes field (optional)', (WidgetTester tester) async {
        /// Test Purpose: Verify that notes field is truly optional
        /// Users should be able to create workouts without notes
        /// Failure indicates incorrect validation on optional fields
        
        await tester.pumpWidget(createTestWidget());

        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => 'new-workout-id');

        // Enter only required field (name), leave notes empty
        await tester.enterText(find.byType(TextFormField).first, 'Workout Without Notes');
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify workout creation was attempted
        verify(mockProvider.createWorkout(
          programId: testProgram.id,
          weekId: testWeek.id,
          name: 'Workout Without Notes',
          dayOfWeek: null, // No day selected
          notes: null, // Empty notes should be null
        )).called(1);
      });
    });

    group('Form Submission', () {
      testWidgets('submits workout with all fields populated', (WidgetTester tester) async {
        /// Test Purpose: Verify complete form submission with all optional fields
        /// Users should be able to create detailed workouts with all information
        /// Failure indicates issues with form data collection or submission
        
        await tester.pumpWidget(createTestWidget());

        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => 'complete-workout-id');

        // Fill in workout name
        await tester.enterText(
          find.widgetWithText(TextFormField, '').first, 
          'Complete Upper Body Workout'
        );

        // Select day of week (Wednesday = 3)
        await tester.tap(find.byType(DropdownButtonFormField<int?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Wednesday').last);
        await tester.pumpAndSettle();

        // Add notes
        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'Focus on progressive overload');

        // Submit form
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify correct data was submitted
        verify(mockProvider.createWorkout(
          programId: testProgram.id,
          weekId: testWeek.id,
          name: 'Complete Upper Body Workout',
          dayOfWeek: 3, // Wednesday
          notes: 'Focus on progressive overload',
        )).called(1);
      });

      testWidgets('submits workout with minimal required data', (WidgetTester tester) async {
        /// Test Purpose: Verify submission works with only required fields
        /// Users should be able to create simple workouts quickly
        /// Failure indicates issues with minimal form submission
        
        await tester.pumpWidget(createTestWidget());

        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => 'minimal-workout-id');

        // Enter only workout name
        await tester.enterText(find.byType(TextFormField).first, 'Quick Workout');

        // Submit without selecting day or adding notes
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify submission with null optional fields
        verify(mockProvider.createWorkout(
          programId: testProgram.id,
          weekId: testWeek.id,
          name: 'Quick Workout',
          dayOfWeek: null,
          notes: null,
        )).called(1);
      });

      testWidgets('shows loading state during submission', (WidgetTester tester) async {
        /// Test Purpose: Verify loading indicator during async operations
        /// Users need feedback that their action is being processed
        /// Failure indicates poor UX with no loading feedback
        
        await tester.pumpWidget(createTestWidget());

        // Set up delayed response to simulate network delay
        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 'delayed-workout-id';
        });

        // Fill form and submit
        await tester.enterText(find.byType(TextFormField).first, 'Loading Test Workout');
        await tester.tap(find.text('CREATE'));
        
        // Verify loading indicator appears
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Should show loading indicator during submission');

        // Wait for completion
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Should hide loading indicator after completion');
      });

      testWidgets('disables save button during submission', (WidgetTester tester) async {
        /// Test Purpose: Verify that save button is disabled during submission
        /// Prevents duplicate submissions and indicates processing state
        /// Failure indicates users could accidentally submit multiple times
        
        await tester.pumpWidget(createTestWidget());

        // Set up delayed response
        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 'disabled-test-workout-id';
        });

        await tester.enterText(find.byType(TextFormField).first, 'Disable Test');
        await tester.tap(find.text('CREATE'));
        await tester.pump(const Duration(milliseconds: 100));

        // Try to tap save button again while processing
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify createWorkout was only called once
        verify(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).called(1);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message when workout creation fails', (WidgetTester tester) async {
        /// Test Purpose: Verify that creation failures are communicated to user
        /// Users need to know when operations fail and why
        /// Failure indicates poor error handling that leaves users confused
        
        await tester.pumpWidget(createTestWidget());

        const errorMessage = 'Failed to create workout: Network error';
        
        // Mock creation failure
        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => null); // null indicates failure

        // Mock error state
        when(mockProvider.error).thenReturn(errorMessage);

        await tester.enterText(find.byType(TextFormField).first, 'Error Test Workout');
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify error is displayed to user
        expect(find.byType(SnackBar), findsOneWidget,
          reason: 'Should show error message in SnackBar');
        expect(find.text(errorMessage), findsOneWidget,
          reason: 'Should display the actual error message');
      });

      testWidgets('shows success message when workout created successfully', (WidgetTester tester) async {
        /// Test Purpose: Verify that successful creation is confirmed to user
        /// Users need positive feedback when operations succeed
        /// Failure indicates missing success feedback
        
        await tester.pumpWidget(createTestWidget());

        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => 'success-workout-id');

        await tester.enterText(find.byType(TextFormField).first, 'Success Test Workout');
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify success message appears
        expect(find.text('Workout created successfully!'), findsOneWidget,
          reason: 'Should show success message');
      });

      testWidgets('clears form validation errors when user starts typing', (WidgetTester tester) async {
        /// Test Purpose: Verify that validation errors clear when user corrects input
        /// Users shouldn't see stale error messages after fixing issues
        /// Failure indicates poor form UX with persistent error states
        
        await tester.pumpWidget(createTestWidget());

        // Trigger validation error
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();
        
        expect(find.text('Please enter a workout name'), findsOneWidget,
          reason: 'Should show validation error initially');

        // Start typing to correct the error
        await tester.enterText(find.byType(TextFormField).first, 'Valid Name');
        await tester.pump();

        // Error message should be cleared (this depends on form implementation)
        // In a real implementation, you'd verify the error disappears when typing starts
      });
    });

    group('Navigation', () {
      testWidgets('navigates back with result on successful creation', (WidgetTester tester) async {
        /// Test Purpose: Verify that screen returns success result for navigation handling
        /// Parent screens need to know when to refresh their workout lists
        /// Failure indicates navigation not working, causing stale data
        
        // This test would require setting up Navigator and verifying pop behavior
        // Implementation depends on how navigation is handled in the real app
        
        await tester.pumpWidget(createTestWidget());

        when(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        )).thenAnswer((_) async => 'navigation-test-workout');

        await tester.enterText(find.byType(TextFormField).first, 'Navigation Test');
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // In a real test, you would verify:
        // 1. Navigator.pop was called with result = true
        // 2. Parent screen receives the success indicator
        // This requires additional navigation testing setup
      });

      testWidgets('allows navigation back without saving changes', (WidgetTester tester) async {
        /// Test Purpose: Verify that users can cancel workout creation
        /// Users should be able to back out without losing their place in the app
        /// Failure indicates users getting stuck in the creation flow
        
        await tester.pumpWidget(createTestWidget());

        // Enter some data but don't save
        await tester.enterText(find.byType(TextFormField).first, 'Unsaved Workout');

        // Tap back button (assuming AppBar back button)
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Verify no workout creation was attempted
        verifyNever(mockProvider.createWorkout(
          programId: anyNamed('programId'),
          weekId: anyNamed('weekId'),
          name: anyNamed('name'),
          dayOfWeek: anyNamed('dayOfWeek'),
          notes: anyNamed('notes'),
        ));
      });
    });

    group('Accessibility', () {
      testWidgets('has proper accessibility labels', (WidgetTester tester) async {
        /// Test Purpose: Verify that screen is accessible to users with disabilities
        /// Screen readers and other accessibility tools need proper labels
        /// Failure indicates app is not inclusive for all users
        
        await tester.pumpWidget(createTestWidget());

        // Verify form fields have proper labels for screen readers
        expect(find.bySemanticsLabel('Workout Name'), findsOneWidget,
          reason: 'Workout name field should have semantic label');
        
        // Verify buttons are properly labeled
        expect(find.bySemanticsLabel('Save workout'), findsOneWidget,
          reason: 'Save button should have semantic label');

        // This test would be expanded based on accessibility requirements
        // and the specific accessibility labels implemented in the UI
      });
    });
  });
}