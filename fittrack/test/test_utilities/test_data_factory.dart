/// Comprehensive test data factory for FitTrack testing
/// 
/// Factory Coverage:
/// - Realistic test data generation for all models
/// - Edge case and boundary condition data
/// - Performance testing datasets
/// - Localized and internationalized data
/// - Error condition simulation data
/// 
/// Usage:
/// - Use TestDataFactory methods to generate consistent test data
/// - Use DatasetBuilder for complex hierarchical data
/// - Use EdgeCaseGenerator for boundary testing
/// - Use PerformanceDatasets for load testing

import 'dart:math';
import '../lib/models/program.dart';
import '../lib/models/week.dart';
import '../lib/models/workout.dart';
import '../lib/models/exercise.dart';
import '../lib/models/exercise_set.dart';
import '../lib/models/analytics.dart';

/// Main factory for generating test data
class TestDataFactory {
  static final Random _random = Random();
  static int _idCounter = 1000;

  /// Generate unique ID for test objects
  static String generateId(String prefix) {
    return '$prefix-${_idCounter++}-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate realistic program data
  static Program createProgram({
    String? id,
    String? name,
    String? description,
    String userId = 'test-user-123',
    bool isArchived = false,
    DateTime? createdAt,
    ProgramTemplate template = ProgramTemplate.general,
  }) {
    final now = DateTime.now();
    final programData = _getProgramTemplate(template);
    
    return Program(
      id: id ?? generateId('program'),
      name: name ?? programData['name'],
      description: description ?? programData['description'],
      createdAt: createdAt ?? now.subtract(Duration(days: _random.nextInt(365))),
      updatedAt: now.subtract(Duration(hours: _random.nextInt(24))),
      userId: userId,
      isArchived: isArchived,
    );
  }

  /// Generate realistic week data
  static Week createWeek({
    String? id,
    String? name,
    int? weekNumber,
    String programId = 'test-program-1',
    String userId = 'test-user-123',
    WeekTemplate template = WeekTemplate.standard,
  }) {
    final now = DateTime.now();
    final weekData = _getWeekTemplate(template);
    
    return Week(
      id: id ?? generateId('week'),
      name: name ?? weekData['name'],
      weekNumber: weekNumber ?? weekData['weekNumber'],
      notes: weekData['notes'],
      createdAt: now.subtract(Duration(days: _random.nextInt(90))),
      updatedAt: now.subtract(Duration(hours: _random.nextInt(48))),
      userId: userId,
      programId: programId,
    );
  }

  /// Generate realistic workout data
  static Workout createWorkout({
    String? id,
    String? name,
    int? dayOfWeek,
    String weekId = 'test-week-1',
    String programId = 'test-program-1',
    String userId = 'test-user-123',
    WorkoutTemplate template = WorkoutTemplate.strength,
  }) {
    final now = DateTime.now();
    final workoutData = _getWorkoutTemplate(template);
    
    return Workout(
      id: id ?? generateId('workout'),
      name: name ?? workoutData['name'],
      dayOfWeek: dayOfWeek ?? workoutData['dayOfWeek'],
      notes: workoutData['notes'],
      createdAt: now.subtract(Duration(days: _random.nextInt(30))),
      updatedAt: now.subtract(Duration(hours: _random.nextInt(72))),
      userId: userId,
      weekId: weekId,
      programId: programId,
    );
  }

  /// Generate realistic exercise data
  static Exercise createExercise({
    String? id,
    String? name,
    ExerciseType? exerciseType,
    int orderIndex = 1,
    String workoutId = 'test-workout-1',
    String weekId = 'test-week-1',
    String programId = 'test-program-1',
    String userId = 'test-user-123',
  }) {
    final now = DateTime.now();
    final type = exerciseType ?? ExerciseType.strength;
    
    return Exercise(
      id: id ?? generateId('exercise'),
      name: name ?? _getExerciseNameByType(type),
      exerciseType: type,
      orderIndex: orderIndex,
      notes: _getExerciseNotesByType(type),
      createdAt: now.subtract(Duration(days: _random.nextInt(14))),
      updatedAt: now.subtract(Duration(minutes: _random.nextInt(1440))),
      userId: userId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    );
  }

  /// Generate realistic exercise set data
  static ExerciseSet createExerciseSet({
    String? id,
    int setNumber = 1,
    ExerciseType exerciseType = ExerciseType.strength,
    String exerciseId = 'test-exercise-1',
    String workoutId = 'test-workout-1',
    String weekId = 'test-week-1',
    String programId = 'test-program-1',
    String userId = 'test-user-123',
    bool checked = false,
    SetIntensity intensity = SetIntensity.moderate,
  }) {
    final now = DateTime.now();
    
    return ExerciseSet(
      id: id ?? generateId('set'),
      setNumber: setNumber,
      reps: _getRealisticReps(exerciseType, intensity, setNumber),
      weight: _getRealisticWeight(exerciseType, intensity, setNumber),
      duration: _getRealisticDuration(exerciseType, intensity),
      distance: _getRealisticDistance(exerciseType, intensity),
      restTime: _getRealisticRestTime(exerciseType, intensity),
      checked: checked,
      notes: _getSetNotes(exerciseType, setNumber),
      createdAt: now.subtract(Duration(minutes: _random.nextInt(180))),
      updatedAt: now.subtract(Duration(minutes: _random.nextInt(30))),
      userId: userId,
      exerciseId: exerciseId,
      workoutId: workoutId,
      weekId: weekId,
      programId: programId,
    );
  }

  /// Generate analytics data with realistic computations
  static WorkoutAnalytics createAnalytics({
    String userId = 'test-user-123',
    DateTime? startDate,
    DateTime? endDate,
    AnalyticsComplexity complexity = AnalyticsComplexity.moderate,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: 90));
    final end = endDate ?? DateTime.now();
    final days = end.difference(start).inDays;
    
    final baseMetrics = _getAnalyticsMetrics(complexity, days);
    
    return WorkoutAnalytics(
      userId: userId,
      startDate: start,
      endDate: end,
      totalWorkouts: baseMetrics['workouts'],
      totalExercises: baseMetrics['exercises'],
      totalSets: baseMetrics['sets'],
      totalVolume: baseMetrics['volume'],
      averageWorkoutDuration: Duration(minutes: baseMetrics['avgDuration']),
      workoutFrequency: baseMetrics['frequency'],
      personalRecords: _generatePersonalRecords(complexity),
      exerciseProgress: _generateExerciseProgress(complexity),
      weeklyVolumes: _generateWeeklyVolumes(start, end, complexity),
    );
  }

