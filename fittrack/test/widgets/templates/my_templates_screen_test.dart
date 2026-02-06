import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/profile/my_templates_screen.dart';
import 'package:fittrack/providers/template_provider.dart';
import 'package:fittrack/models/templates/templates.dart';
import 'package:fittrack/models/exercise.dart';

@GenerateMocks([TemplateProvider])
import 'my_templates_screen_test.mocks.dart';

void main() {
  late MockTemplateProvider mockTemplateProvider;

  setUp(() {
    mockTemplateProvider = MockTemplateProvider();
    // Default setup - not loading, no error, empty templates
    when(mockTemplateProvider.isLoading).thenReturn(false);
    when(mockTemplateProvider.error).thenReturn(null);
    when(mockTemplateProvider.workoutTemplates).thenReturn([]);
    when(mockTemplateProvider.weekTemplates).thenReturn([]);
    when(mockTemplateProvider.programTemplates).thenReturn([]);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<TemplateProvider>.value(
        value: mockTemplateProvider,
        child: const MyTemplatesScreen(),
      ),
    );
  }

  group('MyTemplatesScreen Widget Tests', () {
    testWidgets('displays screen title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('My Templates'), findsOneWidget);
    });

    testWidgets('displays three tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Weeks'), findsOneWidget);
      expect(find.text('Programs'), findsOneWidget);
    });

    testWidgets('displays loading indicator when loading', (tester) async {
      when(mockTemplateProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state when error occurs', (tester) async {
      when(mockTemplateProvider.error).thenReturn('Network error');

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Failed to load templates'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('error state has dismiss button', (tester) async {
      when(mockTemplateProvider.error).thenReturn('Error');

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      verify(mockTemplateProvider.clearError()).called(1);
    });
  });

  group('MyTemplatesScreen Workouts Tab Tests', () {
    testWidgets('displays empty state when no workout templates',
        (tester) async {
      when(mockTemplateProvider.workoutTemplates).thenReturn([]);

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No Workout Templates'), findsOneWidget);
      expect(
        find.text('Save workouts as templates to reuse them later'),
        findsOneWidget,
      );
    });

    testWidgets('displays workout templates list', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Push Workout',
          description: 'Chest and triceps',
          exercises: const [
            TemplateExercise(
              name: 'Bench Press',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: [TemplateSet(setNumber: 1, reps: 10)],
            ),
          ],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Push Workout'), findsOneWidget);
      expect(find.text('1 exercises \u2022 1 sets'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Test Workout',
          exercises: const [],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Workout Template'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Test Workout"?'),
        findsOneWidget,
      );
    });

    testWidgets('delete confirmation cancels on CANCEL tap', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Test Workout',
          exercises: const [],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      verifyNever(mockTemplateProvider.deleteWorkoutTemplate(any));
    });

    testWidgets('delete confirmation deletes on DELETE tap', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Test Workout',
          exercises: const [],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);
      when(mockTemplateProvider.deleteWorkoutTemplate('1'))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      verify(mockTemplateProvider.deleteWorkoutTemplate('1')).called(1);
    });
  });

  group('MyTemplatesScreen Weeks Tab Tests', () {
    testWidgets('displays empty state when no week templates', (tester) async {
      when(mockTemplateProvider.weekTemplates).thenReturn([]);

      await tester.pumpWidget(buildTestWidget());

      // Tap on Weeks tab
      await tester.tap(find.text('Weeks'));
      await tester.pumpAndSettle();

      expect(find.text('No Week Templates'), findsOneWidget);
    });

    testWidgets('displays week templates list', (tester) async {
      final templates = [
        WeekTemplate(
          id: '1',
          name: 'PPL Week',
          description: 'Push Pull Legs',
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
          ],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.weekTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Weeks'));
      await tester.pumpAndSettle();

      expect(find.text('PPL Week'), findsOneWidget);
      expect(find.text('1 workouts \u2022 1 exercises'), findsOneWidget);
    });
  });

  group('MyTemplatesScreen Programs Tab Tests', () {
    testWidgets('displays empty state when no program templates',
        (tester) async {
      when(mockTemplateProvider.programTemplates).thenReturn([]);

      await tester.pumpWidget(buildTestWidget());

      // Tap on Programs tab
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();

      expect(find.text('No Program Templates'), findsOneWidget);
    });

    testWidgets('displays program templates list', (tester) async {
      final templates = [
        ProgramTemplate(
          id: '1',
          name: 'Strength Program',
          description: '12 week program',
          weeks: const [
            TemplateWeek(
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
          ],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.programTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();

      expect(find.text('Strength Program'), findsOneWidget);
      expect(find.text('1 weeks \u2022 1 workouts'), findsOneWidget);
    });
  });

  group('MyTemplatesScreen Tab Navigation Tests', () {
    testWidgets('can switch between tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Start on Workouts tab
      expect(find.text('No Workout Templates'), findsOneWidget);

      // Switch to Weeks tab
      await tester.tap(find.text('Weeks'));
      await tester.pumpAndSettle();
      expect(find.text('No Week Templates'), findsOneWidget);

      // Switch to Programs tab
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();
      expect(find.text('No Program Templates'), findsOneWidget);

      // Switch back to Workouts tab
      await tester.tap(find.text('Workouts'));
      await tester.pumpAndSettle();
      expect(find.text('No Workout Templates'), findsOneWidget);
    });
  });

  group('MyTemplatesScreen Template Card Tests', () {
    testWidgets('displays template description when present', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Test Workout',
          description: 'A detailed description of the workout',
          exercises: const [],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('A detailed description of the workout'), findsOneWidget);
    });

    testWidgets('displays fitness icon for workout templates', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Test Workout',
          exercises: const [],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.fitness_center), findsWidgets);
    });

    testWidgets('displays delete icon for each template', (tester) async {
      final templates = [
        WorkoutTemplate(
          id: '1',
          name: 'Test Workout',
          exercises: const [],
          createdAt: DateTime(2024, 1, 1),
          userId: 'user123',
          isPrebuilt: false,
        ),
      ];
      when(mockTemplateProvider.workoutTemplates).thenReturn(templates);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
