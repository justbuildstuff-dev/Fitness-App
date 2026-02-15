import 'package:flutter/material.dart';

import '../../../models/exercise.dart';

/// A record representing a logged exercise available for selection.
typedef LoggedExercise = ({
  String exerciseId,
  String exerciseName,
  ExerciseType exerciseType,
});

/// Searchable exercise picker showing exercises the user has logged.
///
/// Displays a search field and a filterable list of exercises with
/// type chips. Calls [onSelected] when an exercise is tapped.
class ExercisePicker extends StatefulWidget {
  final List<LoggedExercise> exercises;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const ExercisePicker({
    super.key,
    required this.exercises,
    this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _filteredIndices {
    if (_query.isEmpty) {
      return List.generate(widget.exercises.length, (i) => i);
    }
    final lower = _query.toLowerCase();
    return [
      for (int i = 0; i < widget.exercises.length; i++)
        if (widget.exercises[i].exerciseName.toLowerCase().contains(lower)) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search exercises...',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),

        // Exercise list
        Expanded(
          child: _filteredIndices.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? 'No exercises logged'
                        : 'No matches for "$_query"',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : Semantics(
                  label: 'Exercise list, ${_filteredIndices.length} items',
                  child: ListView.builder(
                    itemCount: _filteredIndices.length,
                    itemBuilder: (context, i) {
                      final originalIndex = _filteredIndices[i];
                      final exercise = widget.exercises[originalIndex];
                      final isSelected =
                          widget.selectedIndex == originalIndex;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                        title: Text(exercise.exerciseName),
                        trailing: Chip(
                          label: Text(exercise.exerciseType.displayName),
                          backgroundColor:
                              _typeColor(exercise.exerciseType)
                                  .withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: _typeColor(exercise.exerciseType),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        onTap: () => widget.onSelected(originalIndex),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  static Color _typeColor(ExerciseType type) {
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
}
