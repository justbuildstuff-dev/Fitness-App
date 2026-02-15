import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/charts/chart_data.dart';
import 'package:fittrack/widgets/charts/line_chart_widget.dart';

void main() {
  group('LineChartWidget', () {
    Widget buildTestWidget({
      List<ChartDataPoint> data = const [],
      List<ChartDataPoint>? secondaryData,
      String? primaryLabel,
      String? secondaryLabel,
      String? emptyMessage,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LineChartWidget(
            data: data,
            secondaryData: secondaryData,
            primaryLabel: primaryLabel,
            secondaryLabel: secondaryLabel,
            emptyMessage: emptyMessage,
          ),
        ),
      );
    }

    final sampleData = [
      ChartDataPoint(date: DateTime(2024, 6, 1), value: 80.0),
      ChartDataPoint(date: DateTime(2024, 6, 8), value: 85.0),
      ChartDataPoint(date: DateTime(2024, 6, 15), value: 90.0),
      ChartDataPoint(date: DateTime(2024, 6, 22), value: 87.5),
    ];

    final secondarySampleData = [
      ChartDataPoint(date: DateTime(2024, 6, 1), value: 100.0),
      ChartDataPoint(date: DateTime(2024, 6, 8), value: 105.0),
      ChartDataPoint(date: DateTime(2024, 6, 15), value: 112.0),
      ChartDataPoint(date: DateTime(2024, 6, 22), value: 108.0),
    ];

    testWidgets('renders with data', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: sampleData));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        emptyMessage: 'No workouts yet',
      ));

      // CustomPaint is still rendered (painter handles empty)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom height', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LineChartWidget(
            data: sampleData,
            height: 300,
          ),
        ),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, equals(300.0));
    });

    testWidgets('shows legend when secondary data and labels provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        data: sampleData,
        secondaryData: secondarySampleData,
        primaryLabel: 'Weight',
        secondaryLabel: 'Est. 1RM',
      ));

      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Est. 1RM'), findsOneWidget);
    });

    testWidgets('does not show legend without labels', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        data: sampleData,
        secondaryData: secondarySampleData,
      ));

      expect(find.text('Weight'), findsNothing);
      expect(find.text('Est. 1RM'), findsNothing);
    });

    testWidgets('tap selects data point', (tester) async {
      await tester.pumpWidget(buildTestWidget(data: sampleData));

      // Tap on the chart area
      final gesture = find.byType(GestureDetector);
      await tester.tapAt(tester.getCenter(gesture));
      await tester.pump();

      // Widget should rebuild (state change) - no crash
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        data: sampleData,
        primaryLabel: 'Weight',
      ));

      final semantics = find.bySemanticsLabel(
        RegExp(r'Line chart showing Weight with 4 data points'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('has empty semantics when no data', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        emptyMessage: 'No data yet',
      ));

      final semantics = find.bySemanticsLabel('No data yet');
      expect(semantics, findsOneWidget);
    });

    testWidgets('renders single data point without crash', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        data: [ChartDataPoint(date: DateTime(2024, 6, 1), value: 100.0)],
      ));

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
