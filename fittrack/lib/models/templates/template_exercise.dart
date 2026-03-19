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

  /// Identifies exercises that belong to the same superset group.
  /// Null means this is a standalone exercise.
  final String? supersetGroupId;

  const TemplateExercise({
    required this.name,
    required this.exerciseType,
    required this.orderIndex,
    this.notes,
    required this.sets,
    this.supersetGroupId,
  });

  /// Creates a TemplateExercise from a Map (JSON deserialization)
  factory TemplateExercise.fromMap(Map<String, dynamic> map) {
    return TemplateExercise(
      name: map['name'] as String? ?? '',
      exerciseType: ExerciseType.fromString(map['exerciseType'] as String? ?? 'strength'),
      orderIndex: _parseIntOrDefault(map['orderIndex'], 0),
      notes: map['notes'] as String?,
      sets: (map['sets'] as List<dynamic>?)
              ?.map((s) => TemplateSet.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      supersetGroupId: map['supersetGroupId'] as String?,
    );
  }

  /// Safely parse a number to int with a default value
  static int _parseIntOrDefault(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return defaultValue;
  }

  /// Converts to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'exerciseType': exerciseType.toMap(),
      'orderIndex': orderIndex,
      if (notes != null) 'notes': notes,
      'sets': sets.map((s) => s.toMap()).toList(),
      if (supersetGroupId != null) 'supersetGroupId': supersetGroupId,
    };
  }

  /// Creates a copy with optional field overrides
  TemplateExercise copyWith({
    String? name,
    ExerciseType? exerciseType,
    int? orderIndex,
    String? notes,
    List<TemplateSet>? sets,
    String? supersetGroupId,
    bool clearSupersetGroupId = false,
  }) {
    return TemplateExercise(
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
      supersetGroupId: clearSupersetGroupId
          ? null
          : (supersetGroupId ?? this.supersetGroupId),
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
        other.supersetGroupId != supersetGroupId ||
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
      supersetGroupId,
      Object.hashAll(sets),
    );
  }
}
