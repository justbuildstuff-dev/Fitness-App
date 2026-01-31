import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/template_week.dart';
import 'package:fittrack/models/templates/template_workout.dart';
import 'package:fittrack/models/templates/template_exercise.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('TemplateWeek', () {
    late TemplateWeek sampleWeek;
    late List<TemplateWorkout> sampleWorkouts;

    setUp(() {
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
                TemplateSet(setNumber: 1, reps: 8),
                TemplateSet(setNumber: 2, reps: 8),
                TemplateSet(setNumber: 3, reps: 8),
              ],
            ),
            TemplateExercise(
              name: 'Rows',
              exerciseType: ExerciseType.strength,
              orderIndex: 1,
              sets: const [
                TemplateSet(setNumber: 1, reps: 10),
              ],
            ),
          ],
        ),
      ];

      sampleWeek = TemplateWeek(
        name: 'Week 1',
        order: 1,
        notes: 'Foundation week',
        workouts: sampleWorkouts,
      );
    });

    group('constructor', () {
      test('should create week with all fields', () {
        expect(sampleWeek.name, 'Week 1');
        expect(sampleWeek.order, 1);
        expect(sampleWeek.notes, 'Foundation week');
        expect(sampleWeek.workouts, sampleWorkouts);
      });

      test('should create week with minimal fields', () {
        final week = TemplateWeek(
          name: 'Deload Week',
          order: 4,
          workouts: const [],
        );

        expect(week.name, 'Deload Week');
        expect(week.order, 4);
        expect(week.notes, isNull);
        expect(week.workouts, isEmpty);
      });

      test('should allow const construction', () {
        const week = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: [],
        );

        expect(week.name, 'Test');
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'name': 'Week 2',
          'order': 2,
          'notes': 'Intensity week',
          'workouts': [
            {
              'name': 'Workout A',
              'dayOfWeek': 1,
              'orderIndex': 0,
              'exercises': <Map<String, dynamic>>[],
            },
          ],
        };

        final week = TemplateWeek.fromMap(map);

        expect(week.name, 'Week 2');
        expect(week.order, 2);
        expect(week.notes, 'Intensity week');
        expect(week.workouts.length, 1);
        expect(week.workouts[0].name, 'Workout A');
      });

      test('should handle missing optional fields', () {
        final map = {
          'name': 'Week 3',
          'order': 3,
          'workouts': <Map<String, dynamic>>[],
        };

        final week = TemplateWeek.fromMap(map);

        expect(week.name, 'Week 3');
        expect(week.notes, isNull);
        expect(week.workouts, isEmpty);
      });

      test('should use defaults for missing required fields', () {
        final map = <String, dynamic>{};

        final week = TemplateWeek.fromMap(map);

        expect(week.name, '');
        expect(week.order, 0);
        expect(week.workouts, isEmpty);
      });

      test('should handle missing workouts list', () {
        final map = {
          'name': 'Test',
          'order': 1,
        };

        final week = TemplateWeek.fromMap(map);

        expect(week.workouts, isEmpty);
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleWeek.toMap();

        expect(map['name'], 'Week 1');
        expect(map['order'], 1);
        expect(map['notes'], 'Foundation week');
        expect(map['workouts'], isA<List>());
        expect((map['workouts'] as List).length, 2);
      });

      test('should omit null notes', () {
        final week = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: const [],
        );
        final map = week.toMap();

        expect(map.containsKey('notes'), isFalse);
      });

      test('fromMap and toMap should be inverses', () {
        final map = sampleWeek.toMap();
        final recreated = TemplateWeek.fromMap(map);

        expect(recreated.name, sampleWeek.name);
        expect(recreated.order, sampleWeek.order);
        expect(recreated.notes, sampleWeek.notes);
        expect(recreated.workouts.length, sampleWeek.workouts.length);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final updated = sampleWeek.copyWith(name: 'Renamed Week');

        expect(updated.name, 'Renamed Week');
        expect(updated.order, sampleWeek.order);
        expect(updated.workouts, sampleWeek.workouts);
      });

      test('should create copy with updated order', () {
        final updated = sampleWeek.copyWith(order: 5);

        expect(updated.order, 5);
      });

      test('should create copy with updated notes', () {
        final updated = sampleWeek.copyWith(notes: 'New notes');

        expect(updated.notes, 'New notes');
      });

      test('should create copy with updated workouts', () {
        final newWorkouts = [
          TemplateWorkout(
            name: 'New Workout',
            orderIndex: 0,
            exercises: const [],
          ),
        ];
        final updated = sampleWeek.copyWith(workouts: newWorkouts);

        expect(updated.workouts, newWorkouts);
        expect(updated.workouts.length, 1);
      });

      test('should preserve all fields when no arguments provided', () {
        final copy = sampleWeek.copyWith();

        expect(copy, sampleWeek);
      });
    });

    group('computed properties', () {
      test('workoutCount should return number of workouts', () {
        expect(sampleWeek.workoutCount, 2);
      });

      test('workoutCount should return 0 for empty workouts', () {
        final week = TemplateWeek(
          name: 'Empty',
          order: 1,
          workouts: const [],
        );

        expect(week.workoutCount, 0);
      });

      test('totalExerciseCount should sum exercises across all workouts', () {
        // First workout has 1 exercise, second has 2 = 3 total
        expect(sampleWeek.totalExerciseCount, 3);
      });

      test('totalExerciseCount should return 0 for empty workouts', () {
        final week = TemplateWeek(
          name: 'Empty',
          order: 1,
          workouts: const [],
        );

        expect(week.totalExerciseCount, 0);
      });

      test('totalSetCount should sum sets across all workouts and exercises',
          () {
        // First workout: 2 sets, Second workout: 3 + 1 = 4 sets
        // Total: 2 + 4 = 6 sets
        expect(sampleWeek.totalSetCount, 6);
      });

      test('totalSetCount should return 0 for empty workouts', () {
        final week = TemplateWeek(
          name: 'Empty',
          order: 1,
          workouts: const [],
        );

        expect(week.totalSetCount, 0);
      });

      test('displayString should format week info', () {
        expect(sampleWeek.displayString, 'Week 1 - 2 workouts');
      });

      test('displayString should use singular for 1 workout', () {
        final week = TemplateWeek(
          name: 'Single',
          order: 1,
          workouts: [
            TemplateWorkout(
              name: 'Only One',
              orderIndex: 0,
              exercises: const [],
            ),
          ],
        );

        expect(week.displayString, 'Single - 1 workout');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final week1 = TemplateWeek(
          name: 'Test',
          order: 1,
          notes: 'Notes',
          workouts: const [],
        );
        final week2 = TemplateWeek(
          name: 'Test',
          order: 1,
          notes: 'Notes',
          workouts: const [],
        );

        expect(week1, week2);
        expect(week1.hashCode, week2.hashCode);
      });

      test('should not be equal for different names', () {
        final week1 = TemplateWeek(
          name: 'Week 1',
          order: 1,
          workouts: const [],
        );
        final week2 = TemplateWeek(
          name: 'Week 2',
          order: 1,
          workouts: const [],
        );

        expect(week1, isNot(week2));
      });

      test('should not be equal for different order', () {
        final week1 = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: const [],
        );
        final week2 = TemplateWeek(
          name: 'Test',
          order: 2,
          workouts: const [],
        );

        expect(week1, isNot(week2));
      });

      test('should not be equal for different workouts', () {
        final week1 = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: [
            TemplateWorkout(
              name: 'Workout A',
              orderIndex: 0,
              exercises: const [],
            ),
          ],
        );
        final week2 = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: [
            TemplateWorkout(
              name: 'Workout B',
              orderIndex: 0,
              exercises: const [],
            ),
          ],
        );

        expect(week1, isNot(week2));
      });

      test('should not be equal for different number of workouts', () {
        final week1 = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: const [],
        );
        final week2 = TemplateWeek(
          name: 'Test',
          order: 1,
          workouts: [
            TemplateWorkout(
              name: 'Workout',
              orderIndex: 0,
              exercises: const [],
            ),
          ],
        );

        expect(week1, isNot(week2));
      });
    });
  });
}
