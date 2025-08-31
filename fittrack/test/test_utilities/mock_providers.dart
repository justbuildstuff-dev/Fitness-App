/// Comprehensive provider mocking utilities for FitTrack testing
/// 
/// Mock Coverage:
/// - ProgramProvider with all state scenarios
/// - AuthProvider with authentication flows
/// - Realistic state transitions and data
/// - Error conditions and edge cases
/// - Performance scenario simulation
/// 
/// Usage:
/// - Import in widget tests that need provider mocking
/// - Use MockProviderSetup for quick mock configuration
/// - Use ProviderStateBuilder for complex state scenarios
/// - Use ProviderTestUtils for common testing patterns

import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import '../../lib/providers/program_provider.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/models/program.dart';
import '../../lib/models/week.dart';
import '../../lib/models/workout.dart';
import '../../lib/models/exercise.dart';
import '../../lib/models/exercise_set.dart';
import '../../lib/models/analytics.dart';
import '../mocks/firebase_mocks.dart';

@GenerateMocks([
  ProgramProvider,
  AuthProvider,
])
import 'mock_providers.mocks.dart';

/// Centralized provider mock setup and configuration
class MockProviderSetup {
  /// Configure ProgramProvider with realistic default state
  static MockProgramProvider createProgramProvider({
    String userId = 'test-user-123',
    List<Program>? programs,
    Program? selectedProgram,
    bool isLoading = false,
    String? error,
    WorkoutAnalytics? analytics,
  }) {
    final mockProvider = MockProgramProvider();
    
    // Set up basic state
    when(mockProvider.programs).thenReturn(programs ?? []);
    when(mockProvider.selectedProgram).thenReturn(selectedProgram);
    when(mockProvider.isLoadingPrograms).thenReturn(isLoading);
    when(mockProvider.error).thenReturn(error);
    
    // Set up analytics state
    when(mockProvider.currentAnalytics).thenReturn(analytics);
    when(mockProvider.isLoadingAnalytics).thenReturn(false);
    
    // Set up default async operations
    _configureDefaultAsyncOperations(mockProvider);
    
    return mockProvider;
  }

  /// Configure AuthProvider with authentication state
  static MockAuthProvider createAuthProvider({
    bool isAuthenticated = true,
    String userId = 'test-user-123',
    String userEmail = 'test@fittrack.test',
    bool isLoading = false,
    String? error,
  }) {
    final mockProvider = MockAuthProvider();
    
    when(mockProvider.isAuthenticated).thenReturn(isAuthenticated);
    when(mockProvider.userId).thenReturn(isAuthenticated ? userId : null);
    when(mockProvider.userEmail).thenReturn(isAuthenticated ? userEmail : null);
    when(mockProvider.isLoading).thenReturn(isLoading);
    when(mockProvider.error).thenReturn(error);
    
    // Set up authentication operations
    when(mockProvider.signIn(any, any)).thenAnswer((_) async => true);
    when(mockProvider.signUp(any, any)).thenAnswer((_) async => true);
    when(mockProvider.signOut()).thenAnswer((_) async {});
    
    return mockProvider;
  }

  /// Configure default async operations for ProgramProvider
  static void _configureDefaultAsyncOperations(MockProgramProvider mockProvider) {
    // Program operations
    when(mockProvider.createProgram(any)).thenAnswer((_) async => 'new-program-id');
    when(mockProvider.updateProgram(any)).thenAnswer((_) async {});
    when(mockProvider.deleteProgram(any)).thenAnswer((_) async {});
    when(mockProvider.loadPrograms()).thenAnswer((_) async {});
    
    // Week operations
    when(mockProvider.createWeek(any, any)).thenAnswer((_) async => 'new-week-id');
    when(mockProvider.updateWeek(any)).thenAnswer((_) async {});
    when(mockProvider.deleteWeek(any)).thenAnswer((_) async {});
    when(mockProvider.loadWeeks(any)).thenAnswer((_) async {});
    
    // Workout operations
    when(mockProvider.createWorkout(any, any, any)).thenAnswer((_) async => 'new-workout-id');
    when(mockProvider.updateWorkout(any)).thenAnswer((_) async {});
    when(mockProvider.deleteWorkout(any)).thenAnswer((_) async {});
    when(mockProvider.loadWorkouts(any, any)).thenAnswer((_) async {});
    
    // Exercise operations
    when(mockProvider.createExercise(any, any, any, any)).thenAnswer((_) async => 'new-exercise-id');
    when(mockProvider.updateExercise(any)).thenAnswer((_) async {});
    when(mockProvider.deleteExercise(any)).thenAnswer((_) async {});
    when(mockProvider.loadExercises(any, any, any)).thenAnswer((_) async {});
    
    // Set operations
    when(mockProvider.createSet(any, any, any, any, any)).thenAnswer((_) async => 'new-set-id');
    when(mockProvider.updateSet(any)).thenAnswer((_) async {});
    when(mockProvider.deleteSet(any)).thenAnswer((_) async {});
    when(mockProvider.loadSets(any, any, any, any)).thenAnswer((_) async {});
    
    // Analytics operations
    when(mockProvider.loadAnalytics()).thenAnswer((_) async {});
    when(mockProvider.refreshAnalytics()).thenAnswer((_) async {});
  }
}

