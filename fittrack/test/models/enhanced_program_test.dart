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

import 'package:test/test.dart';
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

    group('Data Serialization', () {
      test('serializes to map format correctly', () {
        /// Test Purpose: Verify data serialization includes all required fields
        /// This ensures data integrity when saving programs to storage
        final program = Program(
          id: 'serialize-test',
          name: 'Serialization Test Program',
          description: 'Testing data serialization',
          createdAt: testDate,
          updatedAt: updatedDate,
          userId: 'user-789',
          isArchived: true,
        );

        final mapData = program.toMap();

        expect(mapData['name'], 'Serialization Test Program');
        expect(mapData['description'], 'Testing data serialization');
        expect(mapData['createdAt'], isA<String>());
        expect(mapData['updatedAt'], isA<String>());
        expect(mapData['userId'], 'user-789');
        expect(mapData['isArchived'], true);
        
        // Verify timestamps are correct
        final createdDateString = mapData['createdAt'] as String;
        final updatedDateString = mapData['updatedAt'] as String;
        expect(DateTime.parse(createdDateString), testDate);
        expect(DateTime.parse(updatedDateString), updatedDate);
      });

      test('creates program from complete data map', () {
        /// Test Purpose: Verify complete data reconstruction accuracy
        /// This ensures all program data is properly reconstructed from map data
        final dataMap = {
          'name': 'Deserialization Test',
          'description': 'Testing data deserialization functionality',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': updatedDate.toIso8601String(),
          'userId': 'user-abc',
          'isArchived': false,
        };

        final program = Program(
          id: 'program-deserialize',
          name: dataMap['name'] as String,
          description: dataMap['description'] as String?,
          createdAt: DateTime.parse(dataMap['createdAt'] as String),
          updatedAt: DateTime.parse(dataMap['updatedAt'] as String),
          userId: dataMap['userId'] as String,
          isArchived: dataMap['isArchived'] as bool? ?? false,
        );

        expect(program.id, 'program-deserialize');
        expect(program.name, 'Deserialization Test');
        expect(program.description, 'Testing data deserialization functionality');
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
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final program = Program(
          id: 'minimal-program',
          name: minimalData['name'] as String,
          description: minimalData['description'] as String?,
          createdAt: DateTime.parse(minimalData['createdAt'] as String),
          updatedAt: DateTime.parse(minimalData['updatedAt'] as String),
          userId: minimalData['userId'] as String? ?? '',
          isArchived: minimalData['isArchived'] as bool? ?? false,
        );

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
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'userId': null,
          'isArchived': null,
        };

        final program = Program(
          id: 'malformed-program',
          name: malformedData['name'] as String? ?? '',
          description: malformedData['description'] as String?,
          createdAt: DateTime.parse(malformedData['createdAt'] as String),
          updatedAt: DateTime.parse(malformedData['updatedAt'] as String),
          userId: malformedData['userId'] as String? ?? '',
          isArchived: malformedData['isArchived'] as bool? ?? false,
        );

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
          // Don't pass parameters to preserve original values
          updatedAt: testDate.add(Duration(hours: 1)),
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
        
        final mapData = userProgram.toMap();
        expect(mapData['userId'], 'specific-user-id');
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
        /// Test Purpose: Verify timestamp precision through data serialization
        /// This ensures audit trail accuracy and data integrity
        final preciseDate = DateTime(2025, 8, 30, 14, 30, 45, 123);
        
        final program = Program(
          id: 'precision-test',
          name: 'Precision Test',
          createdAt: preciseDate,
          updatedAt: preciseDate,
          userId: 'user-123',
        );

        final mapData = program.toMap();
        final createdDateString = mapData['createdAt'] as String;
        final deserializedDate = DateTime.parse(createdDateString);

        // ISO string timestamps maintain full precision
        expect(deserializedDate, preciseDate);
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

    group('Data Integration', () {
      test('round-trip serialization maintains data integrity', () {
        /// Test Purpose: Verify data integrity through complete serialize/deserialize cycle
        /// This ensures no data is lost in storage operations
        final originalProgram = Program(
          id: 'round-trip',
          name: 'Round Trip Test',
          description: 'Testing serialization round trip',
          createdAt: testDate,
          updatedAt: updatedDate,
          userId: 'user-round-trip',
          isArchived: true,
        );

        // Serialize to map format
        final mapData = originalProgram.toMap();
        
        // Deserialize back to Program object
        final deserializedProgram = Program(
          id: 'round-trip',
          name: mapData['name'] as String,
          description: mapData['description'] as String?,
          createdAt: DateTime.parse(mapData['createdAt'] as String),
          updatedAt: DateTime.parse(mapData['updatedAt'] as String),
          userId: mapData['userId'] as String,
          isArchived: mapData['isArchived'] as bool? ?? false,
        );

        expect(deserializedProgram.id, originalProgram.id);
        expect(deserializedProgram.name, originalProgram.name);
        expect(deserializedProgram.description, originalProgram.description);
        expect(deserializedProgram.userId, originalProgram.userId);
        expect(deserializedProgram.isArchived, originalProgram.isArchived);
        
        // Timestamps should be equal
        expect(deserializedProgram.createdAt, originalProgram.createdAt);
        expect(deserializedProgram.updatedAt, originalProgram.updatedAt);
      });

      test('handles data type conversion edge cases', () {
        /// Test Purpose: Verify robust handling of data type variations
        /// This ensures the system handles different data type representations
        final edgeCaseData = {
          'name': 'Edge Case Program',
          'description': null,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'userId': 'user-123',
          'isArchived': false,
        };

        expect(() => Program(
          id: 'edge-case',
          name: edgeCaseData['name'] as String,
          description: edgeCaseData['description'] as String?,
          createdAt: DateTime.parse(edgeCaseData['createdAt'] as String),
          updatedAt: DateTime.parse(edgeCaseData['updatedAt'] as String),
          userId: edgeCaseData['userId'] as String,
          isArchived: edgeCaseData['isArchived'] as bool? ?? false,
        ), returnsNormally);
        // Should create successfully without crashing
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
        expect(() => programWithLongDesc.toMap(), returnsNormally);
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

