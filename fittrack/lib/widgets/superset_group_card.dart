import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../utils/workout_item.dart';
import 'exercise_card.dart';

/// A card that visually groups exercises belonging to the same superset.
///
/// Renders a coloured header strip with the group label badge, a drag handle
/// for moving the entire group in the parent list, and a 3-dot menu with
/// "Delete Superset". Below the header, an inner [ReorderableListView] lets
/// the user reorder exercises within the group.
class SupersetGroupCard extends StatefulWidget {
  /// Alphabetic group label, e.g. 'A', 'B', 'AA'.
  final String groupLabel;

  /// Exercises in this group, pre-sorted by groupOrderIndex.
  final List<Exercise> exercises;

  /// Map from exerciseId → its sets.
  final Map<String, List<ExerciseSet>> setsMap;

  /// Index of this card in the parent ReorderableListView.
  final int outerIndex;

  /// Whether outer-list drag handles are enabled.
  final bool isReorderEnabled;

  /// Called when the user selects "Delete Superset".
  final VoidCallback onDeleteGroup;

  /// Called when the user drags exercises within this group.
  final Function(int oldIndex, int newIndex) onReorderWithinGroup;

  /// Called when "+" is tapped on a specific exercise.
  final Function(Exercise exercise) onAddSet;

  /// Called when "Edit Name" is selected for a specific exercise.
  final Function(Exercise exercise) onEditName;

  /// Called when a set field is updated.
  final Function(ExerciseSet updatedSet) onUpdateSet;

  /// Called when a set is deleted.
  final Function(String exerciseId, String setId) onDeleteSet;

  const SupersetGroupCard({
    super.key,
    required this.groupLabel,
    required this.exercises,
    required this.setsMap,
    required this.outerIndex,
    this.isReorderEnabled = true,
    required this.onDeleteGroup,
    required this.onReorderWithinGroup,
    required this.onAddSet,
    required this.onEditName,
    required this.onUpdateSet,
    required this.onDeleteSet,
  });

  @override
  State<SupersetGroupCard> createState() => _SupersetGroupCardState();
}

class _SupersetGroupCardState extends State<SupersetGroupCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  // Outer drag handle — moves the whole group in parent list
                  if (widget.isReorderEnabled)
                    ReorderableDragStartListener(
                      index: widget.outerIndex,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 24,
                        ),
                      ),
                    ),

                  const SizedBox(width: 4),

                  // "Superset · A" badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Superset · ${widget.groupLabel}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 3-dot menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        widget.onDeleteGroup();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_sweep, color: Colors.red),
                          title: Text('Delete Superset'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Inner exercise list ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: widget.onReorderWithinGroup,
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.exercises[index];
                final sets = widget.setsMap[exercise.id] ?? [];
                final positionLabel = computePositionLabel(widget.groupLabel, index);

                return Row(
                  key: ValueKey(exercise.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Position label (A1, A2…)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, right: 4),
                      child: SizedBox(
                        width: 28,
                        child: Text(
                          positionLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // ExerciseCard — reorder enabled so it shows its own drag handle
                    Expanded(
                      child: ExerciseCard(
                        key: ValueKey('card-${exercise.id}'),
                        exercise: exercise,
                        sets: sets,
                        isReorderEnabled: true,
                        index: index,
                        onAddSet: () => widget.onAddSet(exercise),
                        onEditName: () => widget.onEditName(exercise),
                        onUpdateSet: widget.onUpdateSet,
                        onDeleteSet: widget.onDeleteSet,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
