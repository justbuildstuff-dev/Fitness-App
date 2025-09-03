import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

/// Converter class for Exercise model Firestore serialization/deserialization
class ExerciseConverter {
  /// Convert Exercise to Firestore format
  static Map<String, dynamic> toFirestore(Exercise exercise) {
    return {
      'name': exercise.name,
      'exerciseType': exercise.exerciseType.toMap(),
      'orderIndex': exercise.orderIndex,
      'notes': exercise.notes,
      'createdAt': Timestamp.fromDate(exercise.createdAt),
      'updatedAt': Timestamp.fromDate(exercise.updatedAt),
      'userId': exercise.userId,
      'workoutId': exercise.workoutId,
      'weekId': exercise.weekId,
      'programId': exercise.programId,
    };
  }

  /// Create Exercise from Firestore DocumentSnapshot
  static Exercise fromFirestore(
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
}