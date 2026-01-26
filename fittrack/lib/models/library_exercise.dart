import 'exercise.dart';
import 'muscle_group.dart';

/// Represents an exercise from the bundled exercise library.
/// Library exercises are read-only and loaded from a JSON asset file.
class LibraryExercise {
  final String id;
  final String name;
  final ExerciseType exerciseType;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;

  /// Always true for library exercises
  bool get isLibrary => true;

  const LibraryExercise({
    required this.id,
    required this.name,
    required this.exerciseType,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
  });

  /// Creates a LibraryExercise from JSON data (bundled asset file)
  factory LibraryExercise.fromJson(Map<String, dynamic> json) {
    return LibraryExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      exerciseType: ExerciseType.fromString(json['exerciseType'] as String),
      primaryMuscles: (json['primaryMuscles'] as List<dynamic>)
          .map((m) => MuscleGroup.fromString(m as String))
          .toList(),
      secondaryMuscles: json['secondaryMuscles'] != null
          ? (json['secondaryMuscles'] as List<dynamic>)
              .map((m) => MuscleGroup.fromString(m as String))
              .toList()
          : [],
    );
  }

  /// Converts to JSON format (primarily for testing)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exerciseType': exerciseType.toMap(),
      'primaryMuscles': primaryMuscles.map((m) => m.toMap()).toList(),
      'secondaryMuscles': secondaryMuscles.map((m) => m.toMap()).toList(),
    };
  }

  /// Checks if the exercise matches a search query (case-insensitive)
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery);
  }

  /// Checks if the exercise matches a muscle group filter.
  /// Only matches against primary muscles as per PRD requirements.
  bool matchesMuscleGroup(MuscleGroup? muscleGroup) {
    if (muscleGroup == null) return true;
    return primaryMuscles.contains(muscleGroup);
  }

  /// Checks if the exercise matches an exercise type filter
  bool matchesExerciseType(ExerciseType? type) {
    if (type == null) return true;
    return exerciseType == type;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LibraryExercise &&
        other.id == id &&
        other.name == name &&
        other.exerciseType == exerciseType &&
        _listEquals(other.primaryMuscles, primaryMuscles) &&
        _listEquals(other.secondaryMuscles, secondaryMuscles);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      exerciseType,
      Object.hashAll(primaryMuscles),
      Object.hashAll(secondaryMuscles),
    );
  }

  @override
  String toString() {
    return 'LibraryExercise(id: $id, name: $name, type: ${exerciseType.displayName})';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