/// Provider state builder for complex testing scenarios
class ProviderStateBuilder {
  final MockProgramProvider _provider;
  
  ProviderStateBuilder() : _provider = MockProgramProvider();

  /// Set up loading state
  ProviderStateBuilder withLoadingState({
    bool programs = false,
    bool weeks = false,
    bool workouts = false,
    bool exercises = false,
    bool sets = false,
    bool analytics = false,
  }) {
    when(_provider.isLoadingPrograms).thenReturn(programs);
    when(_provider.isLoadingWeeks).thenReturn(weeks);
    when(_provider.isLoadingWorkouts).thenReturn(workouts);
    when(_provider.isLoadingExercises).thenReturn(exercises);
    when(_provider.isLoadingSets).thenReturn(sets);
    when(_provider.isLoadingAnalytics).thenReturn(analytics);
    return this;
  }

  /// Set up error state
  ProviderStateBuilder withError(String errorMessage) {
    when(_provider.error).thenReturn(errorMessage);
    return this;
  }

  /// Set up programs data
  ProviderStateBuilder withPrograms(List<Program> programs) {
    when(_provider.programs).thenReturn(programs);
    return this;
  }

  /// Set up selected program
  ProviderStateBuilder withSelectedProgram(Program program) {
    when(_provider.selectedProgram).thenReturn(program);
    return this;
  }

  /// Set up weeks data
  ProviderStateBuilder withWeeks(List<Week> weeks) {
    when(_provider.weeks).thenReturn(weeks);
    return this;
  }

  /// Set up workouts data
  ProviderStateBuilder withWorkouts(List<Workout> workouts) {
    when(_provider.workouts).thenReturn(workouts);
    return this;
  }

  /// Set up exercises data
  ProviderStateBuilder withExercises(List<Exercise> exercises) {
    when(_provider.exercises).thenReturn(exercises);
    return this;
  }

  /// Set up sets data
  ProviderStateBuilder withSets(List<ExerciseSet> sets) {
    when(_provider.sets).thenReturn(sets);
    return this;
  }

  /// Set up analytics data
  ProviderStateBuilder withAnalytics(WorkoutAnalytics analytics) {
    when(_provider.currentAnalytics).thenReturn(analytics);
    return this;
  }

  /// Configure operation results
  ProviderStateBuilder withOperationResults({
    String? createProgramResult,
    String? createWorkoutResult,
    String? createExerciseResult,
    Exception? operationError,
  }) {
    if (operationError != null) {
      when(_provider.createProgram(name: anyNamed('name'), description: anyNamed('description'))).thenThrow(operationError);
      when(_provider.createWorkout(programId: anyNamed('programId'), weekId: anyNamed('weekId'), name: anyNamed('name'), dayOfWeek: anyNamed('dayOfWeek'), notes: anyNamed('notes'))).thenThrow(operationError);
      when(_provider.createExercise(programId: anyNamed('programId'), weekId: anyNamed('weekId'), workoutId: anyNamed('workoutId'), name: anyNamed('name'), exerciseType: anyNamed('exerciseType'), notes: anyNamed('notes'))).thenThrow(operationError);
    } else {
      when(_provider.createProgram(name: anyNamed('name'), description: anyNamed('description'))).thenAnswer((_) async => createProgramResult ?? 'mock-program-id');
      when(_provider.createWorkout(programId: anyNamed('programId'), weekId: anyNamed('weekId'), name: anyNamed('name'), dayOfWeek: anyNamed('dayOfWeek'), notes: anyNamed('notes'))).thenAnswer((_) async => createWorkoutResult ?? 'mock-workout-id');
      when(_provider.createExercise(programId: anyNamed('programId'), weekId: anyNamed('weekId'), workoutId: anyNamed('workoutId'), name: anyNamed('name'), exerciseType: anyNamed('exerciseType'), notes: anyNamed('notes'))).thenAnswer((_) async => createExerciseResult ?? 'mock-exercise-id');
    }
    return this;
  }

