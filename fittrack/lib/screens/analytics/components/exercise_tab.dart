import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/program_provider.dart';
import '../../../widgets/charts/time_range_selector.dart';
import 'exercise_picker.dart';
import 'exercise_progress_section.dart';

/// Exercise tab showing per-exercise progress charts.
///
/// Lazy-loads logged exercises on first visit, then displays
/// a searchable picker and progress chart for the selected exercise.
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
  bool _loadingProgress = false;
  List<LoggedExercise> _exercises = [];
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
    if (_selectedExerciseIndex == null ||
        _selectedExerciseIndex! >= _exercises.length) return;

    setState(() => _loadingProgress = true);
    final exercise = _exercises[_selectedExerciseIndex!];
    final provider = context.read<ProgramProvider>();
    await provider.loadExerciseProgress(
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      exerciseType: exercise.exerciseType,
      dateRange: _selectedTimeRange.toDateRange(),
    );
    if (mounted) {
      setState(() => _loadingProgress = false);
    }
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
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
        return Column(
          children: [
            // Exercise picker (takes ~40% of available space)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ExercisePicker(
                  exercises: _exercises,
                  selectedIndex: _selectedExerciseIndex,
                  onSelected: (index) {
                    setState(() => _selectedExerciseIndex = index);
                    _loadExerciseProgress();
                  },
                ),
              ),
            ),
            const Divider(),
            // Progress chart section (takes ~60% of available space)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ExerciseProgressSection(
                  progressData: provider.exerciseProgress,
                  selectedTimeRange: _selectedTimeRange,
                  isLoading: _loadingProgress,
                  onTimeRangeChanged: (range) {
                    setState(() => _selectedTimeRange = range);
                    _loadExerciseProgress();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
