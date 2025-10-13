import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/analytics/analytics_screen.dart';
import 'package:fittrack/screens/analytics/components/activity_heatmap_section.dart';
import 'package:fittrack/screens/analytics/components/key_statistics_section.dart';
import 'package:fittrack/screens/analytics/components/charts_section.dart';
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

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      mockProvider = MockProgramProvider();
      mockAuthProvider = MockAuthProvider();
      
      // Default mock responses
      when(mockProvider.isLoadingAnalytics).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.currentAnalytics).thenReturn(null);
      when(mockProvider.heatmapData).thenReturn(null);
      when(mockProvider.keyStatistics).thenReturn(null);
      when(mockProvider.recentPRs).thenReturn([]);
      when(mockProvider.loadAnalytics()).thenAnswer((_) async {});
      when(mockProvider.refreshAnalytics()).thenAnswer((_) async {});
      
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

      testWidgets('calls loadAnalytics on init', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Assert
        verify(mockProvider.loadAnalytics()).called(1);
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
        await tester.tap(find.text('Try Again'));
        await tester.pump();

        // Assert
        verify(mockProvider.loadAnalytics()).called(2); // Once on init, once on retry
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
          dailyWorkoutCounts: {DateTime(2024, 1, 1): 1},
          currentStreak: 5,
          longestStreak: 10,
          totalWorkouts: 10,
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
          dailyWorkoutCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalWorkouts: 0,
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

  group('ActivityHeatmapSection', () {
    testWidgets('displays heatmap data correctly', (tester) async {
      // Arrange
      final heatmapData = ActivityHeatmapData(
        userId: 'test_user',
        year: 2024,
        dailyWorkoutCounts: {
          DateTime(2024, 1, 1): 1,
          DateTime(2024, 1, 2): 2,
        },
        currentStreak: 5,
        longestStreak: 15,
        totalWorkouts: 50,
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActivityHeatmapSection(data: heatmapData),
        ),
      ));

      // Assert
      expect(find.text('2024 Activity'), findsOneWidget);
      expect(find.text('50 workouts'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
      expect(find.text('Longest Streak'), findsOneWidget);
      expect(find.text('15 days'), findsOneWidget);
    });

    testWidgets('displays heatmap calendar', (tester) async {
      // Arrange
      final heatmapData = ActivityHeatmapData(
        userId: 'test_user',
        year: 2024,
        dailyWorkoutCounts: {DateTime(2024, 1, 1): 1},
        currentStreak: 0,
        longestStreak: 0,
        totalWorkouts: 1,
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ActivityHeatmapSection(data: heatmapData),
        ),
      ));

      // Assert
      expect(find.byType(HeatmapCalendar), findsOneWidget);
      
      // Check for month labels
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
    });
  });

  group('KeyStatisticsSection', () {
    testWidgets('displays statistics cards correctly', (tester) async {
      // Arrange
      final statistics = {
        'totalWorkouts': 25,
        'totalSets': 150,
        'totalVolume': 7500.0,
        'averageDuration': 45.0,
        'newPRs': 3,
        'mostUsedExerciseType': 'Strength',
        'completionPercentage': 92.5,
        'workoutsPerWeek': 4.2,
      };

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: KeyStatisticsSection(statistics: statistics),
        ),
      ));

      // Assert
      expect(find.text('Key Statistics'), findsOneWidget);
      expect(find.text('25'), findsOneWidget); // totalWorkouts
      expect(find.text('150'), findsOneWidget); // totalSets
      expect(find.text('7.5k'), findsOneWidget); // totalVolume formatted
      expect(find.text('45m'), findsOneWidget); // averageDuration formatted
      expect(find.text('3'), findsOneWidget); // newPRs
      expect(find.text('Strength'), findsOneWidget); // mostUsedExerciseType
      expect(find.text('92%'), findsOneWidget); // completionPercentage
      expect(find.text('4.2'), findsOneWidget); // workoutsPerWeek
    });

    testWidgets('handles large numbers formatting', (tester) async {
      // Arrange
      final statistics = {
        'totalWorkouts': 1000,
        'totalSets': 5000,
        'totalVolume': 1500000.0, // Should format to 1.5M
        'averageDuration': 125.7, // Should format to 125m 42s (125 + 0.7*60)
      };

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: KeyStatisticsSection(statistics: statistics),
        ),
      ));

      // Assert
      expect(find.text('1.5M'), findsOneWidget);
      expect(find.text('125m 42s'), findsOneWidget);
    });
  });

  group('ChartsSection', () {
    testWidgets('displays charts when analytics data is available', (tester) async {
      // Arrange
      final analytics = WorkoutAnalytics(
        userId: 'test_user',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        totalWorkouts: 10,
        totalSets: 50,
        totalVolume: 5000.0,
        totalDuration: 3600,
        exerciseTypeBreakdown: {
          ExerciseType.strength: 5,
          ExerciseType.cardio: 3,
          ExerciseType.bodyweight: 2,
        },
        completedWorkoutIds: [],
      );

      final personalRecords = [
        PersonalRecord(
          id: 'pr1',
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          prType: PRType.maxWeight,
          value: 100.0,
          previousValue: 95.0,
          achievedAt: DateTime.now(),
          workoutId: 'w1',
          setId: 's1',
        ),
      ];

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ChartsSection(
            analytics: analytics,
            personalRecords: personalRecords,
          ),
        ),
      ));

      // Assert
      expect(find.text('Detailed Analytics'), findsOneWidget);
      expect(find.text('Exercise Type Breakdown'), findsOneWidget);
      expect(find.text('Recent Personal Records'), findsOneWidget);
      expect(find.text('1 PR'), findsOneWidget);
    });

    testWidgets('displays empty state when no data', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ChartsSection(
            analytics: null,
            personalRecords: [],
          ),
        ),
      ));

      // Assert
      expect(find.text('No Personal Records Yet'), findsOneWidget);
      expect(find.text('Keep training to set new records!'), findsOneWidget);
    });
  });
}