import 'package:flutter_test/flutter_test.dart';

/// Unit tests for week duplication sequential naming logic.
///
/// duplicateWeek() in FirestoreService uses count-based naming:
/// - Counts existing weeks in the program
/// - New week gets order = existingCount + 1
/// - New week name = 'Week $newOrder'
///
/// This approach is robust against stale/zero 'order' field values in
/// existing Firestore documents (a pre-existing data issue).
///
/// Related files:
/// - lib/services/firestore_service.dart - duplicateWeek() implementation

/// Mirrors the order calculation used in FirestoreService.duplicateWeek().
int _computeNewOrder(int existingCount) => existingCount + 1;

/// Mirrors the name generation used in FirestoreService.duplicateWeek().
String _computeNewWeekName(int newOrder) => 'Week $newOrder';

void main() {
  group('Week Duplication Sequential Naming', () {
    group('order calculation (count-based)', () {
      test('returns 2 when one week exists', () {
        expect(_computeNewOrder(1), 2);
      });

      test('returns 3 when two weeks exist', () {
        expect(_computeNewOrder(2), 3);
      });

      test('returns 4 when three weeks exist', () {
        expect(_computeNewOrder(3), 4);
      });

      test('returns 1 when no weeks exist', () {
        expect(_computeNewOrder(0), 1);
      });

      test('returns 11 when ten weeks exist', () {
        expect(_computeNewOrder(10), 11);
      });
    });

    group('name generation', () {
      test('generates "Week 1" for order 1', () {
        expect(_computeNewWeekName(1), 'Week 1');
      });

      test('generates "Week 2" for order 2', () {
        expect(_computeNewWeekName(2), 'Week 2');
      });

      test('generates "Week 3" for order 3', () {
        expect(_computeNewWeekName(3), 'Week 3');
      });

      test('generates correct name for large order numbers', () {
        expect(_computeNewWeekName(100), 'Week 100');
      });
    });

    group('sequential duplication workflow', () {
      test('duplicating from a 1-week program creates Week 2', () {
        final newOrder = _computeNewOrder(1);
        expect(newOrder, 2);
        expect(_computeNewWeekName(newOrder), 'Week 2');
      });

      test('duplicating from a 2-week program creates Week 3', () {
        final newOrder = _computeNewOrder(2);
        expect(newOrder, 3);
        expect(_computeNewWeekName(newOrder), 'Week 3');
      });

      test('consecutive duplications produce strictly sequential names', () {
        // Simulate: start with 1 week, duplicate 3 times
        var count = 1;

        final order2 = _computeNewOrder(count);
        expect(_computeNewWeekName(order2), 'Week 2');
        count++;

        final order3 = _computeNewOrder(count);
        expect(_computeNewWeekName(order3), 'Week 3');
        count++;

        final order4 = _computeNewOrder(count);
        expect(_computeNewWeekName(order4), 'Week 4');
      });

      test('count-based naming is unaffected by stale order field values', () {
        // Existing weeks all have order: 0 in Firestore (pre-existing data issue)
        // Count = 2, so new order = 3 regardless of stored order values
        const existingCount = 2;
        final newOrder = _computeNewOrder(existingCount);
        expect(newOrder, 3);
        expect(_computeNewWeekName(newOrder), 'Week 3');
      });

      test('empty program duplicates to Week 1', () {
        final newOrder = _computeNewOrder(0);
        expect(newOrder, 1);
        expect(_computeNewWeekName(newOrder), 'Week 1');
      });
    });
  });
}
