import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/templates.dart';
import 'package:fittrack/providers/template_provider.dart';
import 'package:fittrack/services/firestore_service.dart';

@GenerateMocks([FirestoreService])
import 'template_provider_test.mocks.dart';

void main() {
  late MockFirestoreService mockFirestoreService;
  late TemplateProvider provider;
  late DateTime testCreatedAt;
  const testUserId = 'test_user_123';

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    testCreatedAt = DateTime(2026, 1, 15, 10, 30);

    // Setup default stream behaviors
    when(mockFirestoreService.getUserWorkoutTemplates(any))
        .thenAnswer((_) => Stream.value([]));
    when(mockFirestoreService.getUserWeekTemplates(any))
        .thenAnswer((_) => Stream.value([]));
    when(mockFirestoreService.getUserProgramTemplates(any))
        .thenAnswer((_) => Stream.value([]));
    when(mockFirestoreService.getPrebuiltPrograms())
        .thenAnswer((_) async => []);
  });

  tearDown(() {
    provider.dispose();
  });

  group('Initialization', () {
    test('should initialize with empty lists', () {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      expect(provider.workoutTemplates, isEmpty);
      expect(provider.weekTemplates, isEmpty);
      expect(provider.programTemplates, isEmpty);
      expect(provider.prebuiltPrograms, isEmpty);
      expect(provider.error, isNull);
    });

    test('should not initialize streams for null userId', () {
      provider = TemplateProvider.withFirestore(null, mockFirestoreService);

      // Should not call stream methods
      verifyNever(mockFirestoreService.getUserWorkoutTemplates(any));
      verifyNever(mockFirestoreService.getUserWeekTemplates(any));
      verifyNever(mockFirestoreService.getUserProgramTemplates(any));
    });

    test('should not initialize streams for empty userId', () {
      provider = TemplateProvider.withFirestore('', mockFirestoreService);

      verifyNever(mockFirestoreService.getUserWorkoutTemplates(any));
    });

    test('should load prebuilt programs on init', () async {
      final prebuilts = [
        ProgramTemplate(
          id: 'prebuilt_1',
          name: 'PPL Program',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        ),
      ];

      when(mockFirestoreService.getPrebuiltPrograms())
          .thenAnswer((_) async => prebuilts);

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      // Wait for async initialization
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.prebuiltPrograms.length, 1);
      expect(provider.isPrebuiltLoaded, isTrue);
    });
  });

  group('Template Limits', () {
    test('canSaveWorkoutTemplate should be true when under limit', () {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      expect(provider.canSaveWorkoutTemplate, isTrue);
    });

    test('canSaveWorkoutTemplate should be false when at limit', () {
      final templates = List.generate(
        10,
        (i) => WorkoutTemplate(
          id: 'template_$i',
          name: 'Template $i',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: testUserId,
          isPrebuilt: false,
        ),
      );

      when(mockFirestoreService.getUserWorkoutTemplates(any))
          .thenAnswer((_) => Stream.value(templates));

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      // Wait for stream to emit
      return Future.delayed(const Duration(milliseconds: 100), () {
        expect(provider.canSaveWorkoutTemplate, isFalse);
      });
    });

    test('canSaveWeekTemplate should check limit correctly', () async {
      final templates = List.generate(
        10,
        (i) => WeekTemplate(
          id: 'template_$i',
          name: 'Template $i',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: testUserId,
          isPrebuilt: false,
        ),
      );

      when(mockFirestoreService.getUserWeekTemplates(any))
          .thenAnswer((_) => Stream.value(templates));

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.canSaveWeekTemplate, isFalse);
    });
  });

  group('Save Templates', () {
    test('saveWorkoutAsTemplate should create template', () async {
      when(mockFirestoreService.saveWorkoutTemplate(any))
          .thenAnswer((_) async => 'new_template_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.saveWorkoutAsTemplate(
        name: 'My Template',
        description: 'Description',
        exercises: [
          TemplateExercise(
            name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            sets: const [TemplateSet(setNumber: 1, reps: 10)],
          ),
        ],
      );

      expect(result, 'new_template_id');
      verify(mockFirestoreService.saveWorkoutTemplate(any)).called(1);
    });

    test('saveWorkoutAsTemplate should fail with empty name', () async {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.saveWorkoutAsTemplate(
        name: '   ',
        exercises: const [],
      );

      expect(result, isNull);
      expect(provider.error, 'Template name cannot be empty');
    });

    test('saveWorkoutAsTemplate should fail when at limit', () async {
      final templates = List.generate(
        10,
        (i) => WorkoutTemplate(
          id: 'template_$i',
          name: 'Template $i',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: testUserId,
          isPrebuilt: false,
        ),
      );

      when(mockFirestoreService.getUserWorkoutTemplates(any))
          .thenAnswer((_) => Stream.value(templates));

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      await Future.delayed(const Duration(milliseconds: 100));

      final result = await provider.saveWorkoutAsTemplate(
        name: 'New Template',
        exercises: const [],
      );

      expect(result, isNull);
      expect(provider.error, contains('Maximum workout templates reached'));
    });

    test('saveWeekAsTemplate should create template', () async {
      when(mockFirestoreService.saveWeekTemplate(any))
          .thenAnswer((_) async => 'week_template_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.saveWeekAsTemplate(
        name: 'PPL Week',
        workouts: const [],
      );

      expect(result, 'week_template_id');
    });

    test('saveProgramAsTemplate should create template', () async {
      when(mockFirestoreService.saveProgramTemplate(any))
          .thenAnswer((_) async => 'program_template_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.saveProgramAsTemplate(
        name: 'PPL Program',
        weeks: const [],
      );

      expect(result, 'program_template_id');
    });
  });

  group('Apply Templates', () {
    test('applyWorkoutTemplate should create workout', () async {
      when(mockFirestoreService.createWorkoutFromTemplate(
        template: anyNamed('template'),
        workoutName: anyNamed('workoutName'),
        weekId: anyNamed('weekId'),
        programId: anyNamed('programId'),
        userId: anyNamed('userId'),
        orderIndex: anyNamed('orderIndex'),
      )).thenAnswer((_) async => 'new_workout_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final template = WorkoutTemplate(
        id: 'template_1',
        name: 'Push Day',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final result = await provider.applyWorkoutTemplate(
        template: template,
        weekId: 'week_123',
        programId: 'program_123',
        customName: 'Monday Push',
      );

      expect(result, 'new_workout_id');
    });

    test('applyWorkoutTemplate should use SmartCopyNaming when no custom name',
        () async {
      when(mockFirestoreService.createWorkoutFromTemplate(
        template: anyNamed('template'),
        workoutName: anyNamed('workoutName'),
        weekId: anyNamed('weekId'),
        programId: anyNamed('programId'),
        userId: anyNamed('userId'),
        orderIndex: anyNamed('orderIndex'),
      )).thenAnswer((_) async => 'new_workout_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final template = WorkoutTemplate(
        id: 'template_1',
        name: 'Push Day',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      await provider.applyWorkoutTemplate(
        template: template,
        weekId: 'week_123',
        programId: 'program_123',
        existingWorkoutNames: ['Push Day', 'Push Day (Copy)'],
      );

      // Verify the name was generated using SmartCopyNaming
      verify(mockFirestoreService.createWorkoutFromTemplate(
        template: anyNamed('template'),
        workoutName: argThat(contains('Push Day'), named: 'workoutName'),
        weekId: anyNamed('weekId'),
        programId: anyNamed('programId'),
        userId: anyNamed('userId'),
        orderIndex: anyNamed('orderIndex'),
      )).called(1);
    });

    test('applyWeekTemplate should create week', () async {
      when(mockFirestoreService.createWeekFromTemplate(
        template: anyNamed('template'),
        weekName: anyNamed('weekName'),
        order: anyNamed('order'),
        programId: anyNamed('programId'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => 'new_week_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final template = WeekTemplate(
        id: 'template_1',
        name: 'Week Template',
        workouts: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final result = await provider.applyWeekTemplate(
        template: template,
        programId: 'program_123',
        order: 2,
      );

      expect(result, 'new_week_id');
    });

    test('applyProgramTemplate should create program', () async {
      when(mockFirestoreService.createProgramFromTemplate(
        template: anyNamed('template'),
        programName: anyNamed('programName'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => 'new_program_id');

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final template = ProgramTemplate(
        id: 'template_1',
        name: 'Program Template',
        weeks: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final result = await provider.applyProgramTemplate(
        template: template,
        customName: 'My Program',
      );

      expect(result, 'new_program_id');
    });
  });

  group('Delete Templates', () {
    test('deleteWorkoutTemplate should call service method', () async {
      when(mockFirestoreService.deleteWorkoutTemplate(any, any))
          .thenAnswer((_) async {});

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.deleteWorkoutTemplate('template_id');

      expect(result, isTrue);
      verify(mockFirestoreService.deleteWorkoutTemplate(testUserId, 'template_id'))
          .called(1);
    });

    test('deleteWeekTemplate should call service method', () async {
      when(mockFirestoreService.deleteWeekTemplate(any, any))
          .thenAnswer((_) async {});

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.deleteWeekTemplate('template_id');

      expect(result, isTrue);
    });

    test('deleteProgramTemplate should call service method', () async {
      when(mockFirestoreService.deleteProgramTemplate(any, any))
          .thenAnswer((_) async {});

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.deleteProgramTemplate('template_id');

      expect(result, isTrue);
    });
  });

  group('Rename Templates', () {
    test('renameWorkoutTemplate should update name', () async {
      when(mockFirestoreService.renameWorkoutTemplate(any, any, any))
          .thenAnswer((_) async {});

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result =
          await provider.renameWorkoutTemplate('template_id', 'New Name');

      expect(result, isTrue);
      verify(mockFirestoreService.renameWorkoutTemplate(
              testUserId, 'template_id', 'New Name'))
          .called(1);
    });

    test('renameWorkoutTemplate should fail with empty name', () async {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.renameWorkoutTemplate('template_id', '   ');

      expect(result, isFalse);
      expect(provider.error, 'Template name cannot be empty');
    });

    test('renameWeekTemplate should update name', () async {
      when(mockFirestoreService.renameWeekTemplate(any, any, any))
          .thenAnswer((_) async {});

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result =
          await provider.renameWeekTemplate('template_id', 'New Name');

      expect(result, isTrue);
    });

    test('renameProgramTemplate should update name', () async {
      when(mockFirestoreService.renameProgramTemplate(any, any, any))
          .thenAnswer((_) async {});

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result =
          await provider.renameProgramTemplate('template_id', 'New Name');

      expect(result, isTrue);
    });
  });

  group('Helper Methods', () {
    test('getWorkoutTemplateById should find template', () async {
      final template = WorkoutTemplate(
        id: 'find_me',
        name: 'Find Me',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      when(mockFirestoreService.getUserWorkoutTemplates(any))
          .thenAnswer((_) => Stream.value([template]));

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      await Future.delayed(const Duration(milliseconds: 100));

      final found = provider.getWorkoutTemplateById('find_me');
      expect(found, isNotNull);
      expect(found!.name, 'Find Me');
    });

    test('getWorkoutTemplateById should return null for not found', () {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final found = provider.getWorkoutTemplateById('nonexistent');
      expect(found, isNull);
    });

    test('clearError should reset error state', () async {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      // Trigger an error
      await provider.saveWorkoutAsTemplate(name: '', exercises: const []);
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('Error Handling', () {
    test('should handle service errors gracefully', () async {
      when(mockFirestoreService.saveWorkoutTemplate(any))
          .thenThrow(Exception('Network error'));

      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      final result = await provider.saveWorkoutAsTemplate(
        name: 'Template',
        exercises: const [],
      );

      expect(result, isNull);
      expect(provider.error, contains('Failed to save workout template'));
    });

    test('operations should fail for unauthenticated user', () async {
      provider = TemplateProvider.withFirestore(null, mockFirestoreService);

      final result = await provider.saveWorkoutAsTemplate(
        name: 'Template',
        exercises: const [],
      );

      expect(result, isNull);
      expect(provider.error, 'User not authenticated');
    });
  });

  group('Cleanup', () {
    test('dispose should cancel subscriptions', () {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      // Should not throw
      provider.dispose();

      expect(provider.workoutTemplates, isEmpty);
      expect(provider.weekTemplates, isEmpty);
      expect(provider.programTemplates, isEmpty);
    });

    test('cancelSubscriptions should clear state', () {
      provider = TemplateProvider.withFirestore(testUserId, mockFirestoreService);

      provider.cancelSubscriptions();

      expect(provider.workoutTemplates, isEmpty);
      expect(provider.error, isNull);
    });
  });
}
