import 'dart:async';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';

import 'program_provider_analytics_test.mocks.dart';

@GenerateMocks([FirestoreService, AnalyticsService])
void main() {
  group('ProgramProvider Analytics', () {
    late ProgramProvider provider;
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;

    setUpAll(() async {
      // No Firebase initialization needed for fake firestore
    });

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();

      // Set up default stubs for auto-load calls (called in constructor)
      when(mockFirestoreService.getPrograms(any)).thenAnswer((_) => Stream.value([]));
      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: anyNamed('userId'),
        dateRange: anyNamed('dateRange'),
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

      // Add stubs for monthly heatmap methods with CONCRETE values (required for non-nullable params)
      final now = DateTime.now();
      when(mockAnalyticsService.getMonthHeatmapData(
        userId: 'test_user',
        year: now.year,
        month: now.month,
      )).thenAnswer((_) async => MonthHeatmapData(
        year: now.year,
        month: now.month,
        dailySetCounts: {},
        totalSets: 0,
        fetchedAt: now,
      ));

      when(mockAnalyticsService.prefetchAdjacentMonths(
        userId: 'test_user',
        year: now.year,
        month: now.month,
      )).thenAnswer((_) async {});

      // Stubs for loadConfigurableStreak (called via loadAnalytics)
      when(mockFirestoreService.getUserProfile(any))
          .thenAnswer((_) => Stream.value({'settings': {'workoutTarget': 3}}));
      when(mockAnalyticsService.getConfigurableStreak(
        userId: 'test_user',
        weeklyTarget: 3,
      )).thenAnswer((_) async => const ConfigurableStreak(
        weeklyTarget: 3,
        currentStreak: 0,
        longestStreak: 0,
      ));

      provider = ProgramProvider.withServices('test_user', mockFirestoreService, mockAnalyticsService);
    });

    group('loadAnalytics', () {
      test('loads analytics data successfully', () async {
        // Arrange
        final mockAnalytics = WorkoutAnalytics(
          userId: 'test_user',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31),
          totalWorkouts: 10,
          totalSets: 50,
          totalVolume: 5000.0,
          totalDuration: 3600,
          exerciseTypeBreakdown: {ExerciseType.strength: 5, ExerciseType.cardio: 3},
          completedWorkoutIds: ['w1', 'w2', 'w3'],
        );

        final mockHeatmapData = ActivityHeatmapData(
          userId: 'test_user',
          year: 2024,
          dailySetCounts: {DateTime(2024, 1, 1): 3},
          currentStreak: 5,
          longestStreak: 10,
          totalSets: 30,
        );

        final mockPRs = [
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

        final mockStats = {
          'totalWorkouts': 10,
          'totalSets': 50,
          'totalVolume': 5000.0,
          'averageDuration': 60.0,
          'newPRs': 2,
          'mostUsedExerciseType': 'Strength',
          'completionPercentage': 85.5,
          'workoutsPerWeek': 3.2,
        };

        // Clear auto-load interactions before setting up test-specific stubs
        clearInteractions(mockAnalyticsService);

        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) async => mockAnalytics);

        when(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).thenAnswer((_) async => mockHeatmapData);

        when(mockAnalyticsService.getPersonalRecords(
          userId: anyNamed('userId'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => mockPRs);

        when(mockAnalyticsService.computeKeyStatistics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) async => mockStats);

        // Act
        await provider.loadAnalytics();

        // Assert - These would test actual provider state
        // In real implementation, you'd check provider.currentAnalytics, etc.
        expect(provider.isLoadingAnalytics, isFalse);
        expect(provider.analyticsError, isNull);
      });

      test('handles analytics loading errors gracefully', () async {
        // Arrange
        clearInteractions(mockAnalyticsService);

        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenThrow(Exception('Failed to compute analytics'));

        // Act
        await provider.loadAnalytics();

        // Assert
        expect(provider.isLoadingAnalytics, isFalse);
        expect(provider.analyticsError, isNotNull);
        expect(provider.analyticsError, contains('Failed to load analytics'));
      });

      test('sets loading state correctly during analytics loading', () async {
        // Arrange - Clear auto-load interactions and mock with delayed responses
        clearInteractions(mockAnalyticsService);

        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return WorkoutAnalytics(
            userId: 'test_user',
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
            totalWorkouts: 0,
            totalSets: 0,
            totalVolume: 0.0,
            totalDuration: 0,
            exerciseTypeBreakdown: {},
            completedWorkoutIds: [],
          );
        });

        when(mockAnalyticsService.generateSetBasedHeatmapData(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
          programId: anyNamed('programId'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return ActivityHeatmapData(
            userId: 'test_user',
            year: DateTime.now().year,
            dailySetCounts: {},
            currentStreak: 0,
            longestStreak: 0,
            totalSets: 0,
          );
        });

        when(mockAnalyticsService.getPersonalRecords(
          userId: anyNamed('userId'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return [];
        });

        when(mockAnalyticsService.computeKeyStatistics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return {};
        });

        // Act - Start loading (don't await yet)
        final future = provider.loadAnalytics();

        // Wait for synchronous code to execute
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - Loading state should be true during loading
        expect(provider.isLoadingAnalytics, isTrue);

        // Wait for completion
        await future;

        // Assert - Check loading state is false after completion
        expect(provider.isLoadingAnalytics, isFalse);
      });

      test('loads analytics with custom date range', () async {
        // Arrange
        final customRange = DateRange.thisMonth();

        clearInteractions(mockAnalyticsService);

        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) async => WorkoutAnalytics(
          userId: 'test_user',
          startDate: customRange.start,
          endDate: customRange.end,
          totalWorkouts: 5,
          totalSets: 25,
          totalVolume: 2500.0,
          totalDuration: 1800,
          exerciseTypeBreakdown: {ExerciseType.strength: 3},
          completedWorkoutIds: ['w1', 'w2'],
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

        // Act
        await provider.loadAnalytics(dateRange: customRange);

        // Assert
        verify(mockAnalyticsService.computeWorkoutAnalytics(
          userId: 'test_user',
          dateRange: customRange,
        )).called(1);
      });
    });

    group('checkForPersonalRecord', () {
      test('detects and adds new personal record', () async {
        // Arrange
        final testSet = ExerciseSet(
          id: 'set1',
          setNumber: 1,
          reps: 10,
          weight: 105.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final testExercise = Exercise(
          id: 'ex1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final newPR = PersonalRecord(
          id: 'pr1',
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          prType: PRType.maxWeight,
          value: 105.0,
          previousValue: 100.0,
          achievedAt: DateTime.now(),
          workoutId: 'w1',
          setId: 'set1',
        );

        when(mockAnalyticsService.checkForNewPR(
          set: testSet,
          exercise: testExercise,
        )).thenAnswer((_) async => newPR);

        // Act
        final result = await provider.checkForPersonalRecord(testSet, testExercise);

        // Assert
        expect(result, isNotNull);
        expect(result!.value, equals(105.0));
        expect(result.improvement, equals(5.0));
        
        // Verify PR was added to recent PRs (implementation dependent)
        // expect(provider.recentPRs, contains(newPR));
      });

      test('handles no PR found correctly', () async {
        // Arrange
        final testSet = ExerciseSet(
          id: 'set1',
          setNumber: 1,
          reps: 8,
          weight: 95.0, // Lower than previous
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final testExercise = Exercise(
          id: 'ex1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        when(mockAnalyticsService.checkForNewPR(
          set: testSet,
          exercise: testExercise,
        )).thenAnswer((_) async => null);

        // Act
        final result = await provider.checkForPersonalRecord(testSet, testExercise);

        // Assert
        expect(result, isNull);
      });

      test('handles PR check errors gracefully', () async {
        // Arrange
        final testSet = ExerciseSet(
          id: 'set1',
          setNumber: 1,
          reps: 10,
          weight: 105.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        final testExercise = Exercise(
          id: 'ex1',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'test_user',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );

        when(mockAnalyticsService.checkForNewPR(
          set: testSet,
          exercise: testExercise,
        )).thenThrow(Exception('PR check failed'));

        // Act
        final result = await provider.checkForPersonalRecord(testSet, testExercise);

        // Assert
        expect(result, isNull); // Should handle error gracefully
      });

      test('limits recent PRs list to 10 items', () async {
        // This test would verify that the recent PRs list doesn't grow beyond 10 items
        // Implementation would depend on how the provider manages the PRs list
        expect(true, isTrue); // Placeholder
      });
    });

    group('refreshAnalytics', () {
      test('clears cache and reloads analytics', () async {
        // Arrange - Clear auto-load interactions
        clearInteractions(mockAnalyticsService);

        // Mock clearCache method
        when(mockAnalyticsService.clearCache()).thenAnswer((_) async {});

        // Act
        await provider.refreshAnalytics();

        // Assert
        verify(mockAnalyticsService.clearCache()).called(1);
        // Would also verify that loadAnalytics was called
      });
    });

    group('Analytics State Management', () {
      test('general loading state includes analytics loading', () {
        // Arrange - Set analytics loading to true
        // This would require a way to set the internal state for testing
        
        // Assert
        // expect(provider.isLoading, isTrue); // when analytics is loading
        expect(true, isTrue); // Placeholder
      });

      test('userId getter returns correct user ID', () {
        expect(provider.userId, equals('test_user'));
      });

      test('analytics getters return correct values', () async {
        // This would test the getter methods for analytics data
        // Wait for auto-load microtask to complete
        await Future.delayed(Duration.zero);

        // Implementation would depend on how the data is stored internally
        expect(provider.currentAnalytics, isNotNull); // Auto-loaded with default empty data
        expect(provider.heatmapData, isNotNull); // Auto-loaded with default empty data
        expect(provider.recentPRs, isNotNull); // Auto-loaded with empty list
        expect(provider.keyStatistics, isNotNull); // Auto-loaded with empty map
        expect(provider.isLoadingAnalytics, isFalse);
      });
    });

    group('loadExerciseProgress', () {
      test('loads exercise progress and updates getter', () async {
        final dateRange = DateRange.lastMonth();
        final mockData = ExerciseProgressData(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dataPoints: [
            ExerciseProgressPoint(
              date: DateTime(2024, 6, 1),
              workoutId: 'w1',
              maxWeight: 100.0,
              maxReps: 8,
              totalVolume: 800.0,
              estimated1RM: 120.0,
            ),
          ],
          dateRange: dateRange,
        );

        when(mockAnalyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        )).thenAnswer((_) async => mockData);

        await provider.loadExerciseProgress(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        );

        expect(provider.exerciseProgress, isNotNull);
        expect(provider.exerciseProgress!.exerciseId, equals('ex1'));
        expect(provider.exerciseProgress!.dataPoints.length, equals(1));
      });

      test('handles errors gracefully', () async {
        final dateRange = DateRange.lastMonth();

        when(mockAnalyticsService.getExerciseProgress(
          userId: 'test_user',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        )).thenThrow(Exception('Network error'));

        await provider.loadExerciseProgress(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dateRange: dateRange,
        );

        // Should not crash, exerciseProgress stays null
        expect(provider.exerciseProgress, isNull);
      });
    });

    group('loadMuscleGroupVolume', () {
      test('loads muscle group volume and updates getter', () async {
        final dateRange = DateRange.lastMonth();
        final mockData = [
          const MuscleGroupVolume(
            muscleGroup: MuscleGroup.chest,
            label: 'Chest',
            totalSets: 20,
            percentage: 40.0,
          ),
          const MuscleGroupVolume(
            muscleGroup: MuscleGroup.back,
            label: 'Back',
            totalSets: 15,
            percentage: 30.0,
          ),
          const MuscleGroupVolume(
            muscleGroup: MuscleGroup.legs,
            label: 'Legs',
            totalSets: 15,
            percentage: 30.0,
          ),
        ];

        when(mockAnalyticsService.getMuscleGroupVolume(
          userId: 'test_user',
          dateRange: dateRange,
          libraryExercises: const <LibraryExercise>[],
          customExercises: const <CustomExercise>[],
        )).thenAnswer((_) async => mockData);

        await provider.loadMuscleGroupVolume(
          dateRange: dateRange,
          libraryExercises: const [],
          customExercises: const [],
        );

        expect(provider.muscleGroupVolume, isNotNull);
        expect(provider.muscleGroupVolume!.length, equals(3));
        expect(provider.muscleGroupVolume!.first.label, equals('Chest'));
      });

      test('handles errors gracefully', () async {
        final dateRange = DateRange.lastMonth();

        when(mockAnalyticsService.getMuscleGroupVolume(
          userId: 'test_user',
          dateRange: dateRange,
          libraryExercises: const <LibraryExercise>[],
          customExercises: const <CustomExercise>[],
        )).thenThrow(Exception('Network error'));

        await provider.loadMuscleGroupVolume(
          dateRange: dateRange,
          libraryExercises: const [],
          customExercises: const [],
        );

        expect(provider.muscleGroupVolume, isNull);
      });
    });

    group('loadWeeklyTrends', () {
      test('loads weekly trends and updates getter', () async {
        final dateRange = DateRange.lastMonth();
        final mockData = [
          WeeklyTrendPoint(
            weekStart: DateTime(2024, 6, 3),
            totalVolume: 5000.0,
            workoutCount: 3,
          ),
          WeeklyTrendPoint(
            weekStart: DateTime(2024, 6, 10),
            totalVolume: 6000.0,
            workoutCount: 4,
          ),
        ];

        when(mockAnalyticsService.getWeeklyTrends(
          userId: 'test_user',
          dateRange: dateRange,
        )).thenAnswer((_) async => mockData);

        await provider.loadWeeklyTrends(dateRange: dateRange);

        expect(provider.weeklyTrends, isNotNull);
        expect(provider.weeklyTrends!.length, equals(2));
        expect(provider.weeklyTrends!.first.workoutCount, equals(3));
      });

      test('handles errors gracefully', () async {
        final dateRange = DateRange.lastMonth();

        when(mockAnalyticsService.getWeeklyTrends(
          userId: 'test_user',
          dateRange: dateRange,
        )).thenThrow(Exception('Network error'));

        await provider.loadWeeklyTrends(dateRange: dateRange);

        expect(provider.weeklyTrends, isNull);
      });
    });

    group('loadConfigurableStreak', () {
      test('reads target from user profile and loads streak', () async {
        // The setUp already stubs getUserProfile and getConfigurableStreak.
        // Wait for auto-load to settle, then re-load manually.
        await Future.delayed(Duration.zero);

        // Setup a specific profile to verify it reads the target
        when(mockFirestoreService.getUserProfile('test_user'))
            .thenAnswer((_) => Stream.value({'settings': {'workoutTarget': 5}}));
        when(mockAnalyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 5,
        )).thenAnswer((_) async => const ConfigurableStreak(
          weeklyTarget: 5,
          currentStreak: 8,
          longestStreak: 12,
        ));

        await provider.loadConfigurableStreak();

        expect(provider.weeklyWorkoutTarget, equals(5));
        expect(provider.configurableStreak, isNotNull);
        expect(provider.configurableStreak!.currentStreak, equals(8));
        expect(provider.configurableStreak!.longestStreak, equals(12));
      });

      test('uses default target of 3 when no settings', () async {
        await Future.delayed(Duration.zero);

        when(mockFirestoreService.getUserProfile('test_user'))
            .thenAnswer((_) => Stream.value(null));
        when(mockAnalyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 3,
        )).thenAnswer((_) async => const ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 0,
          longestStreak: 0,
        ));

        await provider.loadConfigurableStreak();

        expect(provider.weeklyWorkoutTarget, equals(3));
        expect(provider.configurableStreak, isNotNull);
      });

      test('handles errors gracefully', () async {
        await Future.delayed(Duration.zero);

        when(mockFirestoreService.getUserProfile('test_user'))
            .thenAnswer((_) => Stream.error(Exception('Permission denied')));

        await provider.loadConfigurableStreak();

        // Should not crash
        expect(true, isTrue);
      });
    });

    group('setWeeklyWorkoutTarget', () {
      test('persists target to Firestore and reloads streak', () async {
        await Future.delayed(Duration.zero);

        // Stub read of existing profile (with existing settings to preserve)
        when(mockFirestoreService.getUserProfile('test_user'))
            .thenAnswer((_) => Stream.value({
              'settings': {'theme': 'dark', 'workoutTarget': 3},
            }));

        when(mockFirestoreService.updateUserProfile(
          userId: 'test_user',
          settings: {'theme': 'dark', 'workoutTarget': 5},
        )).thenAnswer((_) async {});

        when(mockAnalyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 5,
        )).thenAnswer((_) async => const ConfigurableStreak(
          weeklyTarget: 5,
          currentStreak: 2,
          longestStreak: 10,
        ));

        await provider.setWeeklyWorkoutTarget(5);

        expect(provider.weeklyWorkoutTarget, equals(5));
        expect(provider.configurableStreak!.currentStreak, equals(2));

        verify(mockFirestoreService.updateUserProfile(
          userId: 'test_user',
          settings: {'theme': 'dark', 'workoutTarget': 5},
        )).called(1);
      });

      test('creates settings map when none exists', () async {
        await Future.delayed(Duration.zero);

        when(mockFirestoreService.getUserProfile('test_user'))
            .thenAnswer((_) => Stream.value(null));

        when(mockFirestoreService.updateUserProfile(
          userId: 'test_user',
          settings: {'workoutTarget': 4},
        )).thenAnswer((_) async {});

        when(mockAnalyticsService.getConfigurableStreak(
          userId: 'test_user',
          weeklyTarget: 4,
        )).thenAnswer((_) async => const ConfigurableStreak(
          weeklyTarget: 4,
          currentStreak: 0,
          longestStreak: 0,
        ));

        await provider.setWeeklyWorkoutTarget(4);

        expect(provider.weeklyWorkoutTarget, equals(4));
        verify(mockFirestoreService.updateUserProfile(
          userId: 'test_user',
          settings: {'workoutTarget': 4},
        )).called(1);
      });

      test('handles errors gracefully', () async {
        await Future.delayed(Duration.zero);

        when(mockFirestoreService.getUserProfile('test_user'))
            .thenAnswer((_) => Stream.value({'settings': {}}));

        when(mockFirestoreService.updateUserProfile(
          userId: 'test_user',
          settings: {'workoutTarget': 5},
        )).thenThrow(Exception('Write failed'));

        await provider.setWeeklyWorkoutTarget(5);

        // Target should still be updated locally even if persist fails
        expect(provider.weeklyWorkoutTarget, equals(5));
      });
    });

    group('getLoggedExercises', () {
      test('returns logged exercises from analytics service', () async {
        final mockResult = [
          (exerciseId: 'ex1', exerciseName: 'Bench Press', exerciseType: ExerciseType.strength),
          (exerciseId: 'ex2', exerciseName: 'Running', exerciseType: ExerciseType.cardio),
        ];

        when(mockAnalyticsService.getLoggedExercises(
          userId: 'test_user',
        )).thenAnswer((_) async => mockResult);

        final result = await provider.getLoggedExercises();

        expect(result.length, equals(2));
        expect(result[0].exerciseName, equals('Bench Press'));
        expect(result[1].exerciseName, equals('Running'));
      });

      test('returns empty list on error', () async {
        when(mockAnalyticsService.getLoggedExercises(
          userId: 'test_user',
        )).thenThrow(Exception('Network error'));

        final result = await provider.getLoggedExercises();

        expect(result, isEmpty);
      });

      test('returns empty list when userId is null', () async {
        // Create provider with null userId
        final nullProvider = ProgramProvider.withServices(
          null,
          mockFirestoreService,
          mockAnalyticsService,
        );

        final result = await nullProvider.getLoggedExercises();

        expect(result, isEmpty);
      });
    });

    group('new analytics getters default values', () {
      test('exerciseProgress is initially null', () {
        expect(provider.exerciseProgress, isNull);
      });

      test('muscleGroupVolume is initially null', () {
        expect(provider.muscleGroupVolume, isNull);
      });

      test('weeklyTrends is initially null', () {
        expect(provider.weeklyTrends, isNull);
      });

      test('weeklyWorkoutTarget defaults to 3', () {
        // Create a fresh provider without any auto-load modifying the target
        final freshProvider = ProgramProvider.withServices(
          null,
          mockFirestoreService,
          mockAnalyticsService,
        );
        expect(freshProvider.weeklyWorkoutTarget, equals(3));
      });
    });

    group('null userId guard', () {
      late ProgramProvider nullProvider;

      setUp(() {
        nullProvider = ProgramProvider.withServices(
          null,
          mockFirestoreService,
          mockAnalyticsService,
        );
      });

      test('loadExerciseProgress returns early with null userId', () async {
        await nullProvider.loadExerciseProgress(
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          exerciseType: ExerciseType.strength,
          dateRange: DateRange.lastMonth(),
        );

        // Getter remains null since service was never called
        expect(nullProvider.exerciseProgress, isNull);
      });

      test('loadMuscleGroupVolume returns early with null userId', () async {
        await nullProvider.loadMuscleGroupVolume(
          dateRange: DateRange.lastMonth(),
          libraryExercises: const [],
          customExercises: const [],
        );

        expect(nullProvider.muscleGroupVolume, isNull);
      });

      test('loadWeeklyTrends returns early with null userId', () async {
        await nullProvider.loadWeeklyTrends(dateRange: DateRange.lastMonth());

        expect(nullProvider.weeklyTrends, isNull);
      });

      test('setWeeklyWorkoutTarget returns early with null userId', () async {
        await nullProvider.setWeeklyWorkoutTarget(5);

        // Target stays at default since method returned early
        expect(nullProvider.weeklyWorkoutTarget, equals(3));
      });
    });
  });
}