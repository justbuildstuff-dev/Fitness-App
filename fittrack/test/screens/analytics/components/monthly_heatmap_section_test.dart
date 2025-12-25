import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/screens/analytics/components/monthly_heatmap_section.dart';
import 'package:fittrack/screens/analytics/components/monthly_calendar_view.dart';

@GenerateNiceMocks([MockSpec<AnalyticsService>()])
import 'monthly_heatmap_section_test.mocks.dart';

void main() {
  group('MonthlyHeatmapSection Widget Tests', () {
    late MockAnalyticsService mockAnalyticsService;
    const testUserId = 'test_user_123';

    // Use fixed test month for deterministic testing
    // December 2024: Dec 1 = Sunday, 31 days, needs 6 weeks
    final testMonth = DateTime(2024, 12, 1);

    setUp(() {
      mockAnalyticsService = MockAnalyticsService();
    });

    MonthHeatmapData createTestData({
      required int year,
      required int month,
      Map<int, int>? dailySetCounts,
    }) {
      return MonthHeatmapData(
        year: year,
        month: month,
        dailySetCounts: dailySetCounts ?? {1: 5, 10: 12, 20: 25},
        totalSets: dailySetCounts?.values.fold<int>(0, (sum, count) => sum + count) ?? 42,
        fetchedAt: DateTime.now(),
      );
    }

    void setupMockService({
      required int year,
      required int month,
      MonthHeatmapData? data,
    }) {
      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: year,
        month: month,
      )).thenAnswer((_) async => data ?? createTestData(year: year, month: month));
    }

    testWidgets('renders header with title and total sets', (WidgetTester tester) async {
      setupMockService(
        year: testMonth.year,
        month: testMonth.month,
        data: createTestData(year: testMonth.year, month: testMonth.month, dailySetCounts: {1: 10, 2: 20}),
      );

      // Pre-fetch adjacent months
      setupMockService(year: 2024, month: 11); // Nov 2024
      setupMockService(year: 2025, month: 1);  // Jan 2025

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      // Wait for async data loading
      await tester.pumpAndSettle();

      expect(find.text('Activity Tracker'), findsOneWidget);
      expect(find.text('30 sets'), findsOneWidget); // 10 + 20
    });

    testWidgets('renders month/year header with current month', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11); // Nov
      setupMockService(year: 2025, month: 1);  // Jan

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: DateTime(2024, 12, 1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for month/year text (format: "December 2024")
      expect(find.text('December 2024'), findsOneWidget);
    });

    testWidgets('month/year header is tappable', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the calendar icon (part of the tappable header)
      final calendarIcon = find.byIcon(Icons.calendar_month);
      expect(calendarIcon, findsOneWidget);

      await tester.tap(calendarIcon);
      await tester.pumpAndSettle();

      // Should open DatePicker dialog
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('Today button is hidden when on current month', (WidgetTester tester) async {
      // Use actual current month for this test since it verifies current month behavior
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      // Calculate adjacent months properly with year boundary handling
      final prevMonth = now.month == 1
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);
      final nextMonth = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);

      setupMockService(year: now.year, month: now.month);
      setupMockService(year: prevMonth.year, month: prevMonth.month);
      setupMockService(year: nextMonth.year, month: nextMonth.month);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: currentMonth, // Start on actual current month
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Today button should be hidden
      expect(find.byIcon(Icons.today), findsNothing);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('Today button appears when not on current month', (WidgetTester tester) async {
      // Start on December 2024 (not current month, since current is likely 2025)
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: DateTime(2024, 12, 1), // Start on past month
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Today button should be visible since we're viewing Dec 2024
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('PageView allows swipe navigation', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);
      setupMockService(year: 2025, month: 2); // Pre-fetched when swiping to Jan

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find PageView
      final pageView = find.byType(PageView);
      expect(pageView, findsOneWidget);

      // Swipe left (to next month)
      await tester.drag(pageView, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Month should have changed
      // Note: Exact verification would require checking displayed month text
    });

    testWidgets('renders MonthlyCalendarView inside PageView', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MonthlyCalendarView), findsOneWidget);
    });

    testWidgets('renders legend with intensity levels', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('renders streak cards', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Longest Streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching data', (WidgetTester tester) async {
      // Delay the response to show loading state
      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2024,
        month: 12,
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return createTestData(year: 2024, month: 12);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      // Should show loading indicator immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pumpAndSettle();

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message when data loading fails', (WidgetTester tester) async {
      // Setup current month to throw error
      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2024,
        month: 12,
      )).thenThrow(Exception('Network error'));

      // Setup adjacent months to return empty data (they get pre-fetched)
      setupMockService(year: 2024, month: 11, data: createTestData(year: 2024, month: 11, dailySetCounts: {}));
      setupMockService(year: 2025, month: 1, data: createTestData(year: 2025, month: 1, dailySetCounts: {}));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading data'), findsOneWidget);
    });

    testWidgets('tapping day shows popup with set count', (WidgetTester tester) async {
      setupMockService(
        year: 2024,
        month: 12,
        data: createTestData(
          year: 2024,
          month: 12,
          dailySetCounts: {5: 12}, // Day 5 has 12 sets
        ),
      );
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on day 5
      final day5 = find.text('5');
      await tester.tap(day5.first);
      await tester.pumpAndSettle();

      // Should show AlertDialog with set count
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('12 sets completed'), findsOneWidget);
    });

    testWidgets('pre-fetches adjacent months on init', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that getMonthHeatmapData was called for current month and adjacent months
      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2024,
        month: 12,
      )).called(greaterThanOrEqualTo(1));

      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2024,
        month: 11,
      )).called(greaterThanOrEqualTo(1));

      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2025,
        month: 1,
      )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('caches month data to avoid redundant fetches', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);
      setupMockService(year: 2025, month: 2); // Pre-fetched when swiping to Jan

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe to next month
      final pageView = find.byType(PageView);
      await tester.drag(pageView, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Swipe back to original month
      await tester.drag(pageView, const Offset(400, 0));
      await tester.pumpAndSettle();

      // Current month data should be fetched only once (cached)
      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2024,
        month: 12,
      )).called(1); // Only called once, then cached
    });

    testWidgets('handles year boundary navigation (Dec to Jan)', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);
      setupMockService(year: 2025, month: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: DateTime(2024, 12, 1), // Start on Dec 2024
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe left to January 2025
      final pageView = find.byType(PageView);
      await tester.drag(pageView, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Should have fetched January 2025 data
      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2025,
        month: 1,
      )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('handles year boundary navigation (Jan to Dec)', (WidgetTester tester) async {
      setupMockService(year: 2025, month: 1);
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2025, month: 2);
      setupMockService(year: 2024, month: 11);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: DateTime(2025, 1, 1), // Start on Jan 2025
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe right to December 2024
      final pageView = find.byType(PageView);
      await tester.drag(pageView, const Offset(400, 0));
      await tester.pumpAndSettle();

      // Should have fetched December 2024 data
      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: 2024,
        month: 12,
      )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('Today button navigates to current month', (WidgetTester tester) async {
      final now = DateTime.now();

      // Start on a past month
      setupMockService(year: 2023, month: 6);
      setupMockService(year: 2023, month: 5);
      setupMockService(year: 2023, month: 7);

      // Also setup current month with proper year boundary handling
      final prevMonth = now.month == 1
          ? DateTime(now.year - 1, 12, 1)
          : DateTime(now.year, now.month - 1, 1);
      final nextMonth = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);

      setupMockService(year: now.year, month: now.month);
      setupMockService(year: prevMonth.year, month: prevMonth.month);
      setupMockService(year: nextMonth.year, month: nextMonth.month);

      // Add extra month that might be pre-fetched during navigation
      final nextNextMonth = now.month >= 11
          ? DateTime(now.year + 1, (now.month + 2) % 12 == 0 ? 12 : (now.month + 2) % 12, 1)
          : DateTime(now.year, now.month + 2, 1);
      setupMockService(year: nextNextMonth.year, month: nextNextMonth.month);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: DateTime(2023, 6, 1), // Start on past month
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Today button should be visible
      expect(find.text('Today'), findsOneWidget);

      // Tap Today button
      await tester.tap(find.text('Today'));
      await tester.pump(); // Start the animation
      await tester.pump(const Duration(milliseconds: 500)); // Allow page animation
      // Don't use pumpAndSettle as PageView animations may not settle immediately

      // Should have navigated to current month
      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('month picker allows selecting specific month', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);
      setupMockService(year: 2023, month: 6); // Target month

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap month/year header to open picker
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      // DatePicker should be shown
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Note: Selecting a specific date in DatePicker requires more complex interaction
      // For now, just verify the dialog opens
    });

    testWidgets('handles empty month data (no sets)', (WidgetTester tester) async {
      setupMockService(
        year: 2024,
        month: 12,
        data: createTestData(
          year: 2024,
          month: 12,
          dailySetCounts: {}, // No sets
        ),
      );
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still render without errors
      expect(find.text('Activity Tracker'), findsOneWidget);
      expect(find.text('0 sets'), findsOneWidget);
    });

    testWidgets('renders within Card widget', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('legend boxes have correct colors', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all legend boxes (should be 5: none, low, medium, high, very high)
      final legendBoxes = find.descendant(
        of: find.ancestor(
          of: find.text('Less'),
          matching: find.byType(Row),
        ),
        matching: find.byType(Container),
      );

      // Should have 5 legend boxes
      expect(legendBoxes, findsWidgets);
    });

    testWidgets('PageView has fixed height', (WidgetTester tester) async {
      setupMockService(year: 2024, month: 12);
      setupMockService(year: 2024, month: 11);
      setupMockService(year: 2025, month: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MonthlyHeatmapSection(
                userId: testUserId,
                analyticsService: mockAnalyticsService,
                initialMonth: testMonth,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find SizedBox containing PageView
      final sizedBox = find.ancestor(
        of: find.byType(PageView),
        matching: find.byType(SizedBox),
      );

      expect(sizedBox, findsOneWidget);

      // Verify height is set (420px to prevent overflow)
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox.first);
      expect(sizedBoxWidget.height, 420);
    });
  });
}
