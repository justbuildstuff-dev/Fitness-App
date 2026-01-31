import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/template_exercise.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('TemplateExercise', () {
    late TemplateExercise sampleExercise;
    late List<TemplateSet> sampleSets;

    setUp(() {
      sampleSets = const [
        TemplateSet(setNumber: 1, reps: 10),
        TemplateSet(setNumber: 2, reps: 8),
        TemplateSet(setNumber: 3, reps: 6),
      ];

      sampleExercise = TemplateExercise(
        name: 'Bench Press',
        exerciseType: ExerciseType.strength,
        orderIndex: 0,
        notes: 'Focus on form',
        sets: sampleSets,
      );
    });

    group('constructor', () {
      test('should create exercise with all fields', () {
        expect(sampleExercise.name, 'Bench Press');
        expect(sampleExercise.exerciseType, ExerciseType.strength);
        expect(sampleExercise.orderIndex, 0);
        expect(sampleExercise.notes, 'Focus on form');
        expect(sampleExercise.sets, sampleSets);
      });

      test('should create exercise with minimal fields', () {
        final exercise = TemplateExercise(
          name: 'Push-ups',
          exerciseType: ExerciseType.bodyweight,
          orderIndex: 1,
          sets: const [],
        );

        expect(exercise.name, 'Push-ups');
        expect(exercise.exerciseType, ExerciseType.bodyweight);
        expect(exercise.orderIndex, 1);
        expect(exercise.notes, isNull);
        expect(exercise.sets, isEmpty);
      });

      test('should allow const construction with const sets', () {
        const exercise = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: [TemplateSet(setNumber: 1, reps: 10)],
        );

        expect(exercise.name, 'Test');
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'name': 'Squat',
          'exerciseType': 'strength',
          'orderIndex': 2,
          'notes': 'Go deep',
          'sets': [
            {'setNumber': 1, 'reps': 5},
            {'setNumber': 2, 'reps': 5},
          ],
        };

        final exercise = TemplateExercise.fromMap(map);

        expect(exercise.name, 'Squat');
        expect(exercise.exerciseType, ExerciseType.strength);
        expect(exercise.orderIndex, 2);
        expect(exercise.notes, 'Go deep');
        expect(exercise.sets.length, 2);
        expect(exercise.sets[0].reps, 5);
      });

      test('should handle missing optional fields', () {
        final map = {
          'name': 'Plank',
          'exerciseType': 'bodyweight',
          'orderIndex': 0,
          'sets': <Map<String, dynamic>>[],
        };

        final exercise = TemplateExercise.fromMap(map);

        expect(exercise.name, 'Plank');
        expect(exercise.notes, isNull);
        expect(exercise.sets, isEmpty);
      });

      test('should use defaults for missing required fields', () {
        final map = <String, dynamic>{};

        final exercise = TemplateExercise.fromMap(map);

        expect(exercise.name, '');
        expect(exercise.exerciseType, ExerciseType.strength);
        expect(exercise.orderIndex, 0);
      });

      test('should handle missing sets list', () {
        final map = {
          'name': 'Test',
          'exerciseType': 'strength',
          'orderIndex': 0,
        };

        final exercise = TemplateExercise.fromMap(map);

        expect(exercise.sets, isEmpty);
      });

      test('should parse all exercise types', () {
        for (final type in ExerciseType.values) {
          final map = {
            'name': 'Test',
            'exerciseType': type.name,
            'orderIndex': 0,
            'sets': <Map<String, dynamic>>[],
          };

          final exercise = TemplateExercise.fromMap(map);

          expect(exercise.exerciseType, type);
        }
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleExercise.toMap();

        expect(map['name'], 'Bench Press');
        expect(map['exerciseType'], 'strength');
        expect(map['orderIndex'], 0);
        expect(map['notes'], 'Focus on form');
        expect(map['sets'], isA<List>());
        expect((map['sets'] as List).length, 3);
      });

      test('should omit null notes', () {
        final exercise = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [],
        );
        final map = exercise.toMap();

        expect(map.containsKey('notes'), isFalse);
      });

      test('fromMap and toMap should be inverses', () {
        final map = sampleExercise.toMap();
        final recreated = TemplateExercise.fromMap(map);

        expect(recreated.name, sampleExercise.name);
        expect(recreated.exerciseType, sampleExercise.exerciseType);
        expect(recreated.orderIndex, sampleExercise.orderIndex);
        expect(recreated.notes, sampleExercise.notes);
        expect(recreated.sets.length, sampleExercise.sets.length);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final updated = sampleExercise.copyWith(name: 'Incline Press');

        expect(updated.name, 'Incline Press');
        expect(updated.exerciseType, sampleExercise.exerciseType);
        expect(updated.sets, sampleExercise.sets);
      });

      test('should create copy with updated exerciseType', () {
        final updated =
            sampleExercise.copyWith(exerciseType: ExerciseType.bodyweight);

        expect(updated.exerciseType, ExerciseType.bodyweight);
        expect(updated.name, sampleExercise.name);
      });

      test('should create copy with updated orderIndex', () {
        final updated = sampleExercise.copyWith(orderIndex: 5);

        expect(updated.orderIndex, 5);
      });

      test('should create copy with updated notes', () {
        final updated = sampleExercise.copyWith(notes: 'New notes');

        expect(updated.notes, 'New notes');
      });

      test('should create copy with updated sets', () {
        final newSets = const [TemplateSet(setNumber: 1, reps: 15)];
        final updated = sampleExercise.copyWith(sets: newSets);

        expect(updated.sets, newSets);
        expect(updated.sets.length, 1);
      });

      test('should preserve all fields when no arguments provided', () {
        final copy = sampleExercise.copyWith();

        expect(copy.name, sampleExercise.name);
        expect(copy.exerciseType, sampleExercise.exerciseType);
        expect(copy.orderIndex, sampleExercise.orderIndex);
        expect(copy.notes, sampleExercise.notes);
        expect(copy.sets, sampleExercise.sets);
      });
    });

    group('computed properties', () {
      test('setCount should return number of sets', () {
        expect(sampleExercise.setCount, 3);
      });

      test('setCount should return 0 for empty sets', () {
        final exercise = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [],
        );

        expect(exercise.setCount, 0);
      });

      test('displayString should format exercise info', () {
        expect(sampleExercise.displayString, 'Bench Press - 3 sets');
      });

      test('displayString should use singular for 1 set', () {
        final exercise = TemplateExercise(
          name: 'Single',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [TemplateSet(setNumber: 1, reps: 10)],
        );

        expect(exercise.displayString, 'Single - 1 set');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final exercise1 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          notes: 'Notes',
          sets: const [TemplateSet(setNumber: 1, reps: 10)],
        );
        final exercise2 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          notes: 'Notes',
          sets: const [TemplateSet(setNumber: 1, reps: 10)],
        );

        expect(exercise1, exercise2);
        expect(exercise1.hashCode, exercise2.hashCode);
      });

      test('should not be equal for different names', () {
        final exercise1 = TemplateExercise(
          name: 'Exercise 1',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [],
        );
        final exercise2 = TemplateExercise(
          name: 'Exercise 2',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [],
        );

        expect(exercise1, isNot(exercise2));
      });

      test('should not be equal for different exerciseType', () {
        final exercise1 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [],
        );
        final exercise2 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.bodyweight,
          orderIndex: 0,
          sets: const [],
        );

        expect(exercise1, isNot(exercise2));
      });

      test('should not be equal for different sets', () {
        final exercise1 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [TemplateSet(setNumber: 1, reps: 10)],
        );
        final exercise2 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [TemplateSet(setNumber: 1, reps: 12)],
        );

        expect(exercise1, isNot(exercise2));
      });

      test('should not be equal for different number of sets', () {
        final exercise1 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [TemplateSet(setNumber: 1)],
        );
        final exercise2 = TemplateExercise(
          name: 'Test',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          sets: const [TemplateSet(setNumber: 1), TemplateSet(setNumber: 2)],
        );

        expect(exercise1, isNot(exercise2));
      });
    });
  });
}
