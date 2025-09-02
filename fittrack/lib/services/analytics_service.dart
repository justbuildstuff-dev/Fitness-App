import 'dart:async';
import '../models/analytics.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/workout.dart';
import 'firestore_service.dart';

/// Service for computing workout analytics and personal records
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;
  AnalyticsService._();

  final FirestoreService _firestoreService = FirestoreService.instance;

  // Simple cache to avoid recomputation for short periods
  final Map<String, _CachedAnalytics> _cache = {};
  final Duration _cacheValidDuration = Duration(minutes: 5);

  /// Compute workout analytics for a date range
  Future<WorkoutAnalytics> computeWorkoutAnalytics({
    required String userId,
    required DateRange dateRange,
  }) async {
    final cacheKey = '${userId}_${dateRange.start.toIso8601String()}_${dateRange.end.toIso8601String()}';
    
    // Check cache first
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as WorkoutAnalytics;
    }

    // Get all user data for the date range
    final workouts = await _getAllUserWorkouts(userId, dateRange);
    final exercises = await _getAllUserExercises(userId, dateRange);
    final sets = await _getAllUserSets(userId, dateRange);

    // Compute analytics from data
    final analytics = WorkoutAnalytics.fromWorkoutData(
      userId: userId,
      startDate: dateRange.start,
      endDate: dateRange.end,
      workouts: workouts,
      exercises: exercises,
      sets: sets,
    );

    // Cache the result
    _cache[cacheKey] = _CachedAnalytics(
      data: analytics,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return analytics;
  }

  /// Generate heatmap data for a specific year
  Future<ActivityHeatmapData> generateHeatmapData({
    required String userId,
    required int year,
  }) async {
    final cacheKey = '${userId}_heatmap_$year';
    
    // Check cache first
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as ActivityHeatmapData;
    }

    // Get all workouts for the year
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31, 23, 59, 59);
    final workouts = await _getAllUserWorkouts(
      userId, 
      DateRange(start: yearStart, end: yearEnd),
    );

    // Compute heatmap data
    final heatmapData = ActivityHeatmapData.fromWorkouts(
      userId: userId,
      year: year,
      workouts: workouts,
    );

    // Cache the result
    _cache[cacheKey] = _CachedAnalytics(
      data: heatmapData,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return heatmapData;
  }

  /// Get personal records for a user
  Future<List<PersonalRecord>> getPersonalRecords({
    required String userId,
    int? limit,
    ExerciseType? exerciseType,
  }) async {
    // Get all user data
    final currentYear = DateTime.now().year;
    final dateRange = DateRange(
      start: DateTime(currentYear - 1, 1, 1),
      end: DateTime.now(),
    );
    
    final exercises = await _getAllUserExercises(userId, dateRange);
    final sets = await _getAllUserSets(userId, dateRange);

    // Detect personal records from sets
    final prs = await _detectPersonalRecords(exercises, sets);

    // Filter by exercise type if specified
    var filteredPRs = exerciseType != null
        ? prs.where((pr) => pr.exerciseType == exerciseType).toList()
        : prs;

    // Sort by achievement date (most recent first)
    filteredPRs.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    // Apply limit if specified
    if (limit != null && limit > 0) {
      filteredPRs = filteredPRs.take(limit).toList();
    }

    return filteredPRs;
  }

  /// Check for new personal record in a specific set
  Future<PersonalRecord?> checkForNewPR({
    required ExerciseSet set,
    required Exercise exercise,
  }) async {
    // Get historical data for this exercise
    final dateRange = DateRange(
      start: DateTime.now().subtract(Duration(days: 365)),
      end: DateTime.now(),
    );
    
    final allSets = await _getAllUserSets(exercise.userId, dateRange);
    
    // Filter sets for this specific exercise
    final exerciseSets = allSets
        .where((s) => s.exerciseId == exercise.id)
        .where((s) => s.id != set.id) // Exclude the current set
        .toList();

    // Check different PR types based on exercise type
    return _checkForPRInSet(set, exercise, exerciseSets);
  }

  /// Compute key statistics for dashboard
  Future<Map<String, dynamic>> computeKeyStatistics({
    required String userId,
    required DateRange dateRange,
  }) async {
    final analytics = await computeWorkoutAnalytics(
      userId: userId,
      dateRange: dateRange,
    );

    final prs = await getPersonalRecords(userId: userId, limit: 50);
    final recentPRs = prs.where((pr) => dateRange.contains(pr.achievedAt)).length;

    // Calculate completion percentage (assuming sets with checked=true)
    final allSets = await _getAllUserSets(userId, dateRange);
    final completedSets = allSets.where((s) => s.checked).length;
    final completionPercentage = allSets.isEmpty 
        ? 0.0 
        : (completedSets / allSets.length) * 100;

    // Calculate workouts per week
    final daysInRange = dateRange.durationInDays;
    final weeksInRange = daysInRange / 7;
    final workoutsPerWeek = weeksInRange > 0 
        ? analytics.totalWorkouts / weeksInRange 
        : 0.0;

    return {
      'totalWorkouts': analytics.totalWorkouts,
      'totalSets': analytics.totalSets,
      'totalVolume': analytics.totalVolume,
      'averageDuration': analytics.averageWorkoutDuration,
      'newPRs': recentPRs,
      'mostUsedExerciseType': analytics.mostUsedExerciseType?.displayName ?? 'None',
      'completionPercentage': completionPercentage,
      'workoutsPerWeek': workoutsPerWeek,
    };
  }

  /// Clear the analytics cache
  void clearCache() {
    _cache.clear();
  }

  // Private helper methods

  Future<List<Workout>> _getAllUserWorkouts(String userId, DateRange dateRange) async {
    final List<Workout> allWorkouts = [];
    
    try {
      // Get all programs for user
      final programs = await _firestoreService.getPrograms(userId).first;
      
      for (final program in programs) {
        // Get weeks for each program
        final weeks = await _firestoreService.getWeeks(userId, program.id).first;
        
        for (final week in weeks) {
          // Get workouts for each week
          final workouts = await _firestoreService.getWorkouts(userId, program.id, week.id).first;
          
          // Filter workouts by date range
          final filteredWorkouts = workouts.where((w) => dateRange.contains(w.createdAt));
          allWorkouts.addAll(filteredWorkouts);
        }
      }
    } catch (e) {
      // Return empty list on error
      return [];
    }
    
    return allWorkouts;
  }

  Future<List<Exercise>> _getAllUserExercises(String userId, DateRange dateRange) async {
    final List<Exercise> allExercises = [];
    
    try {
      final programs = await _firestoreService.getPrograms(userId).first;
      
      for (final program in programs) {
        final weeks = await _firestoreService.getWeeks(userId, program.id).first;
        
        for (final week in weeks) {
          final workouts = await _firestoreService.getWorkouts(userId, program.id, week.id).first;
          
          for (final workout in workouts) {
            if (dateRange.contains(workout.createdAt)) {
              final exercises = await _firestoreService.getExercises(
                userId, program.id, week.id, workout.id).first;
              allExercises.addAll(exercises);
            }
          }
        }
      }
    } catch (e) {
      return [];
    }
    
    return allExercises;
  }

  Future<List<ExerciseSet>> _getAllUserSets(String userId, DateRange dateRange) async {
    final List<ExerciseSet> allSets = [];
    
    try {
      final programs = await _firestoreService.getPrograms(userId).first;
      
      for (final program in programs) {
        final weeks = await _firestoreService.getWeeks(userId, program.id).first;
        
        for (final week in weeks) {
          final workouts = await _firestoreService.getWorkouts(userId, program.id, week.id).first;
          
          for (final workout in workouts) {
            if (dateRange.contains(workout.createdAt)) {
              final exercises = await _firestoreService.getExercises(
                userId, program.id, week.id, workout.id).first;
              
              for (final exercise in exercises) {
                final sets = await _firestoreService.getSets(
                  userId, program.id, week.id, workout.id, exercise.id).first;
                
                // Filter sets by date range
                final filteredSets = sets.where((s) => dateRange.contains(s.createdAt));
                allSets.addAll(filteredSets);
              }
            }
          }
        }
      }
    } catch (e) {
      return [];
    }
    
    return allSets;
  }

  Future<List<PersonalRecord>> _detectPersonalRecords(
      List<Exercise> exercises, List<ExerciseSet> sets) async {
    final List<PersonalRecord> prs = [];
    
    // Group sets by exercise
    final Map<String, List<ExerciseSet>> setsByExercise = {};
    for (final set in sets) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    // Detect PRs for each exercise
    for (final exercise in exercises) {
      final exerciseSets = setsByExercise[exercise.id] ?? [];
      if (exerciseSets.isEmpty) continue;

      // Sort sets by date to track progression
      exerciseSets.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Detect different types of PRs
      final exercisePRs = _findPRsForExercise(exercise, exerciseSets);
      prs.addAll(exercisePRs);
    }

    return prs;
  }

  List<PersonalRecord> _findPRsForExercise(Exercise exercise, List<ExerciseSet> sets) {
    final List<PersonalRecord> prs = [];
    
    // Track maximums for different PR types
    double? maxWeight;
    int? maxReps;
    int? maxDuration;
    double? maxDistance;
    double? maxVolume;

    for (int i = 0; i < sets.length; i++) {
      final set = sets[i];
      
      // Check max weight PR
      if (set.weight != null) {
        if (maxWeight == null || set.weight! > maxWeight) {
          prs.add(PersonalRecord(
            id: '${set.id}_weight',
            userId: set.userId,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.exerciseType,
            prType: PRType.maxWeight,
            value: set.weight!,
            previousValue: maxWeight,
            achievedAt: set.createdAt,
            workoutId: set.workoutId,
            setId: set.id,
          ));
          maxWeight = set.weight!;
        }
      }

      // Check max reps PR
      if (set.reps != null) {
        if (maxReps == null || set.reps! > maxReps) {
          prs.add(PersonalRecord(
            id: '${set.id}_reps',
            userId: set.userId,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.exerciseType,
            prType: PRType.maxReps,
            value: set.reps!.toDouble(),
            previousValue: maxReps?.toDouble(),
            achievedAt: set.createdAt,
            workoutId: set.workoutId,
            setId: set.id,
          ));
          maxReps = set.reps!;
        }
      }

      // Check max volume PR (weight * reps)
      if (set.weight != null && set.reps != null) {
        final volume = set.weight! * set.reps!;
        if (maxVolume == null || volume > maxVolume) {
          prs.add(PersonalRecord(
            id: '${set.id}_volume',
            userId: set.userId,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.exerciseType,
            prType: PRType.maxVolume,
            value: volume,
            previousValue: maxVolume,
            achievedAt: set.createdAt,
            workoutId: set.workoutId,
            setId: set.id,
          ));
          maxVolume = volume;
        }
      }

      // Check max duration PR
      if (set.duration != null) {
        if (maxDuration == null || set.duration! > maxDuration) {
          prs.add(PersonalRecord(
            id: '${set.id}_duration',
            userId: set.userId,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.exerciseType,
            prType: PRType.maxDuration,
            value: set.duration!.toDouble(),
            previousValue: maxDuration?.toDouble(),
            achievedAt: set.createdAt,
            workoutId: set.workoutId,
            setId: set.id,
          ));
          maxDuration = set.duration!;
        }
      }

      // Check max distance PR
      if (set.distance != null) {
        if (maxDistance == null || set.distance! > maxDistance) {
          prs.add(PersonalRecord(
            id: '${set.id}_distance',
            userId: set.userId,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseType: exercise.exerciseType,
            prType: PRType.maxDistance,
            value: set.distance!,
            previousValue: maxDistance,
            achievedAt: set.createdAt,
            workoutId: set.workoutId,
            setId: set.id,
          ));
          maxDistance = set.distance!;
        }
      }
    }

    return prs;
  }

  PersonalRecord? _checkForPRInSet(
      ExerciseSet newSet, Exercise exercise, List<ExerciseSet> historicalSets) {
    // Find the best previous performance for relevant metrics
    
    switch (exercise.exerciseType) {
      case ExerciseType.strength:
        // Check weight PR for strength exercises
        if (newSet.weight != null) {
          final maxPreviousWeight = historicalSets
              .where((s) => s.weight != null)
              .map((s) => s.weight!)
              .fold<double?>(null, (prev, curr) => 
                  prev == null ? curr : (curr > prev ? curr : prev));
          
          if (maxPreviousWeight == null || newSet.weight! > maxPreviousWeight) {
            return PersonalRecord(
              id: '${newSet.id}_weight',
              userId: newSet.userId,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              exerciseType: exercise.exerciseType,
              prType: PRType.maxWeight,
              value: newSet.weight!,
              previousValue: maxPreviousWeight,
              achievedAt: newSet.createdAt,
              workoutId: newSet.workoutId,
              setId: newSet.id,
            );
          }
        }
        break;
        
      case ExerciseType.bodyweight:
        // Check reps PR for bodyweight exercises
        if (newSet.reps != null) {
          final maxPreviousReps = historicalSets
              .where((s) => s.reps != null)
              .map((s) => s.reps!)
              .fold<int?>(null, (prev, curr) => 
                  prev == null ? curr : (curr > prev ? curr : prev));
          
          if (maxPreviousReps == null || newSet.reps! > maxPreviousReps) {
            return PersonalRecord(
              id: '${newSet.id}_reps',
              userId: newSet.userId,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              exerciseType: exercise.exerciseType,
              prType: PRType.maxReps,
              value: newSet.reps!.toDouble(),
              previousValue: maxPreviousReps?.toDouble(),
              achievedAt: newSet.createdAt,
              workoutId: newSet.workoutId,
              setId: newSet.id,
            );
          }
        }
        break;
        
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        // Check duration PR for cardio/time-based exercises
        if (newSet.duration != null) {
          final maxPreviousDuration = historicalSets
              .where((s) => s.duration != null)
              .map((s) => s.duration!)
              .fold<int?>(null, (prev, curr) => 
                  prev == null ? curr : (curr > prev ? curr : prev));
          
          if (maxPreviousDuration == null || newSet.duration! > maxPreviousDuration) {
            return PersonalRecord(
              id: '${newSet.id}_duration',
              userId: newSet.userId,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              exerciseType: exercise.exerciseType,
              prType: PRType.maxDuration,
              value: newSet.duration!.toDouble(),
              previousValue: maxPreviousDuration?.toDouble(),
              achievedAt: newSet.createdAt,
              workoutId: newSet.workoutId,
              setId: newSet.id,
            );
          }
        }
        break;
        
      case ExerciseType.custom:
        // For custom exercises, check the most relevant metric
        // Priority: weight > reps > duration > distance
        if (newSet.weight != null && newSet.reps != null) {
          // Check volume PR
          final volume = newSet.weight! * newSet.reps!;
          final maxPreviousVolume = historicalSets
              .where((s) => s.weight != null && s.reps != null)
              .map((s) => s.weight! * s.reps!)
              .fold<double?>(null, (prev, curr) => 
                  prev == null ? curr : (curr > prev ? curr : prev));
          
          if (maxPreviousVolume == null || volume > maxPreviousVolume) {
            return PersonalRecord(
              id: '${newSet.id}_volume',
              userId: newSet.userId,
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              exerciseType: exercise.exerciseType,
              prType: PRType.maxVolume,
              value: volume,
              previousValue: maxPreviousVolume,
              achievedAt: newSet.createdAt,
              workoutId: newSet.workoutId,
              setId: newSet.id,
            );
          }
        }
        break;
    }

    return null;
  }
}

/// Internal cache structure
class _CachedAnalytics {
  final dynamic data;
  final DateTime computedAt;
  final Duration validFor;

  _CachedAnalytics({
    required this.data,
    required this.computedAt,
    required this.validFor,
  });

  bool get isValid => DateTime.now().difference(computedAt) < validFor;
}