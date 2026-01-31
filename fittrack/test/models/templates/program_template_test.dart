import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/program_template.dart';
import 'package:fittrack/models/templates/template_week.dart';
import 'package:fittrack/models/templates/template_workout.dart';
import 'package:fittrack/models/templates/template_exercise.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('ProgramTemplate', () {
    late ProgramTemplate sampleTemplate;
    late List<TemplateWeek> sampleWeeks;
    late DateTime testCreatedAt;

    setUp(() {
      testCreatedAt = DateTime(2026, 1, 15, 10, 30);

      sampleWeeks = [
        TemplateWeek(
          name: 'Week 1',
          order: 1,
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
                  ],
                ),
              ],
            ),
          ],
        ),
        TemplateWeek(
          name: 'Week 2',
          order: 2,
          workouts: [
            TemplateWorkout(
              name: 'Full Body',
              dayOfWeek: 1,
              orderIndex: 0,
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
          ],
        ),
      ];

      sampleTemplate = ProgramTemplate(
        id: 'program_template_123',
        name: 'PPL Program Template',
        description: 'A complete Push Pull Legs program',
        weeks: sampleWeeks,
        createdAt: testCreatedAt,
        userId: 'user_abc',
        isPrebuilt: false,
        sourceUserId: null,
      );
    });

    group('constructor', () {
      test('should create template with all fields', () {
        expect(sampleTemplate.id, 'program_template_123');
        expect(sampleTemplate.name, 'PPL Program Template');
        expect(sampleTemplate.description, 'A complete Push Pull Legs program');
        expect(sampleTemplate.weeks, sampleWeeks);
        expect(sampleTemplate.createdAt, testCreatedAt);
        expect(sampleTemplate.userId, 'user_abc');
        expect(sampleTemplate.isPrebuilt, false);
        expect(sampleTemplate.sourceUserId, isNull);
      });

      test('should create pre-built template', () {
        final prebuilt = ProgramTemplate(
          id: 'prebuilt_001',
          name: 'Beginner Program',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        );

        expect(prebuilt.isPrebuilt, true);
        expect(prebuilt.userId, '');
        expect(prebuilt.isUserTemplate, false);
      });

      test('should create template with minimal fields', () {
        final template = ProgramTemplate(
          id: 'minimal_123',
          name: 'Minimal',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user_xyz',
          isPrebuilt: false,
        );

        expect(template.description, isNull);
        expect(template.sourceUserId, isNull);
        expect(template.weeks, isEmpty);
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'id': 'parsed_123',
          'name': 'Parsed Template',
          'description': 'Parsed description',
          'weeks': [
            {
              'name': 'Week 1',
              'order': 1,
              'workouts': <Map<String, dynamic>>[],
            },
          ],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user_parsed',
          'isPrebuilt': false,
          'sourceUserId': 'original_user',
        };

        final template = ProgramTemplate.fromMap(map);

        expect(template.id, 'parsed_123');
        expect(template.name, 'Parsed Template');
        expect(template.description, 'Parsed description');
        expect(template.weeks.length, 1);
        expect(template.userId, 'user_parsed');
        expect(template.isPrebuilt, false);
        expect(template.sourceUserId, 'original_user');
      });

      test('should use docId when provided', () {
        final map = {
          'id': 'map_id',
          'name': 'Test',
          'weeks': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };

        final template = ProgramTemplate.fromMap(map, 'override_doc_id');

        expect(template.id, 'override_doc_id');
      });

      test('should handle missing optional fields', () {
        final map = {
          'name': 'Basic',
          'weeks': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };

        final template = ProgramTemplate.fromMap(map);

        expect(template.description, isNull);
        expect(template.sourceUserId, isNull);
      });

      test('should handle DateTime from different formats', () {
        // Test Timestamp
        final mapWithTimestamp = {
          'name': 'Test',
          'weeks': <Map<String, dynamic>>[],
          'createdAt': Timestamp.fromDate(testCreatedAt),
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template1 = ProgramTemplate.fromMap(mapWithTimestamp);
        expect(template1.createdAt, testCreatedAt);

        // Test ISO String
        final mapWithString = {
          'name': 'Test',
          'weeks': <Map<String, dynamic>>[],
          'createdAt': testCreatedAt.toIso8601String(),
          'userId': 'user',
          'isPrebuilt': false,
        };
        final template2 = ProgramTemplate.fromMap(mapWithString);
        expect(template2.createdAt, testCreatedAt);
      });

      test('should use defaults for missing required fields', () {
        final map = <String, dynamic>{};

        final template = ProgramTemplate.fromMap(map);

        expect(template.id, '');
        expect(template.name, '');
        expect(template.weeks, isEmpty);
        expect(template.userId, '');
        expect(template.isPrebuilt, false);
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleTemplate.toMap();

        expect(map['name'], 'PPL Program Template');
        expect(map['description'], 'A complete Push Pull Legs program');
        expect(map['weeks'], isA<List>());
        expect((map['weeks'] as List).length, 2);
        expect(map['createdAt'], isA<Timestamp>());
        expect(map['userId'], 'user_abc');
        expect(map['isPrebuilt'], false);
      });

      test('should omit null optional fields', () {
        final template = ProgramTemplate(
          id: 'test',
          name: 'Test',
          weeks: const [],
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
        final recreated = ProgramTemplate.fromMap(map);

        expect(recreated.id, sampleTemplate.id);
        expect(recreated.name, sampleTemplate.name);
        expect(recreated.description, sampleTemplate.description);
        expect(recreated.userId, sampleTemplate.userId);
        expect(recreated.isPrebuilt, sampleTemplate.isPrebuilt);
        expect(recreated.weeks.length, sampleTemplate.weeks.length);
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

      test('should create copy with updated weeks', () {
        final newWeeks = [
          TemplateWeek(
            name: 'New Week',
            order: 1,
            workouts: const [],
          ),
        ];
        final updated = sampleTemplate.copyWith(weeks: newWeeks);

        expect(updated.weeks, newWeeks);
        expect(updated.weeks.length, 1);
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
      test('weekCount should return number of weeks', () {
        expect(sampleTemplate.weekCount, 2);
      });

      test('weekCount should return 0 for empty weeks', () {
        final template = ProgramTemplate(
          id: 'empty',
          name: 'Empty',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.weekCount, 0);
      });

      test('totalWorkoutCount should sum workouts across all weeks', () {
        // Week 1: 2 workouts, Week 2: 1 workout = 3 total
        expect(sampleTemplate.totalWorkoutCount, 3);
      });

      test('totalWorkoutCount should return 0 for empty weeks', () {
        final template = ProgramTemplate(
          id: 'empty',
          name: 'Empty',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.totalWorkoutCount, 0);
      });

      test('totalExerciseCount should sum exercises across all weeks', () {
        // Week 1: 1 + 1 = 2 exercises, Week 2: 1 exercise = 3 total
        expect(sampleTemplate.totalExerciseCount, 3);
      });

      test('totalExerciseCount should return 0 for empty weeks', () {
        final template = ProgramTemplate(
          id: 'empty',
          name: 'Empty',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.totalExerciseCount, 0);
      });

      test('totalSetCount should sum sets across all weeks', () {
        // Week 1 Push: 2 sets, Pull: 1 set = 3; Week 2: 1 set = 4 total
        expect(sampleTemplate.totalSetCount, 4);
      });

      test('totalSetCount should return 0 for empty weeks', () {
        final template = ProgramTemplate(
          id: 'empty',
          name: 'Empty',
          weeks: const [],
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
        final prebuilt = ProgramTemplate(
          id: 'prebuilt',
          name: 'Prebuilt',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: '',
          isPrebuilt: true,
        );

        expect(prebuilt.isUserTemplate, false);
      });

      test('displayString should format template info', () {
        expect(sampleTemplate.displayString, 'PPL Program Template - 2 weeks');
      });

      test('displayString should use singular for 1 week', () {
        final template = ProgramTemplate(
          id: 'single',
          name: 'Single',
          weeks: [
            TemplateWeek(
              name: 'Only One',
              order: 1,
              workouts: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template.displayString, 'Single - 1 week');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final template1 = ProgramTemplate(
          id: 'test',
          name: 'Test',
          description: 'Desc',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = ProgramTemplate(
          id: 'test',
          name: 'Test',
          description: 'Desc',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, template2);
        expect(template1.hashCode, template2.hashCode);
      });

      test('should not be equal for different ids', () {
        final template1 = ProgramTemplate(
          id: 'id1',
          name: 'Test',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = ProgramTemplate(
          id: 'id2',
          name: 'Test',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different names', () {
        final template1 = ProgramTemplate(
          id: 'test',
          name: 'Name 1',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = ProgramTemplate(
          id: 'test',
          name: 'Name 2',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different isPrebuilt', () {
        final template1 = ProgramTemplate(
          id: 'test',
          name: 'Test',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = ProgramTemplate(
          id: 'test',
          name: 'Test',
          weeks: const [],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: true,
        );

        expect(template1, isNot(template2));
      });

      test('should not be equal for different weeks', () {
        final template1 = ProgramTemplate(
          id: 'test',
          name: 'Test',
          weeks: [
            TemplateWeek(
              name: 'Week A',
              order: 1,
              workouts: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );
        final template2 = ProgramTemplate(
          id: 'test',
          name: 'Test',
          weeks: [
            TemplateWeek(
              name: 'Week B',
              order: 1,
              workouts: const [],
            ),
          ],
          createdAt: testCreatedAt,
          userId: 'user',
          isPrebuilt: false,
        );

        expect(template1, isNot(template2));
      });
    });

    group('nested structure integrity', () {
      test('should preserve full nested structure through serialization', () {
        final map = sampleTemplate.toMap();
        map['id'] = sampleTemplate.id;
        final recreated = ProgramTemplate.fromMap(map);

        // Check weeks
        expect(recreated.weeks.length, 2);
        expect(recreated.weeks[0].name, 'Week 1');
        expect(recreated.weeks[1].name, 'Week 2');

        // Check workouts in first week
        expect(recreated.weeks[0].workouts.length, 2);
        expect(recreated.weeks[0].workouts[0].name, 'Push Day');
        expect(recreated.weeks[0].workouts[1].name, 'Pull Day');

        // Check exercises
        expect(recreated.weeks[0].workouts[0].exercises.length, 1);
        expect(recreated.weeks[0].workouts[0].exercises[0].name, 'Bench Press');

        // Check sets
        expect(recreated.weeks[0].workouts[0].exercises[0].sets.length, 2);
        expect(recreated.weeks[0].workouts[0].exercises[0].sets[0].reps, 10);
        expect(recreated.weeks[0].workouts[0].exercises[0].sets[1].reps, 8);
      });

      test('should calculate counts correctly through hierarchy', () {
        // Manual verification of counts:
        // Week 1: Push Day (1 exercise, 2 sets) + Pull Day (1 exercise, 1 set) = 2 workouts, 2 exercises, 3 sets
        // Week 2: Full Body (1 exercise, 1 set) = 1 workout, 1 exercise, 1 set
        // Total: 3 workouts, 3 exercises, 4 sets

        expect(sampleTemplate.weekCount, 2);
        expect(sampleTemplate.totalWorkoutCount, 3);
        expect(sampleTemplate.totalExerciseCount, 3);
        expect(sampleTemplate.totalSetCount, 4);
      });
    });
  });
}