  /// Template-based data generation helpers
  
  static Map<String, dynamic> _getProgramTemplate(ProgramTemplate template) {
    switch (template) {
      case ProgramTemplate.strength:
        return {
          'name': 'Strength Training Program',
          'description': 'Comprehensive strength building program focusing on compound movements',
        };
      case ProgramTemplate.cardio:
        return {
          'name': 'Cardio Fitness Program',
          'description': 'Cardiovascular endurance and fat burning program',
        };
      case ProgramTemplate.bodyweight:
        return {
          'name': 'Bodyweight Training Program',
          'description': 'No equipment required bodyweight fitness program',
        };
      case ProgramTemplate.hybrid:
        return {
          'name': 'Hybrid Training Program',
          'description': 'Mixed training approach combining strength, cardio, and bodyweight',
        };
      case ProgramTemplate.general:
      default:
        return {
          'name': 'General Fitness Program',
          'description': 'Balanced fitness program for overall health and wellness',
        };
    }
  }

  static Map<String, dynamic> _getWeekTemplate(WeekTemplate template) {
    switch (template) {
      case WeekTemplate.deload:
        return {
          'name': 'Deload Week',
          'weekNumber': 4,
          'notes': 'Recovery week with reduced intensity',
        };
      case WeekTemplate.peak:
        return {
          'name': 'Peak Week',
          'weekNumber': 8,
          'notes': 'Maximum intensity training week',
        };
      case WeekTemplate.standard:
      default:
        return {
          'name': 'Week ${_random.nextInt(12) + 1}',
          'weekNumber': _random.nextInt(12) + 1,
          'notes': 'Standard training week with progressive overload',
        };
    }
  }

