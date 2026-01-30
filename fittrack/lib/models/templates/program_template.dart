import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_week.dart';

/// A user-saved or pre-built program template.
/// Contains the complete program structure as a denormalized snapshot.
class ProgramTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateWeek> weeks;
  final DateTime createdAt;
  final String userId; // Empty string for pre-built templates
  final bool isPrebuilt;
  final String? sourceUserId; // For future community attribution

  const ProgramTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.weeks,
    required this.createdAt,
    required this.userId,
    required this.isPrebuilt,
    this.sourceUserId,
  });

  /// Creates a ProgramTemplate from a Firestore document
  factory ProgramTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgramTemplate.fromMap(data, doc.id);
  }

  /// Creates a ProgramTemplate from a Map (JSON deserialization)
  factory ProgramTemplate.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProgramTemplate(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      weeks: (map['weeks'] as List<dynamic>?)
              ?.map((w) => TemplateWeek.fromMap(w as Map<String, dynamic>))
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
      'weeks': weeks.map((w) => w.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'isPrebuilt': isPrebuilt,
      if (sourceUserId != null) 'sourceUserId': sourceUserId,
    };
  }

  /// Creates a copy with optional field overrides
  ProgramTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateWeek>? weeks,
    DateTime? createdAt,
    String? userId,
    bool? isPrebuilt,
    String? sourceUserId,
  }) {
    return ProgramTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      weeks: weeks ?? this.weeks,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      isPrebuilt: isPrebuilt ?? this.isPrebuilt,
      sourceUserId: sourceUserId ?? this.sourceUserId,
    );
  }

  /// Number of weeks in this program template
  int get weekCount => weeks.length;

  /// Total number of workouts across all weeks
  int get totalWorkoutCount => weeks.fold(0, (sum, w) => sum + w.workoutCount);

  /// Total number of exercises across all weeks and workouts
  int get totalExerciseCount =>
      weeks.fold(0, (sum, w) => sum + w.totalExerciseCount);

  /// Total number of sets across all weeks, workouts, and exercises
  int get totalSetCount => weeks.fold(0, (sum, w) => sum + w.totalSetCount);

  /// Whether this is a user-created template (not pre-built)
  bool get isUserTemplate => !isPrebuilt && userId.isNotEmpty;

  /// Display string showing week count
  String get displayString =>
      '$name - $weekCount ${weekCount == 1 ? 'week' : 'weeks'}';

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
    if (other is! ProgramTemplate) return false;
    if (other.id != id ||
        other.name != name ||
        other.description != description ||
        other.userId != userId ||
        other.isPrebuilt != isPrebuilt ||
        other.weeks.length != weeks.length) {
      return false;
    }
    for (int i = 0; i < weeks.length; i++) {
      if (weeks[i] != other.weeks[i]) return false;
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
      Object.hashAll(weeks),
    );
  }
}
