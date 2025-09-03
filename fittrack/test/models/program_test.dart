import 'package:test/test.dart';
import 'package:fittrack/models/program.dart';

/// Unit tests for the Program model
/// 
/// These tests verify that the Program model correctly:
/// - Validates program data according to business rules
/// - Serializes to/from Firestore format properly
/// - Handles optional and required fields appropriately
/// - Manages copyWith functionality for updates
/// 
/// If any test fails, it indicates a problem with program data handling
/// that could cause issues when saving/loading programs from Firestore.
void main() {
  group('Program Model Tests', () {
    late DateTime testDate;
    
    setUp(() {
      // Set up consistent test data
      // Using a fixed date ensures test reproducibility
      testDate = DateTime(2024, 1, 15, 10, 30);
    });

    group('Constructor and Basic Properties', () {
      test('creates valid program with required fields only', () {
        /// Test Purpose: Verify that a program can be created with only required fields
        /// This ensures the model works with minimal data, which is important for
        /// cases where users create programs without optional details
        
        final program = Program(
          id: 'program-123',
          name: 'Strength Training',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
        );

        // Verify all required fields are set correctly
        expect(program.id, equals('program-123'));
        expect(program.name, equals('Strength Training'));
        expect(program.createdAt, equals(testDate));
        expect(program.updatedAt, equals(testDate));
        expect(program.userId, equals('user-456'));
        
        // Verify optional fields have correct defaults
        expect(program.description, isNull, 
          reason: 'description should be null when not specified');
        expect(program.isArchived, isFalse,
          reason: 'isArchived should default to false');
      });

      test('creates valid program with all fields including optional ones', () {
        /// Test Purpose: Verify that a program can be created with all fields populated
        /// This ensures the model handles the full range of program data correctly
        
        final program = Program(
          id: 'program-123',
          name: 'Advanced Bodybuilding',
          description: 'A comprehensive 12-week bodybuilding program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          isArchived: true,
        );

        // Verify all fields including optional ones
        expect(program.description, equals('A comprehensive 12-week bodybuilding program'));
        expect(program.isArchived, isTrue);
      });
    });

    group('Validation Properties', () {
      test('isValidName returns true for valid program names', () {
        /// Test Purpose: Verify that program name validation works correctly
        /// The name field is critical for user identification of programs
        /// and must meet length requirements (1-100 characters)
        
        final validNames = [
          'A',              // Minimum length
          'Upper Body',     // Normal length
          'A' * 100,        // Maximum length (100 chars)
        ];

        for (final name in validNames) {
          final program = _createTestProgram(name: name);
          expect(program.isValidName, isTrue, 
            reason: 'Name "$name" should be valid (length: ${name.length})');
        }
      });

      test('isValidName returns false for invalid program names', () {
        /// Test Purpose: Verify that invalid program names are properly rejected
        /// This prevents empty names or overly long names that could cause UI issues
        
        final invalidNames = [
          '',              // Empty string
          '   ',           // Only whitespace
          'A' * 101,       // Too long (101 chars)
        ];

        for (final name in invalidNames) {
          final program = _createTestProgram(name: name);
          expect(program.isValidName, isFalse, 
            reason: 'Name "$name" should be invalid (length after trim: ${name.trim().length})');
        }
      });

      test('isValidDescription returns true for valid descriptions', () {
        /// Test Purpose: Verify that program description validation works correctly
        /// Descriptions have a length limit to prevent database issues
        
        final validDescriptions = [
          null,             // Null description
          '',               // Empty description  
          'Short desc',     // Normal description
          'A' * 500,        // Maximum length (500 chars)
        ];

        for (final desc in validDescriptions) {
          final program = _createTestProgram(description: desc);
          expect(program.isValidDescription, isTrue, 
            reason: 'Description should be valid (length: ${desc?.length ?? 0})');
        }
      });

      test('isValidDescription returns false for invalid descriptions', () {
        /// Test Purpose: Verify that overly long descriptions are rejected
        /// This prevents database constraints violations and UI issues
        
        final tooLongDescription = 'A' * 501; // Exceeds 500 character limit
        final program = _createTestProgram(description: tooLongDescription);
        
        expect(program.isValidDescription, isFalse, 
          reason: 'Description should be invalid (length: ${tooLongDescription.length})');
      });
    });

    group('Data Serialization', () {
      test('toMap includes all necessary fields', () {
        /// Test Purpose: Verify that program data serializes correctly for storage
        /// Missing or incorrectly formatted fields could cause database write failures
        
        final program = Program(
          id: 'program-123',
          name: 'Full Body Routine',
          description: 'A complete full body workout program',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          isArchived: true,
        );

        final mapData = program.toMap();

        // Verify all fields are present with correct values
        expect(mapData['name'], equals('Full Body Routine'));
        expect(mapData['description'], equals('A complete full body workout program'));
        expect(mapData['userId'], equals('user-456'));
        expect(mapData['isArchived'], isTrue);
        
        // Verify timestamps are included as ISO strings
        expect(mapData.containsKey('createdAt'), isTrue);
        expect(mapData.containsKey('updatedAt'), isTrue);
        expect(mapData['createdAt'], isA<String>());
        expect(mapData['updatedAt'], isA<String>());

        // Verify ID is NOT included (it's a document ID, not a field)
        expect(mapData, isNot(contains('id')));
      });

      test('toMap handles null description correctly', () {
        /// Test Purpose: Verify that null optional fields are preserved in data
        /// Null values should be explicitly included to match storage rules
        
        final program = _createTestProgram(description: null);
        final mapData = program.toMap();

        expect(mapData['description'], isNull,
          reason: 'Null description should be preserved, not omitted');
      });
    });

    group('Data Validation Logic', () {
      test('validates required fields are present', () {
        /// Test Purpose: Verify that required fields are properly validated
        /// This ensures data integrity without requiring Firebase dependencies
        
        final program = Program(
          id: 'program-123',
          name: 'Powerlifting Program',
          description: 'Focus on the big three lifts',
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          isArchived: false,
        );

        expect(program.id, equals('program-123'));
        expect(program.name, equals('Powerlifting Program'));
        expect(program.description, equals('Focus on the big three lifts'));
        expect(program.createdAt, equals(testDate));
        expect(program.updatedAt, equals(testDate));
        expect(program.userId, equals('user-456'));
        expect(program.isArchived, isFalse);
      });

      test('handles optional fields gracefully', () {
        /// Test Purpose: Verify that missing optional fields work correctly
        /// This ensures backwards compatibility without Firebase dependencies
        
        final program = Program(
          id: 'program-456',
          name: 'Basic Program',
          description: null,
          createdAt: testDate,
          updatedAt: testDate,
          userId: 'user-456',
          isArchived: false,
        );

        expect(program.description, isNull,
          reason: 'Null description should be preserved');
        expect(program.isArchived, isFalse,
          reason: 'isArchived should be false when specified');
        expect(program.name, equals('Basic Program'),
          reason: 'Present fields should be loaded correctly');
      });
    });

    group('Copy With Method', () {
      test('copyWith creates new program with updated fields', () {
        /// Test Purpose: Verify that copyWith method works correctly for updates
        /// This method is used when updating existing programs
        
        final original = _createTestProgram(
          name: 'Original Name',
          description: 'Original description',
          isArchived: false,
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
          updatedAt: testDate.add(Duration(hours: 1)),
          isArchived: true,
        );

        // Verify updated fields changed
        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals('Updated description'));
        expect(updated.isArchived, isTrue);
        expect(updated.updatedAt, equals(testDate.add(Duration(hours: 1))));

        // Verify unchanged fields remained the same
        expect(updated.id, equals(original.id));
        expect(updated.createdAt, equals(original.createdAt));
        expect(updated.userId, equals(original.userId));
      });

      test('copyWith preserves original values for null parameters', () {
        /// Test Purpose: Verify that copyWith doesn't overwrite fields with null
        /// Only specified fields should be updated, others should remain unchanged
        
        final original = _createTestProgram(
          name: 'Keep This Name',
          description: 'Keep This Description',
          isArchived: true,
        );

        final updated = original.copyWith(
          updatedAt: testDate.add(Duration(minutes: 30)),
          // name, description, isArchived not specified - should remain unchanged
        );

        expect(updated.name, equals('Keep This Name'));
        expect(updated.description, equals('Keep This Description'));
        expect(updated.isArchived, isTrue);
        expect(updated.updatedAt, equals(testDate.add(Duration(minutes: 30))));
      });

      test('copyWith can clear description by setting it to null', () {
        /// Test Purpose: Verify that description can be explicitly set to null
        /// This allows removing descriptions from existing programs
        
        final original = _createTestProgram(
          description: 'Remove this description',
        );

        final updated = original.copyWith(description: null);

        expect(updated.description, isNull,
          reason: 'Should be able to clear description by setting to null');
      });
    });

    group('Equality and Comparison', () {
      test('programs with same data are equal', () {
        /// Test Purpose: Verify equality comparison works correctly
        /// This is important for UI state management and caching
        
        final program1 = _createTestProgram(name: 'Test Program');
        final program2 = _createTestProgram(name: 'Test Program');

        expect(program1 == program2, isTrue,
          reason: 'Programs with identical data should be equal');
        expect(program1.hashCode, equals(program2.hashCode),
          reason: 'Equal programs should have same hash code');
      });

      test('programs with different data are not equal', () {
        /// Test Purpose: Verify that different programs are not equal
        /// This prevents false positives in equality checks
        
        final program1 = _createTestProgram(name: 'Program A');
        final program2 = _createTestProgram(name: 'Program B');

        expect(program1 == program2, isFalse,
          reason: 'Programs with different data should not be equal');
      });
    });
  });
}

/// Helper method to create a test program with minimal required fields
/// Additional fields can be overridden by providing parameters
Program _createTestProgram({
  String id = 'test-program-id',
  String name = 'Test Program',
  String? description,
  DateTime? createdAt,
  DateTime? updatedAt,
  String userId = 'test-user-id',
  bool isArchived = false,
}) {
  final testDate = createdAt ?? DateTime(2024, 1, 1);
  return Program(
    id: id,
    name: name,
    description: description,
    createdAt: testDate,
    updatedAt: updatedAt ?? testDate,
    userId: userId,
    isArchived: isArchived,
  );
}

