import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/exercise_card.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';

import '../integration/test_setup_helper.dart';

void main() {
  group('ExerciseCard Widget Tests', () {
    late Exercise testExercise;
    late List<ExerciseSet> testSets;

    setUpAll(() async {
      await TestSetupHelper.initializeFirebaseForWidgetTests();
    });

    setUp(() {
      testExercise = Exercise(
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

      testSets = [
        ExerciseSet(
          id: 'set-1',
          setNumber: 1,
          checked: false,
          reps: 10,
          weight: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user-1',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        ),
      ];
    });

    Widget createTestWidget({
      required Exercise exercise,
      required List<ExerciseSet> sets,
      bool isReorderEnabled = true,
      VoidCallback? onAddSet,
      VoidCallback? onEditName,
      VoidCallback? onDelete,
      required Function(ExerciseSet) onUpdateSet,
      required Function(String, String) onDeleteSet,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ExerciseCard(
            exercise: exercise,
            sets: sets,
            isReorderEnabled: isReorderEnabled,
            onAddSet: onAddSet,
            onEditName: onEditName,
            onDelete: onDelete,
            onUpdateSet: onUpdateSet,
            onDeleteSet: onDeleteSet,
          ),
        ),
      );
    }

    testWidgets('renders exercise name and type icon', (tester) async {
      /// Test Purpose: Verify exercise header displays correctly
      /// Exercise name and type icon should be visible

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget); // Strength icon
    });

    testWidgets('renders set count', (tester) async {
      /// Test Purpose: Verify set count is displayed
      /// Should show "X sets" or "1 set" based on count

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.text('1 set'), findsOneWidget);

      // Test with multiple sets
      final multipleSets = [
        ...testSets,
        ExerciseSet(
          id: 'set-2',
          setNumber: 2,
          checked: false,
          reps: 10,
          weight: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user-1',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: multipleSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.text('2 sets'), findsOneWidget);
    });

    testWidgets('collapses and expands when tapped', (tester) async {
      /// Test Purpose: Verify collapse/expand functionality
      /// Tapping header should toggle visibility of sets

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      // Should start expanded (default)
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Set content visible

      // Tap to collapse
      await tester.tap(find.text('Bench Press'));
      await tester.pump();

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text('10'), findsNothing); // Set content hidden

      // Tap to expand again
      await tester.tap(find.text('Bench Press'));
      await tester.pump();

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Set content visible again
    });

    testWidgets('shows Add Set button', (tester) async {
      /// Test Purpose: Verify Add Set button is present
      /// Button should be visible and enabled when sets < 10

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onAddSet: () {},
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Add set'), findsOneWidget);
    });

    testWidgets('disables Add Set button at 10 sets', (tester) async {
      /// Test Purpose: Verify max sets limit
      /// Button should be disabled when exercise has 10 sets

      final maxSets = List.generate(
        10,
        (index) => ExerciseSet(
          id: 'set-${index + 1}',
          setNumber: index + 1,
          checked: false,
          reps: 10,
          weight: 100.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user-1',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        ),
      );

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: maxSets,
        onAddSet: () {},
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      final addButton = tester.widget<IconButton>(
        find.byIcon(Icons.add).hitTestable(),
      );
      expect(addButton.onPressed, isNull);
      expect(find.byTooltip('Maximum 10 sets per exercise'), findsOneWidget);
    });

    testWidgets('shows 3-dot menu with Edit and Delete options', (tester) async {
      /// Test Purpose: Verify popup menu displays correctly
      /// Menu should have Edit Name and Delete Exercise options

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onEditName: () {},
        onDelete: () {},
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Edit Name'), findsOneWidget);
      expect(find.text('Delete Exercise'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows drag handle when reordering enabled', (tester) async {
      /// Test Purpose: Verify drag handle visibility with reordering enabled
      /// Drag handle should be visible when isReorderEnabled = true

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        isReorderEnabled: true,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('hides drag handle when reordering disabled', (tester) async {
      /// Test Purpose: Verify drag handle visibility with reordering disabled
      /// Drag handle should be hidden when isReorderEnabled = false

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        isReorderEnabled: false,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('calls onAddSet when Add button tapped', (tester) async {
      /// Test Purpose: Verify onAddSet callback is triggered
      /// Tapping Add button should call callback

      bool addSetCalled = false;
      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onAddSet: () => addSetCalled = true,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(addSetCalled, isTrue);
    });

    testWidgets('calls onEditName when Edit Name menu item selected', (tester) async {
      /// Test Purpose: Verify onEditName callback is triggered
      /// Selecting Edit Name from menu should call callback

      bool editNameCalled = false;
      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onEditName: () => editNameCalled = true,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Edit Name
      await tester.tap(find.text('Edit Name'));
      await tester.pump();

      expect(editNameCalled, isTrue);
    });

    testWidgets('calls onDelete when Delete menu item selected', (tester) async {
      /// Test Purpose: Verify onDelete callback is triggered
      /// Selecting Delete Exercise from menu should call callback

      bool deleteCalled = false;
      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onDelete: () => deleteCalled = true,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Delete Exercise
      await tester.tap(find.text('Delete Exercise'));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('shows empty state when no sets', (tester) async {
      /// Test Purpose: Verify empty state is displayed
      /// When exercise has no sets, should show helpful message

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: [],
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.text('No sets yet. Add your first set!'), findsOneWidget);
    });

    testWidgets('starts expanded by default', (tester) async {
      /// Test Purpose: Verify default expanded state
      /// Card should start expanded on first render

      await tester.pumpWidget(createTestWidget(
        exercise: testExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      // Should show up arrow (expanded state)
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      // Should show set content
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays correct icon for cardio exercise', (tester) async {
      /// Test Purpose: Verify exercise type icons
      /// Different exercise types should show different icons

      final cardioExercise = testExercise.copyWith(
        name: 'Running',
        exerciseType: ExerciseType.cardio,
      );

      await tester.pumpWidget(createTestWidget(
        exercise: cardioExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.directions_run), findsOneWidget);
    });

    testWidgets('displays correct icon for bodyweight exercise', (tester) async {
      /// Test Purpose: Verify bodyweight exercise icon
      /// Bodyweight exercises should show accessibility icon

      final bodyweightExercise = testExercise.copyWith(
        name: 'Push-ups',
        exerciseType: ExerciseType.bodyweight,
      );

      await tester.pumpWidget(createTestWidget(
        exercise: bodyweightExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
    });

    testWidgets('displays correct icon for time-based exercise', (tester) async {
      /// Test Purpose: Verify time-based exercise icon
      /// Time-based exercises should show timer icon

      final timeBasedExercise = testExercise.copyWith(
        name: 'Plank',
        exerciseType: ExerciseType.timeBased,
      );

      await tester.pumpWidget(createTestWidget(
        exercise: timeBasedExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('displays correct icon for custom exercise', (tester) async {
      /// Test Purpose: Verify custom exercise icon
      /// Custom exercises should show tune icon

      final customExercise = testExercise.copyWith(
        name: 'Custom Exercise',
        exerciseType: ExerciseType.custom,
      );

      await tester.pumpWidget(createTestWidget(
        exercise: customExercise,
        sets: testSets,
        onUpdateSet: (_) {},
        onDeleteSet: (_, __) {},
      ));

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });
  });
}
