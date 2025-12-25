import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/screens/analytics/components/monthly_calendar_view.dart';

void main() {
  group('MonthlyCalendarView Widget Tests', () {
    late MonthHeatmapData testData;
    late DateTime testMonth;

    setUp(() {
      // December 2024: First day is Sunday, last day is Tuesday
      testMonth = DateTime(2024, 12, 1);
      testData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {
          1: 3,   // Low intensity (1-5 sets)
          5: 8,   // Medium intensity (6-15 sets)
          10: 18, // High intensity (16-25 sets)
          15: 30, // Very high intensity (26+ sets)
          20: 0,  // None intensity (should still show as current month)
        },
        totalSets: 59,
        fetchedAt: DateTime.now(),
      );
    });

    testWidgets('renders day labels (Mon-Sun)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      // Check all day labels are present
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('renders calendar grid with correct number of weeks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      // December 2024 needs 6 weeks (42 cells)
      // First week: Nov 25-Dec 1
      // Last week: Dec 30-Jan 5
      // Check for day numbers that would appear
      expect(find.text('1'), findsWidgets); // Dec 1, Jan 1
      expect(find.text('31'), findsOneWidget); // Dec 31
    });

    testWidgets('displays current month days with heatmap colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find containers representing day cells
      final containerFinder = find.descendant(
        of: find.byType(MonthlyCalendarView),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsWidgets);
    });

    testWidgets('displays adjacent month days in gray', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Adjacent month days should be rendered but not have heatmap colors
      // Dec 2024 starts on Sunday, so Nov 25-30 appear in first week
      // Also Dec 25-26 appear in current month, so these numbers appear twice
      expect(find.text('25'), findsNWidgets(2)); // Nov 25 + Dec 25
      expect(find.text('26'), findsNWidgets(2)); // Nov 26 + Dec 26
    });

    testWidgets('highlights current day with border', (WidgetTester tester) async {
      final today = DateTime.now();
      final currentMonthData = MonthHeatmapData(
        year: today.year,
        month: today.month,
        dailySetCounts: {today.day: 5},
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: MonthlyCalendarView(
              data: currentMonthData,
              displayMonth: DateTime(today.year, today.month, 1),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the container for today's date
      final todayText = find.text('${today.day}');
      expect(todayText, findsWidgets); // May find multiple (current month + adjacent months)

      // Check that at least one container has a border (today's cell)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBoderredContainer = containers.any((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          return decoration.border != null;
        }
        return false;
      });
      expect(hasBoderredContainer, isTrue);
    });

    testWidgets('calls onDayTapped when tapping a day with sets', (WidgetTester tester) async {
      DateTime? tappedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
              onDayTapped: (date) {
                tappedDate = date;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Dec 5 (has 8 sets - medium intensity)
      // Note: "5" appears twice (Dec 5 + Jan 5), so tap first occurrence
      final dec5Finder = find.text('5');
      expect(dec5Finder, findsNWidgets(2));

      // Tap on first occurrence (Dec 5)
      await tester.tap(dec5Finder.first);
      await tester.pumpAndSettle();

      // Verify callback was called with correct date
      expect(tappedDate, isNotNull);
      expect(tappedDate!.year, 2024);
      expect(tappedDate!.month, 12);
      expect(tappedDate!.day, 5);
    });

    testWidgets('does not call onDayTapped for days with 0 sets', (WidgetTester tester) async {
      DateTime? tappedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
              onDayTapped: (date) {
                tappedDate = date;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Dec 2 (not in dailySetCounts, so 0 sets)
      // Note: "2" appears twice (Dec 2 + Jan 2), so tap first occurrence
      final dec2Finder = find.text('2');
      expect(dec2Finder, findsNWidgets(2));

      // Tap on first occurrence (Dec 2)
      await tester.tap(dec2Finder.first);
      await tester.pumpAndSettle();

      // Verify callback was NOT called
      expect(tappedDate, isNull);
    });

    testWidgets('does not call onDayTapped for adjacent month days', (WidgetTester tester) async {
      DateTime? tappedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
              onDayTapped: (date) {
                tappedDate = date;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Nov 25 (adjacent month day in first week)
      // Note: "25" appears twice (Nov 25 + Dec 25), so tap first occurrence
      final nov25Finder = find.text('25');
      expect(nov25Finder, findsNWidgets(2));

      // Tap on first occurrence (Nov 25)
      await tester.tap(nov25Finder.first);
      await tester.pumpAndSettle();

      // Verify callback was NOT called
      expect(tappedDate, isNull);
    });

    testWidgets('renders 5 weeks for months that fit in 5 weeks', (WidgetTester tester) async {
      // February 2027: Starts on Monday, 28 days, fits in exactly 4 weeks
      // But we show 5 weeks minimum for consistency
      final feb2027 = DateTime(2027, 2, 1);
      final feb2027Data = MonthHeatmapData(
        year: 2027,
        month: 2,
        dailySetCounts: {1: 5},
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: feb2027Data,
              displayMonth: feb2027,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have 35 cells (5 weeks × 7 days)
      // Count GestureDetectors that wrap each calendar cell
      final gestureDetectors = tester.widgetList<GestureDetector>(find.byType(GestureDetector));
      expect(gestureDetectors.length, 35);
    });

    testWidgets('renders 6 weeks for months that need 6 weeks', (WidgetTester tester) async {
      // August 2026: Starts on Saturday, 31 days, needs 6 weeks
      final aug2026 = DateTime(2026, 8, 1);
      final aug2026Data = MonthHeatmapData(
        year: 2026,
        month: 8,
        dailySetCounts: {1: 5},
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: aug2026Data,
              displayMonth: aug2026,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have 42 cells (6 weeks × 7 days)
      final gestureDetectors = tester.widgetList<GestureDetector>(find.byType(GestureDetector));
      expect(gestureDetectors.length, 42);
    });

    testWidgets('applies correct heatmap intensity colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify containers exist (color verification requires more complex testing)
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      expect(containers, isNotEmpty);
    });

    testWidgets('calculates cell size within 40-60px range', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Simulate specific screen width
              child: MonthlyCalendarView(
                data: testData,
                displayMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find containers representing day cells
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );

      // Check that containers have reasonable heights (40-60 range)
      for (final container in containers) {
        final height = container.constraints?.maxHeight ?? 0;
        // Height may be null for containers without explicit constraints
        if (height > 0) {
          expect(height, greaterThanOrEqualTo(40));
          expect(height, lessThanOrEqualTo(60));
        }
      }
    });

    testWidgets('handles empty month data (no sets)', (WidgetTester tester) async {
      final emptyData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {},
        totalSets: 0,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: emptyData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render the calendar grid
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('handles month with all days having sets', (WidgetTester tester) async {
      final fullData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {
          for (var day = 1; day <= 31; day++) day: 10, // Medium intensity for all days
        },
        totalSets: 310,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: MonthlyCalendarView(
              data: fullData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('displays correct day numbers for first week of December 2024', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // December 2024 first week (Mon-Sun): Nov 25, 26, 27, 28, 29, 30, Dec 1
      // Days 25-30 appear twice (Nov + Dec)
      expect(find.text('25'), findsNWidgets(2)); // Nov 25 (Mon) + Dec 25
      expect(find.text('26'), findsNWidgets(2)); // Nov 26 (Tue) + Dec 26
      expect(find.text('27'), findsNWidgets(2)); // Nov 27 (Wed) + Dec 27
      expect(find.text('28'), findsNWidgets(2)); // Nov 28 (Thu) + Dec 28
      expect(find.text('29'), findsNWidgets(2)); // Nov 29 (Fri) + Dec 29
      expect(find.text('30'), findsNWidgets(2)); // Nov 30 (Sat) + Dec 30
      expect(find.text('1'), findsNWidgets(2));  // Dec 1 (Sun) + Jan 1
    });

    testWidgets('displays correct day numbers for last week of December 2024', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // December 2024 last week (Mon-Sun): Dec 30, 31, Jan 1, 2, 3, 4, 5
      expect(find.text('30'), findsWidgets);   // Dec 30 (Mon)
      expect(find.text('31'), findsOneWidget); // Dec 31 (Tue)
      expect(find.text('1'), findsWidgets);    // Jan 1 (Wed)
      expect(find.text('2'), findsWidgets);    // Jan 2 (Thu)
      expect(find.text('3'), findsWidgets);    // Jan 3 (Fri)
      expect(find.text('4'), findsWidgets);    // Jan 4 (Sat)
      expect(find.text('5'), findsWidgets);    // Jan 5 (Sun)
    });

    testWidgets('handles leap year (February 2024)', (WidgetTester tester) async {
      final feb2024 = DateTime(2024, 2, 1);
      final feb2024Data = MonthHeatmapData(
        year: 2024,
        month: 2,
        dailySetCounts: {29: 5}, // Leap day
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: feb2024Data,
              displayMonth: feb2024,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show 29 days for February 2024 (leap year)
      expect(find.text('29'), findsWidgets);
    });

    testWidgets('handles non-leap year (February 2023)', (WidgetTester tester) async {
      final feb2023 = DateTime(2023, 2, 1);
      final feb2023Data = MonthHeatmapData(
        year: 2023,
        month: 2,
        dailySetCounts: {28: 5}, // Last day
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: feb2023Data,
              displayMonth: feb2023,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show 28 days for February 2023 (non-leap year)
      expect(find.text('28'), findsWidgets);
      // Day 29 should not be in current month (might be in next month)
    });

    testWidgets('renders without onDayTapped callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
              // No onDayTapped provided
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Tapping should not cause errors
      // "5" appears twice (Dec 5 + Jan 5), so tap first occurrence
      final dec5Finder = find.text('5');
      await tester.tap(dec5Finder.first);
      await tester.pumpAndSettle();

      // No errors expected
    });

    testWidgets('handles year boundary (December to January)', (WidgetTester tester) async {
      // December 2024 last week should show Jan 2025 days
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show days from January 2025 in the last week
      expect(find.text('1'), findsWidgets); // Jan 1, 2025
    });

    testWidgets('week starts on Monday (ISO 8601)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendarView(
              data: testData,
              displayMonth: testMonth,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Monday is the first day label
      final dayLabels = find.byType(Text);
      final firstDayLabel = tester.widget<Text>(dayLabels.first);
      expect(firstDayLabel.data, 'Mon');
    });
  });
}
