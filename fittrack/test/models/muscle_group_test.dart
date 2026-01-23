import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/muscle_group.dart';

void main() {
  group('MuscleGroup', () {
    group('values', () {
      test('should have 6 muscle groups', () {
        expect(MuscleGroup.values.length, 6);
      });

      test('should contain all expected muscle groups', () {
        expect(MuscleGroup.values, contains(MuscleGroup.chest));
        expect(MuscleGroup.values, contains(MuscleGroup.back));
        expect(MuscleGroup.values, contains(MuscleGroup.shoulders));
        expect(MuscleGroup.values, contains(MuscleGroup.arms));
        expect(MuscleGroup.values, contains(MuscleGroup.legs));
        expect(MuscleGroup.values, contains(MuscleGroup.core));
      });
    });

    group('displayName', () {
      test('should return correct display name for chest', () {
        expect(MuscleGroup.chest.displayName, 'Chest');
      });

      test('should return correct display name for back', () {
        expect(MuscleGroup.back.displayName, 'Back');
      });

      test('should return correct display name for shoulders', () {
        expect(MuscleGroup.shoulders.displayName, 'Shoulders');
      });

      test('should return correct display name for arms', () {
        expect(MuscleGroup.arms.displayName, 'Arms');
      });

      test('should return correct display name for legs', () {
        expect(MuscleGroup.legs.displayName, 'Legs');
      });

      test('should return correct display name for core', () {
        expect(MuscleGroup.core.displayName, 'Core');
      });

      test('all muscle groups should have unique display names', () {
        final displayNames =
            MuscleGroup.values.map((m) => m.displayName).toList();
        expect(displayNames.toSet().length, displayNames.length);
      });
    });

    group('fromString', () {
      test('should parse chest correctly', () {
        expect(MuscleGroup.fromString('chest'), MuscleGroup.chest);
      });

      test('should parse back correctly', () {
        expect(MuscleGroup.fromString('back'), MuscleGroup.back);
      });

      test('should parse shoulders correctly', () {
        expect(MuscleGroup.fromString('shoulders'), MuscleGroup.shoulders);
      });

      test('should parse arms correctly', () {
        expect(MuscleGroup.fromString('arms'), MuscleGroup.arms);
      });

      test('should parse legs correctly', () {
        expect(MuscleGroup.fromString('legs'), MuscleGroup.legs);
      });

      test('should parse core correctly', () {
        expect(MuscleGroup.fromString('core'), MuscleGroup.core);
      });

      test('should be case-insensitive', () {
        expect(MuscleGroup.fromString('CHEST'), MuscleGroup.chest);
        expect(MuscleGroup.fromString('Chest'), MuscleGroup.chest);
        expect(MuscleGroup.fromString('cHeSt'), MuscleGroup.chest);
      });

      test('should throw ArgumentError for unknown muscle group', () {
        expect(
          () => MuscleGroup.fromString('unknown'),
          throwsArgumentError,
        );
      });

      test('should throw ArgumentError for empty string', () {
        expect(
          () => MuscleGroup.fromString(''),
          throwsArgumentError,
        );
      });
    });

    group('toMap', () {
      test('should return lowercase string for chest', () {
        expect(MuscleGroup.chest.toMap(), 'chest');
      });

      test('should return lowercase string for back', () {
        expect(MuscleGroup.back.toMap(), 'back');
      });

      test('should return lowercase string for shoulders', () {
        expect(MuscleGroup.shoulders.toMap(), 'shoulders');
      });

      test('should return lowercase string for arms', () {
        expect(MuscleGroup.arms.toMap(), 'arms');
      });

      test('should return lowercase string for legs', () {
        expect(MuscleGroup.legs.toMap(), 'legs');
      });

      test('should return lowercase string for core', () {
        expect(MuscleGroup.core.toMap(), 'core');
      });

      test('toMap and fromString should be inverses', () {
        for (final muscleGroup in MuscleGroup.values) {
          final serialized = muscleGroup.toMap();
          final deserialized = MuscleGroup.fromString(serialized);
          expect(deserialized, muscleGroup);
        }
      });
    });
  });
}
