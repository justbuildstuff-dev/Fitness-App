/// A set configuration within a template exercise.
/// Used for storing set structure without tracking values (weight is always reset).
class TemplateSet {
  final int setNumber;
  final int? reps;
  final int? duration; // seconds
  final int? restTime; // seconds
  final String? notes;

  // Note: weight and distance are intentionally excluded per PRD
  // These values are always reset when applying templates

  const TemplateSet({
    required this.setNumber,
    this.reps,
    this.duration,
    this.restTime,
    this.notes,
  });

  /// Creates a TemplateSet from a Map (JSON deserialization)
  factory TemplateSet.fromMap(Map<String, dynamic> map) {
    return TemplateSet(
      setNumber: map['setNumber'] as int? ?? 0,
      reps: map['reps'] as int?,
      duration: map['duration'] as int?,
      restTime: map['restTime'] as int?,
      notes: map['notes'] as String?,
    );
  }

  /// Converts to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      if (reps != null) 'reps': reps,
      if (duration != null) 'duration': duration,
      if (restTime != null) 'restTime': restTime,
      if (notes != null) 'notes': notes,
    };
  }

  /// Creates a copy with optional field overrides
  TemplateSet copyWith({
    int? setNumber,
    int? reps,
    int? duration,
    int? restTime,
    String? notes,
  }) {
    return TemplateSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
    );
  }

  /// Display string for the set template
  /// Shows "Set X: Y reps" or "Set X: Zs" (duration), prioritizing reps if both exist
  String get displayString {
    if (reps != null) {
      return 'Set $setNumber: $reps reps';
    }
    if (duration != null) {
      return 'Set $setNumber: ${duration}s';
    }
    return 'Set $setNumber';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateSet &&
        other.setNumber == setNumber &&
        other.reps == reps &&
        other.duration == duration &&
        other.restTime == restTime &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(setNumber, reps, duration, restTime, notes);
  }
}
