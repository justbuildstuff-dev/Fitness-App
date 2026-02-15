import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/utils/one_rm_calculator.dart';
import 'package:fittrack/models/exercise_set.dart';

void main() {
  group('OneRMCalculator', () {
    group('epley', () {
      test('calculates 1RM correctly for standard inputs', () {
        // 100kg for 5 reps: 100 * (1 + 5/30) = 100 * 1.1667 ≈ 116.67
        final result = OneRMCalculator.epley(100, 5);
        expect(result, closeTo(116.67, 0.01));
      });

      test('calculates 1RM for 10 reps', () {
        // 80kg for 10 reps: 80 * (1 + 10/30) = 80 * 1.3333 ≈ 106.67
        final result = OneRMCalculator.epley(80, 10);
        expect(result, closeTo(106.67, 0.01));
      });

      test('returns weight itself for 1 rep (actual 1RM)', () {
        final result = OneRMCalculator.epley(120, 1);
        expect(result, equals(120.0));
      });

      test('returns 0 for 0 reps', () {
        final result = OneRMCalculator.epley(100, 0);
        expect(result, equals(0.0));
      });

      test('returns 0 for negative reps', () {
        final result = OneRMCalculator.epley(100, -1);
        expect(result, equals(0.0));
      });

      test('returns 0 for 0 weight', () {
        final result = OneRMCalculator.epley(0, 5);
        expect(result, equals(0.0));
      });

      test('returns 0 for negative weight', () {
        final result = OneRMCalculator.epley(-50, 5);
        expect(result, equals(0.0));
      });

      test('handles decimal weight', () {
        // 67.5kg for 8 reps: 67.5 * (1 + 8/30) = 67.5 * 1.2667 ≈ 85.5
        final result = OneRMCalculator.epley(67.5, 8);
        expect(result, closeTo(85.5, 0.01));
      });
    });

    group('brzycki', () {
      test('calculates 1RM correctly for standard inputs', () {
        // 100kg for 5 reps: 100 * (36 / (37 - 5)) = 100 * (36/32) = 112.5
        final result = OneRMCalculator.brzycki(100, 5);
        expect(result, closeTo(112.5, 0.01));
      });

      test('calculates 1RM for 10 reps', () {
        // 80kg for 10 reps: 80 * (36 / (37 - 10)) = 80 * (36/27) ≈ 106.67
        final result = OneRMCalculator.brzycki(80, 10);
        expect(result, closeTo(106.67, 0.01));
      });

      test('returns weight itself for 1 rep (actual 1RM)', () {
        final result = OneRMCalculator.brzycki(120, 1);
        expect(result, equals(120.0));
      });

      test('returns 0 for 0 reps', () {
        final result = OneRMCalculator.brzycki(100, 0);
        expect(result, equals(0.0));
      });

      test('returns 0 for negative reps', () {
        final result = OneRMCalculator.brzycki(100, -1);
        expect(result, equals(0.0));
      });

      test('returns 0 for 0 weight', () {
        final result = OneRMCalculator.brzycki(0, 5);
        expect(result, equals(0.0));
      });

      test('returns 0 for negative weight', () {
        final result = OneRMCalculator.brzycki(-50, 5);
        expect(result, equals(0.0));
      });

      test('returns 0 for reps >= 37 (division by zero protection)', () {
        final result = OneRMCalculator.brzycki(100, 37);
        expect(result, equals(0.0));
      });

      test('returns 0 for reps > 37', () {
        final result = OneRMCalculator.brzycki(100, 40);
        expect(result, equals(0.0));
      });
    });

    group('estimateFromSets', () {
      ExerciseSet createTestSet({
        double? weight,
        int? reps,
        String id = '1',
      }) {
        return ExerciseSet(
          id: id,
          setNumber: 1,
          reps: reps,
          weight: weight,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user123',
          exerciseId: 'ex1',
          workoutId: 'w1',
          weekId: 'wk1',
          programId: 'p1',
        );
      }

      test('returns best 1RM from multiple sets', () {
        final sets = [
          createTestSet(weight: 80, reps: 8, id: '1'),   // Epley: 80*(1+8/30) ≈ 101.33
          createTestSet(weight: 100, reps: 3, id: '2'),   // Epley: 100*(1+3/30) = 110.0
          createTestSet(weight: 90, reps: 5, id: '3'),    // Epley: 90*(1+5/30) = 105.0
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNotNull);
        expect(result, closeTo(110.0, 0.01));
      });

      test('returns null for empty set list', () {
        final result = OneRMCalculator.estimateFromSets([]);
        expect(result, isNull);
      });

      test('returns null when all sets have reps > 10', () {
        final sets = [
          createTestSet(weight: 60, reps: 12, id: '1'),
          createTestSet(weight: 50, reps: 15, id: '2'),
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNull);
      });

      test('returns null when all sets have null weight', () {
        final sets = [
          createTestSet(weight: null, reps: 5, id: '1'),
          createTestSet(weight: null, reps: 8, id: '2'),
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNull);
      });

      test('returns null when all sets have null reps', () {
        final sets = [
          createTestSet(weight: 100, reps: null, id: '1'),
          createTestSet(weight: 80, reps: null, id: '2'),
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNull);
      });

      test('skips sets with weight <= 0', () {
        final sets = [
          createTestSet(weight: 0, reps: 5, id: '1'),
          createTestSet(weight: -10, reps: 3, id: '2'),
          createTestSet(weight: 80, reps: 5, id: '3'),  // Only eligible set
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNotNull);
        expect(result, closeTo(OneRMCalculator.epley(80, 5), 0.01));
      });

      test('skips sets with reps <= 0', () {
        final sets = [
          createTestSet(weight: 100, reps: 0, id: '1'),
          createTestSet(weight: 100, reps: -1, id: '2'),
          createTestSet(weight: 80, reps: 5, id: '3'),  // Only eligible set
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNotNull);
        expect(result, closeTo(OneRMCalculator.epley(80, 5), 0.01));
      });

      test('filters out sets with reps > 10 but uses eligible ones', () {
        final sets = [
          createTestSet(weight: 60, reps: 15, id: '1'),  // Skipped: reps > 10
          createTestSet(weight: 100, reps: 5, id: '2'),   // Eligible
          createTestSet(weight: 50, reps: 20, id: '3'),   // Skipped: reps > 10
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNotNull);
        expect(result, closeTo(OneRMCalculator.epley(100, 5), 0.01));
      });

      test('handles single eligible set', () {
        final sets = [
          createTestSet(weight: 100, reps: 1, id: '1'),  // Actual 1RM
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, equals(100.0));
      });

      test('handles set at max reliable reps boundary (10)', () {
        final sets = [
          createTestSet(weight: 70, reps: 10, id: '1'),
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNotNull);
        expect(result, closeTo(OneRMCalculator.epley(70, 10), 0.01));
      });

      test('excludes set at reps = 11 (above max reliable)', () {
        final sets = [
          createTestSet(weight: 70, reps: 11, id: '1'),
        ];

        final result = OneRMCalculator.estimateFromSets(sets);
        expect(result, isNull);
      });
    });

    group('maxReliableReps constant', () {
      test('is set to 10', () {
        expect(OneRMCalculator.maxReliableReps, equals(10));
      });
    });
  });
}
