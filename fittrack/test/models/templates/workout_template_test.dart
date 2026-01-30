import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/workout_template.dart';
import 'package:fittrack/models/templates/template_exercise.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('WorkoutTemplate', () {
    late WorkoutTemplate sampleTemplate;
    late List<TemplateExercise> sampleExercises;
    late DateTime testCreatedAt;

    setUp(() {
      testCreatedAt = DateTime(2026, 1, 15, 10, 30);

      sampleExercises = [
        TemplateExercise(
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [
            TemplateSet(setNumber: 1, reps: 10),
            TemplateSet(setNumber: 2, reps: 8),
            TemplateSet(setNumber: 3, reps: 6),
          ],
        ),
        TemplateExercise(
          name: 'Push-ups',
          exerciseType: ExerciseType.bodyweight,
          orderIndex: 1,
          sets: const [
            TemplateSet(setNumber: 1, reps: 20),
            TemplateSet(setNumber: 2, reps: 15),
          ],
        ),
      ];

      sampleTemplate = WorkoutTemplate(
        id: 'workout_template_123',
        name: 'Push Day Template',
        description: 'A complete chest and shoulder workout',
        exercises: sampleExercises,
        createdAt: testCreatedAt,
        userId: 'user_abc',
        isPrebuilt: false,
        sourceUserId: null,
      );
    });

    group('constructor', () {
      test('should create template with all fields', () {
        expect(sampleTemplate.id, 'workout_template_123');
        expect(sampleTemplate.name, 'Push Day Template');
        expect(sampleTemplate.description, 'A complete chest and shoulder workout');
        expect(sampleTemplate.exercises, sampleExercises);
        expect(sampleTemplate.createdAt, testCreatedAt);
        expect(sampleTemplate.userId, 'user_abc');
        expect(sampleTemplate.isPrebuilt, false);
        expect(sampleTemplate.sourceUserId, isNull);
      });

      test('should create pre-built template', () {
        final prebuilt = WorkoutTemplate(
          id: 'prebuilt_001',
          name: 'Beginner Push',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        );

        expect(prebuilt.isPrebuilt, true);
        expect(prebuilt.userId, '');
        expect(prebuilt.isUserTemplate, false);
      });

      test('should create template with minimal fields', () {
        final template = WorkoutTemplate(
          id: 'minimal_123',
          name: 'Minimal',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user_xyz',
          isPrebuilt: false,
        );

        expect(template.description, isNull);
        expect(template.sourceUserId, isNull);
        expect(template.exercises, isEmpty);
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'id': 'parsed_123',
          'name': 'Parsed Template',
          'description': 'Parsed description',
          'exercises': [
            {
              'name': 'Squat',
              'exerciseType': 'strength',
              'orderIndex': 0,
              'sets': [
                {'setNumber': 1, 'reps': 5},
              ],
            },
          ],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user_parsed',
          'isPrebuilt': false,
          'sourceUserId': 'original_user',
        };

        final template = WorkoutTemplate.fromMap(map);

        expect(template.id, 'parsed_123');
        expect(template.name, 'Parsed Template');
        expect(template.description, 'Parsed description');
        expect(template.exercises.length, 1);
        expect(template.userId, 'user_parsed');
        expect(template.isPrebuilt, false);
        expect(template.sourceUserId, 'original_user');
      });

      test('should use docId when provided', () {
        final map = {
          'id': 'map_id',
          'name': 'Test',
          'exercises': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };

        final template = WorkoutTemplate.fromMap(map, 'override_doc_id');

        expect(template.id, 'override_doc_id');
      });

      test('should handle missing optional fields', () {
        final map = {
          'name': 'Basic',
          'exercises': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };

        final template = WorkoutTemplate.fromMap(map);

        expect(template.description, isNull);
        expect(template.sourceUserId, isNull);
      });

      test('should handle DateTime from different formats', () {
        // Test Timestamp
        final mapWithTimestamp = {
          'name': 'Test',
          'exercises': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template1 = WorkoutTemplate.fromMap(mapWithTimestamp);
        expect(template1.createdAt, testCreatedAt);

        // Test ISO String
        final mapWithString = {
          'name': 'Test',
          'exercises': <Map<String, dynamic>>[],
          'createdAt': testCreatedAt.toIso8601String(),
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template2 = WorkoutTemplate.fromMap(mapWithString);
        expect(template2.createdAt, testCreatedAt);

        // Test null (should use DateTime.now())
        final mapWithNull = {
          'name': 'Test',
          'exercises': <Map<String, dynamic>>[],
          'createdAt': null,
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template3 = WorkoutTemplate.fromMap(mapWithNull);
        expect(template3.createdAt, isA<DateTime>());
      });

      test('should use defaults for missing required fields', () {
        final map = <String, dynamic>{};

        final template = WorkoutTemplate.fromMap(map);

        expect(template.id, '');
        expect(template.name, '');
        expect(template.exercises, isEmpty);
        expect(template.userId, '');
        expect(template.isPrebuilt, false);
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleTemplate.toMap();

        expect(map['name'], 'Push Day Template');
        expect(map['description'], 'A complete chest and shoulder workout');
        expect(map['exercises'], isA<List>());
        expect((map['exercises'] as List).length, 2);
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['userId'], 'user_abc');
        expect(map['isPrebuilt'], false);
      });

      test('should omit null optional fields', () {
        final template = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final map = template.toMap();

        expect(map.containsKey('description'), isFalse);
        expect(map.containsKey('sourceUserId'), isFalse);
      });

      test('should not include id in serialized map', () {
        final map = sampleTemplate.toMap();

        expect(map.containsKey('id'), isFalse);
      });

      test('fromMap and toMap should be inverses (except id)', () {
        final map = sampleTemplate.toMap();
        map['id'] = sampleTemplate.id;
        final recreated = WorkoutTemplate.fromMap(map);

        expect(recreated.id, sampleTemplate.id);
        expect(recreated.name, sampleTemplate.name);
        expect(recreated.description, sampleTemplate.description);
        expect(recreated.userId, sampleTemplate.userId);
        expect(recreated.isPrebuilt, sampleTemplate.isPrebuilt);
        expect(recreated.exercises.length, sampleTemplate.exercises.length);
      });
    });

    group('copyWith', () {
      test('should create copy with updated id', () {
        final updated = sampleTemplate.copyWith(id: 'new_id');

        expect(updated.id, 'new_id');
        expect(updated.name, sampleTemplate.name);
      });

      test('should create copy with updated name', () {
        final updated = sampleTemplate.copyWith(name: 'New Name');

        expect(updated.name, 'New Name');
        expect(updated.id, sampleTemplate.id);
      });

      test('should create copy with updated description', () {
        final updated = sampleTemplate.copyWith(description: 'New description');

        expect(updated.description, 'New description');
      });

      test('should create copy with updated exercises', () {
        final newExercises = [
          TemplateExercise(
            name: 'New Exercise',
            exerciseType: ExerciseType.cardio,
            orderIndex: 0,
            sets: const [],
          ),
        ];
        final updated = sampleTemplate.copyWith(exercises: newExercises);

        expect(updated.exercises, newExercises);
        expect(updated.exercises.length, 1);
      });

      test('should create copy with updated userId', () {
        final updated = sampleTemplate.copyWith(userId: 'new_user');

        expect(updated.userId, 'new_user');
      });

      test('should create copy with updated isPrebuilt', () {
        final updated = sampleTemplate.copyWith(isPrebuilt: true);

        expect(updated.isPrebuilt, true);
      });

      test('should preserve all fields when no arguments provided', () {
        final copy = sampleTemplate.copyWith();

        expect(copy.id, sampleTemplate.id);
        expect(copy.name, sampleTemplate.name);
        expect(copy.description, sampleTemplate.description);
        expect(copy.userId, sampleTemplate.userId);
        expect(copy.isPrebuilt, sampleTemplate.isPrebuilt);
      });
    });

    group('computed properties', () {
      test('exerciseCount should return number of exercises', () {
        expect(sampleTemplate.exerciseCount, 2);
      });

      test('exerciseCount should return 0 for empty exercises', () {
        final template = WorkoutTemplate(
          id: 'empty',
          name: 'Empty',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.exerciseCount, 0);
      });

      test('totalSetCount should sum sets across all exercises', () {
        // First exercise: 3 sets, Second exercise: 2 sets = 5 total
        expect(sampleTemplate.totalSetCount, 5);
      });

      test('totalSetCount should return 0 for empty exercises', () {
        final template = WorkoutTemplate(
          id: 'empty',
          name: 'Empty',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.totalSetCount, 0);
      });

      test('isUserTemplate should return true for user-created template', () {
        expect(sampleTemplate.isUserTemplate, true);
      });

      test('isUserTemplate should return false for pre-built template', () {
        final prebuilt = WorkoutTemplate(
          id: 'prebuilt',
          name: 'Prebuilt',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        );

        expect(prebuilt.isUserTemplate, false);
      });

      test('displayString should format template info', () {
        expect(sampleTemplate.displayString, 'Push Day Template - 2 exercises');
      });

      test('displayString should use singular for 1 exercise', () {
        final template = WorkoutTemplate(
          id: 'single',
          name: 'Single',
          exercises: [
            TemplateExercise(
              name: 'Only One',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.displayString, 'Single - 1 exercise');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final template1 = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          description: 'Desc',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          description: 'Desc',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, template2);
        expect(template1.hashCode, template2.hashCode);
      });

      test('should not be equal for different ids', () {
        final template1 = WorkoutTemplate(
          id: 'id1',
          name: 'Test',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WorkoutTemplate(
          id: 'id2',
          name: 'Test',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different names', () {
        final template1 = WorkoutTemplate(
          id: 'test',
          name: 'Name 1',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WorkoutTemplate(
          id: 'test',
          name: 'Name 2',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different isPrebuilt', () {
        final template1 = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          exercises: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: true,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different exercises', () {
        final template1 = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          exercises: [
            TemplateExercise(
              name: 'Ex 1',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WorkoutTemplate(
          id: 'test',
          name: 'Test',
          exercises: [
            TemplateExercise(
              name: 'Ex 2',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });
    });
  });
}
