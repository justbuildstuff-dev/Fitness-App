import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_exercise.dart';

/// A user-saved or pre-built workout template.
/// Contains the complete workout structure as a denormalized snapshot.
class WorkoutTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateExercise> exercises;
  final DateTime createdAt;
  final String userId; // Empty string for pre-built templates
  final bool isPrebuilt;
  final String? sourceUserId; // For future community attribution

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    required this.userId,
    required this.isPrebuilt,
    this.sourceUserId,
  });

  /// Creates a WorkoutTemplate from a Firestore document
  factory WorkoutTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutTemplate.fromMap(data, doc.id);
  }

  /// Creates a WorkoutTemplate from a Map (JSON deserialization)
  factory WorkoutTemplate.fromMap(Map<String, dynamic> map, [String? docId]) {
    return WorkoutTemplate(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => TemplateExercise.fromMap(e as Map<String, dynamic>))
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
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'isPrebuilt': isPrebuilt,
      if (sourceUserId != null) 'sourceUserId': sourceUserId,
    };
  }

  /// Creates a copy with optional field overrides
  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateExercise>? exercises,
    DateTime? createdAt,
    String? userId,
    bool? isPrebuilt,
    String? sourceUserId,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      isPrebuilt: isPrebuilt ?? this.isPrebuilt,
      sourceUserId: sourceUserId ?? this.sourceUserId,
    );
  }

  /// Number of exercises in this workout template
  int get exerciseCount => exercises.length;

  /// Total number of sets across all exercises
  int get totalSetCount => exercises.fold(0, (sum, e) => sum + e.setCount);

  /// Whether this is a user-created template (not pre-built)
  bool get isUserTemplate => !isPrebuilt && userId.isNotEmpty;

  /// Display string showing exercise count
  String get displayString =>
      '$name - $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}';

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
    if (other is! WorkoutTemplate) return false;
    if (other.id != id ||
        other.name != name ||
        other.description != description ||
        other.userId != userId ||
        other.isPrebuilt != isPrebuilt ||
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
      id,
      name,
      description,
      userId,
      isPrebuilt,
      Object.hashAll(exercises),
    );
  }
}
