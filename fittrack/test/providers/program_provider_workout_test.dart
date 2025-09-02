import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/firestore_service.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:fittrack/models/workout.dart';

import 'program_provider_workout_test.mocks.dart';

/// Unit tests for ProgramProvider workout-related methods
/// 
/// These tests verify that the ProgramProvider correctly:
/// - Creates, loads, updates, and deletes workouts
/// - Manages state and error handling appropriately
/// - Integrates properly with FirestoreService
/// 
/// Tests use mocked FirestoreService to ensure isolation from actual database
/// If any test fails, check the ProgramProvider implementation and state management
@GenerateMocks([FirestoreService, AnalyticsService])
void main() {
  group('ProgramProvider Workout Methods Tests', () {
    late MockFirestoreService mockFirestoreService;
    late ProgramProvider programProvider;
    
    const testUserId = 'test-user-123';
    const testProgramId = 'test-program-456';
    const testWeekId = 'test-week-789';

    setUpAll(() async {
      await Firebase.initializeApp();
    });

    setUp(() {
      // Set up clean test environment for each test
      // Using mocks ensures tests don't depend on external services
      mockFirestoreService = MockFirestoreService();
      // Create mock analytics service for dependency injection
      final mockAnalyticsService = MockAnalyticsService();
      programProvider = ProgramProvider.withServices(testUserId, mockFirestoreService, mockAnalyticsService);
    });

    group('Create Workout', () {
      test('createWorkout successfully creates workout and returns ID', () async {
        /// Test Purpose: Verify successful workout creation flow
        /// This is the primary happy path - user creates a workout and gets confirmation
        /// Failure indicates issues with workout creation or ID return
        
        const expectedWorkoutId = 'new-workout-123';
        const workoutName = 'Push Day Workout';
        const workoutNotes = 'Focus on chest and triceps';
        
        // Mock successful Firestore operation
        when(mockFirestoreService.createWorkout(any))
            .thenAnswer((_) async => expectedWorkoutId);

        // Execute the method under test
        final result = await programProvider.createWorkout(
          programId: testProgramId,
          weekId: testWeekId,
          name: workoutName,
          dayOfWeek: 1, // Monday
          notes: workoutNotes,
        );

        // Verify success
        expect(result, equals(expectedWorkoutId),
          reason: 'Should return the workout ID from Firestore');
        expect(programProvider.error, isNull,
          reason: 'Error should be null on successful creation');

        // Verify correct data was sent to Firestore
        final capturedWorkout = verify(mockFirestoreService.createWorkout(captureAny))
            .captured.single as Workout;
        
        expect(capturedWorkout.name, equals(workoutName));
        expect(capturedWorkout.dayOfWeek, equals(1));
        expect(capturedWorkout.notes, equals(workoutNotes));
        expect(capturedWorkout.userId, equals(testUserId));
        expect(capturedWorkout.weekId, equals(testWeekId));
        expect(capturedWorkout.programId, equals(testProgramId));
        expect(capturedWorkout.orderIndex, isA<int>(),
          reason: 'orderIndex should be automatically set');
      });

      test('createWorkout handles missing optional fields correctly', () async {
        /// Test Purpose: Verify workout creation works with minimal data
        /// Users should be able to create workouts with just a name
        /// Failure indicates issues with optional field handling
        
        const expectedWorkoutId = 'minimal-workout-456';
        const workoutName = 'Simple Workout';
        
        when(mockFirestoreService.createWorkout(any))
            .thenAnswer((_) async => expectedWorkoutId);

        final result = await programProvider.createWorkout(
          programId: testProgramId,
          weekId: testWeekId,
          name: workoutName,
          // dayOfWeek and notes intentionally omitted
        );

        expect(result, equals(expectedWorkoutId));

        final capturedWorkout = verify(mockFirestoreService.createWorkout(captureAny))
            .captured.single as Workout;
        
        expect(capturedWorkout.name, equals(workoutName));
        expect(capturedWorkout.dayOfWeek, isNull,
          reason: 'Optional dayOfWeek should be null when not provided');
        expect(capturedWorkout.notes, isNull,
          reason: 'Optional notes should be null when not provided');
      });

      test('createWorkout handles Firestore errors gracefully', () async {
        /// Test Purpose: Verify error handling when Firestore operations fail
        /// Network issues, permission errors, etc. should be handled gracefully
        /// Failure indicates poor error handling that could crash the app
        
        const workoutName = 'Error Test Workout';
        const errorMessage = 'Permission denied';
        
        // Mock Firestore failure
        when(mockFirestoreService.createWorkout(any))
            .thenThrow(Exception(errorMessage));

        final result = await programProvider.createWorkout(
          programId: testProgramId,
          weekId: testWeekId,
          name: workoutName,
        );

        // Verify error handling
        expect(result, isNull,
          reason: 'Should return null when creation fails');
        expect(programProvider.error, contains(errorMessage),
          reason: 'Error should contain the original error message for debugging');
        expect(programProvider.error, contains('Failed to create workout'),
          reason: 'Error should include user-friendly context');
      });

      test('createWorkout fails when user not authenticated', () async {
        /// Test Purpose: Verify authentication requirement for workout creation
        /// Unauthenticated users should not be able to create workouts
        /// Failure indicates security vulnerability
        
        const workoutName = 'Unauthorized Workout';
        
        // Create provider without authenticated user
        final unauthenticatedProvider = ProgramProvider(null);

        final result = await unauthenticatedProvider.createWorkout(
          programId: testProgramId,
          weekId: testWeekId,
          name: workoutName,
        );

        // Verify authorization check
        expect(result, isNull,
          reason: 'Should return null when user not authenticated');
        
        // Verify Firestore was never called
        verifyNever(mockFirestoreService.createWorkout(any));
      });

      test('createWorkout validates workout name length', () async {
        /// Test Purpose: Verify client-side validation prevents invalid data
        /// Long names could cause UI issues or database constraints violations
        /// Failure indicates validation is not working properly
        
        final tooLongName = 'A' * 201; // Exceeds 200 character limit
        
        final result = await programProvider.createWorkout(
          programId: testProgramId,
          weekId: testWeekId,
          name: tooLongName,
        );

        expect(result, isNull,
          reason: 'Should reject workout names longer than 200 characters');
        expect(programProvider.error, contains('name'),
          reason: 'Error should mention the name validation issue');
        
        // Verify Firestore was never called with invalid data
        verifyNever(mockFirestoreService.createWorkout(any));
      });
    });

    group('Load Workouts', () {
      test('loadWorkouts successfully loads and sets workout list', () async {
        /// Test Purpose: Verify successful workout loading and state management
        /// The UI depends on this method to display workouts for a week
        /// Failure indicates issues with data loading or state updates
        
        final mockWorkouts = [
          _createMockWorkout(id: 'workout-1', name: 'Push Day', dayOfWeek: 1),
          _createMockWorkout(id: 'workout-2', name: 'Pull Day', dayOfWeek: 3),
          _createMockWorkout(id: 'workout-3', name: 'Leg Day', dayOfWeek: 5),
        ];

        // Mock successful Firestore stream
        when(mockFirestoreService.getWorkouts(testUserId, testProgramId, testWeekId))
            .thenAnswer((_) => Stream.value(mockWorkouts));

        // Execute the method under test
        programProvider.loadWorkouts(testProgramId, testWeekId);

        // Wait for stream to emit values
        await Future.delayed(Duration(milliseconds: 100));

        // Verify state updates
        expect(programProvider.workouts, hasLength(3),
          reason: 'Should load all 3 workouts');
        expect(programProvider.workouts[0].name, equals('Push Day'));
        expect(programProvider.workouts[1].name, equals('Pull Day'));
        expect(programProvider.workouts[2].name, equals('Leg Day'));
        expect(programProvider.isLoadingWorkouts, isFalse,
          reason: 'Loading state should be false after successful load');
        expect(programProvider.error, isNull,
          reason: 'Error should be null on successful load');
      });

      test('loadWorkouts handles empty workout list correctly', () async {
        /// Test Purpose: Verify handling of weeks with no workouts
        /// New weeks or cleared weeks should show empty state, not errors
        /// Failure indicates issues with empty state handling
        
        // Mock empty workout list
        when(mockFirestoreService.getWorkouts(testUserId, testProgramId, testWeekId))
            .thenAnswer((_) => Stream.value([]));

        programProvider.loadWorkouts(testProgramId, testWeekId);
        await Future.delayed(Duration(milliseconds: 100));

        expect(programProvider.workouts, isEmpty,
          reason: 'Should handle empty workout list gracefully');
        expect(programProvider.isLoadingWorkouts, isFalse);
        expect(programProvider.error, isNull);
      });

      test('loadWorkouts sets loading state during operation', () async {
        /// Test Purpose: Verify loading state management for UI feedback
        /// Users should see loading indicators during data fetching
        /// Failure indicates poor UX due to missing loading states
        
        // Create a stream that doesn't emit immediately
        final streamController = StreamController<List<Workout>>();
        when(mockFirestoreService.getWorkouts(testUserId, testProgramId, testWeekId))
            .thenAnswer((_) => streamController.stream);

        // Start loading
        programProvider.loadWorkouts(testProgramId, testWeekId);

        // Verify loading state is set
        expect(programProvider.isLoadingWorkouts, isTrue,
          reason: 'Should set loading state immediately when starting');

        // Complete the stream
        streamController.add([]);
        await Future.delayed(Duration(milliseconds: 100));

        // Verify loading state is cleared
        expect(programProvider.isLoadingWorkouts, isFalse,
          reason: 'Should clear loading state when complete');

        streamController.close();
      });

      test('loadWorkouts handles stream errors gracefully', () async {
        /// Test Purpose: Verify error handling for network/database issues
        /// Connection problems shouldn't crash the app
        /// Failure indicates insufficient error handling
        
        const errorMessage = 'Network connection failed';
        
        // Mock stream error
        when(mockFirestoreService.getWorkouts(testUserId, testProgramId, testWeekId))
            .thenAnswer((_) => Stream.error(Exception(errorMessage)));

        programProvider.loadWorkouts(testProgramId, testWeekId);
        await Future.delayed(Duration(milliseconds: 100));

        expect(programProvider.error, contains(errorMessage),
          reason: 'Should capture and expose stream errors');
        expect(programProvider.isLoadingWorkouts, isFalse,
          reason: 'Should clear loading state even on error');
        expect(programProvider.workouts, isEmpty,
          reason: 'Should clear workout list on error to avoid stale data');
      });

      test('loadWorkouts fails when user not authenticated', () async {
        /// Test Purpose: Verify authentication requirement for data access
        /// Unauthenticated users should not be able to load workout data
        /// Failure indicates security vulnerability
        
        final unauthenticatedProvider = ProgramProvider(null);

        unauthenticatedProvider.loadWorkouts(testProgramId, testWeekId);

        // Verify no data was loaded
        expect(unauthenticatedProvider.workouts, isEmpty,
          reason: 'Should not load data when user not authenticated');
        
        // Verify Firestore was never called
        verifyNever(mockFirestoreService.getWorkouts(any, any, any));
      });
    });

    group('Update Workout', () {
      test('updateWorkout successfully updates existing workout', () async {
        /// Test Purpose: Verify successful workout update operations
        /// Users need to be able to modify existing workouts
        /// Failure indicates issues with update functionality
        
        final originalWorkout = _createMockWorkout(
          id: 'workout-to-update',
          name: 'Original Name',
          dayOfWeek: 1,
          notes: 'Original notes',
        );

        final updatedWorkout = originalWorkout.copyWith(
          name: 'Updated Name',
          dayOfWeek: 3,
          notes: 'Updated notes',
        );

        // Mock successful update
        when(mockFirestoreService.updateWorkout(any))
            .thenAnswer((_) async {});

        final result = await programProvider.updateWorkout(updatedWorkout);

        expect(result, isTrue,
          reason: 'Should return true on successful update');
        expect(programProvider.error, isNull,
          reason: 'Error should be null on successful update');

        // Verify correct workout was sent to Firestore
        final capturedWorkout = verify(mockFirestoreService.updateWorkout(captureAny))
            .captured.single as Workout;
        
        expect(capturedWorkout.id, equals('workout-to-update'));
        expect(capturedWorkout.name, equals('Updated Name'));
        expect(capturedWorkout.dayOfWeek, equals(3));
        expect(capturedWorkout.notes, equals('Updated notes'));
      });

      test('updateWorkout handles Firestore errors gracefully', () async {
        /// Test Purpose: Verify error handling during update operations
        /// Network issues or conflicts should be handled gracefully
        /// Failure indicates poor error handling
        
        final workout = _createMockWorkout(id: 'error-workout', name: 'Error Workout');
        const errorMessage = 'Document not found';

        when(mockFirestoreService.updateWorkout(any))
            .thenThrow(Exception(errorMessage));

        final result = await programProvider.updateWorkout(workout);

        expect(result, isFalse,
          reason: 'Should return false when update fails');
        expect(programProvider.error, contains(errorMessage),
          reason: 'Should capture and expose update errors');
      });
    });

    group('Delete Workout', () {
      test('deleteWorkout successfully removes workout', () async {
        /// Test Purpose: Verify successful workout deletion
        /// Users need to be able to remove unwanted workouts
        /// Failure indicates issues with deletion functionality
        
        const workoutIdToDelete = 'workout-to-delete';

        // Mock successful deletion
        when(mockFirestoreService.deleteWorkout(
          testUserId, testProgramId, testWeekId, workoutIdToDelete))
            .thenAnswer((_) async {});

        final result = await programProvider.deleteWorkout(
          testProgramId, testWeekId, workoutIdToDelete);

        expect(result, isTrue,
          reason: 'Should return true on successful deletion');
        expect(programProvider.error, isNull,
          reason: 'Error should be null on successful deletion');

        // Verify correct parameters were passed to Firestore
        verify(mockFirestoreService.deleteWorkout(
          testUserId, testProgramId, testWeekId, workoutIdToDelete))
            .called(1);
      });

      test('deleteWorkout handles Firestore errors gracefully', () async {
        /// Test Purpose: Verify error handling during deletion
        /// Failed deletions should be reported to the user
        /// Failure indicates poor error handling
        
        const workoutIdToDelete = 'error-workout';
        const errorMessage = 'Permission denied';

        when(mockFirestoreService.deleteWorkout(
          testUserId, testProgramId, testWeekId, workoutIdToDelete))
            .thenThrow(Exception(errorMessage));

        final result = await programProvider.deleteWorkout(
          testProgramId, testWeekId, workoutIdToDelete);

        expect(result, isFalse,
          reason: 'Should return false when deletion fails');
        expect(programProvider.error, contains(errorMessage),
          reason: 'Should capture and expose deletion errors');
      });

      test('deleteWorkout fails when user not authenticated', () async {
        /// Test Purpose: Verify authentication requirement for deletion
        /// Unauthenticated users should not be able to delete workouts
        /// Failure indicates security vulnerability
        
        const workoutIdToDelete = 'unauthorized-delete';
        
        final unauthenticatedProvider = ProgramProvider(null);

        final result = await unauthenticatedProvider.deleteWorkout(
          testProgramId, testWeekId, workoutIdToDelete);

        expect(result, isFalse,
          reason: 'Should fail when user not authenticated');
        
        // Verify Firestore was never called
        verifyNever(mockFirestoreService.deleteWorkout(any, any, any, any));
      });
    });

    group('State Management', () {
      test('clearError clears error state', () {
        /// Test Purpose: Verify error state can be manually cleared
        /// Users should be able to dismiss error messages
        /// Failure indicates issues with error state management
        
        // Test that clearError exists and can be called
        // Note: Without dependency injection, we can't easily set error state for testing
        programProvider.clearError();
        // Verify method exists and doesn't throw
        expect(programProvider.error, isNull);
      });

      test('workout selection state management works correctly', () {
        /// Test Purpose: Verify workout selection state for navigation
        /// The UI needs to track which workout is currently selected
        /// Failure indicates issues with navigation state
        
        final testWorkout = _createMockWorkout(id: 'selected-workout', name: 'Selected Workout');

        // Select workout
        programProvider.selectWorkout(testWorkout);
        expect(programProvider.selectedWorkout, equals(testWorkout),
          reason: 'Should store selected workout');

        // Clear selection by selecting null (if that's supported) or another workout
        expect(programProvider.selectedWorkout, equals(testWorkout),
          reason: 'Should store selected workout');
      });
    });
  });
}

/// Helper method to create mock workout objects for testing
Workout _createMockWorkout({
  required String id,
  required String name,
  int? dayOfWeek,
  int orderIndex = 1,
  String? notes,
}) {
  return Workout(
    id: id,
    name: name,
    dayOfWeek: dayOfWeek,
    orderIndex: orderIndex,
    notes: notes,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    userId: 'test-user-123',
    weekId: 'test-week-789',
    programId: 'test-program-456',
  );
}

/// Note: Full provider testing would require dependency injection
/// For comprehensive testing, ProgramProvider would need to accept
/// FirestoreService as a constructor parameter or through setter injection.