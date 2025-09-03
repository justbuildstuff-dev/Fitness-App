import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/week.dart';

/// Converter class for Week model Firestore serialization/deserialization
class WeekConverter {
  /// Convert Week to Firestore format
  static Map<String, dynamic> toFirestore(Week week) {
    return {
      'name': week.name,
      'order': week.order,
      'notes': week.notes,
      'createdAt': Timestamp.fromDate(week.createdAt),
      'updatedAt': Timestamp.fromDate(week.updatedAt),
      'userId': week.userId,
      'programId': week.programId,
    };
  }

  /// Create Week from Firestore DocumentSnapshot
  static Week fromFirestore(DocumentSnapshot doc, {String? programId}) {
    final data = doc.data() as Map<String, dynamic>;
    return Week(
      id: doc.id,
      name: data['name'] ?? 'Week ${data['order'] ?? 1}',
      order: data['order'] ?? 1,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      programId: data['programId'] ?? programId ?? '',
    );
  }
}