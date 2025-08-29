import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/exercise.dart';

/// Unit tests for the ExerciseSet model
/// 
/// These tests verify that the ExerciseSet model correctly:
/// - Validates set data according to exercise type requirements
/// - Handles exercise type-specific field requirements
/// - Serializes to/from Firestore format properly
/// - Implements duplication logic correctly per specification
/// - Formats display strings appropriately for UI
/// - Manages copyWith functionality for updates
/// 
/// If any test fails, it indicates a problem with set data handling
/// that could cause issues when saving/loading sets from Firestore.
void main() {
  group('ExerciseSet Model Tests', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    group('Constructor and Basic Properties', () {
      test('creates valid set with required fields only', () {
        /// Test Purpose: Verify that a set can be created with minimal data
        /// This ensures the model works with required fields only
        
        final set = ExerciseSet(
          id: 'set-123',
          setNumber: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          exerciseId: 'exercise-789',
          workoutId: 'workout-101',
          weekId: 'week-202',
          programId: 'program-303',
        );

        expect(set.id, equals('set-123'));
        expect(set.setNumber, equals(1));
        expect(set.checked, isFalse); // Default value
        expect(set.createdAt, equals(testDate));
        expect(set.updatedAt, equals(testDate));
        expect(set.userId, equals('user-456'));
        expect(set.exerciseId, equals('exercise-789'));
        expect(set.workoutId, equals('workout-101'));
        expect(set.weekId, equals('week-202'));
        expect(set.programId, equals('program-303'));
        
        // Verify nullable fields default to null
        expect(set.reps, isNull);
        expect(set.weight, isNull);
        expect(set.duration, isNull);
        expect(set.distance, isNull);
        expect(set.restTime, isNull);
        expect(set.notes, isNull);
      });

      test('creates valid set with all fields populated', () {
        /// Test Purpose: Verify that a set can be created with all fields
        /// This ensures the model handles complete set data correctly
        
        final set = ExerciseSet(
          id: 'set-456',
          setNumber: 2,
          reps: 12,
          weight: 100.5,
          duration: 90, // 90 seconds
          distance: 1000.0, // 1000 meters
          restTime: 120, // 2 minutes
          checked: true,
          notes: 'Good form, felt strong',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          exerciseId: 'exercise-789',
          workoutId: 'workout-101',
          weekId: 'week-202',
          programId: 'program-303',
        );

        expect(set.reps, equals(12));
        expect(set.weight, equals(100.5));
        expect(set.duration, equals(90));
        expect(set.distance, equals(1000.0));
        expect(set.restTime, equals(120));
        expect(set.checked, isTrue);
        expect(set.notes, equals('Good form, felt strong'));
      });
    });

    group('Exercise Type Validation', () {
      test('isValidForExerciseType validates strength exercise sets correctly', () {
        /// Test Purpose: Verify strength exercise validation
        /// Strength exercises require reps, weight is optional
        
        // Valid strength set with reps
        final validSet = _createTestSet(reps: 10);
        expect(validSet.isValidForExerciseType(ExerciseType.strength), isTrue);

        // Valid strength set with reps and weight
        final validSetWithWeight = _createTestSet(reps: 8, weight: 80.0);
        expect(validSetWithWeight.isValidForExerciseType(ExerciseType.strength), isTrue);

        // Invalid strength set without reps
        final invalidSet = _createTestSet(weight: 100.0); // weight without reps
        expect(invalidSet.isValidForExerciseType(ExerciseType.strength), isFalse);

        // Invalid strength set with zero reps
        final zeroRepsSet = _createTestSet(reps: 0);
        expect(zeroRepsSet.isValidForExerciseType(ExerciseType.strength), isFalse);
      });

      test('isValidForExerciseType validates cardio exercise sets correctly', () {
        /// Test Purpose: Verify cardio exercise validation
        /// Cardio exercises require duration, distance is optional
        
        // Valid cardio set with duration
        final validSet = _createTestSet(duration: 300); // 5 minutes
        expect(validSet.isValidForExerciseType(ExerciseType.cardio), isTrue);

        // Valid cardio set with duration and distance
        final validSetWithDistance = _createTestSet(duration: 1800, distance: 5000.0); // 30 min, 5km
        expect(validSetWithDistance.isValidForExerciseType(ExerciseType.cardio), isTrue);

        // Invalid cardio set without duration
        final invalidSet = _createTestSet(distance: 1000.0); // distance without duration
        expect(invalidSet.isValidForExerciseType(ExerciseType.cardio), isFalse);

        // Invalid cardio set with zero duration
        final zeroDurationSet = _createTestSet(duration: 0);
        expect(zeroDurationSet.isValidForExerciseType(ExerciseType.cardio), isFalse);
      });

      test('isValidForExerciseType validates time-based exercise sets correctly', () {
        /// Test Purpose: Verify time-based exercise validation
        /// Time-based exercises have same requirements as cardio
        
        final validSet = _createTestSet(duration: 600); // 10 minutes
        expect(validSet.isValidForExerciseType(ExerciseType.timeBased), isTrue);

        final invalidSet = _createTestSet(reps: 10); // reps without duration
        expect(invalidSet.isValidForExerciseType(ExerciseType.timeBased), isFalse);
      });

      test('isValidForExerciseType validates bodyweight exercise sets correctly', () {
        /// Test Purpose: Verify bodyweight exercise validation
        /// Bodyweight exercises require reps, no weight
        
        final validSet = _createTestSet(reps: 15);
        expect(validSet.isValidForExerciseType(ExerciseType.bodyweight), isTrue);

        final invalidSet = _createTestSet(weight: 0.0); // weight without reps
        expect(invalidSet.isValidForExerciseType(ExerciseType.bodyweight), isFalse);
      });

      test('isValidForExerciseType validates custom exercise sets correctly', () {
        /// Test Purpose: Verify custom exercise validation
        /// Custom exercises just need at least one metric
        
        final validWithReps = _createTestSet(reps: 5);
        expect(validWithReps.isValidForExerciseType(ExerciseType.custom), isTrue);

        final validWithWeight = _createTestSet(reps: 1); // weight alone doesn't count as a metric
        expect(validWithWeight.isValidForExerciseType(ExerciseType.custom), isTrue);

        final validWithDuration = _createTestSet(duration: 120);
        expect(validWithDuration.isValidForExerciseType(ExerciseType.custom), isTrue);

        final validWithDistance = _createTestSet(distance: 500.0);
        expect(validWithDistance.isValidForExerciseType(ExerciseType.custom), isTrue);

        final invalidSet = _createTestSet(); // no metrics at all
        expect(invalidSet.isValidForExerciseType(ExerciseType.custom), isFalse);
      });
    });

    group('General Validation Methods', () {
      test('hasAtLeastOneMetric returns true when any positive metric is present', () {
        /// Test Purpose: Verify that sets with any valid metric pass basic validation
        /// This ensures all exercise types have at least one meaningful data point
        
        expect(_createTestSet(reps: 1).hasAtLeastOneMetric, isTrue);
        expect(_createTestSet(duration: 1).hasAtLeastOneMetric, isTrue);
        expect(_createTestSet(distance: 1.0).hasAtLeastOneMetric, isTrue);
        expect(_createTestSet(reps: 10, weight: 50.0).hasAtLeastOneMetric, isTrue);
      });

      test('hasAtLeastOneMetric returns false when no positive metrics are present', () {
        /// Test Purpose: Verify that sets without meaningful data are invalid
        /// This prevents empty or zero-value sets from being considered valid
        
        expect(_createTestSet().hasAtLeastOneMetric, isFalse); // no metrics
        expect(_createTestSet(reps: 0).hasAtLeastOneMetric, isFalse); // zero reps
        expect(_createTestSet(duration: 0).hasAtLeastOneMetric, isFalse); // zero duration
        expect(_createTestSet(distance: 0.0).hasAtLeastOneMetric, isFalse); // zero distance
        expect(_createTestSet(weight: 50.0).hasAtLeastOneMetric, isFalse); // weight alone isn't a metric
      });

      test('hasValidNumericValues validates non-negative numbers', () {
        /// Test Purpose: Verify that all numeric fields must be non-negative
        /// This prevents invalid negative values in sets
        
        expect(_createTestSet(reps: 10, weight: 100.0, duration: 60, distance: 1000.0, restTime: 90).hasValidNumericValues, isTrue);
        expect(_createTestSet(reps: 0, weight: 0.0, duration: 0, distance: 0.0, restTime: 0).hasValidNumericValues, isTrue);
        
        // Test negative values
        expect(_createTestSet(reps: -1).hasValidNumericValues, isFalse);
        expect(_createTestSet(weight: -50.0).hasValidNumericValues, isFalse);
        expect(_createTestSet(duration: -30).hasValidNumericValues, isFalse);
        expect(_createTestSet(distance: -100.0).hasValidNumericValues, isFalse);
        expect(_createTestSet(restTime: -60).hasValidNumericValues, isFalse);
      });

      test('isValid combines all validation rules correctly', () {
        /// Test Purpose: Verify comprehensive validation works correctly
        /// This method combines exercise type validation with general validation
        
        // Valid strength set
        final validStrengthSet = _createTestSet(setNumber: 1, reps: 10, weight: 80.0);
        expect(validStrengthSet.isValid(ExerciseType.strength), isTrue);

        // Invalid set with negative values
        final negativeSet = _createTestSet(setNumber: 1, reps: 10, weight: -50.0);
        expect(negativeSet.isValid(ExerciseType.strength), isFalse);

        // Invalid set with zero set number
        final zeroSetNumber = _createTestSet(setNumber: 0, reps: 10);
        expect(zeroSetNumber.isValid(ExerciseType.strength), isFalse);

        // Invalid set that doesn't meet exercise type requirements
        final wrongTypeSet = _createTestSet(setNumber: 1, weight: 100.0); // strength needs reps
        expect(wrongTypeSet.isValid(ExerciseType.strength), isFalse);
      });
    });

    group('Duplication Logic', () {
      test('createDuplicateCopy resets weight for strength exercises', () {
        /// Test Purpose: Verify duplication follows specification for strength exercises
        /// Per spec, strength exercises should reset weight to null but keep reps
        
        final original = _createTestSet(
          id: 'original-id',
          setNumber: 1,
          reps: 12,
          weight: 100.0,
          restTime: 90,
          notes: 'Original set notes',
          exerciseId: 'original-exercise',
          workoutId: 'original-workout',
          weekId: 'original-week',
          programId: 'original-program',
        );

        final duplicate = original.createDuplicateCopy(
          newId: 'new-id',
          newExerciseId: 'new-exercise',
          newWorkoutId: 'new-workout',
          newWeekId: 'new-week',
          newProgramId: 'new-program',
          exerciseType: ExerciseType.strength,
        );

        // Verify strength-specific duplication rules
        expect(duplicate.reps, equals(12)); // Keep reps
        expect(duplicate.weight, isNull); // Reset weight
        expect(duplicate.restTime, equals(90)); // Keep rest time

        // Verify general duplication rules
        expect(duplicate.checked, isFalse); // Always reset checked
        expect(duplicate.setNumber, equals(1)); // Keep set number
        expect(duplicate.notes, equals('Original set notes')); // Keep notes

        // Verify new IDs are applied
        expect(duplicate.id, equals('new-id'));
        expect(duplicate.exerciseId, equals('new-exercise'));
        expect(duplicate.workoutId, equals('new-workout'));
        expect(duplicate.weekId, equals('new-week'));
        expect(duplicate.programId, equals('new-program'));

        // Verify timestamps are updated
        expect(duplicate.createdAt.isAfter(original.createdAt), isTrue);
        expect(duplicate.updatedAt.isAfter(original.updatedAt), isTrue);
      });

      test('createDuplicateCopy preserves all fields for cardio exercises', () {
        /// Test Purpose: Verify duplication follows specification for cardio exercises
        /// Per spec, cardio exercises should keep duration and distance
        
        final original = _createTestSet(
          id: 'original-id',
          setNumber: 2,
          duration: 1800, // 30 minutes
          distance: 5000.0, // 5km
          checked: true,
          notes: 'Good pace',
          exerciseId: 'original-exercise',
          workoutId: 'original-workout',
          weekId: 'original-week',
          programId: 'original-program',
        );

        final duplicate = original.createDuplicateCopy(
          newId: 'new-id',
          newExerciseId: 'new-exercise',
          newWorkoutId: 'new-workout',
          newWeekId: 'new-week',
          newProgramId: 'new-program',
          exerciseType: ExerciseType.cardio,
        );

        // Verify cardio-specific duplication rules
        expect(duplicate.duration, equals(1800)); // Keep duration
        expect(duplicate.distance, equals(5000.0)); // Keep distance

        // Verify checked is always reset
        expect(duplicate.checked, isFalse);
      });

      test('createDuplicateCopy preserves reps for bodyweight exercises', () {
        /// Test Purpose: Verify duplication follows specification for bodyweight exercises
        /// Per spec, bodyweight exercises should keep reps and restTime
        
        final original = _createTestSet(
          id: 'original-id',
          setNumber: 3,
          reps: 20,
          restTime: 60,
          exerciseId: 'original-exercise',
          workoutId: 'original-workout',
          weekId: 'original-week',
          programId: 'original-program',
        );

        final duplicate = original.createDuplicateCopy(
          newId: 'new-id',
          newExerciseId: 'new-exercise',
          newWorkoutId: 'new-workout',
          newWeekId: 'new-week',
          newProgramId: 'new-program',
          exerciseType: ExerciseType.bodyweight,
        );

        expect(duplicate.reps, equals(20)); // Keep reps
        expect(duplicate.restTime, equals(60)); // Keep rest time
        expect(duplicate.weight, isNull); // Should remain null
      });

      test('createDuplicateCopy preserves all fields for custom exercises', () {
        /// Test Purpose: Verify duplication follows specification for custom exercises
        /// Per spec, custom exercises should keep all fields
        
        final original = _createTestSet(
          id: 'original-id',
          setNumber: 1,
          reps: 15,
          weight: 75.0,
          duration: 300,
          distance: 1500.0,
          restTime: 120,
          checked: true,
          notes: 'Custom exercise set',
          exerciseId: 'original-exercise',
          workoutId: 'original-workout',
          weekId: 'original-week',
          programId: 'original-program',
        );

        final duplicate = original.createDuplicateCopy(
          newId: 'new-id',
          newExerciseId: 'new-exercise',
          newWorkoutId: 'new-workout',
          newWeekId: 'new-week',
          newProgramId: 'new-program',
          exerciseType: ExerciseType.custom,
        );

        // Verify all fields are preserved for custom exercises
        expect(duplicate.reps, equals(15));
        expect(duplicate.weight, equals(75.0));
        expect(duplicate.duration, equals(300));
        expect(duplicate.distance, equals(1500.0));
        expect(duplicate.restTime, equals(120));
        
        // Except checked should always be reset
        expect(duplicate.checked, isFalse);
      });
    });

    group('Display String Formatting', () {
      test('displayString formats strength sets correctly', () {
        /// Test Purpose: Verify that strength sets display properly in UI
        /// Format should show reps, weight, and rest time when present
        
        final repsOnly = _createTestSet(reps: 10);
        expect(repsOnly.displayString, equals('10 reps'));

        final repsAndWeight = _createTestSet(reps: 12, weight: 100.0);
        expect(repsAndWeight.displayString, equals('12 reps × 100kg'));

        final fullSet = _createTestSet(reps: 8, weight: 80.5, restTime: 90);
        expect(fullSet.displayString, equals('8 reps × 80.5kg × rest: 90s'));
      });

      test('displayString formats cardio sets correctly', () {
        /// Test Purpose: Verify that cardio sets display properly in UI
        /// Format should show duration and distance when present
        
        final durationOnly = _createTestSet(duration: 1800); // 30 minutes
        expect(durationOnly.displayString, equals('30m 0s'));

        final shortDuration = _createTestSet(duration: 90); // 1.5 minutes
        expect(shortDuration.displayString, equals('1m 30s'));

        final secondsOnly = _createTestSet(duration: 45); // 45 seconds
        expect(secondsOnly.displayString, equals('45s'));

        final withDistance = _createTestSet(duration: 600, distance: 2000.0); // 10 min, 2km
        expect(withDistance.displayString, equals('10m 0s × 2.00km'));

        final shortDistance = _createTestSet(duration: 300, distance: 800.0); // 5 min, 800m
        expect(shortDistance.displayString, equals('5m 0s × 800m'));
      });

      test('displayString handles weight formatting correctly', () {
        /// Test Purpose: Verify weight formatting shows appropriate decimal places
        /// Whole numbers should not show decimals, but fractional weights should
        
        final wholeWeight = _createTestSet(reps: 10, weight: 100.0);
        expect(wholeWeight.displayString, equals('10 reps × 100kg'));

        final fractionalWeight = _createTestSet(reps: 10, weight: 100.5);
        expect(fractionalWeight.displayString, equals('10 reps × 100.5kg'));

        final preciseWeight = _createTestSet(reps: 10, weight: 67.25);
        expect(preciseWeight.displayString, equals('10 reps × 67.3kg')); // 67.25 rounds to 67.3
      });

      test('displayString handles distance formatting correctly', () {
        /// Test Purpose: Verify distance formatting shows km for large distances, m for small
        /// This provides appropriate units for different scales
        
        final shortDistance = _createTestSet(duration: 300, distance: 500.0);
        expect(shortDistance.displayString, equals('5m 0s × 500m'));

        final exactKm = _createTestSet(duration: 600, distance: 1000.0);
        expect(exactKm.displayString, equals('10m 0s × 1.00km'));

        final longDistance = _createTestSet(duration: 1800, distance: 5000.0);
        expect(longDistance.displayString, equals('30m 0s × 5.00km'));

        final fractionalKm = _createTestSet(duration: 900, distance: 2500.0);
        expect(fractionalKm.displayString, equals('15m 0s × 2.50km'));
      });

      test('displayString returns appropriate message for empty sets', () {
        /// Test Purpose: Verify empty sets have appropriate display
        /// This handles edge cases where no metrics are present
        
        final emptySet = _createTestSet();
        expect(emptySet.displayString, equals('Empty set'));
      });
    });

    group('Firestore Serialization', () {
      test('toFirestore includes all fields with correct types', () {
        /// Test Purpose: Verify that set data serializes correctly for Firestore
        /// All fields should be included with proper types and formatting
        
        final set = _createTestSet(
          setNumber: 2,
          reps: 12,
          weight: 100.5,
          duration: 300,
          distance: 1500.0,
          restTime: 90,
          checked: true,
          notes: 'Great form on this set',
        );

        final firestoreData = set.toFirestore();

        expect(firestoreData['setNumber'], equals(2));
        expect(firestoreData['reps'], equals(12));
        expect(firestoreData['weight'], equals(100.5));
        expect(firestoreData['duration'], equals(300));
        expect(firestoreData['distance'], equals(1500.0));
        expect(firestoreData['restTime'], equals(90));
        expect(firestoreData['checked'], equals(true));
        expect(firestoreData['notes'], equals('Great form on this set'));
        expect(firestoreData['userId'], equals('test-user-id'));

        // Verify timestamps are converted to Firestore format
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());

        // Verify path parameters are NOT included
        expect(firestoreData, isNot(contains('id')));
        expect(firestoreData, isNot(contains('exerciseId')));
        expect(firestoreData, isNot(contains('workoutId')));
        expect(firestoreData, isNot(contains('weekId')));
        expect(firestoreData, isNot(contains('programId')));
      });

      test('toFirestore handles null values correctly', () {
        /// Test Purpose: Verify that null fields are preserved in serialization
        /// Null values should be explicitly included, not omitted
        
        final setWithNulls = _createTestSet(
          setNumber: 1,
          reps: null,
          weight: null,
          duration: null,
          distance: null,
          restTime: null,
          notes: null,
        );

        final firestoreData = setWithNulls.toFirestore();

        expect(firestoreData['reps'], isNull);
        expect(firestoreData['weight'], isNull);
        expect(firestoreData['duration'], isNull);
        expect(firestoreData['distance'], isNull);
        expect(firestoreData['restTime'], isNull);
        expect(firestoreData['notes'], isNull);
        expect(firestoreData['checked'], equals(false)); // Should have default value
      });
    });

    group('Firestore Deserialization', () {
      test('fromFirestore creates set from complete Firestore data', () {
        /// Test Purpose: Verify that set data deserializes correctly from Firestore
        /// This ensures data loaded from database matches what was stored
        
        final firestoreData = {
          'setNumber': 3,
          'reps': 15,
          'weight': 85.5,
          'duration': 120,
          'distance': 800.0,
          'restTime': 60,
          'checked': true,
          'notes': 'Felt challenging but good',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('set-123', firestoreData);
        
        final set = ExerciseSet.fromFirestore(
          mockDoc,
          'exercise-789',
          'workout-101',
          'week-202',
          'program-303',
        );

        expect(set.id, equals('set-123'));
        expect(set.setNumber, equals(3));
        expect(set.reps, equals(15));
        expect(set.weight, equals(85.5));
        expect(set.duration, equals(120));
        expect(set.distance, equals(800.0));
        expect(set.restTime, equals(60));
        expect(set.checked, equals(true));
        expect(set.notes, equals('Felt challenging but good'));
        expect(set.createdAt, equals(testDate));
        expect(set.updatedAt, equals(testDate));
        expect(set.userId, equals('user-456'));
        expect(set.exerciseId, equals('exercise-789'));
        expect(set.workoutId, equals('workout-101'));
        expect(set.weekId, equals('week-202'));
        expect(set.programId, equals('program-303'));
      });

      test('fromFirestore handles missing fields gracefully', () {
        /// Test Purpose: Verify that missing fields get appropriate defaults
        /// This ensures backwards compatibility with incomplete data
        
        final firestoreData = {
          // setNumber omitted - should default to 1
          'reps': 10,
          // weight omitted - should be null
          // duration omitted - should be null
          // checked omitted - should default to false
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('set-456', firestoreData);
        final set = ExerciseSet.fromFirestore(
          mockDoc,
          'exercise-789',
          'workout-101',
          'week-202',
          'program-303',
        );

        expect(set.setNumber, equals(1));
        expect(set.reps, equals(10));
        expect(set.weight, isNull);
        expect(set.duration, isNull);
        expect(set.checked, equals(false));
        expect(set.userId, equals('user-456'));
      });

      test('fromFirestore converts numeric types correctly', () {
        /// Test Purpose: Verify that Firestore numeric data is converted properly
        /// Firestore might return ints as doubles or vice versa
        
        final firestoreData = {
          'setNumber': 2,
          'reps': 12.0, // Double from Firestore
          'weight': 100, // Int from Firestore  
          'duration': 300.0, // Double from Firestore
          'distance': 1500, // Int from Firestore
          'restTime': 90.0, // Double from Firestore
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('set-789', firestoreData);
        final set = ExerciseSet.fromFirestore(
          mockDoc,
          'exercise-789',
          'workout-101',
          'week-202',
          'program-303',
        );

        expect(set.reps, equals(12)); // Should convert to int
        expect(set.weight, equals(100.0)); // Should convert to double
        expect(set.duration, equals(300)); // Should convert to int
        expect(set.distance, equals(1500.0)); // Should convert to double
        expect(set.restTime, equals(90)); // Should convert to int
      });
    });

    group('Copy With Method', () {
      test('copyWith creates new set with updated fields', () {
        /// Test Purpose: Verify that copyWith method works correctly for updates
        /// This method is used when updating existing sets
        
        final original = _createTestSet(
          setNumber: 1,
          reps: 10,
          weight: 100.0,
          checked: false,
          notes: 'Original notes',
        );

        final updated = original.copyWith(
          reps: 12,
          weight: 110.0,
          checked: true,
          notes: 'Updated notes',
          updatedAt: testDate.add(Duration(hours: 1)),
        );

        // Verify updated fields changed
        expect(updated.reps, equals(12));
        expect(updated.weight, equals(110.0));
        expect(updated.checked, equals(true));
        expect(updated.notes, equals('Updated notes'));
        expect(updated.updatedAt, equals(testDate.add(Duration(hours: 1))));

        // Verify unchanged fields remained the same
        expect(updated.id, equals(original.id));
        expect(updated.setNumber, equals(original.setNumber));
        expect(updated.createdAt, equals(original.createdAt));
        expect(updated.userId, equals(original.userId));
      });

      test('copyWith preserves original values for unspecified parameters', () {
        /// Test Purpose: Verify that copyWith doesn't overwrite fields with null
        /// Only specified fields should be updated
        
        final original = _createTestSet(
          reps: 15,
          weight: 75.0,
          duration: 300,
          notes: 'Keep these notes',
        );

        final updated = original.copyWith(
          checked: true, // Only update checked status
        );

        expect(updated.reps, equals(15));
        expect(updated.weight, equals(75.0));
        expect(updated.duration, equals(300));
        expect(updated.notes, equals('Keep these notes'));
        expect(updated.checked, equals(true)); // This was updated
      });
    });
  });
}

/// Helper method to create a test set with minimal required fields
/// Additional fields can be overridden by providing parameters
ExerciseSet _createTestSet({
  String id = 'test-set-id',
  int setNumber = 1,
  int? reps,
  double? weight,
  int? duration,
  double? distance,
  int? restTime,
  bool checked = false,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
  String userId = 'test-user-id',
  String exerciseId = 'test-exercise-id',
  String workoutId = 'test-workout-id',
  String weekId = 'test-week-id',
  String programId = 'test-program-id',
}) {
  final testDate = createdAt ?? DateTime(2024, 1, 1);
  return ExerciseSet(
    id: id,
    setNumber: setNumber,
    reps: reps,
    weight: weight,
    duration: duration,
    distance: distance,
    restTime: restTime,
    checked: checked,
    notes: notes,
    createdAt: testDate,
    updatedAt: updatedAt ?? testDate,
    userId: userId,
    exerciseId: exerciseId,
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