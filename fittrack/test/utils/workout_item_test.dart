/// Unit tests for WorkoutItem utility and group label computation.
///
/// Test Coverage:
/// - groupExercises: flat list, single group, multiple groups, edge cases
/// - computeGroupLabel: single-letter, boundary Z→AA, multi-letter
/// - computePositionLabel: A1/A2 format
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/utils/workout_item.dart';

Exercise _makeExercise({
  required String id,
  required int orderIndex,
  String? supersetGroupId,
  int? groupOrderIndex,
}) {
  final now = DateTime(2025, 1, 1);
  return Exercise(
    id: id,
    name: 'Exercise $id',
    exerciseType: ExerciseType.strength,
    orderIndex: orderIndex,
    createdAt: now,
    updatedAt: now,
    userId: 'user-1',
    workoutId: 'workout-1',
    weekId: 'week-1',
    programId: 'program-1',
    supersetGroupId: supersetGroupId,
    groupOrderIndex: groupOrderIndex,
  );
}

void main() {
  group('groupExercises', () {
    test('empty list returns empty list', () {
      expect(groupExercises([]), isEmpty);
    });

    test('flat list with no supersets produces all StandaloneExercise items', () {
      final exercises = [
        _makeExercise(id: 'e1', orderIndex: 0),
        _makeExercise(id: 'e2', orderIndex: 1),
        _makeExercise(id: 'e3', orderIndex: 2),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 3);
      expect(items[0], isA<StandaloneExercise>());
      expect(items[1], isA<StandaloneExercise>());
      expect(items[2], isA<StandaloneExercise>());
      expect((items[0] as StandaloneExercise).exercise.id, 'e1');
      expect((items[1] as StandaloneExercise).exercise.id, 'e2');
      expect((items[2] as StandaloneExercise).exercise.id, 'e3');
    });

    test('single 2-exercise superset between standalones', () {
      final exercises = [
        _makeExercise(id: 'e1', orderIndex: 0),
        _makeExercise(id: 'e2', orderIndex: 1, supersetGroupId: 'group-A', groupOrderIndex: 0),
        _makeExercise(id: 'e3', orderIndex: 2, supersetGroupId: 'group-A', groupOrderIndex: 1),
        _makeExercise(id: 'e4', orderIndex: 3),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 3);
      expect(items[0], isA<StandaloneExercise>());
      expect(items[1], isA<SupersetGroup>());
      expect(items[2], isA<StandaloneExercise>());

      final group = items[1] as SupersetGroup;
      expect(group.groupId, 'group-A');
      expect(group.exercises.length, 2);
      expect(group.exercises[0].id, 'e2');
      expect(group.exercises[1].id, 'e3');
    });

    test('two superset groups are ordered by first exercise orderIndex', () {
      final exercises = [
        _makeExercise(id: 'e1', orderIndex: 0, supersetGroupId: 'group-A', groupOrderIndex: 0),
        _makeExercise(id: 'e2', orderIndex: 1, supersetGroupId: 'group-A', groupOrderIndex: 1),
        _makeExercise(id: 'e3', orderIndex: 2, supersetGroupId: 'group-B', groupOrderIndex: 0),
        _makeExercise(id: 'e4', orderIndex: 3, supersetGroupId: 'group-B', groupOrderIndex: 1),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 2);
      expect(items[0], isA<SupersetGroup>());
      expect(items[1], isA<SupersetGroup>());
      expect((items[0] as SupersetGroup).groupId, 'group-A');
      expect((items[1] as SupersetGroup).groupId, 'group-B');
    });

    test('group exercises are sorted by groupOrderIndex regardless of orderIndex', () {
      // Intentionally out of order groupOrderIndex relative to orderIndex
      final exercises = [
        _makeExercise(id: 'e2', orderIndex: 0, supersetGroupId: 'group-A', groupOrderIndex: 1),
        _makeExercise(id: 'e1', orderIndex: 1, supersetGroupId: 'group-A', groupOrderIndex: 0),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 1);
      final group = items[0] as SupersetGroup;
      expect(group.exercises[0].id, 'e1'); // groupOrderIndex 0 first
      expect(group.exercises[1].id, 'e2'); // groupOrderIndex 1 second
    });

    test('all exercises in one group produces single SupersetGroup', () {
      final exercises = [
        _makeExercise(id: 'e1', orderIndex: 0, supersetGroupId: 'group-A', groupOrderIndex: 0),
        _makeExercise(id: 'e2', orderIndex: 1, supersetGroupId: 'group-A', groupOrderIndex: 1),
        _makeExercise(id: 'e3', orderIndex: 2, supersetGroupId: 'group-A', groupOrderIndex: 2),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 1);
      expect(items[0], isA<SupersetGroup>());
      final group = items[0] as SupersetGroup;
      expect(group.exercises.length, 3);
    });

    test('exercises sorted by orderIndex before grouping', () {
      // Input deliberately unsorted
      final exercises = [
        _makeExercise(id: 'e3', orderIndex: 2),
        _makeExercise(id: 'e1', orderIndex: 0),
        _makeExercise(id: 'e2', orderIndex: 1),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 3);
      expect((items[0] as StandaloneExercise).exercise.id, 'e1');
      expect((items[1] as StandaloneExercise).exercise.id, 'e2');
      expect((items[2] as StandaloneExercise).exercise.id, 'e3');
    });

    test('mixed standalone and group exercises maintain relative order', () {
      final exercises = [
        _makeExercise(id: 'standalone1', orderIndex: 0),
        _makeExercise(id: 'g1a', orderIndex: 1, supersetGroupId: 'group-A', groupOrderIndex: 0),
        _makeExercise(id: 'g1b', orderIndex: 2, supersetGroupId: 'group-A', groupOrderIndex: 1),
        _makeExercise(id: 'standalone2', orderIndex: 3),
        _makeExercise(id: 'g2a', orderIndex: 4, supersetGroupId: 'group-B', groupOrderIndex: 0),
        _makeExercise(id: 'g2b', orderIndex: 5, supersetGroupId: 'group-B', groupOrderIndex: 1),
      ];

      final items = groupExercises(exercises);

      expect(items.length, 4);
      expect(items[0], isA<StandaloneExercise>());
      expect(items[1], isA<SupersetGroup>());
      expect(items[2], isA<StandaloneExercise>());
      expect(items[3], isA<SupersetGroup>());
    });
  });

  group('computeGroupLabel', () {
    test('index 0 returns A', () {
      expect(computeGroupLabel(0), 'A');
    });

    test('index 25 returns Z', () {
      expect(computeGroupLabel(25), 'Z');
    });

    test('index 26 returns AA', () {
      expect(computeGroupLabel(26), 'AA');
    });

    test('index 27 returns AB', () {
      expect(computeGroupLabel(27), 'AB');
    });

    test('index 51 returns AZ', () {
      expect(computeGroupLabel(51), 'AZ');
    });

    test('index 52 returns BA', () {
      expect(computeGroupLabel(52), 'BA');
    });

    test('single-letter labels for first 26 indices', () {
      for (var i = 0; i < 26; i++) {
        expect(computeGroupLabel(i), String.fromCharCode('A'.codeUnitAt(0) + i));
      }
    });
  });

  group('computePositionLabel', () {
    test('A group index 0 returns A1', () {
      expect(computePositionLabel('A', 0), 'A1');
    });

    test('A group index 1 returns A2', () {
      expect(computePositionLabel('A', 1), 'A2');
    });

    test('B group index 0 returns B1', () {
      expect(computePositionLabel('B', 0), 'B1');
    });

    test('multi-letter group label works correctly', () {
      expect(computePositionLabel('AA', 0), 'AA1');
      expect(computePositionLabel('AA', 2), 'AA3');
    });
  });
}
