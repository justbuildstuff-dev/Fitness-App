import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/providers/exercise_library_provider.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';

void main() {
  group('ExerciseLibraryProvider Constants', () {
    test('maxCustomExercises should be 20', () {
      expect(maxCustomExercises, 20);
    });

    test('maxCustomExerciseNameLength should be 50', () {
      expect(maxCustomExerciseNameLength, 50);
    });
  });

  group('LibraryExercise Search Matching', () {
    late LibraryExercise benchPress;
    late LibraryExercise pullUp;
    late LibraryExercise squat;

    setUp(() {
      benchPress = const LibraryExercise(
        id: 'lib_bench_press',
        name: 'Barbell Bench Press',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.chest],
        secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.arms],
      );

      pullUp = const LibraryExercise(
        id: 'lib_pull_up',
        name: 'Pull-up',
        exerciseType: ExerciseType.bodyweight,
        primaryMuscles: [MuscleGroup.back],
        secondaryMuscles: [MuscleGroup.arms],
      );

      squat = const LibraryExercise(
        id: 'lib_squat',
        name: 'Barbell Squat',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.legs],
        secondaryMuscles: [MuscleGroup.core],
      );
    });

    group('matchesSearch', () {
      test('should match empty query', () {
        expect(benchPress.matchesSearch(''), true);
        expect(pullUp.matchesSearch(''), true);
      });

      test('should match exact name', () {
        expect(benchPress.matchesSearch('Barbell Bench Press'), true);
      });

      test('should match partial name', () {
        expect(benchPress.matchesSearch('Bench'), true);
        expect(benchPress.matchesSearch('Press'), true);
        expect(benchPress.matchesSearch('Barbell'), true);
      });

      test('should be case-insensitive', () {
        expect(benchPress.matchesSearch('bench press'), true);
        expect(benchPress.matchesSearch('BARBELL'), true);
      });

      test('should not match non-existent text', () {
        expect(benchPress.matchesSearch('Squat'), false);
      });
    });

    group('matchesMuscleGroup', () {
      test('should match null filter', () {
        expect(benchPress.matchesMuscleGroup(null), true);
      });

      test('should match primary muscle', () {
        expect(benchPress.matchesMuscleGroup(MuscleGroup.chest), true);
        expect(pullUp.matchesMuscleGroup(MuscleGroup.back), true);
        expect(squat.matchesMuscleGroup(MuscleGroup.legs), true);
      });

      test('should NOT match secondary muscle (per PRD: primary only)', () {
        // Per PRD requirements, muscle filter should only match primary muscles
        expect(benchPress.matchesMuscleGroup(MuscleGroup.shoulders), false);
        expect(benchPress.matchesMuscleGroup(MuscleGroup.arms), false);
      });

      test('should not match unrelated muscle', () {
        expect(benchPress.matchesMuscleGroup(MuscleGroup.legs), false);
        expect(pullUp.matchesMuscleGroup(MuscleGroup.chest), false);
      });
    });

    group('matchesExerciseType', () {
      test('should match null filter', () {
        expect(benchPress.matchesExerciseType(null), true);
      });

      test('should match correct type', () {
        expect(benchPress.matchesExerciseType(ExerciseType.strength), true);
        expect(pullUp.matchesExerciseType(ExerciseType.bodyweight), true);
      });

      test('should not match incorrect type', () {
        expect(benchPress.matchesExerciseType(ExerciseType.bodyweight), false);
        expect(pullUp.matchesExerciseType(ExerciseType.strength), false);
      });
    });
  });

  group('CustomExercise Search Matching', () {
    late CustomExercise customExercise;
    late DateTime testTime;

    setUp(() {
      testTime = DateTime(2025, 1, 15);
      customExercise = CustomExercise(
        id: 'custom_1',
        name: 'My Special Press',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.chest],
        secondaryMuscles: [MuscleGroup.shoulders],
        userId: 'user_123',
        createdAt: testTime,
        updatedAt: testTime,
      );
    });

    group('matchesSearch', () {
      test('should match empty query', () {
        expect(customExercise.matchesSearch(''), true);
      });

      test('should match partial name', () {
        expect(customExercise.matchesSearch('Special'), true);
        expect(customExercise.matchesSearch('Press'), true);
      });

      test('should be case-insensitive', () {
        expect(customExercise.matchesSearch('special press'), true);
        expect(customExercise.matchesSearch('MY SPECIAL'), true);
      });
    });

    group('matchesMuscleGroup', () {
      test('should match null filter', () {
        expect(customExercise.matchesMuscleGroup(null), true);
      });

      test('should match primary muscle', () {
        expect(customExercise.matchesMuscleGroup(MuscleGroup.chest), true);
      });

      test('should NOT match secondary muscle (per PRD: primary only)', () {
        // Per PRD requirements, muscle filter should only match primary muscles
        expect(customExercise.matchesMuscleGroup(MuscleGroup.shoulders), false);
      });
    });

    group('matchesExerciseType', () {
      test('should match null filter', () {
        expect(customExercise.matchesExerciseType(null), true);
      });

      test('should match correct type', () {
        expect(customExercise.matchesExerciseType(ExerciseType.strength), true);
      });

      test('should not match incorrect type', () {
        expect(
            customExercise.matchesExerciseType(ExerciseType.bodyweight), false);
      });
    });
  });

  group('CustomExercise Validation', () {
    late DateTime testTime;

    setUp(() {
      testTime = DateTime(2025, 1, 15);
    });

    group('isValidName', () {
      test('should return true for valid name', () {
        final exercise = CustomExercise(
          id: 'test',
          name: 'Valid Name',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testTime,
          updatedAt: testTime,
        );

        expect(exercise.isValidName, true);
      });

      test('should return true for name with exactly 50 characters', () {
        final exercise = CustomExercise(
          id: 'test',
          name: 'A' * 50,
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testTime,
          updatedAt: testTime,
        );

        expect(exercise.isValidName, true);
      });

      test('should return false for name exceeding 50 characters', () {
        final exercise = CustomExercise(
          id: 'test',
          name: 'A' * 51,
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          userId: 'user',
          createdAt: testTime,
          updatedAt: testTime,
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
          createdAt: testTime,
          updatedAt: testTime,
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
          createdAt: testTime,
          updatedAt: testTime,
        );

        expect(exercise.isValidName, false);
      });
    });
  });

  group('Search Result Ordering', () {
    // Note: This test validates the expected behavior - custom exercises first
    // In a real scenario, we'd use mock Firestore to test the provider

    test('custom exercises should have isLibrary = false', () {
      final testTime = DateTime(2025, 1, 15);
      final customExercise = CustomExercise(
        id: 'custom_1',
        name: 'Custom Exercise',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.chest],
        userId: 'user_123',
        createdAt: testTime,
        updatedAt: testTime,
      );

      expect(customExercise.isLibrary, false);
    });

    test('library exercises should have isLibrary = true', () {
      const libraryExercise = LibraryExercise(
        id: 'lib_1',
        name: 'Library Exercise',
        exerciseType: ExerciseType.strength,
        primaryMuscles: [MuscleGroup.chest],
      );

      expect(libraryExercise.isLibrary, true);
    });
  });

  group('Combined Filter Logic', () {
    late List<LibraryExercise> libraryExercises;

    setUp(() {
      libraryExercises = [
        const LibraryExercise(
          id: 'lib_bench_press',
          name: 'Barbell Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.shoulders],
        ),
        const LibraryExercise(
          id: 'lib_push_up',
          name: 'Push-up',
          exerciseType: ExerciseType.bodyweight,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.arms],
        ),
        const LibraryExercise(
          id: 'lib_pull_up',
          name: 'Pull-up',
          exerciseType: ExerciseType.bodyweight,
          primaryMuscles: [MuscleGroup.back],
          secondaryMuscles: [MuscleGroup.arms],
        ),
        const LibraryExercise(
          id: 'lib_squat',
          name: 'Barbell Squat',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.legs],
        ),
      ];
    });

    test('should filter by query and muscle group combined', () {
      // Simulate combined filter: query "Press" + muscle group "chest"
      final results = libraryExercises.where((e) {
        return e.matchesSearch('Press') &&
            e.matchesMuscleGroup(MuscleGroup.chest);
      }).toList();

      expect(results.length, 1);
      expect(results[0].id, 'lib_bench_press');
    });

    test('should filter by query and exercise type combined', () {
      // Simulate combined filter: query "up" + type "bodyweight"
      final results = libraryExercises.where((e) {
        return e.matchesSearch('up') &&
            e.matchesExerciseType(ExerciseType.bodyweight);
      }).toList();

      expect(results.length, 2);
      expect(results.map((e) => e.id), contains('lib_push_up'));
      expect(results.map((e) => e.id), contains('lib_pull_up'));
    });

    test('should filter by muscle group and exercise type combined', () {
      // Simulate combined filter: muscle group "chest" + type "bodyweight"
      final results = libraryExercises.where((e) {
        return e.matchesMuscleGroup(MuscleGroup.chest) &&
            e.matchesExerciseType(ExerciseType.bodyweight);
      }).toList();

      expect(results.length, 1);
      expect(results[0].id, 'lib_push_up');
    });

    test('should filter by all three criteria combined', () {
      // Simulate combined filter: query "Barbell" + muscle "chest" + type "strength"
      final results = libraryExercises.where((e) {
        return e.matchesSearch('Barbell') &&
            e.matchesMuscleGroup(MuscleGroup.chest) &&
            e.matchesExerciseType(ExerciseType.strength);
      }).toList();

      expect(results.length, 1);
      expect(results[0].id, 'lib_bench_press');
    });

    test('should return empty when no exercises match all criteria', () {
      // Query "Pull" with muscle "chest" should return nothing
      final results = libraryExercises.where((e) {
        return e.matchesSearch('Pull') &&
            e.matchesMuscleGroup(MuscleGroup.chest);
      }).toList();

      expect(results, isEmpty);
    });
  });
}
