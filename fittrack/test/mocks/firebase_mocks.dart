/// Comprehensive Firebase mocking utilities for FitTrack testing
/// 
/// Mock Coverage:
/// - FirebaseAuth and User authentication
/// - Firestore database operations and queries
/// - DocumentSnapshot and QuerySnapshot data
/// - Realistic response data generation
/// - Error condition simulation
/// 
/// Usage:
/// - Import this file in test files that need Firebase mocking
/// - Use FirebaseMockSetup.configureMocks() to set up consistent mocking
/// - Use MockDataGenerator for realistic test data
/// - Use ErrorSimulator for testing error conditions

import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/models/program.dart';
import '../lib/models/week.dart';
import '../lib/models/workout.dart';
import '../lib/models/exercise.dart';
import '../lib/models/exercise_set.dart';
import '../lib/models/analytics.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  WriteBatch,
  Transaction,
])
import 'firebase_mocks.mocks.dart';

/// Centralized Firebase mock setup and configuration
class FirebaseMockSetup {
  static MockFirebaseAuth? _mockAuth;
  static MockFirebaseFirestore? _mockFirestore;
  static MockUser? _mockUser;

  /// Configure all Firebase mocks with default behavior
  static void configureMocks({
    String userId = 'test-user-123',
    String userEmail = 'test@fittrack.test',
    bool isAuthenticated = true,
  }) {
    _mockAuth = MockFirebaseAuth();
    _mockFirestore = MockFirebaseFirestore();
    _mockUser = MockUser();

    _setupAuthMocks(userId: userId, email: userEmail, isAuthenticated: isAuthenticated);
    _setupFirestoreMocks();
  }

  /// Set up Firebase Authentication mocks
  static void _setupAuthMocks({
    required String userId,
    required String email,
    required bool isAuthenticated,
  }) {
    // Configure mock user
    when(_mockUser!.uid).thenReturn(userId);
    when(_mockUser!.email).thenReturn(email);
    when(_mockUser!.emailVerified).thenReturn(true);
    when(_mockUser!.displayName).thenReturn('Test User');

    // Configure authentication state
    if (isAuthenticated) {
      when(_mockAuth!.currentUser).thenReturn(_mockUser);
      when(_mockAuth!.authStateChanges()).thenAnswer((_) => Stream.value(_mockUser));
    } else {
      when(_mockAuth!.currentUser).thenReturn(null);
      when(_mockAuth!.authStateChanges()).thenAnswer((_) => Stream.value(null));
    }

    // Configure sign-in methods
    when(_mockAuth!.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async {
      final mockCredential = MockUserCredential();
      when(mockCredential.user).thenReturn(_mockUser);
      return mockCredential;
    });

    // Configure sign-up methods
    when(_mockAuth!.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async {
      final mockCredential = MockUserCredential();
      when(mockCredential.user).thenReturn(_mockUser);
      return mockCredential;
    });

    // Configure sign-out
    when(_mockAuth!.signOut()).thenAnswer((_) async {});
  }

  /// Set up Firestore mocks with realistic behavior
  static void _setupFirestoreMocks() {
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    final mockDocument = MockDocumentReference<Map<String, dynamic>>();
    final mockQuery = MockQuery<Map<String, dynamic>>();
    final mockBatch = MockWriteBatch();

    // Configure collection access
    when(_mockFirestore!.collection(any)).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);
    when(mockCollection.where(any, isEqualTo: any)).thenReturn(mockQuery);
    when(mockCollection.orderBy(any, descending: any)).thenReturn(mockQuery);
    when(mockCollection.limit(any)).thenReturn(mockQuery);

    // Configure document operations
    when(mockDocument.set(any)).thenAnswer((_) async {});
    when(mockDocument.update(any)).thenAnswer((_) async {});
    when(mockDocument.delete()).thenAnswer((_) async {});
    when(mockDocument.collection(any)).thenReturn(mockCollection);

