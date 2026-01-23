/// Muscle group categories for exercise filtering and organization
enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core;

  /// Returns the display-friendly name for UI rendering
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.core:
        return 'Core';
    }
  }

  /// Creates a MuscleGroup from a string value (case-insensitive)
  static MuscleGroup fromString(String value) {
    switch (value.toLowerCase()) {
      case 'chest':
        return MuscleGroup.chest;
      case 'back':
        return MuscleGroup.back;
      case 'shoulders':
        return MuscleGroup.shoulders;
      case 'arms':
        return MuscleGroup.arms;
      case 'legs':
        return MuscleGroup.legs;
      case 'core':
        return MuscleGroup.core;
      default:
        throw ArgumentError('Unknown muscle group: $value');
    }
  }

  /// Converts to string for JSON/Firestore serialization
  String toMap() {
    switch (this) {
      case MuscleGroup.chest:
        return 'chest';
      case MuscleGroup.back:
        return 'back';
      case MuscleGroup.shoulders:
        return 'shoulders';
      case MuscleGroup.arms:
        return 'arms';
      case MuscleGroup.legs:
        return 'legs';
      case MuscleGroup.core:
        return 'core';
    }
  }
}
