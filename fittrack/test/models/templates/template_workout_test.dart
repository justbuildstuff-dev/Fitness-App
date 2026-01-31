import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/template_workout.dart';
import 'package:fittrack/models/templates/template_exercise.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('TemplateWorkout', () {
    late TemplateWorkout sampleWorkout;
    late List<TemplateExercise> sampleExercises;

    setUp(() {
      sampleExercises = [
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
          name: 'Incline Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          sets: const [
            TemplateSet(setNumber: 1, reps: 10),
            TemplateSet(setNumber: 2, reps: 10),
            TemplateSet(setNumber: 3, reps: 10),
          ],
        ),
      ];

      sampleWorkout = TemplateWorkout(
        name: 'Push Day',
        dayOfWeek: 1, // Monday
        orderIndex: 0,
        notes: 'Chest and shoulders',
        exercises: sampleExercises,
      );
    });

    group('constructor', () {
      test('should create workout with all fields', () {
        expect(sampleWorkout.name, 'Push Day');
        expect(sampleWorkout.dayOfWeek, 1);
        expect(sampleWorkout.orderIndex, 0);
        expect(sampleWorkout.notes, 'Chest and shoulders');
        expect(sampleWorkout.exercises, sampleExercises);
      });

      test('should create workout with minimal fields', () {
        final workout = TemplateWorkout(
          name: 'Rest Day',
          orderIndex: 6,
          exercises: const [],
        );

        expect(workout.name, 'Rest Day');
        expect(workout.dayOfWeek, isNull);
        expect(workout.orderIndex, 6);
        expect(workout.notes, isNull);
        expect(workout.exercises, isEmpty);
      });

      test('should allow const construction', () {
        const workout = TemplateWorkout(
          name: 'Test',
          orderIndex: 0,
          exercises: [],
        );

        expect(workout.name, 'Test');
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'name': 'Leg Day',
          'dayOfWeek': 3,
          'orderIndex': 2,
          'notes': 'Quad focus',
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
        };

        final workout = TemplateWorkout.fromMap(map);

        expect(workout.name, 'Leg Day');
        expect(workout.dayOfWeek, 3);
        expect(workout.orderIndex, 2);
        expect(workout.notes, 'Quad focus');
        expect(workout.exercises.length, 1);
        expect(workout.exercises[0].name, 'Squat');
      });

      test('should handle missing optional fields', () {
        final map = {
          'name': 'Cardio',
          'orderIndex': 4,
          'exercises': <Map<String, dynamic>>[],
        };

        final workout = TemplateWorkout.fromMap(map);

        expect(workout.name, 'Cardio');
        expect(workout.dayOfWeek, isNull);
        expect(workout.notes, isNull);
        expect(workout.exercises, isEmpty);
      });

      test('should use defaults for missing required fields', () {
        final map = <String, dynamic>{};

        final workout = TemplateWorkout.fromMap(map);

        expect(workout.name, '');
        expect(workout.orderIndex, 0);
        expect(workout.exercises, isEmpty);
      });

      test('should handle missing exercises list', () {
        final map = {
          'name': 'Test',
          'orderIndex': 0,
        };

        final workout = TemplateWorkout.fromMap(map);

        expect(workout.exercises, isEmpty);
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleWorkout.toMap();

        expect(map['name'], 'Push Day');
        expect(map['dayOfWeek'], 1);
        expect(map['orderIndex'], 0);
        expect(map['notes'], 'Chest and shoulders');
        expect(map['exercises'], isA<List>());
        expect((map['exercises'] as List).length, 2);
      });

      test('should omit null optional fields', () {
        final workout = TemplateWorkout(
          name: 'Test',
          orderIndex: 0,
          exercises: const [],
        );
        final map = workout.toMap();

        expect(map.containsKey('dayOfWeek'), isFalse);
        expect(map.containsKey('notes'), isFalse);
      });

      test('fromMap and toMap should be inverses', () {
        final map = sampleWorkout.toMap();
        final recreated = TemplateWorkout.fromMap(map);

        expect(recreated.name, sampleWorkout.name);
        expect(recreated.dayOfWeek, sampleWorkout.dayOfWeek);
        expect(recreated.orderIndex, sampleWorkout.orderIndex);
        expect(recreated.notes, sampleWorkout.notes);
        expect(recreated.exercises.length, sampleWorkout.exercises.length);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final updated = sampleWorkout.copyWith(name: 'New Name');

        expect(updated.name, 'New Name');
        expect(updated.dayOfWeek, sampleWorkout.dayOfWeek);
        expect(updated.exercises, sampleWorkout.exercises);
      });

      test('should create copy with updated dayOfWeek', () {
        final updated = sampleWorkout.copyWith(dayOfWeek: 5);

        expect(updated.dayOfWeek, 5);
      });

      test('should create copy with updated orderIndex', () {
        final updated = sampleWorkout.copyWith(orderIndex: 3);

        expect(updated.orderIndex, 3);
      });

      test('should create copy with updated notes', () {
        final updated = sampleWorkout.copyWith(notes: 'New notes');

        expect(updated.notes, 'New notes');
      });

      test('should create copy with updated exercises', () {
        final newExercises = [
          TemplateExercise(
            name: 'New Exercise',
            exerciseType: ExerciseType.bodyweight,
            orderIndex: 0,
            sets: const [],
          ),
        ];
        final updated = sampleWorkout.copyWith(exercises: newExercises);

        expect(updated.exercises, newExercises);
        expect(updated.exercises.length, 1);
      });

      test('should preserve all fields when no arguments provided', () {
        final copy = sampleWorkout.copyWith();

        expect(copy, sampleWorkout);
      });
    });

    group('computed properties', () {
      test('exerciseCount should return number of exercises', () {
        expect(sampleWorkout.exerciseCount, 2);
      });

      test('exerciseCount should return 0 for empty exercises', () {
        final workout = TemplateWorkout(
          name: 'Empty',
          orderIndex: 0,
          exercises: const [],
        );

        expect(workout.exerciseCount, 0);
      });

      test('totalSetCount should sum sets across all exercises', () {
        // First exercise has 2 sets, second has 3 sets = 5 total
        expect(sampleWorkout.totalSetCount, 5);
      });

      test('totalSetCount should return 0 for empty exercises', () {
        final workout = TemplateWorkout(
          name: 'Empty',
          orderIndex: 0,
          exercises: const [],
        );

        expect(workout.totalSetCount, 0);
      });

      test('displayString should format workout info', () {
        expect(sampleWorkout.displayString, 'Push Day - 2 exercises');
      });

      test('displayString should use singular for 1 exercise', () {
        final workout = TemplateWorkout(
          name: 'Single',
          orderIndex: 0,
          exercises: [
            TemplateExercise(
              name: 'Only One',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [],
            ),
          ],
        );

        expect(workout.displayString, 'Single - 1 exercise');
      });
    });

    group('dayOfWeekDisplay', () {
      test('should return Monday for dayOfWeek 1', () {
        expect(sampleWorkout.dayOfWeekDisplay, 'Monday');
      });

      test('should return correct day names for all days', () {
        final days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];

        for (int i = 1; i <= 7; i++) {
          final workout = TemplateWorkout(
            name: 'Test',
            dayOfWeek: i,
            orderIndex: 0,
            exercises: const [],
          );

          expect(workout.dayOfWeekDisplay, days[i - 1]);
        }
      });

      test('should return null for null dayOfWeek', () {
        final workout = TemplateWorkout(
          name: 'Test',
          orderIndex: 0,
          exercises: const [],
        );

        expect(workout.dayOfWeekDisplay, isNull);
      });

      test('should return null for out of range dayOfWeek', () {
        final workout1 = TemplateWorkout(
          name: 'Test',
          dayOfWeek: 0,
          orderIndex: 0,
          exercises: const [],
        );
        final workout2 = TemplateWorkout(
          name: 'Test',
          dayOfWeek: 8,
          orderIndex: 0,
          exercises: const [],
        );

        expect(workout1.dayOfWeekDisplay, isNull);
        expect(workout2.dayOfWeekDisplay, isNull);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final workout1 = TemplateWorkout(
          name: 'Test',
          dayOfWeek: 1,
          orderIndex: 0,
          notes: 'Notes',
          exercises: const [],
        );
        final workout2 = TemplateWorkout(
          name: 'Test',
          dayOfWeek: 1,
          orderIndex: 0,
          notes: 'Notes',
          exercises: const [],
        );

        expect(workout1, workout2);
        expect(workout1.hashCode, workout2.hashCode);
      });

      test('should not be equal for different names', () {
        final workout1 = TemplateWorkout(
          name: 'Workout 1',
          orderIndex: 0,
          exercises: const [],
        );
        final workout2 = TemplateWorkout(
          name: 'Workout 2',
          orderIndex: 0,
          exercises: const [],
        );

        expect(workout1, isNot(workout2));
      });

      test('should not be equal for different dayOfWeek', () {
        final workout1 = TemplateWorkout(
          name: 'Test',
          dayOfWeek: 1,
          orderIndex: 0,
          exercises: const [],
        );
        final workout2 = TemplateWorkout(
          name: 'Test',
          dayOfWeek: 2,
          orderIndex: 0,
          exercises: const [],
        );

        expect(workout1, isNot(workout2));
      });

      test('should not be equal for different exercises', () {
        final workout1 = TemplateWorkout(
          name: 'Test',
          orderIndex: 0,
          exercises: [
            TemplateExercise(
              name: 'Ex 1',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [],
            ),
          ],
        );
        final workout2 = TemplateWorkout(
          name: 'Test',
          orderIndex: 0,
          exercises: [
            TemplateExercise(
              name: 'Ex 2',
              exerciseType: ExerciseType.strength,
              orderIndex: 0,
              sets: const [],
            ),
          ],
        );

        expect(workout1, isNot(workout2));
      });
    });
  });
}
