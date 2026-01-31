import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/converters/template_converters.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/templates.dart';

void main() {
  group('TemplateSetConverter', () {
    test('toMap and fromMap should be inverses', () {
      const original = TemplateSet(
        setNumber: 1,
        reps: 10,
        duration: 30,
        restTime: 60,
        notes: 'Test notes',
      );

      final map = TemplateSetConverter.toMap(original);
      final restored = TemplateSetConverter.fromMap(map);

      expect(restored, original);
    });

    test('should handle minimal set', () {
      const original = TemplateSet(setNumber: 2);

      final map = TemplateSetConverter.toMap(original);
      final restored = TemplateSetConverter.fromMap(map);

      expect(restored.setNumber, 2);
      expect(restored.reps, isNull);
      expect(restored.duration, isNull);
    });
  });

  group('TemplateExerciseConverter', () {
    test('toMap and fromMap should be inverses', () {
      final original = TemplateExercise(
        name: 'Bench Press',
        exerciseType: ExerciseType.strength,
        orderIndex: 0,
        notes: 'Keep back flat',
        sets: const [
          TemplateSet(setNumber: 1, reps: 10),
          TemplateSet(setNumber: 2, reps: 8),
        ],
      );

      final map = TemplateExerciseConverter.toMap(original);
      final restored = TemplateExerciseConverter.fromMap(map);

      expect(restored.name, original.name);
      expect(restored.exerciseType, original.exerciseType);
      expect(restored.orderIndex, original.orderIndex);
      expect(restored.notes, original.notes);
      expect(restored.sets.length, original.sets.length);
    });

    test('should handle exercise with empty sets', () {
      final original = TemplateExercise(
        name: 'Pull-ups',
        exerciseType: ExerciseType.bodyweight,
        orderIndex: 1,
        sets: const [],
      );

      final map = TemplateExerciseConverter.toMap(original);
      final restored = TemplateExerciseConverter.fromMap(map);

      expect(restored.name, 'Pull-ups');
      expect(restored.sets, isEmpty);
    });
  });

  group('TemplateWorkoutConverter', () {
    test('toMap and fromMap should be inverses', () {
      final original = TemplateWorkout(
        name: 'Push Day',
        dayOfWeek: 1,
        orderIndex: 0,
        notes: 'Focus on chest',
        exercises: [
          TemplateExercise(
            name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            sets: const [TemplateSet(setNumber: 1, reps: 10)],
          ),
        ],
      );

      final map = TemplateWorkoutConverter.toMap(original);
      final restored = TemplateWorkoutConverter.fromMap(map);

      expect(restored.name, original.name);
      expect(restored.dayOfWeek, original.dayOfWeek);
      expect(restored.exercises.length, original.exercises.length);
    });

    test('should handle workout without dayOfWeek', () {
      final original = TemplateWorkout(
        name: 'Flexible Workout',
        orderIndex: 0,
        exercises: const [],
      );

      final map = TemplateWorkoutConverter.toMap(original);
      final restored = TemplateWorkoutConverter.fromMap(map);

      expect(restored.name, 'Flexible Workout');
      expect(restored.dayOfWeek, isNull);
    });
  });

  group('TemplateWeekConverter', () {
    test('toMap and fromMap should be inverses', () {
      final original = TemplateWeek(
        name: 'Week 1',
        order: 1,
        notes: 'Foundation week',
        workouts: [
          TemplateWorkout(
            name: 'Day 1',
            orderIndex: 0,
            exercises: const [],
          ),
        ],
      );

      final map = TemplateWeekConverter.toMap(original);
      final restored = TemplateWeekConverter.fromMap(map);

      expect(restored.name, original.name);
      expect(restored.order, original.order);
      expect(restored.notes, original.notes);
      expect(restored.workouts.length, original.workouts.length);
    });
  });

  group('WorkoutTemplateConverter', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testCreatedAt;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testCreatedAt = DateTime(2026, 1, 15, 10, 30);
    });

    test('toFirestore should create valid Firestore map', () {
      final template = WorkoutTemplate(
        id: 'test_id',
        name: 'Push Day',
        description: 'Chest and shoulders',
        exercises: [
          TemplateExercise(
            name: 'Bench Press',
            exerciseType: ExerciseType.strength,
            orderIndex: 0,
            sets: const [TemplateSet(setNumber: 1, reps: 10)],
          ),
        ],
        createdAt: testCreatedAt,
        userId: 'user_123',
        isPrebuilt: false,
      );

      final map = WorkoutTemplateConverter.toFirestore(template);

      expect(map['name'], 'Push Day');
      expect(map['description'], 'Chest and shoulders');
      expect(map['exercises'], isA<List>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['userId'], 'user_123');
      expect(map['isPrebuilt'], false);
      expect(map.containsKey('id'), isFalse);
    });

    test('fromFirestore should parse DocumentSnapshot', () async {
      final docRef = fakeFirestore.collection('templates').doc('test_doc');
      await docRef.set({
        'name': 'Test Template',
        'description': 'Test description',
        'exercises': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'userId': 'user_abc',
        'isPrebuilt': true,
      });

      final doc = await docRef.get();
      final template = WorkoutTemplateConverter.fromFirestore(doc);

      expect(template.id, 'test_doc');
      expect(template.name, 'Test Template');
      expect(template.description, 'Test description');
      expect(template.userId, 'user_abc');
      expect(template.isPrebuilt, true);
    });

    test('toMap should include id for nested use', () {
      final template = WorkoutTemplate(
        id: 'nested_id',
        name: 'Nested Template',
        exercises: const [],
        createdAt: testCreatedAt,
        userId: 'user',
        isPrebuilt: false,
      );

      final map = WorkoutTemplateConverter.toMap(template);

      expect(map['id'], 'nested_id');
      expect(map['name'], 'Nested Template');
    });

    test('fromMap should accept docId override', () {
      final map = {
        'id': 'map_id',
        'name': 'Test',
        'exercises': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'userId': 'user',
        'isPrebuilt': false,
      };

      final template = WorkoutTemplateConverter.fromMap(map, 'override_id');

      expect(template.id, 'override_id');
    });
  });

  group('WeekTemplateConverter', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testCreatedAt;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testCreatedAt = DateTime(2026, 1, 15, 10, 30);
    });

    test('toFirestore should create valid Firestore map', () {
      final template = WeekTemplate(
        id: 'test_id',
        name: 'PPL Week',
        description: 'Push Pull Legs',
        workouts: [
          TemplateWorkout(
            name: 'Push',
            orderIndex: 0,
            exercises: const [],
          ),
        ],
        createdAt: testCreatedAt,
        userId: 'user_123',
        isPrebuilt: false,
      );

      final map = WeekTemplateConverter.toFirestore(template);

      expect(map['name'], 'PPL Week');
      expect(map['workouts'], isA<List>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map.containsKey('id'), isFalse);
    });

    test('fromFirestore should parse DocumentSnapshot', () async {
      final docRef = fakeFirestore.collection('week_templates').doc('week_doc');
      await docRef.set({
        'name': 'Week Template',
        'workouts': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'userId': 'user_abc',
        'isPrebuilt': false,
      });

      final doc = await docRef.get();
      final template = WeekTemplateConverter.fromFirestore(doc);

      expect(template.id, 'week_doc');
      expect(template.name, 'Week Template');
    });

    test('toMap should include id for nested use', () {
      final template = WeekTemplate(
        id: 'week_nested',
        name: 'Nested Week',
        workouts: const [],
        createdAt: testCreatedAt,
        userId: 'user',
        isPrebuilt: false,
      );

      final map = WeekTemplateConverter.toMap(template);

      expect(map['id'], 'week_nested');
    });
  });

  group('ProgramTemplateConverter', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DateTime testCreatedAt;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      testCreatedAt = DateTime(2026, 1, 15, 10, 30);
    });

    test('toFirestore should create valid Firestore map', () {
      final template = ProgramTemplate(
        id: 'test_id',
        name: 'PPL Program',
        description: '12 week program',
        weeks: [
          TemplateWeek(
            name: 'Week 1',
            order: 1,
            workouts: const [],
          ),
        ],
        createdAt: testCreatedAt,
        userId: 'user_123',
        isPrebuilt: true,
      );

      final map = ProgramTemplateConverter.toFirestore(template);

      expect(map['name'], 'PPL Program');
      expect(map['weeks'], isA<List>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['isPrebuilt'], true);
      expect(map.containsKey('id'), isFalse);
    });

    test('fromFirestore should parse DocumentSnapshot', () async {
      final docRef =
          fakeFirestore.collection('program_templates').doc('prog_doc');
      await docRef.set({
        'name': 'Program Template',
        'weeks': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'userId': '',
        'isPrebuilt': true,
      });

      final doc = await docRef.get();
      final template = ProgramTemplateConverter.fromFirestore(doc);

      expect(template.id, 'prog_doc');
      expect(template.name, 'Program Template');
      expect(template.isPrebuilt, true);
    });

    test('toMap should include id for nested use', () {
      final template = ProgramTemplate(
        id: 'prog_nested',
        name: 'Nested Program',
        weeks: const [],
        createdAt: testCreatedAt,
        userId: 'user',
        isPrebuilt: false,
      );

      final map = ProgramTemplateConverter.toMap(template);

      expect(map['id'], 'prog_nested');
    });

    test('fromMap should accept docId override', () {
      final map = {
        'id': 'map_id',
        'name': 'Test',
        'weeks': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(testCreatedAt),
        'userId': 'user',
        'isPrebuilt': false,
      };

      final template = ProgramTemplateConverter.fromMap(map, 'override_id');

      expect(template.id, 'override_id');
    });

    test('full round-trip with nested structures', () async {
      final original = ProgramTemplate(
        id: 'full_test',
        name: 'Complete Program',
        description: 'Full program with all nested structures',
        weeks: [
          TemplateWeek(
            name: 'Week 1',
            order: 1,
            notes: 'Foundation',
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
                    sets: const [
                      TemplateSet(setNumber: 1, reps: 10),
                      TemplateSet(setNumber: 2, reps: 8),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        createdAt: testCreatedAt,
        userId: 'user_xyz',
        isPrebuilt: false,
        sourceUserId: 'original_author',
      );

      // Write to Firestore
      final docRef =
          fakeFirestore.collection('program_templates').doc('full_test');
      await docRef.set(ProgramTemplateConverter.toFirestore(original));

      // Read back from Firestore
      final doc = await docRef.get();
      final restored = ProgramTemplateConverter.fromFirestore(doc);

      // Verify all nested structures
      expect(restored.id, 'full_test');
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.sourceUserId, original.sourceUserId);
      expect(restored.weeks.length, 1);

      final week = restored.weeks[0];
      expect(week.name, 'Week 1');
      expect(week.order, 1);
      expect(week.notes, 'Foundation');
      expect(week.workouts.length, 1);

      final workout = week.workouts[0];
      expect(workout.name, 'Push Day');
      expect(workout.dayOfWeek, 1);
      expect(workout.exercises.length, 1);

      final exercise = workout.exercises[0];
      expect(exercise.name, 'Bench Press');
      expect(exercise.exerciseType, ExerciseType.strength);
      expect(exercise.sets.length, 2);

      expect(exercise.sets[0].reps, 10);
      expect(exercise.sets[1].reps, 8);
    });
  });
}
