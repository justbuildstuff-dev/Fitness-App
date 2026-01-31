import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/templates/templates.dart';

/// Converter class for TemplateSet serialization/deserialization
class TemplateSetConverter {
  /// Convert TemplateSet to Firestore/Map format
  static Map<String, dynamic> toMap(TemplateSet set) {
    return set.toMap();
  }

  /// Create TemplateSet from Map
  static TemplateSet fromMap(Map<String, dynamic> map) {
    return TemplateSet.fromMap(map);
  }
}

/// Converter class for TemplateExercise serialization/deserialization
class TemplateExerciseConverter {
  /// Convert TemplateExercise to Firestore/Map format
  static Map<String, dynamic> toMap(TemplateExercise exercise) {
    return exercise.toMap();
  }

  /// Create TemplateExercise from Map
  static TemplateExercise fromMap(Map<String, dynamic> map) {
    return TemplateExercise.fromMap(map);
  }
}

/// Converter class for TemplateWorkout serialization/deserialization
class TemplateWorkoutConverter {
  /// Convert TemplateWorkout to Firestore/Map format
  static Map<String, dynamic> toMap(TemplateWorkout workout) {
    return workout.toMap();
  }

  /// Create TemplateWorkout from Map
  static TemplateWorkout fromMap(Map<String, dynamic> map) {
    return TemplateWorkout.fromMap(map);
  }
}

/// Converter class for TemplateWeek serialization/deserialization
class TemplateWeekConverter {
  /// Convert TemplateWeek to Firestore/Map format
  static Map<String, dynamic> toMap(TemplateWeek week) {
    return week.toMap();
  }

  /// Create TemplateWeek from Map
  static TemplateWeek fromMap(Map<String, dynamic> map) {
    return TemplateWeek.fromMap(map);
  }
}

/// Converter class for WorkoutTemplate Firestore serialization/deserialization
class WorkoutTemplateConverter {
  /// Convert WorkoutTemplate to Firestore format
  static Map<String, dynamic> toFirestore(WorkoutTemplate template) {
    return template.toMap();
  }

  /// Create WorkoutTemplate from Firestore DocumentSnapshot
  static WorkoutTemplate fromFirestore(DocumentSnapshot doc) {
    return WorkoutTemplate.fromFirestore(doc);
  }

  /// Convert WorkoutTemplate to Map (for nested use)
  static Map<String, dynamic> toMap(WorkoutTemplate template) {
    final map = template.toMap();
    map['id'] = template.id;
    return map;
  }

  /// Create WorkoutTemplate from Map (for nested use)
  static WorkoutTemplate fromMap(Map<String, dynamic> map, [String? docId]) {
    return WorkoutTemplate.fromMap(map, docId);
  }
}

/// Converter class for WeekTemplate Firestore serialization/deserialization
class WeekTemplateConverter {
  /// Convert WeekTemplate to Firestore format
  static Map<String, dynamic> toFirestore(WeekTemplate template) {
    return template.toMap();
  }

  /// Create WeekTemplate from Firestore DocumentSnapshot
  static WeekTemplate fromFirestore(DocumentSnapshot doc) {
    return WeekTemplate.fromFirestore(doc);
  }

  /// Convert WeekTemplate to Map (for nested use)
  static Map<String, dynamic> toMap(WeekTemplate template) {
    final map = template.toMap();
    map['id'] = template.id;
    return map;
  }

  /// Create WeekTemplate from Map (for nested use)
  static WeekTemplate fromMap(Map<String, dynamic> map, [String? docId]) {
    return WeekTemplate.fromMap(map, docId);
  }
}

/// Converter class for ProgramTemplate Firestore serialization/deserialization
class ProgramTemplateConverter {
  /// Convert ProgramTemplate to Firestore format
  static Map<String, dynamic> toFirestore(ProgramTemplate template) {
    return template.toMap();
  }

  /// Create ProgramTemplate from Firestore DocumentSnapshot
  static ProgramTemplate fromFirestore(DocumentSnapshot doc) {
    return ProgramTemplate.fromFirestore(doc);
  }

  /// Convert ProgramTemplate to Map (for nested use)
  static Map<String, dynamic> toMap(ProgramTemplate template) {
    final map = template.toMap();
    map['id'] = template.id;
    return map;
  }

  /// Create ProgramTemplate from Map (for nested use)
  static ProgramTemplate fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProgramTemplate.fromMap(map, docId);
  }
}
