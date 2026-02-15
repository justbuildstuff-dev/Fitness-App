import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/custom_exercise.dart';
import '../../../models/library_exercise.dart';
import '../../../models/muscle_group.dart';
import '../../../providers/program_provider.dart';
import '../../../widgets/charts/bar_chart_widget.dart';
import '../../../widgets/charts/chart_data.dart';
import '../../../widgets/charts/line_chart_widget.dart';
import '../../../widgets/charts/time_range_selector.dart';

/// Trends tab showing streak, muscle group volume, and weekly trends.
///
/// Lazy-loads data on first visit. Displays three sections:
/// 1. Configurable streak
/// 2. Muscle group volume bar chart
/// 3. Weekly training trends line chart
class TrendsTab extends StatefulWidget {
  const TrendsTab({super.key});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loaded = false;
  bool _loading = false;
  TimeRange _selectedTimeRange = TimeRange.threeMonths;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && !_loading) {
      _loadTrendsData();
    }
  }

  Future<void> _loadTrendsData() async {
    setState(() => _loading = true);
    final provider = context.read<ProgramProvider>();
    final dateRange = _selectedTimeRange.toDateRange();

    await Future.wait([
      provider.loadWeeklyTrends(dateRange: dateRange),
      provider.loadMuscleGroupVolume(
        dateRange: dateRange,
        libraryExercises: const <LibraryExercise>[],
        customExercises: const <CustomExercise>[],
      ),
    ]);

    if (mounted) {
      setState(() {
        _loaded = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshAnalytics();
            await _loadTrendsData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time range selector
                TimeRangeSelector(
                  selected: _selectedTimeRange,
                  onChanged: (range) {
                    setState(() {
                      _selectedTimeRange = range;
                      _loading = true;
                    });
                    _loadTrendsData();
                  },
                ),
                const SizedBox(height: 24),

                // Streak section
                _buildStreakSection(context, provider),
                const SizedBox(height: 24),

                // Muscle group volume section
                _buildMuscleGroupSection(context, provider),
                const SizedBox(height: 24),

                // Weekly trends section
                _buildWeeklyTrendsSection(context, provider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakSection(BuildContext context, ProgramProvider provider) {
    final streak = provider.configurableStreak;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Workout Streak', style: textTheme.titleMedium),
                // Weekly target selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Target: ', style: textTheme.bodySmall),
                    DropdownButton<int>(
                      value: provider.weeklyWorkoutTarget,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      items: List.generate(7, (i) => i + 1)
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text('$n/wk'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          provider.setWeeklyWorkoutTarget(value);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (streak != null) ...[
              Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: colorScheme.primary, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    streak.currentStreakString,
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Longest: ${streak.longestStreakString}',
                style: textTheme.bodySmall,
              ),
            ] else if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Text('No streak data', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupSection(
      BuildContext context, ProgramProvider provider) {
    final volumeData = provider.muscleGroupVolume;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muscle Group Volume', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (volumeData == null || volumeData.isEmpty)
              Text('No volume data for this period',
                  style: textTheme.bodyMedium)
            else
              BarChartWidget(
                entries: volumeData
                    .map((v) => BarChartEntry(
                          label: v.label,
                          value: v.totalSets.toDouble(),
                          percentage: v.percentage,
                          color: _colorForMuscleGroup(v.muscleGroup, colorScheme),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendsSection(
      BuildContext context, ProgramProvider provider) {
    final trendsData = provider.weeklyTrends;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Training Volume', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (trendsData == null || trendsData.isEmpty)
              Text('No training data for this period',
                  style: textTheme.bodyMedium)
            else
              LineChartWidget(
                data: trendsData
                    .map((w) => ChartDataPoint(
                          date: w.weekStart,
                          value: w.totalVolume,
                          label: '${w.workoutCount} workouts',
                        ))
                    .toList(),
                primaryLabel: 'Volume (kg)',
                emptyMessage: 'No training data',
              ),
          ],
        ),
      ),
    );
  }

  Color _colorForMuscleGroup(MuscleGroup? muscleGroup, ColorScheme colorScheme) {
    if (muscleGroup == null) return colorScheme.surfaceContainerHighest;
    switch (muscleGroup) {
      case MuscleGroup.chest:
        return colorScheme.primary;
      case MuscleGroup.back:
        return colorScheme.secondary;
      case MuscleGroup.shoulders:
        return colorScheme.tertiary;
      case MuscleGroup.arms:
        return colorScheme.primaryContainer;
      case MuscleGroup.legs:
        return colorScheme.error;
      case MuscleGroup.core:
        return colorScheme.tertiaryContainer;
    }
  }
}
