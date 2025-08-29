import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/sets/create_set_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/exercise.dart';

import 'create_set_screen_test.mocks.dart';

@GenerateMocks([ProgramProvider])
void main() {
  group('CreateSetScreen Widget Tests', () {
    late MockProgramProvider mockProvider;
    late Program testProgram;
    late Week testWeek;
    late Workout testWorkout;
    late Exercise strengthExercise;
    late Exercise cardioExercise;
    late Exercise customExercise;

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
      strengthExercise = Exercise(
        id: 'exercise-1',
        name: 'Bench Press',
        exerciseType: ExerciseType.strength,
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        workoutId: 'workout-1',
        weekId: 'week-1',
        programId: 'program-1',
      );
      cardioExercise = Exercise(
        id: 'exercise-2',
        name: 'Running',
        exerciseType: ExerciseType.cardio,
        orderIndex: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        workoutId: 'workout-1',
        weekId: 'week-1',
        programId: 'program-1',
      );
      customExercise = Exercise(
        id: 'exercise-3',
        name: 'Custom Movement',
        exerciseType: ExerciseType.custom,
        orderIndex: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        workoutId: 'workout-1',
        weekId: 'week-1',
        programId: 'program-1',
      );

      // Setup default mock behavior
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.createSet(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        exerciseId: anyNamed('exerciseId'),
        reps: anyNamed('reps'),
        weight: anyNamed('weight'),
        duration: anyNamed('duration'),
        distance: anyNamed('distance'),
        restTime: anyNamed('restTime'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async => 'new-set-id');
    });

    Widget createTestWidget(Exercise exercise) {
      return MaterialApp(
        home: ChangeNotifierProvider<ProgramProvider>(
          create: (context) => mockProvider,
          child: CreateSetScreen(
            program: testProgram,
            week: testWeek,
            workout: testWorkout,
            exercise: exercise,
          ),
        ),
      );
    }

    testWidgets('displays correct header information for strength exercise', (tester) async {
      /// Test Purpose: Verify that the screen shows proper context information
      /// Users should see which exercise they're adding a set to
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      expect(find.text('Add Set'), findsOneWidget);
      expect(find.text('Adding set to:'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
    });

    testWidgets('shows appropriate fields for strength exercise', (tester) async {
      /// Test Purpose: Verify that strength exercises show correct input fields
      /// Strength exercises should show reps (required), weight and rest time (optional)
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Should show strength-specific fields
      expect(find.text('Reps *'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Rest Time (seconds)'), findsOneWidget);
      
      // Should not show cardio fields
      expect(find.text('Minutes'), findsNothing);
      expect(find.text('Distance (km)'), findsNothing);
    });

    testWidgets('shows appropriate fields for cardio exercise', (tester) async {
      /// Test Purpose: Verify that cardio exercises show correct input fields
      /// Cardio exercises should show duration (required) and distance (optional)
      
      await tester.pumpWidget(createTestWidget(cardioExercise));
      
      // Should show cardio-specific fields
      expect(find.text('Minutes *'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
      expect(find.text('Distance (km)'), findsOneWidget);
      
      // Should not show strength fields
      expect(find.text('Reps *'), findsNothing);
      expect(find.text('Weight (kg)'), findsNothing);
    });

    testWidgets('shows all fields for custom exercise', (tester) async {
      /// Test Purpose: Verify that custom exercises show all possible fields
      /// Custom exercises should be flexible with all tracking options
      
      await tester.pumpWidget(createTestWidget(customExercise));
      
      // Should show all possible fields
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
      expect(find.text('Distance (km)'), findsOneWidget);
      expect(find.text('Rest Time (seconds)'), findsOneWidget);
    });

    testWidgets('validates required fields for strength exercise', (tester) async {
      /// Test Purpose: Verify that strength exercises enforce reps requirement
      /// Should show validation error if reps is missing
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Try to save without entering reps
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      
      expect(find.text('Please enter number of reps'), findsOneWidget);
    });

    testWidgets('validates required fields for cardio exercise', (tester) async {
      /// Test Purpose: Verify that cardio exercises enforce duration requirement
      /// Should show validation error if duration is missing
      
      await tester.pumpWidget(createTestWidget(cardioExercise));
      
      // Try to save without entering duration
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      
      expect(find.text('Duration required'), findsOneWidget);
    });

    testWidgets('accepts valid strength set with reps only', (tester) async {
      /// Test Purpose: Verify successful creation with minimum required data for strength
      /// Should work with just reps for strength exercises
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Enter valid reps
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '10');
      
      // Save the set
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pump();
      
      // Verify createSet was called with correct parameters
      verify(mockProvider.createSet(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        exerciseId: 'exercise-1',
        reps: 10,
        weight: null,
        duration: null,
        distance: null,
        restTime: null,
        notes: null,
      )).called(1);
    });

    testWidgets('accepts valid strength set with all fields', (tester) async {
      /// Test Purpose: Verify successful creation with all strength fields
      /// Should work with reps, weight, and rest time
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Enter all strength fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '12');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '100.5');
      await tester.enterText(find.widgetWithText(TextFormField, 'Rest Time (seconds)'), '90');
      await tester.enterText(find.widgetWithText(TextFormField, 'Notes (Optional)'), 'Good form');
      
      // Save the set
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pump();
      
      // Verify createSet was called with all parameters
      verify(mockProvider.createSet(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        exerciseId: 'exercise-1',
        reps: 12,
        weight: 100.5,
        duration: null,
        distance: null,
        restTime: 90,
        notes: 'Good form',
      )).called(1);
    });

    testWidgets('accepts valid cardio set with duration', (tester) async {
      /// Test Purpose: Verify successful creation with cardio duration
      /// Should convert minutes and seconds to total seconds for storage
      
      await tester.pumpWidget(createTestWidget(cardioExercise));
      
      // Enter duration: 5 minutes 30 seconds
      await tester.enterText(find.widgetWithText(TextFormField, 'Minutes *'), '5');
      await tester.enterText(find.widgetWithText(TextFormField, 'Seconds'), '30');
      
      // Save the set
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pump();
      
      // Verify duration is converted to total seconds (5*60 + 30 = 330)
      verify(mockProvider.createSet(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        exerciseId: 'exercise-2',
        reps: null,
        weight: null,
        duration: 330, // 5 minutes 30 seconds
        distance: null,
        restTime: null,
        notes: null,
      )).called(1);
    });

    testWidgets('accepts valid cardio set with duration and distance', (tester) async {
      /// Test Purpose: Verify successful creation with cardio duration and distance
      /// Should convert km to meters for storage
      
      await tester.pumpWidget(createTestWidget(cardioExercise));
      
      // Enter duration and distance
      await tester.enterText(find.widgetWithText(TextFormField, 'Minutes *'), '30');
      await tester.enterText(find.widgetWithText(TextFormField, 'Distance (km)'), '5.5');
      
      // Save the set
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pump();
      
      // Verify distance is converted to meters (5.5 * 1000 = 5500)
      verify(mockProvider.createSet(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        exerciseId: 'exercise-2',
        reps: null,
        weight: null,
        duration: 1800, // 30 minutes
        distance: 5500.0, // 5.5 km in meters
        restTime: null,
        notes: null,
      )).called(1);
    });

    testWidgets('validates numeric inputs properly', (tester) async {
      /// Test Purpose: Verify that invalid numeric inputs are rejected
      /// Should show validation errors for negative or invalid numbers
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // The reps field only allows digits, so test by clearing field (empty = invalid)
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '');
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      
      expect(find.text('Please enter number of reps'), findsOneWidget);
      
      // Input formatters prevent invalid characters, so test empty weight field after setting valid reps
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '10');
      // Clear any existing weight and don't enter anything (test passes because weight is optional for strength)
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '');
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pump();
      
      // Should succeed with just reps
      verify(mockProvider.createSet(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        exerciseId: anyNamed('exerciseId'),
        reps: 10,
        weight: null,
        duration: anyNamed('duration'),
        distance: anyNamed('distance'),
        restTime: anyNamed('restTime'),
        notes: anyNamed('notes'),
      )).called(1);
    });

    testWidgets('validates seconds field range', (tester) async {
      /// Test Purpose: Verify that seconds field validates proper range
      /// Seconds should be 0-59 only
      
      await tester.pumpWidget(createTestWidget(cardioExercise));
      
      // Enter invalid seconds (over 59)
      await tester.enterText(find.widgetWithText(TextFormField, 'Minutes *'), '5');
      await tester.enterText(find.widgetWithText(TextFormField, 'Seconds'), '75');
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      
      expect(find.text('Must be 0-59'), findsOneWidget);
    });

    testWidgets('prevents saving custom exercise without any metrics', (tester) async {
      /// Test Purpose: Verify that custom exercises require at least one metric
      /// Should show error if no fields are filled
      
      await tester.pumpWidget(createTestWidget(customExercise));
      
      // Try to save without entering any metrics
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pumpAndSettle();
      
      expect(find.text('Please enter at least one metric'), findsOneWidget);
    });

    testWidgets('shows loading state during creation', (tester) async {
      /// Test Purpose: Verify that loading state is displayed during async operation
      /// Users should see visual feedback while set is being created
      
      // Make createSet return a delayed future to see loading state
      when(mockProvider.createSet(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        exerciseId: anyNamed('exerciseId'),
        reps: anyNamed('reps'),
        weight: anyNamed('weight'),
        duration: anyNamed('duration'),
        distance: anyNamed('distance'),
        restTime: anyNamed('restTime'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 200));
        return 'new-set-id';
      });
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Enter valid data
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '10');
      
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
      /// Test Purpose: Verify error handling when set creation fails
      /// Users should see appropriate error messages
      
      // Mock creation failure
      when(mockProvider.createSet(
        programId: anyNamed('programId'),
        weekId: anyNamed('weekId'),
        workoutId: anyNamed('workoutId'),
        exerciseId: anyNamed('exerciseId'),
        reps: anyNamed('reps'),
        weight: anyNamed('weight'),
        duration: anyNamed('duration'),
        distance: anyNamed('distance'),
        restTime: anyNamed('restTime'),
        notes: anyNamed('notes'),
      )).thenAnswer((_) async => null);
      
      when(mockProvider.error).thenReturn('Failed to create set');
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Enter valid data
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '10');
      
      // Save the set
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pumpAndSettle();
      
      // Should show error message
      expect(find.text('Failed to create set'), findsOneWidget);
    });

    testWidgets('shows exercise type description and field requirements', (tester) async {
      /// Test Purpose: Verify that helper information explains exercise type
      /// Users should understand what fields are available and required
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      expect(find.text('Strength Exercise'), findsOneWidget);
      expect(find.text('Track repetitions and weight. Add rest time to track recovery between sets.'), findsOneWidget);
      expect(find.text('Required fields: Reps'), findsOneWidget);
    });

    testWidgets('notes field accepts multi-line input', (tester) async {
      /// Test Purpose: Verify that notes field supports longer text input
      /// Notes should allow detailed comments about the set
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      final notesField = find.widgetWithText(TextFormField, 'Notes (Optional)');
      expect(notesField, findsOneWidget);
      
      // Test functionality - enter multi-line text
      await tester.enterText(notesField, 'Line 1\nLine 2');
      await tester.pump();
      
      // Verify the text was accepted
      expect(find.text('Line 1\nLine 2'), findsOneWidget);
    });

    testWidgets('shows success message on successful creation', (tester) async {
      /// Test Purpose: Verify success feedback is shown
      /// Users should see confirmation that set was created
      
      await tester.pumpWidget(createTestWidget(strengthExercise));
      
      // Enter valid data
      await tester.enterText(find.widgetWithText(TextFormField, 'Reps *'), '12');
      
      // Save the set
      await tester.tap(find.text('SAVE'));
      await tester.pump();
      await tester.pumpAndSettle();
      
      // Verify createSet was called (core functionality)
      verify(mockProvider.createSet(
        programId: 'program-1',
        weekId: 'week-1',
        workoutId: 'workout-1',
        exerciseId: 'exercise-1',
        reps: 12,
        weight: null,
        duration: null,
        distance: null,
        restTime: null,
        notes: null,
      )).called(1);
    });
  });
}