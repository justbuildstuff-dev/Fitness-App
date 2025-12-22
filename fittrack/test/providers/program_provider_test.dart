import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/services/analytics_service.dart';

@GenerateMocks([FirestoreService, AnalyticsService])
import 'program_provider_test.mocks.dart';

void main() {
  group('ProgramProvider Analytics Tests', () {
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;
    const testUserId = 'test_user_123';

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();

      // Stub Firestore methods called by provider constructor during auto-load
      when(mockFirestoreService.getPrograms(testUserId))
        .thenAnswer((_) => Stream.value([]));
    });

    MonthHeatmapData createTestMonthData({
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

    WorkoutAnalytics createTestAnalytics() {
      return WorkoutAnalytics(
        userId: testUserId,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        totalWorkouts: 10,
        totalSets: 100,
        totalVolume: 5000,
        totalDuration: 2700, // 45 minutes in seconds
        exerciseTypeBreakdown: {ExerciseType.strength: 5, ExerciseType.cardio: 3},
        completedWorkoutIds: ['w1', 'w2', 'w3'],
      );
    }

    ActivityHeatmapData createTestHeatmapData() {
      return ActivityHeatmapData(
        userId: testUserId,
        year: 2024,
        dailySetCounts: {DateTime(2024, 12, 1): 5, DateTime(2024, 12, 15): 10},
        currentStreak: 3,
        longestStreak: 7,
        totalSets: 15,
      );
    }

    test('loadAnalytics fetches current month heatmap data', () async {
      final now = DateTime.now();
      final monthData = createTestMonthData(year: now.year, month: now.month);

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).thenAnswer((_) async => monthData);

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Wait for auto-load to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.monthHeatmapData, isNotNull);
      expect(provider.monthHeatmapData?.year, now.year);
      expect(provider.monthHeatmapData?.month, now.month);

      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).called(1);
    });

    test('loadAnalytics pre-fetches adjacent months', () async {
      final now = DateTime.now();

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => createTestMonthData(year: now.year, month: now.month));

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Wait for auto-load
      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).called(1);
    });

    test('loadAnalytics loads other analytics data', () async {
      final now = DateTime.now();

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => createTestMonthData(year: now.year, month: now.month));

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{'total_volume': 5000});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Wait for auto-load
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.currentAnalytics, isNotNull);
      expect(provider.heatmapData, isNotNull);
      expect(provider.recentPRs, isNotNull);
      expect(provider.keyStatistics, isNotNull);
      expect(provider.keyStatistics?['total_volume'], 5000);
    });

    test('loadAnalytics sets loading state correctly', () async {
      final now = DateTime.now();

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return createTestMonthData(year: now.year, month: now.month);
      });

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Initially should be loading
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.isLoadingAnalytics, isTrue);

      // After completion should not be loading
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.isLoadingAnalytics, isFalse);
    });

    test('loadAnalytics handles errors gracefully', () async {
      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenThrow(Exception('Network error'));

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Wait for auto-load to attempt and fail
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isLoadingAnalytics, isFalse);
      expect(provider.error, contains('Failed to load analytics'));
    });

    test('loadAnalytics uses current year date range by default', () async {
      final now = DateTime.now();

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => createTestMonthData(year: now.year, month: now.month));

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify that analytics are computed with a date range
      final capturedAnalytics = verify(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: captureAnyNamed('dateRange'),
      )).captured;

      expect(capturedAnalytics, isNotEmpty);
      final dateRange = capturedAnalytics.first as DateRange;
      expect(dateRange.start.year, now.year);
      expect(dateRange.start.month, 1);
      expect(dateRange.start.day, 1);
    });

    test('refreshAnalytics clears cache and reloads', () async {
      final now = DateTime.now();

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => createTestMonthData(year: now.year, month: now.month));

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      when(mockAnalyticsService.clearCache()).thenReturn(null);

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      await provider.refreshAnalytics();

      verify(mockAnalyticsService.clearCache()).called(1);
      // getMonthHeatmapData should be called twice: auto-load + refresh
      verify(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: now.year,
        month: now.month,
      )).called(2);
    });

    test('monthHeatmapData getter returns current month data', () async {
      final now = DateTime.now();
      final monthData = createTestMonthData(
        year: now.year,
        month: now.month,
        dailySetCounts: {1: 10, 15: 20},
      );

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => monthData);

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.monthHeatmapData, isNotNull);
      expect(provider.monthHeatmapData?.year, now.year);
      expect(provider.monthHeatmapData?.month, now.month);
      expect(provider.monthHeatmapData?.dailySetCounts[1], 10);
      expect(provider.monthHeatmapData?.dailySetCounts[15], 20);
      expect(provider.monthHeatmapData?.totalSets, 30);
    });

    test('loadAnalytics skips when userId is null', () async {
      final provider = ProgramProvider.withServices(
        null,
        mockFirestoreService,
        mockAnalyticsService,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Should not call any analytics methods when userId is null
      verifyNever(mockAnalyticsService.getMonthHeatmapData(
        userId: anyNamed('userId'),
        year: anyNamed('year'),
        month: anyNamed('month'),
      ));
    });

    test('loadAnalytics loads data concurrently for performance', () async {
      final now = DateTime.now();
      final startTime = DateTime.now();

      // Each method takes 50ms
      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return createTestMonthData(year: now.year, month: now.month);
      });

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return;
      });

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return createTestAnalytics();
      });

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return createTestHeatmapData();
      });

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return <PersonalRecord>[];
      });

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return <String, dynamic>{};
      });

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      await Future.delayed(const Duration(milliseconds: 200));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // If running concurrently, should take ~50ms (not 300ms sequential)
      // Allow some buffer for test execution
      expect(duration, lessThan(200),
          reason: 'Analytics should load concurrently');
    });

    test('loadAnalytics with custom dateRange uses provided range', () async {
      final now = DateTime.now();
      final customRange = DateRange(
        start: DateTime(2023, 1, 1),
        end: DateTime(2023, 12, 31),
      );

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => createTestMonthData(year: now.year, month: now.month));

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: testUserId,
        year: anyNamed('year'),
        month: anyNamed('month'),
      )).thenAnswer((_) async => null);

      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestAnalytics());

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => createTestHeatmapData());

      when(mockAnalyticsService.getPersonalRecords(
        userId: testUserId,
        limit: 10,
      )).thenAnswer((_) async => <PersonalRecord>[]);

      when(mockAnalyticsService.computeKeyStatistics(
        userId: testUserId,
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => <String, dynamic>{});

      final provider = ProgramProvider.withServices(
        testUserId,
        mockFirestoreService,
        mockAnalyticsService,
      );

      // Clear auto-load calls
      await Future.delayed(const Duration(milliseconds: 100));
      clearInteractions(mockAnalyticsService);

      // Call loadAnalytics with custom date range
      await provider.loadAnalytics(dateRange: customRange);

      // Verify custom date range was used
      final captured = verify(mockAnalyticsService.computeWorkoutAnalytics(
        userId: testUserId,
        dateRange: captureAnyNamed('dateRange'),
      )).captured;

      expect(captured, isNotEmpty);
      final usedRange = captured.first as DateRange;
      expect(usedRange.start, customRange.start);
      expect(usedRange.end, customRange.end);
    });
  });
}
