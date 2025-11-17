import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/exercise_card.dart';
import '../exercises/create_exercise_screen.dart';

/// Consolidated workout screen that displays all exercises and their sets inline
/// Replaces the separate WorkoutDetailScreen and ExerciseDetailScreen with a single unified view
class ConsolidatedWorkoutScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;

  const ConsolidatedWorkoutScreen({
    super.key,
    required this.program,
    required this.week,
    required this.workout,
  });

  @override
  State<ConsolidatedWorkoutScreen> createState() => _ConsolidatedWorkoutScreenState();
}

class _ConsolidatedWorkoutScreenState extends State<ConsolidatedWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Load exercises and all sets when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programProvider = Provider.of<ProgramProvider>(context, listen: false);

      // First load exercises
      programProvider.loadExercises(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
      );

      // Then load all sets for all exercises
      programProvider.loadAllSetsForWorkout(
        programId: widget.program.id,
        weekId: widget.week.id,
        workoutId: widget.workout.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editWorkout(context),
            tooltip: 'Edit Workout',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Workout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProgramProvider>(
        builder: (context, provider, child) {
          final exercises = provider.exercises;
          final isLoadingExercises = provider.isLoadingExercises;
          final isLoadingSets = provider.isLoadingAllWorkoutSets;
          final error = provider.error;

          // Show loading indicator while exercises or sets are loading
          if ((isLoadingExercises || isLoadingSets) && exercises.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null && exercises.isEmpty) {
            return Center(
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
                    'Error loading exercises',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadExercises(
                        widget.program.id,
                        widget.week.id,
                        widget.workout.id,
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return exercises.isEmpty
              ? _buildEmptyState()
              : _buildExercisesList(exercises);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExercise(context),
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first exercise to start building this workout',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addExercise(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Exercise'),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(List<Exercise> exercises) {
    final provider = Provider.of<ProgramProvider>(context, listen: false);

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      onReorder: (oldIndex, newIndex) => _reorderExercises(context, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final sets = provider.getSetsForExercise(exercise.id);

        return ExerciseCard(
          key: ValueKey(exercise.id),
          exercise: exercise,
          sets: sets,
          onAddSet: () => _addSet(context, exercise),
          onEditName: () => _editExerciseName(context, exercise),
          onDelete: () => _deleteExercise(context, exercise),
          onUpdateSet: (updatedSet) => _updateSet(context, updatedSet),
          onDeleteSet: (exerciseId, setId) => _deleteSet(context, exerciseId, setId),
        );
      },
    );
  }

  Future<void> _addSet(BuildContext context, Exercise exercise) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await provider.createSet(
        programId: widget.program.id,
        weekId: widget.week.id,
        workoutId: widget.workout.id,
        exerciseId: exercise.id,
      );

      // Reload all sets to get the new one
      await provider.loadAllSetsForWorkout(
        programId: widget.program.id,
        weekId: widget.week.id,
        workoutId: widget.workout.id,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Set added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add set: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateSet(BuildContext context, ExerciseSet updatedSet) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);

    try {
      await provider.updateSet(updatedSet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update set: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteSet(BuildContext context, String exerciseId, String setId) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: const Text('Are you sure you want to delete this set?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteSet(
          widget.program.id,
          widget.week.id,
          widget.workout.id,
          exerciseId,
          setId,
        );

        // Reload all sets
        await provider.loadAllSetsForWorkout(
          programId: widget.program.id,
          weekId: widget.week.id,
          workoutId: widget.workout.id,
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Set deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete set: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _editExerciseName(BuildContext context, Exercise exercise) async {
    final nameController = TextEditingController(text: exercise.name);
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Exercise Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Exercise Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != exercise.name) {
      try {
        final updatedExercise = exercise.copyWith(
          name: result,
          updatedAt: DateTime.now(),
        );

        await provider.updateExercise(updatedExercise);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Exercise name updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to update exercise name: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    nameController.dispose();
  }

  Future<void> _reorderExercises(BuildContext context, int oldIndex, int newIndex) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);

    // Adjust newIndex if moving down the list
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    try {
      // Get the current exercises list
      final exercises = List<Exercise>.from(provider.exercises);

      // Reorder in local list
      final exercise = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, exercise);

      // Update orderIndex for all affected exercises
      for (int i = 0; i < exercises.length; i++) {
        if (exercises[i].orderIndex != i) {
          final updatedExercise = exercises[i].copyWith(
            orderIndex: i,
            updatedAt: DateTime.now(),
          );
          await provider.updateExercise(updatedExercise);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder exercises: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteExercise(BuildContext context, Exercise exercise) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await programProvider.getCascadeDeleteCounts(
      exerciseId: exercise.id,
    );

    if (!context.mounted) return;

    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Exercise',
      content: 'Are you sure you want to delete this exercise?',
      itemName: exercise.name,
      deleteButtonText: 'Delete Exercise',
      cascadeCounts: cascadeCounts,
    );

    if (confirmed == true) {
      try {
        await programProvider.deleteExerciseById(exercise.id);

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Exercise "${exercise.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final errorColor = Theme.of(context).colorScheme.error;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete exercise: $e'),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _editWorkout(BuildContext context) {
    // TODO: Implement edit workout functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit workout functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addExercise(BuildContext context) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<ProgramProvider>(context, listen: false);

    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateExerciseScreen(
          program: widget.program,
          week: widget.week,
          workout: widget.workout,
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh exercises list
      provider.loadExercises(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await provider.getCascadeDeleteCounts(
      workoutId: widget.workout.id,
    );

    if (!context.mounted) return;

    // Show enhanced dialog with cascade counts
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Workout',
      content: 'Are you sure you want to delete this workout?',
      itemName: widget.workout.name,
      deleteButtonText: 'Delete Workout',
      cascadeCounts: cascadeCounts,
    );

    if (confirmed == true) {
      try {
        await provider.deleteWorkoutById(widget.workout.id);

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Workout "${widget.workout.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pop(); // Go back to weeks screen
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete workout: $e'),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