  static Map<String, dynamic> _getWorkoutTemplate(WorkoutTemplate template) {
    switch (template) {
      case WorkoutTemplate.strength:
        return {
          'name': ['Push Day', 'Pull Day', 'Leg Day'][_random.nextInt(3)],
          'dayOfWeek': _random.nextInt(7) + 1,
          'notes': 'Heavy compound movements with progressive overload',
        };
      case WorkoutTemplate.cardio:
        return {
          'name': ['HIIT Cardio', 'Steady State', 'Interval Training'][_random.nextInt(3)],
          'dayOfWeek': _random.nextInt(7) + 1,
          'notes': 'Cardiovascular endurance training session',
        };
      case WorkoutTemplate.recovery:
        return {
          'name': 'Recovery Session',
          'dayOfWeek': 7, // Sunday
          'notes': 'Light movement and mobility work',
        };
    }
  }

  static String _getExerciseNameByType(ExerciseType type) {
    final exercises = {
      ExerciseType.strength: ['Bench Press', 'Squat', 'Deadlift', 'Overhead Press', 'Barbell Row'],
      ExerciseType.cardio: ['Running', 'Cycling', 'Swimming', 'Elliptical', 'Stair Climber'],
      ExerciseType.bodyweight: ['Push-ups', 'Pull-ups', 'Dips', 'Burpees', 'Mountain Climbers'],
      ExerciseType.timeBased: ['Plank', 'Wall Sit', 'Dead Hang', 'Isometric Squat'],
      ExerciseType.custom: ['Custom Movement', 'Functional Exercise', 'Specialized Drill'],
    };
    
    final exerciseList = exercises[type] ?? exercises[ExerciseType.custom]!;
    return exerciseList[_random.nextInt(exerciseList.length)];
  }

