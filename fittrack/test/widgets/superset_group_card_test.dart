/// Widget tests for SupersetGroupCard.
///
/// Test Coverage:
/// - Renders group label badge with correct text
/// - Shows position labels (A1, A2) for exercises in the group
/// - 3-dot menu contains "Delete Superset" option
/// - Drag handle is present in the header
/// - onDeleteGroup callback fires when delete tapped
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/widgets/superset_group_card.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/providers/weight_unit_provider.dart';

import '../integration/test_setup_helper.dart';

void main() {
  group('SupersetGroupCard Widget Tests', () {
    late WeightUnitProvider weightUnitProvider;
    late List<Exercise> testExercises;
    late Map<String, List<ExerciseSet>> testSetsMap;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await TestSetupHelper.initializeFirebaseForWidgetTests();
    });

    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      weightUnitProvider = WeightUnitProvider(prefs);

      final now = DateTime.now();

      testExercises = [
        Exercise(
          id: 'ex-1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          createdAt: now,
          updatedAt: now,
          userId: 'user-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
          supersetGroupId: 'group-A',
          groupOrderIndex: 0,
        ),
        Exercise(
          id: 'ex-2',
          name: 'Pull-ups',
          exerciseType: ExerciseType.bodyweight,
          orderIndex: 1,
          createdAt: now,
          updatedAt: now,
          userId: 'user-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
          supersetGroupId: 'group-A',
          groupOrderIndex: 1,
        ),
      ];

      testSetsMap = {
        'ex-1': [
          ExerciseSet(
            id: 'set-1',
            setNumber: 1,
            checked: false,
            reps: 10,
            weight: 80.0,
            createdAt: now,
            updatedAt: now,
            userId: 'user-1',
            exerciseId: 'ex-1',
            workoutId: 'workout-1',
            weekId: 'week-1',
            programId: 'program-1',
          ),
        ],
        'ex-2': [],
      };
    });

    Widget createTestWidget({
      String groupLabel = 'A',
      List<Exercise>? exercises,
      Map<String, List<ExerciseSet>>? setsMap,
      int outerIndex = 0,
      bool isReorderEnabled = true,
      VoidCallback? onDeleteGroup,
      Function(int, int)? onReorderWithinGroup,
      Function(Exercise)? onAddSet,
      Function(Exercise)? onEditName,
      Function(ExerciseSet)? onUpdateSet,
      Function(String, String)? onDeleteSet,
    }) {
      return ChangeNotifierProvider<WeightUnitProvider>.value(
        value: weightUnitProvider,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (_, __) {},
                children: [
                  SupersetGroupCard(
                    key: const ValueKey('group'),
                    groupLabel: groupLabel,
                    exercises: exercises ?? testExercises,
                    setsMap: setsMap ?? testSetsMap,
                    outerIndex: outerIndex,
                    isReorderEnabled: isReorderEnabled,
                    onDeleteGroup: onDeleteGroup ?? () {},
                    onReorderWithinGroup: onReorderWithinGroup ?? (_, __) {},
                    onAddSet: onAddSet ?? (_) {},
                    onEditName: onEditName ?? (_) {},
                    onUpdateSet: onUpdateSet ?? (_) {},
                    onDeleteSet: onDeleteSet ?? (_, __) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders group label badge with correct text', (tester) async {
      /// Test Purpose: Verify the badge shows the group label correctly
      await tester.pumpWidget(createTestWidget(groupLabel: 'A'));
      await tester.pump();

      expect(find.textContaining('Superset'), findsOneWidget);
      expect(find.textContaining('A'), findsWidgets);
    });

    testWidgets('renders group label B correctly', (tester) async {
      /// Test Purpose: Verify different group labels render correctly
      await tester.pumpWidget(createTestWidget(groupLabel: 'B'));
      await tester.pump();

      expect(find.textContaining('Superset · B'), findsOneWidget);
    });

    testWidgets('shows A1 and A2 position labels for 2-exercise group', (tester) async {
      /// Test Purpose: Verify position labels are rendered for each exercise
      await tester.pumpWidget(createTestWidget(groupLabel: 'A'));
      await tester.pump();

      expect(find.text('A1'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
    });

    testWidgets('renders exercise names', (tester) async {
      /// Test Purpose: Verify exercise names within the group are displayed
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Pull-ups'), findsOneWidget);
    });

    testWidgets('drag handle icon is present in header', (tester) async {
      /// Test Purpose: Verify the header drag handle is visible when reorder enabled
      await tester.pumpWidget(createTestWidget(isReorderEnabled: true));
      await tester.pump();

      // drag_handle icons: one in the group header, two in inner ExerciseCards
      expect(find.byIcon(Icons.drag_handle), findsWidgets);
    });

    testWidgets('3-dot menu contains Delete Superset option', (tester) async {
      /// Test Purpose: Verify popup menu shows "Delete Superset" action
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Delete Superset'), findsOneWidget);
    });

    testWidgets('onDeleteGroup fires when Delete Superset tapped', (tester) async {
      /// Test Purpose: Verify the delete callback is invoked on menu selection
      var deleteCalled = false;

      await tester.pumpWidget(createTestWidget(
        onDeleteGroup: () => deleteCalled = true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Superset'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });
  });
}
