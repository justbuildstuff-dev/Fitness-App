import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/utils/smart_copy_naming.dart';

/// Unit tests for week duplication logic with smart naming integration
///
/// These tests verify that the smart naming algorithm works correctly
/// when integrated with week duplication workflows. They test the logic
/// that will be used in FirestoreService.duplicateWeek().
///
/// Related files:
/// - lib/utils/smart_copy_naming.dart - Smart naming utility
/// - lib/services/firestore_service.dart - Week duplication implementation
/// - test/utils/smart_copy_naming_test.dart - Comprehensive SmartCopyNaming tests
void main() {
  group('Week Duplication Smart Naming Integration', () {
    group('Basic Duplication Scenarios', () {
      test('first duplication of a week generates "Copy 1"', () {
        // Simulate duplicating "Week 1" with no existing copies
        const weekName = 'Week 1';
        final existingWeekNames = ['Week 1']; // Original week

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 1');
      });

      test('second duplication generates "Copy 2"', () {
        // Simulate duplicating "Week 1" when "Week 1 Copy 1" exists
        const weekName = 'Week 1';
        final existingWeekNames = ['Week 1', 'Week 1 Copy 1'];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 2');
      });

      test('third duplication generates "Copy 3"', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          'Week 1 Copy 2',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 3');
      });
    });

    group('Duplicating Copies', () {
      test('duplicating "Copy 1" generates "Copy 2" when Copy 2 does not exist', () {
        // User duplicates "Week 1 Copy 1"
        const weekName = 'Week 1 Copy 1';
        final existingWeekNames = ['Week 1', 'Week 1 Copy 1'];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 2');
      });

      test('duplicating "Copy 2" generates "Copy 3" when Copy 3 does not exist', () {
        const weekName = 'Week 1 Copy 2';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          'Week 1 Copy 2',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 3');
      });

      test('duplicating "Copy 5" fills gap at "Copy 2"', () {
        const weekName = 'Week 1 Copy 5';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          'Week 1 Copy 5', // Source week
          // Gap at Copy 2, 3, 4
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 2'); // Fills lowest gap
      });
    });

    group('Gap Filling', () {
      test('fills gap when "Copy 2" is deleted', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          // Gap at Copy 2 (was deleted)
          'Week 1 Copy 3',
          'Week 1 Copy 4',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 2');
      });

      test('fills lowest gap when multiple gaps exist', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          // Gap at Copy 2
          'Week 1 Copy 3',
          // Gap at Copy 4
          'Week 1 Copy 5',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 2'); // Lowest gap
      });

      test('uses next number when no gaps exist', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          'Week 1 Copy 2',
          'Week 1 Copy 3',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 4');
      });
    });

    group('Custom Week Names', () {
      test('duplicates custom week name "Upper Body"', () {
        const weekName = 'Upper Body';
        final existingWeekNames = ['Upper Body'];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Upper Body Copy 1');
      });

      test('increments custom week name copies correctly', () {
        const weekName = 'Upper Body';
        final existingWeekNames = [
          'Upper Body',
          'Upper Body Copy 1',
          'Upper Body Copy 2',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Upper Body Copy 3');
      });

      test('handles week names with special characters', () {
        const weekName = 'Week #1 - Push Day';
        final existingWeekNames = ['Week #1 - Push Day'];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week #1 - Push Day Copy 1');
      });
    });

    group('Multi-Program Isolation', () {
      test('ignores copies from other weeks with different names', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1',
          'Week 2 Copy 1', // Different week
          'Week 2 Copy 2', // Different week
          'Upper Body Copy 1', // Different week
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        // Should generate Copy 1 (not affected by other week names)
        expect(duplicatedName, 'Week 1 Copy 1');
      });

      test('correctly handles multiple weeks with copies in same program', () {
        const weekName = 'Week 2';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 1',
          'Week 1 Copy 2',
          'Week 2',
          'Week 2 Copy 1', // Week 2's first copy
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        // Should generate Week 2 Copy 2 (ignores Week 1 copies)
        expect(duplicatedName, 'Week 2 Copy 2');
      });
    });

    group('Edge Cases', () {
      test('handles empty existing names list', () {
        const weekName = 'Week 1';
        final existingWeekNames = <String>[];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 1');
      });

      test('handles very long week names', () {
        const weekName = 'This is a very long week name for a custom program';
        final existingWeekNames = [weekName];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(
          duplicatedName,
          'This is a very long week name for a custom program Copy 1',
        );
      });

      test('handles large copy numbers', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1',
          'Week 1 Copy 98',
          'Week 1 Copy 99',
          'Week 1 Copy 100',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 101');
      });

      test('handles unsorted existing copy numbers', () {
        const weekName = 'Week 1';
        final existingWeekNames = [
          'Week 1 Copy 5',
          'Week 1',
          'Week 1 Copy 1',
          'Week 1 Copy 3',
        ];

        final duplicatedName = SmartCopyNaming.generateCopyName(
          weekName,
          existingWeekNames,
        );

        expect(duplicatedName, 'Week 1 Copy 2'); // Fills gap at 2
      });
    });

    group('Real-World Workflow Scenarios', () {
      test('scenario: create, duplicate, duplicate again', () {
        var existingNames = ['Week 1'];

        // First duplication
        var name1 = SmartCopyNaming.generateCopyName('Week 1', existingNames);
        expect(name1, 'Week 1 Copy 1');
        existingNames.add(name1);

        // Second duplication
        var name2 = SmartCopyNaming.generateCopyName('Week 1', existingNames);
        expect(name2, 'Week 1 Copy 2');
        existingNames.add(name2);

        // Third duplication
        var name3 = SmartCopyNaming.generateCopyName('Week 1', existingNames);
        expect(name3, 'Week 1 Copy 3');
      });

      test('scenario: create, duplicate, delete copy, duplicate again', () {
        var existingNames = ['Week 1', 'Week 1 Copy 1', 'Week 1 Copy 2'];

        // User deletes "Week 1 Copy 1"
        existingNames.remove('Week 1 Copy 1');

        // Next duplication fills the gap
        var name = SmartCopyNaming.generateCopyName('Week 1', existingNames);
        expect(name, 'Week 1 Copy 1'); // Fills gap
      });

      test('scenario: duplicate a copy multiple times', () {
        var existingNames = ['Week 1', 'Week 1 Copy 1'];

        // Duplicate "Week 1 Copy 1"
        var name1 = SmartCopyNaming.generateCopyName('Week 1 Copy 1', existingNames);
        expect(name1, 'Week 1 Copy 2');
        existingNames.add(name1);

        // Duplicate "Week 1 Copy 1" again
        var name2 = SmartCopyNaming.generateCopyName('Week 1 Copy 1', existingNames);
        expect(name2, 'Week 1 Copy 3');
        existingNames.add(name2);

        // Duplicate "Week 1 Copy 2"
        var name3 = SmartCopyNaming.generateCopyName('Week 1 Copy 2', existingNames);
        expect(name3, 'Week 1 Copy 4');
      });

      test('scenario: mixed operations with different week names', () {
        var existingNames = [
          'Week 1',
          'Week 1 Copy 1',
          'Upper Body',
          'Upper Body Copy 1',
        ];

        // Duplicate "Week 1"
        var weekCopy = SmartCopyNaming.generateCopyName('Week 1', existingNames);
        expect(weekCopy, 'Week 1 Copy 2');

        // Duplicate "Upper Body"
        var upperBodyCopy = SmartCopyNaming.generateCopyName('Upper Body', existingNames);
        expect(upperBodyCopy, 'Upper Body Copy 2');

        // Names don't interfere with each other
        existingNames.add(weekCopy);
        existingNames.add(upperBodyCopy);

        expect(existingNames, containsAll([
          'Week 1 Copy 2',
          'Upper Body Copy 2',
        ]));
      });
    });
  });
}
