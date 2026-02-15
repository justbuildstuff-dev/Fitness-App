import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/charts/chart_data.dart';
import 'package:fittrack/widgets/charts/line_chart_painter.dart';

void main() {
  group('ChartDataPoint', () {
    test('creates with required fields', () {
      final point = ChartDataPoint(
        date: DateTime(2024, 6, 15),
        value: 100.0,
      );
      expect(point.date, equals(DateTime(2024, 6, 15)));
      expect(point.value, equals(100.0));
      expect(point.label, isNull);
    });

    test('creates with optional label', () {
      final point = ChartDataPoint(
        date: DateTime(2024, 6, 15),
        value: 100.0,
        label: 'Max weight',
      );
      expect(point.label, equals('Max weight'));
    });

    test('equality works correctly', () {
      final a = ChartDataPoint(date: DateTime(2024, 6, 15), value: 100.0);
      final b = ChartDataPoint(date: DateTime(2024, 6, 15), value: 100.0);
      final c = ChartDataPoint(date: DateTime(2024, 6, 16), value: 100.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = ChartDataPoint(date: DateTime(2024, 6, 15), value: 100.0);
      final b = ChartDataPoint(date: DateTime(2024, 6, 15), value: 100.0);

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('BarChartEntry', () {
    test('creates with all fields', () {
      const entry = BarChartEntry(
        label: 'Chest',
        value: 20,
        percentage: 40.0,
        color: Color(0xFF0000FF),
      );
      expect(entry.label, equals('Chest'));
      expect(entry.value, equals(20));
      expect(entry.percentage, equals(40.0));
      expect(entry.color, equals(const Color(0xFF0000FF)));
    });

    test('equality works correctly', () {
      const a = BarChartEntry(
        label: 'Chest', value: 20, percentage: 40.0, color: Color(0xFF0000FF),
      );
      const b = BarChartEntry(
        label: 'Chest', value: 20, percentage: 40.0, color: Color(0xFF0000FF),
      );
      const c = BarChartEntry(
        label: 'Back', value: 20, percentage: 40.0, color: Color(0xFF0000FF),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('LineChartPainter.findClosestPoint', () {
    final data = [
      ChartDataPoint(date: DateTime(2024, 6, 1), value: 80.0),
      ChartDataPoint(date: DateTime(2024, 6, 15), value: 100.0),
      ChartDataPoint(date: DateTime(2024, 6, 30), value: 90.0),
    ];

    test('returns null for empty data', () {
      final result = LineChartPainter.findClosestPoint(
        const Offset(100, 100),
        [],
        const Size(400, 250),
      );
      expect(result, isNull);
    });

    test('returns null when tap is far from all points', () {
      // Tap far outside the chart area
      final result = LineChartPainter.findClosestPoint(
        const Offset(0, 0),
        data,
        const Size(400, 250),
        hitRadius: 5.0, // Very small radius
      );
      expect(result, isNull);
    });

    test('returns closest point index when tapping near data', () {
      // The first point should be near left padding (50) area
      // Y position depends on value scaling
      final result = LineChartPainter.findClosestPoint(
        const Offset(50, 125), // Near first data point
        data,
        const Size(400, 250),
        hitRadius: 100.0, // Large radius to ensure hit
      );
      expect(result, isNotNull);
      expect(result, greaterThanOrEqualTo(0));
      expect(result, lessThan(data.length));
    });
  });
}
