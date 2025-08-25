import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/models/workout.dart';

/// Unit tests for the Workout model
/// 
/// These tests verify that the Workout model correctly:
/// - Validates workout data according to business rules
/// - Serializes to/from Firestore format properly
/// - Handles optional and required fields appropriately
/// 
/// If any test fails, it indicates a problem with workout data handling
/// that could cause issues when saving/loading workouts from Firestore.
void main() {
  group('Workout Model Tests', () {
    late DateTime testDate;
    
    setUp(() {
      // Set up consistent test data
      // Using a fixed date ensures test reproducibility
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    group('Constructor and Basic Properties', () {
      test('creates valid workout with required fields only', () {
        /// Test Purpose: Verify that a workout can be created with only required fields
        /// This ensures the model works with minimal data, which is important for
        /// cases where users create workouts without optional details
        
        final workout = Workout(
          id: 'workout-123',
          name: 'Push Day',
          orderIndex: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          weekId: 'week-789',
          programId: 'program-101',
        );

        // Verify all required fields are set correctly
        expect(workout.id, equals('workout-123'));
        expect(workout.name, equals('Push Day'));
        expect(workout.orderIndex, equals(1));
        expect(workout.createdAt, equals(testDate));
        expect(workout.updatedAt, equals(testDate));
        expect(workout.userId, equals('user-456'));
        expect(workout.weekId, equals('week-789'));
        expect(workout.programId, equals('program-101'));
        
        // Verify optional fields default to null
        expect(workout.dayOfWeek, isNull, 
          reason: 'dayOfWeek should be null when not specified');
        expect(workout.notes, isNull,
          reason: 'notes should be null when not specified');
      });

      test('creates valid workout with all fields including optional ones', () {
        /// Test Purpose: Verify that a workout can be created with all fields populated
        /// This ensures the model handles the full range of workout data correctly
        
        final workout = Workout(
          id: 'workout-123',
          name: 'Upper Body Strength',
          dayOfWeek: 2, // Tuesday
          orderIndex: 3,
          notes: 'Focus on form over weight',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          weekId: 'week-789',
          programId: 'program-101',
        );

        // Verify all fields including optional ones
        expect(workout.dayOfWeek, equals(2));
        expect(workout.notes, equals('Focus on form over weight'));
        expect(workout.dayOfWeekName, equals('Tuesday'),
          reason: 'dayOfWeekName should return correct day name for dayOfWeek=2');
      });
    });

    group('Validation Methods', () {
      test('isValidName returns true for valid workout names', () {
        /// Test Purpose: Verify that workout name validation works correctly
        /// The name field is critical for user identification of workouts
        /// and must meet length requirements (1-200 characters)
        
        final validNames = [
          'Push',           // Minimum length
          'Upper Body',     // Normal length
          'A' * 200,        // Maximum length (200 chars)
        ];

        for (final name in validNames) {
          final workout = _createTestWorkout(name: name);
          expect(workout.isValidName, isTrue, 
            reason: 'Name "$name" should be valid (length: ${name.length})');
        }
      });

      test('isValidName returns false for invalid workout names', () {
        /// Test Purpose: Verify that invalid workout names are properly rejected
        /// This prevents empty names or overly long names that could cause UI issues
        
        final invalidNames = [
          '',              // Empty string
          '   ',           // Only whitespace
          'A' * 201,       // Too long (201 chars)
        ];

        for (final name in invalidNames) {
          final workout = _createTestWorkout(name: name);
          expect(workout.isValidName, isFalse, 
            reason: 'Name "$name" should be invalid (length after trim: ${name.trim().length})');
        }
      });

      test('isValidDayOfWeek returns true for valid day values', () {
        /// Test Purpose: Verify day of week validation follows business rules
        /// Days must be 1-7 (Monday-Sunday) or null (no specific day)
        
        final validDays = [null, 1, 2, 3, 4, 5, 6, 7];

        for (final day in validDays) {
          final workout = _createTestWorkout(dayOfWeek: day);
          expect(workout.isValidDayOfWeek, isTrue, 
            reason: 'Day $day should be valid');
        }
      });

      test('isValidDayOfWeek returns false for invalid day values', () {
        /// Test Purpose: Verify that invalid day values are rejected
        /// This prevents data corruption and ensures UI consistency
        
        final invalidDays = [0, 8, -1, 99];

        for (final day in invalidDays) {
          final workout = _createTestWorkout(dayOfWeek: day);
          expect(workout.isValidDayOfWeek, isFalse, 
            reason: 'Day $day should be invalid (must be 1-7 or null)');
        }
      });
    });

    group('Day of Week Name Mapping', () {
      test('dayOfWeekName returns correct day names', () {
        /// Test Purpose: Verify that dayOfWeek integers map to correct day names
        /// This mapping is used throughout the UI to display human-readable day names
        
        final dayMappings = {
          1: 'Monday',
          2: 'Tuesday', 
          3: 'Wednesday',
          4: 'Thursday',
          5: 'Friday',
          6: 'Saturday',
          7: 'Sunday',
        };

        dayMappings.forEach((dayNumber, expectedName) {
          final workout = _createTestWorkout(dayOfWeek: dayNumber);
          expect(workout.dayOfWeekName, equals(expectedName),
            reason: 'Day $dayNumber should map to $expectedName');
        });
      });

      test('dayOfWeekName returns empty string for null dayOfWeek', () {
        /// Test Purpose: Verify null dayOfWeek handling
        /// When no specific day is assigned, the UI should show nothing
        
        final workout = _createTestWorkout(dayOfWeek: null);
        expect(workout.dayOfWeekName, equals(''),
          reason: 'null dayOfWeek should return empty string, not throw error');
      });
    });

    group('Firestore Serialization', () {
      test('toFirestore includes all necessary fields', () {
        /// Test Purpose: Verify that workout data serializes correctly for Firestore storage
        /// Missing or incorrectly formatted fields could cause database write failures
        
        final workout = Workout(
          id: 'workout-123',
          name: 'Leg Day',
          dayOfWeek: 5, // Friday
          orderIndex: 2,
          notes: 'Remember to warm up',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          weekId: 'week-789',
          programId: 'program-101',
        );

        final firestoreData = workout.toFirestore();

        // Verify all fields are present with correct values
        expect(firestoreData['name'], equals('Leg Day'));
        expect(firestoreData['dayOfWeek'], equals(5));
        expect(firestoreData['orderIndex'], equals(2));
        expect(firestoreData['notes'], equals('Remember to warm up'));
        expect(firestoreData['userId'], equals('user-456'));
        
        // Verify timestamps are converted to Firestore format
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));

        // Verify weekId and programId are NOT included (they're path parameters, not document fields)
        expect(firestoreData, isNot(contains('weekId')));
        expect(firestoreData, isNot(contains('programId')));
        expect(firestoreData, isNot(contains('id')));
      });

      test('toFirestore handles null optional fields correctly', () {
        /// Test Purpose: Verify that null optional fields are preserved in Firestore data
        /// Null values should be explicitly included to match Firestore security rules
        
        final workout = _createTestWorkout(
          dayOfWeek: null,
          notes: null,
        );

        final firestoreData = workout.toFirestore();

        expect(firestoreData['dayOfWeek'], isNull,
          reason: 'Null dayOfWeek should be preserved, not omitted');
        expect(firestoreData['notes'], isNull,
          reason: 'Null notes should be preserved, not omitted');
      });
    });

    group('Firestore Deserialization', () {
      test('fromFirestore creates workout from complete Firestore data', () {
        /// Test Purpose: Verify that workout data deserializes correctly from Firestore
        /// This ensures data loaded from the database matches what was stored
        
        final firestoreData = {
          'name': 'Full Body',
          'dayOfWeek': 3, // Wednesday
          'orderIndex': 1,
          'notes': 'Compound movements focus',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        // Mock DocumentSnapshot
        final mockDoc = MockDocumentSnapshot('workout-123', firestoreData);
        
        final workout = Workout.fromFirestore(mockDoc, 'week-789', 'program-101');

        expect(workout.id, equals('workout-123'));
        expect(workout.name, equals('Full Body'));
        expect(workout.dayOfWeek, equals(3));
        expect(workout.orderIndex, equals(1));
        expect(workout.notes, equals('Compound movements focus'));
        expect(workout.createdAt, equals(testDate));
        expect(workout.updatedAt, equals(testDate));
        expect(workout.userId, equals('user-456'));
        expect(workout.weekId, equals('week-789'));
        expect(workout.programId, equals('program-101'));
      });

      test('fromFirestore handles missing optional fields gracefully', () {
        /// Test Purpose: Verify that missing optional fields default to appropriate values
        /// This ensures backwards compatibility and handles partially populated data
        
        final firestoreData = {
          'name': 'Basic Workout',
          // dayOfWeek omitted
          'orderIndex': 0,
          // notes omitted
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('workout-456', firestoreData);
        final workout = Workout.fromFirestore(mockDoc, 'week-789', 'program-101');

        expect(workout.dayOfWeek, isNull,
          reason: 'Missing dayOfWeek should default to null');
        expect(workout.notes, isNull,
          reason: 'Missing notes should default to null');
        expect(workout.name, equals('Basic Workout'),
          reason: 'Present fields should still be loaded correctly');
      });

      test('fromFirestore provides defaults for missing required fields', () {
        /// Test Purpose: Verify that missing required fields get sensible defaults
        /// This prevents crashes when loading corrupted or incomplete data
        
        final firestoreData = {
          // name omitted - should default to empty string
          // orderIndex omitted - should default to 0
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          // userId omitted - should default to empty string
        };

        final mockDoc = MockDocumentSnapshot('workout-789', firestoreData);
        final workout = Workout.fromFirestore(mockDoc, 'week-789', 'program-101');

        expect(workout.name, equals(''),
          reason: 'Missing name should default to empty string');
        expect(workout.orderIndex, equals(0),
          reason: 'Missing orderIndex should default to 0');
        expect(workout.userId, equals(''),
          reason: 'Missing userId should default to empty string');
      });
    });

    group('Copy With Method', () {
      test('copyWith creates new workout with updated fields', () {
        /// Test Purpose: Verify that copyWith method works correctly for updates
        /// This method is used when updating existing workouts
        
        final original = _createTestWorkout(
          name: 'Original Name',
          dayOfWeek: 1,
          notes: 'Original notes',
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          dayOfWeek: 5,
          notes: 'Updated notes',
        );

        // Verify updated fields changed
        expect(updated.name, equals('Updated Name'));
        expect(updated.dayOfWeek, equals(5));
        expect(updated.notes, equals('Updated notes'));

        // Verify unchanged fields remained the same
        expect(updated.id, equals(original.id));
        expect(updated.orderIndex, equals(original.orderIndex));
        expect(updated.createdAt, equals(original.createdAt));
        expect(updated.userId, equals(original.userId));
      });

      test('copyWith preserves original values for null parameters', () {
        /// Test Purpose: Verify that copyWith doesn't overwrite fields with null
        /// Only specified fields should be updated, others should remain unchanged
        
        final original = _createTestWorkout(
          name: 'Keep This Name',
          dayOfWeek: 2,
          notes: 'Keep These Notes',
        );

        final updated = original.copyWith(
          orderIndex: 99, // Only update orderIndex
          // name, dayOfWeek, notes not specified - should remain unchanged
        );

        expect(updated.name, equals('Keep This Name'));
        expect(updated.dayOfWeek, equals(2));
        expect(updated.notes, equals('Keep These Notes'));
        expect(updated.orderIndex, equals(99));
      });
    });
  });
}

/// Helper method to create a test workout with minimal required fields
/// Additional fields can be overridden by providing parameters
Workout _createTestWorkout({
  String id = 'test-workout-id',
  String name = 'Test Workout',
  int? dayOfWeek,
  int orderIndex = 1,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
  String userId = 'test-user-id',
  String weekId = 'test-week-id',
  String programId = 'test-program-id',
}) {
  final testDate = createdAt ?? DateTime(2024, 1, 1);
  return Workout(
    id: id,
    name: name,
    dayOfWeek: dayOfWeek,
    orderIndex: orderIndex,
    notes: notes,
    createdAt: testDate,
    updatedAt: updatedAt ?? testDate,
    userId: userId,
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