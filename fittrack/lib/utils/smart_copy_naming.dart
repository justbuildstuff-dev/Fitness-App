/// Utility class for generating intelligent copy names with auto-incrementing numbers.
///
/// This class provides smart naming for duplicated items by:
/// - Detecting existing "Copy N" suffixes
/// - Extracting base names
/// - Finding gaps in numbering sequences
/// - Generating the next available copy number
///
/// Examples:
/// ```dart
/// // First duplicate
/// generateCopyName("Week 1", []) // "Week 1 Copy 1"
///
/// // Second duplicate
/// generateCopyName("Week 1", ["Week 1 Copy 1"]) // "Week 1 Copy 2"
///
/// // Duplicating a copy
/// generateCopyName("Week 1 Copy 1", ["Week 1 Copy 2"]) // "Week 1 Copy 3"
///
/// // Gap filling
/// generateCopyName("Week 1", ["Week 1 Copy 1", "Week 1 Copy 3"]) // "Week 1 Copy 2"
/// ```
class SmartCopyNaming {
  /// Regular expression pattern to match " Copy N" suffix where N is a number.
  ///
  /// Pattern breakdown:
  /// - `\s+` - One or more whitespace characters
  /// - `Copy` - Literal "Copy"
  /// - `\s+` - One or more whitespace characters
  /// - `(\d+)` - Capturing group for one or more digits
  /// - `$` - End of string
  static final RegExp _copyPattern = RegExp(r'\s+Copy\s+(\d+)$');

  /// Generates an intelligent copy name for a duplicated item.
  ///
  /// Algorithm:
  /// 1. Extracts the base name from [sourceName] (removes " Copy N" if present)
  /// 2. Finds all existing copies matching "{baseName} Copy {N}" pattern
  /// 3. Extracts all N values and sorts them
  /// 4. Checks for gaps in the sequence [1, 2, 3, ...]
  /// 5. Returns lowest missing number if gap exists, otherwise max(N) + 1
  /// 6. If no copies exist, returns "{baseName} Copy 1"
  ///
  /// Parameters:
  /// - [sourceName]: The name of the item being duplicated
  /// - [existingNames]: List of all existing names to check for conflicts
  ///
  /// Returns:
  /// A unique copy name with an auto-incremented number.
  ///
  /// Examples:
  /// ```dart
  /// // First duplicate
  /// generateCopyName("Week 1", []) // "Week 1 Copy 1"
  ///
  /// // Increment existing copies
  /// generateCopyName("Week 1", ["Week 1 Copy 1"]) // "Week 1 Copy 2"
  ///
  /// // Fill gaps in numbering
  /// generateCopyName("Week 1", ["Week 1 Copy 1", "Week 1 Copy 3"]) // "Week 1 Copy 2"
  ///
  /// // Handle custom names
  /// generateCopyName("Upper Body", []) // "Upper Body Copy 1"
  ///
  /// // Duplicate a copy (extracts base name)
  /// generateCopyName("Week 1 Copy 1", ["Week 1 Copy 2"]) // "Week 1 Copy 3"
  /// ```
  static String generateCopyName(String sourceName, List<String> existingNames) {
    // Extract base name (removes " Copy N" suffix if present)
    final baseName = _extractBaseName(sourceName);

    // Find all existing copy numbers for this base name
    final copyNumbers = <int>[];

    for (final name in existingNames) {
      // Check if this name matches the "{baseName} Copy {N}" pattern
      if (name.startsWith(baseName)) {
        final suffix = name.substring(baseName.length);
        final match = _copyPattern.firstMatch(suffix);

        if (match != null) {
          final numberStr = match.group(1);
          if (numberStr != null) {
            final number = int.tryParse(numberStr);
            if (number != null) {
              copyNumbers.add(number);
            }
          }
        }
      }
    }

    // Determine next copy number
    int nextNumber;

    if (copyNumbers.isEmpty) {
      // No copies exist, start with 1
      nextNumber = 1;
    } else {
      // Sort numbers to check for gaps
      copyNumbers.sort();

      // Check for gaps in sequence [1, 2, 3, ...]
      int? firstGap;
      for (int i = 1; i <= copyNumbers.last; i++) {
        if (!copyNumbers.contains(i)) {
          firstGap = i;
          break;
        }
      }

      if (firstGap != null) {
        // Fill the lowest gap
        nextNumber = firstGap;
      } else {
        // No gaps, use max + 1
        nextNumber = copyNumbers.last + 1;
      }
    }

    return '$baseName Copy $nextNumber';
  }

  /// Extracts the base name by removing " Copy N" suffix if present.
  ///
  /// If the source name already has a " Copy N" suffix, it is removed to
  /// get the original base name. This allows duplicating copies to increment
  /// correctly.
  ///
  /// Examples:
  /// ```dart
  /// _extractBaseName("Week 1") // "Week 1"
  /// _extractBaseName("Week 1 Copy 1") // "Week 1"
  /// _extractBaseName("Week 1 Copy 5") // "Week 1"
  /// _extractBaseName("Upper Body") // "Upper Body"
  /// _extractBaseName("Upper Body Copy 2") // "Upper Body"
  /// ```
  ///
  /// Parameters:
  /// - [name]: The name to extract the base from
  ///
  /// Returns:
  /// The base name without any " Copy N" suffix.
  static String _extractBaseName(String name) {
    final match = _copyPattern.firstMatch(name);

    if (match != null) {
      // Remove the " Copy N" suffix
      return name.substring(0, match.start);
    }

    // No " Copy N" suffix, return as-is
    return name;
  }
}