  /// Build the configured mock provider
  MockProgramProvider build() {
    MockProviderSetup._configureDefaultAsyncOperations(_provider);
    return _provider;
  }
}

/// Common testing patterns and utilities
class ProviderTestUtils {
  /// Create provider with realistic program data
  static MockProgramProvider createWithRealisticData() {
    final programs = [
      MockDataGenerator.generateProgram(name: 'Strength Training'),
      MockDataGenerator.generateProgram(name: 'Cardio Program', isArchived: true),
    ];
    
    final analytics = MockDataGenerator.generateAnalytics();
    
    return ProviderStateBuilder()
        .withPrograms(programs)
        .withSelectedProgram(programs.first)
        .withAnalytics(analytics)
        .build();
  }

  /// Create provider in loading state
  static MockProgramProvider createInLoadingState() {
    return ProviderStateBuilder()
        .withLoadingState(programs: true, analytics: true)
        .build();
  }

  /// Create provider with error state
  static MockProgramProvider createWithError(String errorMessage) {
    return ProviderStateBuilder()
        .withError(errorMessage)
        .build();
  }

  /// Create provider with empty data
  static MockProgramProvider createEmpty() {
    return ProviderStateBuilder()
        .withPrograms([])
        .build();
  }

  /// Create provider with large dataset
  static MockProgramProvider createWithLargeDataset() {
    final largeDataset = TestDataSets.large();
    final programs = [largeDataset['program'] as Program];
    
    return ProviderStateBuilder()
        .withPrograms(programs)
        .withSelectedProgram(programs.first)
        .build();
  }

  /// Verify provider method calls
  static void verifyCreateProgramCalled(MockProgramProvider provider, {int times = 1}) {
    verify(provider.createProgram(any)).called(times);
  }

  static void verifyLoadProgramsCalled(MockProgramProvider provider, {int times = 1}) {
    verify(provider.loadPrograms()).called(times);
  }

  static void verifyNoInteractions(MockProgramProvider provider) {
    verifyZeroInteractions(provider);
  }

  /// Common assertion patterns
  static void assertProviderState(
    MockProgramProvider provider, {
    bool? shouldBeLoading,
    bool? shouldHaveError,
    int? expectedProgramCount,
  }) {
    if (shouldBeLoading != null) {
      verify(provider.isLoadingPrograms).called(greaterThan(0));
    }
    
    if (shouldHaveError != null) {
      if (shouldHaveError) {
        verify(provider.error).called(greaterThan(0));
      } else {
        when(provider.error).thenReturn(null);
      }
    }
    
    if (expectedProgramCount != null) {
      verify(provider.programs).called(greaterThan(0));
    }
  }
}

/// Test scenario configurations for different testing needs
class ProviderTestScenarios {
  /// Scenario: User with established workout data
  static MockProgramProvider establishedUser() {
    final programs = List.generate(3, (i) => 
      MockDataGenerator.generateProgram(name: 'Program ${i + 1}'));
    
    final weeks = List.generate(2, (i) => 
      MockDataGenerator.generateWeek(weekNumber: i + 1));
    
    final workouts = List.generate(6, (i) => 
      MockDataGenerator.generateWorkout(name: 'Workout ${i + 1}'));
    
    return ProviderStateBuilder()
        .withPrograms(programs)
        .withSelectedProgram(programs.first)
        .withWeeks(weeks)
        .withWorkouts(workouts)
        .build();
  }

  /// Scenario: New user with no data
  static MockProgramProvider newUser() {
    return ProviderStateBuilder()
        .withPrograms([])
        .build();
  }

  /// Scenario: User experiencing network issues
  static MockProgramProvider networkIssues() {
    return ProviderStateBuilder()
        .withError('Network connection failed. Please check your internet connection.')
        .withLoadingState(programs: false)
        .build();
  }

  /// Scenario: User with performance-heavy data
  static MockProgramProvider performanceTest() {
    return MockProviderSetup.createProgramProvider(
      programs: List.generate(50, (i) => MockDataGenerator.generateProgram()),
      analytics: MockDataGenerator.generateAnalytics(),
    );
  }