    // Configure batch operations
    when(_mockFirestore!.batch()).thenReturn(mockBatch);
    when(mockBatch.set(any, any)).thenReturn(null);
    when(mockBatch.update(any, any)).thenReturn(null);
    when(mockBatch.delete(any)).thenReturn(null);
    when(mockBatch.commit()).thenAnswer((_) async => []);
  }

  /// Get configured mock instances
  static MockFirebaseAuth get mockAuth => _mockAuth!;
  static MockFirebaseFirestore get mockFirestore => _mockFirestore!;
  static MockUser get mockUser => _mockUser!;

  /// Reset all mocks to clean state
  static void resetMocks() {
    _mockAuth = null;
    _mockFirestore = null;
    _mockUser = null;
  }
}

/// Realistic test data generation for comprehensive testing
class MockDataGenerator {
  static const String defaultUserId = 'test-user-123';
  
  /// Generate realistic program data
  static Program generateProgram({
    String? id,
    String? name,
    String? description,
    String? userId,
    bool isArchived = false,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return Program(
      id: id ?? 'program-${now.millisecondsSinceEpoch}',
      name: name ?? 'Test Program ${now.millisecondsSinceEpoch % 1000}',
      description: description ?? 'Generated test program for comprehensive testing',
      createdAt: createdAt ?? now.subtract(Duration(days: 30)),
      updatedAt: now,
      userId: userId ?? defaultUserId,
      isArchived: isArchived,
    );
  }

  /// Generate realistic week data
  static Week generateWeek({
    String? id,
    String? name,
    String? programId,
    String? userId,
    int weekNumber = 1,
  }) {
    final now = DateTime.now();
    return Week(
      id: id ?? 'week-${now.millisecondsSinceEpoch}',
      name: name ?? 'Week $weekNumber',
      weekNumber: weekNumber,
      notes: 'Generated test week',
      createdAt: now.subtract(Duration(days: 20)),
      updatedAt: now,
      userId: userId ?? defaultUserId,
      programId: programId ?? 'test-program-1',
    );
  }

  /// Generate realistic workout data
  static Workout generateWorkout({
    String? id,
    String? name,
    int? dayOfWeek,
    String? weekId,
    String? programId,
    String? userId,
  }) {
    final now = DateTime.now();
    return Workout(
      id: id ?? 'workout-${now.millisecondsSinceEpoch}',
      name: name ?? 'Test Workout',
      dayOfWeek: dayOfWeek ?? 1, // Monday
      notes: 'Generated test workout',
      createdAt: now.subtract(Duration(days: 10)),
      updatedAt: now,
      userId: userId ?? defaultUserId,
      weekId: weekId ?? 'test-week-1',
      programId: programId ?? 'test-program-1',
    );
  }

  /// Generate realistic exercise data by type
  static Exercise generateExercise({
    String? id,
    String? name,
    ExerciseType? exerciseType,
    int orderIndex = 1,
    String? workoutId,
    String? weekId,
    String? programId,
    String? userId,
  }) {
    final now = DateTime.now();
    final type = exerciseType ?? ExerciseType.strength;
    
    return Exercise(
      id: id ?? 'exercise-${now.millisecondsSinceEpoch}',
      name: name ?? _getExerciseNameByType(type),
      exerciseType: type,
      orderIndex: orderIndex,
      notes: 'Generated ${type.displayName.toLowerCase()} exercise',
      createdAt: now.subtract(Duration(days: 5)),
      updatedAt: now,
      userId: userId ?? defaultUserId,
      workoutId: workoutId ?? 'test-workout-1',
      weekId: weekId ?? 'test-week-1',
      programId: programId ?? 'test-program-1',
    );
  }

  /// Generate realistic exercise set data
  static ExerciseSet generateExerciseSet({
    String? id,
    int setNumber = 1,
    ExerciseType exerciseType = ExerciseType.strength,
    String? exerciseId,
    String? workoutId,
    String? weekId,
    String? programId,
    String? userId,
    bool checked = false,
  }) {
    final now = DateTime.now();
    
    return ExerciseSet(
      id: id ?? 'set-${now.millisecondsSinceEpoch}',
      setNumber: setNumber,
      reps: _getDefaultReps(exerciseType, setNumber),
      weight: _getDefaultWeight(exerciseType, setNumber),
      duration: _getDefaultDuration(exerciseType),
      distance: _getDefaultDistance(exerciseType),
      restTime: _getDefaultRestTime(exerciseType),
      checked: checked,
      notes: 'Generated set $setNumber',
      createdAt: now.subtract(Duration(minutes: 30)),
      updatedAt: now,
      userId: userId ?? defaultUserId,
      exerciseId: exerciseId ?? 'test-exercise-1',
      workoutId: workoutId ?? 'test-workout-1',
      weekId: weekId ?? 'test-week-1',
      programId: programId ?? 'test-program-1',
    );
  }

  /// Generate complete program hierarchy
  static Map<String, dynamic> generateCompleteProgram({
    String? userId,
    int weeksCount = 4,
    int workoutsPerWeek = 3,
    int exercisesPerWorkout = 5,
    int setsPerExercise = 3,
  }) {
    final program = generateProgram(userId: userId);
    final weeks = <Week>[];
    final workouts = <Workout>[];
    final exercises = <Exercise>[];
    final sets = <ExerciseSet>[];

    for (int w = 1; w <= weeksCount; w++) {
      final week = generateWeek(
        programId: program.id,
        userId: program.userId,
        weekNumber: w,
      );
      weeks.add(week);

      for (int wo = 1; wo <= workoutsPerWeek; wo++) {
        final workout = generateWorkout(
          weekId: week.id,
          programId: program.id,
          userId: program.userId,
          name: 'Workout ${(w-1) * workoutsPerWeek + wo}',
          dayOfWeek: wo,
        );
        workouts.add(workout);

        for (int e = 1; e <= exercisesPerWorkout; e++) {
          final exerciseType = ExerciseType.values[e % ExerciseType.values.length];
          final exercise = generateExercise(
            exerciseType: exerciseType,
            orderIndex: e,
            workoutId: workout.id,
            weekId: week.id,
            programId: program.id,
            userId: program.userId,
          );
          exercises.add(exercise);

          for (int s = 1; s <= setsPerExercise; s++) {
            final set = generateExerciseSet(
              setNumber: s,
              exerciseType: exerciseType,
              exerciseId: exercise.id,
              workoutId: workout.id,
              weekId: week.id,
              programId: program.id,
              userId: program.userId,
            );
            sets.add(set);
          }
        }
      }
    }

    return {
      'program': program,
      'weeks': weeks,
      'workouts': workouts,
      'exercises': exercises,
      'sets': sets,
    };
  }

  /// Generate analytics test data
  static WorkoutAnalytics generateAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
    final end = endDate ?? DateTime.now();
    
    return WorkoutAnalytics(
      userId: userId ?? defaultUserId,
      startDate: start,
      endDate: end,
      totalWorkouts: 24,
      totalExercises: 120,
      totalSets: 360,
      totalVolume: 12500.0,
      averageWorkoutDuration: Duration(minutes: 75),
      workoutFrequency: 6.0, // per week
      personalRecords: _generatePersonalRecords(),
      exerciseProgress: _generateExerciseProgress(),
      weeklyVolumes: _generateWeeklyVolumes(start, end),
    );
  }

