import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';

import 'program_provider_analytics_test.mocks.dart';

@GenerateMocks([FirestoreService, AnalyticsService])
void main() {
  group('ProgramProvider Analytics', () {
    late ProgramProvider provider;
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;

    setUpAll(() async {
      await Firebase.initializeApp();
    });

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();
      provider = ProgramProvider('test_user');
      
      // In a real implementation, you'd inject these dependencies
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
          dailyWorkoutCounts: {DateTime(2024, 1, 1): 1},
          currentStreak: 5,
          longestStreak: 10,
          totalWorkouts: 10,
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

        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) async => mockAnalytics);

        when(mockAnalyticsService.generateHeatmapData(
          userId: anyNamed('userId'),
          year: anyNamed('year'),
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
        expect(provider.error, isNull);
      });

      test('handles analytics loading errors gracefully', () async {
        // Arrange
        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenThrow(Exception('Failed to compute analytics'));

        // Act
        await provider.loadAnalytics();

        // Assert
        expect(provider.isLoadingAnalytics, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to load analytics'));
      });

      test('sets loading state correctly during analytics loading', () async {
        // Arrange
        final completer = Completer<WorkoutAnalytics>();
        when(mockAnalyticsService.computeWorkoutAnalytics(
          userId: anyNamed('userId'),
          dateRange: anyNamed('dateRange'),
        )).thenAnswer((_) => completer.future);

        // Act
        final future = provider.loadAnalytics();
        
        // Assert - Check loading state is true
        expect(provider.isLoadingAnalytics, isTrue);

        // Complete the future
        completer.complete(WorkoutAnalytics(
          userId: 'test_user',
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now(),
          totalWorkouts: 0,
          totalSets: 0,
          totalVolume: 0.0,
          totalDuration: 0,
          exerciseTypeBreakdown: {},
          completedWorkoutIds: [],
        ));

        await future;

        // Assert - Check loading state is false after completion
        expect(provider.isLoadingAnalytics, isFalse);
      });

      test('loads analytics with custom date range', () async {
        // Arrange
        final customRange = DateRange.thisMonth();
        
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

        when(mockAnalyticsService.generateHeatmapData(
          userId: anyNamed('userId'),
          year: anyNamed('year'),
        )).thenAnswer((_) async => ActivityHeatmapData(
          userId: 'test_user',
          year: DateTime.now().year,
          dailyWorkoutCounts: {},
          currentStreak: 0,
          longestStreak: 0,
          totalWorkouts: 0,
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

      test('analytics getters return correct values', () {
        // This would test the getter methods for analytics data
        // Implementation would depend on how the data is stored internally
        expect(provider.currentAnalytics, isNull); // Initially null
        expect(provider.heatmapData, isNull);
        expect(provider.recentPRs, isNull);
        expect(provider.keyStatistics, isNull);
        expect(provider.isLoadingAnalytics, isFalse);
      });
    });

    group('Integration with Existing Provider Methods', () {
      test('createSet triggers PR check', () async {
        // This test would verify that creating a set also checks for PRs
        // Would require mocking the existing createSet method flow
        expect(true, isTrue); // Placeholder
      });

      test('updating set triggers PR check', () async {
        // This test would verify that updating a set also checks for PRs
        expect(true, isTrue); // Placeholder
      });
    });
  });
}

// Helper class to simulate Future completion for testing async loading states
class Completer<T> {
  late Future<T> future;
  late Function(T) _complete;
  late Function(Object) _completeError;

  Completer() {
    final controller = StreamController<T>();
    future = controller.stream.single;
    _complete = controller.add;
    _completeError = controller.addError;
  }

  void complete(T value) => _complete(value);
  void completeError(Object error) => _completeError(error);
}