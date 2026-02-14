import '../models/exercise_set.dart';

/// Utility class for estimating one-repetition maximum (1RM) from sub-maximal
/// lift data.
///
/// Provides two industry-standard formulas:
/// - **Epley** (primary): Most accurate for moderate rep ranges (2-10)
/// - **Brzycki** (alternative): Tends to give slightly lower estimates
///
/// Both formulas are only reliable when reps <= 10. For higher rep ranges,
/// the estimates become increasingly inaccurate.
///
/// Example:
/// ```dart
/// // 100kg for 5 reps
/// final epley1RM = OneRMCalculator.epley(100, 5);   // ~116.67kg
/// final brzycki1RM = OneRMCalculator.brzycki(100, 5); // ~112.50kg
/// ```
class OneRMCalculator {
  OneRMCalculator._();

  /// Maximum reps for reliable 1RM estimation
  static const int maxReliableReps = 10;

  /// Calculate estimated 1RM using the Epley formula.
  ///
  /// Formula: weight * (1 + reps / 30)
  ///
  /// Returns the raw calculation regardless of rep count.
  /// For reps == 1, returns the weight itself (actual 1RM).
  static double epley(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// Calculate estimated 1RM using the Brzycki formula.
  ///
  /// Formula: weight * (36 / (37 - reps))
  ///
  /// Returns the raw calculation regardless of rep count.
  /// For reps == 1, returns the weight itself (actual 1RM).
  /// Note: Formula is undefined at reps == 37 (division by zero).
  static double brzycki(double weight, int reps) {
    if (reps <= 0 || weight <= 0) return 0;
    if (reps == 1) return weight;
    if (reps >= 37) return 0;
    return weight * (36 / (37 - reps));
  }

  /// Estimate 1RM from the best set in a list of exercise sets.
  ///
  /// Finds the set that produces the highest estimated 1RM (using Epley)
  /// from all eligible sets. A set is eligible if:
  /// - `weight > 0`
  /// - `reps > 0` and `reps <= 10`
  ///
  /// Returns `null` if no eligible sets are found.
  ///
  /// Example:
  /// ```dart
  /// final sets = [
  ///   ExerciseSet(weight: 80, reps: 8, ...),  // 1RM ≈ 101.3
  ///   ExerciseSet(weight: 100, reps: 3, ...),  // 1RM ≈ 110.0
  /// ];
  /// final best1RM = OneRMCalculator.estimateFromSets(sets); // ≈ 110.0
  /// ```
  static double? estimateFromSets(List<ExerciseSet> sets) {
    double? best1RM;

    for (final set in sets) {
      if (set.weight == null || set.reps == null) continue;
      if (set.weight! <= 0 || set.reps! <= 0) continue;
      if (set.reps! > maxReliableReps) continue;

      final estimated = epley(set.weight!, set.reps!);
      if (best1RM == null || estimated > best1RM) {
        best1RM = estimated;
      }
    }

    return best1RM;
  }
}
