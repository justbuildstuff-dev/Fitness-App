import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/analytics.dart';

/// Activity heatmap section showing GitHub-style workout consistency visualization
class ActivityHeatmapSection extends StatelessWidget {
  final ActivityHeatmapData data;

  const ActivityHeatmapSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${data.year} Activity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${data.totalWorkouts} workouts',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Heatmap Calendar
              SizedBox(
                height: 200,
                child: HeatmapCalendar(data: data),
              ),
              
              const SizedBox(height: 16),
              
              // Streak information
              Row(
                children: [
                  Expanded(
                    child: _StreakCard(
                      title: 'Current Streak',
                      value: '${data.currentStreak} days',
                      icon: Icons.local_fire_department,
                      color: data.currentStreak > 0 
                          ? Colors.orange 
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StreakCard(
                      title: 'Longest Streak',
                      value: '${data.longestStreak} days',
                      icon: Icons.emoji_events,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Heatmap calendar widget displaying workout intensity
class HeatmapCalendar extends StatelessWidget {
  final ActivityHeatmapData data;

  const HeatmapCalendar({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final heatmapDays = data.getHeatmapDays();
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Group days by week
    final weeks = <List<HeatmapDay>>[];
    List<HeatmapDay> currentWeek = [];
    
    for (final day in heatmapDays) {
      currentWeek.add(day);
      
      // If it's Sunday or the last day, complete the week
      if (day.date.weekday == DateTime.sunday || day == heatmapDays.last) {
        // Fill the week to 7 days if needed
        while (currentWeek.length < 7) {
          final emptyDate = currentWeek.first.date.subtract(
            Duration(days: 7 - currentWeek.length),
          );
          currentWeek.insert(0, HeatmapDay(
            date: emptyDate,
            workoutCount: 0,
            intensity: HeatmapIntensity.none,
          ));
        }
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    return Column(
      children: [
        // Month labels
        SizedBox(
          height: 20,
          child: Row(
            children: [
              const SizedBox(width: 20), // Space for day labels
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(12, (index) {
                    return Text(
                      DateFormat('MMM').format(DateTime(currentYear, index + 1)),
                      style: Theme.of(context).textTheme.labelSmall,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Heatmap grid
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels (M, T, W, T, F, S, S)
              SizedBox(
                width: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((day) => Text(
                            day,
                            style: Theme.of(context).textTheme.labelSmall,
                          ))
                      .toList(),
                ),
              ),
              
              // Heatmap squares
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: weeks.map((week) => Column(
                      children: week.map((day) => Container(
                        margin: const EdgeInsets.all(1),
                        child: HeatmapSquare(
                          day: day,
                          onTap: () => _showDayDetails(context, day),
                        ),
                      )).toList(),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 4),
            ...HeatmapIntensity.values.map((intensity) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: HeatmapSquare(
                day: HeatmapDay(
                  date: DateTime.now(),
                  workoutCount: _getCountForIntensity(intensity),
                  intensity: intensity,
                ),
                size: 12,
              ),
            )),
            const SizedBox(width: 4),
            Text(
              'More',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  int _getCountForIntensity(HeatmapIntensity intensity) {
    switch (intensity) {
      case HeatmapIntensity.none:
        return 0;
      case HeatmapIntensity.low:
        return 1;
      case HeatmapIntensity.medium:
        return 2;
      case HeatmapIntensity.high:
        return 4;
    }
  }

  void _showDayDetails(BuildContext context, HeatmapDay day) {
    if (day.workoutCount == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('EEEE, MMM d, y').format(day.date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${day.workoutCount} workout${day.workoutCount == 1 ? '' : 's'} completed'),
            const SizedBox(height: 8),
            Text(
              day.intensity.displayName,
              style: TextStyle(
                color: _getColorForIntensity(day.intensity),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getColorForIntensity(HeatmapIntensity intensity) {
    switch (intensity) {
      case HeatmapIntensity.none:
        return Colors.grey[300]!;
      case HeatmapIntensity.low:
        return Colors.green[200]!;
      case HeatmapIntensity.medium:
        return Colors.green[400]!;
      case HeatmapIntensity.high:
        return Colors.green[700]!;
    }
  }
}

/// Individual heatmap square
class HeatmapSquare extends StatelessWidget {
  final HeatmapDay day;
  final VoidCallback? onTap;
  final double size;

  const HeatmapSquare({
    super.key,
    required this.day,
    this.onTap,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: '${day.workoutCount} workout${day.workoutCount == 1 ? '' : 's'} on ${DateFormat('MMM d').format(day.date)}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _getColorForIntensity(day.intensity),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForIntensity(HeatmapIntensity intensity) {
    switch (intensity) {
      case HeatmapIntensity.none:
        return Colors.grey[200]!;
      case HeatmapIntensity.low:
        return Colors.green[200]!;
      case HeatmapIntensity.medium:
        return Colors.green[400]!;
      case HeatmapIntensity.high:
        return Colors.green[700]!;
    }
  }
}

/// Streak information card
class _StreakCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StreakCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}