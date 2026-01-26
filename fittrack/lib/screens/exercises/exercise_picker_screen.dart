import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/exercise_library_provider.dart';
import '../../models/library_exercise.dart';
import '../../models/custom_exercise.dart';
import '../../models/muscle_group.dart';
import '../../models/exercise.dart';
import 'custom_exercise_form_screen.dart';

/// A screen for browsing and selecting exercises from the library or custom exercises.
/// Returns the selected exercise data when the user taps "Add to Workout".
class ExercisePickerScreen extends StatefulWidget {
  /// If true, show the "Create Custom" button for creating new exercises
  final bool showCreateCustomButton;

  const ExercisePickerScreen({
    super.key,
    this.showCreateCustomButton = true,
  });

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  MuscleGroup? _selectedMuscleGroup;
  ExerciseType? _selectedExerciseType;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        elevation: 0,
      ),
      body: Consumer<ExerciseLibraryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isLibraryLoaded) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && !provider.isLibraryLoaded) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load exercise library',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => provider.loadLibrary(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final searchResults = provider.searchExercises(
            query: _searchQuery,
            muscleGroup: _selectedMuscleGroup,
            exerciseType: _selectedExerciseType,
          );

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Filter chips
              _buildFilterChips(),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${searchResults.length} exercise${searchResults.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    if (_selectedMuscleGroup != null ||
                        _selectedExerciseType != null)
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Exercise list
              Expanded(
                child: searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final exercise = searchResults[index];
                          return _ExerciseListTile(
                            exercise: exercise,
                            onTap: () => _showExerciseDetails(context, exercise),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: widget.showCreateCustomButton
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateCustom(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Custom'),
            )
          : null,
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Muscle group filter dropdown
          _FilterChipDropdown<MuscleGroup>(
            label: 'Muscle Group',
            value: _selectedMuscleGroup,
            items: MuscleGroup.values,
            itemLabel: (m) => m.displayName,
            onSelected: (value) {
              setState(() {
                _selectedMuscleGroup = value;
              });
            },
          ),
          const SizedBox(width: 8),
          // Exercise type filter dropdown
          _FilterChipDropdown<ExerciseType>(
            label: 'Type',
            value: _selectedExerciseType,
            // Only show strength and bodyweight as per PRD
            items: const [ExerciseType.strength, ExerciseType.bodyweight],
            itemLabel: (t) => t.displayName,
            onSelected: (value) {
              setState(() {
                _selectedExerciseType = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedMuscleGroup != null ||
        _selectedExerciseType != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.fitness_center,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No exercises found' : 'No exercises available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'Create a custom exercise to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear all filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedMuscleGroup = null;
      _selectedExerciseType = null;
    });
  }

  void _showExerciseDetails(BuildContext context, dynamic exercise) async {
    final String name;
    final ExerciseType exerciseType;
    final List<MuscleGroup> primaryMuscles;
    final List<MuscleGroup> secondaryMuscles;
    final bool isLibrary;

    if (exercise is LibraryExercise) {
      isLibrary = true;
      name = exercise.name;
      exerciseType = exercise.exerciseType;
      primaryMuscles = exercise.primaryMuscles;
      secondaryMuscles = exercise.secondaryMuscles;
    } else {
      final customExercise = exercise as CustomExercise;
      isLibrary = false;
      name = customExercise.name;
      exerciseType = customExercise.exerciseType;
      primaryMuscles = customExercise.primaryMuscles;
      secondaryMuscles = customExercise.secondaryMuscles;
    }

    // Capture navigator before async gap
    final navigator = Navigator.of(context);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExerciseDetailsSheet(
        name: name,
        exerciseType: exerciseType,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        isLibrary: isLibrary,
        exercise: exercise,
      ),
    );

    // If an exercise was selected, return it to the caller
    if (result != null && mounted) {
      navigator.pop(result);
    }
  }

  void _navigateToCreateCustom(BuildContext context) async {
    // Capture navigator before async gap
    final navigator = Navigator.of(context);

    // Navigate to custom exercise form with flag to return exercise data
    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const CustomExerciseFormScreen(
          returnExerciseData: true,
        ),
      ),
    );

    // If custom exercise was created and returned, pass it back to the caller
    if (result != null && mounted) {
      navigator.pop(result);
    }
  }
}

