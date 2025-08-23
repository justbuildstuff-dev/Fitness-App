import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class ExerciseSet {
  final String id;
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? duration; // seconds
  final double? distance; // meters
  final int? restTime; // seconds
  final bool checked;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String exerciseId;
  final String workoutId;
  final String weekId;
  final String programId;

  ExerciseSet({
    required this.id,
    required this.setNumber,
    this.reps,
    this.weight,
    this.duration,
    this.distance,
    this.restTime,
    this.checked = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.exerciseId,
    required this.workoutId,
    required this.weekId,
    required this.programId,
  });

  factory ExerciseSet.fromFirestore(
    DocumentSnapshot doc,
    String exerciseId,
    String workoutId,
    String weekId,
    String programId,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseSet(
      id: doc.id,
      setNumber: data['setNumber'] ?? 1,
      reps: data['reps']?.toInt(),
      weight: data['weight']?.toDouble(),
      duration: data['duration']?.toInt(),
      distance: data['distance']?.toDouble(),
      restTime: data['restTime']?.toInt(),
      checked: data['checked'] ?? false,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      exerciseId: exerciseId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'duration': duration,
      'distance': distance,
      'restTime': restTime,
      'checked': checked,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  ExerciseSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? duration,
    double? distance,
    int? restTime,
    bool? checked,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ExerciseSet(
      id: id,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      restTime: restTime ?? this.restTime,
      checked: checked ?? this.checked,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
      exerciseId: exerciseId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    );
  }

  /// Validates the set based on exercise type requirements
  bool isValidForExerciseType(ExerciseType exerciseType) {
    switch (exerciseType) {
      case ExerciseType.strength:
        return reps != null && reps! > 0;
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return duration != null && duration! > 0;
      case ExerciseType.bodyweight:
        return reps != null && reps! > 0;
      case ExerciseType.custom:
        return hasAtLeastOneMetric;
    }
  }

  /// Checks if at least one metric is present (required for all sets)
  bool get hasAtLeastOneMetric =>
      (reps != null && reps! > 0) ||
      (duration != null && duration! > 0) ||
      (distance != null && distance! > 0);

  /// Validates numeric fields are non-negative
  bool get hasValidNumericValues =>
      (reps == null || reps! >= 0) &&
      (weight == null || weight! >= 0) &&
      (duration == null || duration! >= 0) &&
      (distance == null || distance! >= 0) &&
      (restTime == null || restTime! >= 0);

  /// Comprehensive validation
  bool isValid(ExerciseType exerciseType) =>
      hasValidNumericValues && 
      setNumber > 0 &&
      isValidForExerciseType(exerciseType);

  /// Creates a copy for duplication (resets certain fields)
  ExerciseSet createDuplicateCopy({
    required String newId,
    required String newExerciseId,
    required String newWorkoutId,
    required String newWeekId,
    required String newProgramId,
    required ExerciseType exerciseType,
  }) {
    final now = DateTime.now();
    
    // Reset fields based on exercise type per spec
    int? newReps = reps;
    double? newWeight = weight;
    int? newDuration = duration;
    double? newDistance = distance;

    switch (exerciseType) {
      case ExerciseType.strength:
        newWeight = null; // Reset weight to encourage fresh entry
        break;
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        // Keep duration and distance
        break;
      case ExerciseType.bodyweight:
        // Keep reps
        break;
      case ExerciseType.custom:
        // Keep all fields
        break;
    }

    return ExerciseSet(
      id: newId,
      setNumber: setNumber,
      reps: newReps,
      weight: newWeight,
      duration: newDuration,
      distance: newDistance,
      restTime: restTime,
      checked: false, // Always reset checked status
      notes: notes,
      createdAt: now,
      updatedAt: now,
      userId: userId,
      exerciseId: newExerciseId,
      workoutId: newWorkoutId,
      weekId: newWeekId,
      programId: newProgramId,
    );
  }

  /// Display string for the set (e.g., "12 reps x 100kg")
  String get displayString {
    final parts = <String>[];
    
    if (reps != null) parts.add('$reps reps');
    if (weight != null) parts.add('${weight!.toStringAsFixed(weight! == weight!.roundToDouble() ? 0 : 1)}kg');
    if (duration != null) {
      final minutes = duration! ~/ 60;
      final seconds = duration! % 60;
      if (minutes > 0) {
        parts.add('${minutes}m ${seconds}s');
      } else {
        parts.add('${seconds}s');
      }
    }
    if (distance != null) {
      if (distance! >= 1000) {
        parts.add('${(distance! / 1000).toStringAsFixed(2)}km');
      } else {
        parts.add('${distance!.toStringAsFixed(0)}m');
      }
    }
    if (restTime != null) parts.add('rest: ${restTime}s');
    
    return parts.isEmpty ? 'Empty set' : parts.join(' × ');
  }
}