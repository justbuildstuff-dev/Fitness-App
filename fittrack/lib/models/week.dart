import 'package:cloud_firestore/cloud_firestore.dart';

class Week {
  final String id;
  final String name;
  final int order;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String programId;

  Week({
    required this.id,
    required this.name,
    required this.order,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.programId,
  });

  factory Week.fromFirestore(DocumentSnapshot doc, String programId) {
    final data = doc.data() as Map<String, dynamic>;
    return Week(
      id: doc.id,
      name: data['name'] ?? 'Week ${data['order'] ?? 1}',
      order: data['order'] ?? 1,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      programId: data['programId'] ?? programId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'order': order,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'programId': programId,
    };
  }

  Week copyWith({
    String? name,
    int? order,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Week(
      id: id,
      name: name ?? this.name,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
      programId: programId,
    );
  }

  bool get isValidName => name.trim().isNotEmpty;
  bool get isValidOrder => order > 0;
}