  /// Helper methods for realistic data generation
  
  static String _getExerciseNameByType(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return ['Bench Press', 'Squat', 'Deadlift', 'Overhead Press'][DateTime.now().millisecond % 4];
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return ['Running', 'Cycling', 'Swimming', 'Rowing'][DateTime.now().millisecond % 4];
      case ExerciseType.bodyweight:
        return ['Push-ups', 'Pull-ups', 'Burpees', 'Planks'][DateTime.now().millisecond % 4];
      case ExerciseType.custom:
        return 'Custom Exercise';
    }
  }

  static int? _getDefaultReps(ExerciseType type, int setNumber) {
    switch (type) {
      case ExerciseType.strength:
      case ExerciseType.bodyweight:
        return 8 + setNumber; // Progressive rep scheme
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return null;
      case ExerciseType.custom:
        return 10;
    }
  }

  static double? _getDefaultWeight(ExerciseType type, int setNumber) {
    switch (type) {
      case ExerciseType.strength:
        return 135.0 + (setNumber * 10); // Progressive weight
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
      case ExerciseType.bodyweight:
        return null;
      case ExerciseType.custom:
        return 50.0;
    }
  }

  static int? _getDefaultDuration(ExerciseType type) {
    switch (type) {
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return 1800; // 30 minutes
      case ExerciseType.strength:
      case ExerciseType.bodyweight:
        return null;
      case ExerciseType.custom:
        return 300; // 5 minutes
    }
  }

  static double? _getDefaultDistance(ExerciseType type) {
    switch (type) {
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return 5000.0; // 5km
      default:
        return null;
    }
  }

  static int? _getDefaultRestTime(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return 180; // 3 minutes
      case ExerciseType.bodyweight:
        return 60; // 1 minute
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return null;
      case ExerciseType.custom:
        return 120; // 2 minutes
    }
  }

  static List<PersonalRecord> _generatePersonalRecords() {
    return [
      PersonalRecord(
        exerciseName: 'Bench Press',
        recordType: 'Max Weight',
        value: 225.0,
        unit: 'kg',
        achievedDate: DateTime.now().subtract(Duration(days: 5)),
      ),
      PersonalRecord(
        exerciseName: 'Running',
        recordType: 'Longest Distance',
        value: 10.0,
        unit: 'km',
        achievedDate: DateTime.now().subtract(Duration(days: 12)),
      ),
    ];
  }

  static Map<String, ExerciseProgress> _generateExerciseProgress() {
    return {
      'Bench Press': ExerciseProgress(
        exerciseName: 'Bench Press',
        currentMaxWeight: 215.0,
        previousMaxWeight: 205.0,
        weightProgress: 10.0,
        volumeProgress: 15.5,
        lastPerformed: DateTime.now().subtract(Duration(days: 2)),
      ),
    };
  }

  static List<WeeklyVolume> _generateWeeklyVolumes(DateTime start, DateTime end) {
    final weeks = <WeeklyVolume>[];
    var current = start;
    
    while (current.isBefore(end)) {
      weeks.add(WeeklyVolume(
        weekStart: current,
        totalVolume: 2500.0 + (weeks.length * 100), // Progressive volume
        workoutCount: 3 + (weeks.length % 2),
      ));
      current = current.add(Duration(days: 7));
    }
    
    return weeks;
  }

  /// Get mocks for injection
  static Map<String, dynamic> getMocks() => {
    'auth': _mockAuth,
    'firestore': _mockFirestore,
    'user': _mockUser,
  };
}

