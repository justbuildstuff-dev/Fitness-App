/// Comprehensive unit tests for ExerciseSet model
/// 
/// Test Coverage:
/// - Set validation logic per exercise type
/// - Numeric field validation and constraints
/// - Display string formatting and presentation
/// - Duplication logic and field preservation
/// - Firestore serialization and data integrity
/// 
/// If any test fails, it indicates issues with:
/// - Set data validation and type-specific requirements
/// - Numeric input handling and validation
/// - User interface display formatting
/// - Data duplication and field copying logic
/// - Database serialization and data conversion

import 'package:test/test.dart';
import '../../lib/models/exercise_set.dart';
import '../../lib/models/exercise.dart';

void main() {
  group('ExerciseSet Model - Core Functionality', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2025, 1, 1, 12, 0, 0);
    });

    group('Set Creation and Basic Validation', () {
      test('creates valid strength set with reps and weight', () {
        /// Test Purpose: Verify strength set creation with typical training data
        /// This ensures strength training sets can be created with proper field validation
        final strengthSet = ExerciseSet(
          id: 'set-1',
          setNumber: 1,
          reps: 10,
          weight: 135.5,
          restTime: 120,
          notes: 'Good form',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(strengthSet.reps, 10);
        expect(strengthSet.weight, 135.5);
        expect(strengthSet.checked, false); // Default value
        expect(strengthSet.hasValidNumericValues, isTrue);
        expect(strengthSet.isValidForExerciseType(ExerciseType.strength), isTrue);
      });

      test('creates valid cardio set with duration and distance', () {
        /// Test Purpose: Verify cardio set creation with time and distance metrics
        /// This ensures cardio workouts can track duration and distance correctly
        final cardioSet = ExerciseSet(
          id: 'set-2',
          setNumber: 1,
          duration: 1800, // 30 minutes in seconds
          distance: 5000, // 5km in meters
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(cardioSet.duration, 1800);
        expect(cardioSet.distance, 5000);
        expect(cardioSet.reps, isNull);
        expect(cardioSet.weight, isNull);
        expect(cardioSet.isValidForExerciseType(ExerciseType.cardio), isTrue);
        expect(cardioSet.isValidForExerciseType(ExerciseType.timeBased), isTrue);
      });

      test('creates valid bodyweight set with reps only', () {
        /// Test Purpose: Verify bodyweight exercise sets require only reps
        /// This ensures bodyweight exercises can be tracked without weight measurements
        final bodyweightSet = ExerciseSet(
          id: 'set-3',
          setNumber: 1,
          reps: 15,
          restTime: 60,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-3',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(bodyweightSet.reps, 15);
        expect(bodyweightSet.weight, isNull);
        expect(bodyweightSet.duration, isNull);
        expect(bodyweightSet.isValidForExerciseType(ExerciseType.bodyweight), isTrue);
      });

      test('creates valid custom set with multiple metrics', () {
        /// Test Purpose: Verify custom exercises can use any combination of metrics
        /// This ensures flexible tracking for custom exercise types
        final customSet = ExerciseSet(
          id: 'set-4',
          setNumber: 1,
          reps: 12,
          weight: 45.0,
          duration: 300,
          distance: 1000,
          restTime: 90,
          checked: true,
          notes: 'Mixed training set',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-4',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(customSet.hasAtLeastOneMetric, isTrue);
        expect(customSet.isValidForExerciseType(ExerciseType.custom), isTrue);
        expect(customSet.checked, isTrue);
      });
    });

    group('Exercise Type Validation Logic', () {
      test('validates strength exercise set requirements', () {
        /// Test Purpose: Verify strength sets require reps but allow optional weight
        /// This ensures strength training validation follows business rules
        final validStrengthSet = ExerciseSet(
          id: 'valid-strength',
          setNumber: 1,
          reps: 8,
          weight: 100.0,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final validStrengthNoWeight = ExerciseSet(
          id: 'valid-strength-no-weight',
          setNumber: 1,
          reps: 8,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final invalidStrengthSet = ExerciseSet(
          id: 'invalid-strength',
          setNumber: 1,
          weight: 100.0, // Missing required reps
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validStrengthSet.isValidForExerciseType(ExerciseType.strength), isTrue);
        expect(validStrengthNoWeight.isValidForExerciseType(ExerciseType.strength), isTrue);
        expect(invalidStrengthSet.isValidForExerciseType(ExerciseType.strength), isFalse);
      });

      test('validates cardio exercise set requirements', () {
        /// Test Purpose: Verify cardio sets require duration but allow optional distance
        /// This ensures cardio workout validation follows business rules
        final validCardioSet = ExerciseSet(
          id: 'valid-cardio',
          setNumber: 1,
          duration: 1200, // 20 minutes
          distance: 3000, // 3km
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final validCardioNoDistance = ExerciseSet(
          id: 'valid-cardio-no-distance',
          setNumber: 1,
          duration: 1200,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final invalidCardioSet = ExerciseSet(
          id: 'invalid-cardio',
          setNumber: 1,
          distance: 3000, // Missing required duration
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validCardioSet.isValidForExerciseType(ExerciseType.cardio), isTrue);
        expect(validCardioNoDistance.isValidForExerciseType(ExerciseType.cardio), isTrue);
        expect(invalidCardioSet.isValidForExerciseType(ExerciseType.cardio), isFalse);
      });

      test('validates custom exercise requires at least one metric', () {
        /// Test Purpose: Verify custom exercises need at least one tracking metric
        /// This ensures custom exercises have meaningful data for tracking
        final validCustomSet = ExerciseSet(
          id: 'valid-custom',
          setNumber: 1,
          reps: 1, // At least one metric
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-4',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final emptyCustomSet = ExerciseSet(
          id: 'empty-custom',
          setNumber: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-4',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validCustomSet.hasAtLeastOneMetric, isTrue);
        expect(validCustomSet.isValidForExerciseType(ExerciseType.custom), isTrue);
        expect(emptyCustomSet.hasAtLeastOneMetric, isFalse);
        expect(emptyCustomSet.isValidForExerciseType(ExerciseType.custom), isFalse);
      });
    });

    group('Numeric Validation', () {
      test('validates all numeric fields are non-negative', () {
        /// Test Purpose: Ensure numeric fields follow business constraints
        /// This prevents invalid data like negative weights or durations
        final validSet = ExerciseSet(
          id: 'valid-numeric',
          setNumber: 1,
          reps: 10,
          weight: 50.5,
          duration: 300,
          distance: 1000.0,
          restTime: 120,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final invalidSet = ExerciseSet(
          id: 'invalid-numeric',
          setNumber: 1,
          reps: -5, // Invalid negative reps
          weight: -10.0, // Invalid negative weight
          duration: -60, // Invalid negative duration
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validSet.hasValidNumericValues, isTrue);
        expect(invalidSet.hasValidNumericValues, isFalse);
      });

      test('handles zero values correctly', () {
        /// Test Purpose: Verify zero values are handled appropriately
        /// This ensures edge cases with zero values follow business logic
        final zeroRepsSet = ExerciseSet(
          id: 'zero-reps',
          setNumber: 1,
          reps: 0,
          weight: 100.0,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final zeroWeightSet = ExerciseSet(
          id: 'zero-weight',
          setNumber: 1,
          reps: 10,
          weight: 0.0,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(zeroRepsSet.hasValidNumericValues, isTrue);
        expect(zeroRepsSet.isValidForExerciseType(ExerciseType.strength), isFalse); // reps must be > 0
        expect(zeroWeightSet.hasValidNumericValues, isTrue);
        expect(zeroWeightSet.isValidForExerciseType(ExerciseType.strength), isTrue); // zero weight is valid
      });
    });

    group('Display String Formatting', () {
      test('formats strength set display string correctly', () {
        /// Test Purpose: Verify display string formatting for strength exercises
        /// This ensures proper UI presentation of strength training data
        final strengthSet = ExerciseSet(
          id: 'display-1',
          setNumber: 1,
          reps: 12,
          weight: 225.0,
          restTime: 180,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(strengthSet.displayString, '12 reps × 225kg × rest: 180s');
      });

      test('formats cardio set display string correctly', () {
        /// Test Purpose: Verify display string formatting for cardio exercises
        /// This ensures proper UI presentation of cardio workout data
        final cardioSet = ExerciseSet(
          id: 'display-2',
          setNumber: 1,
          duration: 2400, // 40 minutes
          distance: 8000, // 8km
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(cardioSet.displayString, '40m 0s × 8.00km');
      });

      test('formats time display with minutes and seconds correctly', () {
        /// Test Purpose: Verify time formatting handles various duration values
        /// This ensures consistent time display across different duration ranges
        final shortDurationSet = ExerciseSet(
          id: 'short-duration',
          setNumber: 1,
          duration: 45, // 45 seconds
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final longDurationSet = ExerciseSet(
          id: 'long-duration',
          setNumber: 1,
          duration: 3665, // 1 hour, 1 minute, 5 seconds
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(shortDurationSet.displayString, '45s');
        expect(longDurationSet.displayString, '61m 5s');
      });

      test('formats distance display with appropriate units', () {
        /// Test Purpose: Verify distance formatting uses appropriate units (m/km)
        /// This ensures proper distance display based on magnitude
        final shortDistanceSet = ExerciseSet(
          id: 'short-distance',
          setNumber: 1,
          duration: 600,
          distance: 500, // 500 meters
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final longDistanceSet = ExerciseSet(
          id: 'long-distance',
          setNumber: 1,
          duration: 3600,
          distance: 10500, // 10.5 km
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-2',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(shortDistanceSet.displayString, contains('500m'));
        expect(longDistanceSet.displayString, contains('10.50km'));
      });

      test('handles empty set display correctly', () {
        /// Test Purpose: Verify empty sets display appropriate message
        /// This ensures UI handles incomplete or empty sets gracefully
        final emptySet = ExerciseSet(
          id: 'empty',
          setNumber: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(emptySet.displayString, 'Empty set');
      });
    });

    group('Duplication Logic', () {
      test('creates duplicate strength set with correct field preservation', () {
        /// Test Purpose: Verify strength set duplication preserves appropriate fields
        /// This ensures duplication logic follows specification for strength exercises
        final originalSet = ExerciseSet(
          id: 'original-strength',
          setNumber: 2,
          reps: 10,
          weight: 135.0,
          restTime: 120,
          checked: true,
          notes: 'Previous workout',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final duplicateSet = originalSet.createDuplicateCopy(
          newId: 'duplicate-strength',
          newExerciseId: 'exercise-2',
          newWorkoutId: 'workout-2',
          newWeekId: 'week-2',
          newProgramId: 'program-2',
          exerciseType: ExerciseType.strength,
        );

        expect(duplicateSet.id, 'duplicate-strength');
        expect(duplicateSet.setNumber, 2); // Preserved
        expect(duplicateSet.reps, 10); // Preserved
        expect(duplicateSet.weight, 135.0); // Preserved for progressive overload
        expect(duplicateSet.restTime, 120); // Preserved
        expect(duplicateSet.checked, false); // Reset for new tracking
        expect(duplicateSet.notes, 'Previous workout'); // Preserved
        expect(duplicateSet.exerciseId, 'exercise-2'); // Updated
        expect(duplicateSet.createdAt, isNot(testDate)); // New timestamp
      });

      test('creates duplicate cardio set with correct field preservation', () {
        /// Test Purpose: Verify cardio set duplication preserves time and distance
        /// This ensures cardio duplication follows specification requirements
        final originalCardioSet = ExerciseSet(
          id: 'original-cardio',
          setNumber: 1,
          duration: 1800, // 30 minutes
          distance: 5000, // 5km
          checked: true,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final duplicateCardioSet = originalCardioSet.createDuplicateCopy(
          newId: 'duplicate-cardio',
          newExerciseId: 'exercise-2',
          newWorkoutId: 'workout-2',
          newWeekId: 'week-2',
          newProgramId: 'program-2',
          exerciseType: ExerciseType.cardio,
        );

        expect(duplicateCardioSet.duration, 1800); // Preserved
        expect(duplicateCardioSet.distance, 5000); // Preserved
        expect(duplicateCardioSet.checked, false); // Reset
        expect(duplicateCardioSet.reps, isNull); // Not applicable for cardio
        expect(duplicateCardioSet.weight, isNull); // Not applicable for cardio
      });
    });

    group('Data Serialization', () {
      test('serializes to map format with all fields', () {
        /// Test Purpose: Verify complete data serialization includes all data
        /// This ensures data integrity when saving sets to storage
        final completeSet = ExerciseSet(
          id: 'complete-set',
          setNumber: 3,
          reps: 15,
          weight: 80.5,
          duration: 600,
          distance: 2500.0,
          restTime: 90,
          checked: true,
          notes: 'Great set!',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final mapData = completeSet.toMap();

        expect(mapData['setNumber'], 3);
        expect(mapData['reps'], 15);
        expect(mapData['weight'], 80.5);
        expect(mapData['duration'], 600);
        expect(mapData['distance'], 2500.0);
        expect(mapData['restTime'], 90);
        expect(mapData['checked'], true);
        expect(mapData['notes'], 'Great set!');
        expect(mapData['userId'], 'user-123');
        expect(mapData['exerciseId'], 'exercise-1');
        expect(mapData['createdAt'], isA<String>());
        expect(mapData['updatedAt'], isA<String>());
      });

      test('creates set from complete data map', () {
        /// Test Purpose: Verify data reconstruction from map data
        /// This ensures data accuracy when loading sets from storage
        final dataMap = {
          'setNumber': 2,
          'reps': 8,
          'weight': 120.25,
          'duration': 45,
          'distance': 100.0,
          'restTime': 150,
          'checked': false,
          'notes': 'Focus on form',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'userId': 'user-456',
          'exerciseId': 'exercise-2',
          'workoutId': 'workout-2',
          'weekId': 'week-2',
          'programId': 'program-2',
        };

        final exerciseSet = ExerciseSet(
          id: 'set-123',
          setNumber: dataMap['setNumber'] as int,
          reps: dataMap['reps'] as int?,
          weight: dataMap['weight'] as double?,
          duration: dataMap['duration'] as int?,
          distance: dataMap['distance'] as double?,
          restTime: dataMap['restTime'] as int?,
          checked: dataMap['checked'] as bool? ?? false,
          notes: dataMap['notes'] as String?,
          createdAt: DateTime.parse(dataMap['createdAt'] as String),
          updatedAt: DateTime.parse(dataMap['updatedAt'] as String),
          userId: dataMap['userId'] as String,
          exerciseId: dataMap['exerciseId'] as String,
          workoutId: dataMap['workoutId'] as String,
          weekId: dataMap['weekId'] as String,
          programId: dataMap['programId'] as String,
        );

        expect(exerciseSet.id, 'set-123');
        expect(exerciseSet.setNumber, 2);
        expect(exerciseSet.reps, 8);
        expect(exerciseSet.weight, 120.25);
        expect(exerciseSet.duration, 45);
        expect(exerciseSet.distance, 100.0);
        expect(exerciseSet.restTime, 150);
        expect(exerciseSet.checked, false);
        expect(exerciseSet.notes, 'Focus on form');
        expect(exerciseSet.userId, 'user-456');
      });

      test('handles missing optional fields during data reconstruction', () {
        /// Test Purpose: Verify graceful handling of incomplete data
        /// This ensures backward compatibility and robust data loading
        final minimalData = {
          'setNumber': 1,
          'reps': 5,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'userId': 'user-123',
        };

        final exerciseSet = ExerciseSet(
          id: 'minimal-set',
          setNumber: minimalData['setNumber'] as int,
          reps: minimalData['reps'] as int?,
          weight: minimalData['weight'] as double?,
          duration: minimalData['duration'] as int?,
          distance: minimalData['distance'] as double?,
          restTime: minimalData['restTime'] as int?,
          checked: minimalData['checked'] as bool? ?? false,
          notes: minimalData['notes'] as String?,
          createdAt: DateTime.parse(minimalData['createdAt'] as String),
          updatedAt: DateTime.parse(minimalData['updatedAt'] as String),
          userId: minimalData['userId'] as String,
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(exerciseSet.setNumber, 1);
        expect(exerciseSet.reps, 5);
        expect(exerciseSet.weight, isNull);
        expect(exerciseSet.duration, isNull);
        expect(exerciseSet.distance, isNull);
        expect(exerciseSet.restTime, isNull);
        expect(exerciseSet.checked, false); // Default value
        expect(exerciseSet.notes, isNull);
      });
    });

    group('copyWith Functionality', () {
      test('copyWith updates specified fields only', () {
        /// Test Purpose: Verify copyWith method preserves unmodified fields
        /// This ensures partial updates maintain data integrity
        final original = ExerciseSet(
          id: 'original',
          setNumber: 1,
          reps: 10,
          weight: 100.0,
          checked: false,
          notes: 'Original notes',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        final updated = original.copyWith(
          reps: 12,
          weight: 110.0,
          checked: true,
          updatedAt: testDate.add(Duration(minutes: 5)),
        );

        expect(updated.id, 'original'); // Unchanged
        expect(updated.setNumber, 1); // Unchanged
        expect(updated.reps, 12); // Changed
        expect(updated.weight, 110.0); // Changed
        expect(updated.checked, true); // Changed
        expect(updated.notes, 'Original notes'); // Unchanged
        expect(updated.createdAt, testDate); // Unchanged
        expect(updated.updatedAt, testDate.add(Duration(minutes: 5))); // Changed
      });
    });

    group('Comprehensive Validation Tests', () {
      test('validates complete strength set correctly', () {
        /// Test Purpose: Verify comprehensive validation for strength exercises
        /// This ensures all validation rules work together correctly
        final validStrengthSet = ExerciseSet(
          id: 'valid-complete',
          setNumber: 1,
          reps: 8,
          weight: 225.5,
          restTime: 180,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(validStrengthSet.isValid(ExerciseType.strength), isTrue);
        expect(validStrengthSet.hasValidNumericValues, isTrue);
        expect(validStrengthSet.hasAtLeastOneMetric, isTrue);
      });

      test('identifies invalid sets with comprehensive validation', () {
        /// Test Purpose: Verify comprehensive validation catches all invalid conditions
        /// This ensures data quality and prevents invalid sets from being saved
        final invalidSet = ExerciseSet(
          id: 'invalid-complete',
          setNumber: 0, // Invalid set number
          reps: -5, // Invalid negative reps
          weight: -10.0, // Invalid negative weight
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(invalidSet.isValid(ExerciseType.strength), isFalse);
        expect(invalidSet.hasValidNumericValues, isFalse);
      });
    });

    group('Edge Cases and Error Conditions', () {
      test('handles extreme numeric values', () {
        /// Test Purpose: Test behavior with boundary and extreme values
        /// This ensures the system handles edge cases without crashing
        final extremeSet = ExerciseSet(
          id: 'extreme',
          setNumber: 999,
          reps: 1000,
          weight: 999.99,
          duration: 86400, // 24 hours in seconds
          distance: 1000000, // 1000 km
          restTime: 3600, // 1 hour rest
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(extremeSet.hasValidNumericValues, isTrue);
        expect(extremeSet.hasAtLeastOneMetric, isTrue);
        expect(extremeSet.displayString, isNot('Empty set'));
      });

      test('handles decimal precision for weight values', () {
        /// Test Purpose: Verify weight precision is maintained for accurate tracking
        /// This ensures weight measurements maintain required precision
        final preciseWeightSet = ExerciseSet(
          id: 'precise',
          setNumber: 1,
          reps: 5,
          weight: 123.456789, // High precision
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          exerciseId: 'exercise-1',
          workoutId: 'workout-1',
          weekId: 'week-1',
          programId: 'program-1',
        );

        expect(preciseWeightSet.weight, closeTo(123.456789, 0.0001));
        expect(preciseWeightSet.displayString, contains('123.5kg')); // Formatted for display
      });
    });
  });
}

