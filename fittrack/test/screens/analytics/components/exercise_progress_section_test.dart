import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/providers/weight_unit_provider.dart';
import 'package:fittrack/screens/analytics/components/exercise_progress_section.dart';
import 'package:fittrack/widgets/charts/line_chart_widget.dart';
import 'package:fittrack/widgets/charts/time_range_selector.dart';

void main() {
  late WeightUnitProvider weightUnitProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    weightUnitProvider = WeightUnitProvider(prefs);
  });

  Widget buildTestWidget({
    ExerciseProgressData? progressData,
    TimeRange selectedTimeRange = TimeRange.threeMonths,
    ValueChanged<TimeRange>? onTimeRangeChanged,
    bool isLoading = false,
  }) {
    return ChangeNotifierProvider<WeightUnitProvider>.value(
      value: weightUnitProvider,
      child: MaterialApp(
        home: Scaffold(
          body: ExerciseProgressSection(
            progressData: progressData,
            selectedTimeRange: selectedTimeRange,
            onTimeRangeChanged: onTimeRangeChanged ?? (_) {},
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  ExerciseProgressData createProgressData({
    ExerciseType type = ExerciseType.strength,
    List<ExerciseProgressPoint>? dataPoints,
  }) {
    return ExerciseProgressData(
      exerciseId: 'ex1',
      exerciseName: 'Bench Press',
      exerciseType: type,
      dataPoints: dataPoints ??
          [
            ExerciseProgressPoint(
              date: DateTime(2024, 1, 1),
              workoutId: 'w1',
              maxWeight: 60,
              maxReps: 8,
              estimated1RM: 75,
            ),
            ExerciseProgressPoint(
              date: DateTime(2024, 2, 1),
              workoutId: 'w2',
              maxWeight: 65,
              maxReps: 8,
              estimated1RM: 81.25,
            ),
            ExerciseProgressPoint(
              date: DateTime(2024, 3, 1),
              workoutId: 'w3',
              maxWeight: 70,
              maxReps: 8,
              estimated1RM: 87.5,
            ),
          ],
      dateRange: DateRange.last3Months(),
    );
  }

  group('ExerciseProgressSection', () {
    testWidgets('shows time range selector', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TimeRangeSelector), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows select exercise message when no data', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Select an exercise to see progress'), findsOneWidget);
    });

    testWidgets('shows empty state when data has no points', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        progressData: createProgressData(dataPoints: []),
      ));

      expect(
        find.text('No data for this exercise in the selected time range'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('shows line chart for strength exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        progressData: createProgressData(),
      ));

      expect(find.byType(LineChartWidget), findsOneWidget);
      expect(find.text('Showing max weight per session'), findsOneWidget);
    });

    testWidgets('shows line chart for bodyweight exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        progressData: createProgressData(
          type: ExerciseType.bodyweight,
          dataPoints: [
            ExerciseProgressPoint(
              date: DateTime(2024, 1, 1),
              workoutId: 'w1',
              maxReps: 10,
            ),
            ExerciseProgressPoint(
              date: DateTime(2024, 2, 1),
              workoutId: 'w2',
              maxReps: 12,
            ),
          ],
        ),
      ));

      expect(find.byType(LineChartWidget), findsOneWidget);
      expect(find.text('Showing max reps per session'), findsOneWidget);
    });

    testWidgets('shows line chart for cardio exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        progressData: createProgressData(
          type: ExerciseType.cardio,
          dataPoints: [
            ExerciseProgressPoint(
              date: DateTime(2024, 1, 1),
              workoutId: 'w1',
              totalDuration: 1800,
            ),
            ExerciseProgressPoint(
              date: DateTime(2024, 2, 1),
              workoutId: 'w2',
              totalDuration: 2000,
            ),
          ],
        ),
      ));

      expect(find.byType(LineChartWidget), findsOneWidget);
      expect(find.text('Showing total duration per session'), findsOneWidget);
    });

    testWidgets('shows line chart for custom exercise', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        progressData: createProgressData(
          type: ExerciseType.custom,
          dataPoints: [
            ExerciseProgressPoint(
              date: DateTime(2024, 1, 1),
              workoutId: 'w1',
              maxWeight: 20,
              maxReps: 15,
            ),
          ],
        ),
      ));

      expect(find.byType(LineChartWidget), findsOneWidget);
      expect(
          find.text('Showing estimated volume per session'), findsOneWidget);
    });

    testWidgets('calls onTimeRangeChanged when time range changes',
        (tester) async {
      TimeRange? changedRange;
      await tester.pumpWidget(buildTestWidget(
        progressData: createProgressData(),
        onTimeRangeChanged: (range) => changedRange = range,
      ));

      // Tap the "1M" button
      await tester.tap(find.text('1M'));
      await tester.pump();

      expect(changedRange, equals(TimeRange.oneMonth));
    });
  });
}
