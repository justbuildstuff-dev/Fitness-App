import 'package:flutter/material.dart';
import '../../models/templates/templates.dart';

/// A bottom sheet that previews a workout template before selection.
class WorkoutTemplatePreviewSheet extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onUseTemplate;

  const WorkoutTemplatePreviewSheet({
    super.key,
    required this.template,
    required this.onUseTemplate,
  });

  /// Shows the preview sheet and returns true if the user selects "Use Template"
  static Future<bool> show(
    BuildContext context, {
    required WorkoutTemplate template,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WorkoutTemplatePreviewSheet(
        template: template,
        onUseTemplate: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Template name and badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TemplateBadge(isPrebuilt: template.isPrebuilt),
                ],
              ),

              // Description
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  template.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],

              const SizedBox(height: 16),

              // Stats row
              _StatsRow(
                items: [
                  _StatItem(
                    icon: Icons.fitness_center,
                    value: '${template.exerciseCount}',
                    label: template.exerciseCount == 1 ? 'Exercise' : 'Exercises',
                  ),
                  _StatItem(
                    icon: Icons.repeat,
                    value: '${template.totalSetCount}',
                    label: template.totalSetCount == 1 ? 'Set' : 'Sets',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Exercises section
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Exercise list
              ...template.exercises.map((exercise) => _ExercisePreviewTile(
                    name: exercise.name,
                    type: exercise.exerciseType.displayName,
                    setCount: exercise.setCount,
                  )),

              const SizedBox(height: 24),

              // Use Template button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUseTemplate,
                  icon: const Icon(Icons.check),
                  label: const Text('Use Template'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom sheet that previews a week template before selection.
class WeekTemplatePreviewSheet extends StatelessWidget {
  final WeekTemplate template;
  final VoidCallback onUseTemplate;

  const WeekTemplatePreviewSheet({
    super.key,
    required this.template,
    required this.onUseTemplate,
  });

  /// Shows the preview sheet and returns true if the user selects "Use Template"
  static Future<bool> show(
    BuildContext context, {
    required WeekTemplate template,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WeekTemplatePreviewSheet(
        template: template,
        onUseTemplate: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Template name and badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TemplateBadge(isPrebuilt: template.isPrebuilt),
                ],
              ),

              // Description
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  template.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],

              const SizedBox(height: 16),

              // Stats row
              _StatsRow(
                items: [
                  _StatItem(
                    icon: Icons.calendar_today,
                    value: '${template.workoutCount}',
                    label: template.workoutCount == 1 ? 'Workout' : 'Workouts',
                  ),
                  _StatItem(
                    icon: Icons.fitness_center,
                    value: '${template.totalExerciseCount}',
                    label: template.totalExerciseCount == 1
                        ? 'Exercise'
                        : 'Exercises',
                  ),
                  _StatItem(
                    icon: Icons.repeat,
                    value: '${template.totalSetCount}',
                    label: template.totalSetCount == 1 ? 'Set' : 'Sets',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Workouts section
              Text(
                'Workouts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Workout list
              ...template.workouts.map((workout) => _WorkoutPreviewTile(
                    name: workout.name,
                    dayOfWeek: workout.dayOfWeekDisplay,
                    exerciseCount: workout.exerciseCount,
                  )),

              const SizedBox(height: 24),

              // Use Template button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUseTemplate,
                  icon: const Icon(Icons.check),
                  label: const Text('Use Template'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bottom sheet that previews a program template before selection.
class ProgramTemplatePreviewSheet extends StatelessWidget {
  final ProgramTemplate template;
  final VoidCallback onUseTemplate;

  const ProgramTemplatePreviewSheet({
    super.key,
    required this.template,
    required this.onUseTemplate,
  });

  /// Shows the preview sheet and returns true if the user selects "Use Template"
  static Future<bool> show(
    BuildContext context, {
    required ProgramTemplate template,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProgramTemplatePreviewSheet(
        template: template,
        onUseTemplate: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Template name and badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TemplateBadge(isPrebuilt: template.isPrebuilt),
                ],
              ),

              // Description
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  template.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],

              const SizedBox(height: 16),

              // Stats row
              _StatsRow(
                items: [
                  _StatItem(
                    icon: Icons.date_range,
                    value: '${template.weekCount}',
                    label: template.weekCount == 1 ? 'Week' : 'Weeks',
                  ),
                  _StatItem(
                    icon: Icons.calendar_today,
                    value: '${template.totalWorkoutCount}',
                    label: template.totalWorkoutCount == 1
                        ? 'Workout'
                        : 'Workouts',
                  ),
                  _StatItem(
                    icon: Icons.fitness_center,
                    value: '${template.totalExerciseCount}',
                    label: template.totalExerciseCount == 1
                        ? 'Exercise'
                        : 'Exercises',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Weeks section
              Text(
                'Program Structure',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Week list
              ...template.weeks.map((week) => _WeekPreviewTile(
                    name: week.name,
                    workoutCount: week.workoutCount,
                    exerciseCount: week.totalExerciseCount,
                  )),

              const SizedBox(height: 24),

              // Use Template button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUseTemplate,
                  icon: const Icon(Icons.check),
                  label: const Text('Use Template'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Private helper widgets
// ============================================================================

/// Badge showing if template is pre-built or user-created
class _TemplateBadge extends StatelessWidget {
  final bool isPrebuilt;

  const _TemplateBadge({required this.isPrebuilt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrebuilt
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPrebuilt ? 'Pre-built' : 'My Template',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPrebuilt
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onTertiaryContainer,
            ),
      ),
    );
  }
}

/// A row showing template statistics
class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((item) => Expanded(
                  child: Column(
                    children: [
                      Icon(
                        item.icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Data for a single stat item
class _StatItem {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
}

/// Preview tile for an exercise in a workout template
class _ExercisePreviewTile extends StatelessWidget {
  final String name;
  final String type;
  final int setCount;

  const _ExercisePreviewTile({
    required this.name,
    required this.type,
    required this.setCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.fitness_center,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$type \u2022 $setCount ${setCount == 1 ? 'set' : 'sets'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview tile for a workout in a week template
class _WorkoutPreviewTile extends StatelessWidget {
  final String name;
  final String? dayOfWeek;
  final int exerciseCount;

  const _WorkoutPreviewTile({
    required this.name,
    this.dayOfWeek,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.calendar_today,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dayOfWeek != null
                      ? '$dayOfWeek \u2022 $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}'
                      : '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview tile for a week in a program template
class _WeekPreviewTile extends StatelessWidget {
  final String name;
  final int workoutCount;
  final int exerciseCount;

  const _WeekPreviewTile({
    required this.name,
    required this.workoutCount,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.date_range,
                size: 20,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$workoutCount ${workoutCount == 1 ? 'workout' : 'workouts'} \u2022 $exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
