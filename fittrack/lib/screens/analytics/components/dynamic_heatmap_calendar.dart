import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/analytics.dart';

/// Dynamic heatmap calendar that adapts layout based on timeframe
class DynamicHeatmapCalendar extends StatelessWidget {
  final ActivityHeatmapData data;
  final HeatmapLayoutConfig config;

  const DynamicHeatmapCalendar({
    super.key,
    required this.data,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels (only for year view)
        if (config.showMonthLabels) _buildMonthLabels(context),

        // Heatmap grid
        if (config.enableVerticalScroll)
          Expanded(child: _buildScrollableGrid(context))
        else
          _buildStaticGrid(context),

        const SizedBox(height: 8),

        // Legend
        _buildLegend(context),
      ],
    );
  }

  Widget _buildMonthLabels(BuildContext context) {
    // GitHub-style month labels across the top
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          const SizedBox(width: 30), // Space for day labels
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(12, (index) {
                    return Text(
                      DateFormat('MMM').format(DateTime(config.startDate.year, index + 1)),
                      style: Theme.of(context).textTheme.labelSmall,
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableGrid(BuildContext context) {
    // For year view with vertical scrolling
    final weeks = _generateWeeksData();
    final currentWeekIndex = _getCurrentWeekIndex(weeks);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        _buildDayLabels(context),

        // Scrollable heatmap
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: weeks.asMap().entries.map((entry) {
                final index = entry.key;
                final week = entry.value;
                final isCurrentWeek = index == currentWeekIndex;

                return Container(
                  decoration: isCurrentWeek
                      ? BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: _buildWeekRow(context, week),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticGrid(BuildContext context) {
    // For week, month, and 30-day views (no scrolling)
    final weeks = _generateWeeksData();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        _buildDayLabels(context),

        // Static heatmap grid
        Expanded(
          child: Column(
            children: weeks.map((week) => _buildWeekRow(context, week)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabels(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            .map((day) => SizedBox(
                  height: 18, // Match cell height
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildWeekRow(BuildContext context, List<HeatmapDay?> week) {
    return Row(
      children: week.map((day) {
        if (day == null) {
          // Empty cell for partial weeks
          return Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.all(1),
          );
        }

        return Container(
          margin: const EdgeInsets.all(1),
          child: HeatmapSquare(
            day: day,
            onTap: () => _showDayPopup(context, day),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 4),
        ...HeatmapIntensity.values.map((intensity) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForIntensity(context, intensity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
        const SizedBox(width: 4),
        Text('More', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  List<List<HeatmapDay?>> _generateWeeksData() {
    final weeks = <List<HeatmapDay?>>[];
    DateTime currentDate = config.startDate;

    while (currentDate.isBefore(config.endDate.add(const Duration(days: 1)))) {
      final week = <HeatmapDay?>[];

      // Find Monday of current week
      final monday = currentDate.subtract(Duration(days: currentDate.weekday - 1));

      // Generate 7 days for the week
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));

        // Only include date if within range
        if (date.isAfter(config.startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(config.endDate.add(const Duration(days: 1)))) {
          final setCount = data.getSetCountForDate(date);
          final intensity = HeatmapIntensity.fromSetCount(setCount);

          week.add(HeatmapDay(
            date: date,
            workoutCount: setCount, // Using workoutCount field for set count
            intensity: intensity,
          ));
        } else {
          week.add(null); // Empty cell
        }
      }

      weeks.add(week);
      currentDate = monday.add(const Duration(days: 7));
    }

    return weeks;
  }

  int? _getCurrentWeekIndex(List<List<HeatmapDay?>> weeks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < weeks.length; i++) {
      for (final day in weeks[i]) {
        if (day != null && day.date.isAtSameMomentAs(today)) {
          return i;
        }
      }
    }
    return null;
  }

  void _showDayPopup(BuildContext context, HeatmapDay day) {
    if (day.workoutCount == 0) return;

    // Show a simple dialog overlay
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _DayDetailPopup(day: day),
    );
  }

  Color _getColorForIntensity(BuildContext context, HeatmapIntensity intensity) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get theme color (will use color scheme from Issue #44 when available)
    final baseColor = colorScheme.primary;

    switch (intensity) {
      case HeatmapIntensity.none:
        return colorScheme.surfaceContainerHighest;
      case HeatmapIntensity.low:
        return baseColor.withOpacity(0.2);
      case HeatmapIntensity.medium:
        return baseColor.withOpacity(0.4);
      case HeatmapIntensity.high:
        return baseColor.withOpacity(0.7);
      case HeatmapIntensity.veryHigh:
        return baseColor;
    }
  }
}

/// Individual heatmap square cell
class HeatmapSquare extends StatelessWidget {
  final HeatmapDay day;
  final VoidCallback onTap;

  const HeatmapSquare({
    super.key,
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.primary;

    final cellColor = _getColorForIntensity(context, day.intensity, baseColor, colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: '${day.workoutCount} set${day.workoutCount == 1 ? '' : 's'}',
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForIntensity(
    BuildContext context,
    HeatmapIntensity intensity,
    Color baseColor,
    ColorScheme colorScheme,
  ) {
    switch (intensity) {
      case HeatmapIntensity.none:
        return colorScheme.surfaceContainerHighest;
      case HeatmapIntensity.low:
        return baseColor.withOpacity(0.2);
      case HeatmapIntensity.medium:
        return baseColor.withOpacity(0.4);
      case HeatmapIntensity.high:
        return baseColor.withOpacity(0.7);
      case HeatmapIntensity.veryHigh:
        return baseColor;
    }
  }
}

/// Popup overlay showing day details
class _DayDetailPopup extends StatelessWidget {
  final HeatmapDay day;

  const _DayDetailPopup({
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(day.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.workoutCount} set${day.workoutCount == 1 ? '' : 's'} completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
