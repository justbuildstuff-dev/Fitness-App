import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/templates/template_set.dart';

void main() {
  group('TemplateSet', () {
    late TemplateSet sampleSet;

    setUp(() {
      sampleSet = const TemplateSet(
        setNumber: 1,
        reps: 10,
        duration: 30,
        restTime: 60,
        notes: 'First set',
      );
    });

    group('constructor', () {
      test('should create set with all fields', () {
        expect(sampleSet.setNumber, 1);
        expect(sampleSet.reps, 10);
        expect(sampleSet.duration, 30);
        expect(sampleSet.restTime, 60);
        expect(sampleSet.notes, 'First set');
      });

      test('should create set with only required fields', () {
        const set = TemplateSet(setNumber: 1);

        expect(set.setNumber, 1);
        expect(set.reps, isNull);
        expect(set.duration, isNull);
        expect(set.restTime, isNull);
        expect(set.notes, isNull);
      });

      test('should allow const construction', () {
        const set1 = TemplateSet(setNumber: 1, reps: 10);
        const set2 = TemplateSet(setNumber: 1, reps: 10);

        expect(identical(set1, set2), isTrue);
      });
    });

    group('fromMap', () {
      test('should parse map with all fields', () {
        final map = {
          'setNumber': 2,
          'reps': 8,
          'duration': 45,
          'restTime': 90,
          'notes': 'Heavy set',
        };

        final set = TemplateSet.fromMap(map);

        expect(set.setNumber, 2);
        expect(set.reps, 8);
        expect(set.duration, 45);
        expect(set.restTime, 90);
        expect(set.notes, 'Heavy set');
      });

      test('should handle missing optional fields', () {
        final map = {
          'setNumber': 1,
        };

        final set = TemplateSet.fromMap(map);

        expect(set.setNumber, 1);
        expect(set.reps, isNull);
        expect(set.duration, isNull);
        expect(set.restTime, isNull);
        expect(set.notes, isNull);
      });

      test('should use default setNumber if missing', () {
        final map = <String, dynamic>{};

        final set = TemplateSet.fromMap(map);

        expect(set.setNumber, 0);
      });

      test('should handle null values', () {
        final map = {
          'setNumber': 1,
          'reps': null,
          'duration': null,
          'restTime': null,
          'notes': null,
        };

        final set = TemplateSet.fromMap(map);

        expect(set.reps, isNull);
        expect(set.duration, isNull);
        expect(set.restTime, isNull);
        expect(set.notes, isNull);
      });
    });

    group('toMap', () {
      test('should serialize all fields', () {
        final map = sampleSet.toMap();

        expect(map['setNumber'], 1);
        expect(map['reps'], 10);
        expect(map['duration'], 30);
        expect(map['restTime'], 60);
        expect(map['notes'], 'First set');
      });

      test('should omit null optional fields', () {
        const set = TemplateSet(setNumber: 1);
        final map = set.toMap();

        expect(map['setNumber'], 1);
        expect(map.containsKey('reps'), isFalse);
        expect(map.containsKey('duration'), isFalse);
        expect(map.containsKey('restTime'), isFalse);
        expect(map.containsKey('notes'), isFalse);
      });

      test('fromMap and toMap should be inverses', () {
        final map = sampleSet.toMap();
        final recreated = TemplateSet.fromMap(map);

        expect(recreated, sampleSet);
      });
    });

    group('copyWith', () {
      test('should create copy with updated setNumber', () {
        final updated = sampleSet.copyWith(setNumber: 2);

        expect(updated.setNumber, 2);
        expect(updated.reps, sampleSet.reps);
        expect(updated.duration, sampleSet.duration);
        expect(updated.restTime, sampleSet.restTime);
        expect(updated.notes, sampleSet.notes);
      });

      test('should create copy with updated reps', () {
        final updated = sampleSet.copyWith(reps: 12);

        expect(updated.reps, 12);
        expect(updated.setNumber, sampleSet.setNumber);
      });

      test('should create copy with updated duration', () {
        final updated = sampleSet.copyWith(duration: 60);

        expect(updated.duration, 60);
      });

      test('should create copy with updated restTime', () {
        final updated = sampleSet.copyWith(restTime: 120);

        expect(updated.restTime, 120);
      });

      test('should create copy with updated notes', () {
        final updated = sampleSet.copyWith(notes: 'New notes');

        expect(updated.notes, 'New notes');
      });

      test('should preserve all fields when no arguments provided', () {
        final copy = sampleSet.copyWith();

        expect(copy, sampleSet);
      });
    });

    group('displayString', () {
      test('should format set with reps', () {
        const set = TemplateSet(setNumber: 1, reps: 10);

        expect(set.displayString, 'Set 1: 10 reps');
      });

      test('should format set with duration', () {
        const set = TemplateSet(setNumber: 2, duration: 60);

        expect(set.displayString, 'Set 2: 60s');
      });

      test('should format set with both reps and duration (reps priority)', () {
        const set = TemplateSet(setNumber: 1, reps: 10, duration: 30);

        expect(set.displayString, 'Set 1: 10 reps');
      });

      test('should format set with no reps or duration', () {
        const set = TemplateSet(setNumber: 3);

        expect(set.displayString, 'Set 3');
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        const set1 = TemplateSet(
          setNumber: 1,
          reps: 10,
          duration: 30,
          restTime: 60,
          notes: 'Test',
        );
        const set2 = TemplateSet(
          setNumber: 1,
          reps: 10,
          duration: 30,
          restTime: 60,
          notes: 'Test',
        );

        expect(set1, set2);
        expect(set1.hashCode, set2.hashCode);
      });

      test('should not be equal for different setNumber', () {
        const set1 = TemplateSet(setNumber: 1, reps: 10);
        const set2 = TemplateSet(setNumber: 2, reps: 10);

        expect(set1, isNot(set2));
      });

      test('should not be equal for different reps', () {
        const set1 = TemplateSet(setNumber: 1, reps: 10);
        const set2 = TemplateSet(setNumber: 1, reps: 12);

        expect(set1, isNot(set2));
      });

      test('should not be equal for different notes', () {
        const set1 = TemplateSet(setNumber: 1, notes: 'Note 1');
        const set2 = TemplateSet(setNumber: 1, notes: 'Note 2');

        expect(set1, isNot(set2));
      });
    });
  });
}
