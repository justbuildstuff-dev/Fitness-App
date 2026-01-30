import '../exercise.dart';
import 'template_set.dart';

/// An exercise configuration within a template workout.
/// Contains the exercise structure with all its sets.
class TemplateExercise {
  final String name;
  final ExerciseType exerciseType;
  final int orderIndex;
  final String? notes;
  final List<TemplateSet> sets;

  const TemplateExercise({
    required this.name,
    required this.exerciseType,
    required this.orderIndex,
    this.notes,
    required this.sets,
  });

  /// Creates a TemplateExercise from a Map (JSON deserialization)
  factory TemplateExercise.fromMap(Map<String, dynamic> map) {
    return TemplateExercise(
      name: map['name'] as String? ?? '',
      exerciseType: ExerciseType.fromString(map['exerciseType'] as String? ?? 'custom'),
      orderIndex: map['orderIndex'] as int? ?? 0,
      notes: map['notes'] as String?,
      sets: (map['sets'] as List<dynamic>?)
              ?.map((s) => TemplateSet.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'exerciseType': exerciseType.toMap(),
      'orderIndex': orderIndex,
      if (notes != null) 'notes': notes,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  /// Creates a copy with optional field overrides
  TemplateExercise copyWith({
    String? name,
    ExerciseType? exerciseType,
    int? orderIndex,
    String? notes,
    List<TemplateSet>? sets,
  }) {
    return TemplateExercise(
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
    );
  }

  /// Number of sets in this exercise
  int get setCount => sets.length;

  /// Display string showing set count
  String get displayString => '$name - $setCount ${setCount == 1 ? 'set' : 'sets'}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TemplateExercise) return false;
    if (other.name != name ||
        other.exerciseType != exerciseType ||
        other.orderIndex != orderIndex ||
        other.notes != notes ||
        other.sets.length != sets.length) {
      return false;
    }
    for (int i = 0; i < sets.length; i++) {
      if (sets[i] != other.sets[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      exerciseType,
      orderIndex,
      notes,
      Object.hashAll(sets),
    );
  }
}
