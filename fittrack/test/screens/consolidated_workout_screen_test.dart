import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/screens/workouts/consolidated_workout_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';

import 'create_exercise_screen_test.mocks.dart';
import '../integration/test_setup_helper.dart';

@GenerateMocks([ProgramProvider])
void main() {
  group('ConsolidatedWorkoutScreen Widget Tests', () {
    late MockProgramProvider mockProvider;
    late Program testProgram;
    late Week testWeek;
    late Workout testWorkout;

    setUpAll(() async {
      await TestSetupHelper.initializeFirebaseForWidgetTests();
    });

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
      when(mockProvider.exercises).thenReturn([]);
      when(mockProvider.isLoadingExercises).thenReturn(false);
      when(mockProvider.allWorkoutSets).thenReturn({});
    });

    Widget createTestWidget() {
      return TestSetupHelper.createTestAppWithMockedProviders(
        programProvider: mockProvider,
        child: ConsolidatedWorkoutScreen(
          program: testProgram,
          week: testWeek,
          workout: testWorkout,
        ),
      );
    }

    testWidgets('displays correct header information', (tester) async {
      /// Test Purpose: Verify screen shows proper context (program/week/workout)

      await tester.pumpWidget(createTestWidget());

      expect(find.text(testWorkout.name), findsOneWidget);
      expect(find.text('${testProgram.name} → ${testWeek.name}'), findsOneWidget);
    });

    testWidgets('shows empty state when no exercises', (tester) async {
      /// Test Purpose: Verify empty state is displayed correctly

      when(mockProvider.exercises).thenReturn([]);
      when(mockProvider.allWorkoutSets).thenReturn({});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No exercises yet'), findsOneWidget);
      expect(find.text('Add your first exercise to start building this workout'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets); // FAB + empty state button
    });

    testWidgets('shows loading indicator when loading exercises', (tester) async {
      /// Test Purpose: Verify loading state displays correctly

      when(mockProvider.exercises).thenReturn([]);
      when(mockProvider.allWorkoutSets).thenReturn({});
      when(mockProvider.isLoadingExercises).thenReturn(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays exercises when available', (tester) async {
      /// Test Purpose: Verify exercises render correctly in list

      final exercises = [
        Exercise(
          id: 'ex-1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        ),
        Exercise(
          id: 'ex-2',
          name: 'Squats',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        ),
      ];

      final sets = {
        'ex-1': [
          ExerciseSet(
            id: 'set-1',
            setNumber: 1,
            checked: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'user-1',
            exerciseId: 'ex-1',
            workoutId: 'workout-1',
            weekId: 'week-1',
            programId: 'program-1',
          ),
        ],
        'ex-2': [
          ExerciseSet(
            id: 'set-2',
            setNumber: 1,
            checked: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userId: 'user-1',
            exerciseId: 'ex-2',
            workoutId: 'workout-1',
            weekId: 'week-1',
            programId: 'program-1',
          ),
        ],
      };

      when(mockProvider.exercises).thenReturn(exercises);
      when(mockProvider.allWorkoutSets).thenReturn(sets);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);
    });

    testWidgets('FAB navigates to create exercise screen', (tester) async {
      /// Test Purpose: Verify FAB triggers navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify navigation occurred (CreateExerciseScreen should be pushed)
      expect(find.text('Create Exercise'), findsOneWidget);
    });

    testWidgets('displays workout notes if present', (tester) async {
      /// Test Purpose: Verify workout notes are displayed

      final workoutWithNotes = Workout(
        id: 'workout-1',
        name: 'Test Workout',
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        weekId: 'week-1',
        programId: 'program-1',
        notes: 'Focus on form today',
      );

      await tester.pumpWidget(
        TestSetupHelper.createTestAppWithMockedProviders(
          programProvider: mockProvider,
          child: ConsolidatedWorkoutScreen(
            program: testProgram,
            week: testWeek,
            workout: workoutWithNotes,
          ),
        ),
      );

      expect(find.text('Focus on form today'), findsOneWidget);
      expect(find.byIcon(Icons.notes), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      /// Test Purpose: Verify error handling displays correctly

      when(mockProvider.exercises).thenReturn([]);
      when(mockProvider.allWorkoutSets).thenReturn({});
      when(mockProvider.error).thenReturn('Failed to load exercises');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error loading exercises'), findsOneWidget);
      expect(find.text('Failed to load exercises'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button reloads exercises on error', (tester) async {
      /// Test Purpose: Verify retry functionality works

      when(mockProvider.exercises).thenReturn([]);
      when(mockProvider.allWorkoutSets).thenReturn({});
      when(mockProvider.error).thenReturn('Failed to load exercises');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      verify(mockProvider.loadExercises('program-1', 'week-1', 'workout-1')).called(2); // Once on init, once on retry
    });

    testWidgets('displays day of week chip when present', (tester) async {
      /// Test Purpose: Verify day of week chip is shown

      final workoutWithDay = Workout(
        id: 'workout-1',
        name: 'Test Workout',
        orderIndex: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user-1',
        weekId: 'week-1',
        programId: 'program-1',
        dayOfWeek: 1, // Monday
      );

      await tester.pumpWidget(
        TestSetupHelper.createTestAppWithMockedProviders(
          programProvider: mockProvider,
          child: ConsolidatedWorkoutScreen(
            program: testProgram,
            week: testWeek,
            workout: workoutWithDay,
          ),
        ),
      );

      expect(find.text('Monday'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('edit button shows in app bar', (tester) async {
      /// Test Purpose: Verify edit action is available

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byTooltip('Edit Workout'), findsOneWidget);
    });

    testWidgets('delete option available in popup menu', (tester) async {
      /// Test Purpose: Verify delete action is accessible

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open popup menu
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Workout'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsWidgets);
    });

    testWidgets('loads exercises and sets on screen init', (tester) async {
      /// Test Purpose: Verify data loading is triggered on screen open

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Trigger post-frame callback

      verify(mockProvider.loadExercises('program-1', 'week-1', 'workout-1')).called(1);
    });
  });
}
