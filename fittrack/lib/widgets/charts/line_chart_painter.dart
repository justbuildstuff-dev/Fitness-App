import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chart_data.dart';

/// CustomPainter for rendering time-series line charts.
///
/// Supports:
/// - Primary data line (solid) with data points
/// - Optional secondary data line (dashed) for overlay (e.g. est. 1RM)
/// - Background grid with auto-scaled axes
/// - Tap-to-select data point with tooltip
/// - Empty state message
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final List<ChartDataPoint>? secondaryData;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;
  final int? selectedIndex;
  final String? emptyMessage;
  final String? yAxisLabel;
  final String? secondaryYAxisLabel;

  /// Padding constants
  static const double leftPadding = 50.0;
  static const double rightPadding = 16.0;
  static const double topPadding = 20.0;
  static const double bottomPadding = 30.0;
  static const int gridLineCount = 5;
  static const double dataPointRadius = 4.0;
  static const double selectedPointRadius = 7.0;

  LineChartPainter({
    required this.data,
    this.secondaryData,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
    this.selectedIndex,
    this.emptyMessage,
    this.yAxisLabel,
    this.secondaryYAxisLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    final chartArea = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    // Compute Y range from all data
    final allValues = [
      ...data.map((d) => d.value),
      if (secondaryData != null) ...secondaryData!.map((d) => d.value),
    ];
    final minY = allValues.reduce(min);
    final maxY = allValues.reduce(max);
    final yRange = _computeNiceRange(minY, maxY);

    // Compute X range from dates
    final minDate = data.map((d) => d.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = data.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final dateRange = maxDate.difference(minDate).inMilliseconds.toDouble();

    _paintGrid(canvas, chartArea, yRange);
    _paintXAxis(canvas, chartArea, minDate, dateRange);
    _paintYAxis(canvas, chartArea, yRange);

    if (secondaryData != null && secondaryData!.isNotEmpty) {
      _paintDataLine(
        canvas, chartArea, secondaryData!, yRange, minDate, dateRange,
        color: secondaryColor, dashed: true, lineWidth: 1.5,
      );
    }

    _paintDataLine(
      canvas, chartArea, data, yRange, minDate, dateRange,
      color: primaryColor, dashed: false, lineWidth: 2.0,
    );

    _paintDataPoints(canvas, chartArea, data, yRange, minDate, dateRange, primaryColor);

    if (secondaryData != null && secondaryData!.isNotEmpty) {
      _paintDataPoints(canvas, chartArea, secondaryData!, yRange, minDate, dateRange, secondaryColor);
    }

    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < data.length) {
      _paintSelectedPoint(canvas, chartArea, yRange, minDate, dateRange, size);
    }
  }

  void _paintEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emptyMessage ?? 'No data available',
        style: TextStyle(color: textColor, fontSize: 14),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: size.width - 32);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _paintGrid(Canvas canvas, Rect chartArea, _YRange yRange) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridLineCount; i++) {
      final y = chartArea.top + (chartArea.height * i / gridLineCount);
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );
    }
  }

  void _paintXAxis(Canvas canvas, Rect chartArea, DateTime minDate, double dateRange) {
    if (data.length <= 1) {
      // Single point: just show the date centered
      if (data.isNotEmpty) {
        _drawXLabel(canvas, chartArea, data.first.date, chartArea.left + chartArea.width / 2);
      }
      return;
    }

    // Show up to 5 date labels, evenly spaced
    final labelCount = min(5, data.length);
    final step = (data.length - 1) / (labelCount - 1);

    for (int i = 0; i < labelCount; i++) {
      final index = (i * step).round().clamp(0, data.length - 1);
      final point = data[index];
      final x = dateRange > 0
          ? chartArea.left + (point.date.difference(minDate).inMilliseconds / dateRange) * chartArea.width
          : chartArea.left + chartArea.width / 2;
      _drawXLabel(canvas, chartArea, point.date, x);
    }
  }

  void _drawXLabel(Canvas canvas, Rect chartArea, DateTime date, double x) {
    final label = DateFormat('MMM d').format(date);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, chartArea.bottom + 4),
    );
  }

  void _paintYAxis(Canvas canvas, Rect chartArea, _YRange yRange) {
    for (int i = 0; i <= gridLineCount; i++) {
      final value = yRange.max - (yRange.range * i / gridLineCount);
      final y = chartArea.top + (chartArea.height * i / gridLineCount);

      final label = _formatYValue(value);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout(maxWidth: leftPadding - 8);
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 4, y - textPainter.height / 2),
      );
    }
  }

  void _paintDataLine(
    Canvas canvas,
    Rect chartArea,
    List<ChartDataPoint> points,
    _YRange yRange,
    DateTime minDate,
    double dateRange, {
    required Color color,
    required bool dashed,
    required double lineWidth,
  }) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final offset = _pointToOffset(points[i], chartArea, yRange, minDate, dateRange);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    if (dashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _paintDataPoints(
    Canvas canvas,
    Rect chartArea,
    List<ChartDataPoint> points,
    _YRange yRange,
    DateTime minDate,
    double dateRange,
    Color color,
  ) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final point in points) {
      final offset = _pointToOffset(point, chartArea, yRange, minDate, dateRange);
      canvas.drawCircle(offset, dataPointRadius, fillPaint);
      canvas.drawCircle(offset, dataPointRadius, strokePaint);
    }
  }

  void _paintSelectedPoint(
    Canvas canvas,
    Rect chartArea,
    _YRange yRange,
    DateTime minDate,
    double dateRange,
    Size canvasSize,
  ) {
    final point = data[selectedIndex!];
    final offset = _pointToOffset(point, chartArea, yRange, minDate, dateRange);

    // Draw larger selected circle
    final selectedPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(offset, selectedPointRadius, selectedPaint);
    canvas.drawCircle(offset, selectedPointRadius, strokePaint);

    // Draw vertical indicator line
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(offset.dx, chartArea.top),
      Offset(offset.dx, chartArea.bottom),
      linePaint,
    );

    // Draw tooltip
    _paintTooltip(canvas, offset, point, canvasSize);
  }

  void _paintTooltip(Canvas canvas, Offset anchor, ChartDataPoint point, Size canvasSize) {
    final dateStr = DateFormat('MMM d, y').format(point.date);
    final valueStr = _formatYValue(point.value);
    final text = point.label != null
        ? '${point.label}: $valueStr\n$dateStr'
        : '$valueStr\n$dateStr';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: 150);

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = textPainter.height + 12;

    // Position tooltip above point, clamped to canvas bounds
    var tooltipX = anchor.dx - tooltipWidth / 2;
    tooltipX = tooltipX.clamp(4.0, canvasSize.width - tooltipWidth - 4);
    final tooltipY = anchor.dy - tooltipHeight - 12;

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
      const Radius.circular(6),
    );

    // Shadow
    canvas.drawRRect(
      tooltipRect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Background
    canvas.drawRRect(
      tooltipRect,
      Paint()..color = const Color(0xFF333333),
    );

    textPainter.paint(
      canvas,
      Offset(tooltipX + 8, tooltipY + 6),
    );
  }

  Offset _pointToOffset(
    ChartDataPoint point,
    Rect chartArea,
    _YRange yRange,
    DateTime minDate,
    double dateRange,
  ) {
    final x = dateRange > 0
        ? chartArea.left + (point.date.difference(minDate).inMilliseconds / dateRange) * chartArea.width
        : chartArea.left + chartArea.width / 2;
    final y = yRange.range > 0
        ? chartArea.bottom - ((point.value - yRange.min) / yRange.range) * chartArea.height
        : chartArea.top + chartArea.height / 2;
    return Offset(x, y);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    const dashLength = 6.0;
    const gapLength = 4.0;

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final end = min(distance + length, metric.length);

        if (draw) {
          final extractedPath = metric.extractPath(distance, end);
          canvas.drawPath(extractedPath, paint);
        }
        distance = end;
        draw = !draw;
      }
    }
  }

  String _formatYValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  _YRange _computeNiceRange(double minVal, double maxVal) {
    if (minVal == maxVal) {
      // Single value: create a range around it
      final padding = maxVal == 0 ? 1.0 : maxVal * 0.1;
      return _YRange(min: minVal - padding, max: maxVal + padding);
    }

    final range = maxVal - minVal;
    final padding = range * 0.1;
    return _YRange(min: minVal - padding, max: maxVal + padding);
  }

  /// Returns the index of the data point closest to the given local position.
  /// Used by the widget to determine which point was tapped.
  static int? findClosestPoint(
    Offset localPosition,
    List<ChartDataPoint> data,
    Size size, {
    double hitRadius = 24.0,
  }) {
    if (data.isEmpty) return null;

    final chartArea = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    final allValues = data.map((d) => d.value);
    final minY = allValues.reduce(min);
    final maxY = allValues.reduce(max);
    final yRange = _YRange._compute(minY, maxY);

    final minDate = data.map((d) => d.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = data.map((d) => d.date).reduce((a, b) => a.isAfter(b) ? a : b);
    final dateRange = maxDate.difference(minDate).inMilliseconds.toDouble();

    int? closestIndex;
    double closestDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = dateRange > 0
          ? chartArea.left + (point.date.difference(minDate).inMilliseconds / dateRange) * chartArea.width
          : chartArea.left + chartArea.width / 2;
      final y = yRange.range > 0
          ? chartArea.bottom - ((point.value - yRange.min) / yRange.range) * chartArea.height
          : chartArea.top + chartArea.height / 2;

      final distance = (Offset(x, y) - localPosition).distance;
      if (distance < hitRadius && distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        secondaryData != oldDelegate.secondaryData ||
        selectedIndex != oldDelegate.selectedIndex ||
        primaryColor != oldDelegate.primaryColor ||
        secondaryColor != oldDelegate.secondaryColor;
  }
}

class _YRange {
  final double min;
  final double max;

  const _YRange({required this.min, required this.max});

  double get range => max - min;

  static _YRange _compute(double minVal, double maxVal) {
    if (minVal == maxVal) {
      final padding = maxVal == 0 ? 1.0 : maxVal * 0.1;
      return _YRange(min: minVal - padding, max: maxVal + padding);
    }
    final range = maxVal - minVal;
    final padding = range * 0.1;
    return _YRange(min: minVal - padding, max: maxVal + padding);
  }
}
