import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';
import 'exercise_set.dart';
import 'workout.dart';

/// Analytics data for a specific date range
class WorkoutAnalytics {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume; // weight * reps sum
  final int totalDuration; // in seconds
  final Map<ExerciseType, int> exerciseTypeBreakdown;
  final List<String> completedWorkoutIds;

  const WorkoutAnalytics({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.totalWorkouts,
    required this.totalSets,
    required this.totalVolume,
    required this.totalDuration,
    required this.exerciseTypeBreakdown,
    required this.completedWorkoutIds,
  });

  /// Factory constructor to compute analytics from workout data
  factory WorkoutAnalytics.fromWorkoutData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required List<Workout> workouts,
    required List<Exercise> exercises,
    required List<ExerciseSet> sets,
  }) {
    // Filter workouts within date range
    final filteredWorkouts = workouts.where((w) =>
        w.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
        w.createdAt.isBefore(endDate.add(const Duration(days: 1)))).toList();

    // Get exercise type breakdown
    final Map<ExerciseType, int> typeBreakdown = {};
    for (final exercise in exercises) {
      typeBreakdown[exercise.exerciseType] =
          (typeBreakdown[exercise.exerciseType] ?? 0) + 1;
    }

    // Calculate volume and duration
    double volume = 0.0;
    int duration = 0;
    int totalSetsCount = 0;

    for (final set in sets) {
      totalSetsCount++;
      
      // Volume calculation (weight * reps)
      if (set.weight != null && set.reps != null) {
        volume += set.weight! * set.reps!;
      }
      
      // Duration accumulation
      if (set.duration != null) {
        duration += set.duration!;
      }
    }

    return WorkoutAnalytics(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      totalWorkouts: filteredWorkouts.length,
      totalSets: totalSetsCount,
      totalVolume: volume,
      totalDuration: duration,
      exerciseTypeBreakdown: typeBreakdown,
      completedWorkoutIds: filteredWorkouts.map((w) => w.id).toList(),
    );
  }

  /// Average workout duration in minutes
  double get averageWorkoutDuration {
    if (totalWorkouts == 0) return 0.0;
    return totalDuration / totalWorkouts / 60.0;
  }

  /// Average sets per workout
  double get averageSetsPerWorkout {
    if (totalWorkouts == 0) return 0.0;
    return totalSets / totalWorkouts;
  }

  /// Get the most used exercise type
  ExerciseType? get mostUsedExerciseType {
    if (exerciseTypeBreakdown.isEmpty) return null;
    return exerciseTypeBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Personal record tracking
class PersonalRecord {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final PRType prType;
  final double value;
  final double? previousValue;
  final DateTime achievedAt;
  final String workoutId;
  final String setId;

  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required this.prType,
    required this.value,
    this.previousValue,
    required this.achievedAt,
    required this.workoutId,
    required this.setId,
  });

  /// Improvement over previous record
  double get improvement => 
      previousValue != null ? value - previousValue! : value;

  /// Improvement as formatted string
  String get improvementString {
    if (previousValue == null) return 'New PR!';
    final diff = improvement;
    final prefix = diff > 0 ? '+' : '';
    return '$prefix${diff.toStringAsFixed(diff == diff.roundToDouble() ? 0 : 1)}';
  }

  /// Display string for the PR value
  String get displayValue {
    switch (prType) {
      case PRType.maxWeight:
        return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}kg';
      case PRType.maxReps:
        return '${value.toInt()} reps';
      case PRType.maxDuration:
        final minutes = value ~/ 60;
        final seconds = (value % 60).toInt();
        // For durations under 2 minutes, show seconds only for simplicity
        if (value < 120) {
          return '${value.toInt()}s';
        } else if (minutes > 0 && seconds == 0) {
          return '${minutes}m';
        } else {
          return '${minutes}m ${seconds}s';
        }
      case PRType.maxDistance:
        return value >= 1000 
            ? '${(value / 1000).toStringAsFixed(2)}km'
            : '${value.toStringAsFixed(0)}m';
      case PRType.maxVolume:
        return '${value.toStringAsFixed(0)} vol';
      case PRType.oneRepMax:
        return '${value.toStringAsFixed(0)}kg (1RM)';
    }
  }

  factory PersonalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonalRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseId: data['exerciseId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      exerciseType: ExerciseType.fromString(data['exerciseType'] ?? 'custom'),
      prType: PRType.fromString(data['prType'] ?? 'maxWeight'),
      value: data['value']?.toDouble() ?? 0.0,
      previousValue: data['previousValue']?.toDouble(),
      achievedAt: (data['achievedAt'] as Timestamp).toDate(),
      workoutId: data['workoutId'] ?? '',
      setId: data['setId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'exerciseType': exerciseType.toMap(),
      'prType': prType.toMap(),
      'value': value,
      'previousValue': previousValue,
      'achievedAt': Timestamp.fromDate(achievedAt),
      'workoutId': workoutId,
      'setId': setId,
    };
  }
}