  static String _getExerciseNotesByType(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return 'Focus on proper form and controlled movement';
      case ExerciseType.cardio:
        return 'Maintain target heart rate throughout the session';
      case ExerciseType.bodyweight:
        return 'Full range of motion with quality repetitions';
      case ExerciseType.timeBased:
        return 'Hold position with proper form';
      case ExerciseType.custom:
        return 'Follow specific movement pattern guidelines';
    }
  }

  static int? _getRealisticReps(ExerciseType type, SetIntensity intensity, int setNumber) {
    if (type == ExerciseType.cardio || type == ExerciseType.timeBased) return null;
    
    final baseReps = {
      SetIntensity.light: 15,
      SetIntensity.moderate: 10,
      SetIntensity.heavy: 6,
      SetIntensity.maximum: 3,
    }[intensity]!;
    
    // Account for fatigue in later sets
    final fatigueReduction = (setNumber - 1) * 1;
    return math.max(1, baseReps - fatigueReduction + _random.nextInt(3) - 1);
  }

  static double? _getRealisticWeight(ExerciseType type, SetIntensity intensity, int setNumber) {
    if (type != ExerciseType.strength && type != ExerciseType.custom) return null;
    
    final baseWeights = {
      'Bench Press': {SetIntensity.light: 60.0, SetIntensity.moderate: 100.0, SetIntensity.heavy: 140.0, SetIntensity.maximum: 180.0},
      'Squat': {SetIntensity.light: 80.0, SetIntensity.moderate: 120.0, SetIntensity.heavy: 160.0, SetIntensity.maximum: 200.0},
      'Deadlift': {SetIntensity.light: 100.0, SetIntensity.moderate: 150.0, SetIntensity.heavy: 200.0, SetIntensity.maximum: 250.0},
    };
    
    final exerciseName = _getExerciseNameByType(type);
    final weightMap = baseWeights[exerciseName] ?? baseWeights['Bench Press']!;
    final baseWeight = weightMap[intensity]!;
    
    // Add some realistic variation
    return baseWeight + (_random.nextDouble() * 20 - 10);
  }

  static int? _getRealisticDuration(ExerciseType type, SetIntensity intensity) {
    if (type != ExerciseType.cardio && type != ExerciseType.timeBased && type != ExerciseType.custom) return null;
    
    final baseDurations = {
      SetIntensity.light: 1200, // 20 minutes
      SetIntensity.moderate: 1800, // 30 minutes
      SetIntensity.heavy: 2400, // 40 minutes
      SetIntensity.maximum: 3000, // 50 minutes
    };
    
    final baseDuration = baseDurations[intensity]!;
    return baseDuration + _random.nextInt(600) - 300; // ±5 minutes variation
  }

  static double? _getRealisticDistance(ExerciseType type, SetIntensity intensity) {
    if (type != ExerciseType.cardio && type != ExerciseType.timeBased) return null;
    
    final baseDistances = {
      SetIntensity.light: 3000.0, // 3km
      SetIntensity.moderate: 5000.0, // 5km
      SetIntensity.heavy: 8000.0, // 8km
      SetIntensity.maximum: 12000.0, // 12km
    };
    
    final baseDistance = baseDistances[intensity]!;
    return baseDistance + (_random.nextDouble() * 2000 - 1000); // ±1km variation
  }

  static int? _getRealisticRestTime(ExerciseType type, SetIntensity intensity) {
    final restTimes = {
      ExerciseType.strength: {
        SetIntensity.light: 120, // 2 minutes
        SetIntensity.moderate: 180, // 3 minutes
        SetIntensity.heavy: 240, // 4 minutes
        SetIntensity.maximum: 300, // 5 minutes
      },
      ExerciseType.bodyweight: {
        SetIntensity.light: 60, // 1 minute
        SetIntensity.moderate: 90, // 1.5 minutes
        SetIntensity.heavy: 120, // 2 minutes
        SetIntensity.maximum: 150, // 2.5 minutes
      },
    };
    
    return restTimes[type]?[intensity];
  }

  static String _getSetNotes(ExerciseType type, int setNumber) {
    final notes = {
      ExerciseType.strength: [
        'Good form maintained',
        'Felt strong today',
        'Slight fatigue from previous set',
        'Perfect rep range',
      ],
      ExerciseType.cardio: [
        'Good pace throughout',
        'Heart rate in target zone',
        'Feeling energized',
        'Consistent breathing',
      ],
      ExerciseType.bodyweight: [
        'Full range of motion',
        'Controlled tempo',
        'Good muscle activation',
        'Quality reps over quantity',
      ],
    };
    
    final typeNotes = notes[type] ?? notes[ExerciseType.strength]!;
    return typeNotes[_random.nextInt(typeNotes.length)];
  }

  static Map<String, int> _getAnalyticsMetrics(AnalyticsComplexity complexity, int days) {
    final multipliers = {
      AnalyticsComplexity.simple: 0.5,
      AnalyticsComplexity.moderate: 1.0,
      AnalyticsComplexity.complex: 2.0,
      AnalyticsComplexity.extreme: 5.0,
    };
    
    final multiplier = multipliers[complexity]!;
    final weeksInPeriod = days / 7;
    
    return {
      'workouts': (weeksInPeriod * 3 * multiplier).round(),
      'exercises': (weeksInPeriod * 15 * multiplier).round(),
      'sets': (weeksInPeriod * 45 * multiplier).round(),
      'volume': (weeksInPeriod * 2500 * multiplier).round(),
      'avgDuration': (75 * multiplier).round(),
      'frequency': (3.5 * multiplier).round(),
    };
  }

  static List<PersonalRecord> _generatePersonalRecords(AnalyticsComplexity complexity) {
    final recordCount = {
      AnalyticsComplexity.simple: 2,
      AnalyticsComplexity.moderate: 5,
      AnalyticsComplexity.complex: 10,
      AnalyticsComplexity.extreme: 20,
    }[complexity]!;

    return List.generate(recordCount, (index) {
      final exercises = ['Bench Press', 'Squat', 'Deadlift', 'Running', 'Pull-ups'];
      final recordTypes = ['Max Weight', 'Max Reps', 'Best Time', 'Longest Distance'];
      
      return PersonalRecord(
        exerciseName: exercises[index % exercises.length],
        recordType: recordTypes[index % recordTypes.length],
        value: 100.0 + (index * 25),
        unit: index % 2 == 0 ? 'kg' : (index % 3 == 0 ? 'reps' : 'min'),
        achievedDate: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
      );
    });
  }

  static Map<String, ExerciseProgress> _generateExerciseProgress(AnalyticsComplexity complexity) {
    final progressCount = {
      AnalyticsComplexity.simple: 3,
      AnalyticsComplexity.moderate: 8,
      AnalyticsComplexity.complex: 15,
      AnalyticsComplexity.extreme: 30,
    }[complexity]!;

    final progress = <String, ExerciseProgress>{};
    final exercises = ['Bench Press', 'Squat', 'Deadlift', 'Running', 'Pull-ups', 'Push-ups'];

    for (int i = 0; i < progressCount; i++) {
      final exerciseName = exercises[i % exercises.length];
      final currentMax = 100.0 + (i * 15);
      final previousMax = currentMax - (5 + _random.nextInt(20));
      
      progress[exerciseName] = ExerciseProgress(
        exerciseName: exerciseName,
        currentMaxWeight: currentMax,
        previousMaxWeight: previousMax,
        weightProgress: currentMax - previousMax,
        volumeProgress: 10.0 + _random.nextDouble() * 30,
        lastPerformed: DateTime.now().subtract(Duration(days: _random.nextInt(14))),
      );
    }

    return progress;
  }

  static List<WeeklyVolume> _generateWeeklyVolumes(
    DateTime start, 
    DateTime end, 
    AnalyticsComplexity complexity
  ) {
    final volumes = <WeeklyVolume>[];
    var current = start;
    var baseVolume = 2000.0;
    
    final volumeMultiplier = {
      AnalyticsComplexity.simple: 0.8,
      AnalyticsComplexity.moderate: 1.0,
      AnalyticsComplexity.complex: 1.5,
      AnalyticsComplexity.extreme: 3.0,
    }[complexity]!;

    while (current.isBefore(end)) {
      // Simulate realistic volume progression with some variation
      baseVolume += _random.nextDouble() * 200 - 100; // ±100 variation
      baseVolume = math.max(1000, baseVolume); // Minimum volume
      
      volumes.add(WeeklyVolume(
        weekStart: current,
        totalVolume: baseVolume * volumeMultiplier,
        workoutCount: 3 + _random.nextInt(3), // 3-5 workouts per week
      ));
      
      current = current.add(Duration(days: 7));
    }

    return volumes;
  }
}