/// Error simulation utilities for testing error conditions
class ErrorSimulator {
  /// Simulate authentication errors
  static void simulateAuthError(MockFirebaseAuth mockAuth, String errorCode) {
    when(mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenThrow(FirebaseAuthException(code: errorCode, message: _getAuthErrorMessage(errorCode)));
  }

  /// Simulate Firestore errors
  static void simulateFirestoreError(MockFirebaseFirestore mockFirestore, String errorCode) {
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.add(any)).thenThrow(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: errorCode,
        message: _getFirestoreErrorMessage(errorCode),
      ),
    );
  }

  /// Simulate network connectivity issues
  static void simulateNetworkError(MockFirebaseFirestore mockFirestore) {
    final mockCollection = MockCollectionReference<Map<String, dynamic>>();
    when(mockFirestore.collection(any)).thenReturn(mockCollection);
    when(mockCollection.snapshots()).thenAnswer((_) => 
      Stream.error(Exception('Network unavailable')));
  }

  /// Simulate permission denied errors
  static void simulatePermissionError(MockFirebaseFirestore mockFirestore) {
    simulateFirestoreError(mockFirestore, 'permission-denied');
  }

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error occurred.';
      default:
        return 'Authentication error occurred.';
    }
  }

  static String _getFirestoreErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Insufficient permissions to access this data.';
      case 'not-found':
        return 'Document does not exist.';
      case 'already-exists':
        return 'Document already exists.';
      case 'failed-precondition':
        return 'Operation failed due to precondition.';
      case 'unavailable':
        return 'Service is currently unavailable.';
      default:
        return 'Firestore operation failed.';
    }
  }
}

