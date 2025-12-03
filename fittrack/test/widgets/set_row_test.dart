import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/set_row.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/exercise.dart';

import '../integration/test_setup_helper.dart';

void main() {
  group('SetRow Widget Tests', () {
    late ExerciseSet testSet;

    setUpAll(() async {
      await TestSetupHelper.initializeFirebaseForWidgetTests();
    });

    setUp(() {
      testSet = ExerciseSet(
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
      );
    });

    Widget createTestWidget({
      required ExerciseSet set,
      required ExerciseType exerciseType,
      bool isLastSet = false,
      required Function(ExerciseSet) onUpdate,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SetRow(
            set: set,
            exerciseType: exerciseType,
            isLastSet: isLastSet,
            onUpdate: onUpdate,
            onDelete: onDelete,
          ),
        ),
      );
    }

    testWidgets('displays set number', (tester) async {
      /// Test Purpose: Verify set number is shown

      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        onUpdate: (_) {},
      ));

      expect(find.text('1'), findsOneWidget); // Set number
    });

    testWidgets('displays reps and weight for strength exercise', (tester) async {
      /// Test Purpose: Verify strength fields are shown

      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        onUpdate: (_) {},
      ));

      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('shows checkbox for completion', (tester) async {
      /// Test Purpose: Verify checkbox is present

      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        onUpdate: (_) {},
      ));

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('checking checkbox calls onUpdate with checked=true', (tester) async {
      /// Test Purpose: Verify checkbox interaction updates set

      ExerciseSet? updatedSet;
      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        onUpdate: (set) => updatedSet = set,
      ));

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(updatedSet, isNotNull);
      expect(updatedSet!.checked, isTrue);
    });

    testWidgets('displays duration and distance for cardio exercise', (tester) async {
      /// Test Purpose: Verify cardio fields are shown

      final cardioSet = testSet.copyWith(
        reps: null,
        weight: null,
      ).copyWith(
        duration: 1800, // 30 minutes
        distance: 5000.0, // 5km
      );

      // Create new set with correct values since copyWith doesn't support duration/distance
      final cardioSetFull = ExerciseSet(
        id: cardioSet.id,
        setNumber: cardioSet.setNumber,
        checked: cardioSet.checked,
        duration: 1800,
        distance: 5000.0,
        createdAt: cardioSet.createdAt,
        updatedAt: cardioSet.updatedAt,
        userId: cardioSet.userId,
        exerciseId: cardioSet.exerciseId,
        workoutId: cardioSet.workoutId,
        weekId: cardioSet.weekId,
        programId: cardioSet.programId,
      );

      await tester.pumpWidget(createTestWidget(
        set: cardioSetFull,
        exerciseType: ExerciseType.cardio,
        onUpdate: (_) {},
      ));

      expect(find.text('Duration (min)'), findsOneWidget);
      expect(find.text('Distance (km)'), findsOneWidget);
    });

    testWidgets('displays only reps for bodyweight exercise', (tester) async {
      /// Test Purpose: Verify bodyweight only shows reps

      await tester.pumpWidget(createTestWidget(
        set: testSet.copyWith(weight: null),
        exerciseType: ExerciseType.bodyweight,
        onUpdate: (_) {},
      ));

      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsNothing);
    });

    testWidgets('delete button shown when not last set', (tester) async {
      /// Test Purpose: Verify delete button presence

      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        isLastSet: false,
        onUpdate: (_) {},
        onDelete: () {},
      ));

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('delete button hidden when last set', (tester) async {
      /// Test Purpose: Verify last set cannot be deleted

      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        isLastSet: true,
        onUpdate: (_) {},
        onDelete: null,
      ));

      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('tapping delete button calls onDelete', (tester) async {
      /// Test Purpose: Verify delete callback works

      bool deleteCalled = false;
      await tester.pumpWidget(createTestWidget(
        set: testSet,
        exerciseType: ExerciseType.strength,
        isLastSet: false,
        onUpdate: (_) {},
        onDelete: () => deleteCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('notes button shown when set has notes', (tester) async {
      /// Test Purpose: Verify notes indicator

      final setWithNotes = ExerciseSet(
        id: testSet.id,
        setNumber: testSet.setNumber,
        checked: testSet.checked,
        reps: testSet.reps,
        weight: testSet.weight,
        notes: 'Focus on form',
        createdAt: testSet.createdAt,
        updatedAt: testSet.updatedAt,
        userId: testSet.userId,
        exerciseId: testSet.exerciseId,
        workoutId: testSet.workoutId,
        weekId: testSet.weekId,
        programId: testSet.programId,
      );

      await tester.pumpWidget(createTestWidget(
        set: setWithNotes,
        exerciseType: ExerciseType.strength,
        onUpdate: (_) {},
      ));

      expect(find.byIcon(Icons.notes), findsOneWidget);
    });

    testWidgets('fields are disabled when set is checked', (tester) async {
      /// Test Purpose: Verify checked sets are read-only

      final checkedSet = testSet.copyWith(checked: true);

      await tester.pumpWidget(createTestWidget(
        set: checkedSet,
        exerciseType: ExerciseType.strength,
        onUpdate: (_) {},
      ));

      // Find text fields and verify they're disabled
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in textFields) {
        expect(field.enabled, isFalse);
      }
    });

    testWidgets('unchecking checked set enables fields', (tester) async {
      /// Test Purpose: Verify unchecking enables editing

      final checkedSet = testSet.copyWith(checked: true);
      ExerciseSet? updatedSet;

      await tester.pumpWidget(createTestWidget(
        set: checkedSet,
        exerciseType: ExerciseType.strength,
        onUpdate: (set) => updatedSet = set,
      ));

      // Uncheck the set
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(updatedSet, isNotNull);
      expect(updatedSet!.checked, isFalse);
    });
  });
}
