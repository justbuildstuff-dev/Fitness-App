import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';

void main() {
  group('LibraryExercise', () {
    late LibraryExercise sampleExercise;

    setUp(() {
      sampleExercise = const LibraryExercise(
        id: 'lib_bench_press',
        name: 'Barbell Bench Press',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.chest],
        secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.arms],
      );
    });

    group('constructor', () {
      test('should create exercise with required fields', () {
        const exercise = LibraryExercise(
          id: 'lib_squat',
          name: 'Barbell Squat',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.legs],
        );

        expect(exercise.id, 'lib_squat');
        expect(exercise.name, 'Barbell Squat');
        expect(exercise.exerciseType, ExerciseType.strength);
        expect(exercise.primaryMuscles, [MuscleGroup.legs]);
        expect(exercise.secondaryMuscles, isEmpty);
      });

      test('should create exercise with all fields', () {
        expect(sampleExercise.id, 'lib_bench_press');
        expect(sampleExercise.name, 'Barbell Bench Press');
        expect(sampleExercise.exerciseType, ExerciseType.strength);
        expect(sampleExercise.primaryMuscles, [MuscleGroup.chest]);
        expect(sampleExercise.secondaryMuscles,
            [MuscleGroup.shoulders, MuscleGroup.arms]);
      });
    });

    group('isLibrary', () {
      test('should always return true', () {
        expect(sampleExercise.isLibrary, true);
      });
    });

    group('fromJson', () {
      test('should parse JSON with all fields', () {
        final json = {
          'id': 'lib_deadlift',
          'name': 'Barbell Deadlift',
          'exerciseType': 'strength',
          'primaryMuscles': ['back', 'legs'],
          'secondaryMuscles': ['arms', 'core'],
        };

        final exercise = LibraryExercise.fromJson(json);

        expect(exercise.id, 'lib_deadlift');
        expect(exercise.name, 'Barbell Deadlift');
        expect(exercise.exerciseType, ExerciseType.strength);
        expect(exercise.primaryMuscles, [MuscleGroup.back, MuscleGroup.legs]);
        expect(exercise.secondaryMuscles, [MuscleGroup.arms, MuscleGroup.core]);
      });

      test('should parse JSON without secondaryMuscles', () {
        final json = {
          'id': 'lib_pullup',
          'name': 'Pull-up',
          'exerciseType': 'bodyweight',
          'primaryMuscles': ['back'],
        };

        final exercise = LibraryExercise.fromJson(json);

        expect(exercise.id, 'lib_pullup');
        expect(exercise.name, 'Pull-up');
        expect(exercise.exerciseType, ExerciseType.bodyweight);
        expect(exercise.primaryMuscles, [MuscleGroup.back]);
        expect(exercise.secondaryMuscles, isEmpty);
      });

      test('should parse JSON with empty secondaryMuscles', () {
        final json = {
          'id': 'lib_pushup',
          'name': 'Push-up',
          'exerciseType': 'bodyweight',
          'primaryMuscles': ['chest'],
          'secondaryMuscles': <String>[],
        };

        final exercise = LibraryExercise.fromJson(json);

        expect(exercise.secondaryMuscles, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize to JSON correctly', () {
        final json = sampleExercise.toJson();

        expect(json['id'], 'lib_bench_press');
        expect(json['name'], 'Barbell Bench Press');
        expect(json['exerciseType'], 'strength');
        expect(json['primaryMuscles'], ['chest']);
        expect(json['secondaryMuscles'], ['shoulders', 'arms']);
      });

      test('fromJson and toJson should be inverses', () {
        final json = sampleExercise.toJson();
        final recreated = LibraryExercise.fromJson(json);

        expect(recreated, sampleExercise);
      });
    });

    group('matchesSearch', () {
      test('should match exact name', () {
        expect(sampleExercise.matchesSearch('Barbell Bench Press'), true);
      });

      test('should match partial name', () {
        expect(sampleExercise.matchesSearch('Bench'), true);
        expect(sampleExercise.matchesSearch('Press'), true);
        expect(sampleExercise.matchesSearch('Barbell'), true);
      });

      test('should be case-insensitive', () {
        expect(sampleExercise.matchesSearch('bench press'), true);
        expect(sampleExercise.matchesSearch('BENCH'), true);
        expect(sampleExercise.matchesSearch('bEnCh'), true);
      });

      test('should return true for empty query', () {
        expect(sampleExercise.matchesSearch(''), true);
      });

      test('should return false for non-matching query', () {
        expect(sampleExercise.matchesSearch('Squat'), false);
        expect(sampleExercise.matchesSearch('Deadlift'), false);
      });
    });

    group('matchesMuscleGroup', () {
      test('should match primary muscle group', () {
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.chest), true);
      });

      test('should match secondary muscle group', () {
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.shoulders), true);
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.arms), true);
      });

      test('should return true for null filter', () {
        expect(sampleExercise.matchesMuscleGroup(null), true);
      });

      test('should return false for non-matching muscle group', () {
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.legs), false);
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.core), false);
      });
    });

    group('matchesExerciseType', () {
      test('should match correct exercise type', () {
        expect(sampleExercise.matchesExerciseType(ExerciseType.strength), true);
      });

      test('should return true for null filter', () {
        expect(sampleExercise.matchesExerciseType(null), true);
      });

      test('should return false for non-matching type', () {
        expect(
            sampleExercise.matchesExerciseType(ExerciseType.bodyweight), false);
        expect(sampleExercise.matchesExerciseType(ExerciseType.cardio), false);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const exercise1 = LibraryExercise(
          id: 'lib_test',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.arms],
        );

        const exercise2 = LibraryExercise(
          id: 'lib_test',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.arms],
        );

        expect(exercise1, exercise2);
        expect(exercise1.hashCode, exercise2.hashCode);
      });

      test('should not be equal for different ids', () {
        const exercise1 = LibraryExercise(
          id: 'lib_test1',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        );

        const exercise2 = LibraryExercise(
          id: 'lib_test2',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        );

        expect(exercise1, isNot(exercise2));
      });

      test('should not be equal for different names', () {
        const exercise1 = LibraryExercise(
          id: 'lib_test',
          name: 'Test Exercise 1',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        );

        const exercise2 = LibraryExercise(
          id: 'lib_test',
          name: 'Test Exercise 2',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        );

        expect(exercise1, isNot(exercise2));
      });

      test('should not be equal for different muscle groups', () {
        const exercise1 = LibraryExercise(
          id: 'lib_test',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        );

        const exercise2 = LibraryExercise(
          id: 'lib_test',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.back],
        );

        expect(exercise1, isNot(exercise2));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final str = sampleExercise.toString();

        expect(str, contains('LibraryExercise'));
        expect(str, contains('lib_bench_press'));
        expect(str, contains('Barbell Bench Press'));
        expect(str, contains('Strength'));
      });
    });
  });
}
