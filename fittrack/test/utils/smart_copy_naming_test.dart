import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/utils/smart_copy_naming.dart';

void main() {
  group('SmartCopyNaming', () {
    group('generateCopyName', () {
      test('returns "Copy 1" for first duplicate with no existing copies', () {
        const sourceName = 'Week 1';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 1');
      });

      test('returns "Copy 2" when "Copy 1" exists', () {
        const sourceName = 'Week 1';
        final existingNames = ['Week 1 Copy 1'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 2');
      });

      test('returns "Copy 3" when "Copy 1" and "Copy 2" exist', () {
        const sourceName = 'Week 1';
        final existingNames = ['Week 1 Copy 1', 'Week 1 Copy 2'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 3');
      });

      test('fills gap in numbering sequence', () {
        const sourceName = 'Week 1';
        final existingNames = ['Week 1 Copy 1', 'Week 1 Copy 3', 'Week 1 Copy 4'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 2'); // Fills the gap at 2
      });

      test('fills lowest gap when multiple gaps exist', () {
        const sourceName = 'Week 1';
        final existingNames = ['Week 1 Copy 1', 'Week 1 Copy 3', 'Week 1 Copy 5'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 2'); // Fills lowest gap
      });

      test('extracts base name when duplicating a copy', () {
        const sourceName = 'Week 1 Copy 1';
        final existingNames = ['Week 1 Copy 2'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 3');
      });

      test('extracts base name from "Copy 5" and increments correctly', () {
        const sourceName = 'Week 1 Copy 5';
        final existingNames = ['Week 1 Copy 1', 'Week 1 Copy 2'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 3'); // Fills gap at 3
      });

      test('works with custom week names', () {
        const sourceName = 'Upper Body';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Upper Body Copy 1');
      });

      test('increments custom names correctly', () {
        const sourceName = 'Upper Body';
        final existingNames = ['Upper Body Copy 1', 'Upper Body Copy 2'];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Upper Body Copy 3');
      });

      test('handles empty source name', () {
        const sourceName = '';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, ' Copy 1');
      });

      test('handles source name with special characters', () {
        const sourceName = 'Week #1 - Push';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week #1 - Push Copy 1');
      });

      test('ignores names with different base names', () {
        const sourceName = 'Week 1';
        final existingNames = [
          'Week 2 Copy 1',
          'Week 2 Copy 2',
          'Different Name Copy 1',
        ];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 1'); // Not affected by other base names
      });

      test('handles unsorted existing copy numbers', () {
        const sourceName = 'Week 1';
        final existingNames = [
          'Week 1 Copy 5',
          'Week 1 Copy 1',
          'Week 1 Copy 3',
        ];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 2'); // Fills gap at 2
      });

      test('handles large copy numbers', () {
        const sourceName = 'Week 1';
        final existingNames = [
          'Week 1 Copy 99',
          'Week 1 Copy 100',
        ];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 101');
      });

      test('handles names that partially match but are not copies', () {
        const sourceName = 'Week 1';
        final existingNames = [
          'Week 1 Copy 1',
          'Week 1 - Modified', // Not a copy pattern
          'Week 1 Copy', // Missing number
          'Week 1 (Copy)', // Wrong format
        ];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 2'); // Only counts valid "Copy 1"
      });

      test('handles names with multiple spaces in "Copy N"', () {
        const sourceName = 'Week 1';
        final existingNames = [
          'Week 1  Copy  1', // Multiple spaces (still valid regex pattern)
        ];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 2');
      });

      test('preserves original spacing in base name', () {
        const sourceName = 'Week  1'; // Double space
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week  1 Copy 1'); // Preserves double space
      });
    });

    group('_extractBaseName (via generateCopyName behavior)', () {
      test('returns original name when no "Copy N" suffix exists', () {
        const sourceName = 'Week 1';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, startsWith('Week 1'));
      });

      test('removes "Copy 1" suffix', () {
        const sourceName = 'Week 1 Copy 1';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 1'); // Base is "Week 1", adds " Copy 1"
      });

      test('removes "Copy 5" suffix', () {
        const sourceName = 'Week 1 Copy 5';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 1 Copy 1'); // Base is "Week 1", starts at 1
      });

      test('handles nested copies correctly', () {
        const sourceName = 'Week 1 Copy 1 Copy 2'; // Edge case: nested copies
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        // Should extract "Week 1 Copy 1" as base (removes last " Copy 2")
        expect(result, 'Week 1 Copy 1 Copy 1');
      });
    });

    group('Edge Cases', () {
      test('handles very long source names', () {
        const sourceName =
            'This is a very long week name that might be used by someone who likes descriptive names';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(
          result,
          'This is a very long week name that might be used by someone who likes descriptive names Copy 1',
        );
      });

      test('handles source name ending with number', () {
        const sourceName = 'Week 123';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Week 123 Copy 1');
      });

      test('handles source name with "Copy" in the middle', () {
        const sourceName = 'Copy This Week';
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Copy This Week Copy 1');
      });

      test('handles Unicode characters in source name', () {
        const sourceName = 'Semaine 1 🏋️'; // French week with emoji
        final existingNames = <String>[];

        final result = SmartCopyNaming.generateCopyName(sourceName, existingNames);

        expect(result, 'Semaine 1 🏋️ Copy 1');
      });
    });
  });
}
