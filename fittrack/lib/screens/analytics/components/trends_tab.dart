import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/exercise_library_provider.dart';
import '../../../providers/program_provider.dart';
import '../../../widgets/charts/time_range_selector.dart';
import 'muscle_group_section.dart';
import 'streak_section.dart';
import 'training_trends_section.dart';

/// Trends tab showing streak, muscle group volume, and weekly trends.
///
/// Lazy-loads data on first visit. Displays three sections:
/// 1. Configurable streak
/// 2. Muscle group volume bar chart
/// 3. Weekly training trends line charts (volume + frequency)
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
    final exerciseLibrary = context.read<ExerciseLibraryProvider>();
    final dateRange = _selectedTimeRange.toDateRange();

    await Future.wait([
      provider.loadWeeklyTrends(dateRange: dateRange),
      provider.loadMuscleGroupVolume(
        dateRange: dateRange,
        libraryExercises: exerciseLibrary.libraryExercises,
        customExercises: exerciseLibrary.customExercises,
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
                StreakSection(
                  streak: provider.configurableStreak,
                  weeklyTarget: provider.weeklyWorkoutTarget,
                  onTargetChanged: (value) {
                    provider.setWeeklyWorkoutTarget(value);
                  },
                  isLoading: _loading,
                ),
                const SizedBox(height: 16),

                // Muscle group volume section
                MuscleGroupSection(
                  volumeData: provider.muscleGroupVolume,
                  isLoading: _loading,
                ),
                const SizedBox(height: 16),

                // Weekly trends section (volume + frequency)
                TrainingTrendsSection(
                  trendsData: provider.weeklyTrends,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

}
