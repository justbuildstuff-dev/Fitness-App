import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../exercises/create_exercise_screen.dart';
import '../exercises/exercise_detail_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;

  const WorkoutDetailScreen({
    super.key,
    required this.program,
    required this.week,
    required this.workout,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load exercises when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programProvider = Provider.of<ProgramProvider>(context, listen: false);
      programProvider.loadExercises(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
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
          final isLoading = provider.isLoadingExercises;
          final error = provider.error;

          if (isLoading && exercises.isEmpty) {
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

          return Column(
            children: [
              // Workout Info Header
              _buildWorkoutHeader(),
              
              // Exercises List
              Expanded(
                child: exercises.isEmpty
                    ? _buildEmptyState()
                    : _buildExercisesList(exercises),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExercise(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Exercise',
      ),
    );
  }

  Widget _buildWorkoutHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Text(
              '${widget.program.name} → ${widget.week.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            
            // Workout Name
            Text(
              widget.workout.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Day of Week if present
            if (widget.workout.dayOfWeek != null) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(_getDayName(widget.workout.dayOfWeek!)),
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            
            // Notes if present
            if (widget.workout.notes != null && widget.workout.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.workout.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise, index);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getExerciseTypeColor(exercise.exerciseType).withValues(alpha: 0.1),
          child: Icon(
            _getExerciseTypeIcon(exercise.exerciseType),
            color: _getExerciseTypeColor(exercise.exerciseType),
          ),
        ),
        title: Text(
          exercise.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              exercise.exerciseType.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getExerciseTypeColor(exercise.exerciseType),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                exercise.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editExercise(context, exercise),
              tooltip: 'Edit exercise',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteExercise(context, exercise),
              tooltip: 'Delete exercise',
            ),
          ],
        ),
        onTap: () => _navigateToExerciseDetail(exercise),
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday', 
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dayOfWeek - 1]; // dayOfWeek is 1-based
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
    
    if (result == true) {
      // Exercise was updated successfully - no action needed as UI updates via stream
    }
  }

  void _deleteExercise(BuildContext context, Exercise exercise) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Exercise',
      content: 'This will permanently delete "${exercise.name}" and all its sets. '
               'This action cannot be undone.',
      deleteButtonText: 'Delete Exercise',
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

  void _navigateToExerciseDetail(Exercise exercise) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          program: widget.program,
          week: widget.week,
          workout: widget.workout,
          exercise: exercise,
        ),
      ),
    );

    // Refresh exercises when returning (in case exercise was deleted)
    if (mounted) {
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
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: Text(
          'Are you sure you want to delete "${widget.workout.name}"? This will also delete all exercises and sets in this workout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      
      final success = await provider.deleteWorkout(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
      );

      if (mounted) {
        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Workout deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pop(); // Go back to weeks screen
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to delete workout'),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}