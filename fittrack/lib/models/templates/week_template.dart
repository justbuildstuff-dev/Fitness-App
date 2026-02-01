import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_workout.dart';

/// A user-saved or pre-built week template.
/// Contains the complete week structure as a denormalized snapshot.
class WeekTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateWorkout> workouts;
  final DateTime createdAt;
  final String userId; // Empty string for pre-built templates
  final bool isPrebuilt;
  final String? sourceUserId; // For future community attribution

  const WeekTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.workouts,
    required this.createdAt,
    required this.userId,
    required this.isPrebuilt,
    this.sourceUserId,
  });

  /// Creates a WeekTemplate from a Firestore document
  factory WeekTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeekTemplate.fromMap(data, doc.id);
  }

  /// Creates a WeekTemplate from a Map (JSON deserialization)
  factory WeekTemplate.fromMap(Map<String, dynamic> map, [String? docId]) {
    return WeekTemplate(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      workouts: (map['workouts'] as List<dynamic>?)
              ?.map((w) => TemplateWorkout.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseDateTime(map['createdAt']),
      userId: map['userId'] as String? ?? '',
      isPrebuilt: map['isPrebuilt'] as bool? ?? false,
      sourceUserId: map['sourceUserId'] as String?,
    );
  }

  /// Converts to Map for Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'workouts': workouts.map((w) => w.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'isPrebuilt': isPrebuilt,
      if (sourceUserId != null) 'sourceUserId': sourceUserId,
    };
  }

  /// Creates a copy with optional field overrides
  WeekTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateWorkout>? workouts,
    DateTime? createdAt,
    String? userId,
    bool? isPrebuilt,
    String? sourceUserId,
  }) {
    return WeekTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      workouts: workouts ?? this.workouts,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      isPrebuilt: isPrebuilt ?? this.isPrebuilt,
      sourceUserId: sourceUserId ?? this.sourceUserId,
    );
  }

  /// Number of workouts in this week template
  int get workoutCount => workouts.length;

  /// Total number of exercises across all workouts
  int get totalExerciseCount =>
      workouts.fold(0, (total, w) => total + w.exerciseCount);

  /// Total number of sets across all workouts and exercises
  int get totalSetCount => workouts.fold(0, (total, w) => total + w.totalSetCount);

  /// Whether this is a user-created template (not pre-built)
  bool get isUserTemplate => !isPrebuilt && userId.isNotEmpty;

  /// Display string showing workout count
  String get displayString =>
      '$name - $workoutCount ${workoutCount == 1 ? 'workout' : 'workouts'}';

  /// Helper to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeekTemplate) return false;
    if (other.id != id ||
        other.name != name ||
        other.description != description ||
        other.userId != userId ||
        other.isPrebuilt != isPrebuilt ||
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
      id,
      name,
      description,
      userId,
      isPrebuilt,
      Object.hashAll(workouts),
    );
  }
}
