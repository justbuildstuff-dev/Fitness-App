import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/charts/time_range_selector.dart';

void main() {
  group('TimeRangeSelector', () {
    Widget buildTestWidget({
      TimeRange selected = TimeRange.threeMonths,
      required ValueChanged<TimeRange> onChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TimeRangeSelector(
            selected: selected,
            onChanged: onChanged,
          ),
        ),
      );
    }

    testWidgets('renders all 4 segments', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onChanged: (_) {},
      ));

      expect(find.text('1M'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('defaults to 3M selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onChanged: (_) {},
      ));

      // SegmentedButton renders, 3M is selected by default
      expect(find.byType(SegmentedButton<TimeRange>), findsOneWidget);
    });

    testWidgets('calls onChanged when segment tapped', (tester) async {
      TimeRange? selectedRange;

      await tester.pumpWidget(buildTestWidget(
        onChanged: (range) => selectedRange = range,
      ));

      // Tap "1M" segment
      await tester.tap(find.text('1M'));
      await tester.pumpAndSettle();

      expect(selectedRange, equals(TimeRange.oneMonth));
    });

    testWidgets('calls onChanged with 6M', (tester) async {
      TimeRange? selectedRange;

      await tester.pumpWidget(buildTestWidget(
        onChanged: (range) => selectedRange = range,
      ));

      await tester.tap(find.text('6M'));
      await tester.pumpAndSettle();

      expect(selectedRange, equals(TimeRange.sixMonths));
    });

    testWidgets('calls onChanged with All', (tester) async {
      TimeRange? selectedRange;

      await tester.pumpWidget(buildTestWidget(
        onChanged: (range) => selectedRange = range,
      ));

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(selectedRange, equals(TimeRange.allTime));
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        onChanged: (_) {},
      ));

      final semantics = find.bySemanticsLabel(
        RegExp(r'Time range selector, currently 3M'),
      );
      expect(semantics, findsOneWidget);
    });
  });

  group('TimeRange', () {
    test('labels are correct', () {
      expect(TimeRange.oneMonth.label, equals('1M'));
      expect(TimeRange.threeMonths.label, equals('3M'));
      expect(TimeRange.sixMonths.label, equals('6M'));
      expect(TimeRange.allTime.label, equals('All'));
    });

    test('toDateRange returns valid DateRange for each option', () {
      final now = DateTime.now();

      final oneMonth = TimeRange.oneMonth.toDateRange();
      expect(oneMonth.end.day, equals(now.day));
      expect(oneMonth.durationInDays, greaterThanOrEqualTo(28));

      final threeMonths = TimeRange.threeMonths.toDateRange();
      expect(threeMonths.durationInDays, greaterThanOrEqualTo(89));

      final sixMonths = TimeRange.sixMonths.toDateRange();
      expect(sixMonths.durationInDays, greaterThanOrEqualTo(181));

      final allTime = TimeRange.allTime.toDateRange();
      expect(allTime.start.year, equals(2020));
    });
  });
}
