import 'dart:ui';

/// A single data point for time-series line charts
class ChartDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  const ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartDataPoint &&
        other.date == date &&
        other.value == value &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(date, value, label);
}

/// A single entry for horizontal bar charts
class BarChartEntry {
  final String label;
  final double value;
  final double percentage;
  final Color color;

  const BarChartEntry({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarChartEntry &&
        other.label == label &&
        other.value == value &&
        other.percentage == percentage &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(label, value, percentage, color);
}
