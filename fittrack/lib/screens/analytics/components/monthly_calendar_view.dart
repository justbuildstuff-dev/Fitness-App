import 'package:flutter/material.dart';
import '../../../models/analytics.dart';

/// A single month's calendar grid for the habit tracker
///
/// Displays a monthly calendar with:
/// - 7 columns (Mon-Sun, ISO 8601 week start)
/// - 5-6 rows (weeks)
/// - Heatmap intensity colors for current month days
/// - Grayed-out adjacent month days
/// - Current day indicator
/// - Tappable cells to show set count
class MonthlyCalendarView extends StatelessWidget {
  final MonthHeatmapData data;
  final DateTime displayMonth; // Year + month being displayed
  final Function(DateTime)? onDayTapped;

  const MonthlyCalendarView({
    super.key,
    required this.data,
    required this.displayMonth,
    this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDayLabels(context),
        const SizedBox(height: 8),
        _buildCalendarGrid(context),
      ],
    );
  }

  /// Build day labels (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
  Widget _buildDayLabels(BuildContext context) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dayLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build the calendar grid (5-6 weeks × 7 days)
  Widget _buildCalendarGrid(BuildContext context) {
    final weeks = _generateWeeksData();

    return Column(
      children: weeks.map((week) {
        return _buildWeekRow(context, week);
      }).toList(),
    );
  }

  /// Build a single week row (7 cells)
  Widget _buildWeekRow(BuildContext context, List<_DayCell> week) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: week.map((dayCell) {
        return _buildDayCell(context, dayCell);
      }).toList(),
    );
  }

  /// Build a single day cell
  Widget _buildDayCell(BuildContext context, _DayCell dayCell) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = _calculateCellSize(screenWidth);

    final isCurrentMonth = dayCell.date.year == displayMonth.year &&
                           dayCell.date.month == displayMonth.month;

    final isToday = _isToday(dayCell.date);

    final setCount = isCurrentMonth ? data.getSetCountForDay(dayCell.date.day) : 0;
    final intensity = isCurrentMonth ? data.getIntensityForDay(dayCell.date.day) : HeatmapIntensity.none;

    final backgroundColor = isCurrentMonth
        ? _getColorForIntensity(context, intensity)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.1);

    final textColor = isCurrentMonth
        ? (intensity == HeatmapIntensity.none
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
            : Theme.of(context).colorScheme.onPrimary)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3);

    return Expanded(
      child: GestureDetector(
        onTap: (isCurrentMonth && setCount > 0 && onDayTapped != null)
            ? () => onDayTapped!(dayCell.date)
            : null,
        child: Container(
          height: cellSize,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '${dayCell.date.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Calculate responsive cell size (square cells, 40-60px range)
  double _calculateCellSize(double screenWidth) {
    const padding = 32.0 + 16.0; // Card padding + margins
    const cellMargin = 4.0; // 2px margin on each side

    final availableWidth = screenWidth - padding - (cellMargin * 7);
    final calculatedSize = availableWidth / 7;

    // Clamp between 40 and 60 pixels
    return calculatedSize.clamp(40.0, 60.0);
  }

  /// Get color for intensity level
  Color _getColorForIntensity(BuildContext context, HeatmapIntensity intensity) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    switch (intensity) {
      case HeatmapIntensity.none:
        return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3);
      case HeatmapIntensity.low:
        return primaryColor.withOpacity(0.2);
      case HeatmapIntensity.medium:
        return primaryColor.withOpacity(0.4);
      case HeatmapIntensity.high:
        return primaryColor.withOpacity(0.7);
      case HeatmapIntensity.veryHigh:
        return primaryColor;
    }
  }

  /// Check if date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  /// Generate weeks data (5-6 weeks, 35-42 cells)
  ///
  /// Algorithm:
  /// 1. Find first day of month (e.g., Dec 1, 2024)
  /// 2. Find Monday of week containing first day
  /// 3. Generate 5-6 week rows from that Monday
  /// 4. Each cell knows its actual date (may be previous/next month)
  List<List<_DayCell>> _generateWeeksData() {
    // Get first day of display month
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);

    // Get Monday of the week containing the first day
    // DateTime.weekday: Monday=1, Tuesday=2, ..., Sunday=7
    final firstWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final daysFromMonday = firstWeekday - 1; // 0 for Monday, 6 for Sunday
    final startDate = firstDayOfMonth.subtract(Duration(days: daysFromMonday));

    // Determine how many weeks we need (5 or 6)
    // Get last day of month (handles December → January boundary)
    final lastDayOfMonth = displayMonth.month == 12
        ? DateTime(displayMonth.year, 12, 31)  // Dec 31
        : DateTime(displayMonth.year, displayMonth.month + 1, 0); // Last day via month+1, day 0
    final endDate = startDate.add(const Duration(days: 35)); // 5 weeks minimum

    // If last day of month is after 35-day mark, we need 6 weeks
    final needsSixWeeks = lastDayOfMonth.isAfter(endDate);
    final totalDays = needsSixWeeks ? 42 : 35;

    // Generate all cells
    final List<List<_DayCell>> weeks = [];
    DateTime currentDate = startDate;

    for (int week = 0; week < (totalDays ~/ 7); week++) {
      final List<_DayCell> weekCells = [];

      for (int day = 0; day < 7; day++) {
        weekCells.add(_DayCell(date: currentDate));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      weeks.add(weekCells);
    }

    return weeks;
  }
}

/// Internal helper class to represent a single day cell
class _DayCell {
  final DateTime date;

  const _DayCell({required this.date});
}
