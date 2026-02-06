import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/screens/templates/template_preview_sheet.dart';
import 'package:fittrack/models/templates/templates.dart';
import 'package:fittrack/models/exercise.dart';

void main() {
  group('WorkoutTemplatePreviewSheet Widget Tests', () {
    final testWorkoutTemplate = WorkoutTemplate(
      id: 'workout1',
      name: 'Upper Body Workout',
      description: 'A comprehensive upper body workout',
      exercises: const [
        TemplateExercise(
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: [
            TemplateSet(setNumber: 1, reps: 10),
            TemplateSet(setNumber: 2, reps: 10),
            TemplateSet(setNumber: 3, reps: 8),
          ],
        ),
        TemplateExercise(
          name: 'Shoulder Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          sets: [
            TemplateSet(setNumber: 1, reps: 12),
            TemplateSet(setNumber: 2, reps: 10),
          ],
        ),
      ],
      createdAt: DateTime(2024, 1, 1),
      userId: 'user123',
      isPrebuilt: false,
    );

    final prebuiltWorkoutTemplate = WorkoutTemplate(
      id: 'prebuilt1',
      name: 'Starter Workout',
      description: 'A beginner friendly workout',
      exercises: const [
        TemplateExercise(
          name: 'Squats',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: [
            TemplateSet(setNumber: 1, reps: 15),
          ],
        ),
      ],
      createdAt: DateTime(2024, 1, 1),
      userId: '',
      isPrebuilt: true,
    );

    Widget buildTestWidget({
      required WorkoutTemplate template,
      void Function(bool)? onResult,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await WorkoutTemplatePreviewSheet.show(
                  context,
                  template: template,
                );
                onResult?.call(result);
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays template name', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Upper Body Workout'), findsOneWidget);
    });

    testWidgets('displays template description', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('A comprehensive upper body workout'), findsOneWidget);
    });

    testWidgets('displays My Template badge for user templates', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('My Template'), findsOneWidget);
    });

    testWidgets('displays Pre-built badge for pre-built templates',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(template: prebuiltWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Pre-built'), findsOneWidget);
    });

    testWidgets('displays exercise count', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // '2' appears in stats, 'Exercises' appears in stats label and section header
      expect(find.text('2'), findsWidgets); // 2 exercises
      expect(find.text('Exercises'), findsWidgets);
    });

    testWidgets('displays total set count', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget); // 5 sets total
      expect(find.text('Sets'), findsOneWidget);
    });

    testWidgets('displays exercise names in list', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Shoulder Press'), findsOneWidget);
    });

    testWidgets('displays Use Template button', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Use Template'), findsOneWidget);
    });

    testWidgets('Use Template button returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestWidget(
        template: testWorkoutTemplate,
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Scroll to make the Use Template button visible
      final useTemplateButton = find.text('Use Template');
      await tester.ensureVisible(useTemplateButton);
      await tester.pumpAndSettle();

      await tester.tap(useTemplateButton);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('displays Exercises section header', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Exercises'), findsWidgets);
    });

    testWidgets('displays drag handle', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWorkoutTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Find the drag handle container (40x4)
      final dragHandleFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.constraints?.maxWidth == 40 &&
          widget.constraints?.maxHeight == 4);

      expect(dragHandleFinder, findsOneWidget);
    });
  });

  group('WeekTemplatePreviewSheet Widget Tests', () {
    final testWeekTemplate = WeekTemplate(
      id: 'week1',
      name: 'Push Pull Legs Week',
      description: 'A PPL training week',
      workouts: const [
        TemplateWorkout(
          name: 'Push Day',
          dayOfWeek: 1,
          orderIndex: 0,
          exercises: [
            TemplateExercise(
              name: 'Bench Press',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: [TemplateSet(setNumber: 1, reps: 10)],
            ),
          ],
        ),
        TemplateWorkout(
          name: 'Pull Day',
          dayOfWeek: 3,
          orderIndex: 1,
          exercises: [
            TemplateExercise(
              name: 'Pull Ups',
              exerciseType: ExerciseType.bodyweight,
              orderIndex: 0,
              sets: [TemplateSet(setNumber: 1, reps: 8)],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2024, 1, 1),
      userId: 'user123',
      isPrebuilt: false,
    );

    Widget buildTestWidget({
      required WeekTemplate template,
      void Function(bool)? onResult,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await WeekTemplatePreviewSheet.show(
                  context,
                  template: template,
                );
                onResult?.call(result);
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays template name', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWeekTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Push Pull Legs Week'), findsOneWidget);
    });

    testWidgets('displays workout count', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWeekTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // '2' may appear in multiple places, 'Workouts' in stats and section header
      expect(find.text('2'), findsWidgets); // 2 workouts
      expect(find.text('Workouts'), findsWidgets);
    });

    testWidgets('displays workout names in list', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWeekTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Pull Day'), findsOneWidget);
    });

    testWidgets('displays Workouts section header', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testWeekTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Workouts'), findsWidgets);
    });

    testWidgets('Use Template button returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestWidget(
        template: testWeekTemplate,
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Scroll to make the Use Template button visible
      final useTemplateButton = find.text('Use Template');
      await tester.ensureVisible(useTemplateButton);
      await tester.pumpAndSettle();

      await tester.tap(useTemplateButton);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('ProgramTemplatePreviewSheet Widget Tests', () {
    final testProgramTemplate = ProgramTemplate(
      id: 'program1',
      name: 'Strength Program',
      description: '12 week strength program',
      weeks: [
        const TemplateWeek(
          name: 'Week 1',
          order: 1,
          workouts: [
            TemplateWorkout(
              name: 'Day 1',
              dayOfWeek: 1,
              orderIndex: 0,
              exercises: [
                TemplateExercise(
                  name: 'Squats',
                  exerciseType: ExerciseType.strength,
                  orderIndex: 0,
                  sets: [TemplateSet(setNumber: 1, reps: 5)],
                ),
              ],
            ),
          ],
        ),
        const TemplateWeek(
          name: 'Week 2',
          order: 2,
          workouts: [
            TemplateWorkout(
              name: 'Day 1',
              dayOfWeek: 1,
              orderIndex: 0,
              exercises: [
                TemplateExercise(
                  name: 'Deadlifts',
                  exerciseType: ExerciseType.strength,
                  orderIndex: 0,
                  sets: [TemplateSet(setNumber: 1, reps: 5)],
                ),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2024, 1, 1),
      userId: 'user123',
      isPrebuilt: false,
    );

    Widget buildTestWidget({
      required ProgramTemplate template,
      void Function(bool)? onResult,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await ProgramTemplatePreviewSheet.show(
                  context,
                  template: template,
                );
                onResult?.call(result);
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays template name', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testProgramTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Strength Program'), findsOneWidget);
    });

    testWidgets('displays week count', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testProgramTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets); // 2 weeks
      expect(find.text('Weeks'), findsOneWidget);
    });

    testWidgets('displays week names in list', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testProgramTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('Week 2'), findsOneWidget);
    });

    testWidgets('displays Program Structure section header', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testProgramTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Program Structure'), findsOneWidget);
    });

    testWidgets('Use Template button returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(buildTestWidget(
        template: testProgramTemplate,
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Scroll to make the Use Template button visible
      final useTemplateButton = find.text('Use Template');
      await tester.ensureVisible(useTemplateButton);
      await tester.pumpAndSettle();

      await tester.tap(useTemplateButton);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('displays check icon on Use Template button', (tester) async {
      await tester.pumpWidget(buildTestWidget(template: testProgramTemplate));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