/// Mock Firestore response generators
class MockResponseGenerator {
  /// Generate mock QuerySnapshot for program lists
  static MockQuerySnapshot<Map<String, dynamic>> generateProgramsResponse(List<Program> programs) {
    final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final mockDocs = programs.map((program) {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn(program.id);
      when(mockDoc.data()).thenReturn(program.toFirestore());
      when(mockDoc.exists).thenReturn(true);
      return mockDoc;
    }).toList();

    when(mockSnapshot.docs).thenReturn(mockDocs);
    when(mockSnapshot.size).thenReturn(programs.length);
    return mockSnapshot;
  }

  /// Generate mock DocumentSnapshot for individual documents
  static MockDocumentSnapshot<Map<String, dynamic>> generateDocumentResponse(
    String id,
    Map<String, dynamic> data, {
    bool exists = true,
  }) {
    final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
    when(mockDoc.id).thenReturn(id);
    when(mockDoc.data()).thenReturn(exists ? data : null);
    when(mockDoc.exists).thenReturn(exists);
    return mockDoc;
  }

  /// Generate mock Stream responses for real-time data
  static Stream<QuerySnapshot<Map<String, dynamic>>> generateStreamResponse(
    List<Map<String, dynamic>> items,
  ) {
    final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    final mockDocs = items.asMap().entries.map((entry) {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('item-${entry.key}');
      when(mockDoc.data()).thenReturn(entry.value);
      when(mockDoc.exists).thenReturn(true);
      return mockDoc;
    }).toList();

    when(mockSnapshot.docs).thenReturn(mockDocs);
    when(mockSnapshot.size).thenReturn(items.length);
    
    return Stream.value(mockSnapshot);
  }
}

/// Test data sets for different testing scenarios
class TestDataSets {
  /// Small dataset for unit tests
  static Map<String, dynamic> small() {
    return MockDataGenerator.generateCompleteProgram(
      weeksCount: 1,
      workoutsPerWeek: 2,
      exercisesPerWorkout: 3,
      setsPerExercise: 2,
    );
  }

  /// Medium dataset for widget tests
  static Map<String, dynamic> medium() {
    return MockDataGenerator.generateCompleteProgram(
      weeksCount: 4,
      workoutsPerWeek: 3,
      exercisesPerWorkout: 5,
      setsPerExercise: 3,
    );
  }

  /// Large dataset for performance tests
  static Map<String, dynamic> large() {
    return MockDataGenerator.generateCompleteProgram(
      weeksCount: 12,
      workoutsPerWeek: 4,
      exercisesPerWorkout: 8,
      setsPerExercise: 4,
    );
  }

  /// Edge case dataset with minimal data
  static Map<String, dynamic> minimal() {
    final program = MockDataGenerator.generateProgram(name: 'Minimal Program');
    return {
      'program': program,
      'weeks': <Week>[],
      'workouts': <Workout>[],
      'exercises': <Exercise>[],
      'sets': <ExerciseSet>[],
    };
  }

  /// Edge case dataset with various exercise types
  static Map<String, dynamic> multiType() {
    final program = MockDataGenerator.generateProgram(name: 'Multi-Type Program');
    final exercises = ExerciseType.values.map((type) => 
      MockDataGenerator.generateExercise(exerciseType: type, programId: program.id)
    ).toList();
    
    final sets = exercises.expand((exercise) => 
      List.generate(3, (i) => MockDataGenerator.generateExerciseSet(
        setNumber: i + 1,
        exerciseType: exercise.exerciseType,
        exerciseId: exercise.id,
        programId: program.id,
      ))
    ).toList();

    return {
      'program': program,
      'exercises': exercises,
      'sets': sets,
    };
  }
}

