import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/week_template.dart';
import 'package:fittrack/models/templates/template_workout.dart';
import 'package:fittrack/models/templates/template_exercise.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('WeekTemplate', () {
    late WeekTemplate sampleTemplate;
    late List<TemplateWorkout> sampleWorkouts;
    late DateTime testCreatedAt;

    setUp(() {
      testCreatedAt = DateTime(2026, 1, 15, 10, 30);

      sampleWorkouts = [
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
        TemplateWorkout(
          name: 'Pull Day',
          dayOfWeek: 2,
          orderIndex: 1,
          exercises: [
            TemplateExercise(
              name: 'Pull-ups',
              exerciseType: ExerciseType.bodyweight,
              orderIndex: 0,
              sets: const [
                TemplateSet(setNumber: 1, reps: 10),
                TemplateSet(setNumber: 2, reps: 10),
                TemplateSet(setNumber: 3, reps: 10),
              ],
            ),
          ],
        ),
        TemplateWorkout(
          name: 'Leg Day',
          dayOfWeek: 3,
          orderIndex: 2,
          exercises: [
            TemplateExercise(
              name: 'Squat',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [
                TemplateSet(setNumber: 1, reps: 5),
              ],
            ),
          ],
        ),
      ];

      sampleTemplate = WeekTemplate(
        id: 'week_template_123',
        name: 'PPL Week Template',
        description: 'Push Pull Legs training week',
        workouts: sampleWorkouts,
        createdAt: testCreatedAt,
        userId: 'user_abc',
        isPrebuilt: false,
        sourceUserId: null,
      );
    });

    group('constructor', () {
      test('should create template with all fields', () {
        expect(sampleTemplate.id, 'week_template_123');
        expect(sampleTemplate.name, 'PPL Week Template');
        expect(sampleTemplate.description, 'Push Pull Legs training week');
        expect(sampleTemplate.workouts, sampleWorkouts);
        expect(sampleTemplate.createdAt, testCreatedAt);
        expect(sampleTemplate.userId, 'user_abc');
        expect(sampleTemplate.isPrebuilt, false);
        expect(sampleTemplate.sourceUserId, isNull);
      });

      test('should create pre-built template', () {
        final prebuilt = WeekTemplate(
          id: 'prebuilt_001',
          name: 'Beginner Week',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        );

        expect(prebuilt.isPrebuilt, true);
        expect(prebuilt.userId, '');
        expect(prebuilt.isUserTemplate, false);
      });

      test('should create template with minimal fields', () {
        final template = WeekTemplate(
          id: 'minimal_123',
          name: 'Minimal',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user_xyz',
          isPrebuilt: false,
        );

        expect(template.description, isNull);
        expect(template.sourceUserId, isNull);
        expect(template.workouts, isEmpty);
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'id': 'parsed_123',
          'name': 'Parsed Template',
          'description': 'Parsed description',
          'workouts': [
            {
              'name': 'Workout A',
              'dayOfWeek': 1,
              'orderIndex': 0,
              'exercises': <Map<String, dynamic>>[],
            },
          ],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user_parsed',
          'isPrebuilt': false,
          'sourceUserId': 'original_user',
        };

        final template = WeekTemplate.fromMap(map);

        expect(template.id, 'parsed_123');
        expect(template.name, 'Parsed Template');
        expect(template.description, 'Parsed description');
        expect(template.workouts.length, 1);
        expect(template.userId, 'user_parsed');
        expect(template.isPrebuilt, false);
        expect(template.sourceUserId, 'original_user');
      });

      test('should use docId when provided', () {
        final map = {
          'id': 'map_id',
          'name': 'Test',
          'workouts': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };

        final template = WeekTemplate.fromMap(map, 'override_doc_id');

        expect(template.id, 'override_doc_id');
      });

      test('should handle missing optional fields', () {
        final map = {
          'name': 'Basic',
          'workouts': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };

        final template = WeekTemplate.fromMap(map);

        expect(template.description, isNull);
        expect(template.sourceUserId, isNull);
      });

      test('should handle DateTime from different formats', () {
        // Test Timestamp
        final mapWithTimestamp = {
          'name': 'Test',
          'workouts': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template1 = WeekTemplate.fromMap(mapWithTimestamp);
        expect(template1.createdAt, testCreatedAt);

        // Test ISO String
        final mapWithString = {
          'name': 'Test',
          'workouts': <Map<String, dynamic>>[],
          'createdAt': testCreatedAt.toIso8601String(),
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template2 = WeekTemplate.fromMap(mapWithString);
        expect(template2.createdAt, testCreatedAt);
      });

      test('should use defaults for missing required fields', () {
        final map = <String, dynamic>{};

        final template = WeekTemplate.fromMap(map);

        expect(template.id, '');
        expect(template.name, '');
        expect(template.workouts, isEmpty);
        expect(template.userId, '');
        expect(template.isPrebuilt, false);
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleTemplate.toMap();

        expect(map['name'], 'PPL Week Template');
        expect(map['description'], 'Push Pull Legs training week');
        expect(map['workouts'], isA<List>());
        expect((map['workouts'] as List).length, 3);
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['userId'], 'user_abc');
        expect(map['isPrebuilt'], false);
      });

      test('should omit null optional fields', () {
        final template = WeekTemplate(
          id: 'test',
          name: 'Test',
          workouts: const [],
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
        final recreated = WeekTemplate.fromMap(map);

        expect(recreated.id, sampleTemplate.id);
        expect(recreated.name, sampleTemplate.name);
        expect(recreated.description, sampleTemplate.description);
        expect(recreated.userId, sampleTemplate.userId);
        expect(recreated.isPrebuilt, sampleTemplate.isPrebuilt);
        expect(recreated.workouts.length, sampleTemplate.workouts.length);
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

      test('should create copy with updated workouts', () {
        final newWorkouts = [
          TemplateWorkout(
            name: 'New Workout',
            orderIndex: 0,
            exercises: const [],
          ),
        ];
        final updated = sampleTemplate.copyWith(workouts: newWorkouts);

        expect(updated.workouts, newWorkouts);
        expect(updated.workouts.length, 1);
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
      test('workoutCount should return number of workouts', () {
        expect(sampleTemplate.workoutCount, 3);
      });

      test('workoutCount should return 0 for empty workouts', () {
        final template = WeekTemplate(
          id: 'empty',
          name: 'Empty',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.workoutCount, 0);
      });

      test('totalExerciseCount should sum exercises across all workouts', () {
        // Each workout has 1 exercise = 3 total
        expect(sampleTemplate.totalExerciseCount, 3);
      });

      test('totalExerciseCount should return 0 for empty workouts', () {
        final template = WeekTemplate(
          id: 'empty',
          name: 'Empty',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.totalExerciseCount, 0);
      });

      test('totalSetCount should sum sets across all workouts and exercises',
          () {
        // Workout 1: 2 sets, Workout 2: 3 sets, Workout 3: 1 set = 6 total
        expect(sampleTemplate.totalSetCount, 6);
      });

      test('totalSetCount should return 0 for empty workouts', () {
        final template = WeekTemplate(
          id: 'empty',
          name: 'Empty',
          workouts: const [],
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
        final prebuilt = WeekTemplate(
          id: 'prebuilt',
          name: 'Prebuilt',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        );

        expect(prebuilt.isUserTemplate, false);
      });

      test('displayString should format template info', () {
        expect(sampleTemplate.displayString, 'PPL Week Template - 3 workouts');
      });

      test('displayString should use singular for 1 workout', () {
        final template = WeekTemplate(
          id: 'single',
          name: 'Single',
          workouts: [
            TemplateWorkout(
              name: 'Only One',
              orderIndex: 0,
              exercises: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.displayString, 'Single - 1 workout');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final template1 = WeekTemplate(
          id: 'test',
          name: 'Test',
          description: 'Desc',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WeekTemplate(
          id: 'test',
          name: 'Test',
          description: 'Desc',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, template2);
        expect(template1.hashCode, template2.hashCode);
      });

      test('should not be equal for different ids', () {
        final template1 = WeekTemplate(
          id: 'id1',
          name: 'Test',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WeekTemplate(
          id: 'id2',
          name: 'Test',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different names', () {
        final template1 = WeekTemplate(
          id: 'test',
          name: 'Name 1',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WeekTemplate(
          id: 'test',
          name: 'Name 2',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different isPrebuilt', () {
        final template1 = WeekTemplate(
          id: 'test',
          name: 'Test',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WeekTemplate(
          id: 'test',
          name: 'Test',
          workouts: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: true,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different workouts', () {
        final template1 = WeekTemplate(
          id: 'test',
          name: 'Test',
          workouts: [
            TemplateWorkout(
              name: 'Workout A',
              orderIndex: 0,
              exercises: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = WeekTemplate(
          id: 'test',
          name: 'Test',
          workouts: [
            TemplateWorkout(
              name: 'Workout B',
              orderIndex: 0,
              exercises: const [],
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
