import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_set.dart';

/// Converter class for ExerciseSet model Firestore serialization/deserialization
class ExerciseSetConverter {
  /// Convert ExerciseSet to Firestore format
  static Map<String, dynamic> toFirestore(ExerciseSet set) {
    return {
      'setNumber': set.setNumber,
      'reps': set.reps,
      'weight': set.weight,
      'duration': set.duration,
      'distance': set.distance,
      'restTime': set.restTime,
      'checked': set.checked,
      'notes': set.notes,
      'createdAt': Timestamp.fromDate(set.createdAt),
      'updatedAt': Timestamp.fromDate(set.updatedAt),
      'userId': set.userId,
      'exerciseId': set.exerciseId,
      'workoutId': set.workoutId,
      'weekId': set.weekId,
      'programId': set.programId,
    };
  }

  /// Create ExerciseSet from Firestore DocumentSnapshot
  static ExerciseSet fromFirestore(
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
}