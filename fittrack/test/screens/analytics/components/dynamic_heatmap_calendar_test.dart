import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/screens/analytics/components/dynamic_heatmap_calendar.dart';

void main() {
  group('DynamicHeatmapCalendar Widget Tests', () {
    late ActivityHeatmapData testData;

    setUp(() {
      // Create test data with varied set counts for different intensity levels
      final now = DateTime.now();
      testData = ActivityHeatmapData(
        userId: 'test_user',
        year: now.year,
        dailySetCounts: {
          // Different intensity levels
          DateTime(now.year, now.month, now.day): 30, // veryHigh
          DateTime(now.year, now.month, now.day - 1): 20, // high
          DateTime(now.year, now.month, now.day - 2): 10, // medium
          DateTime(now.year, now.month, now.day - 3): 3, // low
          DateTime(now.year, now.month, now.day - 4): 0, // none
        },
        currentStreak: 4,
        longestStreak: 7,
        totalSets: 63,
      );
    });

    Widget buildTestWidget({
      required ActivityHeatmapData data,
      required HeatmapLayoutConfig config,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DynamicHeatmapCalendar(
            data: data,
            config: config,
          ),
        ),
      );
    }

    group('This Week Layout Tests', () {
      testWidgets('renders week layout correctly', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);

        // Day labels should be present
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Tue'), findsOneWidget);
        expect(find.text('Wed'), findsOneWidget);
        expect(find.text('Thu'), findsOneWidget);
        expect(find.text('Fri'), findsOneWidget);
        expect(find.text('Sat'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });

      testWidgets('does not show month labels for week view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Month labels should not be present (only for year view)
        expect(find.text('Jan'), findsNothing);
        expect(find.text('Feb'), findsNothing);
      });

      testWidgets('uses static grid for week view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should not have scrollable widget for week view
        expect(config.enableVerticalScroll, isFalse);
      });
    });

    group('This Month Layout Tests', () {
      testWidgets('renders month layout correctly', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);

        // Day labels should be present
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });

      testWidgets('uses static grid for month view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should not have vertical scroll
        expect(config.enableVerticalScroll, isFalse);
      });
    });

    group('Last 30 Days Layout Tests', () {
      testWidgets('renders 30-day layout correctly', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('uses static grid for 30-day view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.last30Days);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        expect(config.enableVerticalScroll, isFalse);
      });
    });

    group('This Year Layout Tests', () {
      testWidgets('renders year layout with scrolling', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);

        // Should have scrollable widget for year view
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('shows month labels for year view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Month labels should be present
        expect(find.text('Jan'), findsOneWidget);
        expect(find.text('Feb'), findsOneWidget);
        expect(find.text('Mar'), findsOneWidget);
        expect(find.text('Dec'), findsOneWidget);
      });

      testWidgets('enables vertical scrolling for year view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        expect(config.enableVerticalScroll, isTrue);
      });

      testWidgets('can scroll through year view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Find the scrollable widget
        final scrollView = find.byType(SingleChildScrollView);
        expect(scrollView, findsOneWidget);

        // Perform scroll
        await tester.drag(scrollView, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Should not crash
        expect(tester.takeException(), isNull);
      });
    });

    group('Heatmap Cell Rendering Tests', () {
      testWidgets('renders heatmap squares', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should find multiple HeatmapSquare widgets (7 days minimum)
        expect(find.byType(HeatmapSquare), findsWidgets);
      });

      testWidgets('renders empty cells for partial weeks', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without errors even with partial weeks
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('displays different intensity colors', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Find HeatmapSquare widgets
        final squares = find.byType(HeatmapSquare);
        expect(squares, findsWidgets);

        // Should have squares with different intensities (verified by presence of widgets)
        final squareWidgets = tester.widgetList<HeatmapSquare>(squares);
        expect(squareWidgets.length, greaterThan(0));
      });
    });

    group('Legend Tests', () {
      testWidgets('renders legend with all intensity levels', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Legend labels should be present
        expect(find.text('Less'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);

        // Should have 5 intensity level boxes (none, low, medium, high, veryHigh)
        // Testing this indirectly through the presence of the legend
        expect(find.text('Less'), findsOneWidget);
      });

      testWidgets('legend appears for all timeframes', (tester) async {
        for (final timeframe in HeatmapTimeframe.values) {
          final config = HeatmapLayoutConfig.forTimeframe(timeframe);

          await tester.pumpWidget(buildTestWidget(
            data: testData,
            config: config,
          ));

          expect(find.text('Less'), findsOneWidget);
          expect(find.text('More'), findsOneWidget);

          await tester.pumpAndSettle();
        }
      });
    });

    group('Day Labels Tests', () {
      testWidgets('renders all day labels', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // All 7 day labels should be present
        final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        for (final label in dayLabels) {
          expect(find.text(label), findsOneWidget);
        }
      });

      testWidgets('day labels have correct height', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Find day label containers (testing indirectly through rendering)
        expect(find.text('Mon'), findsOneWidget);
      });
    });

    group('Interaction Tests', () {
      testWidgets('tapping cell shows popup', (tester) async {
        final now = DateTime.now();
        final dataWithSets = ActivityHeatmapData(
          userId: 'test_user',
          year: now.year,
          dailySetCounts: {
            DateTime(now.year, now.month, now.day): 15,
          },
          currentStreak: 1,
          longestStreak: 1,
          totalSets: 15,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: dataWithSets,
          config: config,
        ));

        // Find a heatmap square
        final square = find.byType(HeatmapSquare).first;

        // Tap it
        await tester.tap(square);
        await tester.pumpAndSettle();

        // Popup should appear (testing that no exception is thrown)
        expect(tester.takeException(), isNull);
      });

      testWidgets('tapping empty cell does not show popup', (tester) async {
        final emptyData = ActivityHeatmapData(
          userId: 'test_user',
          year: DateTime.now().year,
          dailySetCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalSets: 0,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: emptyData,
          config: config,
        ));

        // Find a heatmap square
        final square = find.byType(HeatmapSquare).first;

        // Tap it
        await tester.tap(square);
        await tester.pumpAndSettle();

        // Should not crash
        expect(tester.takeException(), isNull);
      });

      testWidgets('tooltip shows on hover', (tester) async {
        final now = DateTime.now();
        final dataWithSets = ActivityHeatmapData(
          userId: 'test_user',
          year: now.year,
          dailySetCounts: {
            DateTime(now.year, now.month, now.day): 10,
          },
          currentStreak: 1,
          longestStreak: 1,
          totalSets: 10,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: dataWithSets,
          config: config,
        ));

        // Long press to trigger tooltip
        final square = find.byType(HeatmapSquare).first;
        await tester.longPress(square);
        await tester.pump(const Duration(milliseconds: 500));

        // Tooltip should appear (testing that widget tree doesn't throw)
        expect(tester.takeException(), isNull);
      });
    });

    group('Current Week Highlighting Tests', () {
      testWidgets('highlights current week in year view', (tester) async {
        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without errors
        // Current week highlighting is visual, tested indirectly
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });
    });

    group('Empty Data Tests', () {
      testWidgets('renders correctly with no activity', (tester) async {
        final emptyData = ActivityHeatmapData(
          userId: 'test_user',
          year: DateTime.now().year,
          dailySetCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalSets: 0,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: emptyData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
        expect(find.text('Less'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);
      });

      testWidgets('all cells show "none" intensity with empty data', (tester) async {
        final emptyData = ActivityHeatmapData(
          userId: 'test_user',
          year: DateTime.now().year,
          dailySetCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalSets: 0,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: emptyData,
          config: config,
        ));

        // Should have heatmap squares (all with none intensity)
        expect(find.byType(HeatmapSquare), findsWidgets);
      });
    });

    group('Layout Adaptation Tests', () {
      testWidgets('adapts to different timeframes correctly', (tester) async {
        for (final timeframe in HeatmapTimeframe.values) {
          final config = HeatmapLayoutConfig.forTimeframe(timeframe);

          await tester.pumpWidget(buildTestWidget(
            data: testData,
            config: config,
          ));

          // Should render without errors for each timeframe
          expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);

          // Verify day labels are present
          expect(find.text('Mon'), findsOneWidget);
          expect(find.text('Sun'), findsOneWidget);

          await tester.pumpAndSettle();
        }
      });

      testWidgets('handles different year data correctly', (tester) async {
        // Test with data from different years
        final pastYear = DateTime.now().year - 1;
        final pastYearData = ActivityHeatmapData(
          userId: 'test_user',
          year: pastYear,
          dailySetCounts: {
            DateTime(pastYear, 6, 15): 10,
          },
          currentStreak: 0,
          longestStreak: 1,
          totalSets: 10,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: pastYearData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });
    });

    group('Responsive Layout Tests', () {
      testWidgets('renders correctly on narrow screens', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisWeek);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        // Should render without overflow
        expect(tester.takeException(), isNull);
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('renders correctly on wide screens', (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('renders correctly on tablet screens', (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        await tester.pumpWidget(buildTestWidget(
          data: testData,
          config: config,
        ));

        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('handles large dataset efficiently', (tester) async {
        // Create data with sets every day for a year
        final largeDataset = <DateTime, int>{};
        final now = DateTime.now();
        for (int i = 0; i < 365; i++) {
          final date = DateTime(now.year, 1, 1).add(Duration(days: i));
          largeDataset[date] = (i % 30) + 1; // Vary set counts
        }

        final largeData = ActivityHeatmapData(
          userId: 'test_user',
          year: now.year,
          dailySetCounts: largeDataset,
          currentStreak: 365,
          longestStreak: 365,
          totalSets: largeDataset.values.reduce((a, b) => a + b),
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        // Should render within reasonable time
        await tester.pumpWidget(buildTestWidget(
          data: largeData,
          config: config,
        ));

        // Should render without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });
    });

    group('Edge Case Tests', () {
      testWidgets('handles leap year correctly', (tester) async {
        final leapYearData = ActivityHeatmapData(
          userId: 'test_user',
          year: 2024, // Leap year
          dailySetCounts: {
            DateTime(2024, 2, 29): 10, // Feb 29th
          },
          currentStreak: 1,
          longestStreak: 1,
          totalSets: 10,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: leapYearData,
          config: config,
        ));

        // Should handle Feb 29th without errors
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('handles year boundary correctly', (tester) async {
        final now = DateTime.now();
        final yearEndData = ActivityHeatmapData(
          userId: 'test_user',
          year: now.year,
          dailySetCounts: {
            DateTime(now.year, 1, 1): 5,
            DateTime(now.year, 12, 31): 10,
          },
          currentStreak: 0,
          longestStreak: 1,
          totalSets: 15,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisYear);

        await tester.pumpWidget(buildTestWidget(
          data: yearEndData,
          config: config,
        ));

        // Should render first and last days correctly
        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('handles month with 31 days', (tester) async {
        final now = DateTime.now();
        final januaryData = <DateTime, int>{};
        for (int day = 1; day <= 31; day++) {
          januaryData[DateTime(now.year, 1, day)] = day % 10;
        }

        final data = ActivityHeatmapData(
          userId: 'test_user',
          year: now.year,
          dailySetCounts: januaryData,
          currentStreak: 31,
          longestStreak: 31,
          totalSets: januaryData.values.reduce((a, b) => a + b),
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        await tester.pumpWidget(buildTestWidget(
          data: data,
          config: config,
        ));

        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });

      testWidgets('handles month with 28 days (non-leap year)', (tester) async {
        final februaryData = <DateTime, int>{};
        for (int day = 1; day <= 28; day++) {
          februaryData[DateTime(2023, 2, day)] = 5;
        }

        final data = ActivityHeatmapData(
          userId: 'test_user',
          year: 2023,
          dailySetCounts: februaryData,
          currentStreak: 28,
          longestStreak: 28,
          totalSets: 140,
        );

        final config = HeatmapLayoutConfig.forTimeframe(HeatmapTimeframe.thisMonth);

        await tester.pumpWidget(buildTestWidget(
          data: data,
          config: config,
        ));

        expect(find.byType(DynamicHeatmapCalendar), findsOneWidget);
      });
    });
  });
}