/// Types of personal records
enum PRType {
  oneRepMax,
  maxWeight,
  maxReps,
  maxVolume,
  maxDuration,
  maxDistance;

  String get displayName {
    switch (this) {
      case PRType.oneRepMax:
        return '1RM';
      case PRType.maxWeight:
        return 'Max Weight';
      case PRType.maxReps:
        return 'Max Reps';
      case PRType.maxVolume:
        return 'Volume PR';
      case PRType.maxDuration:
        return 'Max Duration';
      case PRType.maxDistance:
        return 'Max Distance';
    }
  }

  String toMap() {
    switch (this) {
      case PRType.oneRepMax:
        return 'onerepmax';
      case PRType.maxWeight:
        return 'maxweight';
      case PRType.maxReps:
        return 'maxreps';
      case PRType.maxVolume:
        return 'maxvolume';
      case PRType.maxDuration:
        return 'maxduration';
      case PRType.maxDistance:
        return 'maxdistance';
    }
  }

  static PRType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'onerepmax':
      case 'one_rep_max':
        return PRType.oneRepMax;
      case 'maxweight':
      case 'max_weight':
        return PRType.maxWeight;
      case 'maxreps':
      case 'max_reps':
        return PRType.maxReps;
      case 'maxvolume':
      case 'max_volume':
        return PRType.maxVolume;
      case 'maxduration':
      case 'max_duration':
        return PRType.maxDuration;
      case 'maxdistance':
      case 'max_distance':
        return PRType.maxDistance;
      default:
        return PRType.maxWeight;
    }
  }

}

/// Activity heatmap data for GitHub-style visualization
class ActivityHeatmapData {
  final String userId;
  final int year;
  final Map<DateTime, int> dailySetCounts; // Date -> set count (changed from workouts)
  final int currentStreak;
  final int longestStreak;
  final int totalSets; // Changed from totalWorkouts
  final String? programId; // NEW: Optional program filter

  ActivityHeatmapData({
    required this.userId,
    required this.year,
    required this.dailySetCounts,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSets,
    this.programId,
  });

  /// Factory constructor to compute heatmap from workout data
  factory ActivityHeatmapData.fromWorkouts({
    required String userId,
    required int year,
    required List<Workout> workouts,
  }) {
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31, 23, 59, 59);

    // Filter workouts for the specified year
    final yearWorkouts = workouts.where((w) =>
        w.createdAt.isAfter(yearStart.subtract(const Duration(days: 1))) &&
        w.createdAt.isBefore(yearEnd.add(const Duration(days: 1)))).toList();

    // Group workouts by date
    final Map<DateTime, int> dailyCounts = {};
    for (final workout in yearWorkouts) {
      final date = DateTime(
        workout.createdAt.year,
        workout.createdAt.month,
        workout.createdAt.day,
      );
      dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
    }

    // Calculate streaks
    final streaks = _calculateStreaks(dailyCounts, year);

