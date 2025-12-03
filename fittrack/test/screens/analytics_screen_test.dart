import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/analytics/analytics_screen.dart';
import 'package:fittrack/screens/analytics/components/activity_heatmap_section.dart';
import 'package:fittrack/screens/analytics/components/key_statistics_section.dart';
import 'package:fittrack/screens/analytics/components/charts_section.dart';
import 'package:fittrack/screens/analytics/components/dynamic_heatmap_calendar.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';

import 'analytics_screen_test.mocks.dart';

@GenerateMocks([ProgramProvider, app_auth.AuthProvider])
void main() {
  group('AnalyticsScreen', () {
    late MockProgramProvider mockProvider;
    late MockAuthProvider mockAuthProvider;
    late ActivityHeatmapData mockHeatmapData;
    late WorkoutAnalytics mockAnalytics;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      mockProvider = MockProgramProvider();
      mockAuthProvider = MockAuthProvider();

      // Create simple mock data objects
      mockHeatmapData = ActivityHeatmapData(
        userId: 'test-user',
        year: DateTime.now().year,
        dailySetCounts: {}, // Changed from 'days' to 'dailySetCounts'
        totalSets: 30,
        currentStreak: 3,
        longestStreak: 5,
      );

      mockAnalytics = WorkoutAnalytics(
        userId: 'test-user',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        totalWorkouts: 10,
        totalSets: 50,
        totalVolume: 1000,
        totalDuration: 3600, // Changed from averageWorkoutDuration to totalDuration (in seconds)
        exerciseTypeBreakdown: {}, // Changed from exerciseBreakdown to exerciseTypeBreakdown
        completedWorkoutIds: [], // Added required field
      );

      // Default mock responses
      when(mockProvider.isLoadingAnalytics).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.currentAnalytics).thenReturn(null);
      when(mockProvider.heatmapData).thenReturn(null);
      when(mockProvider.keyStatistics).thenReturn(null);
      when(mockProvider.recentPRs).thenReturn([]);
      when(mockProvider.loadAnalytics()).thenAnswer((_) async {});
      when(mockProvider.refreshAnalytics()).thenAnswer((_) async {});

      // Heatmap-related mocks
      when(mockProvider.selectedHeatmapTimeframe).thenReturn(HeatmapTimeframe.thisYear);
      when(mockProvider.selectedHeatmapProgramId).thenReturn(null);
      when(mockProvider.programs).thenReturn([]);
      when(mockProvider.setHeatmapTimeframe(any)).thenAnswer((_) async {});
      when(mockProvider.setHeatmapProgramFilter(any)).thenAnswer((_) async {});

      // Set up auth provider mocks to prevent Firebase calls
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
    });

    Widget createTestApp({MockProgramProvider? provider}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ProgramProvider>.value(value: provider ?? mockProvider),
            ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
          ],
          child: const AnalyticsScreen(),
        ),
      );
    }

    group('Loading States', () {
      testWidgets('displays loading indicator when analytics are loading', (tester) async {
        // Arrange
        when(mockProvider.isLoadingAnalytics).thenReturn(true);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading analytics...'), findsOneWidget);
      });

      testWidgets('analytics data loads from provider', (tester) async {
        // Arrange - Set up mock to return analytics data
        when(mockProvider.isLoadingAnalytics).thenReturn(false);
        when(mockProvider.error).thenReturn(null);
        when(mockProvider.heatmapData).thenReturn(mockHeatmapData);
        when(mockProvider.currentAnalytics).thenReturn(mockAnalytics);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Assert - Screen displays data from provider (auto-loaded by provider, not by screen)
        expect(find.byType(ActivityHeatmapSection), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('displays error when analytics fail to load', (tester) async {
        // Arrange
        when(mockProvider.error).thenReturn('Failed to load analytics data');

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Now using ErrorDisplay widget
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Unable to load analytics data. Please check your connection and try again.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Try Again'), findsOneWidget);
      });

      testWidgets('retry button calls loadAnalytics', (tester) async {
        // Arrange
        when(mockProvider.error).thenReturn('Network error');

        // Act
        await tester.pumpWidget(createTestApp());

        // Clear auto-load interactions before testing retry button
        clearInteractions(mockProvider);

        await tester.tap(find.text('Try Again'));
        await tester.pump();

        // Assert - Should be called once after clearing interactions
        verify(mockProvider.loadAnalytics()).called(1);
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no data available', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.text('No Data Available'), findsOneWidget);
        expect(find.text('Start tracking workouts to see your analytics'), findsOneWidget);
        expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
        expect(find.text('Use the Programs tab to start tracking workouts'), findsOneWidget);
      });
    });

    group('Theme Support', () {
      testWidgets('respects dark theme setting', (tester) async {
        // Arrange - wrap in dark theme
        final darkThemeApp = MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
              ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const AnalyticsScreen(),
          ),
        );

        // Act
        await tester.pumpWidget(darkThemeApp);
        await tester.pumpAndSettle();

        // Assert - verify scaffold uses dark theme
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness, Brightness.dark);
      });

      testWidgets('respects light theme setting', (tester) async {
        // Arrange - wrap in light theme
        final lightThemeApp = MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
              ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const AnalyticsScreen(),
          ),
        );

        // Act
        await tester.pumpWidget(lightThemeApp);
        await tester.pumpAndSettle();

        // Assert - verify scaffold uses light theme
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness, Brightness.light);
      });
    });

    group('AppBar', () {
      testWidgets('displays correct title and actions', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.text('Analytics'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.date_range), findsOneWidget);
      });

      testWidgets('refresh button calls refreshAnalytics', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Assert
        verify(mockProvider.refreshAnalytics()).called(1);
      });

      testWidgets('date range menu shows options', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.byIcon(Icons.date_range));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('This Week'), findsOneWidget);
        expect(find.text('This Month'), findsOneWidget);
        expect(find.text('Last 30 Days'), findsOneWidget);
        expect(find.text('This Year'), findsOneWidget);
      });

      testWidgets('selecting date range calls loadAnalytics with range', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Reset mock after initial load
        clearInteractions(mockProvider);

        await tester.tap(find.byIcon(Icons.date_range));
        await tester.pumpAndSettle();
        await tester.tap(find.text('This Month'));
        await tester.pumpAndSettle();

        // Assert - should be called once after reset
        verify(mockProvider.loadAnalytics(dateRange: anyNamed('dateRange'))).called(1);
      });
    });

    group('Data Display', () {
      testWidgets('displays analytics components when data is available', (tester) async {
        // Arrange
        final mockAnalytics = WorkoutAnalytics(
          userId: 'test_user',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
          totalWorkouts: 10,
          totalSets: 50,
          totalVolume: 5000.0,
          totalDuration: 3600,
          exerciseTypeBreakdown: {ExerciseType.strength: 5},
          completedWorkoutIds: ['w1', 'w2'],
        );

        final mockHeatmapData = ActivityHeatmapData(
          userId: 'test_user',
          year: 2024,
          dailySetCounts: {DateTime(2024, 1, 1): 1},
          currentStreak: 5,
          longestStreak: 10,
          totalSets: 10,
        );

        final mockStats = {
          'totalWorkouts': 10,
          'totalSets': 50,
          'totalVolume': 5000.0,
        };

        when(mockProvider.currentAnalytics).thenReturn(mockAnalytics);
        when(mockProvider.heatmapData).thenReturn(mockHeatmapData);
        when(mockProvider.keyStatistics).thenReturn(mockStats);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.byType(ActivityHeatmapSection), findsOneWidget);
        expect(find.byType(KeyStatisticsSection), findsOneWidget);
        expect(find.byType(ChartsSection), findsOneWidget);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('pull to refresh calls refreshAnalytics', (tester) async {
        // Arrange
        when(mockProvider.heatmapData).thenReturn(ActivityHeatmapData(
          userId: 'test_user',
          year: 2024,
          dailySetCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalSets: 0,
        ));

        // Act
        await tester.pumpWidget(createTestApp());

        // Reset mock after initial load
        clearInteractions(mockProvider);

        await tester.fling(find.byType(SingleChildScrollView).first, const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1)); // Allow refresh to complete

        // Assert - should be called once after reset
        verify(mockProvider.refreshAnalytics()).called(1);
      });
    });
  });
}