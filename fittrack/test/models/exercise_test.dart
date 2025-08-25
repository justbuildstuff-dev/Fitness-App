import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/models/exercise.dart';

/// Unit tests for the Exercise model and ExerciseType enum
/// 
/// These tests verify that the Exercise model correctly:
/// - Handles different exercise types with proper field requirements
/// - Validates exercise data according to business rules
/// - Serializes to/from Firestore format properly
/// - Handles optional and required fields appropriately
/// - Manages copyWith functionality for updates
/// 
/// If any test fails, it indicates a problem with exercise data handling
/// that could cause issues when saving/loading exercises from Firestore.
void main() {
  group('ExerciseType Enum Tests', () {
    group('Display Names', () {
      test('returns correct display names for all exercise types', () {
        /// Test Purpose: Verify that exercise types have proper display names
        /// These names are shown in the UI, so they must be user-friendly
        
        expect(ExerciseType.strength.displayName, equals('Strength'));
        expect(ExerciseType.cardio.displayName, equals('Cardio'));
        expect(ExerciseType.bodyweight.displayName, equals('Bodyweight'));
        expect(ExerciseType.custom.displayName, equals('Custom'));
        expect(ExerciseType.timeBased.displayName, equals('Time-based'));
      });
    });

    group('String Conversion', () {
      test('fromString creates correct exercise types', () {
        /// Test Purpose: Verify that string values correctly map to enum types
        /// This is crucial for deserializing data from Firestore
        
        expect(ExerciseType.fromString('strength'), equals(ExerciseType.strength));
        expect(ExerciseType.fromString('cardio'), equals(ExerciseType.cardio));
        expect(ExerciseType.fromString('bodyweight'), equals(ExerciseType.bodyweight));
        expect(ExerciseType.fromString('time-based'), equals(ExerciseType.timeBased));
        expect(ExerciseType.fromString('timebased'), equals(ExerciseType.timeBased));
        expect(ExerciseType.fromString('custom'), equals(ExerciseType.custom));
      });

      test('fromString handles case insensitive input', () {
        /// Test Purpose: Verify case insensitive parsing for flexibility
        /// Users might enter data in different cases
        
        expect(ExerciseType.fromString('STRENGTH'), equals(ExerciseType.strength));
        expect(ExerciseType.fromString('Cardio'), equals(ExerciseType.cardio));
        expect(ExerciseType.fromString('BODYWEIGHT'), equals(ExerciseType.bodyweight));
      });

      test('fromString defaults to custom for unknown values', () {
        /// Test Purpose: Verify graceful handling of unknown exercise types
        /// This provides fallback behavior for invalid or new types
        
        expect(ExerciseType.fromString('unknown'), equals(ExerciseType.custom));
        expect(ExerciseType.fromString('invalid'), equals(ExerciseType.custom));
        expect(ExerciseType.fromString(''), equals(ExerciseType.custom));
      });

      test('toFirestore returns correct string values', () {
        /// Test Purpose: Verify that enum values serialize correctly for Firestore
        /// These strings must match what's expected by Firestore rules
        
        expect(ExerciseType.strength.toFirestore(), equals('strength'));
        expect(ExerciseType.cardio.toFirestore(), equals('cardio'));
        expect(ExerciseType.bodyweight.toFirestore(), equals('bodyweight'));
        expect(ExerciseType.custom.toFirestore(), equals('custom'));
        expect(ExerciseType.timeBased.toFirestore(), equals('time-based'));
      });
    });
  });

  group('Exercise Model Tests', () {
    late DateTime testDate;
    
    setUp(() {
      // Set up consistent test data
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    group('Constructor and Basic Properties', () {
      test('creates valid exercise with required fields only', () {
        /// Test Purpose: Verify that an exercise can be created with minimal data
        /// This ensures the model works with required fields only
        
        final exercise = Exercise(
          id: 'exercise-123',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          workoutId: 'workout-789',
          weekId: 'week-101',
          programId: 'program-202',
        );

        // Verify all required fields are set correctly
        expect(exercise.id, equals('exercise-123'));
        expect(exercise.name, equals('Bench Press'));
        expect(exercise.exerciseType, equals(ExerciseType.strength));
        expect(exercise.orderIndex, equals(1));
        expect(exercise.createdAt, equals(testDate));
        expect(exercise.updatedAt, equals(testDate));
        expect(exercise.userId, equals('user-456'));
        expect(exercise.workoutId, equals('workout-789'));
        expect(exercise.weekId, equals('week-101'));
        expect(exercise.programId, equals('program-202'));
        
        // Verify optional fields have correct defaults
        expect(exercise.notes, isNull, 
          reason: 'notes should be null when not specified');
      });

      test('creates valid exercise with all fields including optional ones', () {
        /// Test Purpose: Verify that an exercise can be created with all fields
        /// This ensures the model handles complete exercise data correctly
        
        final exercise = Exercise(
          id: 'exercise-123',
          name: 'Barbell Row',
          exerciseType: ExerciseType.strength,
          orderIndex: 2,
          notes: 'Focus on pulling shoulder blades together',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          workoutId: 'workout-789',
          weekId: 'week-101',
          programId: 'program-202',
        );

        // Verify all fields including optional ones
        expect(exercise.notes, equals('Focus on pulling shoulder blades together'));
      });
    });

    group('Validation Properties', () {
      test('isValidName returns true for valid exercise names', () {
        /// Test Purpose: Verify that exercise name validation works correctly
        /// Names must be non-empty and within length limits
        
        final validNames = [
          'Squat',          // Short name
          'Barbell Bench Press', // Normal name
          'A' * 200,        // Maximum length (200 chars)
        ];

        for (final name in validNames) {
          final exercise = _createTestExercise(name: name);
          expect(exercise.isValidName, isTrue, 
            reason: 'Name "$name" should be valid (length: ${name.length})');
        }
      });

      test('isValidName returns false for invalid exercise names', () {
        /// Test Purpose: Verify that invalid exercise names are properly rejected
        /// This prevents empty or overly long names
        
        final invalidNames = [
          '',              // Empty string
          '   ',           // Only whitespace
          'A' * 201,       // Too long (201 chars)
        ];

        for (final name in invalidNames) {
          final exercise = _createTestExercise(name: name);
          expect(exercise.isValidName, isFalse, 
            reason: 'Name "$name" should be invalid');
        }
      });
    });

    group('Exercise Type Field Requirements', () {
      test('strength exercises have correct required and optional fields', () {
        /// Test Purpose: Verify field requirements for strength exercises
        /// Strength exercises require reps, weight is optional
        
        final exercise = _createTestExercise(exerciseType: ExerciseType.strength);
        
        expect(exercise.requiredSetFields, equals(['reps']));
        expect(exercise.optionalSetFields, contains('weight'));
        expect(exercise.optionalSetFields, contains('restTime'));
      });

      test('cardio exercises have correct required and optional fields', () {
        /// Test Purpose: Verify field requirements for cardio exercises
        /// Cardio exercises require duration, distance is optional
        
        final exercise = _createTestExercise(exerciseType: ExerciseType.cardio);
        
        expect(exercise.requiredSetFields, equals(['duration']));
        expect(exercise.optionalSetFields, contains('distance'));
      });

      test('time-based exercises have same requirements as cardio', () {
        /// Test Purpose: Verify time-based exercises work like cardio
        /// Time-based is an alternative naming for cardio exercises
        
        final exercise = _createTestExercise(exerciseType: ExerciseType.timeBased);
        
        expect(exercise.requiredSetFields, equals(['duration']));
        expect(exercise.optionalSetFields, contains('distance'));
      });

      test('bodyweight exercises have correct required fields', () {
        /// Test Purpose: Verify field requirements for bodyweight exercises
        /// Bodyweight exercises require reps, no weight needed
        
        final exercise = _createTestExercise(exerciseType: ExerciseType.bodyweight);
        
        expect(exercise.requiredSetFields, equals(['reps']));
        expect(exercise.optionalSetFields, contains('restTime'));
        expect(exercise.optionalSetFields, isNot(contains('weight')));
      });

      test('custom exercises have flexible field requirements', () {
        /// Test Purpose: Verify field requirements for custom exercises
        /// Custom exercises should be flexible with all fields optional
        
        final exercise = _createTestExercise(exerciseType: ExerciseType.custom);
        
        expect(exercise.requiredSetFields, isEmpty);
        expect(exercise.optionalSetFields, contains('reps'));
        expect(exercise.optionalSetFields, contains('weight'));
        expect(exercise.optionalSetFields, contains('duration'));
        expect(exercise.optionalSetFields, contains('distance'));
        expect(exercise.optionalSetFields, contains('restTime'));
      });
    });

    group('Firestore Serialization', () {
      test('toFirestore includes all necessary fields', () {
        /// Test Purpose: Verify that exercise data serializes correctly for Firestore
        /// All relevant fields should be included with proper formatting
        
        final exercise = Exercise(
          id: 'exercise-123',
          name: 'Deadlift',
          exerciseType: ExerciseType.strength,
          orderIndex: 3,
          notes: 'Keep back straight',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          workoutId: 'workout-789',
          weekId: 'week-101',
          programId: 'program-202',
        );

        final firestoreData = exercise.toFirestore();

        // Verify all fields are present with correct values
        expect(firestoreData['name'], equals('Deadlift'));
        expect(firestoreData['exerciseType'], equals('strength'));
        expect(firestoreData['orderIndex'], equals(3));
        expect(firestoreData['notes'], equals('Keep back straight'));
        expect(firestoreData['userId'], equals('user-456'));
        
        // Verify timestamps are converted to Firestore format
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));

        // Verify path parameters are NOT included (they're document path info)
        expect(firestoreData, isNot(contains('id')));
        expect(firestoreData, isNot(contains('workoutId')));
        expect(firestoreData, isNot(contains('weekId')));
        expect(firestoreData, isNot(contains('programId')));
      });

      test('toFirestore handles different exercise types correctly', () {
        /// Test Purpose: Verify that different exercise types serialize properly
        /// Each type should serialize with its correct string representation
        
        final types = [
          ExerciseType.strength,
          ExerciseType.cardio,
          ExerciseType.bodyweight,
          ExerciseType.custom,
          ExerciseType.timeBased,
        ];

        for (final type in types) {
          final exercise = _createTestExercise(exerciseType: type);
          final firestoreData = exercise.toFirestore();
          
          expect(firestoreData['exerciseType'], equals(type.toFirestore()),
            reason: 'Exercise type $type should serialize correctly');
        }
      });

      test('toFirestore handles null notes correctly', () {
        /// Test Purpose: Verify that null optional fields are preserved
        /// Null values should be explicitly included
        
        final exercise = _createTestExercise(notes: null);
        final firestoreData = exercise.toFirestore();

        expect(firestoreData['notes'], isNull,
          reason: 'Null notes should be preserved, not omitted');
      });
    });

    group('Firestore Deserialization', () {
      test('fromFirestore creates exercise from complete Firestore data', () {
        /// Test Purpose: Verify that exercise data deserializes correctly from Firestore
        /// This ensures data loaded from the database matches what was stored
        
        final firestoreData = {
          'name': 'Pull-ups',
          'exerciseType': 'bodyweight',
          'orderIndex': 1,
          'notes': 'Full range of motion',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('exercise-123', firestoreData);
        
        final exercise = Exercise.fromFirestore(
          mockDoc,
          'workout-789',
          'week-101',
          'program-202',
        );

        expect(exercise.id, equals('exercise-123'));
        expect(exercise.name, equals('Pull-ups'));
        expect(exercise.exerciseType, equals(ExerciseType.bodyweight));
        expect(exercise.orderIndex, equals(1));
        expect(exercise.notes, equals('Full range of motion'));
        expect(exercise.createdAt, equals(testDate));
        expect(exercise.updatedAt, equals(testDate));
        expect(exercise.userId, equals('user-456'));
        expect(exercise.workoutId, equals('workout-789'));
        expect(exercise.weekId, equals('week-101'));
        expect(exercise.programId, equals('program-202'));
      });

      test('fromFirestore handles missing optional fields gracefully', () {
        /// Test Purpose: Verify that missing optional fields default to appropriate values
        /// This ensures backwards compatibility
        
        final firestoreData = {
          'name': 'Running',
          'exerciseType': 'cardio',
          'orderIndex': 2,
          // notes omitted
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('exercise-456', firestoreData);
        final exercise = Exercise.fromFirestore(
          mockDoc,
          'workout-789',
          'week-101',
          'program-202',
        );

        expect(exercise.notes, isNull,
          reason: 'Missing notes should default to null');
        expect(exercise.name, equals('Running'),
          reason: 'Present fields should still be loaded correctly');
      });

      test('fromFirestore provides defaults for missing required fields', () {
        /// Test Purpose: Verify that missing required fields get sensible defaults
        /// This prevents crashes when loading incomplete data
        
        final firestoreData = {
          // name omitted - should default to empty string
          // exerciseType omitted - should default to custom
          // orderIndex omitted - should default to 0
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          // userId omitted - should default to empty string
        };

        final mockDoc = MockDocumentSnapshot('exercise-789', firestoreData);
        final exercise = Exercise.fromFirestore(
          mockDoc,
          'workout-789',
          'week-101',
          'program-202',
        );

        expect(exercise.name, equals(''),
          reason: 'Missing name should default to empty string');
        expect(exercise.exerciseType, equals(ExerciseType.custom),
          reason: 'Missing exerciseType should default to custom');
        expect(exercise.orderIndex, equals(0),
          reason: 'Missing orderIndex should default to 0');
        expect(exercise.userId, equals(''),
          reason: 'Missing userId should default to empty string');
      });
    });

    group('Copy With Method', () {
      test('copyWith creates new exercise with updated fields', () {
        /// Test Purpose: Verify that copyWith method works correctly for updates
        /// This method is used when updating existing exercises
        
        final original = _createTestExercise(
          name: 'Original Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          notes: 'Original notes',
        );

        final updated = original.copyWith(
          name: 'Updated Exercise',
          exerciseType: ExerciseType.cardio,
          orderIndex: 2,
          notes: 'Updated notes',
          updatedAt: testDate.add(Duration(hours: 1)),
        );

        // Verify updated fields changed
        expect(updated.name, equals('Updated Exercise'));
        expect(updated.exerciseType, equals(ExerciseType.cardio));
        expect(updated.orderIndex, equals(2));
        expect(updated.notes, equals('Updated notes'));
        expect(updated.updatedAt, equals(testDate.add(Duration(hours: 1))));

        // Verify unchanged fields remained the same
        expect(updated.id, equals(original.id));
        expect(updated.createdAt, equals(original.createdAt));
        expect(updated.userId, equals(original.userId));
        expect(updated.workoutId, equals(original.workoutId));
        expect(updated.weekId, equals(original.weekId));
        expect(updated.programId, equals(original.programId));
      });

      test('copyWith preserves original values for null parameters', () {
        /// Test Purpose: Verify that copyWith doesn't overwrite fields with null
        /// Only specified fields should be updated
        
        final original = _createTestExercise(
          name: 'Keep This Name',
          exerciseType: ExerciseType.bodyweight,
          orderIndex: 5,
          notes: 'Keep These Notes',
        );

        final updated = original.copyWith(
          updatedAt: testDate.add(Duration(minutes: 30)),
          // other fields not specified - should remain unchanged
        );

        expect(updated.name, equals('Keep This Name'));
        expect(updated.exerciseType, equals(ExerciseType.bodyweight));
        expect(updated.orderIndex, equals(5));
        expect(updated.notes, equals('Keep These Notes'));
        expect(updated.updatedAt, equals(testDate.add(Duration(minutes: 30))));
      });
    });

    group('Exercise Ordering', () {
      test('exercises can be sorted by order index', () {
        /// Test Purpose: Verify that exercises can be properly ordered
        /// This is important for displaying exercises in correct sequence
        
        final exercise3 = _createTestExercise(name: 'Third Exercise', orderIndex: 3);
        final exercise1 = _createTestExercise(name: 'First Exercise', orderIndex: 1);
        final exercise2 = _createTestExercise(name: 'Second Exercise', orderIndex: 2);
        
        final exercises = [exercise3, exercise1, exercise2];
        exercises.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        expect(exercises[0].orderIndex, equals(1));
        expect(exercises[1].orderIndex, equals(2));
        expect(exercises[2].orderIndex, equals(3));
        expect(exercises[0].name, equals('First Exercise'));
        expect(exercises[1].name, equals('Second Exercise'));
        expect(exercises[2].name, equals('Third Exercise'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles special characters in exercise names', () {
        /// Test Purpose: Verify model handles various text content
        /// Users might enter special characters or symbols
        
        final specialName = 'Exercise with émojis 💪 and symbols: @#\$%';
        final exercise = _createTestExercise(name: specialName);

        expect(exercise.name, equals(specialName));
        expect(exercise.isValidName, isTrue);
      });

      test('handles very long exercise names within limits', () {
        /// Test Purpose: Verify model handles maximum length names
        /// Names at the limit should be valid
        
        final longName = 'A' * 200; // Exactly at limit
        final exercise = _createTestExercise(name: longName);

        expect(exercise.name, equals(longName));
        expect(exercise.isValidName, isTrue);
      });

      test('handles negative order indices gracefully', () {
        /// Test Purpose: Verify model can handle edge case values
        /// While not recommended, negative orders shouldn't crash
        
        final exercise = _createTestExercise(orderIndex: -1);

        expect(exercise.orderIndex, equals(-1));
        // The model should store the value even if it's unusual
      });
    });
  });
}

/// Helper method to create a test exercise with minimal required fields
/// Additional fields can be overridden by providing parameters
Exercise _createTestExercise({
  String id = 'test-exercise-id',
  String name = 'Test Exercise',
  ExerciseType exerciseType = ExerciseType.strength,
  int orderIndex = 1,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
  String userId = 'test-user-id',
  String workoutId = 'test-workout-id',
  String weekId = 'test-week-id',
  String programId = 'test-program-id',
}) {
  final testDate = createdAt ?? DateTime(2024, 1, 1);
  return Exercise(
    id: id,
    name: name,
    exerciseType: exerciseType,
    orderIndex: orderIndex,
    notes: notes,
    createdAt: testDate,
    updatedAt: updatedAt ?? testDate,
    userId: userId,
    workoutId: workoutId,
    weekId: weekId,
    programId: programId,
  );
}

/// Mock DocumentSnapshot for testing Firestore deserialization
/// This simulates the data structure returned by Firestore
class MockDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  // Implement other DocumentSnapshot members as needed for testing
  @override
  bool get exists => true;

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  dynamic get(Object field) => _data[field];
}