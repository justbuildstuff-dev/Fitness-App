import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/charts/chart_data.dart';
import 'package:fittrack/widgets/charts/bar_chart_painter.dart';
import 'package:fittrack/widgets/charts/bar_chart_widget.dart';

void main() {
  group('BarChartWidget', () {
    Widget buildTestWidget({
      List<BarChartEntry> entries = const [],
      double? height,
      String? emptyMessage,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BarChartWidget(
            entries: entries,
            height: height,
            emptyMessage: emptyMessage,
          ),
        ),
      );
    }

    final sampleEntries = [
      const BarChartEntry(
        label: 'Chest', value: 20, percentage: 40, color: Colors.blue,
      ),
      const BarChartEntry(
        label: 'Back', value: 15, percentage: 30, color: Colors.green,
      ),
      const BarChartEntry(
        label: 'Legs', value: 15, percentage: 30, color: Colors.red,
      ),
    ];

    testWidgets('renders with entries', (tester) async {
      await tester.pumpWidget(buildTestWidget(entries: sampleEntries));

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        emptyMessage: 'No muscle data',
      ));

      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('auto-sizes height from entry count', (tester) async {
      await tester.pumpWidget(buildTestWidget(entries: sampleEntries));

      final expectedHeight = BarChartPainter.computeHeight(3);
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, equals(expectedHeight));
    });

    testWidgets('uses custom height when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        entries: sampleEntries,
        height: 200,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, equals(200.0));
    });

    testWidgets('has accessibility semantics', (tester) async {
      await tester.pumpWidget(buildTestWidget(entries: sampleEntries));

      final semantics = find.bySemanticsLabel(
        RegExp(r'Bar chart showing 3 categories, top: Chest'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('has empty semantics when no data', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        emptyMessage: 'No data',
      ));

      final semantics = find.bySemanticsLabel('No data');
      expect(semantics, findsOneWidget);
    });

    testWidgets('renders single entry without crash', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        entries: const [
          BarChartEntry(
            label: 'Arms', value: 10, percentage: 100, color: Colors.orange,
          ),
        ],
      ));

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('BarChartPainter.computeHeight', () {
    test('returns 60 for zero entries', () {
      expect(BarChartPainter.computeHeight(0), equals(60));
    });

    test('returns correct height for entries', () {
      // barHeight=28, barGap=8, so: n*36-8
      expect(BarChartPainter.computeHeight(1), equals(28));
      expect(BarChartPainter.computeHeight(3), equals(100)); // 3*36-8
      expect(BarChartPainter.computeHeight(6), equals(208)); // 6*36-8
    });
  });
}
