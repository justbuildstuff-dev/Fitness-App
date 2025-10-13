import 'package:flutter/material.dart';

/// Key statistics section displaying workout metrics in cards
class KeyStatisticsSection extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const KeyStatisticsSection({
    super.key,
    required this.statistics,
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
                'Key Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // First row of statistics
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Workouts',
                      value: '${statistics['totalWorkouts'] ?? 0}',
                      subtitle: 'Total',
                      icon: Icons.fitness_center,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Sets',
                      value: '${statistics['totalSets'] ?? 0}',
                      subtitle: 'Completed',
                      icon: Icons.format_list_numbered,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Second row of statistics
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Volume',
                      value: _formatVolume(statistics['totalVolume']),
                      subtitle: 'Total kg',
                      icon: Icons.fitness_center,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Avg Time',
                      value: _formatDuration(statistics['averageDuration']),
                      subtitle: 'Per workout',
                      icon: Icons.timer,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Third row of statistics
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'New PRs',
                      value: '${statistics['newPRs'] ?? 0}',
                      subtitle: 'This period',
                      icon: Icons.trending_up,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Most Used',
                      value: _truncateExerciseType(statistics['mostUsedExerciseType']),
                      subtitle: 'Exercise type',
                      icon: Icons.star,
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Fourth row of statistics
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Completion',
                      value: '${(statistics['completionPercentage'] ?? 0.0).toInt()}%',
                      subtitle: 'Sets completed',
                      icon: Icons.check_circle,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Frequency',
                      value: '${(statistics['workoutsPerWeek'] ?? 0.0).toStringAsFixed(1)}',
                      subtitle: 'Per week',
                      icon: Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
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

  String _formatVolume(dynamic volume) {
    if (volume == null || volume == 0) return '0';
    final vol = volume is double ? volume : double.tryParse(volume.toString()) ?? 0.0;
    
    if (vol >= 1000000) {
      return '${(vol / 1000000).toStringAsFixed(1)}M';
    } else if (vol >= 1000) {
      return '${(vol / 1000).toStringAsFixed(1)}k';
    } else {
      return vol.toStringAsFixed(0);
    }
  }

  String _formatDuration(dynamic duration) {
    if (duration == null || duration == 0) return '0m';
    final dur = duration is double ? duration : double.tryParse(duration.toString()) ?? 0.0;
    
    if (dur < 1) return '0m';
    
    final minutes = dur.floor();
    final seconds = ((dur - minutes) * 60).round();
    
    if (seconds > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${minutes}m';
    }
  }

  String _truncateExerciseType(dynamic exerciseType) {
    if (exerciseType == null) return 'None';
    final type = exerciseType.toString();
    
    // Truncate if too long for the card
    if (type.length > 10) {
      return '${type.substring(0, 7)}...';
    }
    return type;
  }
}

/// Individual statistic card
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Statistics overview widget for quick insights
class StatisticsOverview extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const StatisticsOverview({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final totalWorkouts = statistics['totalWorkouts'] ?? 0;
    final totalSets = statistics['totalSets'] ?? 0;
    final completionPercentage = (statistics['completionPercentage'] ?? 0.0);
    final workoutsPerWeek = (statistics['workoutsPerWeek'] ?? 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _OverviewItem(
                label: 'Workouts',
                value: totalWorkouts.toString(),
                color: Theme.of(context).colorScheme.primary,
              ),
              _OverviewItem(
                label: 'Sets',
                value: totalSets.toString(),
                color: Theme.of(context).colorScheme.tertiary,
              ),
              _OverviewItem(
                label: 'Completion',
                value: '${completionPercentage.toInt()}%',
                color: Theme.of(context).colorScheme.secondary,
              ),
              _OverviewItem(
                label: 'Per Week',
                value: workoutsPerWeek.toStringAsFixed(1),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}