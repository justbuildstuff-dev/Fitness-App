import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';

/// Converter class for Workout model Firestore serialization/deserialization
class WorkoutConverter {
  /// Convert Workout to Firestore format
  static Map<String, dynamic> toFirestore(Workout workout) {
    return {
      'name': workout.name,
      'dayOfWeek': workout.dayOfWeek,
      'orderIndex': workout.orderIndex,
      'notes': workout.notes,
      'createdAt': Timestamp.fromDate(workout.createdAt),
      'updatedAt': Timestamp.fromDate(workout.updatedAt),
      'userId': workout.userId,
      'weekId': workout.weekId,
      'programId': workout.programId,
    };
  }

  /// Create Workout from Firestore DocumentSnapshot
  static Workout fromFirestore(
    DocumentSnapshot doc, 
    String weekId, 
    String programId,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      name: data['name'] ?? '',
      dayOfWeek: data['dayOfWeek'],
      orderIndex: data['orderIndex'] ?? 0,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      weekId: weekId,
      programId: programId,
    );
  }
}