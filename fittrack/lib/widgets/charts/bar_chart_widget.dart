import 'package:flutter/material.dart';

import 'bar_chart_painter.dart';
import 'chart_data.dart';

/// A horizontal bar chart widget with auto-sized height.
///
/// Wraps [BarChartPainter] with accessibility semantics.
class BarChartWidget extends StatelessWidget {
  final List<BarChartEntry> entries;
  final double? height;
  final String? emptyMessage;

  const BarChartWidget({
    super.key,
    required this.entries,
    this.height,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurfaceVariant;
    final chartHeight = height ?? BarChartPainter.computeHeight(entries.length);

    return Semantics(
      label: _buildSemanticsLabel(),
      child: SizedBox(
        height: chartHeight,
        child: CustomPaint(
          painter: BarChartPainter(
            entries: entries,
            textColor: textColor,
            emptyMessage: emptyMessage,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  String _buildSemanticsLabel() {
    if (entries.isEmpty) {
      return emptyMessage ?? 'Bar chart with no data';
    }

    final count = entries.length;
    final topEntry = entries.isNotEmpty ? entries.first.label : '';
    return 'Bar chart showing $count categories, top: $topEntry';
  }
}
