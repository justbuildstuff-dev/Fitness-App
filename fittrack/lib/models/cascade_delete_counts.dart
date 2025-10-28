/// Represents the count of child entities that will be deleted
/// in a cascade delete operation.
///
/// Used in confirmation dialogs to inform users about the scope
/// of a delete operation before they confirm.
class CascadeDeleteCounts {
  /// Number of workouts that will be deleted
  final int workouts;

  /// Number of exercises that will be deleted
  final int exercises;

  /// Number of sets that will be deleted
  final int sets;

  const CascadeDeleteCounts({
    this.workouts = 0,
    this.exercises = 0,
    this.sets = 0,
  });

  /// Total number of items that will be deleted
  int get totalItems => workouts + exercises + sets;

  /// Whether any items will be deleted
  bool get hasItems => totalItems > 0;

  /// Human-readable summary for confirmation dialogs
  ///
  /// Returns a comma-separated list of items that will be deleted.
  /// Example: "3 workouts, 9 exercises, 27 sets"
  String getSummary() {
    final List<String> parts = [];
    if (workouts > 0) {
      parts.add('$workouts workout${workouts > 1 ? 's' : ''}');
    }
    if (exercises > 0) {
      parts.add('$exercises exercise${exercises > 1 ? 's' : ''}');
    }
    if (sets > 0) {
      parts.add('$sets set${sets > 1 ? 's' : ''}');
    }
    return parts.join(', ');
  }

  @override
  String toString() =>
      'CascadeDeleteCounts(workouts: $workouts, exercises: $exercises, sets: $sets)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CascadeDeleteCounts &&
        other.workouts == workouts &&
        other.exercises == exercises &&
        other.sets == sets;
  }

  @override
  int get hashCode => Object.hash(workouts, exercises, sets);
}
