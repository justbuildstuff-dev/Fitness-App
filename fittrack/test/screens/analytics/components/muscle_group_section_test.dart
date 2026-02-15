import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/screens/analytics/components/muscle_group_section.dart';
import 'package:fittrack/widgets/charts/bar_chart_widget.dart';

void main() {
  Widget buildTestWidget({
    List<MuscleGroupVolume>? volumeData,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MuscleGroupSection(
            volumeData: volumeData,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  final sampleVolumeData = [
    const MuscleGroupVolume(
      muscleGroup: MuscleGroup.chest,
      label: 'Chest',
      totalSets: 20,
      percentage: 25.0,
    ),
    const MuscleGroupVolume(
      muscleGroup: MuscleGroup.back,
      label: 'Back',
      totalSets: 18,
      percentage: 22.5,
    ),
    const MuscleGroupVolume(
      muscleGroup: MuscleGroup.legs,
      label: 'Legs',
      totalSets: 16,
      percentage: 20.0,
    ),
    const MuscleGroupVolume(
      muscleGroup: MuscleGroup.shoulders,
      label: 'Shoulders',
      totalSets: 12,
      percentage: 15.0,
    ),
    const MuscleGroupVolume(
      muscleGroup: MuscleGroup.arms,
      label: 'Arms',
      totalSets: 10,
      percentage: 12.5,
    ),
    const MuscleGroupVolume(
      muscleGroup: MuscleGroup.core,
      label: 'Core',
      totalSets: 4,
      percentage: 5.0,
    ),
  ];

  group('MuscleGroupSection', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildTestWidget(volumeData: sampleVolumeData));

      expect(find.text('Muscle Group Volume'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when null data', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text('Complete some workouts to see muscle group breakdown'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when empty list', (tester) async {
      await tester.pumpWidget(buildTestWidget(volumeData: []));

      expect(
        find.text('Complete some workouts to see muscle group breakdown'),
        findsOneWidget,
      );
    });

    testWidgets('shows bar chart when data available', (tester) async {
      await tester.pumpWidget(buildTestWidget(volumeData: sampleVolumeData));

      expect(find.byType(BarChartWidget), findsOneWidget);
    });

    testWidgets('renders in a Card', (tester) async {
      await tester.pumpWidget(buildTestWidget(volumeData: sampleVolumeData));

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('MuscleGroupSection.colorForMuscleGroup', () {
    test('returns distinct colors for each muscle group', () {
      final colors = MuscleGroup.values
          .map((g) => MuscleGroupSection.colorForMuscleGroup(g))
          .toSet();
      // All 6 muscle groups should have unique colors
      expect(colors.length, equals(6));
    });

    test('returns grey for null (Other)', () {
      final color = MuscleGroupSection.colorForMuscleGroup(null);
      expect(color, equals(Colors.grey));
    });
  });
}
