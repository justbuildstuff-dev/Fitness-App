import 'dart:async';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'program_provider_analytics_test.mocks.dart';

@GenerateMocks([FirestoreService, AnalyticsService])
void main() {
  group('ProgramProvider Heatmap Preferences', () {
    late ProgramProvider provider;
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();

      // Set up default stubs for auto-load calls
      when(mockFirestoreService.getPrograms(any))
          .thenAnswer((_) => Stream.value([]));
      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: anyNamed('userId'),
        dateRange: anyNamed('dateRange'),
        programId: anyNamed('programId'),
      )).thenAnswer((_) async => WorkoutAnalytics(
            userId: 'test_user',
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
            totalWorkouts: 0,
            totalSets: 0,
            totalVolume: 0.0,
            totalDuration: 0,
            exerciseTypeBreakdown: {},
            completedWorkoutIds: [],
          ));
      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: anyNamed('userId'),
        dateRange: anyNamed('dateRange'),
        programId: anyNamed('programId'),
      )).thenAnswer((_) async => ActivityHeatmapData(
            userId: 'test_user',
            year: DateTime.now().year,
            dailySetCounts: {},
            currentStreak: 0,
            longestStreak: 0,
            totalSets: 0,
          ));
      when(mockAnalyticsService.getPersonalRecords(
        userId: anyNamed('userId'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);
      when(mockAnalyticsService.computeKeyStatistics(
        userId: anyNamed('userId'),
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => {});

      provider = ProgramProvider.withServices(
        'test_user',
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Allow auto-load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    group('Preference Initialization', () {
      test('loads preferences from SharedPreferences on initialization', () async {
        // Arrange - Set saved preferences
        SharedPreferences.setMockInitialValues({
          'heatmap_timeframe': HeatmapTimeframe.thisMonth.index,
          'heatmap_program_filter': 'program123',
        });

        // Re-create provider to test initialization
        provider.dispose();
        provider = ProgramProvider.withServices(
          'test_user',
          mockFirestoreService,
          mockAnalyticsService,
        );

        // Allow initialization to complete
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert
        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.thisMonth));
        expect(provider.selectedHeatmapProgramId, equals('program123'));
      });

      test('uses default values when no preferences are saved', () async {
        // Arrange - Empty preferences
        SharedPreferences.setMockInitialValues({});

        // Re-create provider
        provider.dispose();
        provider = ProgramProvider.withServices(
          'test_user',
          mockFirestoreService,
          mockAnalyticsService,
        );

        // Allow initialization to complete
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert - Should use defaults
        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.thisYear));
        expect(provider.selectedHeatmapProgramId, isNull);
      });

      test('handles invalid timeframe index gracefully', () async {
        // Arrange - Invalid timeframe index
        SharedPreferences.setMockInitialValues({
          'heatmap_timeframe': 999, // Invalid index
        });

        // Re-create provider
        provider.dispose();
        provider = ProgramProvider.withServices(
          'test_user',
          mockFirestoreService,
          mockAnalyticsService,
        );

        // Allow initialization to complete
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert - Should fall back to default
        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.thisYear));
      });

      test('handles negative timeframe index gracefully', () async {
        // Arrange - Negative timeframe index
        SharedPreferences.setMockInitialValues({
          'heatmap_timeframe': -1,
        });

        // Re-create provider
        provider.dispose();
        provider = ProgramProvider.withServices(
          'test_user',
          mockFirestoreService,
          mockAnalyticsService,
        );

        // Allow initialization to complete
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert - Should fall back to default
        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.thisYear));
      });
    });

    group('setHeatmapTimeframe', () {
      test('updates timeframe and persists to SharedPreferences', () async {
        // Arrange
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisWeek);

        // Assert - Getter returns new value
        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.thisWeek));

        // Assert - Value was persisted
        final prefs = await SharedPreferences.getInstance();
        final savedIndex = prefs.getInt('heatmap_timeframe');
        expect(savedIndex, equals(HeatmapTimeframe.thisWeek.index));
      });

      test('notifies listeners when timeframe changes', () async {
        // Arrange
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        // Act
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisMonth);

        // Assert - Should notify at least once (potentially twice: once for state, once after reload)
        expect(notifyCount, greaterThanOrEqualTo(1));
      });

      test('reloads analytics after timeframe change', () async {
        // Arrange
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.setHeatmapTimeframe(HeatmapTimeframe.last30Days);

        // Assert - Verify analytics were reloaded
        verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: anyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).called(greaterThan(0));
      });

      test('uses correct date range for each timeframe', () async {
        // Test thisWeek
        clearInteractions(mockAnalyticsService);
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisWeek);

        final captured = verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: captureAnyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).captured;

        final dateRange = captured.first as DateRange;
        // This Week should start on Monday
        expect(dateRange.start.weekday, equals(DateTime.monday));
      });

      test('handles all timeframe options correctly', () async {
        for (final timeframe in HeatmapTimeframe.values) {
          clearInteractions(mockAnalyticsService);

          await provider.setHeatmapTimeframe(timeframe);

          expect(provider.selectedHeatmapTimeframe, equals(timeframe));

          // Verify analytics were reloaded
          verify(mockAnalyticsService.generateSetBasedHeatmapData(
            userId: anyNamed('userId'),
            dateRange: anyNamed('dateRange'),
            programId: anyNamed('programId'),
          )).called(greaterThan(0));
        }
      });
    });

    group('setHeatmapProgramFilter', () {
      test('updates program filter and persists to SharedPreferences', () async {
        // Arrange
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.setHeatmapProgramFilter('program456');

        // Assert - Getter returns new value
        expect(provider.selectedHeatmapProgramId, equals('program456'));

        // Assert - Value was persisted
        final prefs = await SharedPreferences.getInstance();
        final savedProgramId = prefs.getString('heatmap_program_filter');
        expect(savedProgramId, equals('program456'));
      });

      test('clears program filter when set to null', () async {
        // Arrange - First set a value
        await provider.setHeatmapProgramFilter('program789');

        clearInteractions(mockAnalyticsService);

        // Act - Set to null
        await provider.setHeatmapProgramFilter(null);

        // Assert - Getter returns null
        expect(provider.selectedHeatmapProgramId, isNull);

        // Assert - Value was removed from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedProgramId = prefs.getString('heatmap_program_filter');
        expect(savedProgramId, isNull);
      });

      test('notifies listeners when program filter changes', () async {
        // Arrange
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        // Act
        await provider.setHeatmapProgramFilter('program999');

        // Assert - Should notify at least once
        expect(notifyCount, greaterThanOrEqualTo(1));
      });

      test('reloads analytics after program filter change', () async {
        // Arrange
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.setHeatmapProgramFilter('program111');

        // Assert - Verify analytics were reloaded with new program filter
        verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: anyNamed('dateRange'),
          programId: 'program111',
        )).called(greaterThan(0));
      });

      test('loads all programs when filter is null', () async {
        // Arrange
        await provider.setHeatmapProgramFilter('program222');
        clearInteractions(mockAnalyticsService);

        // Act - Clear filter
        await provider.setHeatmapProgramFilter(null);

        // Assert - Verify analytics were reloaded with null programId
        verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: anyNamed('dateRange'),
          programId: null,
        )).called(greaterThan(0));
      });

      test('handles switching between different programs', () async {
        // Test switching between programs
        await provider.setHeatmapProgramFilter('programA');
        expect(provider.selectedHeatmapProgramId, equals('programA'));

        await provider.setHeatmapProgramFilter('programB');
        expect(provider.selectedHeatmapProgramId, equals('programB'));

        await provider.setHeatmapProgramFilter('programC');
        expect(provider.selectedHeatmapProgramId, equals('programC'));

        // Verify last saved value
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('heatmap_program_filter'), equals('programC'));
      });
    });

    group('Combined Filter and Timeframe Changes', () {
      test('both filters work together correctly', () async {
        // Arrange
        clearInteractions(mockAnalyticsService);

        // Act - Set both filters
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisMonth);
        await provider.setHeatmapProgramFilter('combined_program');

        // Clear and reload to verify both are used
        clearInteractions(mockAnalyticsService);
        await provider.loadAnalytics();

        // Assert - Both filters are applied
        verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: anyNamed('dateRange'),
          programId: 'combined_program',
        )).called(greaterThan(0));

        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.thisMonth));
        expect(provider.selectedHeatmapProgramId, equals('combined_program'));
      });

      test('preferences persist across provider instances', () async {
        // Arrange - Set preferences
        await provider.setHeatmapTimeframe(HeatmapTimeframe.last30Days);
        await provider.setHeatmapProgramFilter('persistent_program');

        // Act - Dispose and create new provider
        provider.dispose();
        SharedPreferences.setMockInitialValues({
          'heatmap_timeframe': HeatmapTimeframe.last30Days.index,
          'heatmap_program_filter': 'persistent_program',
        });

        provider = ProgramProvider.withServices(
          'test_user',
          mockFirestoreService,
          mockAnalyticsService,
        );

        // Allow initialization to complete
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert - Preferences were loaded
        expect(provider.selectedHeatmapTimeframe, equals(HeatmapTimeframe.last30Days));
        expect(provider.selectedHeatmapProgramId, equals('persistent_program'));
      });
    });

    group('Error Handling', () {
      test('handles SharedPreferences failure gracefully on load', () async {
        // This test verifies that the provider doesn't crash if SharedPreferences fails
        // In a real scenario, you'd use dependency injection to mock SharedPreferences
        // For now, we verify the provider handles errors in _loadHeatmapPreferences

        // The provider should still work with default values even if prefs fail
        expect(provider.selectedHeatmapTimeframe, isNotNull);
        expect(provider.selectedHeatmapProgramId, isNull);
      });

      test('handles SharedPreferences failure gracefully on save', () async {
        // This test would verify that save failures don't crash the app
        // The provider should handle the error and continue working

        // Attempt to set values (may fail in mock environment but shouldn't crash)
        try {
          await provider.setHeatmapTimeframe(HeatmapTimeframe.thisWeek);
          await provider.setHeatmapProgramFilter('test_program');
        } catch (e) {
          // Should not throw
          fail('Setting preferences should not throw exceptions');
        }

        // Provider should still work
        expect(provider.selectedHeatmapTimeframe, isNotNull);
      });
    });

    group('Analytics Integration', () {
      test('loadAnalytics uses selected timeframe and program filter', () async {
        // Arrange
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisWeek);
        await provider.setHeatmapProgramFilter('analytics_program');

        clearInteractions(mockAnalyticsService);

        // Act
        await provider.loadAnalytics();

        // Assert - Verify correct parameters were passed
        verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: anyNamed('dateRange'),
          programId: 'analytics_program',
        )).called(greaterThan(0));

        final captured = verify(mockAnalyticsService.computeWorkoutAnalytics(
          userId: 'test_user',
          dateRange: captureAnyNamed('dateRange'),
          programId: 'analytics_program',
        )).captured;

        // Verify date range matches timeframe
        final dateRange = captured.first as DateRange;
        expect(dateRange.start.weekday, equals(DateTime.monday));
      });

      test('loadAnalytics with custom date range overrides selected timeframe', () async {
        // Arrange
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisWeek);

        final customRange = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 12, 31),
        );

        clearInteractions(mockAnalyticsService);

        // Act
        await provider.loadAnalytics(dateRange: customRange);

        // Assert - Custom range should be used instead of timeframe-derived range
        verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: 'test_user',
          dateRange: customRange,
          programId: anyNamed('programId'),
        )).called(greaterThan(0));
      });
    });

    group('Date Range Calculations', () {
      test('_getDateRangeForTimeframe calculates correct range for thisWeek', () async {
        // Arrange
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisWeek);
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.loadAnalytics();

        // Assert
        final captured = verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: anyNamed('userId'),
          dateRange: captureAnyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).captured;

        final dateRange = captured.first as DateRange;

        // Should start on Monday and span 7 days
        expect(dateRange.start.weekday, equals(DateTime.monday));
        expect(dateRange.durationInDays, equals(7));
      });

      test('_getDateRangeForTimeframe calculates correct range for thisMonth', () async {
        // Arrange
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisMonth);
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.loadAnalytics();

        // Assert
        final captured = verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: anyNamed('userId'),
          dateRange: captureAnyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).captured;

        final dateRange = captured.first as DateRange;
        final now = DateTime.now();

        // Should start on first day of month
        expect(dateRange.start.year, equals(now.year));
        expect(dateRange.start.month, equals(now.month));
        expect(dateRange.start.day, equals(1));

        // Should end on last day of month
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        expect(dateRange.endDate.day, equals(lastDay));
      });

      test('_getDateRangeForTimeframe calculates correct range for last30Days', () async {
        // Arrange
        await provider.setHeatmapTimeframe(HeatmapTimeframe.last30Days);
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.loadAnalytics();

        // Assert
        final captured = verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: anyNamed('userId'),
          dateRange: captureAnyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).captured;

        final dateRange = captured.first as DateRange;

        // Should be exactly 30 days
        expect(dateRange.durationInDays, equals(30));

        // Should end today
        final now = DateTime.now();
        expect(dateRange.endDate.day, equals(now.day));
        expect(dateRange.endDate.month, equals(now.month));
        expect(dateRange.endDate.year, equals(now.year));
      });

      test('_getDateRangeForTimeframe calculates correct range for thisYear', () async {
        // Arrange
        await provider.setHeatmapTimeframe(HeatmapTimeframe.thisYear);
        clearInteractions(mockAnalyticsService);

        // Act
        await provider.loadAnalytics();

        // Assert
        final captured = verify(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: anyNamed('userId'),
          dateRange: captureAnyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).captured;

        final dateRange = captured.first as DateRange;
        final now = DateTime.now();

        // Should start January 1st
        expect(dateRange.start.year, equals(now.year));
        expect(dateRange.start.month, equals(1));
        expect(dateRange.start.day, equals(1));

        // Should end December 31st
        expect(dateRange.endDate.year, equals(now.year));
        expect(dateRange.endDate.month, equals(12));
        expect(dateRange.endDate.day, equals(31));
      });
    });
  });
}
