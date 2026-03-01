import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/analytics.dart';
import '../../../providers/weight_unit_provider.dart';
import '../../../widgets/charts/chart_data.dart';
import '../../../widgets/charts/line_chart_widget.dart';

/// Displays weekly training trends: total volume and workout frequency.
///
/// Shows two stacked line charts with optional 4-week moving average overlay.
class TrainingTrendsSection extends StatelessWidget {
  final List<WeeklyTrendPoint>? trendsData;
  final bool isLoading;

  const TrainingTrendsSection({
    super.key,
    required this.trendsData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weekly Volume chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Training Volume', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildVolumeChart(context),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weekly Frequency chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Workout Frequency', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                _buildFrequencyChart(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeChart(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (trendsData == null || trendsData!.isEmpty) {
      return Text(
        'Complete some workouts to see training trends',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final primaryData = trendsData!
        .map((w) => ChartDataPoint(
              date: w.weekStart,
              value: w.totalVolume,
              label: '${w.workoutCount} workouts',
            ))
        .toList();

    // 4-week moving average
    final movingAvgData = _computeMovingAverage(
      trendsData!.map((w) => w.totalVolume).toList(),
      trendsData!.map((w) => w.weekStart).toList(),
    );

    return LineChartWidget(
      data: primaryData,
      secondaryData: movingAvgData,
      primaryLabel: 'Volume',
      secondaryLabel: movingAvgData != null ? '4-wk avg' : null,
      yAxisLabel: context.watch<WeightUnitProvider>().label,
      emptyMessage: 'No training data',
    );
  }

  Widget _buildFrequencyChart(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (trendsData == null || trendsData!.isEmpty) {
      return Text(
        'Complete some workouts to see frequency trends',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final primaryData = trendsData!
        .map((w) => ChartDataPoint(
              date: w.weekStart,
              value: w.workoutCount.toDouble(),
            ))
        .toList();

    // 4-week moving average
    final movingAvgData = _computeMovingAverage(
      trendsData!.map((w) => w.workoutCount.toDouble()).toList(),
      trendsData!.map((w) => w.weekStart).toList(),
    );

    return LineChartWidget(
      data: primaryData,
      secondaryData: movingAvgData,
      primaryLabel: 'Workouts',
      secondaryLabel: movingAvgData != null ? '4-wk avg' : null,
      yAxisLabel: 'count',
      emptyMessage: 'No frequency data',
    );
  }

  /// Computes a 4-week moving average. Returns null if fewer than 4 points.
  static List<ChartDataPoint>? _computeMovingAverage(
    List<double> values,
    List<DateTime> dates,
  ) {
    if (values.length < 4) return null;

    final result = <ChartDataPoint>[];
    for (int i = 3; i < values.length; i++) {
      final avg = (values[i] + values[i - 1] + values[i - 2] + values[i - 3]) / 4;
      result.add(ChartDataPoint(date: dates[i], value: avg));
    }
    return result.isNotEmpty ? result : null;
  }
}