/// Builder pattern for complex hierarchical data
class DatasetBuilder {
  final String userId;
  final List<Program> _programs = [];
  final Map<String, List<Week>> _weeks = {};
  final Map<String, List<Workout>> _workouts = {};
  final Map<String, List<Exercise>> _exercises = {};
  final Map<String, List<ExerciseSet>> _sets = {};

  DatasetBuilder({this.userId = 'test-user-123'});

  /// Add program to dataset
  DatasetBuilder addProgram({
    String? name,
    ProgramTemplate template = ProgramTemplate.general,
    bool isArchived = false,
  }) {
    final program = TestDataFactory.createProgram(
      name: name,
      userId: userId,
      template: template,
      isArchived: isArchived,
    );
    _programs.add(program);
    _weeks[program.id] = [];
    return this;
  }

  /// Add week to last program
  DatasetBuilder addWeek({
    String? name,
    WeekTemplate template = WeekTemplate.standard,
  }) {
    if (_programs.isEmpty) throw StateError('No program to add week to');
    
    final program = _programs.last;
    final week = TestDataFactory.createWeek(
      name: name,
      programId: program.id,
      userId: userId,
      template: template,
    );
    
    _weeks[program.id]!.add(week);
    _workouts[week.id] = [];
    return this;
  }

  /// Add workout to last week
  DatasetBuilder addWorkout({
    String? name,
    WorkoutTemplate template = WorkoutTemplate.strength,
    int? dayOfWeek,
  }) {
    final week = _getLastWeek();
    final workout = TestDataFactory.createWorkout(
      name: name,
      weekId: week.id,
      programId: week.programId,
      userId: userId,
      template: template,
      dayOfWeek: dayOfWeek,
    );
    
    _workouts[week.id]!.add(workout);
    _exercises[workout.id] = [];
    return this;
  }

