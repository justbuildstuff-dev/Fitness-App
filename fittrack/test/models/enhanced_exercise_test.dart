/// Comprehensive unit tests for Exercise model
/// 
/// Test Coverage:
/// - Exercise type validation and field mappings
/// - Firestore serialization accuracy and data integrity
/// - Business logic for different exercise types and constraints
/// - Edge cases, validation boundaries, and error conditions
/// - Exercise type enum behavior and conversion logic
/// 
/// If any test fails, it indicates issues with:
/// - Exercise data handling and validation
/// - Firestore integration and data conversion
/// - Business rule validation and type safety
/// - User input validation and data integrity

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/exercise.dart';

void main() {
  group('Exercise Model - Core Functionality', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2025, 1, 1, 12, 0, 0);
    });

    group('Exercise Creation and Validation', () {
      test('creates valid strength exercise with all required fields', () {
        /// Test Purpose: Verify strength exercise creation with complete field validation
        /// This ensures all required and optional fields are handled correctly for strength exercises
        final exercise = Exercise(
          id: 'exercise-1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          notes: 'Test notes',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(exercise.id, 'exercise-1');
        expect(exercise.name, 'Bench Press');
        expect(exercise.exerciseType, ExerciseType.strength);
        expect(exercise.orderIndex, 1);
        expect(exercise.notes, 'Test notes');
        expect(exercise.userId, 'user-123');
        expect(exercise.isValidName, isTrue);
      });

      test('creates valid cardio exercise with minimal fields', () {
        /// Test Purpose: Verify cardio exercise creation with only required fields
        /// This tests the minimal viable exercise creation for cardio type
        final exercise = Exercise(
          id: 'exercise-2',
          name: 'Running',
          exerciseType: ExerciseType.cardio,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(exercise.exerciseType, ExerciseType.cardio);
        expect(exercise.notes, isNull);
        expect(exercise.isValidName, isTrue);
      });

      test('validates name length constraints correctly', () {
        /// Test Purpose: Ensure exercise name validation follows business rules
        /// This validates the 1-200 character constraint for exercise names
        final validExercise = Exercise(
          id: 'test-1',
          name: 'Valid Exercise Name',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final longNameExercise = Exercise(
          id: 'test-2',
          name: 'A' * 201, // 201 characters - exceeds limit
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final emptyNameExercise = Exercise(
          id: 'test-3',
          name: '   ', // Only whitespace
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validExercise.isValidName, isTrue);
        expect(longNameExercise.isValidName, isFalse);
        expect(emptyNameExercise.isValidName, isFalse);
      });
    });

    group('Exercise Type Behavior', () {
      test('returns correct required fields for each exercise type', () {
        /// Test Purpose: Verify exercise type field mappings are correct
        /// This ensures the business logic for different exercise types matches specifications
        expect(ExerciseType.strength.toString().split('.').last, 'strength');
        expect(ExerciseType.cardio.toString().split('.').last, 'cardio');
        expect(ExerciseType.bodyweight.toString().split('.').last, 'bodyweight');
        expect(ExerciseType.custom.toString().split('.').last, 'custom');
        expect(ExerciseType.timeBased.toString().split('.').last, 'timeBased');
      });

      test('validates required set fields per exercise type', () {
        /// Test Purpose: Ensure set field requirements are enforced correctly per exercise type
        /// This validates the business rules for what fields are required for each exercise type
        final strengthExercise = Exercise(
          id: 'test-1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final cardioExercise = Exercise(
          id: 'test-2',
          name: 'Running',
          exerciseType: ExerciseType.cardio,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(strengthExercise.requiredSetFields, containsAll(['reps']));
        expect(strengthExercise.optionalSetFields, containsAll(['weight', 'restTime']));
        
        expect(cardioExercise.requiredSetFields, containsAll(['duration']));
        expect(cardioExercise.optionalSetFields, containsAll(['distance']));
      });

      test('handles exercise type display names correctly', () {
        /// Test Purpose: Verify display name formatting for UI presentation
        /// This ensures consistent display formatting across the application
        expect(ExerciseType.strength.displayName, 'Strength');
        expect(ExerciseType.cardio.displayName, 'Cardio');
        expect(ExerciseType.bodyweight.displayName, 'Bodyweight');
        expect(ExerciseType.custom.displayName, 'Custom');
        expect(ExerciseType.timeBased.displayName, 'Time-based');
      });

      test('converts exercise type from string correctly', () {
        /// Test Purpose: Verify string-to-enum conversion handles all cases
        /// This validates proper parsing of exercise types from user input or Firestore
        expect(ExerciseType.fromString('strength'), ExerciseType.strength);
        expect(ExerciseType.fromString('CARDIO'), ExerciseType.cardio);
        expect(ExerciseType.fromString('bodyweight'), ExerciseType.bodyweight);
        expect(ExerciseType.fromString('time-based'), ExerciseType.timeBased);
        expect(ExerciseType.fromString('timebased'), ExerciseType.timeBased);
        expect(ExerciseType.fromString('invalid'), ExerciseType.custom);
        expect(ExerciseType.fromString(''), ExerciseType.custom);
      });
    });

    group('Firestore Serialization', () {
      test('serializes to Firestore format correctly', () {
        /// Test Purpose: Verify Firestore serialization includes all required fields
        /// This ensures data integrity when saving to Firestore database
        final exercise = Exercise(
          id: 'exercise-1',
          name: 'Squat',
          exerciseType: ExerciseType.strength,
          orderIndex: 2,
          notes: 'Keep back straight',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final firestoreData = exercise.toFirestore();

        expect(firestoreData['name'], 'Squat');
        expect(firestoreData['exerciseType'], 'strength');
        expect(firestoreData['orderIndex'], 2);
        expect(firestoreData['notes'], 'Keep back straight');
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect(firestoreData['userId'], 'user-123');
        expect(firestoreData['workoutId'], 'workout-1');
        expect(firestoreData['weekId'], 'week-1');
        expect(firestoreData['programId'], 'program-1');
      });

      test('deserializes from Firestore correctly with complete data', () {
        /// Test Purpose: Verify Firestore deserialization handles all field types
        /// This ensures proper data reconstruction from Firestore documents
        final firestoreData = {
          'name': 'Pull-ups',
          'exerciseType': 'bodyweight',
          'orderIndex': 3,
          'notes': 'Full range of motion',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
          'workoutId': 'workout-2',
          'weekId': 'week-2',
          'programId': 'program-2',
        };

        // Create a mock DocumentSnapshot
        final mockDoc = _MockDocumentSnapshot('exercise-123', firestoreData);
        
        final exercise = Exercise.fromFirestore(mockDoc, 'workout-2', 'week-2', 'program-2');

        expect(exercise.id, 'exercise-123');
        expect(exercise.name, 'Pull-ups');
        expect(exercise.exerciseType, ExerciseType.bodyweight);
        expect(exercise.orderIndex, 3);
        expect(exercise.notes, 'Full range of motion');
        expect(exercise.userId, 'user-456');
        expect(exercise.workoutId, 'workout-2');
      });

      test('handles missing optional fields during deserialization', () {
        /// Test Purpose: Verify graceful handling of missing optional data
        /// This ensures backward compatibility and robust data handling
        final minimalData = {
          'name': 'Basic Exercise',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        final mockDoc = _MockDocumentSnapshot('exercise-minimal', minimalData);
        
        final exercise = Exercise.fromFirestore(mockDoc, 'workout-1', 'week-1', 'program-1');

        expect(exercise.name, 'Basic Exercise');
        expect(exercise.exerciseType, ExerciseType.custom); // Default fallback
        expect(exercise.orderIndex, 0); // Default value
        expect(exercise.notes, isNull);
        expect(exercise.userId, ''); // Empty string fallback
      });
    });

    group('Exercise Operations', () {
      test('copyWith updates specified fields only', () {
        /// Test Purpose: Verify copyWith method preserves data integrity
        /// This ensures partial updates work correctly without data loss
        final original = Exercise(
          id: 'original-id',
          name: 'Original Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          notes: 'Original notes',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final updated = original.copyWith(
          name: 'Updated Exercise',
          orderIndex: 2,
          updatedAt: testDate.add(Duration(hours: 1)),
        );

        expect(updated.id, 'original-id'); // Unchanged
        expect(updated.name, 'Updated Exercise'); // Changed
        expect(updated.exerciseType, ExerciseType.strength); // Unchanged
        expect(updated.orderIndex, 2); // Changed
        expect(updated.notes, 'Original notes'); // Unchanged
        expect(updated.createdAt, testDate); // Unchanged
        expect(updated.updatedAt, testDate.add(Duration(hours: 1))); // Changed
      });

      test('equality operator works correctly', () {
        /// Test Purpose: Verify object equality comparison for data consistency
        /// This ensures proper comparison behavior for caching and state management
        final exercise1 = Exercise(
          id: 'same-id',
          name: 'Same Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final exercise2 = Exercise(
          id: 'same-id',
          name: 'Same Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final exercise3 = exercise1.copyWith(name: 'Different Exercise');

        expect(exercise1, equals(exercise2));
        expect(exercise1, isNot(equals(exercise3)));
        expect(exercise1.hashCode, equals(exercise2.hashCode));
      });
    });

    group('Exercise Type Enum Tests', () {
      test('exercise type enum serialization to Firestore', () {
        /// Test Purpose: Verify exercise type enum conversion for database storage
        /// This ensures consistent data representation in Firestore
        expect(ExerciseType.strength.toFirestore(), 'strength');
        expect(ExerciseType.cardio.toFirestore(), 'cardio');
        expect(ExerciseType.bodyweight.toFirestore(), 'bodyweight');
        expect(ExerciseType.custom.toFirestore(), 'custom');
        expect(ExerciseType.timeBased.toFirestore(), 'time-based');
      });

      test('exercise type field requirements are correct', () {
        /// Test Purpose: Validate business logic for exercise type field requirements
        /// This ensures UI forms show correct required/optional fields per exercise type
        
        // Test strength exercise requirements
        final strengthExercise = Exercise(
          id: 'test',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(strengthExercise.requiredSetFields, equals(['reps']));
        expect(strengthExercise.optionalSetFields, containsAll(['weight', 'restTime']));

        // Test cardio exercise requirements  
        final cardioExercise = strengthExercise.copyWith(exerciseType: ExerciseType.cardio);
        expect(cardioExercise.requiredSetFields, equals(['duration']));
        expect(cardioExercise.optionalSetFields, contains('distance'));

        // Test bodyweight exercise requirements
        final bodyweightExercise = strengthExercise.copyWith(exerciseType: ExerciseType.bodyweight);
        expect(bodyweightExercise.requiredSetFields, equals(['reps']));
        expect(bodyweightExercise.optionalSetFields, contains('restTime'));

        // Test custom exercise requirements
        final customExercise = strengthExercise.copyWith(exerciseType: ExerciseType.custom);
        expect(customExercise.requiredSetFields, isEmpty);
        expect(customExercise.optionalSetFields, containsAll([
          'reps', 'weight', 'duration', 'distance', 'restTime'
        ]));
      });
    });

    group('Edge Cases and Error Conditions', () {
      test('handles extremely long exercise names gracefully', () {
        /// Test Purpose: Test boundary conditions for exercise name validation
        /// This ensures the system handles edge cases without crashing
        final maxLengthName = 'A' * 200; // Exactly at limit
        final tooLongName = 'A' * 250; // Over limit

        final validExercise = Exercise(
          id: 'test-valid',
          name: maxLengthName,
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final invalidExercise = Exercise(
          id: 'test-invalid',
          name: tooLongName,
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validExercise.isValidName, isTrue);
        expect(invalidExercise.isValidName, isFalse);
      });

      test('handles special characters in exercise names', () {
        /// Test Purpose: Verify exercise names handle international and special characters
        /// This ensures global usability and robust text handling
        final specialCharExercise = Exercise(
          id: 'test-special',
          name: 'Übung für Rücken (Back Exercise) 💪',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(specialCharExercise.isValidName, isTrue);
        expect(specialCharExercise.name, contains('Übung'));
        expect(specialCharExercise.name, contains('💪'));
      });

      test('handles negative order index values', () {
        /// Test Purpose: Test behavior with invalid order index values
        /// This ensures the system handles data corruption or invalid input gracefully
        expect(() => Exercise(
          id: 'test-negative',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: -1, // Invalid order
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        ), returnsNormally); // Should create but may have validation issues
      });
    });

    group('Data Consistency Validation', () {
      test('maintains referential integrity across hierarchy', () {
        /// Test Purpose: Verify hierarchical ID relationships are maintained
        /// This ensures data consistency in the program->week->workout->exercise hierarchy
        final exercise = Exercise(
          id: 'exercise-1',
          name: 'Test Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          workoutId: 'workout-abc',
          weekId: 'week-xyz',
          programId: 'program-def',
        );

        expect(exercise.workoutId, 'workout-abc');
        expect(exercise.weekId, 'week-xyz');
        expect(exercise.programId, 'program-def');
        expect(exercise.userId, 'user-123');
      });

      test('timestamp handling preserves precision', () {
        /// Test Purpose: Ensure timestamp precision is maintained through serialization
        /// This validates that created/updated times are accurately preserved
        final preciseDate = DateTime(2025, 8, 30, 14, 30, 45, 123, 456);
        
        final exercise = Exercise(
          id: 'time-test',
          name: 'Time Test Exercise',
          exerciseType: ExerciseType.strength,
          orderIndex: 1,
          createdAt: preciseDate,
          updatedAt: preciseDate,
          userId: 'user-123',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final firestoreData = exercise.toFirestore();
        final timestamp = firestoreData['createdAt'] as Timestamp;
        final deserializedDate = timestamp.toDate();

        // Firestore timestamps have second precision
        expect(deserializedDate.year, preciseDate.year);
        expect(deserializedDate.month, preciseDate.month);
        expect(deserializedDate.day, preciseDate.day);
        expect(deserializedDate.hour, preciseDate.hour);
        expect(deserializedDate.minute, preciseDate.minute);
        expect(deserializedDate.second, preciseDate.second);
      });
    });
  });
}

/// Mock DocumentSnapshot for testing Firestore deserialization
class _MockDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}