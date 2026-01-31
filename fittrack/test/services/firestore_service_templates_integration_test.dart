// ignore_for_file: avoid_print
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/templates.dart';
import 'package:fittrack/services/firestore_service.dart';
import '../helpers/firebase_integration_test_helper.dart';

/// Integration tests for FirestoreService template operations
///
/// These tests use REAL Firebase emulators and create REAL data.
/// Run Firebase emulators before running these tests:
///   firebase emulators:start
void main() {
  late FirestoreService service;
  late FirebaseFirestore firestore;
  late String testUserId;
  late DateTime testCreatedAt;

  setUpAll(() async {
    await FirebaseIntegrationTestHelper.initializeFirebase();
    firestore = FirebaseIntegrationTestHelper.firestore;
    service = FirestoreService.withFirestore(firestore);
    testCreatedAt = DateTime(2026, 1, 15, 10, 30);
  });

  setUp(() {
    testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
  });

  tearDown(() async {
    await FirebaseIntegrationTestHelper.cleanupTestData(testUserId);
  });

  group('Workout Template CRUD', () {
    test('saveWorkoutTemplate creates new template', () async {
      final template = WorkoutTemplate(
        id: '',
        name: 'Push Day Template',
        description: 'Chest and shoulders',
        exercises: [
          TemplateExercise(
            name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            sets: const [
              TemplateSet(setNumber: 1, reps: 10),
              TemplateSet(setNumber: 2, reps: 8),
            ],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveWorkoutTemplate(template);

      expect(templateId, isNotEmpty);

      // Verify in Firestore
      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('workoutTemplates')
          .doc(templateId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'Push Day Template');
      expect(doc.data()!['exercises'], isA<List>());
      expect((doc.data()!['exercises'] as List).length, 1);
    });

    test('getUserWorkoutTemplates returns stream of templates', () async {
      // Create a template first
      final template = WorkoutTemplate(
        id: '',
        name: 'Test Template',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      await service.saveWorkoutTemplate(template);

      // Get stream and verify
      final stream = service.getUserWorkoutTemplates(testUserId);
      final templates = await stream.first;

      expect(templates, isNotEmpty);
      expect(templates.first.name, 'Test Template');
    });

    test('deleteWorkoutTemplate removes template', () async {
      // Create template
      final template = WorkoutTemplate(
        id: '',
        name: 'To Delete',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveWorkoutTemplate(template);

      // Delete it
      await service.deleteWorkoutTemplate(testUserId, templateId);

      // Verify deleted
      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('workoutTemplates')
          .doc(templateId)
          .get();

      expect(doc.exists, isFalse);
    });

    test('renameWorkoutTemplate updates name', () async {
      // Create template
      final template = WorkoutTemplate(
        id: '',
        name: 'Original Name',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveWorkoutTemplate(template);

      // Rename it
      await service.renameWorkoutTemplate(testUserId, templateId, 'New Name');

      // Verify renamed
      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('workoutTemplates')
          .doc(templateId)
          .get();

      expect(doc.data()!['name'], 'New Name');
    });
  });

  group('Week Template CRUD', () {
    test('saveWeekTemplate creates new template', () async {
      final template = WeekTemplate(
        id: '',
        name: 'PPL Week',
        description: 'Push Pull Legs',
        workouts: [
          TemplateWorkout(
            name: 'Push Day',
            dayOfWeek: 1,
            orderIndex: 0,
            exercises: [
              TemplateExercise(
                name: 'Bench Press',
                exerciseType: ExerciseType.strength,
                orderIndex: 0,
                sets: const [TemplateSet(setNumber: 1, reps: 10)],
              ),
            ],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveWeekTemplate(template);

      expect(templateId, isNotEmpty);

      // Verify in Firestore
      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('weekTemplates')
          .doc(templateId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'PPL Week');
    });

    test('getUserWeekTemplates returns stream of templates', () async {
      final template = WeekTemplate(
        id: '',
        name: 'Week Template',
        workouts: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      await service.saveWeekTemplate(template);

      final stream = service.getUserWeekTemplates(testUserId);
      final templates = await stream.first;

      expect(templates, isNotEmpty);
      expect(templates.first.name, 'Week Template');
    });

    test('deleteWeekTemplate removes template', () async {
      final template = WeekTemplate(
        id: '',
        name: 'To Delete',
        workouts: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveWeekTemplate(template);
      await service.deleteWeekTemplate(testUserId, templateId);

      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('weekTemplates')
          .doc(templateId)
          .get();

      expect(doc.exists, isFalse);
    });
  });

  group('Program Template CRUD', () {
    test('saveProgramTemplate creates new template', () async {
      final template = ProgramTemplate(
        id: '',
        name: 'PPL Program',
        description: '12 Week Program',
        weeks: [
          TemplateWeek(
            name: 'Week 1',
            order: 1,
            workouts: const [],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveProgramTemplate(template);

      expect(templateId, isNotEmpty);

      // Verify in Firestore
      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('programTemplates')
          .doc(templateId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'PPL Program');
    });

    test('getUserProgramTemplates returns stream of templates', () async {
      final template = ProgramTemplate(
        id: '',
        name: 'Program Template',
        weeks: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      await service.saveProgramTemplate(template);

      final stream = service.getUserProgramTemplates(testUserId);
      final templates = await stream.first;

      expect(templates, isNotEmpty);
      expect(templates.first.name, 'Program Template');
    });

    test('deleteProgramTemplate removes template', () async {
      final template = ProgramTemplate(
        id: '',
        name: 'To Delete',
        weeks: const [],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final templateId = await service.saveProgramTemplate(template);
      await service.deleteProgramTemplate(testUserId, templateId);

      final doc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('programTemplates')
          .doc(templateId)
          .get();

      expect(doc.exists, isFalse);
    });
  });

  group('Template Application', () {
    late String testProgramId;
    late String testWeekId;

    setUp(() async {
      // Create a program and week for testing template application
      final programRef = firestore
          .collection('users')
          .doc(testUserId)
          .collection('programs')
          .doc();

      await programRef.set({
        'name': 'Test Program',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': testUserId,
      });

      testProgramId = programRef.id;

      final weekRef = programRef.collection('weeks').doc();
      await weekRef.set({
        'name': 'Week 1',
        'order': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': testUserId,
        'programId': testProgramId,
      });

      testWeekId = weekRef.id;
    });

    test('createWorkoutFromTemplate creates full hierarchy', () async {
      final template = WorkoutTemplate(
        id: 'template_1',
        name: 'Push Day Template',
        exercises: [
          TemplateExercise(
            name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            sets: const [
              TemplateSet(setNumber: 1, reps: 10),
              TemplateSet(setNumber: 2, reps: 8),
            ],
          ),
          TemplateExercise(
            name: 'Shoulder Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 1,
            sets: const [
              TemplateSet(setNumber: 1, reps: 12),
            ],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final workoutId = await service.createWorkoutFromTemplate(
        template: template,
        workoutName: 'Monday Push',
        weekId: testWeekId,
        programId: testProgramId,
        userId: testUserId,
        orderIndex: 0,
      );

      expect(workoutId, isNotEmpty);

      // Verify workout created
      final workoutDoc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('programs')
          .doc(testProgramId)
          .collection('weeks')
          .doc(testWeekId)
          .collection('workouts')
          .doc(workoutId)
          .get();

      expect(workoutDoc.exists, isTrue);
      expect(workoutDoc.data()!['name'], 'Monday Push');

      // Verify exercises created
      final exercisesSnap = await workoutDoc.reference
          .collection('exercises')
          .orderBy('orderIndex')
          .get();

      expect(exercisesSnap.docs.length, 2);
      expect(exercisesSnap.docs[0].data()['name'], 'Bench Press');
      expect(exercisesSnap.docs[1].data()['name'], 'Shoulder Press');

      // Verify sets created with reset values
      final setsSnap = await exercisesSnap.docs[0].reference
          .collection('sets')
          .orderBy('setNumber')
          .get();

      expect(setsSnap.docs.length, 2);
      expect(setsSnap.docs[0].data()['reps'], 10);
      expect(setsSnap.docs[0].data()['weight'], isNull);
      expect(setsSnap.docs[0].data()['checked'], false);
    });

    test('createWeekFromTemplate creates full hierarchy', () async {
      final template = WeekTemplate(
        id: 'week_template_1',
        name: 'PPL Week',
        workouts: [
          TemplateWorkout(
            name: 'Push',
            dayOfWeek: 1,
            orderIndex: 0,
            exercises: [
              TemplateExercise(
                name: 'Bench Press',
                exerciseType: ExerciseType.strength,
                orderIndex: 0,
                sets: const [TemplateSet(setNumber: 1, reps: 10)],
              ),
            ],
          ),
          TemplateWorkout(
            name: 'Pull',
            dayOfWeek: 2,
            orderIndex: 1,
            exercises: const [],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final weekId = await service.createWeekFromTemplate(
        template: template,
        weekName: 'Week 2',
        order: 2,
        programId: testProgramId,
        userId: testUserId,
      );

      expect(weekId, isNotEmpty);

      // Verify week created
      final weekDoc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('programs')
          .doc(testProgramId)
          .collection('weeks')
          .doc(weekId)
          .get();

      expect(weekDoc.exists, isTrue);
      expect(weekDoc.data()!['name'], 'Week 2');
      expect(weekDoc.data()!['order'], 2);

      // Verify workouts created
      final workoutsSnap = await weekDoc.reference
          .collection('workouts')
          .orderBy('orderIndex')
          .get();

      expect(workoutsSnap.docs.length, 2);
      expect(workoutsSnap.docs[0].data()['name'], 'Push');
      expect(workoutsSnap.docs[0].data()['dayOfWeek'], 1);
    });

    test('createProgramFromTemplate creates full hierarchy', () async {
      final template = ProgramTemplate(
        id: 'prog_template_1',
        name: 'PPL Program Template',
        description: '4 Week PPL',
        weeks: [
          TemplateWeek(
            name: 'Week 1',
            order: 1,
            workouts: [
              TemplateWorkout(
                name: 'Push',
                orderIndex: 0,
                exercises: [
                  TemplateExercise(
                    name: 'Bench Press',
                    exerciseType: ExerciseType.strength,
                    orderIndex: 0,
                    sets: const [
                      TemplateSet(setNumber: 1, reps: 10),
                    ],
                  ),
                ],
              ),
            ],
          ),
          TemplateWeek(
            name: 'Week 2',
            order: 2,
            workouts: const [],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final programId = await service.createProgramFromTemplate(
        template: template,
        programName: 'My PPL Program',
        userId: testUserId,
      );

      expect(programId, isNotEmpty);

      // Verify program created
      final programDoc = await firestore
          .collection('users')
          .doc(testUserId)
          .collection('programs')
          .doc(programId)
          .get();

      expect(programDoc.exists, isTrue);
      expect(programDoc.data()!['name'], 'My PPL Program');
      expect(programDoc.data()!['description'], '4 Week PPL');

      // Verify weeks created
      final weeksSnap = await programDoc.reference
          .collection('weeks')
          .orderBy('order')
          .get();

      expect(weeksSnap.docs.length, 2);
      expect(weeksSnap.docs[0].data()['name'], 'Week 1');
      expect(weeksSnap.docs[1].data()['name'], 'Week 2');

      // Verify workouts in week 1
      final workoutsSnap = await weeksSnap.docs[0].reference
          .collection('workouts')
          .get();

      expect(workoutsSnap.docs.length, 1);
      expect(workoutsSnap.docs[0].data()['name'], 'Push');

      // Verify exercises
      final exercisesSnap = await workoutsSnap.docs[0].reference
          .collection('exercises')
          .get();

      expect(exercisesSnap.docs.length, 1);
      expect(exercisesSnap.docs[0].data()['name'], 'Bench Press');

      // Verify sets with reset values
      final setsSnap = await exercisesSnap.docs[0].reference
          .collection('sets')
          .get();

      expect(setsSnap.docs.length, 1);
      expect(setsSnap.docs[0].data()['reps'], 10);
      expect(setsSnap.docs[0].data()['weight'], isNull);
      expect(setsSnap.docs[0].data()['checked'], false);
    });

    test('template application always resets tracking values', () async {
      // Even if template somehow had tracking values, they should be reset
      final template = WorkoutTemplate(
        id: 'template_reset',
        name: 'Template',
        exercises: [
          TemplateExercise(
            name: 'Exercise',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            sets: const [
              TemplateSet(
                setNumber: 1,
                reps: 10,
                duration: 60,
                restTime: 90,
              ),
            ],
          ),
        ],
        createdAt: testCreatedAt,
        userId: testUserId,
        isPrebuilt: false,
      );

      final workoutId = await service.createWorkoutFromTemplate(
        template: template,
        workoutName: 'Test Workout',
        weekId: testWeekId,
        programId: testProgramId,
        userId: testUserId,
      );

      // Get the created set
      final workoutRef = firestore
          .collection('users')
          .doc(testUserId)
          .collection('programs')
          .doc(testProgramId)
          .collection('weeks')
          .doc(testWeekId)
          .collection('workouts')
          .doc(workoutId);

      final exercisesSnap =
          await workoutRef.collection('exercises').get();
      final setsSnap = await exercisesSnap.docs[0].reference
          .collection('sets')
          .get();

      final setData = setsSnap.docs[0].data();

      // Template values should be preserved
      expect(setData['reps'], 10);
      expect(setData['duration'], 60);
      expect(setData['restTime'], 90);

      // Tracking values should always be reset
      expect(setData['weight'], isNull);
      expect(setData['distance'], isNull);
      expect(setData['checked'], false);
    });
  });
}
