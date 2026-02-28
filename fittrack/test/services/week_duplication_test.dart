import 'package:flutter_test/flutter_test.dart';

/// Unit tests for week duplication sequential naming logic.
///
/// duplicateWeek() in FirestoreService uses sequential naming:
/// - Finds the maximum 'order' value among existing weeks in the program
/// - New week gets order = maxOrder + 1
/// - New week name = 'Week $newOrder'
///
/// This replaces the previous SmartCopyNaming-based approach ("Copy N" suffix).
///
/// Related files:
/// - lib/services/firestore_service.dart - duplicateWeek() implementation

/// Mirrors the max-order calculation used in FirestoreService.duplicateWeek().
int _computeNewOrder(List<int?> existingOrders) {
  return existingOrders
      .map((order) => order ?? 0)
      .fold(0, (max, order) => order > max ? order : max) + 1;
}

/// Mirrors the name generation used in FirestoreService.duplicateWeek().
String _computeNewWeekName(int newOrder) => 'Week $newOrder';

void main() {
  group('Week Duplication Sequential Naming', () {
    group('order calculation', () {
      test('returns 2 when only one week exists with order 1', () {
        expect(_computeNewOrder([1]), 2);
      });

      test('returns maxOrder + 1 for sequential weeks', () {
        expect(_computeNewOrder([1, 2, 3]), 4);
      });

      test('returns maxOrder + 1 for non-sequential (gap) orders', () {
        // Gaps in order don't cause duplicates — new week appends after max
        expect(_computeNewOrder([1, 3, 5]), 6);
      });

      test('returns 1 when no weeks exist', () {
        expect(_computeNewOrder([]), 1);
      });

      test('handles null order values by treating them as 0', () {
        expect(_computeNewOrder([null, 2, 3]), 4);
      });

      test('handles all null order values, returns 1', () {
        expect(_computeNewOrder([null, null]), 1);
      });

      test('handles a single null order, returns 1', () {
        expect(_computeNewOrder([null]), 1);
      });

      test('returns max + 1 when orders are unsorted', () {
        expect(_computeNewOrder([3, 1, 4, 2]), 5);
      });

      test('handles large order numbers', () {
        expect(_computeNewOrder([1, 2, 98, 99, 100]), 101);
      });
    });

    group('name generation', () {
      test('generates "Week 1" for order 1', () {
        expect(_computeNewWeekName(1), 'Week 1');
      });

      test('generates "Week 2" for order 2', () {
        expect(_computeNewWeekName(2), 'Week 2');
      });

      test('generates "Week 10" for order 10', () {
        expect(_computeNewWeekName(10), 'Week 10');
      });
    });

    group('sequential duplication workflow', () {
      test('first duplication of a 1-week program creates Week 2', () {
        final existingOrders = [1];
        final newOrder = _computeNewOrder(existingOrders);

        expect(newOrder, 2);
        expect(_computeNewWeekName(newOrder), 'Week 2');
      });

      test('duplicating a 2-week program creates Week 3', () {
        final existingOrders = [1, 2];
        final newOrder = _computeNewOrder(existingOrders);

        expect(newOrder, 3);
        expect(_computeNewWeekName(newOrder), 'Week 3');
      });

      test('consecutive duplications produce strictly sequential names', () {
        var orders = [1];

        final order2 = _computeNewOrder(orders);
        expect(_computeNewWeekName(order2), 'Week 2');
        orders.add(order2);

        final order3 = _computeNewOrder(orders);
        expect(_computeNewWeekName(order3), 'Week 3');
        orders.add(order3);

        final order4 = _computeNewOrder(orders);
        expect(_computeNewWeekName(order4), 'Week 4');
      });

      test('duplicate after week deletion appends after remaining max', () {
        // Program had weeks 1, 2, 3 but week 2 was deleted
        // Sequential naming appends after max (3), not filling gaps
        final existingOrders = [1, 3];
        final newOrder = _computeNewOrder(existingOrders);

        expect(newOrder, 4);
        expect(_computeNewWeekName(newOrder), 'Week 4');
      });

      test('empty program duplicates to Week 1', () {
        final existingOrders = <int?>[];
        final newOrder = _computeNewOrder(existingOrders);

        expect(newOrder, 1);
        expect(_computeNewWeekName(newOrder), 'Week 1');
      });
    });
  });
}
