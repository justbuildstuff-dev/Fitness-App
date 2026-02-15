import 'package:flutter/material.dart';

import '../../../models/analytics.dart';

/// Streak section displaying configurable weekly workout streak.
///
/// Shows current streak with flame icon, longest streak, and a gear
/// icon that opens a bottom sheet for setting the weekly target (1-7).
class StreakSection extends StatelessWidget {
  final ConfigurableStreak? streak;
  final int weeklyTarget;
  final ValueChanged<int> onTargetChanged;
  final bool isLoading;

  const StreakSection({
    super.key,
    required this.streak,
    required this.weeklyTarget,
    required this.onTargetChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Target: $weeklyTarget/wk',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 20),
                      onPressed: () => _showTargetBottomSheet(context),
                      tooltip: 'Set weekly target',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (streak != null) ...[
              Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: colorScheme.primary, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    streak!.currentStreakString,
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Longest: ${streak!.longestStreakString}',
                style: textTheme.bodySmall,
              ),
            ] else
              Text('No streak data', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showTargetBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return _TargetPickerSheet(
          currentTarget: weeklyTarget,
          onTargetChanged: (value) {
            onTargetChanged(value);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

/// Bottom sheet for selecting weekly workout target (1-7).
class _TargetPickerSheet extends StatefulWidget {
  final int currentTarget;
  final ValueChanged<int> onTargetChanged;

  const _TargetPickerSheet({
    required this.currentTarget,
    required this.onTargetChanged,
  });

  @override
  State<_TargetPickerSheet> createState() => _TargetPickerSheetState();
}

class _TargetPickerSheetState extends State<_TargetPickerSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentTarget;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weekly Workout Target',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Streak counts consecutive weeks where you meet this target',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(7, (i) {
              final value = i + 1;
              final isSelected = value == _selected;
              return ChoiceChip(
                label: Text('$value'),
                selected: isSelected,
                onSelected: (_) => setState(() => _selected = value),
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$_selected workout${_selected == 1 ? '' : 's'} per week',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => widget.onTargetChanged(_selected),
            child: const Text('Save'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
