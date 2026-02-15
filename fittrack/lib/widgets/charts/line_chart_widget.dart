import 'package:flutter/material.dart';

import 'chart_data.dart';
import 'line_chart_painter.dart';

/// A line chart widget with tap-to-select data points.
///
/// Wraps [LineChartPainter] with gesture detection, optional legend,
/// and accessibility semantics.
class LineChartWidget extends StatefulWidget {
  final List<ChartDataPoint> data;
  final List<ChartDataPoint>? secondaryData;
  final double height;
  final String? primaryLabel;
  final String? secondaryLabel;
  final String? emptyMessage;
  final String? yAxisLabel;

  const LineChartWidget({
    super.key,
    required this.data,
    this.secondaryData,
    this.height = 250,
    this.primaryLabel,
    this.secondaryLabel,
    this.emptyMessage,
    this.yAxisLabel,
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.tertiary;
    final gridColor = colorScheme.surfaceContainerHighest;
    final textColor = colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.secondaryData != null &&
            widget.primaryLabel != null &&
            widget.secondaryLabel != null)
          _buildLegend(context, primaryColor, secondaryColor),
        Semantics(
          label: _buildSemanticsLabel(),
          child: GestureDetector(
            onTapDown: (details) => _onTapDown(details, context),
            onTapUp: (_) {},
            child: SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: LineChartPainter(
                  data: widget.data,
                  secondaryData: widget.secondaryData,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                  gridColor: gridColor,
                  textColor: textColor,
                  selectedIndex: _selectedIndex,
                  emptyMessage: widget.emptyMessage,
                  yAxisLabel: widget.yAxisLabel,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, Color primaryColor, Color secondaryColor) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(primaryColor, widget.primaryLabel!, textTheme, false),
          const SizedBox(width: 24),
          _legendItem(secondaryColor, widget.secondaryLabel!, textTheme, true),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, TextTheme textTheme, bool dashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 3,
          child: CustomPaint(
            painter: _LegendLinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }

  void _onTapDown(TapDownDetails details, BuildContext context) {
    if (widget.data.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Adjust for legend height if present
    final hasLegend = widget.secondaryData != null &&
        widget.primaryLabel != null &&
        widget.secondaryLabel != null;

    final chartSize = Size(renderBox.size.width, widget.height);
    var localPosition = details.localPosition;

    // If legend is shown, subtract its approximate height
    if (hasLegend) {
      localPosition = Offset(localPosition.dx, localPosition.dy - 28);
    }

    final index = LineChartPainter.findClosestPoint(
      localPosition,
      widget.data,
      chartSize,
    );

    setState(() {
      _selectedIndex = index == _selectedIndex ? null : index;
    });
  }

  String _buildSemanticsLabel() {
    if (widget.data.isEmpty) {
      return widget.emptyMessage ?? 'Line chart with no data';
    }

    final count = widget.data.length;
    final label = widget.primaryLabel ?? 'Value';
    return 'Line chart showing $label with $count data points';
  }
}

/// Paints a short line segment for the legend (solid or dashed)
class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool dashed;

  _LegendLinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;

    if (dashed) {
      const dashWidth = 4.0;
      const gapWidth = 3.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dashWidth).clamp(0, size.width), y),
          paint,
        );
        x += dashWidth + gapWidth;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) {
    return color != oldDelegate.color || dashed != oldDelegate.dashed;
  }
}
