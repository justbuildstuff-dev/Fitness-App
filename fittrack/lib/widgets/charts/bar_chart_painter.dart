import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'chart_data.dart';

/// CustomPainter for rendering horizontal bar charts.
///
/// Displays bars with:
/// - Labels on the left (muscle group name, 100px column)
/// - Proportional bars in the middle
/// - Value labels on the right ("X sets (Y%)")
class BarChartPainter extends CustomPainter {
  final List<BarChartEntry> entries;
  final Color textColor;
  final String? emptyMessage;

  static const double labelWidth = 100.0;
  static const double valueWidth = 80.0;
  static const double barHeight = 28.0;
  static const double barGap = 8.0;
  static const double barRadius = 4.0;

  BarChartPainter({
    required this.entries,
    required this.textColor,
    this.emptyMessage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    final barAreaWidth = size.width - labelWidth - valueWidth - 8;
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final y = i * (barHeight + barGap);

      // Draw label on the left
      _drawLabel(canvas, entry.label, y, size);

      // Draw bar
      final barWidth = maxValue > 0
          ? (entry.value / maxValue) * barAreaWidth
          : 0.0;

      if (barWidth > 0) {
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(labelWidth + 4, y + 2, barWidth, barHeight - 4),
          const Radius.circular(barRadius),
        );
        canvas.drawRRect(barRect, Paint()..color = entry.color);
      }

      // Draw value label on the right
      _drawValueLabel(canvas, entry, y, size);
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

  void _drawLabel(Canvas canvas, String label, double y, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: labelWidth - 4);
    textPainter.paint(
      canvas,
      Offset(0, y + (barHeight - textPainter.height) / 2),
    );
  }

  void _drawValueLabel(Canvas canvas, BarChartEntry entry, double y, Size size) {
    final setsText = entry.value == 1 ? 'set' : 'sets';
    final label = '${entry.value.toInt()} $setsText (${entry.percentage.toStringAsFixed(0)}%)';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: textColor, fontSize: 11),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    textPainter.layout(maxWidth: valueWidth);
    textPainter.paint(
      canvas,
      Offset(size.width - valueWidth, y + (barHeight - textPainter.height) / 2),
    );
  }

  /// Computes the ideal height based on entry count
  static double computeHeight(int entryCount) {
    if (entryCount == 0) return 60;
    return entryCount * (barHeight + barGap) - barGap;
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return entries != oldDelegate.entries ||
        textColor != oldDelegate.textColor;
  }
}
