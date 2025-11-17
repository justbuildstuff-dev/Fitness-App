import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../sets/create_set_screen.dart';

/// DEPRECATED: Use ConsolidatedWorkoutScreen instead.
/// This screen will be removed in a future version.
/// ConsolidatedWorkoutScreen shows all exercises and sets inline,
/// eliminating the need for separate exercise detail screens.
@Deprecated('Use ConsolidatedWorkoutScreen instead')
class ExerciseDetailScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;
  final Exercise exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.program,
    required this.week,
    required this.workout,
    required this.exercise,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load sets when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programProvider = Provider.of<ProgramProvider>(context, listen: false);
      programProvider.loadSets(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
        widget.exercise.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editExercise(context),
            tooltip: 'Edit Exercise',
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
                  title: Text('Delete Exercise'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProgramProvider>(
        builder: (context, provider, child) {
          final sets = provider.getCurrentSets();
          final isLoading = provider.isLoading;
          final error = provider.error;

          if (isLoading && sets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null && sets.isEmpty) {
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
                    'Error loading sets',
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
                      provider.loadSets(
                        widget.program.id,
                        widget.week.id,
                        widget.workout.id,
                        widget.exercise.id,
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
              // Exercise Info Header
              _buildExerciseHeader(),
              
              // Sets List
              Expanded(
                child: sets.isEmpty
                    ? _buildEmptyState()
                    : _buildSetsList(sets),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSet(context),
        tooltip: 'Add Set',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Text(
              '${widget.program.name} → ${widget.week.name} → ${widget.workout.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            
            // Exercise Name and Type
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(widget.exercise.exerciseType.displayName),
                  backgroundColor: _getTypeColor().withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: _getTypeColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            // Notes if present
            if (widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty) ...[
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
                        widget.exercise.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Field Info
            const SizedBox(height: 16),
            _buildFieldInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldInfo() {
    final exercise = Exercise(
      id: '',
      name: '',
      exerciseType: widget.exercise.exerciseType,
      orderIndex: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: '',
      workoutId: '',
      weekId: '',
      programId: '',
    );

    final requiredFields = exercise.requiredSetFields;
    final optionalFields = exercise.optionalSetFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trackable fields for this exercise:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...requiredFields.map((field) => Chip(
              label: Text('${_getFieldDisplayName(field)} *'),
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )),
            ...optionalFields.map((field) => Chip(
              label: Text(_getFieldDisplayName(field)),
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No sets yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first set to start tracking this exercise',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addSet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsList(List<ExerciseSet> sets) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final set = sets[index];
        return _buildSetCard(set, index);
      },
    );
  }

  Widget _buildSetCard(ExerciseSet set, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: set.checked 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          child: Text(
            '${set.setNumber}',
            style: TextStyle(
              color: set.checked 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          set.displayString,
          style: TextStyle(
            decoration: set.checked ? TextDecoration.lineThrough : null,
            color: set.checked 
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                : null,
          ),
        ),
        subtitle: set.notes != null && set.notes!.isNotEmpty
            ? Text(
                set.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                set.checked ? Icons.check_box : Icons.check_box_outline_blank,
                color: set.checked 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
              ),
              onPressed: () => _toggleSetCompletion(set),
              tooltip: set.checked ? 'Mark incomplete' : 'Mark complete',
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editSet(context, set),
              tooltip: 'Edit set',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteSet(context, set),
              tooltip: 'Delete set',
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.exercise.exerciseType) {
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

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'reps':
        return 'Reps';
      case 'weight':
        return 'Weight';
      case 'duration':
        return 'Duration';
      case 'distance':
        return 'Distance';
      case 'restTime':
        return 'Rest Time';
      default:
        return field;
    }
  }

  void _editExercise(BuildContext context) {
    // TODO: Implement edit exercise functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit exercise functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addSet(BuildContext context) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateSetScreen(
          program: widget.program,
          week: widget.week,
          workout: widget.workout,
          exercise: widget.exercise,
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh sets list
      provider.loadSets(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
        widget.exercise.id,
      );
    }
  }

  void _editSet(BuildContext context, ExerciseSet set) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSetScreen(
          program: widget.program,
          week: widget.week,
          workout: widget.workout,
          exercise: widget.exercise,
          exerciseSet: set,
        ),
      ),
    );
    
    if (result == true) {
      // Set was updated successfully - no action needed as UI updates via stream
    }
  }

  void _toggleSetCompletion(ExerciseSet set) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    
    final updatedSet = set.copyWith(
      checked: !set.checked,
      updatedAt: DateTime.now(),
    );

    await provider.updateSet(updatedSet);
  }

  void _deleteSet(BuildContext context, ExerciseSet set) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Are you sure you want to delete set ${set.setNumber}?'),
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

    if (confirmed == true) {
      await provider.deleteSet(
        widget.program.id,
        widget.week.id,
        widget.workout.id,
        widget.exercise.id,
        set.id,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Set deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await provider.getCascadeDeleteCounts(
      exerciseId: widget.exercise.id,
    );

    if (!context.mounted) return;

    // Show enhanced dialog with cascade counts
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Exercise',
      content: 'Are you sure you want to delete this exercise?',
      itemName: widget.exercise.name,
      deleteButtonText: 'Delete Exercise',
      cascadeCounts: cascadeCounts,
    );

    if (confirmed == true) {
      try {
        await provider.deleteExerciseById(widget.exercise.id);

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Exercise "${widget.exercise.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          navigator.pop(); // Go back to workout screen
        }
      } catch (e) {
        if (context.mounted) {
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
}