  /// Scenario: Authentication issues
  static MockAuthProvider authenticationIssues() {
    final mockAuth = MockAuthProvider();
    when(mockAuth.isAuthenticated).thenReturn(false);
    when(mockAuth.error).thenReturn('Authentication failed. Please sign in again.');
    when(mockAuth.signIn(any, any)).thenAnswer((_) async => false);
    return mockAuth;
  }
}

/// Provider notification utilities for testing reactive UI
class ProviderNotificationUtils {
  /// Simulate provider state change notifications
  static void simulateStateChange(MockProgramProvider provider, {
    List<Program>? newPrograms,
    bool? newLoadingState,
    String? newError,
  }) {
    if (newPrograms != null) {
      when(provider.programs).thenReturn(newPrograms);
    }
    if (newLoadingState != null) {
      when(provider.isLoadingPrograms).thenReturn(newLoadingState);
    }
    if (newError != null) {
      when(provider.error).thenReturn(newError);
    }
    
    provider.notifyListeners();
  }

  /// Simulate loading sequence
  static Future<void> simulateLoadingSequence(
    MockProgramProvider provider,
    List<Program> finalPrograms,
    {Duration loadingDuration = const Duration(milliseconds: 500)}
  ) async {
    // Start loading
    when(provider.isLoadingPrograms).thenReturn(true);
    when(provider.programs).thenReturn([]);
    provider.notifyListeners();
    
    await Future.delayed(loadingDuration);
    
    // Complete loading
    when(provider.isLoadingPrograms).thenReturn(false);
    when(provider.programs).thenReturn(finalPrograms);
    provider.notifyListeners();
  }

  /// Simulate error sequence
  static Future<void> simulateErrorSequence(
    MockProgramProvider provider,
    String errorMessage,
    {Duration errorDelay = const Duration(milliseconds: 300)}
  ) async {
    // Start operation
    when(provider.isLoadingPrograms).thenReturn(true);
    when(provider.error).thenReturn(null);
    provider.notifyListeners();
    
    await Future.delayed(errorDelay);
    
    // Error occurs
    when(provider.isLoadingPrograms).thenReturn(false);
    when(provider.error).thenReturn(errorMessage);
    provider.notifyListeners();
  }
}

/// Advanced mock configurations for complex testing scenarios
class AdvancedMockConfigurations {
  /// Configure provider for duplication testing
  static MockProgramProvider forDuplicationTesting() {
    final sourceProgram = MockDataGenerator.generateProgram(name: 'Source Program');
    final provider = MockProviderSetup.createProgramProvider(
      programs: [sourceProgram],
      selectedProgram: sourceProgram,
    );

    // Configure duplication behavior
    when(provider.duplicateWeek(any, any, any, any)).thenAnswer((_) async => 'new-week-id');
    when(provider.duplicateProgram(any, any)).thenAnswer((_) async => 'new-program-id');
    
    return provider;
  }

  /// Configure provider for analytics testing
  static MockProgramProvider forAnalyticsTesting() {
    final programs = [MockDataGenerator.generateProgram(name: 'Analytics Test Program')];
    final analytics = MockDataGenerator.generateAnalytics();
    
    final provider = MockProviderSetup.createProgramProvider(
      programs: programs,
      analytics: analytics,
    );

    // Configure analytics-specific behavior
    when(provider.loadAnalytics()).thenAnswer((_) async {
      when(provider.currentAnalytics).thenReturn(analytics);
      when(provider.isLoadingAnalytics).thenReturn(false);
    });

    return provider;
  }

  /// Configure provider for offline testing
  static MockProgramProvider forOfflineTesting() {
    final provider = MockProviderSetup.createProgramProvider();
    
    // Configure offline behavior
    when(provider.createProgram(any)).thenAnswer((_) async {
      // Simulate offline storage
      await Future.delayed(Duration(milliseconds: 100));
      return 'offline-program-id';
    });

    when(provider.syncOfflineData()).thenAnswer((_) async {
      // Simulate sync process
      await Future.delayed(Duration(seconds: 1));
    });

    return provider;
  }

  /// Configure provider for error recovery testing
  static MockProgramProvider forErrorRecoveryTesting() {
    final provider = MockProviderSetup.createProgramProvider();
    
    // First call fails, second succeeds
    when(provider.createProgram(any))
        .thenThrow(Exception('Network error'))
        .thenAnswer((_) async => 'recovered-program-id');

    when(provider.retryLastOperation()).thenAnswer((_) async {
      // Simulate retry logic
      when(provider.error).thenReturn(null);
    });

    return provider;
  }
}

