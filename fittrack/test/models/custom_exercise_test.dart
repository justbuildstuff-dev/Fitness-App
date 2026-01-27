import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';

void main() {
  group('CustomExercise', () {
    late CustomExercise sampleExercise;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testCreatedAt = DateTime(2025, 1, 15, 10, 30);
      testUpdatedAt = DateTime(2025, 1, 15, 12, 0);

      sampleExercise = CustomExercise(
        id: 'custom_123',
        name: 'My Custom Press',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.chest],
        secondaryMuscles: [MuscleGroup.shoulders],
        userId: 'user_abc',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
    });

    group('constructor', () {
      test('should create exercise with required fields', () {
        final exercise = CustomExercise(
          id: 'custom_456',
          name: 'Simple Exercise',
          exerciseType: ExerciseType.bodyweight,
          primaryMuscles: [MuscleGroup.core],
          userId: 'user_xyz',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise.id, 'custom_456');
        expect(exercise.name, 'Simple Exercise');
        expect(exercise.exerciseType, ExerciseType.bodyweight);
        expect(exercise.primaryMuscles, [MuscleGroup.core]);
        expect(exercise.secondaryMuscles, isEmpty);
        expect(exercise.userId, 'user_xyz');
      });

      test('should create exercise with all fields', () {
        expect(sampleExercise.id, 'custom_123');
        expect(sampleExercise.name, 'My Custom Press');
        expect(sampleExercise.exerciseType, ExerciseType.strength);
        expect(sampleExercise.primaryMuscles, [MuscleGroup.chest]);
        expect(sampleExercise.secondaryMuscles, [MuscleGroup.shoulders]);
        expect(sampleExercise.userId, 'user_abc');
        expect(sampleExercise.createdAt, testCreatedAt);
        expect(sampleExercise.updatedAt, testUpdatedAt);
      });
    });

    group('isLibrary', () {
      test('should always return false', () {
        expect(sampleExercise.isLibrary, false);
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'id': 'custom_789',
          'name': 'Test Custom Exercise',
          'exerciseType': 'strength',
          'primaryMuscles': ['back', 'legs'],
          'secondaryMuscles': ['arms'],
          'userId': 'user_test',
          'createdAt': '2025-01-15T10:30:00.000',
          'updatedAt': '2025-01-15T12:00:00.000',
        };

        final exercise = CustomExercise.fromMap(map);

        expect(exercise.id, 'custom_789');
        expect(exercise.name, 'Test Custom Exercise');
        expect(exercise.exerciseType, ExerciseType.strength);
        expect(exercise.primaryMuscles, [MuscleGroup.back, MuscleGroup.legs]);
        expect(exercise.secondaryMuscles, [MuscleGroup.arms]);
        expect(exercise.userId, 'user_test');
      });

      test('should use provided id over map id', () {
        final map = {
          'id': 'map_id',
          'name': 'Test',
          'exerciseType': 'bodyweight',
          'primaryMuscles': ['core'],
          'userId': 'user_test',
          'createdAt': '2025-01-15T10:30:00.000',
          'updatedAt': '2025-01-15T12:00:00.000',
        };

        final exercise = CustomExercise.fromMap(map, id: 'override_id');

        expect(exercise.id, 'override_id');
      });

      test('should handle missing secondaryMuscles', () {
        final map = {
          'id': 'custom_test',
          'name': 'Test',
          'exerciseType': 'bodyweight',
          'primaryMuscles': ['chest'],
          'userId': 'user_test',
          'createdAt': '2025-01-15T10:30:00.000',
          'updatedAt': '2025-01-15T12:00:00.000',
        };

        final exercise = CustomExercise.fromMap(map);

        expect(exercise.secondaryMuscles, isEmpty);
      });
    });

    group('toMap', () {
      test('should serialize to map correctly', () {
        final map = sampleExercise.toMap();

        expect(map['id'], 'custom_123');
        expect(map['name'], 'My Custom Press');
        expect(map['exerciseType'], 'strength');
        expect(map['primaryMuscles'], ['chest']);
        expect(map['secondaryMuscles'], ['shoulders']);
        expect(map['userId'], 'user_abc');
        expect(map['createdAt'], testCreatedAt.toIso8601String());
        expect(map['updatedAt'], testUpdatedAt.toIso8601String());
      });

      test('fromMap and toMap should be inverses', () {
        final map = sampleExercise.toMap();
        final recreated = CustomExercise.fromMap(map);

        expect(recreated.id, sampleExercise.id);
        expect(recreated.name, sampleExercise.name);
        expect(recreated.exerciseType, sampleExercise.exerciseType);
        expect(recreated.primaryMuscles, sampleExercise.primaryMuscles);
        expect(recreated.secondaryMuscles, sampleExercise.secondaryMuscles);
        expect(recreated.userId, sampleExercise.userId);
      });
    });

    group('toFirestore', () {
      test('should not include id in Firestore document', () {
        final firestoreMap = sampleExercise.toFirestore();

        expect(firestoreMap.containsKey('id'), false);
        expect(firestoreMap['name'], 'My Custom Press');
        expect(firestoreMap['exerciseType'], 'strength');
        expect(firestoreMap['primaryMuscles'], ['chest']);
        expect(firestoreMap['secondaryMuscles'], ['shoulders']);
        expect(firestoreMap['userId'], 'user_abc');
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final updated = sampleExercise.copyWith(name: 'New Name');

        expect(updated.name, 'New Name');
        expect(updated.id, sampleExercise.id);
        expect(updated.exerciseType, sampleExercise.exerciseType);
        expect(updated.primaryMuscles, sampleExercise.primaryMuscles);
        expect(updated.userId, sampleExercise.userId);
      });

      test('should create copy with updated exerciseType', () {
        final updated =
            sampleExercise.copyWith(exerciseType: ExerciseType.bodyweight);

        expect(updated.exerciseType, ExerciseType.bodyweight);
        expect(updated.name, sampleExercise.name);
      });

      test('should create copy with updated muscles', () {
        final updated = sampleExercise.copyWith(
          primaryMuscles: [MuscleGroup.back],
          secondaryMuscles: [MuscleGroup.arms, MuscleGroup.core],
        );

        expect(updated.primaryMuscles, [MuscleGroup.back]);
        expect(updated.secondaryMuscles, [MuscleGroup.arms, MuscleGroup.core]);
      });

      test('should create copy with updated timestamp', () {
        final newTime = DateTime(2025, 2, 1);
        final updated = sampleExercise.copyWith(updatedAt: newTime);

        expect(updated.updatedAt, newTime);
        expect(updated.createdAt, sampleExercise.createdAt);
      });

      test('should preserve userId and createdAt', () {
        final updated = sampleExercise.copyWith(name: 'New Name');

        expect(updated.userId, sampleExercise.userId);
        expect(updated.createdAt, sampleExercise.createdAt);
      });
    });

    group('isValidName', () {
      test('should return true for valid name', () {
        expect(sampleExercise.isValidName, true);
      });

      test('should return true for name with exactly 50 characters', () {
        final exercise = CustomExercise(
          id: 'test',
          name: 'A' * 50,
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise.isValidName, true);
      });

      test('should return false for name with more than 50 characters', () {
        final exercise = CustomExercise(
          id: 'test',
          name: 'A' * 51,
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise.isValidName, false);
      });

      test('should return false for empty name', () {
        final exercise = CustomExercise(
          id: 'test',
          name: '',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise.isValidName, false);
      });

      test('should return false for whitespace-only name', () {
        final exercise = CustomExercise(
          id: 'test',
          name: '   ',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise.isValidName, false);
      });
    });

    group('matchesSearch', () {
      test('should match exact name', () {
        expect(sampleExercise.matchesSearch('My Custom Press'), true);
      });

      test('should match partial name', () {
        expect(sampleExercise.matchesSearch('Custom'), true);
        expect(sampleExercise.matchesSearch('Press'), true);
      });

      test('should be case-insensitive', () {
        expect(sampleExercise.matchesSearch('my custom'), true);
        expect(sampleExercise.matchesSearch('MY CUSTOM'), true);
      });

      test('should return true for empty query', () {
        expect(sampleExercise.matchesSearch(''), true);
      });

      test('should return false for non-matching query', () {
        expect(sampleExercise.matchesSearch('Squat'), false);
      });
    });

    group('matchesMuscleGroup', () {
      test('should match primary muscle group', () {
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.chest), true);
      });

      test('should NOT match secondary muscle group (per PRD: primary only)', () {
        // Per PRD requirements, muscle filter should only match primary muscles
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.shoulders), false);
      });

      test('should return true for null filter', () {
        expect(sampleExercise.matchesMuscleGroup(null), true);
      });

      test('should return false for non-matching muscle group', () {
        expect(sampleExercise.matchesMuscleGroup(MuscleGroup.legs), false);
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
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final exercise1 = CustomExercise(
          id: 'test',
          name: 'Test',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.arms],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final exercise2 = CustomExercise(
          id: 'test',
          name: 'Test',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.arms],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise1, exercise2);
        expect(exercise1.hashCode, exercise2.hashCode);
      });

      test('should not be equal for different ids', () {
        final exercise1 = CustomExercise(
          id: 'test1',
          name: 'Test',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final exercise2 = CustomExercise(
          id: 'test2',
          name: 'Test',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise1, isNot(exercise2));
      });

      test('should not be equal for different userIds', () {
        final exercise1 = CustomExercise(
          id: 'test',
          name: 'Test',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user1',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final exercise2 = CustomExercise(
          id: 'test',
          name: 'Test',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user2',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(exercise1, isNot(exercise2));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final str = sampleExercise.toString();

        expect(str, contains('CustomExercise'));
        expect(str, contains('custom_123'));
        expect(str, contains('My Custom Press'));
        expect(str, contains('Strength'));
        expect(str, contains('user_abc'));
      });
    });
  });
}
