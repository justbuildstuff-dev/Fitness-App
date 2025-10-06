import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/analytics.dart';
import '../../../models/exercise.dart';

/// Charts section displaying detailed analytics visualizations
class ChartsSection extends StatelessWidget {
  final WorkoutAnalytics? analytics;
  final List<PersonalRecord> personalRecords;

  const ChartsSection({
    super.key,
    this.analytics,
    required this.personalRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Exercise type breakdown
              if (analytics != null && analytics!.exerciseTypeBreakdown.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercise Type Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExerciseTypeChart(data: analytics!.exerciseTypeBreakdown),
                    const SizedBox(height: 24),
                  ],
                ),
              
              // Personal records - always show this section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Personal Records',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (personalRecords.isNotEmpty)
                        Text(
                          '${personalRecords.length} PR${personalRecords.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PersonalRecordsList(records: personalRecords),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exercise type breakdown chart (simple bar/pie visualization)
class ExerciseTypeChart extends StatelessWidget {
  final Map<ExerciseType, int> data;

  const ExerciseTypeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No exercise data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    final total = data.values.fold(0, (sum, count) => sum + count);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 120,
      child: Column(
        children: [
          // Bar chart representation
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: sortedEntries.map((entry) {
                final percentage = entry.value / total;
                final color = _getColorForExerciseType(entry.key);
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar
                        Container(
                          height: 60 * percentage,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Label
                        Text(
                          entry.key.displayName.substring(0, 
                            entry.key.displayName.length > 8 ? 8 : entry.key.displayName.length),
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                        // Count
                        Text(
                          '${entry.value}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Legend with percentages
          Wrap(
            spacing: 16,
            children: sortedEntries.map((entry) {
              final percentage = (entry.value / total * 100).round();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForExerciseType(entry.key),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key.displayName} $percentage%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getColorForExerciseType(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return Colors.blue;
      case ExerciseType.cardio:
        return Colors.red;
      case ExerciseType.bodyweight:
        return Colors.green;
      case ExerciseType.timeBased:
        return Colors.orange;
      case ExerciseType.custom:
        return Colors.purple;
    }
  }
}

/// Personal records list widget
class PersonalRecordsList extends StatelessWidget {
  final List<PersonalRecord> records;

  const PersonalRecordsList({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'No Personal Records Yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Keep training to set new records!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: records.take(5).map((record) {
        return PersonalRecordTile(record: record);
      }).toList(),
    );
  }
}

/// Individual personal record tile
class PersonalRecordTile extends StatelessWidget {
  final PersonalRecord record;

  const PersonalRecordTile({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(record.achievedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // PR Type Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorForPRType(record.prType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForPRType(record.prType),
              color: _getColorForPRType(record.prType),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Exercise and PR details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      record.displayValue,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getColorForPRType(record.prType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (record.improvementString != 'New PR!')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.improvementString,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Time ago
          Text(
            timeAgo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return DateFormat('MMM d').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getColorForPRType(PRType prType) {
    switch (prType) {
      case PRType.maxWeight:
        return Colors.blue;
      case PRType.maxReps:
        return Colors.green;
      case PRType.maxDuration:
        return Colors.orange;
      case PRType.maxDistance:
        return Colors.purple;
      case PRType.maxVolume:
        return Colors.red;
      case PRType.oneRepMax:
        return Colors.amber;
    }
  }

  IconData _getIconForPRType(PRType prType) {
    switch (prType) {
      case PRType.maxWeight:
        return Icons.fitness_center;
      case PRType.maxReps:
        return Icons.repeat;
      case PRType.maxDuration:
        return Icons.timer;
      case PRType.maxDistance:
        return Icons.straighten;
      case PRType.maxVolume:
        return Icons.trending_up;
      case PRType.oneRepMax:
        return Icons.emoji_events;
    }
  }
}

/// Simple progress indicator for analytics loading
class AnalyticsLoadingIndicator extends StatelessWidget {
  const AnalyticsLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Computing analytics...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}