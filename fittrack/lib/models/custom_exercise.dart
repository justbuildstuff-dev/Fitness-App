import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise.dart';
import 'muscle_group.dart';

/// Represents a user-created custom exercise stored in Firestore.
/// Custom exercises are mutable and scoped to individual users.
class CustomExercise {
  final String id;
  final String name;
  final ExerciseType exerciseType;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Always false for custom exercises
  bool get isLibrary => false;

  const CustomExercise({
    required this.id,
    required this.name,
    required this.exerciseType,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a CustomExercise from a Firestore document
  factory CustomExercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomExercise(
      id: doc.id,
      name: data['name'] as String,
      exerciseType: ExerciseType.fromString(data['exerciseType'] as String),
      primaryMuscles: (data['primaryMuscles'] as List<dynamic>)
          .map((m) => MuscleGroup.fromString(m as String))
          .toList(),
      secondaryMuscles: data['secondaryMuscles'] != null
          ? (data['secondaryMuscles'] as List<dynamic>)
              .map((m) => MuscleGroup.fromString(m as String))
              .toList()
          : [],
      userId: data['userId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Creates a CustomExercise from a Map (for testing without Firestore)
  factory CustomExercise.fromMap(Map<String, dynamic> map, {String? id}) {
    return CustomExercise(
      id: id ?? map['id'] as String,
      name: map['name'] as String,
      exerciseType: ExerciseType.fromString(map['exerciseType'] as String),
      primaryMuscles: (map['primaryMuscles'] as List<dynamic>)
          .map((m) => MuscleGroup.fromString(m as String))
          .toList(),
      secondaryMuscles: map['secondaryMuscles'] != null
          ? (map['secondaryMuscles'] as List<dynamic>)
              .map((m) => MuscleGroup.fromString(m as String))
              .toList()
          : [],
      userId: map['userId'] as String,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Converts to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'exerciseType': exerciseType.toMap(),
      'primaryMuscles': primaryMuscles.map((m) => m.toMap()).toList(),
      'secondaryMuscles': secondaryMuscles.map((m) => m.toMap()).toList(),
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Converts to Map format (for testing)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exerciseType': exerciseType.toMap(),
      'primaryMuscles': primaryMuscles.map((m) => m.toMap()).toList(),
      'secondaryMuscles': secondaryMuscles.map((m) => m.toMap()).toList(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy with updated fields
  CustomExercise copyWith({
    String? name,
    ExerciseType? exerciseType,
    List<MuscleGroup>? primaryMuscles,
    List<MuscleGroup>? secondaryMuscles,
    DateTime? updatedAt,
  }) {
    return CustomExercise(
      id: id,
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates the exercise name (1-50 characters)
  bool get isValidName =>
      name.trim().isNotEmpty && name.trim().length <= 50;

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
    return other is CustomExercise &&
        other.id == id &&
        other.name == name &&
        other.exerciseType == exerciseType &&
        _listEquals(other.primaryMuscles, primaryMuscles) &&
        _listEquals(other.secondaryMuscles, secondaryMuscles) &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      exerciseType,
      Object.hashAll(primaryMuscles),
      Object.hashAll(secondaryMuscles),
      userId,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomExercise(id: $id, name: $name, type: ${exerciseType.displayName}, userId: $userId)';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
