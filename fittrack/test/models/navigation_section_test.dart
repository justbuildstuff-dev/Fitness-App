import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/navigation_section.dart';

void main() {
  group('NavigationSection Enum', () {
    test('has correct number of sections', () {
      expect(NavigationSection.values.length, 3);
    });

    test('programs section has index 0', () {
      expect(NavigationSection.programs.index, 0);
    });

    test('analytics section has index 1', () {
      expect(NavigationSection.analytics.index, 1);
    });

    test('profile section has index 2', () {
      expect(NavigationSection.profile.index, 2);
    });

    test('can access sections by index via values list', () {
      expect(NavigationSection.values[0], NavigationSection.programs);
      expect(NavigationSection.values[1], NavigationSection.analytics);
      expect(NavigationSection.values[2], NavigationSection.profile);
    });

    test('enum names are correct', () {
      expect(NavigationSection.programs.name, 'programs');
      expect(NavigationSection.analytics.name, 'analytics');
      expect(NavigationSection.profile.name, 'profile');
    });

    test('index values match expected bottom nav positions', () {
      // Programs should be first (leftmost) in bottom nav
      expect(NavigationSection.programs.index, 0);

      // Analytics should be second (middle) in bottom nav
      expect(NavigationSection.analytics.index, 1);

      // Profile should be third (rightmost) in bottom nav
      expect(NavigationSection.profile.index, 2);
    });
  });
}
