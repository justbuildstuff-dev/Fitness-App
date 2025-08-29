import 'package:cloud_firestore/cloud_firestore.dart';

enum ExerciseType {
  strength,
  cardio,
  bodyweight,
  custom,
  timeBased; // Alternative name for cardio/time-based

  String get displayName {
    switch (this) {
      case ExerciseType.strength:
        return 'Strength';
      case ExerciseType.cardio:
        return 'Cardio';
      case ExerciseType.bodyweight:
        return 'Bodyweight';
      case ExerciseType.custom:
        return 'Custom';
      case ExerciseType.timeBased:
        return 'Time-based';
    }
  }

  static ExerciseType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'strength':
        return ExerciseType.strength;
      case 'cardio':
        return ExerciseType.cardio;
      case 'bodyweight':
        return ExerciseType.bodyweight;
      case 'time-based':
      case 'timebased':
        return ExerciseType.timeBased;
      case 'custom':
      default:
        return ExerciseType.custom;
    }
  }

  String toFirestore() {
    switch (this) {
      case ExerciseType.strength:
        return 'strength';
      case ExerciseType.cardio:
        return 'cardio';
      case ExerciseType.bodyweight:
        return 'bodyweight';
      case ExerciseType.custom:
        return 'custom';
      case ExerciseType.timeBased:
        return 'time-based';
    }
  }
}

class Exercise {
  final String id;
  final String name;
  final ExerciseType exerciseType;
  final int orderIndex;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String workoutId;
  final String weekId;
  final String programId;

  Exercise({
    required this.id,
    required this.name,
    required this.exerciseType,
    required this.orderIndex,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.workoutId,
    required this.weekId,
    required this.programId,
  });

  factory Exercise.fromFirestore(
    DocumentSnapshot doc,
    String workoutId,
    String weekId,
    String programId,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      exerciseType: ExerciseType.fromString(data['exerciseType'] ?? 'custom'),
      orderIndex: data['orderIndex'] ?? 0,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'exerciseType': exerciseType.toFirestore(),
      'orderIndex': orderIndex,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'workoutId': workoutId,
      'weekId': weekId,
      'programId': programId,
    };
  }

  Exercise copyWith({
    String? name,
    ExerciseType? exerciseType,
    int? orderIndex,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      exerciseType: exerciseType ?? this.exerciseType,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    );
  }

  bool get isValidName => name.trim().isNotEmpty && name.trim().length <= 200;

  /// Returns the required fields for sets based on exercise type
  List<String> get requiredSetFields {
    switch (exerciseType) {
      case ExerciseType.strength:
        return ['reps']; // weight is optional
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return ['duration']; // distance is optional
      case ExerciseType.bodyweight:
        return ['reps'];
      case ExerciseType.custom:
        return []; // flexible - at least one metric required
    }
  }

  /// Returns the optional fields for sets based on exercise type
  List<String> get optionalSetFields {
    switch (exerciseType) {
      case ExerciseType.strength:
        return ['weight', 'restTime'];
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return ['distance'];
      case ExerciseType.bodyweight:
        return ['restTime'];
      case ExerciseType.custom:
        return ['reps', 'weight', 'duration', 'distance', 'restTime'];
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.exerciseType == exerciseType &&
        other.orderIndex == orderIndex &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.userId == userId &&
        other.workoutId == workoutId &&
        other.weekId == weekId &&
        other.programId == programId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      exerciseType,
      orderIndex,
      notes,
      createdAt,
      updatedAt,
      userId,
      workoutId,
      weekId,
      programId,
    );
  }
}