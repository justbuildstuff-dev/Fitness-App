import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';

void main() {
  group('HeatmapIntensity', () {
    group('fromSetCount', () {
      test('returns none for 0 sets', () {
        expect(HeatmapIntensity.fromSetCount(0), equals(HeatmapIntensity.none));
      });

      test('returns low for 1-5 sets', () {
        expect(HeatmapIntensity.fromSetCount(1), equals(HeatmapIntensity.low));
        expect(HeatmapIntensity.fromSetCount(3), equals(HeatmapIntensity.low));
        expect(HeatmapIntensity.fromSetCount(5), equals(HeatmapIntensity.low));
      });

      test('returns medium for 6-15 sets', () {
        expect(HeatmapIntensity.fromSetCount(6), equals(HeatmapIntensity.medium));
        expect(HeatmapIntensity.fromSetCount(10), equals(HeatmapIntensity.medium));
        expect(HeatmapIntensity.fromSetCount(15), equals(HeatmapIntensity.medium));
      });

      test('returns high for 16-25 sets', () {
        expect(HeatmapIntensity.fromSetCount(16), equals(HeatmapIntensity.high));
        expect(HeatmapIntensity.fromSetCount(20), equals(HeatmapIntensity.high));
        expect(HeatmapIntensity.fromSetCount(25), equals(HeatmapIntensity.high));
      });

      test('returns veryHigh for 26+ sets', () {
        expect(HeatmapIntensity.fromSetCount(26), equals(HeatmapIntensity.veryHigh));
        expect(HeatmapIntensity.fromSetCount(50), equals(HeatmapIntensity.veryHigh));
        expect(HeatmapIntensity.fromSetCount(100), equals(HeatmapIntensity.veryHigh));
      });

      test('handles boundary values correctly', () {
        // Test boundary between none and low
        expect(HeatmapIntensity.fromSetCount(0), equals(HeatmapIntensity.none));
        expect(HeatmapIntensity.fromSetCount(1), equals(HeatmapIntensity.low));

        // Test boundary between low and medium
        expect(HeatmapIntensity.fromSetCount(5), equals(HeatmapIntensity.low));
        expect(HeatmapIntensity.fromSetCount(6), equals(HeatmapIntensity.medium));

        // Test boundary between medium and high
        expect(HeatmapIntensity.fromSetCount(15), equals(HeatmapIntensity.medium));
        expect(HeatmapIntensity.fromSetCount(16), equals(HeatmapIntensity.high));

        // Test boundary between high and veryHigh
        expect(HeatmapIntensity.fromSetCount(25), equals(HeatmapIntensity.high));
        expect(HeatmapIntensity.fromSetCount(26), equals(HeatmapIntensity.veryHigh));
      });
    });

    group('displayName', () {
      test('returns correct display names', () {
        expect(HeatmapIntensity.none.displayName, equals('No activity'));
        expect(HeatmapIntensity.low.displayName, equals('Light activity'));
        expect(HeatmapIntensity.medium.displayName, equals('Moderate activity'));
        expect(HeatmapIntensity.high.displayName, equals('High activity'));
        expect(HeatmapIntensity.veryHigh.displayName, equals('Very high activity'));
      });
    });
  });

  group('HeatmapTimeframe', () {
    test('has correct display names', () {
      expect(HeatmapTimeframe.thisWeek.displayName, equals('This Week'));
      expect(HeatmapTimeframe.thisMonth.displayName, equals('This Month'));
      expect(HeatmapTimeframe.last30Days.displayName, equals('Last 30 Days'));
      expect(HeatmapTimeframe.thisYear.displayName, equals('This Year'));
    });

    test('all values are unique', () {
      final values = HeatmapTimeframe.values;
      expect(values.toSet().length, equals(values.length));
    });
  });

  group('HeatmapLayoutConfig', () {
    group('forTimeframe - thisWeek', () {
      test('generates correct config for This Week', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        expect(config.timeframe, equals(HeatmapTimeframe.thisWeek));
        expect(config.rows, equals(1));
        expect(config.columns, equals(7));
        expect(config.columnLabels, equals(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']));
        expect(config.showMonthLabels, isFalse);
        expect(config.enableVerticalScroll, isFalse);
      });

      test('starts on Monday and ends on Sunday', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);
        final duration = config.endDate.difference(config.startDate);

        // Should be exactly 7 days (Mon-Sun)
        expect(duration.inDays, greaterThanOrEqualTo(6));
        expect(duration.inDays, lessThanOrEqualTo(7));

        // Start date should be a Monday (weekday = 1)
        expect(config.startDate.weekday, equals(DateTime.monday));
      });

      test('date range includes current week', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);
        final now = DateTime.now();

        expect(config.startDate.isBefore(now) || config.startDate.isAtSameMomentAs(now), isTrue);
        expect(config.endDate.isAfter(now) || config.endDate.isAtSameMomentAs(now), isTrue);
      });
    });

    group('forTimeframe - thisMonth', () {
      test('generates correct config for This Month', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        expect(config.timeframe, equals(HeatmapTimeframe.thisMonth));
        expect(config.columns, equals(7));
        expect(config.columnLabels, equals(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']));
        expect(config.showMonthLabels, isFalse);
        expect(config.enableVerticalScroll, isFalse);
        expect(config.rows, greaterThan(0));
      });

      test('starts on first day of current month', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);
        final now = DateTime.now();

        expect(config.startDate.year, equals(now.year));
        expect(config.startDate.month, equals(now.month));
        expect(config.startDate.day, equals(1));
      });

      test('ends on last day of current month', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);
        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0).day;

        expect(config.endDate.year, equals(now.year));
        expect(config.endDate.month, equals(now.month));
        expect(config.endDate.day, equals(lastDay));
      });

      test('calculates correct number of weeks for different month lengths', () {
        // This test verifies the logic works for various month configurations
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        // Number of weeks should be between 4 and 6
        expect(config.rows, greaterThanOrEqualTo(4));
        expect(config.rows, lessThanOrEqualTo(6));
      });
    });

    group('forTimeframe - last30Days', () {
      test('generates correct config for Last 30 Days', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days);

        expect(config.timeframe, equals(HeatmapTimeframe.last30Days));
        expect(config.columns, equals(7));
        expect(config.columnLabels, equals(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']));
        expect(config.showMonthLabels, isFalse);
        expect(config.enableVerticalScroll, isFalse);

        // Should need 5 weeks for 30 days (ceil(30/7) = 5)
        expect(config.rows, equals(5));
      });

      test('covers exactly 30 days ending today', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days);
        final now = DateTime.now();
        final todayNormalized = DateTime(now.year, now.month, now.day);

        // End date should be today
        expect(
          DateTime(config.endDate.year, config.endDate.month, config.endDate.day),
          equals(todayNormalized),
        );

        // Duration should be 30 days (29 days ago + today = 30 days total)
        final duration = config.endDate.difference(config.startDate);
        expect(duration.inDays, equals(29));
      });

      test('is a rolling window that changes daily', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days);
        final now = DateTime.now();

        // Should always end on today
        expect(config.endDate.day, equals(now.day));
        expect(config.endDate.month, equals(now.month));
        expect(config.endDate.year, equals(now.year));
      });
    });

    group('forTimeframe - thisYear', () {
      test('generates correct config for This Year', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        expect(config.timeframe, equals(HeatmapTimeframe.thisYear));
        expect(config.columns, equals(7));
        expect(config.columnLabels, equals(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']));
        expect(config.showMonthLabels, isTrue);
        expect(config.enableVerticalScroll, isTrue);
        expect(config.maxVisibleRows, equals(10));
      });

      test('starts on January 1st of current year', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);
        final now = DateTime.now();

        expect(config.startDate.year, equals(now.year));
        expect(config.startDate.month, equals(1));
        expect(config.startDate.day, equals(1));
      });

      test('ends on December 31st of current year', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);
        final now = DateTime.now();

        expect(config.endDate.year, equals(now.year));
        expect(config.endDate.month, equals(12));
        expect(config.endDate.day, equals(31));
      });

      test('calculates correct number of weeks for the year', () {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        // A year should have between 52 and 54 weeks depending on how it starts
        expect(config.rows, greaterThanOrEqualTo(52));
        expect(config.rows, lessThanOrEqualTo(54));
      });

      test('handles leap years correctly', () {
        final now = DateTime.now();
        final isLeapYear = (now.year % 4 == 0) &&
                          (now.year % 100 != 0 || now.year % 400 == 0);
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        final expectedDays = isLeapYear ? 366 : 365;
        final actualDays = config.endDate.difference(config.startDate).inDays + 1;

        expect(actualDays, equals(expectedDays));
      });
    });

    group('date range calculations', () {
      test('all timeframes produce valid date ranges', () {
        for (final timeframe in HeatmapTimeframe.values) {
          final config = HeatmapLayoutConfig.forTimeframe(timeframe);

          // Start date should be before end date
          expect(config.startDate.isBefore(config.endDate), isTrue,
              reason: 'Start date should be before end date for $timeframe');

          // Date range should not be in the far future
          // Note: "This Week" can have an end date up to 6 days in the future
          // (e.g., if today is Monday, week ends on Sunday)
          final now = DateTime.now();
          final maxFutureDays = timeframe == HeatmapTimeframe.thisWeek ? 7 : 1;
          expect(config.endDate.isAfter(now.add(Duration(days: maxFutureDays))), isFalse,
              reason: 'End date should not be in the far future for $timeframe');
        }
      });

      test('all timeframes have consistent grid dimensions', () {
        for (final timeframe in HeatmapTimeframe.values) {
          final config = HeatmapLayoutConfig.forTimeframe(timeframe);

          // All should use 7 columns (days of week)
          expect(config.columns, equals(7),
              reason: 'All timeframes should have 7 columns for $timeframe');

          // All should have at least 1 row
          expect(config.rows, greaterThan(0),
              reason: 'Should have at least 1 row for $timeframe');

          // Column labels should match columns
          expect(config.columnLabels.length, equals(config.columns),
              reason: 'Column labels should match column count for $timeframe');
        }
      });
    });

    group('scrolling configuration', () {
      test('only year view enables vertical scrolling', () {
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek).enableVerticalScroll,
          isFalse,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth).enableVerticalScroll,
          isFalse,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days).enableVerticalScroll,
          isFalse,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear).enableVerticalScroll,
          isTrue,
        );
      });

      test('only year view shows month labels', () {
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek).showMonthLabels,
          isFalse,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth).showMonthLabels,
          isFalse,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days).showMonthLabels,
          isFalse,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear).showMonthLabels,
          isTrue,
        );
      });

      test('only year view specifies maxVisibleRows', () {
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek).maxVisibleRows,
          isNull,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth).maxVisibleRows,
          isNull,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days).maxVisibleRows,
          isNull,
        );
        expect(
          HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear).maxVisibleRows,
          equals(10),
        );
      });
    });
  });

  group('DateRange', () {
    test('factory constructors create valid ranges', () {
      final thisWeek = DateRange.thisWeek();
      final thisMonth = DateRange.thisMonth();
      final thisYear = DateRange.thisYear();
      final last30Days = DateRange.last30Days();

      expect(thisWeek.start.isBefore(thisWeek.end), isTrue);
      expect(thisMonth.start.isBefore(thisMonth.end), isTrue);
      expect(thisYear.start.isBefore(thisYear.end), isTrue);
      expect(last30Days.start.isBefore(last30Days.end), isTrue);
    });

    test('contains method works correctly', () {
      final now = DateTime.now();
      final range = DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now.add(const Duration(days: 7)),
      );

      expect(range.contains(now), isTrue);
      expect(range.contains(now.subtract(const Duration(days: 3))), isTrue);
      expect(range.contains(now.add(const Duration(days: 3))), isTrue);
      expect(range.contains(now.subtract(const Duration(days: 10))), isFalse);
      expect(range.contains(now.add(const Duration(days: 10))), isFalse);
    });

    test('durationInDays calculates correctly', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 7);
      final range = DateRange(start: start, end: end);

      expect(range.durationInDays, equals(7));
    });

    test('thisWeek starts on Monday', () {
      final thisWeek = DateRange.thisWeek();
      expect(thisWeek.start.weekday, equals(DateTime.monday));
    });

    test('last30Days includes today', () {
      final last30Days = DateRange.last30Days();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(last30Days.contains(today), isTrue);
    });
  });
}
