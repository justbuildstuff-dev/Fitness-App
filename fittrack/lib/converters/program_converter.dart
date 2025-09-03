import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program.dart';

/// Converter class for Program model Firestore serialization/deserialization
/// This separates Firebase dependencies from the core model
class ProgramConverter {
  /// Convert Program to Firestore format
  static Map<String, dynamic> toFirestore(Program program) {
    return {
      'name': program.name,
      'description': program.description,
      'createdAt': Timestamp.fromDate(program.createdAt),
      'updatedAt': Timestamp.fromDate(program.updatedAt),
      'userId': program.userId,
      'isArchived': program.isArchived,
    };
  }

  /// Create Program from Firestore DocumentSnapshot
  static Program fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Program(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      isArchived: data['isArchived'] ?? false,
    );
  }
}