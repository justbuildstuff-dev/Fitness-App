import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../../../models/muscle_group.dart';
import '../../../widgets/charts/bar_chart_widget.dart';
import '../../../widgets/charts/chart_data.dart';

/// Displays a horizontal bar chart of muscle group volume (sets per group).
///
/// Color-coded per muscle group with "Other" for unmatched exercises.
class MuscleGroupSection extends StatelessWidget {
  final List<MuscleGroupVolume>? volumeData;
  final bool isLoading;

  const MuscleGroupSection({
    super.key,
    required this.volumeData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Muscle Group Volume', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (volumeData == null || volumeData!.isEmpty)
              Text(
                'Complete some workouts to see muscle group breakdown',
                style: textTheme.bodyMedium,
              )
            else
              BarChartWidget(
                entries: volumeData!
                    .map((v) => BarChartEntry(
                          label: v.label,
                          value: v.totalSets.toDouble(),
                          percentage: v.percentage,
                          color: colorForMuscleGroup(v.muscleGroup),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Consistent color mapping for muscle groups.
  static Color colorForMuscleGroup(MuscleGroup? muscleGroup) {
    if (muscleGroup == null) return Colors.grey;
    switch (muscleGroup) {
      case MuscleGroup.chest:
        return Colors.red.shade400;
      case MuscleGroup.back:
        return Colors.blue.shade400;
      case MuscleGroup.shoulders:
        return Colors.orange.shade400;
      case MuscleGroup.arms:
        return Colors.purple.shade400;
      case MuscleGroup.legs:
        return Colors.green.shade400;
      case MuscleGroup.core:
        return Colors.teal.shade400;
    }
  }
}
