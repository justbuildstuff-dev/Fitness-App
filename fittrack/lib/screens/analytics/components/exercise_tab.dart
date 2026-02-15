import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/exercise.dart';
import '../../../providers/program_provider.dart';
import '../../../widgets/charts/line_chart_widget.dart';
import '../../../widgets/charts/chart_data.dart';
import '../../../widgets/charts/time_range_selector.dart';

/// Exercise tab showing per-exercise progress charts.
///
/// Lazy-loads logged exercises on first visit, then displays
/// a picker and line chart for the selected exercise.
class ExerciseTab extends StatefulWidget {
  const ExerciseTab({super.key});

  @override
  State<ExerciseTab> createState() => _ExerciseTabState();
}

class _ExerciseTabState extends State<ExerciseTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _loaded = false;
  bool _loading = false;
  List<({String exerciseId, String exerciseName, ExerciseType exerciseType})>
      _exercises = [];
  int? _selectedExerciseIndex;
  TimeRange _selectedTimeRange = TimeRange.threeMonths;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && !_loading) {
      _loadExercises();
    }
  }

  Future<void> _loadExercises() async {
    setState(() => _loading = true);
    final provider = context.read<ProgramProvider>();
    final exercises = await provider.getLoggedExercises();
    if (mounted) {
      setState(() {
        _exercises = exercises;
        _loaded = true;
        _loading = false;
        if (_exercises.isNotEmpty && _selectedExerciseIndex == null) {
          _selectedExerciseIndex = 0;
          _loadExerciseProgress();
        }
      });
    }
  }

  Future<void> _loadExerciseProgress() async {
    if (_selectedExerciseIndex == null || _selectedExerciseIndex! >= _exercises.length) return;

    final exercise = _exercises[_selectedExerciseIndex!];
    final provider = context.read<ProgramProvider>();
    await provider.loadExerciseProgress(
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      exerciseType: exercise.exerciseType,
      dateRange: _selectedTimeRange.toDateRange(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Exercises Logged',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to track exercise progress',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshAnalytics();
            await _loadExercises();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Exercise picker
                _buildExercisePicker(context),
                const SizedBox(height: 16),

                // Time range selector
                TimeRangeSelector(
                  selected: _selectedTimeRange,
                  onChanged: (range) {
                    setState(() => _selectedTimeRange = range);
                    _loadExerciseProgress();
                  },
                ),
                const SizedBox(height: 16),

                // Progress chart
                _buildProgressChart(provider),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercisePicker(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedExerciseIndex,
      decoration: const InputDecoration(
        labelText: 'Exercise',
        border: OutlineInputBorder(),
      ),
      items: List.generate(_exercises.length, (index) {
        final exercise = _exercises[index];
        return DropdownMenuItem(
          value: index,
          child: Text(exercise.exerciseName),
        );
      }),
      onChanged: (index) {
        setState(() => _selectedExerciseIndex = index);
        _loadExerciseProgress();
      },
    );
  }

  Widget _buildProgressChart(ProgramProvider provider) {
    final progressData = provider.exerciseProgress;

    if (progressData == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (progressData.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No data for this exercise in the selected time range',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isStrength =
        progressData.exerciseType == ExerciseType.strength;

    // Build primary data points (weight or reps or duration)
    final primaryData = progressData.dataPoints.map((point) {
      double value;
      if (point.maxWeight != null) {
        value = point.maxWeight!;
      } else if (point.maxReps != null) {
        value = point.maxReps!.toDouble();
      } else if (point.totalDuration != null) {
        value = point.totalDuration!.toDouble();
      } else {
        value = 0;
      }
      return ChartDataPoint(date: point.date, value: value);
    }).toList();

    // Build secondary data points (est. 1RM for strength)
    List<ChartDataPoint>? secondaryData;
    if (isStrength) {
      final points = progressData.dataPoints
          .where((p) => p.estimated1RM != null)
          .map((p) => ChartDataPoint(date: p.date, value: p.estimated1RM!))
          .toList();
      if (points.isNotEmpty) {
        secondaryData = points;
      }
    }

    return LineChartWidget(
      data: primaryData,
      secondaryData: secondaryData,
      primaryLabel: isStrength ? 'Weight' : 'Value',
      secondaryLabel: isStrength ? 'Est. 1RM' : null,
      emptyMessage: 'No data available',
    );
  }
}