    return ActivityHeatmapData(
      userId: userId,
      year: year,
      dailySetCounts: dailyCounts,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
      totalSets: yearWorkouts.length,
      programId: null,
    );
  }

  /// Get heatmap days for the year
  List<HeatmapDay> getHeatmapDays() {
    final days = <HeatmapDay>[];
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);

    for (var date = startDate; date.isBefore(endDate.add(const Duration(days: 1)));
         date = date.add(const Duration(days: 1))) {
      final setCount = getSetCountForDate(date);
      final intensity = getIntensityForDate(date);

      days.add(HeatmapDay(
        date: date,
        workoutCount: setCount,
        intensity: intensity,
      ));
    }

    return days;
  }

  /// Get set count for a specific date
  int getSetCountForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailySetCounts[normalizedDate] ?? 0;
  }

  /// Get intensity for a specific date based on set count
  HeatmapIntensity getIntensityForDate(DateTime date) {
    final count = getSetCountForDate(date);
    return HeatmapIntensity.fromSetCount(count);
  }

  /// Calculate current and longest streaks
  static ({int current, int longest}) _calculateStreaks(
      Map<DateTime, int> dailyCounts, int year) {
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

/// Individual day data for heatmap visualization
class HeatmapDay {
  final DateTime date;
  final int workoutCount;
  final HeatmapIntensity intensity;

  const HeatmapDay({
    required this.date,
    required this.workoutCount,
    required this.intensity,
  });
}

/// Intensity levels for heatmap visualization
enum HeatmapIntensity {
  none,     // 0 sets - background color
  low,      // 1-5 sets - lightest shade
  medium,   // 6-15 sets - light-medium shade
  high,     // 16-25 sets - medium-dark shade
  veryHigh; // 26+ sets - darkest shade

  String get displayName {
    switch (this) {
      case HeatmapIntensity.none:
        return 'No activity';
      case HeatmapIntensity.low:
        return 'Light activity';
      case HeatmapIntensity.medium:
        return 'Moderate activity';
      case HeatmapIntensity.high:
        return 'High activity';
      case HeatmapIntensity.veryHigh:
        return 'Very high activity';
    }
  }

  /// Get intensity level from set count
  ///
  /// Intensity levels are determined by set count thresholds:
  /// - none: 0 sets
  /// - low: 1-5 sets
  /// - medium: 6-15 sets
  /// - high: 16-25 sets
  /// - veryHigh: 26+ sets
  ///
  /// These thresholds are designed to provide visual distinction in the
  /// GitHub-style heatmap calendar, where different colors represent
  /// different activity levels.
  static HeatmapIntensity fromSetCount(int setCount) {
    if (setCount == 0) return HeatmapIntensity.none;
    if (setCount <= 5) return HeatmapIntensity.low;
    if (setCount <= 15) return HeatmapIntensity.medium;
    if (setCount <= 25) return HeatmapIntensity.high;
    return HeatmapIntensity.veryHigh;
  }
}

/// Heatmap data for a single month
///
/// Represents activity data for one calendar month with daily set counts.
/// This model is used by the monthly calendar view to display workout activity
/// intensity across the days of the month.
///
/// The [dailySetCounts] map uses day of month (1-31) as keys and total
/// checked sets as values. Days with no activity are not included in the map.
///
/// Example:
/// ```dart
/// final monthData = MonthHeatmapData(
///   year: 2024,
///   month: 12,
///   dailySetCounts: {
///     1: 8,   // December 1st: 8 sets
///     2: 12,  // December 2nd: 12 sets
///     5: 6,   // December 5th: 6 sets
///   },
///   totalSets: 26,
///   fetchedAt: DateTime.now(),
/// );
///
/// // Get set count for a specific day
/// final day5Count = monthData.getSetCountForDay(5); // Returns 6
/// final day3Count = monthData.getSetCountForDay(3); // Returns 0 (no data)
///
/// // Get heatmap intensity for visualization
/// final day5Intensity = monthData.getIntensityForDay(5); // Returns HeatmapIntensity.medium
/// ```
class MonthHeatmapData {
  /// Year (e.g., 2024)
  final int year;

  /// Month (1-12)
  final int month;

  /// Map of day of month (1-31) to total checked sets for that day
  ///
  /// Only days with activity are included. Days with no sets are absent from the map.
  /// Values represent the total count of sets where `checked: true`.
  final Map<int, int> dailySetCounts;

  /// Total sets completed in the month (sum of all dailySetCounts values)
  final int totalSets;

  /// Timestamp when this data was fetched from Firestore
  ///
  /// Used for cache validation. Data is considered stale after 5 minutes.
  final DateTime fetchedAt;

  const MonthHeatmapData({
    required this.year,
    required this.month,
    required this.dailySetCounts,
    required this.totalSets,
    required this.fetchedAt,
  });

  /// Get set count for a specific day of the month
  ///
  /// Returns 0 if no data exists for the day.
  ///
  /// Parameters:
  /// - [day]: Day of month (1-31)
  ///
  /// Returns:
  /// Total checked sets for the day, or 0 if no data.
  ///
  /// Example:
  /// ```dart
  /// final count = monthData.getSetCountForDay(15);
  /// if (count > 0) {
  ///   print('December 15: $count sets');
  /// }
  /// ```
  int getSetCountForDay(int day) {
    return dailySetCounts[day] ?? 0;
  }

  /// Get heatmap intensity for a specific day
  ///
  /// Intensity levels are based on set count thresholds:
  /// - none: 0 sets
  /// - low: 1-5 sets
  /// - medium: 6-15 sets
  /// - high: 16-25 sets
  /// - veryHigh: 26+ sets
  ///
  /// Parameters:
  /// - [day]: Day of month (1-31)
  ///
  /// Returns:
  /// HeatmapIntensity enum value for the day's activity level.
  ///
  /// Example:
  /// ```dart
  /// final intensity = monthData.getIntensityForDay(10);
  /// final color = _getColorForIntensity(intensity);
  /// ```
  HeatmapIntensity getIntensityForDay(int day) {
    final count = getSetCountForDay(day);
    return HeatmapIntensity.fromSetCount(count);
  }

  /// Check if cache is still valid (within 5 minutes)
  ///
  /// Returns true if less than 5 minutes have passed since [fetchedAt],
  /// false otherwise. Used to determine if cached data can be reused or
  /// if a fresh Firestore query is needed.
  ///
  /// Example:
  /// ```dart
  /// if (cachedData.isCacheValid) {
  ///   return cachedData;
  /// } else {
  ///   return await fetchFreshData();
  /// }
  /// ```
  bool get isCacheValid {
    final now = DateTime.now();
    return now.difference(fetchedAt).inMinutes < 5;
  }
}

/// Date range utility class for heatmap timeframe calculations
///
/// Provides factory methods for common timeframe selections:
/// - thisWeek: Monday to Sunday of the current week
/// - thisMonth: First to last day of the current month
/// - thisYear: January 1 to December 31 of the current year
/// - last30Days: Rolling 30-day window from today
///
/// All date ranges are normalized to start at 00:00:00 and end at 23:59:59
/// to ensure consistent day-level grouping in analytics.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// Creates a date range for the current week (Monday to Sunday)
  ///
  /// The week always starts on Monday (ISO 8601 standard) and includes
  /// 7 consecutive days ending on Sunday.
  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return DateRange(
      start: DateTime(weekStart.year, weekStart.month, weekStart.day),
      end: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    );
  }

  /// Creates a date range for the current month
  ///
  /// Includes all days from the 1st to the last day of the current month.
  /// Automatically handles months with different lengths (28-31 days).
  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(microseconds: 1));
    return DateRange(start: monthStart, end: monthEnd);
  }

  /// Creates a date range for the current calendar year
  ///
  /// Includes all days from January 1 to December 31 of the current year.
  factory DateRange.thisYear() {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    return DateRange(start: yearStart, end: yearEnd);
  }

  /// Creates a rolling 30-day date range ending today
  ///
  /// The range includes the last 30 days (including today), which provides
  /// a consistent time window regardless of month boundaries.
  factory DateRange.last30Days() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end.subtract(const Duration(days: 29));
    return DateRange(start: start, end: end);
  }

  /// Check if a date falls within this range
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(microseconds: 1))) &&
           date.isBefore(end.add(const Duration(microseconds: 1)));
  }

  /// Duration of the range in days
  int get durationInDays => end.difference(start).inDays + 1;
}