  /// Add exercise to last workout
  DatasetBuilder addExercise({
    String? name,
    ExerciseType? exerciseType,
    int? orderIndex,
  }) {
    final workout = _getLastWorkout();
    final exercise = TestDataFactory.createExercise(
      name: name,
      exerciseType: exerciseType,
      orderIndex: orderIndex ?? (_exercises[workout.id]!.length + 1),
      workoutId: workout.id,
      weekId: workout.weekId,
      programId: workout.programId,
      userId: userId,
    );
    
    _exercises[workout.id]!.add(exercise);
    _sets[exercise.id] = [];
    return this;
  }

  /// Add set to last exercise
  DatasetBuilder addSet({
    int? setNumber,
    SetIntensity intensity = SetIntensity.moderate,
    bool checked = false,
  }) {
    final exercise = _getLastExercise();
    final set = TestDataFactory.createExerciseSet(
      setNumber: setNumber ?? (_sets[exercise.id]!.length + 1),
      exerciseType: exercise.exerciseType,
      exerciseId: exercise.id,
      workoutId: exercise.workoutId,
      weekId: exercise.weekId,
      programId: exercise.programId,
      userId: userId,
      intensity: intensity,
      checked: checked,
    );
    
    _sets[exercise.id]!.add(set);
    return this;
  }

  /// Build complete dataset
  Map<String, dynamic> build() {
    return {
      'programs': _programs,
      'weeks': _weeks,
      'workouts': _workouts,
      'exercises': _exercises,
      'sets': _sets,
      'userId': userId,
    };
  }

  Week _getLastWeek() {
    if (_programs.isEmpty) throw StateError('No program available');
    final lastProgram = _programs.last;
    final weeks = _weeks[lastProgram.id]!;
    if (weeks.isEmpty) throw StateError('No week available');
    return weeks.last;
  }

  Workout _getLastWorkout() {
    final week = _getLastWeek();
    final workouts = _workouts[week.id]!;
    if (workouts.isEmpty) throw StateError('No workout available');
    return workouts.last;
  }

  Exercise _getLastExercise() {
    final workout = _getLastWorkout();
    final exercises = _exercises[workout.id]!;
    if (exercises.isEmpty) throw StateError('No exercise available');
    return exercises.last;
  }
}

/// Edge case data generation
class EdgeCaseGenerator {
  /// Generate data with boundary values
  static Program createBoundaryProgram() {
    return TestDataFactory.createProgram(
      name: 'A' * 200, // Maximum name length
      description: 'A' * 1000, // Very long description
    );
  }

  /// Generate data with minimal values
  static Program createMinimalProgram() {
    return TestDataFactory.createProgram(
      name: 'A', // Minimum name length
      description: null, // No description
    );
  }

