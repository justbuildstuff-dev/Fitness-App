import 'package:cloud_firestore/cloud_firestore.dart';

class Program {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final bool isArchived;

  Program({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.isArchived = false,
  });

  factory Program.fromFirestore(DocumentSnapshot doc) {
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

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'isArchived': isArchived,
    };
  }

  Program copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return Program(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  bool get isValidName => name.trim().isNotEmpty && name.trim().length <= 100;
  bool get isValidDescription => 
      description == null || description!.length <= 500;
}