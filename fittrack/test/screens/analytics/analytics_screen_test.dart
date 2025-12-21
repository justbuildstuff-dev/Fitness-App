import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/analytics/analytics_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/screens/analytics/components/monthly_heatmap_section.dart';
import 'package:fittrack/screens/analytics/components/key_statistics_section.dart';
import 'package:fittrack/screens/analytics/components/charts_section.dart';

import 'analytics_screen_test.mocks.dart';

@GenerateMocks([ProgramProvider])
void main() {
  late MockProgramProvider mockProvider;

  setUp(() {
    mockProvider = MockProgramProvider();

    // Default setup: no data, not loading, no error
    when(mockProvider.isLoadingAnalytics).thenReturn(false);
    when(mockProvider.error).thenReturn(null);
    when(mockProvider.monthHeatmapData).thenReturn(null);
    when(mockProvider.currentAnalytics).thenReturn(null);
    when(mockProvider.keyStatistics).thenReturn(null);
    when(mockProvider.recentPRs).thenReturn(null);
    when(mockProvider.userId).thenReturn('test-user-id');
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<ProgramProvider>.value(
        value: mockProvider,
        child: const AnalyticsScreen(),
      ),
    );
  }

  group('AnalyticsScreen - Loading States', () {
    testWidgets('shows loading indicator when analytics are loading', (WidgetTester tester) async {
      when(mockProvider.isLoadingAnalytics).thenReturn(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading analytics...'), findsOneWidget);
    });

    testWidgets('shows error display when error occurs', (WidgetTester tester) async {
      when(mockProvider.error).thenReturn('Test error message');

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Unable to load analytics data. Please check your connection and try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows no data message when no analytics available', (WidgetTester tester) async {
      // Default mock already has no data

      await tester.pumpWidget(createTestWidget());

      expect(find.text('No Data Available'), findsOneWidget);
      expect(find.text('Start tracking workouts to see your analytics'), findsOneWidget);
      expect(find.text('Use the Programs tab to start tracking workouts'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });
  });

  group('AnalyticsScreen - MonthlyHeatmapSection Integration', () {
    testWidgets('displays MonthlyHeatmapSection when month data is available', (WidgetTester tester) async {
      final testMonthData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {1: 5, 10: 12, 20: 25},
        totalSets: 42,
        fetchedAt: DateTime.now(),
      );

      when(mockProvider.monthHeatmapData).thenReturn(testMonthData);
      when(mockProvider.userId).thenReturn('test-user-id');

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(MonthlyHeatmapSection), findsOneWidget);
    });

    testWidgets('does not display MonthlyHeatmapSection when userId is null', (WidgetTester tester) async {
      final testMonthData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {1: 5},
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      when(mockProvider.monthHeatmapData).thenReturn(testMonthData);
      when(mockProvider.userId).thenReturn(null);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(MonthlyHeatmapSection), findsNothing);
    });

    testWidgets('does not display MonthlyHeatmapSection when month data is null', (WidgetTester tester) async {
      when(mockProvider.monthHeatmapData).thenReturn(null);
      when(mockProvider.userId).thenReturn('test-user-id');

      // Provide other data so we don't show "No Data Available" screen
      when(mockProvider.currentAnalytics).thenReturn(
        WorkoutAnalytics(
          userId: 'test-user-id',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
          totalWorkouts: 10,
          totalSets: 100,
          totalVolume: 5000,
          totalDuration: 2700,
          exerciseTypeBreakdown: {ExerciseType.strength: 5},
          completedWorkoutIds: ['w1', 'w2'],
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(MonthlyHeatmapSection), findsNothing);
    });
  });

  group('AnalyticsScreen - Other Sections', () {
    testWidgets('displays KeyStatisticsSection when statistics are available', (WidgetTester tester) async {
      when(mockProvider.keyStatistics).thenReturn({
        'totalWorkouts': 50,
        'totalVolume': 10000,
        'averageDuration': 45,
      });

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(KeyStatisticsSection), findsOneWidget);
    });

    testWidgets('displays ChartsSection when analytics or PRs are available', (WidgetTester tester) async {
      when(mockProvider.currentAnalytics).thenReturn(
        WorkoutAnalytics(
          userId: 'test-user-id',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
          totalWorkouts: 10,
          totalSets: 100,
          totalVolume: 5000,
          totalDuration: 2700,
          exerciseTypeBreakdown: {ExerciseType.strength: 5},
          completedWorkoutIds: ['w1'],
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(ChartsSection), findsOneWidget);
    });

    testWidgets('displays all sections when all data is available', (WidgetTester tester) async {
      final testMonthData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {1: 5, 10: 12},
        totalSets: 17,
        fetchedAt: DateTime.now(),
      );

      when(mockProvider.monthHeatmapData).thenReturn(testMonthData);
      when(mockProvider.userId).thenReturn('test-user-id');
      when(mockProvider.keyStatistics).thenReturn({'totalWorkouts': 50});
      when(mockProvider.currentAnalytics).thenReturn(
        WorkoutAnalytics(
          userId: 'test-user-id',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
          totalWorkouts: 10,
          totalSets: 100,
          totalVolume: 5000,
          totalDuration: 2700,
          exerciseTypeBreakdown: {ExerciseType.strength: 5},
          completedWorkoutIds: ['w1'],
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(MonthlyHeatmapSection), findsOneWidget);
      expect(find.byType(KeyStatisticsSection), findsOneWidget);
      expect(find.byType(ChartsSection), findsOneWidget);
    });
  });

  group('AnalyticsScreen - User Interactions', () {
    testWidgets('refresh button calls refreshAnalytics', (WidgetTester tester) async {
      final testMonthData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {1: 5},
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      when(mockProvider.monthHeatmapData).thenReturn(testMonthData);
      when(mockProvider.userId).thenReturn('test-user-id');
      when(mockProvider.refreshAnalytics()).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());

      // Find and tap refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      verify(mockProvider.refreshAnalytics()).called(1);
    });

    testWidgets('pull to refresh calls refreshAnalytics', (WidgetTester tester) async {
      final testMonthData = MonthHeatmapData(
        year: 2024,
        month: 12,
        dailySetCounts: {1: 5},
        totalSets: 5,
        fetchedAt: DateTime.now(),
      );

      when(mockProvider.monthHeatmapData).thenReturn(testMonthData);
      when(mockProvider.userId).thenReturn('test-user-id');
      when(mockProvider.refreshAnalytics()).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());

      // Simulate pull to refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Wait for refresh

      verify(mockProvider.refreshAnalytics()).called(1);
    });

    testWidgets('retry button on error clears error and reloads analytics', (WidgetTester tester) async {
      when(mockProvider.error).thenReturn('Test error');
      when(mockProvider.clearError()).thenAnswer((_) => Future.value());
      when(mockProvider.loadAnalytics()).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());

      // Find and tap retry button
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      verify(mockProvider.clearError()).called(1);
      verify(mockProvider.loadAnalytics()).called(1);
    });
  });

  group('AnalyticsScreen - AppBar', () {
    testWidgets('displays correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('has refresh button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final refreshButton = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.refresh),
      );
      expect(refreshButton, findsOneWidget);
    });
  });
}
