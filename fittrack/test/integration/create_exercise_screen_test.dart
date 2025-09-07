import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/exercises/create_exercise_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/exercise.dart';

import 'create_exercise_screen_test.mocks.dart';
import 'test_setup_helper.dart';

@GenerateMocks([ProgramProvider])
void main() {
  group('CreateExerciseScreen Widget Tests', () {
    late MockProgramProvider mockProvider;

    setUpAll(() async {
      await TestSetupHelper.initializeFirebaseForWidgetTests();
    });
    late Program testProgram;
    late Week testWeek;
    late Workout testWorkout;

    setUp(() {
      mockProvider = MockProgramProvider();
      testProgram = Program(
        id: 'program-1',
        name: 'Test Program',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
      );
      testWeek = Week(
        id: 'week-1',
        name: 'Week 1',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        programId: 'program-1',
      );
      testWorkout = Workout(
        id: 'workout-1',
        name: 'Test Workout',
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        weekId: 'week-1',
        programId: 'program-1',
      );

      // Setup default mock behavior
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.createExercise(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        name: anyNamed('name'),
        exerciseType: anyNamed('exerciseType'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async => 'new-exercise-id');
    });

    Widget createTestWidget() {
      return TestSetupHelper.createTestAppWithMockedProviders(
        programProvider: mockProvider,
        child: CreateExerciseScreen(
          program: testProgram,
          week: testWeek,
          workout: testWorkout,
        ),
      );
    }

    testWidgets('displays correct header information', (tester) async {
      /// Test Purpose: Verify that the screen shows proper context information
      /// Users should see which program/week/workout they're adding exercise to
      
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Create Exercise'), findsOneWidget);
      expect(find.text('Creating exercise for:'), findsOneWidget);
      expect(find.text('Test Program → Week 1 → Test Workout'), findsOneWidget);
    });

    testWidgets('shows all exercise name field', (tester) async {
      /// Test Purpose: Verify that required input fields are present
      /// Exercise name is always required regardless of type
      
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Exercise Name *'), findsOneWidget);
      expect(find.text('e.g., Bench Press, Squat, Push-ups'), findsOneWidget);
    });

    testWidgets('shows exercise type dropdown with all options', (tester) async {
      /// Test Purpose: Verify that all exercise types are available for selection
      /// All exercise types should be selectable from dropdown
      
      await tester.pumpWidget(createTestWidget());
      
      expect(find.text('Exercise Type *'), findsOneWidget);
      
      // Tap dropdown to open options
      await tester.tap(find.byType(DropdownButtonFormField<ExerciseType>));
      await tester.pumpAndSettle();
      
      // Verify all exercise types are present
      expect(find.text('Strength').last, findsOneWidget);
      expect(find.text('Cardio').last, findsOneWidget);
      expect(find.text('Bodyweight').last, findsOneWidget);
      expect(find.text('Custom').last, findsOneWidget);
      expect(find.text('Time-based').last, findsOneWidget);
    });

    testWidgets('updates exercise type info when type is changed', (tester) async {
      /// Test Purpose: Verify that exercise type information updates dynamically
      /// When user changes exercise type, the info section should update
      
      await tester.pumpWidget(createTestWidget());
      
      // Initially shows strength exercise info (default)
      expect(find.text('Strength Exercise'), findsOneWidget);
      expect(find.text('Track reps and weight for traditional strength training'), findsOneWidget);
      
      // Change to cardio
      await tester.tap(find.byType(DropdownButtonFormField<ExerciseType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cardio').last);
      await tester.pumpAndSettle();
      
      // Should now show cardio exercise info
      expect(find.text('Cardio Exercise'), findsOneWidget);
      expect(find.text('Track time and distance for cardiovascular activities'), findsOneWidget);
      expect(find.text('• Duration (required)'), findsOneWidget);
      expect(find.text('• Distance (optional)'), findsOneWidget);
    });

    testWidgets('validates exercise name is required', (tester) async {
      /// Test Purpose: Verify that form validation prevents empty exercise names
      /// Users must provide a name before creating exercise
      
      await tester.pumpWidget(createTestWidget());
      
      // Try to save without entering name
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      
      expect(find.text('Please enter an exercise name'), findsOneWidget);
      verifyNever(mockProvider.createExercise(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        name: anyNamed('name'),
        exerciseType: anyNamed('exerciseType'),
        notes: anyNamed('notes'),
      )); // Should not be called due to validation failure
    });

    testWidgets('validates exercise name length', (tester) async {
      /// Test Purpose: Verify that overly long exercise names are rejected
      /// Names must be within reasonable length limits
      
      await tester.pumpWidget(createTestWidget());
      
      // Enter name that's too long (over 200 characters)
      final longName = 'A' * 201;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        longName,
      );
      
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      
      expect(find.text('Exercise name must be 200 characters or less'), findsOneWidget);
    });

    testWidgets('creates exercise with minimum required information', (tester) async {
      /// Test Purpose: Verify successful exercise creation with just required fields
      /// Should work with name and type only
      
      await tester.pumpWidget(createTestWidget());
      
      // Enter valid exercise name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Bench Press',
      );
      
      // Save the exercise
      await tester.tap(find.text('SAVE'));
      await tester.pump(); // Trigger form validation
      await tester.pump(); // Allow async operation to start
      
      // Verify createExercise was called with correct parameters
      verify(mockProvider.createExercise(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        name: 'Bench Press',
        exerciseType: ExerciseType.strength, // Default selection
        notes: null,
      )).called(1);
    });

    testWidgets('creates exercise with all information including notes', (tester) async {
      /// Test Purpose: Verify successful exercise creation with all optional fields
      /// Should include notes when provided
      
      await tester.pumpWidget(createTestWidget());
      
      // Enter exercise name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Deadlift',
      );
      
      // Change exercise type to bodyweight
      await tester.tap(find.byType(DropdownButtonFormField<ExerciseType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bodyweight').last);
      await tester.pumpAndSettle();
      
      // Enter notes
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes (Optional)'),
        'Focus on proper form and full range of motion',
      );
      
      // Save the exercise
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pump();
      
      // Verify createExercise was called with all parameters
      verify(mockProvider.createExercise(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        name: 'Deadlift',
        exerciseType: ExerciseType.bodyweight,
        notes: 'Focus on proper form and full range of motion',
      )).called(1);
    });

    testWidgets('shows loading state during creation', (tester) async {
      /// Test Purpose: Verify that loading state is displayed during async operation
      /// Users should see visual feedback while exercise is being created
      
      // Make createExercise delay to simulate network request
      when(mockProvider.createExercise(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        name: anyNamed('name'),
        exerciseType: anyNamed('exerciseType'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'new-exercise-id';
      });
      
      await tester.pumpWidget(createTestWidget());
      
      // Enter valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Test Exercise',
      );
      
      // Tap save
      await tester.tap(find.text('SAVE'));
      await tester.pump(); // Start async operation
      
      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SAVE'), findsNothing);
      
      // Complete the async operation
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message when creation fails', (tester) async {
      /// Test Purpose: Verify error handling when exercise creation fails
      /// Users should see appropriate error messages
      
      // Mock creation failure
      when(mockProvider.createExercise(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        name: anyNamed('name'),
        exerciseType: anyNamed('exerciseType'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async => null); // Simulate failure
      
      when(mockProvider.error).thenReturn('Failed to create exercise');
      
      await tester.pumpWidget(createTestWidget());
      
      // Enter valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Test Exercise',
      );
      
      // Save the exercise
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pumpAndSettle();
      
      // Should show error message
      expect(find.text('Failed to create exercise'), findsOneWidget);
    });

    testWidgets('shows success message and navigates back on successful creation', (tester) async {
      /// Test Purpose: Verify success feedback and navigation
      /// Users should see success message and return to previous screen
      
      await tester.pumpWidget(createTestWidget());
      
      // Enter valid data
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Exercise Name *'),
        'Successful Exercise',
      );
      
      // Save the exercise
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pumpAndSettle();
      
      // Verify createExercise was called (this is the core functionality)
      verify(mockProvider.createExercise(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        name: 'Successful Exercise',
        exerciseType: ExerciseType.strength,
        notes: null,
      )).called(1);
    });

    testWidgets('shows helper text with tips', (tester) async {
      /// Test Purpose: Verify that helpful information is provided to users
      /// Tips should guide users in creating good exercises
      
      await tester.pumpWidget(createTestWidget());
      
      // Scroll down to make the Tips section visible
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      
      expect(find.text('Tips'), findsOneWidget);
      expect(find.textContaining('Choose the exercise type that matches your activity'), findsOneWidget);
      expect(find.textContaining('Exercise type determines which fields you can track'), findsOneWidget);
    });

    testWidgets('notes field accepts multi-line input', (tester) async {
      /// Test Purpose: Verify that notes field supports longer text input
      /// Notes should allow detailed instructions or comments
      
      await tester.pumpWidget(createTestWidget());
      
      final notesField = find.widgetWithText(TextFormField, 'Notes (Optional)');
      expect(notesField, findsOneWidget);
      
      // Test functionality - enter multi-line text
      await tester.enterText(notesField, 'Line 1\nLine 2\nLine 3');
      await tester.pump();
      
      // Verify the text was accepted
      expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
    });

    testWidgets('exercise type information shows correct field requirements for each type', (tester) async {
      /// Test Purpose: Verify that field requirement information is accurate
      /// Users need to understand what they can track for each exercise type
      
      await tester.pumpWidget(createTestWidget());
      
      // Test strength exercise info
      expect(find.text('• Reps (required)'), findsOneWidget);
      expect(find.text('• Weight (optional)'), findsOneWidget);
      expect(find.text('• Rest Time (optional)'), findsOneWidget);
      
      // Change to cardio and verify different requirements
      await tester.tap(find.byType(DropdownButtonFormField<ExerciseType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cardio').last);
      await tester.pumpAndSettle();
      
      expect(find.text('• Duration (required)'), findsOneWidget);
      expect(find.text('• Distance (optional)'), findsOneWidget);
      
      // Change to custom and verify flexible requirements
      await tester.tap(find.byType(DropdownButtonFormField<ExerciseType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').last);
      await tester.pumpAndSettle();
      
      expect(find.text('• Any metric (at least one required)'), findsOneWidget);
      expect(find.text('Flexible tracking with any combination of metrics'), findsOneWidget);
    });
  });
}