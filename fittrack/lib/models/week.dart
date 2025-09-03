
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

  /// Convert Week to basic Map format (Firebase conversion handled by converter)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Week &&
        other.id == id &&
        other.name == name &&
        other.order == order &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.userId == userId &&
        other.programId == programId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      order,
      notes,
      createdAt,
      updatedAt,
      userId,
      programId,
    );
  }
}