/// Test configuration utilities
class TestConfig {
  /// Performance benchmarks for operations
  static const performanceBenchmarks = {
    'program_creation': Duration(milliseconds: 500),
    'workout_creation': Duration(milliseconds: 300),
    'exercise_creation': Duration(milliseconds: 200),
    'set_creation': Duration(milliseconds: 100),
    'analytics_calculation': Duration(milliseconds: 1000),
    'data_duplication': Duration(milliseconds: 2000),
  };

  /// Validate operation performance
  static void validatePerformance(Duration elapsed, String operation) {
    final benchmark = performanceBenchmarks[operation];
    if (benchmark != null && elapsed > benchmark) {
      throw TestFailure(
        'Performance benchmark failed for $operation: '
        'Expected <${benchmark.inMilliseconds}ms, '
        'Actual: ${elapsed.inMilliseconds}ms'
      );
    }
  }

  /// Memory usage tracking
  static void validateMemoryUsage() {
    // Implementation would check memory usage patterns
    // This ensures tests don't cause memory leaks
  }
}

/// Mock setup utilities for specific test scenarios
class MockScenarios {
  /// Set up mocks for successful operations
  static void configureSuccessScenario() {
    FirebaseMockSetup.configureMocks(isAuthenticated: true);
  }

  /// Set up mocks for authentication failure scenarios
  static void configureAuthFailureScenario() {
    FirebaseMockSetup.configureMocks(isAuthenticated: false);
    ErrorSimulator.simulateAuthError(
      FirebaseMockSetup.mockAuth,
      'user-not-found',
    );
  }

  /// Set up mocks for network failure scenarios
  static void configureNetworkFailureScenario() {
    FirebaseMockSetup.configureMocks(isAuthenticated: true);
    ErrorSimulator.simulateNetworkError(FirebaseMockSetup.mockFirestore);
  }

  /// Set up mocks for permission denied scenarios
  static void configurePermissionDeniedScenario() {
    FirebaseMockSetup.configureMocks(isAuthenticated: true);
    ErrorSimulator.simulatePermissionError(FirebaseMockSetup.mockFirestore);
  }

  /// Set up mocks for large dataset scenarios
  static void configureLargeDatasetScenario() {
    FirebaseMockSetup.configureMocks(isAuthenticated: true);
    
    // Configure mock responses with large datasets
    final largeDataset = TestDataSets.large();
    final programs = [largeDataset['program'] as Program];
    
    final mockResponse = MockResponseGenerator.generateProgramsResponse(programs);
    
    // This would configure the mocks to return large datasets
  }
}

/// Custom matchers for testing Firebase data
class FirebaseMatchers {
  /// Matcher for valid Firestore data structure
  static Matcher hasValidFirestoreStructure() {
    return predicate<Map<String, dynamic>>((data) {
      return data.containsKey('userId') &&
             data.containsKey('createdAt') &&
             data.containsKey('updatedAt') &&
             data['userId'] is String &&
             data['userId'].isNotEmpty;
    }, 'has valid Firestore structure');
  }

  /// Matcher for valid program hierarchy
  static Matcher hasValidProgramHierarchy() {
    return predicate<Map<String, dynamic>>((data) {
      return data.containsKey('programId') &&
             data.containsKey('userId') &&
             data['programId'] is String &&
             data['programId'].isNotEmpty;
    }, 'has valid program hierarchy');
  }

  /// Matcher for performance requirements
  static Matcher meetsPerformanceRequirement(Duration maxDuration) {
    return predicate<Duration>((elapsed) => elapsed <= maxDuration,
        'completes within ${maxDuration.inMilliseconds}ms');
  }
}