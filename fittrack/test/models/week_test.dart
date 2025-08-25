import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/models/week.dart';

/// Unit tests for the Week model
/// 
/// These tests verify that the Week model correctly:
/// - Validates week data according to business rules
/// - Serializes to/from Firestore format properly
/// - Handles optional and required fields appropriately
/// - Manages copyWith functionality for updates
/// 
/// If any test fails, it indicates a problem with week data handling
/// that could cause issues when saving/loading weeks from Firestore.
void main() {
  group('Week Model Tests', () {
    late DateTime testDate;
    
    setUp(() {
      // Set up consistent test data
      // Using a fixed date ensures test reproducibility
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    group('Constructor and Basic Properties', () {
      test('creates valid week with required fields only', () {
        /// Test Purpose: Verify that a week can be created with only required fields
        /// This ensures the model works with minimal data, which is important for
        /// cases where users create weeks without optional details
        
        final week = Week(
          id: 'week-123',
          name: 'Week 1',
          order: 1,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          programId: 'program-789',
        );

        // Verify all required fields are set correctly
        expect(week.id, equals('week-123'));
        expect(week.name, equals('Week 1'));
        expect(week.order, equals(1));
        expect(week.createdAt, equals(testDate));
        expect(week.updatedAt, equals(testDate));
        expect(week.userId, equals('user-456'));
        expect(week.programId, equals('program-789'));
        
        // Verify optional fields have correct defaults
        expect(week.notes, isNull, 
          reason: 'notes should be null when not specified');
      });

      test('creates valid week with all fields including optional ones', () {
        /// Test Purpose: Verify that a week can be created with all fields populated
        /// This ensures the model handles the full range of week data correctly
        
        final week = Week(
          id: 'week-123',
          name: 'Foundation Week',
          order: 2,
          notes: 'Focus on proper form and technique',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          programId: 'program-789',
        );

        // Verify all fields including optional ones
        expect(week.notes, equals('Focus on proper form and technique'));
      });
    });

    group('Validation Properties', () {
      test('isValidName returns true for valid week names', () {
        /// Test Purpose: Verify that week name validation works correctly
        /// The name field is critical for user identification of weeks
        
        final validNames = [
          'Week 1',         // Normal name
          'Foundation',     // Single word
          'Week A',         // With letter
          '   Week 2   ',   // With whitespace (should be trimmed)
        ];

        for (final name in validNames) {
          final week = _createTestWeek(name: name);
          expect(week.isValidName, isTrue, 
            reason: 'Name "$name" should be valid');
        }
      });

      test('isValidName returns false for invalid week names', () {
        /// Test Purpose: Verify that invalid week names are properly rejected
        /// This prevents empty names that could cause UI issues
        
        final invalidNames = [
          '',              // Empty string
          '   ',           // Only whitespace
          '\t\n',          // Only whitespace chars
        ];

        for (final name in invalidNames) {
          final week = _createTestWeek(name: name);
          expect(week.isValidName, isFalse, 
            reason: 'Name "$name" should be invalid');
        }
      });

      test('isValidOrder returns true for valid order values', () {
        /// Test Purpose: Verify order validation follows business rules
        /// Order must be positive to maintain proper sequence
        
        final validOrders = [1, 2, 5, 10, 100];

        for (final order in validOrders) {
          final week = _createTestWeek(order: order);
          expect(week.isValidOrder, isTrue, 
            reason: 'Order $order should be valid');
        }
      });

      test('isValidOrder returns false for invalid order values', () {
        /// Test Purpose: Verify that invalid order values are rejected
        /// This prevents negative or zero order values that break sequencing
        
        final invalidOrders = [0, -1, -5, -100];

        for (final order in invalidOrders) {
          final week = _createTestWeek(order: order);
          expect(week.isValidOrder, isFalse, 
            reason: 'Order $order should be invalid (must be positive)');
        }
      });
    });

    group('Firestore Serialization', () {
      test('toFirestore includes all necessary fields', () {
        /// Test Purpose: Verify that week data serializes correctly for Firestore storage
        /// Missing or incorrectly formatted fields could cause database write failures
        
        final week = Week(
          id: 'week-123',
          name: 'Strength Week',
          order: 3,
          notes: 'Focus on compound movements',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          programId: 'program-789',
        );

        final firestoreData = week.toFirestore();

        // Verify all fields are present with correct values
        expect(firestoreData['name'], equals('Strength Week'));
        expect(firestoreData['order'], equals(3));
        expect(firestoreData['notes'], equals('Focus on compound movements'));
        expect(firestoreData['userId'], equals('user-456'));
        expect(firestoreData['programId'], equals('program-789'));
        
        // Verify timestamps are converted to Firestore format
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect((firestoreData['createdAt'] as Timestamp).toDate(), equals(testDate));

        // Verify ID is NOT included (it's a document ID, not a field)
        expect(firestoreData, isNot(contains('id')));
      });

      test('toFirestore handles null notes correctly', () {
        /// Test Purpose: Verify that null optional fields are preserved in Firestore data
        /// Null values should be explicitly included to match Firestore security rules
        
        final week = _createTestWeek(notes: null);
        final firestoreData = week.toFirestore();

        expect(firestoreData['notes'], isNull,
          reason: 'Null notes should be preserved, not omitted');
      });
    });

    group('Firestore Deserialization', () {
      test('fromFirestore creates week from complete Firestore data', () {
        /// Test Purpose: Verify that week data deserializes correctly from Firestore
        /// This ensures data loaded from the database matches what was stored
        
        final firestoreData = {
          'name': 'Power Week',
          'order': 4,
          'notes': 'Heavy compound lifts',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
          'programId': 'program-789',
        };

        // Mock DocumentSnapshot
        final mockDoc = MockDocumentSnapshot('week-123', firestoreData);
        
        final week = Week.fromFirestore(mockDoc, 'program-789');

        expect(week.id, equals('week-123'));
        expect(week.name, equals('Power Week'));
        expect(week.order, equals(4));
        expect(week.notes, equals('Heavy compound lifts'));
        expect(week.createdAt, equals(testDate));
        expect(week.updatedAt, equals(testDate));
        expect(week.userId, equals('user-456'));
        expect(week.programId, equals('program-789'));
      });

      test('fromFirestore handles missing optional fields gracefully', () {
        /// Test Purpose: Verify that missing optional fields default to appropriate values
        /// This ensures backwards compatibility and handles partially populated data
        
        final firestoreData = {
          'name': 'Basic Week',
          'order': 1,
          // notes omitted
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
        };

        final mockDoc = MockDocumentSnapshot('week-456', firestoreData);
        final week = Week.fromFirestore(mockDoc, 'program-789');

        expect(week.notes, isNull,
          reason: 'Missing notes should default to null');
        expect(week.name, equals('Basic Week'),
          reason: 'Present fields should still be loaded correctly');
      });

      test('fromFirestore provides defaults for missing required fields', () {
        /// Test Purpose: Verify that missing required fields get sensible defaults
        /// This prevents crashes when loading corrupted or incomplete data
        
        final firestoreData = {
          // name omitted - should get auto-generated from order
          // order omitted - should default to 1
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          // userId omitted - should default to empty string
        };

        final mockDoc = MockDocumentSnapshot('week-789', firestoreData);
        final week = Week.fromFirestore(mockDoc, 'program-789');

        expect(week.name, equals('Week 1'),
          reason: 'Missing name should default to auto-generated name');
        expect(week.order, equals(1),
          reason: 'Missing order should default to 1');
        expect(week.userId, equals(''),
          reason: 'Missing userId should default to empty string');
        expect(week.programId, equals('program-789'),
          reason: 'programId should be set from parameter when missing');
      });

      test('fromFirestore handles missing programId by using parameter', () {
        /// Test Purpose: Verify that programId parameter is used when field is missing
        /// This ensures proper parent-child relationship even with incomplete data
        
        final firestoreData = {
          'name': 'Test Week',
          'order': 2,
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 'user-456',
          // programId omitted
        };

        final mockDoc = MockDocumentSnapshot('week-test', firestoreData);
        final week = Week.fromFirestore(mockDoc, 'provided-program-id');

        expect(week.programId, equals('provided-program-id'),
          reason: 'Should use programId parameter when field is missing');
      });
    });

    group('Copy With Method', () {
      test('copyWith creates new week with updated fields', () {
        /// Test Purpose: Verify that copyWith method works correctly for updates
        /// This method is used when updating existing weeks
        
        final original = _createTestWeek(
          name: 'Original Name',
          order: 1,
          notes: 'Original notes',
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          order: 2,
          notes: 'Updated notes',
          updatedAt: testDate.add(Duration(hours: 1)),
        );

        // Verify updated fields changed
        expect(updated.name, equals('Updated Name'));
        expect(updated.order, equals(2));
        expect(updated.notes, equals('Updated notes'));
        expect(updated.updatedAt, equals(testDate.add(Duration(hours: 1))));

        // Verify unchanged fields remained the same
        expect(updated.id, equals(original.id));
        expect(updated.createdAt, equals(original.createdAt));
        expect(updated.userId, equals(original.userId));
        expect(updated.programId, equals(original.programId));
      });

      test('copyWith preserves original values for null parameters', () {
        /// Test Purpose: Verify that copyWith doesn't overwrite fields with null
        /// Only specified fields should be updated, others should remain unchanged
        
        final original = _createTestWeek(
          name: 'Keep This Name',
          order: 5,
          notes: 'Keep These Notes',
        );

        final updated = original.copyWith(
          updatedAt: testDate.add(Duration(minutes: 30)),
          // name, order, notes not specified - should remain unchanged
        );

        expect(updated.name, equals('Keep This Name'));
        expect(updated.order, equals(5));
        expect(updated.notes, equals('Keep These Notes'));
        expect(updated.updatedAt, equals(testDate.add(Duration(minutes: 30))));
      });
    });

    group('Week Ordering', () {
      test('weeks can be sorted by order field', () {
        /// Test Purpose: Verify that weeks can be properly ordered
        /// This is important for displaying weeks in correct sequence
        
        final week3 = _createTestWeek(name: 'Week 3', order: 3);
        final week1 = _createTestWeek(name: 'Week 1', order: 1);
        final week2 = _createTestWeek(name: 'Week 2', order: 2);
        
        final weeks = [week3, week1, week2];
        weeks.sort((a, b) => a.order.compareTo(b.order));

        expect(weeks[0].order, equals(1));
        expect(weeks[1].order, equals(2));
        expect(weeks[2].order, equals(3));
        expect(weeks[0].name, equals('Week 1'));
        expect(weeks[1].name, equals('Week 2'));
        expect(weeks[2].name, equals('Week 3'));
      });
    });

    group('Edge Cases', () {
      test('handles very long week names gracefully', () {
        /// Test Purpose: Verify model handles edge cases without crashing
        /// While validation may fail, the model should not throw exceptions
        
        final longName = 'A' * 1000; // Very long name
        final week = _createTestWeek(name: longName);

        expect(week.name, equals(longName));
        expect(week.isValidName, isTrue, 
          reason: 'Long names should still be considered valid by current validation');
      });

      test('handles large order numbers', () {
        /// Test Purpose: Verify model handles large order values
        /// Users might create many weeks in a program
        
        final largeOrder = 999999;
        final week = _createTestWeek(order: largeOrder);

        expect(week.order, equals(largeOrder));
        expect(week.isValidOrder, isTrue,
          reason: 'Large positive orders should be valid');
      });

      test('handles special characters in notes', () {
        /// Test Purpose: Verify model handles various text content
        /// Users might enter emoji, special characters, or formatted text
        
        final specialNotes = 'Week notes with emojis 💪 and symbols: @#\$%^&*()';
        final week = _createTestWeek(notes: specialNotes);

        expect(week.notes, equals(specialNotes));
      });
    });
  });
}

/// Helper method to create a test week with minimal required fields
/// Additional fields can be overridden by providing parameters
Week _createTestWeek({
  String id = 'test-week-id',
  String name = 'Test Week',
  int order = 1,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
  String userId = 'test-user-id',
  String programId = 'test-program-id',
}) {
  final testDate = createdAt ?? DateTime(2024, 1, 1);
  return Week(
    id: id,
    name: name,
    order: order,
    notes: notes,
    createdAt: testDate,
    updatedAt: updatedAt ?? testDate,
    userId: userId,
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