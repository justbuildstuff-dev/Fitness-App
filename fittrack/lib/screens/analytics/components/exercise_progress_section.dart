import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../../../models/exercise.dart';
import '../../../widgets/charts/chart_data.dart';
import '../../../widgets/charts/line_chart_widget.dart';
import '../../../widgets/charts/time_range_selector.dart';

/// Displays a per-exercise progress chart with time range selector.
///
/// Shows different metrics based on exercise type:
/// - Strength: Max Weight (primary) + Est. 1RM (secondary dashed)
/// - Bodyweight: Max Reps
/// - Cardio/Time-based: Duration
/// - Custom: Volume (weight * reps)
class ExerciseProgressSection extends StatelessWidget {
  final ExerciseProgressData? progressData;
  final TimeRange selectedTimeRange;
  final ValueChanged<TimeRange> onTimeRangeChanged;
  final bool isLoading;

  const ExerciseProgressSection({
    super.key,
    required this.progressData,
    required this.selectedTimeRange,
    required this.onTimeRangeChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Time range selector
        TimeRangeSelector(
          selected: selectedTimeRange,
          onChanged: onTimeRangeChanged,
        ),
        const SizedBox(height: 16),

        // Chart content
        _buildChartContent(context),
      ],
    );
  }

  Widget _buildChartContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (progressData == null) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Select an exercise to see progress',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (progressData!.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No data for this exercise in the selected time range',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isStrength =
        progressData!.exerciseType == ExerciseType.strength;

    // Build primary data points
    final primaryData = _buildPrimaryData();

    // Build secondary data points (est. 1RM for strength)
    final secondaryData = isStrength ? _buildSecondaryData() : null;

    // Determine labels based on exercise type
    final labels = _labelsForType(progressData!.exerciseType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Metric label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            labels.metricDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        LineChartWidget(
          data: primaryData,
          secondaryData: secondaryData,
          primaryLabel: labels.primary,
          secondaryLabel: labels.secondary,
          yAxisLabel: labels.yAxis,
          emptyMessage: 'No data available',
        ),
      ],
    );
  }

  List<ChartDataPoint> _buildPrimaryData() {
    return progressData!.dataPoints.map((point) {
      double value;
      switch (progressData!.exerciseType) {
        case ExerciseType.strength:
          value = point.maxWeight ?? 0;
        case ExerciseType.bodyweight:
          value = point.maxReps?.toDouble() ?? 0;
        case ExerciseType.cardio:
        case ExerciseType.timeBased:
          value = point.totalDuration?.toDouble() ?? 0;
        case ExerciseType.custom:
          // Volume = weight * reps (best approximation)
          value = (point.maxWeight ?? 0) * (point.maxReps ?? 1);
      }
      return ChartDataPoint(date: point.date, value: value);
    }).toList();
  }

  List<ChartDataPoint>? _buildSecondaryData() {
    final points = progressData!.dataPoints
        .where((p) => p.estimated1RM != null)
        .map((p) => ChartDataPoint(date: p.date, value: p.estimated1RM!))
        .toList();
    return points.isNotEmpty ? points : null;
  }

  static _ChartLabels _labelsForType(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return const _ChartLabels(
          primary: 'Weight',
          secondary: 'Est. 1RM',
          yAxis: 'kg',
          metricDescription: 'Showing max weight per session',
        );
      case ExerciseType.bodyweight:
        return const _ChartLabels(
          primary: 'Reps',
          yAxis: 'reps',
          metricDescription: 'Showing max reps per session',
        );
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return const _ChartLabels(
          primary: 'Duration',
          yAxis: 'sec',
          metricDescription: 'Showing total duration per session',
        );
      case ExerciseType.custom:
        return const _ChartLabels(
          primary: 'Volume',
          yAxis: 'vol',
          metricDescription: 'Showing estimated volume per session',
        );
    }
  }
}

class _ChartLabels {
  final String primary;
  final String? secondary;
  final String? yAxis;
  final String metricDescription;

  const _ChartLabels({
    required this.primary,
    this.secondary,
    this.yAxis,
    required this.metricDescription,
  });
}
