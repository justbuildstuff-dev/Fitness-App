import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/screens/analytics/components/exercise_picker.dart';

void main() {
  final sampleExercises = <LoggedExercise>[
    (
      exerciseId: 'ex1',
      exerciseName: 'Bench Press',
      exerciseType: ExerciseType.strength,
    ),
    (
      exerciseId: 'ex2',
      exerciseName: 'Pull Up',
      exerciseType: ExerciseType.bodyweight,
    ),
    (
      exerciseId: 'ex3',
      exerciseName: 'Running',
      exerciseType: ExerciseType.cardio,
    ),
    (
      exerciseId: 'ex4',
      exerciseName: 'Plank',
      exerciseType: ExerciseType.timeBased,
    ),
  ];

  Widget buildTestWidget({
    List<LoggedExercise> exercises = const [],
    int? selectedIndex,
    ValueChanged<int>? onSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: ExercisePicker(
            exercises: exercises,
            selectedIndex: selectedIndex,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ExercisePicker', () {
    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows all exercises when no search query', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Pull Up'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Plank'), findsOneWidget);
    });

    testWidgets('shows exercise type chips', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('Time-based'), findsOneWidget);
    });

    testWidgets('filters exercises by search query', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pump();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Pull Up'), findsNothing);
      expect(find.text('Running'), findsNothing);
      expect(find.text('Plank'), findsNothing);
    });

    testWidgets('shows no matches message when search has no results',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();

      expect(find.textContaining('No matches'), findsOneWidget);
    });

    testWidgets('shows empty state when no exercises', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No exercises logged'), findsOneWidget);
    });

    testWidgets('calls onSelected when exercise tapped', (tester) async {
      int? selectedIndex;
      await tester.pumpWidget(buildTestWidget(
        exercises: sampleExercises,
        onSelected: (index) => selectedIndex = index,
      ));

      await tester.tap(find.text('Pull Up'));
      await tester.pump();

      expect(selectedIndex, equals(1));
    });

    testWidgets('highlights selected exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        exercises: sampleExercises,
        selectedIndex: 0,
      ));

      final listTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Bench Press'),
      );
      expect(listTile.selected, isTrue);
    });

    testWidgets('clear button clears search', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pump();

      // Verify filtered
      expect(find.text('Pull Up'), findsNothing);

      // Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // All exercises visible again
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Pull Up'), findsOneWidget);
    });

    testWidgets('search is case insensitive', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      await tester.enterText(find.byType(TextField), 'BENCH');
      await tester.pump();

      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(buildTestWidget(exercises: sampleExercises));

      expect(
        find.bySemanticsLabel(RegExp(r'Exercise list, 4 items')),
        findsOneWidget,
      );
    });
  });
}
