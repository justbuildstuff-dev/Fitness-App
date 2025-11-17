import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../widgets/delete_confirmation_dialog.dart';
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _ExerciseCardPlaceholder(
          key: ValueKey(exercise.id),
          program: widget.program,
          week: widget.week,
          workout: widget.workout,
          exercise: exercise,
          onEdit: () => _editExercise(context, exercise),
          onDelete: () => _deleteExercise(context, exercise),
        );
      },
    );
  }

  void _editExercise(BuildContext context, Exercise exercise) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExerciseScreen(
          program: widget.program,
          week: widget.week,
          workout: widget.workout,
          exercise: exercise,
        ),
      ),
    );

    if (result == true && mounted) {
      // Exercise was updated successfully - reload exercises
      final provider = Provider.of<ProgramProvider>(context, listen: false);
      provider.loadExercises(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
      );
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

/// Placeholder for ExerciseCard widget (will be implemented in Task #115)
/// This allows the ConsolidatedWorkoutScreen to be created and tested while
/// the full ExerciseCard implementation is developed separately
class _ExerciseCardPlaceholder extends StatelessWidget {
  final Program program;
  final Week week;
  final Workout workout;
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCardPlaceholder({
    super.key,
    required this.program,
    required this.week,
    required this.workout,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              _getExerciseTypeIcon(exercise.exerciseType),
              color: _getExerciseTypeColor(exercise.exerciseType),
            ),
            title: Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              exercise.exerciseType.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getExerciseTypeColor(exercise.exerciseType),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit exercise',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete exercise',
                ),
              ],
            ),
          ),

          // Sets section (placeholder)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Sets will be displayed here',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '(SetRow widgets will be implemented in Task #114)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
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
