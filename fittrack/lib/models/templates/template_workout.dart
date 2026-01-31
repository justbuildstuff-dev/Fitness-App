import 'template_exercise.dart';

/// A workout configuration within a template week.
/// Contains the workout structure with all its exercises.
class TemplateWorkout {
  final String name;
  final int? dayOfWeek; // 1-7 (Monday-Sunday), null if not specified
  final int orderIndex;
  final String? notes;
  final List<TemplateExercise> exercises;

  const TemplateWorkout({
    required this.name,
    this.dayOfWeek,
    required this.orderIndex,
    this.notes,
    required this.exercises,
  });

  /// Creates a TemplateWorkout from a Map (JSON deserialization)
  factory TemplateWorkout.fromMap(Map<String, dynamic> map) {
    return TemplateWorkout(
      name: map['name'] as String? ?? '',
      dayOfWeek: map['dayOfWeek'] as int?,
      orderIndex: map['orderIndex'] as int? ?? 0,
      notes: map['notes'] as String?,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => TemplateExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      'orderIndex': orderIndex,
      if (notes != null) 'notes': notes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  /// Creates a copy with optional field overrides
  TemplateWorkout copyWith({
    String? name,
    int? dayOfWeek,
    int? orderIndex,
    String? notes,
    List<TemplateExercise>? exercises,
  }) {
    return TemplateWorkout(
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Number of exercises in this workout
  int get exerciseCount => exercises.length;

  /// Total number of sets across all exercises
  int get totalSetCount => exercises.fold(0, (total, e) => total + e.setCount);

  /// Display string for day of week
  String? get dayOfWeekDisplay {
    if (dayOfWeek == null) return null;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek! >= 1 && dayOfWeek! <= 7) {
      return days[dayOfWeek! - 1];
    }
    return null;
  }

  /// Display string showing exercise count
  String get displayString => '$name - $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TemplateWorkout) return false;
    if (other.name != name ||
        other.dayOfWeek != dayOfWeek ||
        other.orderIndex != orderIndex ||
        other.notes != notes ||
        other.exercises.length != exercises.length) {
      return false;
    }
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i] != other.exercises[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      dayOfWeek,
      orderIndex,
      notes,
      Object.hashAll(exercises),
    );
  }
}
