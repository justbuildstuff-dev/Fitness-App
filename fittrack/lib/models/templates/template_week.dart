import 'template_workout.dart';

/// A week configuration within a program template.
/// Contains the week structure with all its workouts.
class TemplateWeek {
  final String name;
  final int order;
  final String? notes;
  final List<TemplateWorkout> workouts;

  const TemplateWeek({
    required this.name,
    required this.order,
    this.notes,
    required this.workouts,
  });

  /// Creates a TemplateWeek from a Map (JSON deserialization)
  factory TemplateWeek.fromMap(Map<String, dynamic> map) {
    return TemplateWeek(
      name: map['name'] as String? ?? '',
      order: _parseIntOrDefault(map['order'], 0),
      notes: map['notes'] as String?,
      workouts: (map['workouts'] as List<dynamic>?)
              ?.map((w) => TemplateWorkout.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
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
      'order': order,
      if (notes != null) 'notes': notes,
      'workouts': workouts.map((w) => w.toMap()).toList(),
    };
  }

  /// Creates a copy with optional field overrides
  TemplateWeek copyWith({
    String? name,
    int? order,
    String? notes,
    List<TemplateWorkout>? workouts,
  }) {
    return TemplateWeek(
      name: name ?? this.name,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      workouts: workouts ?? this.workouts,
    );
  }

  /// Number of workouts in this week
  int get workoutCount => workouts.length;

  /// Total number of exercises across all workouts
  int get totalExerciseCount =>
      workouts.fold(0, (total, w) => total + w.exerciseCount);

  /// Total number of sets across all workouts and exercises
  int get totalSetCount => workouts.fold(0, (total, w) => total + w.totalSetCount);

  /// Display string showing workout count
  String get displayString =>
      '$name - $workoutCount ${workoutCount == 1 ? 'workout' : 'workouts'}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TemplateWeek) return false;
    if (other.name != name ||
        other.order != order ||
        other.notes != notes ||
        other.workouts.length != workouts.length) {
      return false;
    }
    for (int i = 0; i < workouts.length; i++) {
      if (workouts[i] != other.workouts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      order,
      notes,
      Object.hashAll(workouts),
    );
  }
}
