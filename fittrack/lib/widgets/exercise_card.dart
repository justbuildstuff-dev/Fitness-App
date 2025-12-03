import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import 'set_row.dart';

/// A collapsible card that displays an exercise and its sets
/// Supports drag-and-drop reordering, adding sets, editing exercise name, and deleting
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final List<ExerciseSet> sets;
  final bool isReorderEnabled;
  final VoidCallback? onAddSet;
  final VoidCallback? onEditName;
  final VoidCallback? onDelete;
  final Function(ExerciseSet updatedSet) onUpdateSet;
  final Function(String exerciseId, String setId) onDeleteSet;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sets,
    this.isReorderEnabled = true,
    this.onAddSet,
    this.onEditName,
    this.onDelete,
    required this.onUpdateSet,
    required this.onDeleteSet,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _isExpanded = true; // Start expanded by default

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddSet = widget.sets.length < 10; // Max 10 sets per exercise

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Drag handle (if reordering enabled)
                  if (widget.isReorderEnabled) ...[
                    Icon(
                      Icons.drag_handle,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Exercise type icon
                  Icon(
                    _getExerciseTypeIcon(widget.exercise.exerciseType),
                    color: _getExerciseTypeColor(widget.exercise.exerciseType),
                    size: 20,
                  ),
                  const SizedBox(width: 12),

                  // Exercise name and set count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.sets.length} ${widget.sets.length == 1 ? 'set' : 'sets'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add Set button
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: canAddSet ? widget.onAddSet : null,
                    tooltip: canAddSet
                        ? 'Add set'
                        : 'Maximum 10 sets per exercise',
                    color: theme.colorScheme.primary,
                  ),

                  // 3-dot menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          widget.onEditName?.call();
                          break;
                        case 'delete':
                          widget.onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Name'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Exercise'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  // Expand/collapse indicator
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          // Sets list (collapsible)
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Set rows
                  ...widget.sets.asMap().entries.map((entry) {
                    final set = entry.value;
                    final isLastSet = widget.sets.length == 1;

                    return SetRow(
                      key: ValueKey(set.id),
                      set: set,
                      exerciseType: widget.exercise.exerciseType,
                      isLastSet: isLastSet,
                      onUpdate: widget.onUpdateSet,
                      onDelete: isLastSet
                          ? null
                          : () => widget.onDeleteSet(widget.exercise.id, set.id),
                    );
                  }),

                  // Empty state if no sets
                  if (widget.sets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No sets yet. Add your first set!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getExerciseTypeColor(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return Colors.blue;
      case ExerciseType.cardio:
        return Colors.red;
      case ExerciseType.timeBased:
        return Colors.orange;
      case ExerciseType.bodyweight:
        return Colors.green;
      case ExerciseType.custom:
        return Colors.purple;
    }
  }

  IconData _getExerciseTypeIcon(ExerciseType type) {
    switch (type) {
      case ExerciseType.strength:
        return Icons.fitness_center;
      case ExerciseType.cardio:
        return Icons.directions_run;
      case ExerciseType.timeBased:
        return Icons.timer;
      case ExerciseType.bodyweight:
        return Icons.accessibility_new;
      case ExerciseType.custom:
        return Icons.tune;
    }
  }
}
