import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/screens/analytics/components/training_trends_section.dart';
import 'package:fittrack/widgets/charts/line_chart_widget.dart';

void main() {
  Widget buildTestWidget({
    List<WeeklyTrendPoint>? trendsData,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TrainingTrendsSection(
            trendsData: trendsData,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  List<WeeklyTrendPoint> createTrendData({int weeks = 6}) {
    return List.generate(weeks, (i) {
      final weekStart = DateTime(2024, 1, 1).add(Duration(days: i * 7));
      return WeeklyTrendPoint(
        weekStart: weekStart,
        totalVolume: 1000.0 + i * 200,
        workoutCount: 3 + (i % 3),
      );
    });
  }

  group('TrainingTrendsSection', () {
    testWidgets('shows both chart titles', (tester) async {
      await tester.pumpWidget(
          buildTestWidget(trendsData: createTrendData()));

      expect(find.text('Weekly Training Volume'), findsOneWidget);
      expect(find.text('Weekly Workout Frequency'), findsOneWidget);
    });

    testWidgets('shows loading state for both charts', (tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });

    testWidgets('shows empty state when null data', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text('Complete some workouts to see training trends'),
        findsOneWidget,
      );
      expect(
        find.text('Complete some workouts to see frequency trends'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when empty list', (tester) async {
      await tester.pumpWidget(buildTestWidget(trendsData: []));

      expect(
        find.text('Complete some workouts to see training trends'),
        findsOneWidget,
      );
    });

    testWidgets('shows two line charts with data', (tester) async {
      await tester.pumpWidget(
          buildTestWidget(trendsData: createTrendData()));

      expect(find.byType(LineChartWidget), findsNWidgets(2));
    });

    testWidgets('renders in two Cards', (tester) async {
      await tester.pumpWidget(
          buildTestWidget(trendsData: createTrendData()));

      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows moving average with enough data points',
        (tester) async {
      // 6 weeks of data - should produce 3 moving average points
      await tester.pumpWidget(
          buildTestWidget(trendsData: createTrendData(weeks: 6)));

      // Both charts should show "4-wk avg" legend
      expect(find.text('4-wk avg'), findsNWidgets(2));
    });

    testWidgets('no moving average with fewer than 4 points',
        (tester) async {
      await tester.pumpWidget(
          buildTestWidget(trendsData: createTrendData(weeks: 3)));

      // No "4-wk avg" should appear
      expect(find.text('4-wk avg'), findsNothing);
    });
  });
}