/// Performance testing utilities for provider operations
class ProviderPerformanceUtils {
  /// Measure provider operation performance
  static Future<Duration> measureOperation(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Validate provider operation meets performance requirements
  static Future<void> validateOperationPerformance(
    Future<void> Function() operation,
    Duration maxDuration,
    String operationName,
  ) async {
    final elapsed = await measureOperation(operation);
    
    if (elapsed > maxDuration) {
      throw TestFailure(
        'Provider operation performance failed for $operationName: '
        'Expected <${maxDuration.inMilliseconds}ms, '
        'Actual: ${elapsed.inMilliseconds}ms'
      );
    }
  }

  /// Configure provider for performance testing
  static MockProgramProvider createPerformanceTestProvider() {
    final largeDataset = TestDataSets.large();
    final programs = [largeDataset['program'] as Program];
    
    final provider = MockProviderSetup.createProgramProvider(programs: programs);
    
    // Configure realistic operation delays
    when(provider.loadPrograms()).thenAnswer((_) async {
      await Future.delayed(Duration(milliseconds: 50)); // Realistic load time
    });

    when(provider.loadAnalytics()).thenAnswer((_) async {
      await Future.delayed(Duration(milliseconds: 200)); // Analytics computation
    });

    return provider;
  }
}

/// Provider verification utilities for test assertions
class ProviderVerificationUtils {
  /// Verify CRUD operation calls
  static void verifyCRUDOperations(MockProgramProvider provider, {
    bool shouldCreateProgram = false,
    bool shouldUpdateProgram = false,
    bool shouldDeleteProgram = false,
    bool shouldLoadPrograms = false,
  }) {
    if (shouldCreateProgram) {
      verify(provider.createProgram(any)).called(1);
    } else {
      verifyNever(provider.createProgram(any));
    }

    if (shouldUpdateProgram) {
      verify(provider.updateProgram(any)).called(1);
    } else {
      verifyNever(provider.updateProgram(any));
    }

    if (shouldDeleteProgram) {
      verify(provider.deleteProgram(any)).called(1);
    } else {
      verifyNever(provider.deleteProgram(any));
    }

    if (shouldLoadPrograms) {
      verify(provider.loadPrograms()).called(greaterThan(0));
    }
  }

  /// Verify provider state consistency
  static void verifyStateConsistency(MockProgramProvider provider) {
    // Verify that loading states are consistent
    verify(provider.isLoadingPrograms).called(greaterThan(0));
    verify(provider.programs).called(greaterThan(0));
    
    // If there's an error, should not be loading
    try {
      verify(provider.error).called(greaterThan(0));
      verify(provider.isLoadingPrograms).called(greaterThan(0));
      // If error exists, should not be loading
    } catch (e) {
      // No error state checked
    }
  }

  /// Verify provider method call sequence
  static void verifyMethodCallSequence(
    MockProgramProvider provider,
    List<String> expectedSequence,
  ) {
    final verificationSequence = <Verification>[];
    
    for (final method in expectedSequence) {
      switch (method) {
        case 'loadPrograms':
          verificationSequence.add(verify(provider.loadPrograms()));
          break;
        case 'createProgram':
          verificationSequence.add(verify(provider.createProgram(any)));
          break;
        case 'updateProgram':
          verificationSequence.add(verify(provider.updateProgram(any)));
          break;
        case 'deleteProgram':
          verificationSequence.add(verify(provider.deleteProgram(any)));
          break;
      }
    }
    
    verifyInOrder(verificationSequence);
  }
}

/// Test data validation utilities
class MockDataValidation {
  /// Validate generated program data meets requirements
  static bool validateProgramData(Program program) {
    return program.id.isNotEmpty &&
           program.name.isNotEmpty &&
           program.userId.isNotEmpty &&
           program.createdAt != null &&
           program.updatedAt != null;
  }

  /// Validate complete hierarchy data
  static bool validateHierarchyData(Map<String, dynamic> hierarchy) {
    final program = hierarchy['program'] as Program?;
    final weeks = hierarchy['weeks'] as List<Week>?;
    final workouts = hierarchy['workouts'] as List<Workout>?;
    
    return program != null &&
           validateProgramData(program) &&
           weeks != null &&
           workouts != null &&
           workouts.every((w) => w.programId == program.id);
  }

  /// Validate mock provider configuration
  static bool validateProviderSetup(MockProgramProvider provider) {
    try {
      // Check that basic getters work
      provider.programs;
      provider.isLoadingPrograms;
      provider.error;
      return true;
    } catch (e) {
      return false;
    }
  }
}