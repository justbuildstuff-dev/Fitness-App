import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/analytics.dart';

import 'program_provider_superset_test.mocks.dart';

/// Unit tests for ProgramProvider superset operations.
///
/// Tests verify that:
/// - createSuperset delegates to FirestoreService with a shared supersetGroupId
/// - createSuperset assigns sequential groupOrderIndex values
/// - createSuperset returns null when user is not authenticated
/// - deleteSupersetGroup delegates to FirestoreService with correct parameters
/// - deleteSupersetGroup rethrows on service error

@GenerateMocks([FirestoreService, AnalyticsService])
void main() {
  group('ProgramProvider Superset Operations', () {
    late MockFirestoreService mockFirestoreService;
    late MockAnalyticsService mockAnalyticsService;
    late ProgramProvider provider;
    late Program testProgram;
    late Week testWeek;
    late Workout testWorkout;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      mockAnalyticsService = MockAnalyticsService();

      testProgram = Program(
        id: 'prog123',
        name: 'Test Program',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user123',
      );

      testWeek = Week(
        id: 'week123',
        name: 'Test Week',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user123',
        programId: 'prog123',
      );

      testWorkout = Workout(
        id: 'workout123',
        name: 'Test Workout',
        orderIndex: 1,
        dayOfWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user123',
        weekId: 'week123',
        programId: 'prog123',
      );

      // Stubs required by ProgramProvider auto-load on construction
      when(mockFirestoreService.getWeeks(any, any))
          .thenAnswer((_) => Stream.value([]));
      when(mockFirestoreService.getPrograms(any))
          .thenAnswer((_) => Stream.value([]));
      when(mockFirestoreService.getWorkouts(any, any, any))
          .thenAnswer((_) => Stream.value([]));
      when(mockFirestoreService.getExercises(any, any, any, any))
          .thenAnswer((_) => Stream.value([]));
      when(mockFirestoreService.getSets(any, any, any, any, any))
          .thenAnswer((_) => Stream.value([]));

      final now = DateTime.now();
      when(mockAnalyticsService.computeWorkoutAnalytics(
        userId: anyNamed('userId'),
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => WorkoutAnalytics(
        userId: 'user123',
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        totalWorkouts: 0,
        totalSets: 0,
        totalVolume: 0,
        totalDuration: 0,
        exerciseTypeBreakdown: {},
        completedWorkoutIds: [],
      ));

      when(mockAnalyticsService.generateSetBasedHeatmapData(
        userId: anyNamed('userId'),
        dateRange: anyNamed('dateRange'),
      )).thenAnswer((_) async => ActivityHeatmapData(
        userId: 'user123',
        year: now.year,
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

      when(mockAnalyticsService.getMonthHeatmapData(
        userId: 'user123',
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
        userId: 'user123',
        year: now.year,
        month: now.month,
      )).thenAnswer((_) async {});

      // Superset-specific stubs
      when(mockFirestoreService.createSupersetWithExercises(any, any, any))
          .thenAnswer((_) async => ['ex-id-1', 'ex-id-2']);

      when(mockFirestoreService.deleteSupersetGroup(any, any, any, any, any))
          .thenAnswer((_) async {});

      provider = ProgramProvider.withServices(
          'user123', mockFirestoreService, mockAnalyticsService);

      provider.selectProgram(testProgram);
      provider.selectWeek(testWeek);
      provider.selectWorkout(testWorkout);
    });

    test('createSuperset calls FirestoreService with shared supersetGroupId',
        () async {
      /// Test Purpose: Verify createSuperset passes a non-null UUID to the
      /// service and all exercises share the same supersetGroupId.
      final exercises = [
        (name: 'Bench Press', exerciseType: ExerciseType.strength),
        (name: 'Pull-ups', exerciseType: ExerciseType.bodyweight),
      ];

      final ids = await provider.createSuperset(
        programId: testProgram.id,
        weekId: testWeek.id,
        workoutId: testWorkout.id,
        exercises: exercises,
        setCount: 3,
      );

      expect(ids, isNotNull);
      expect(ids!.length, 2);

      final captured = verify(
        mockFirestoreService.createSupersetWithExercises(
          captureAny, captureAny, captureAny,
        ),
      ).captured;
      final capturedExercises = captured[0] as List<Exercise>;
      final capturedGroupId = captured[1] as String;
      final capturedSetCount = captured[2] as int;

      expect(capturedExercises.length, 2);
      expect(capturedGroupId, isNotEmpty);
      expect(capturedSetCount, 3);
      for (final ex in capturedExercises) {
        expect(ex.supersetGroupId, capturedGroupId);
      }
    });

    test('createSuperset assigns sequential groupOrderIndex to exercises',
        () async {
      /// Test Purpose: Verify exercises get groupOrderIndex 0, 1, 2 etc.
      final exercises = [
        (name: 'A', exerciseType: ExerciseType.strength),
        (name: 'B', exerciseType: ExerciseType.strength),
        (name: 'C', exerciseType: ExerciseType.strength),
      ];
      when(mockFirestoreService.createSupersetWithExercises(any, any, any))
          .thenAnswer((_) async => ['id-1', 'id-2', 'id-3']);

      await provider.createSuperset(
        programId: testProgram.id,
        weekId: testWeek.id,
        workoutId: testWorkout.id,
        exercises: exercises,
      );

      final captured = verify(
        mockFirestoreService.createSupersetWithExercises(
          captureAny, captureAny, captureAny,
        ),
      ).captured;
      final capturedExercises = captured[0] as List<Exercise>;
      expect(capturedExercises[0].groupOrderIndex, 0);
      expect(capturedExercises[1].groupOrderIndex, 1);
      expect(capturedExercises[2].groupOrderIndex, 2);
    });

    test('createSuperset returns null when userId is missing', () async {
      /// Test Purpose: Verify null guard when user is not authenticated.
      final unauthProvider = ProgramProvider.withServices(
        null,
        mockFirestoreService,
        mockAnalyticsService,
      );

      final ids = await unauthProvider.createSuperset(
        programId: 'prog',
        weekId: 'week',
        workoutId: 'workout',
        exercises: [(name: 'X', exerciseType: ExerciseType.strength)],
      );

      expect(ids, isNull);
      verifyNever(
          mockFirestoreService.createSupersetWithExercises(any, any, any));
    });

    test('deleteSupersetGroup calls FirestoreService with correct parameters',
        () async {
      /// Test Purpose: Verify deleteSupersetGroup passes all IDs to service.
      const groupId = 'group-uuid-123';

      await provider.deleteSupersetGroup(
        programId: testProgram.id,
        weekId: testWeek.id,
        workoutId: testWorkout.id,
        supersetGroupId: groupId,
      );

      verify(mockFirestoreService.deleteSupersetGroup(
        'user123',
        testProgram.id,
        testWeek.id,
        testWorkout.id,
        groupId,
      )).called(1);
    });

    test('deleteSupersetGroup rethrows on service error', () async {
      /// Test Purpose: Verify errors propagate so the UI can show feedback.
      when(mockFirestoreService.deleteSupersetGroup(any, any, any, any, any))
          .thenThrow(Exception('delete failed'));

      expect(
        () async => provider.deleteSupersetGroup(
          programId: testProgram.id,
          weekId: testWeek.id,
          workoutId: testWorkout.id,
          supersetGroupId: 'group-id',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
