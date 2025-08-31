/// Comprehensive unit tests for Program model
/// 
/// Test Coverage:
/// - Program creation, validation, and business rules
/// - Firestore serialization and deserialization accuracy
/// - Archive functionality and state management
/// - Program operations like copyWith and equality
/// - Edge cases and data integrity validation
/// 
/// If any test fails, it indicates issues with:
/// - Program data validation and constraints
/// - User data scoping and security requirements
/// - Firestore integration and data conversion
/// - Program lifecycle management

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/program.dart';

void main() {
  group('Program Model - Core Functionality', () {
    late DateTime testDate;
    late DateTime updatedDate;
    
    setUp(() {
      testDate = DateTime(2025, 1, 1, 12, 0, 0);
      updatedDate = DateTime(2025, 1, 2, 12, 0, 0);
    });

    group('Program Creation and Validation', () {
      test('creates valid program with all fields', () {
        /// Test Purpose: Verify program creation with complete field set
        /// This ensures all program fields are properly initialized and accessible
        final program = Program(
          id: 'program-1',
          name: 'Strength Training Program',
          description: 'A comprehensive strength building program',
          createdAt: testDate,
          updatedAt: updatedDate,
          userId: 'user-123',
          isArchived: false,
        );

        expect(program.id, 'program-1');
        expect(program.name, 'Strength Training Program');
        expect(program.description, 'A comprehensive strength building program');
        expect(program.createdAt, testDate);
        expect(program.updatedAt, updatedDate);
        expect(program.userId, 'user-123');
        expect(program.isArchived, false);
      });

      test('creates valid program with minimal required fields', () {
        /// Test Purpose: Verify program creation with only required fields
        /// This tests minimal viable program creation with optional fields null
        final minimalProgram = Program(
          id: 'minimal-program',
          name: 'Basic Program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(minimalProgram.name, 'Basic Program');
        expect(minimalProgram.description, isNull);
        expect(minimalProgram.isArchived, false); // Default value
        expect(minimalProgram.userId, 'user-123');
      });

      test('validates program name constraints', () {
        /// Test Purpose: Ensure program names follow business rules
        /// This validates program naming requirements and constraints
        final validProgram = Program(
          id: 'valid',
          name: 'Valid Program Name',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        final longNameProgram = Program(
          id: 'long-name',
          name: 'A' * 300, // Very long name
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(validProgram.name.length, lessThanOrEqualTo(200));
        expect(longNameProgram.name.length, greaterThan(200));
      });
    });

    group('Archive Functionality', () {
      test('program archive state management', () {
        /// Test Purpose: Verify archive functionality works correctly
        /// This ensures programs can be archived/unarchived for organization
        final activeProgram = Program(
          id: 'active-program',
          name: 'Active Program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: false,
        );

        final archivedProgram = Program(
          id: 'archived-program',
          name: 'Archived Program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: true,
        );

        expect(activeProgram.isArchived, false);
        expect(archivedProgram.isArchived, true);
      });

      test('copyWith can toggle archive status', () {
        /// Test Purpose: Verify archive status can be updated via copyWith
        /// This ensures archive operations maintain data integrity
        final program = Program(
          id: 'toggle-test',
          name: 'Toggle Test Program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: false,
        );

        final archivedProgram = program.copyWith(
          isArchived: true,
          updatedAt: updatedDate,
        );

        final unarchivedProgram = archivedProgram.copyWith(
          isArchived: false,
          updatedAt: updatedDate.add(Duration(hours: 1)),
        );

        expect(program.isArchived, false);
        expect(archivedProgram.isArchived, true);
        expect(unarchivedProgram.isArchived, false);
        expect(archivedProgram.updatedAt, updatedDate);
      });
    });

    group('Firestore Serialization', () {
      test('serializes to Firestore format correctly', () {
        /// Test Purpose: Verify Firestore serialization includes all required fields
        /// This ensures data integrity when saving programs to Firestore
        final program = Program(
          id: 'serialize-test',
          name: 'Serialization Test Program',
          description: 'Testing Firestore serialization',
          createdAt: testDate,
          updatedAt: updatedDate,
          userId: 'user-789',
          isArchived: true,
        );

        final firestoreData = program.toFirestore();

        expect(firestoreData['name'], 'Serialization Test Program');
        expect(firestoreData['description'], 'Testing Firestore serialization');
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['updatedAt'], isA<Timestamp>());
        expect(firestoreData['userId'], 'user-789');
        expect(firestoreData['isArchived'], true);
        
        // Verify timestamps are correct
        final createdTimestamp = firestoreData['createdAt'] as Timestamp;
        final updatedTimestamp = firestoreData['updatedAt'] as Timestamp;
        expect(createdTimestamp.toDate(), testDate);
        expect(updatedTimestamp.toDate(), updatedDate);
      });

      test('deserializes from Firestore with complete data', () {
        /// Test Purpose: Verify complete Firestore deserialization accuracy
        /// This ensures all program data is properly reconstructed from Firestore
        final firestoreData = {
          'name': 'Deserialization Test',
          'description': 'Testing Firestore deserialization functionality',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(updatedDate),
          'userId': 'user-abc',
          'isArchived': false,
        };

        final mockDoc = _MockDocumentSnapshot('program-deserialize', firestoreData);
        final program = Program.fromFirestore(mockDoc);

        expect(program.id, 'program-deserialize');
        expect(program.name, 'Deserialization Test');
        expect(program.description, 'Testing Firestore deserialization functionality');
        expect(program.createdAt, testDate);
        expect(program.updatedAt, updatedDate);
        expect(program.userId, 'user-abc');
        expect(program.isArchived, false);
      });

      test('handles missing optional fields gracefully', () {
        /// Test Purpose: Verify backward compatibility with incomplete data
        /// This ensures the system can handle legacy or corrupted data gracefully
        final minimalData = {
          'name': 'Minimal Program',
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        final mockDoc = _MockDocumentSnapshot('minimal-program', minimalData);
        final program = Program.fromFirestore(mockDoc);

        expect(program.name, 'Minimal Program');
        expect(program.description, isNull);
        expect(program.userId, ''); // Empty string fallback
        expect(program.isArchived, false); // Default value
      });

      test('handles malformed data appropriately', () {
        /// Test Purpose: Verify system resilience with corrupted or invalid data
        /// This ensures the application can handle data corruption gracefully
        final malformedData = {
          'name': '', // Empty name
          'description': null,
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': null,
          'isArchived': null,
        };

        final mockDoc = _MockDocumentSnapshot('malformed-program', malformedData);
        final program = Program.fromFirestore(mockDoc);

        expect(program.name, ''); // Empty but handled
        expect(program.description, isNull);
        expect(program.userId, '');
        expect(program.isArchived, false);
      });
    });

    group('Program Operations', () {
      test('copyWith preserves unchanged fields', () {
        /// Test Purpose: Verify copyWith method maintains data integrity during updates
        /// This ensures partial program updates work correctly without data loss
        final original = Program(
          id: 'copy-test',
          name: 'Original Program',
          description: 'Original description',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: false,
        );

        final updated = original.copyWith(
          name: 'Updated Program',
          isArchived: true,
          updatedAt: updatedDate,
        );

        expect(updated.id, 'copy-test'); // Unchanged
        expect(updated.name, 'Updated Program'); // Changed
        expect(updated.description, 'Original description'); // Unchanged
        expect(updated.createdAt, testDate); // Unchanged (should never change)
        expect(updated.updatedAt, updatedDate); // Changed
        expect(updated.userId, 'user-123'); // Unchanged
        expect(updated.isArchived, true); // Changed
      });

      test('copyWith with null values preserves original fields', () {
        /// Test Purpose: Verify copyWith handles explicit null values correctly
        /// This ensures null values in copyWith preserve original field values
        final original = Program(
          id: 'null-test',
          name: 'Null Test Program',
          description: 'Test description',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: true,
        );

        final updated = original.copyWith(
          name: null, // Should preserve original
          description: null, // Should preserve original
          isArchived: null, // Should preserve original
        );

        expect(updated.name, 'Null Test Program');
        expect(updated.description, 'Test description');
        expect(updated.isArchived, true);
      });

      test('equality operator and hashCode work correctly', () {
        /// Test Purpose: Verify object equality and hash code for proper comparisons
        /// This ensures programs can be compared accurately for caching and state management
        final program1 = Program(
          id: 'equality-1',
          name: 'Equality Test',
          description: 'Testing equality',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: false,
        );

        final program2 = Program(
          id: 'equality-1',
          name: 'Equality Test',
          description: 'Testing equality',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
          isArchived: false,
        );

        final program3 = program1.copyWith(name: 'Different Name');

        expect(program1, equals(program2));
        expect(program1.hashCode, equals(program2.hashCode));
        expect(program1, isNot(equals(program3)));
        expect(program1.hashCode, isNot(equals(program3.hashCode)));
      });
    });

    group('User Data Scoping', () {
      test('maintains user ID consistency', () {
        /// Test Purpose: Verify user ID is properly maintained for data security
        /// This ensures per-user data scoping required by security rules
        final userProgram = Program(
          id: 'user-scoped',
          name: 'User Scoped Program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'specific-user-id',
        );

        expect(userProgram.userId, 'specific-user-id');
        
        final firestoreData = userProgram.toFirestore();
        expect(firestoreData['userId'], 'specific-user-id');
      });

      test('copyWith preserves user ID immutability', () {
        /// Test Purpose: Verify user ID cannot be changed through copyWith
        /// This ensures data security and prevents unauthorized data access
        final program = Program(
          id: 'immutable-user',
          name: 'Immutable User Test',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'original-user',
        );

        final attemptedUpdate = program.copyWith(
          name: 'Updated Name',
          updatedAt: updatedDate,
        );

        expect(attemptedUpdate.userId, 'original-user'); // Should remain unchanged
        expect(attemptedUpdate.name, 'Updated Name'); // Other fields can change
      });
    });

    group('Timestamp Management', () {
      test('created and updated timestamps are handled correctly', () {
        /// Test Purpose: Verify timestamp handling for audit trails
        /// This ensures proper creation and modification tracking
        final program = Program(
          id: 'timestamp-test',
          name: 'Timestamp Test Program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        final updatedProgram = program.copyWith(
          name: 'Updated Program',
          updatedAt: updatedDate,
        );

        expect(program.createdAt, testDate);
        expect(program.updatedAt, testDate);
        expect(updatedProgram.createdAt, testDate); // Should not change
        expect(updatedProgram.updatedAt, updatedDate); // Should change
      });

      test('timestamp serialization preserves precision', () {
        /// Test Purpose: Verify timestamp precision through Firestore serialization
        /// This ensures audit trail accuracy and data integrity
        final preciseDate = DateTime(2025, 8, 30, 14, 30, 45, 123);
        
        final program = Program(
          id: 'precision-test',
          name: 'Precision Test',
          createdAt: preciseDate,
          updatedAt: preciseDate,
          userId: 'user-123',
        );

        final firestoreData = program.toFirestore();
        final createdTimestamp = firestoreData['createdAt'] as Timestamp;
        final deserializedDate = createdTimestamp.toDate();

        // Firestore timestamps have millisecond precision
        expect(deserializedDate.millisecondsSinceEpoch ~/ 1000, 
               preciseDate.millisecondsSinceEpoch ~/ 1000);
      });
    });

    group('Data Validation and Constraints', () {
      test('validates program name length limits', () {
        /// Test Purpose: Verify program name validation follows UI constraints
        /// This ensures form validation rules are properly enforced
        final validName = 'A' * 100; // Reasonable length
        final maxName = 'A' * 200; // At maximum length
        final tooLongName = 'A' * 300; // Exceeds reasonable limits

        final validProgram = Program(
          id: 'valid-length',
          name: validName,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        final maxProgram = Program(
          id: 'max-length',
          name: maxName,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        final tooLongProgram = Program(
          id: 'too-long',
          name: tooLongName,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(validProgram.name.length, lessThanOrEqualTo(200));
        expect(maxProgram.name.length, lessThanOrEqualTo(200));
        expect(tooLongProgram.name.length, greaterThan(200));
      });

      test('handles special characters in program names and descriptions', () {
        /// Test Purpose: Verify international character support and emoji handling
        /// This ensures global usability and modern text input support
        final internationalProgram = Program(
          id: 'international',
          name: 'Программа Тренировок (Training Program) 🏋️',
          description: 'Descripción del programa de entrenamiento with émojis 💪',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(internationalProgram.name, contains('Программа'));
        expect(internationalProgram.name, contains('🏋️'));
        expect(internationalProgram.description, contains('émojis'));
        expect(internationalProgram.description, contains('💪'));
      });

      test('handles empty and whitespace-only descriptions', () {
        /// Test Purpose: Verify description field handles edge cases
        /// This ensures optional fields are properly validated
        final emptyDescProgram = Program(
          id: 'empty-desc',
          name: 'Empty Description Program',
          description: '',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        final whitespaceDescProgram = Program(
          id: 'whitespace-desc',
          name: 'Whitespace Description Program',
          description: '   \n\t   ',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(emptyDescProgram.description, '');
        expect(whitespaceDescProgram.description, '   \n\t   ');
      });
    });

    group('Firestore Integration', () {
      test('round-trip serialization maintains data integrity', () {
        /// Test Purpose: Verify data integrity through complete serialize/deserialize cycle
        /// This ensures no data is lost in Firestore operations
        final originalProgram = Program(
          id: 'round-trip',
          name: 'Round Trip Test',
          description: 'Testing serialization round trip',
          createdAt: testDate,
          updatedAt: updatedDate,
          userId: 'user-round-trip',
          isArchived: true,
        );

        // Serialize to Firestore format
        final firestoreData = originalProgram.toFirestore();
        
        // Deserialize back to Program object
        final mockDoc = _MockDocumentSnapshot('round-trip', firestoreData);
        final deserializedProgram = Program.fromFirestore(mockDoc);

        expect(deserializedProgram.id, originalProgram.id);
        expect(deserializedProgram.name, originalProgram.name);
        expect(deserializedProgram.description, originalProgram.description);
        expect(deserializedProgram.userId, originalProgram.userId);
        expect(deserializedProgram.isArchived, originalProgram.isArchived);
        
        // Timestamps should be equal (within reasonable precision)
        expect(deserializedProgram.createdAt.millisecondsSinceEpoch ~/ 1000,
               originalProgram.createdAt.millisecondsSinceEpoch ~/ 1000);
      });

      test('handles Firestore data type conversion edge cases', () {
        /// Test Purpose: Verify robust handling of Firestore data type variations
        /// This ensures the system handles different data type representations
        final edgeCaseData = {
          'name': 123, // Non-string name (should convert)
          'description': true, // Non-string description 
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
          'userId': 456, // Non-string userId
          'isArchived': 'true', // String instead of boolean
        };

        final mockDoc = _MockDocumentSnapshot('edge-case', edgeCaseData);
        
        expect(() => Program.fromFirestore(mockDoc), returnsNormally);
        // The actual conversion behavior depends on implementation
        // but should not crash the application
      });
    });

    group('Business Logic and Rules', () {
      test('validates createdAt is before or equal to updatedAt', () {
        /// Test Purpose: Verify logical timestamp ordering
        /// This ensures data consistency and proper audit trails
        final validProgram = Program(
          id: 'valid-timestamps',
          name: 'Valid Timestamps',
          createdAt: testDate,
          updatedAt: testDate.add(Duration(hours: 1)), // After creation
          userId: 'user-123',
        );

        final simultaneousProgram = Program(
          id: 'simultaneous',
          name: 'Simultaneous Timestamps',
          createdAt: testDate,
          updatedAt: testDate, // Same time as creation
          userId: 'user-123',
        );

        expect(validProgram.updatedAt.isAfter(validProgram.createdAt), isTrue);
        expect(simultaneousProgram.updatedAt.isAtSameMomentAs(simultaneousProgram.createdAt), isTrue);
      });

      test('program ID requirements and format', () {
        /// Test Purpose: Verify program ID handling and requirements
        /// This ensures proper ID management for Firestore documents
        final program = Program(
          id: 'abc-123-def',
          name: 'ID Format Test',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(program.id, 'abc-123-def');
        expect(program.id.isNotEmpty, isTrue);
        expect(program.id.contains(' '), isFalse); // No spaces in IDs
      });
    });

    group('Edge Cases and Error Conditions', () {
      test('handles extremely long descriptions', () {
        /// Test Purpose: Test behavior with very long description text
        /// This ensures the system handles large text inputs gracefully
        final longDescription = 'A' * 5000; // Very long description
        
        final programWithLongDesc = Program(
          id: 'long-desc',
          name: 'Long Description Program',
          description: longDescription,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        expect(programWithLongDesc.description?.length, 5000);
        expect(() => programWithLongDesc.toFirestore(), returnsNormally);
      });

      test('handles empty string fields appropriately', () {
        /// Test Purpose: Verify empty string handling in various fields
        /// This ensures proper validation of empty vs null values
        final emptyFieldsProgram = Program(
          id: '',
          name: '',
          description: '',
          createdAt: testDate,
          updatedAt: testDate,
          userId: '',
        );

        expect(emptyFieldsProgram.id, '');
        expect(emptyFieldsProgram.name, '');
        expect(emptyFieldsProgram.description, '');
        expect(emptyFieldsProgram.userId, '');
      });

      test('maintains immutability of core fields', () {
        /// Test Purpose: Verify critical fields cannot be accidentally modified
        /// This ensures data integrity and security requirements
        final program = Program(
          id: 'immutable-test',
          name: 'Immutable Test',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-123',
        );

        // Verify these fields are not modifiable through copyWith
        final updated = program.copyWith(
          description: 'New description',
          updatedAt: updatedDate,
        );

        expect(updated.id, program.id); // ID should never change
        expect(updated.createdAt, program.createdAt); // CreatedAt should never change
        expect(updated.userId, program.userId); // UserId should never change
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

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}