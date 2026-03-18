import '../models/exercise.dart';

/// A workout item is either a standalone exercise or a superset group.
sealed class WorkoutItem {}

/// A single exercise not belonging to any superset group.
class StandaloneExercise extends WorkoutItem {
  final Exercise exercise;
  StandaloneExercise(this.exercise);
}

/// A group of exercises performed as a superset (back-to-back before resting).
class SupersetGroup extends WorkoutItem {
  final String groupId;
  final List<Exercise> exercises; // sorted by groupOrderIndex
  SupersetGroup({required this.groupId, required this.exercises});
}

/// Converts a flat [List<Exercise>] into an ordered [List<WorkoutItem>].
///
/// Algorithm:
/// 1. Sort input by [Exercise.orderIndex].
/// 2. Walk the sorted list. Exercises with [Exercise.supersetGroupId] == null
///    become [StandaloneExercise]s.
/// 3. Exercises sharing a [Exercise.supersetGroupId] are collected into a
///    [SupersetGroup] and sorted by [Exercise.groupOrderIndex].
/// 4. The position of a group in the output is determined by the [orderIndex]
///    of the first exercise in the group encountered in the sorted list.
List<WorkoutItem> groupExercises(List<Exercise> exercises) {
  if (exercises.isEmpty) return [];

  final sorted = [...exercises]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  final result = <WorkoutItem>[];
  // Map from groupId → index in result list (so we can append to existing groups)
  final groupPositions = <String, int>{};

  for (final exercise in sorted) {
    final groupId = exercise.supersetGroupId;
    if (groupId == null) {
      result.add(StandaloneExercise(exercise));
    } else {
      if (groupPositions.containsKey(groupId)) {
        // Append to existing group
        final group = result[groupPositions[groupId]!] as SupersetGroup;
        result[groupPositions[groupId]!] = SupersetGroup(
          groupId: groupId,
          exercises: [...group.exercises, exercise]
            ..sort((a, b) => (a.groupOrderIndex ?? 0).compareTo(b.groupOrderIndex ?? 0)),
        );
      } else {
        // First encounter — create new group at current position
        groupPositions[groupId] = result.length;
        result.add(SupersetGroup(
          groupId: groupId,
          exercises: [exercise],
        ));
      }
    }
  }

  return result;
}

/// Returns an alphabetic group label for the given [groupIndex] (0-based).
///
/// 0 → 'A', 1 → 'B', … 25 → 'Z', 26 → 'AA', 27 → 'AB', etc.
String computeGroupLabel(int groupIndex) {
  var index = groupIndex;
  var label = '';
  do {
    label = String.fromCharCode('A'.codeUnitAt(0) + (index % 26)) + label;
    index = index ~/ 26 - 1;
  } while (index >= 0);
  return label;
}

/// Returns a position label combining the group letter and 1-based position.
///
/// Example: groupLabel='A', positionIndex=0 → 'A1'
String computePositionLabel(String groupLabel, int positionIndex) {
  return '$groupLabel${positionIndex + 1}';
}
