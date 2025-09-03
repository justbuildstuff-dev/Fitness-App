
class Workout {
  final String id;
  final String name;
  final int? dayOfWeek; // 1-7 (Monday-Sunday)
  final int orderIndex;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String weekId;
  final String programId;

  Workout({
    required this.id,
    required this.name,
    this.dayOfWeek,
    required this.orderIndex,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.weekId,
    required this.programId,
  });

  /// Convert Workout to basic Map format (Firebase conversion handled by converter)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dayOfWeek': dayOfWeek,
      'orderIndex': orderIndex,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'weekId': weekId,
      'programId': programId,
    };
  }

  Workout copyWith({
    String? name,
    int? dayOfWeek,
    int? orderIndex,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId,
      weekId: weekId,
      programId: programId,
    );
  }

  bool get isValidName => name.trim().isNotEmpty && name.trim().length <= 200;
  bool get isValidDayOfWeek => 
      dayOfWeek == null || (dayOfWeek! >= 1 && dayOfWeek! <= 7);

  String get dayOfWeekName {
    if (dayOfWeek == null) return '';
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek!];
  }
}