  /// Generate data with special characters
  static Program createUnicodeProgram() {
    return TestDataFactory.createProgram(
      name: 'Программа тренировок 🏋️‍♂️💪',
      description: 'Descripción con acentos y émojis 🎯🔥',
    );
  }

  /// Generate sets with extreme values
  static List<ExerciseSet> createExtremeSets() {
    return [
      // Maximum values
      TestDataFactory.createExerciseSet(
        setNumber: 999,
        exerciseType: ExerciseType.strength,
        intensity: SetIntensity.maximum,
      ),
      // Minimum values
      TestDataFactory.createExerciseSet(
        setNumber: 1,
        exerciseType: ExerciseType.bodyweight,
        intensity: SetIntensity.light,
      ),
      // Zero/null values where allowed
      ExerciseSet(
        id: 'zero-set',
        setNumber: 1,
        reps: 0, // Edge case: zero reps
        weight: 0.0, // Edge case: zero weight
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'test-user',
        exerciseId: 'test-exercise',
        workoutId: 'test-workout',
        weekId: 'test-week',
        programId: 'test-program',
      ),
    ];
  }
}

/// Performance testing datasets
class PerformanceDatasets {
  /// Create small dataset for baseline performance
  static Map<String, dynamic> createSmallDataset() {
    return DatasetBuilder()
        .addProgram(name: 'Small Program')
        .addWeek()
        .addWorkout()
        .addExercise(exerciseType: ExerciseType.strength)
        .addSet()
        .addSet()
        .build();
  }

  /// Create medium dataset for typical performance
  static Map<String, dynamic> createMediumDataset() {
    final builder = DatasetBuilder()
        .addProgram(name: 'Medium Program');
    
    for (int w = 0; w < 4; w++) {
      builder.addWeek();
      for (int wo = 0; wo < 3; wo++) {
        builder.addWorkout();
        for (int e = 0; e < 5; e++) {
          builder.addExercise(exerciseType: ExerciseType.values[e % ExerciseType.values.length]);
          for (int s = 0; s < 3; s++) {
            builder.addSet();
          }
        }
      }
    }
    
    return builder.build();
  }

  /// Create large dataset for stress testing
  static Map<String, dynamic> createLargeDataset() {
    final builder = DatasetBuilder()
        .addProgram(name: 'Large Program');
    
    for (int w = 0; w < 12; w++) {
      builder.addWeek();
      for (int wo = 0; wo < 5; wo++) {
        builder.addWorkout();
        for (int e = 0; e < 8; e++) {
          builder.addExercise(exerciseType: ExerciseType.values[e % ExerciseType.values.length]);
          for (int s = 0; s < 4; s++) {
            builder.addSet();
          }
        }
      }
    }
    
    return builder.build();
  }

  /// Create extreme dataset for load testing
  static Map<String, dynamic> createExtremeDataset() {
    final builder = DatasetBuilder()
        .addProgram(name: 'Extreme Program');
    
    for (int w = 0; w < 52; w++) { // Full year
      builder.addWeek();
      for (int wo = 0; wo < 6; wo++) { // 6 workouts per week
        builder.addWorkout();
        for (int e = 0; e < 10; e++) { // 10 exercises per workout
          builder.addExercise(exerciseType: ExerciseType.values[e % ExerciseType.values.length]);
          for (int s = 0; s < 5; s++) { // 5 sets per exercise
            builder.addSet();
          }
        }
      }
    }
    
    return builder.build();
  }
}

/// Enums for test data templates and configurations

enum ProgramTemplate {
  general,
  strength,
  cardio,
  bodyweight,
  hybrid,
}

enum WeekTemplate {
  standard,
  deload,
  peak,
}

enum WorkoutTemplate {
  strength,
  cardio,
  recovery,
}

enum SetIntensity {
  light,
  moderate,
  heavy,
  maximum,
}

enum AnalyticsComplexity {
  simple,
  moderate,
  complex,
  extreme,
}