class _ExerciseListTile extends StatelessWidget {
  final dynamic exercise;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLibrary = exercise is LibraryExercise;
    final name = isLibrary
        ? (exercise as LibraryExercise).name
        : (exercise as CustomExercise).name;
    final exerciseType = isLibrary
        ? (exercise as LibraryExercise).exerciseType
        : (exercise as CustomExercise).exerciseType;
    final primaryMuscles = isLibrary
        ? (exercise as LibraryExercise).primaryMuscles
        : (exercise as CustomExercise).primaryMuscles;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isLibrary
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(
            Icons.fitness_center,
            color: isLibrary
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${exerciseType.displayName} • ${primaryMuscles.map((m) => m.displayName).join(", ")}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        trailing: isLibrary
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Custom',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                ),
              ),
      ),
    );
  }
}

class _FilterChipDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onSelected;

  const _FilterChipDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T?>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<T?>(
          value: null,
          child: Text(
            'All',
            style: TextStyle(
              fontWeight: value == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        ...items.map((item) => PopupMenuItem<T?>(
              value: item,
              child: Text(
                itemLabel(item),
                style: TextStyle(
                  fontWeight: value == item ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            )),
      ],
      child: Chip(
        label: Text(value == null ? label : itemLabel(value as T)),
        avatar: value != null
            ? Icon(
                Icons.check,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        backgroundColor: value != null
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        side: value != null
            ? BorderSide(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stateful bottom sheet for exercise details with set count selector
class _ExerciseDetailsSheet extends StatefulWidget {
  final String name;
  final ExerciseType exerciseType;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final bool isLibrary;
  final dynamic exercise;

  const _ExerciseDetailsSheet({
    required this.name,
    required this.exerciseType,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.isLibrary,
    required this.exercise,
  });

  @override
  State<_ExerciseDetailsSheet> createState() => _ExerciseDetailsSheetState();
}

class _ExerciseDetailsSheetState extends State<_ExerciseDetailsSheet> {
  int _setCount = 1;

  void _incrementSetCount() {
    if (_setCount < 10) {
      setState(() => _setCount++);
    }
  }

  void _decrementSetCount() {
    if (_setCount > 1) {
      setState(() => _setCount--);
    }
  }

  void _addToWorkout() {
    // Close the bottom sheet
    Navigator.of(context).pop();

    // Return the exercise data with set count to the calling screen
    final Map<String, dynamic> result;
    if (widget.exercise is LibraryExercise) {
      result = {
        'name': widget.name,
        'exerciseType': widget.exerciseType,
        'isLibrary': true,
        'sourceId': (widget.exercise as LibraryExercise).id,
        'setCount': _setCount,
      };
    } else {
      final customExercise = widget.exercise as CustomExercise;
      result = {
        'name': customExercise.name,
        'exerciseType': customExercise.exerciseType,
        'isLibrary': false,
        'sourceId': customExercise.id,
        'setCount': _setCount,
      };
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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

              // Exercise name and badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isLibrary
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.isLibrary ? 'Library' : 'Custom',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: widget.isLibrary
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Exercise type
              _DetailRow(
                icon: Icons.category,
                label: 'Type',
                value: widget.exerciseType.displayName,
              ),
              const SizedBox(height: 12),

              // Primary muscles
              _DetailRow(
                icon: Icons.fitness_center,
                label: 'Primary Muscles',
                value: widget.primaryMuscles.map((m) => m.displayName).join(', '),
              ),
              const SizedBox(height: 12),

              // Secondary muscles
              if (widget.secondaryMuscles.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.fitness_center_outlined,
                  label: 'Secondary Muscles',
                  value:
                      widget.secondaryMuscles.map((m) => m.displayName).join(', '),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 24),

              // Set count selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Number of Sets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _setCount > 1 ? _decrementSetCount : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$_setCount',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                        IconButton(
                          onPressed: _setCount < 10 ? _incrementSetCount : null,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Add to workout button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addToWorkout,
                  icon: const Icon(Icons.add),
                  label: Text('Add $_setCount Set${_setCount > 1 ? 's' : ''} to Workout'),
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
