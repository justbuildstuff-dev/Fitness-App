import 'dart:async';
import '../models/analytics.dart';
import '../models/custom_exercise.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/library_exercise.dart';
import '../models/muscle_group.dart';
import '../models/workout.dart';
import '../utils/one_rm_calculator.dart';
import 'firestore_service.dart';

/// Service for computing workout analytics and personal records
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;
  
  final FirestoreService _firestoreService;
  
  AnalyticsService._() : _firestoreService = FirestoreService.instance;
  
  // Constructor for testing with dependency injection
  AnalyticsService.withFirestoreService(this._firestoreService);

  // Simple cache to avoid recomputation for short periods
  final Map<String, _CachedAnalytics> _cache = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Compute workout analytics for a date range
  Future<WorkoutAnalytics> computeWorkoutAnalytics({
    required String userId,
    required DateRange dateRange,
    String? programId,
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

  /// Generate heatmap data based on completed sets (checked: true)
  ///
  /// This method provides set-based activity tracking for the heatmap calendar.
  /// Only sets marked as completed (`checked: true`) are counted.
  ///
  /// **Parameters:**
  /// - [userId]: The user ID to retrieve analytics for
  /// - [dateRange]: The time period to analyze (e.g., this week, this month, etc.)
  /// - [programId]: Optional program filter. If null, includes sets from all programs
  ///
  /// **Returns:**
  /// [ActivityHeatmapData] containing:
  /// - Daily set counts grouped by date
  /// - Current streak (consecutive days with at least 1 set)
  /// - Longest streak within the date range
  /// - Total completed sets
  ///
  /// **Caching:**
  /// Results are cached for 5 minutes to improve performance. The cache key
  /// includes userId, dateRange, and programId to ensure correct data isolation.
  ///
  /// **Example:**
  /// ```dart
  /// final heatmapData = await analyticsService.generateSetBasedHeatmapData(
  ///   userId: 'user123',
  ///   dateRange: DateRange.thisWeek(),
  ///   programId: 'program456', // or null for all programs
  /// );
  /// ```
  Future<ActivityHeatmapData> generateSetBasedHeatmapData({
    required String userId,
    required DateRange dateRange,
    String? programId,
  }) async {
    final cacheKey = '${userId}_heatmap_sets_${dateRange.start.toIso8601String()}_${dateRange.end.toIso8601String()}_${programId ?? 'all'}';

    // Check cache first
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as ActivityHeatmapData;
    }

    // Get all sets for the date range (with optional program filter)
    final allSets = await _getAllUserSets(userId, dateRange, programId: programId);

    // Filter only checked sets (completed sets)
    final checkedSets = allSets.where((set) => set.checked).toList();

    // Group sets by completion date (normalize to midnight for consistent day-level grouping)
    final Map<DateTime, int> dailySetCounts = {};
    for (final set in checkedSets) {
      final completionDate = _completionDate(set);
      final date = DateTime(
        completionDate.year,
        completionDate.month,
        completionDate.day,
      );
      dailySetCounts[date] = (dailySetCounts[date] ?? 0) + 1;
    }

    // Calculate streaks based on consecutive days with at least 1 set
    final streaks = _calculateStreaks(dailySetCounts, dateRange);

    final heatmapData = ActivityHeatmapData(
      userId: userId,
      year: dateRange.start.year,
      dailySetCounts: dailySetCounts,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
      totalSets: checkedSets.length,
      programId: programId,
    );

    // Cache the result for 5 minutes
    _cache[cacheKey] = _CachedAnalytics(
      data: heatmapData,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return heatmapData;
  }

  /// Generate heatmap data for a specific month (all programs aggregated)
  ///
  /// This method provides monthly calendar view data for the monthly swipe feature.
  /// It queries all programs and aggregates set counts by day for the specified month.
  ///
  /// **Parameters:**
  /// - [userId]: The user ID to retrieve analytics for
  /// - [year]: Year (e.g., 2024)
  /// - [month]: Month (1-12)
  ///
  /// **Returns:**
  /// [MonthHeatmapData] containing:
  /// - Daily set counts mapped by day of month (1-31)
  /// - Total completed sets for the month
  /// - Timestamp when data was fetched (for cache validation)
  ///
  /// **Caching:**
  /// Results are cached for 5 minutes to improve performance. The cache key
  /// includes userId, year, and month to ensure correct data isolation.
  ///
  /// **Example:**
  /// ```dart
  /// final monthData = await analyticsService.getMonthHeatmapData(
  ///   userId: 'user123',
  ///   year: 2024,
  ///   month: 12, // December
  /// );
  ///
  /// // Get set count for a specific day
  /// final day15Count = monthData.getSetCountForDay(15);
  /// ```
  Future<MonthHeatmapData> getMonthHeatmapData({
    required String userId,
    required int year,
    required int month,
  }) async {
    final cacheKey = '${userId}_month_${year}_$month';

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!.data as MonthHeatmapData;
      if (cached.isCacheValid) {
        return cached;
      }
    }

    // Calculate month date range
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    final dateRange = DateRange(start: monthStart, end: monthEnd);

    // Get all sets for the month (all programs aggregated)
    final allSets = await _getAllUserSets(userId, dateRange);

    // Filter only checked sets (completed sets)
    final checkedSets = allSets.where((set) => set.checked).toList();

    // Group sets by day of month using completion date
    final Map<int, int> dailySetCounts = {};
    for (final set in checkedSets) {
      final day = _completionDate(set).day;
      dailySetCounts[day] = (dailySetCounts[day] ?? 0) + 1;
    }

    final monthData = MonthHeatmapData(
      year: year,
      month: month,
      dailySetCounts: dailySetCounts,
      totalSets: checkedSets.length,
      fetchedAt: DateTime.now(),
    );

    // Cache the result for 5 minutes
    _cache[cacheKey] = _CachedAnalytics(
      data: monthData,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return monthData;
  }

  /// Pre-fetch data for adjacent months to enable smooth swiping
  ///
  /// This method fetches data for the previous and next month in parallel
  /// to improve perceived performance when users swipe between months.
  ///
  /// **Parameters:**
  /// - [userId]: The user ID to retrieve analytics for
  /// - [year]: Current month's year
  /// - [month]: Current month (1-12)
  ///
  /// **Returns:**
  /// A Future that completes when both adjacent months are fetched and cached.
  ///
  /// **Example:**
  /// ```dart
  /// // User is viewing December 2024
  /// await analyticsService.prefetchAdjacentMonths(
  ///   userId: 'user123',
  ///   year: 2024,
  ///   month: 12,
  /// );
  /// // Now Nov 2024 and Jan 2025 are cached
  /// ```
  Future<void> prefetchAdjacentMonths({
    required String userId,
    required int year,
    required int month,
  }) async {
    // Calculate previous month
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    // Calculate next month
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;

    // Fetch both in parallel for better performance
    await Future.wait([
      getMonthHeatmapData(userId: userId, year: prevYear, month: prevMonth),
      getMonthHeatmapData(userId: userId, year: nextYear, month: nextMonth),
    ]);
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
      start: DateTime.now().subtract(const Duration(days: 365)),
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

  /// Get per-exercise progress data for charting
  ///
  /// Retrieves all sets for a specific exercise within the date range,
  /// groups them by workout session, and computes per-session aggregates.
  ///
  /// **Parameters:**
  /// - [userId]: The user ID
  /// - [exerciseId]: The exercise to retrieve progress for
  /// - [exerciseName]: Display name for the result
  /// - [exerciseType]: Type of exercise (determines which metrics to compute)
  /// - [dateRange]: Time period to analyze
  ///
  /// **Returns:**
  /// [ExerciseProgressData] with chronologically ordered data points.
  /// For strength exercises, includes estimated 1RM per session.
  Future<ExerciseProgressData> getExerciseProgress({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required ExerciseType exerciseType,
    required DateRange dateRange,
  }) async {
    final cacheKey = '${userId}_exercise_progress_${exerciseId}_${dateRange.start.toIso8601String()}_${dateRange.end.toIso8601String()}';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as ExerciseProgressData;
    }

    final allSets = await _getAllUserSets(userId, dateRange);

    // Filter sets for this specific exercise
    final exerciseSets = allSets.where((s) => s.exerciseId == exerciseId).toList();

    // Group sets by workoutId (one data point per workout session)
    final Map<String, List<ExerciseSet>> setsByWorkout = {};
    for (final set in exerciseSets) {
      setsByWorkout.putIfAbsent(set.workoutId, () => []).add(set);
    }

    // Build data points from grouped sets
    final List<ExerciseProgressPoint> dataPoints = [];
    for (final entry in setsByWorkout.entries) {
      final workoutSets = entry.value;
      final workoutId = entry.key;

      // Use earliest set's completion date as the session date
      workoutSets.sort((a, b) => _completionDate(a).compareTo(_completionDate(b)));
      final sessionDate = _completionDate(workoutSets.first);

      // Compute per-session aggregates
      double? maxWeight;
      int? maxReps;
      double totalVolume = 0;
      int totalDuration = 0;
      double totalDistance = 0;

      for (final set in workoutSets) {
        if (set.weight != null && (maxWeight == null || set.weight! > maxWeight)) {
          maxWeight = set.weight;
        }
        if (set.reps != null && (maxReps == null || set.reps! > maxReps)) {
          maxReps = set.reps;
        }
        if (set.weight != null && set.reps != null) {
          totalVolume += set.weight! * set.reps!;
        }
        if (set.duration != null) {
          totalDuration += set.duration!;
        }
        if (set.distance != null) {
          totalDistance += set.distance!;
        }
      }

      // Compute estimated 1RM for strength exercises
      double? estimated1RM;
      if (exerciseType == ExerciseType.strength) {
        estimated1RM = OneRMCalculator.estimateFromSets(workoutSets);
      }

      dataPoints.add(ExerciseProgressPoint(
        date: sessionDate,
        workoutId: workoutId,
        maxWeight: maxWeight,
        maxReps: maxReps,
        totalVolume: totalVolume > 0 ? totalVolume : null,
        totalDuration: totalDuration > 0 ? totalDuration : null,
        totalDistance: totalDistance > 0 ? totalDistance : null,
        estimated1RM: estimated1RM,
      ));
    }

    // Sort chronologically
    dataPoints.sort((a, b) => a.date.compareTo(b.date));

    final result = ExerciseProgressData(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseType: exerciseType,
      dataPoints: dataPoints,
      dateRange: dateRange,
    );

    _cache[cacheKey] = _CachedAnalytics(
      data: result,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return result;
  }

  /// Get muscle group volume distribution for a date range
  ///
  /// Matches exercises by name to library/custom exercises to determine
  /// primary muscle group. Unmatched exercises are grouped as "Other".
  ///
  /// **Parameters:**
  /// - [userId]: The user ID
  /// - [dateRange]: Time period to analyze
  /// - [libraryExercises]: Available library exercises for name matching
  /// - [customExercises]: User's custom exercises for name matching
  ///
  /// **Returns:**
  /// List of [MuscleGroupVolume] sorted by totalSets descending, with percentages.
  Future<List<MuscleGroupVolume>> getMuscleGroupVolume({
    required String userId,
    required DateRange dateRange,
    required List<LibraryExercise> libraryExercises,
    required List<CustomExercise> customExercises,
  }) async {
    final cacheKey = '${userId}_muscle_volume_${dateRange.start.toIso8601String()}_${dateRange.end.toIso8601String()}';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as List<MuscleGroupVolume>;
    }

    final exercises = await _getAllUserExercises(userId, dateRange);
    final allSets = await _getAllUserSets(userId, dateRange);

    // Build a name→MuscleGroup lookup from library and custom exercises
    final Map<String, MuscleGroup> nameToMuscleGroup = {};
    for (final libEx in libraryExercises) {
      if (libEx.primaryMuscles.isNotEmpty) {
        nameToMuscleGroup[libEx.name.toLowerCase()] = libEx.primaryMuscles.first;
      }
    }
    for (final customEx in customExercises) {
      if (customEx.primaryMuscles.isNotEmpty) {
        nameToMuscleGroup[customEx.name.toLowerCase()] = customEx.primaryMuscles.first;
      }
    }

    // Build exerciseId→MuscleGroup mapping
    final Map<String, MuscleGroup?> exerciseToMuscleGroup = {};
    for (final exercise in exercises) {
      exerciseToMuscleGroup[exercise.id] =
          nameToMuscleGroup[exercise.name.toLowerCase()];
    }

    // Count sets per muscle group
    final Map<MuscleGroup?, int> setCounts = {};
    for (final set in allSets) {
      final muscleGroup = exerciseToMuscleGroup[set.exerciseId];
      setCounts[muscleGroup] = (setCounts[muscleGroup] ?? 0) + 1;
    }

    final totalSets = setCounts.values.fold<int>(0, (sum, count) => sum + count);
    if (totalSets == 0) {
      _cache[cacheKey] = _CachedAnalytics(
        data: <MuscleGroupVolume>[],
        computedAt: DateTime.now(),
        validFor: _cacheValidDuration,
      );
      return [];
    }

    // Build result list
    final List<MuscleGroupVolume> result = [];
    for (final entry in setCounts.entries) {
      result.add(MuscleGroupVolume(
        muscleGroup: entry.key,
        label: entry.key?.displayName ?? 'Other',
        totalSets: entry.value,
        percentage: (entry.value / totalSets) * 100,
      ));
    }

    // Sort by totalSets descending
    result.sort((a, b) => b.totalSets.compareTo(a.totalSets));

    _cache[cacheKey] = _CachedAnalytics(
      data: result,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return result;
  }

  /// Get weekly training trends for a date range
  ///
  /// Groups workouts and sets by ISO 8601 week (Monday-Sunday),
  /// computing total volume and workout count per week.
  ///
  /// **Parameters:**
  /// - [userId]: The user ID
  /// - [dateRange]: Time period to analyze
  ///
  /// **Returns:**
  /// List of [WeeklyTrendPoint] sorted chronologically by weekStart.
  Future<List<WeeklyTrendPoint>> getWeeklyTrends({
    required String userId,
    required DateRange dateRange,
  }) async {
    final cacheKey = '${userId}_weekly_trends_${dateRange.start.toIso8601String()}_${dateRange.end.toIso8601String()}';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as List<WeeklyTrendPoint>;
    }

    final workouts = await _getAllUserWorkouts(userId, dateRange);
    final allSets = await _getAllUserSets(userId, dateRange);

    // Helper: get the Monday of a given date's week
    DateTime getWeekStart(DateTime date) {
      final daysFromMonday = date.weekday - 1; // Monday = 1, so subtract 1
      return DateTime(date.year, date.month, date.day - daysFromMonday);
    }

    // Group workouts by week (count unique workouts per week)
    final Map<DateTime, Set<String>> workoutsByWeek = {};
    for (final workout in workouts) {
      final weekStart = getWeekStart(workout.createdAt);
      workoutsByWeek.putIfAbsent(weekStart, () => {}).add(workout.id);
    }

    // Group sets by week using completion date and compute volume
    final Map<DateTime, double> volumeByWeek = {};
    for (final set in allSets) {
      final weekStart = getWeekStart(_completionDate(set));
      double setVolume = 0;
      if (set.weight != null && set.reps != null) {
        setVolume = set.weight! * set.reps!;
      }
      volumeByWeek[weekStart] = (volumeByWeek[weekStart] ?? 0) + setVolume;
    }

    // Merge into WeeklyTrendPoints
    final allWeeks = <DateTime>{...workoutsByWeek.keys, ...volumeByWeek.keys};
    final List<WeeklyTrendPoint> result = allWeeks.map((weekStart) {
      return WeeklyTrendPoint(
        weekStart: weekStart,
        totalVolume: volumeByWeek[weekStart] ?? 0,
        workoutCount: workoutsByWeek[weekStart]?.length ?? 0,
      );
    }).toList();

    // Sort chronologically
    result.sort((a, b) => a.weekStart.compareTo(b.weekStart));

    _cache[cacheKey] = _CachedAnalytics(
      data: result,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return result;
  }

  /// Get configurable workout streak based on weekly target
  ///
  /// Counts consecutive weeks (from current week backwards) where the
  /// workout count meets or exceeds the weekly target.
  ///
  /// **Parameters:**
  /// - [userId]: The user ID
  /// - [weeklyTarget]: Minimum workouts per week to count (1-7)
  ///
  /// **Returns:**
  /// [ConfigurableStreak] with current streak, longest streak, and target.
  Future<ConfigurableStreak> getConfigurableStreak({
    required String userId,
    required int weeklyTarget,
  }) async {
    final cacheKey = '${userId}_streak_$weeklyTarget';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as ConfigurableStreak;
    }

    // Get workouts for past 2 years
    final now = DateTime.now();
    final dateRange = DateRange(
      start: DateTime(now.year - 2, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    final workouts = await _getAllUserWorkouts(userId, dateRange);

    // Helper: get the Monday of a given date's week
    DateTime getWeekStart(DateTime date) {
      final daysFromMonday = date.weekday - 1;
      return DateTime(date.year, date.month, date.day - daysFromMonday);
    }

    // Group workouts by week
    final Map<DateTime, int> workoutsPerWeek = {};
    for (final workout in workouts) {
      final weekStart = getWeekStart(workout.createdAt);
      workoutsPerWeek[weekStart] = (workoutsPerWeek[weekStart] ?? 0) + 1;
    }

    if (workoutsPerWeek.isEmpty) {
      final result = ConfigurableStreak(
        weeklyTarget: weeklyTarget,
        currentStreak: 0,
        longestStreak: 0,
      );
      _cache[cacheKey] = _CachedAnalytics(
        data: result,
        computedAt: DateTime.now(),
        validFor: _cacheValidDuration,
      );
      return result;
    }

    // Sort weeks chronologically
    final sortedWeeks = workoutsPerWeek.keys.toList()..sort();

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? previousWeek;

    for (final weekStart in sortedWeeks) {
      final count = workoutsPerWeek[weekStart]!;
      if (count >= weeklyTarget) {
        if (previousWeek == null ||
            weekStart.difference(previousWeek).inDays == 7) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        previousWeek = weekStart;
      } else {
        tempStreak = 0;
        previousWeek = null;
      }
    }

    // Calculate current streak (working backwards from current week)
    int currentStreak = 0;
    DateTime checkWeek = getWeekStart(now);

    while (true) {
      final count = workoutsPerWeek[checkWeek] ?? 0;
      if (count >= weeklyTarget) {
        currentStreak++;
        checkWeek = checkWeek.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    final result = ConfigurableStreak(
      weeklyTarget: weeklyTarget,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );

    _cache[cacheKey] = _CachedAnalytics(
      data: result,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return result;
  }

  /// Get list of exercises the user has logged across all programs
  ///
  /// Scans all exercises across all programs and deduplicates by name.
  /// No date filter applied - returns all exercises ever logged.
  ///
  /// **Returns:**
  /// List of ({String exerciseId, String exerciseName, ExerciseType exerciseType})
  /// records sorted alphabetically by name.
  Future<List<({String exerciseId, String exerciseName, ExerciseType exerciseType})>> getLoggedExercises({
    required String userId,
  }) async {
    final cacheKey = '${userId}_logged_exercises';

    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data as List<({String exerciseId, String exerciseName, ExerciseType exerciseType})>;
    }

    // Use allTime range to get all exercises
    final dateRange = DateRange.allTime();
    final exercises = await _getAllUserExercises(userId, dateRange);

    // Deduplicate by exercise name (keep first occurrence for ID)
    final Map<String, ({String exerciseId, String exerciseName, ExerciseType exerciseType})> seen = {};
    for (final exercise in exercises) {
      final key = exercise.name.toLowerCase();
      if (!seen.containsKey(key)) {
        seen[key] = (
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          exerciseType: exercise.exerciseType,
        );
      }
    }

    final result = seen.values.toList()
      ..sort((a, b) => a.exerciseName.toLowerCase().compareTo(b.exerciseName.toLowerCase()));

    _cache[cacheKey] = _CachedAnalytics(
      data: result,
      computedAt: DateTime.now(),
      validFor: _cacheValidDuration,
    );

    return result;
  }

  /// Clear the analytics cache
  void clearCache() {
    _cache.clear();
  }

  // Private helper methods

  /// Returns the date to use for analytics grouping for a completed set.
  ///
  /// Uses [ExerciseSet.completedAt] when available (set when a set is checked),
  /// falling back to [ExerciseSet.updatedAt] for historical sets created before
  /// the completedAt field was introduced. This ensures no Firestore migration
  /// is needed while still providing accurate completion-date analytics.
  DateTime _completionDate(ExerciseSet set) => set.completedAt ?? set.updatedAt;

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

  Future<List<ExerciseSet>> _getAllUserSets(
    String userId,
    DateRange dateRange,
    {String? programId}
  ) async {
    final List<ExerciseSet> allSets = [];

    try {
      final programs = await _firestoreService.getPrograms(userId).first;

      // Filter by program if specified
      final targetPrograms = programId != null
          ? programs.where((p) => p.id == programId).toList()
          : programs;

      for (final program in targetPrograms) {
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

                allSets.addAll(sets);
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

      // Sort sets by completion date to track progression
      exerciseSets.sort((a, b) => _completionDate(a).compareTo(_completionDate(b)));

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
            achievedAt: _completionDate(set),
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
            achievedAt: _completionDate(set),
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
            achievedAt: _completionDate(set),
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
            achievedAt: _completionDate(set),
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
            achievedAt: _completionDate(set),
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
              achievedAt: _completionDate(newSet),
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
              achievedAt: _completionDate(newSet),
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
              achievedAt: _completionDate(newSet),
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
              achievedAt: _completionDate(newSet),
              workoutId: newSet.workoutId,
              setId: newSet.id,
            );
          }
        }
        break;
    }

    return null;
  }

  /// Calculate current and longest streaks from daily counts
  ({int current, int longest}) _calculateStreaks(
      Map<DateTime, int> dailyCounts, DateRange dateRange) {
    final today = DateTime.now();
    final sortedDates = dailyCounts.keys.toList()..sort();

    if (sortedDates.isEmpty) return (current: 0, longest: 0);

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Calculate longest streak
    DateTime? lastDate;
    for (final date in sortedDates) {
      if (lastDate == null ||
          date.difference(lastDate).inDays == 1) {
        tempStreak++;
      } else if (date.difference(lastDate).inDays > 1) {
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        tempStreak = 1;
      }
      lastDate = date;
    }
    longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

    // Calculate current streak (working backwards from today)
    final todayNormalized = DateTime(today.year, today.month, today.day);
    DateTime checkDate = todayNormalized;

    while (dailyCounts.containsKey(checkDate) &&
           dailyCounts[checkDate]! > 0) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return (current: currentStreak, longest: longestStreak);
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