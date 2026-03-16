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
  // Tracks whether the exercise library was ready when we last fetched muscle
  // group volume. If the library finishes loading after our initial fetch, we
  // need to re-fetch so exercise names can be resolved to muscle groups.
  bool _libraryReadyOnLastLoad = false;
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

    _libraryReadyOnLastLoad = exerciseLibrary.isLibraryLoaded;

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

    return Consumer2<ProgramProvider, ExerciseLibraryProvider>(
      builder: (context, provider, exerciseLibrary, child) {
        // If the exercise library finished loading after our initial data fetch,
        // the muscle group volume will have been computed with an empty library
        // (all sets bucketed as "Other"). Re-fetch now that names are resolvable.
        if (_loaded && !_loading && exerciseLibrary.isLibraryLoaded && !_libraryReadyOnLastLoad) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_loading) {
              // Clear the stale cache entry (computed with empty library) before
              // re-fetching so muscle groups are resolved correctly.
              context.read<ProgramProvider>().clearAnalyticsCache();
              _loadTrendsData();
            }
          });
        }

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
