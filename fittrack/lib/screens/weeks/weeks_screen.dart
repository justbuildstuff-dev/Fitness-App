import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../workouts/create_workout_screen.dart';
import '../workouts/workout_detail_screen.dart';

class WeeksScreen extends StatefulWidget {
  final Program program;
  final Week week;

  const WeeksScreen({
    super.key,
    required this.program,
    required this.week,
  });

  @override
  State<WeeksScreen> createState() => _WeeksScreenState();
}

class _WeeksScreenState extends State<WeeksScreen> {
  @override
  void initState() {
    super.initState();
    // Load workouts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programProvider = Provider.of<ProgramProvider>(context, listen: false);
      programProvider.loadWorkouts(widget.program.id, widget.week.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.week.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.content_copy),
                  title: Text('Duplicate Week'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Week'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete Week'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.week.order}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.week.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.week.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.week.notes!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<ProgramProvider>(
                  builder: (context, programProvider, child) {
                    final workoutCount = programProvider.workouts.length;
                    return Row(
                      children: [
                        _StatCard(
                          icon: Icons.fitness_center,
                          label: 'Workouts',
                          value: '$workoutCount',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        _StatCard(
                          icon: Icons.calendar_today,
                          label: 'Week',
                          value: '${widget.week.order}',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Workouts List
          Expanded(
            child: Consumer<ProgramProvider>(
              builder: (context, programProvider, child) {
                if (programProvider.isLoadingWorkouts) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (programProvider.error != null) {
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
                          'Error loading workouts',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          programProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            programProvider.clearError();
                            programProvider.loadWorkouts(widget.program.id, widget.week.id);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (programProvider.workouts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Workouts Yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first workout for this week',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreateWorkout(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Workout'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    programProvider.loadWorkouts(widget.program.id, widget.week.id);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: programProvider.workouts.length,
                    itemBuilder: (context, index) {
                      final workout = programProvider.workouts[index];
                      return _WorkoutCard(
                        workout: workout,
                        onTap: () => _navigateToWorkout(context, workout),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateWorkout(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateWorkout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    
    final result = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateWorkoutScreen(
          program: widget.program,
          week: widget.week,
        ),
      ),
    );
    
    // Refresh workouts list if workout was created
    if (result == true && mounted) {
      programProvider.loadWorkouts(widget.program.id, widget.week.id);
    }
  }

  void _navigateToWorkout(BuildContext context, Workout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          program: widget.program,
          week: widget.week,
          workout: workout,
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    
    switch (action) {
      case 'duplicate':
        final result = await programProvider.duplicateWeek(
          programId: widget.program.id,
          weekId: widget.week.id,
        );
        
        if (context.mounted) {
          if (result != null && result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Week duplicated successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(programProvider.error ?? 'Failed to duplicate week'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;
      
      case 'edit':
        // TODO: Navigate to edit week screen
        break;
        
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Week'),
        content: Text(
          'Are you sure you want to delete "${widget.week.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final programProvider = Provider.of<ProgramProvider>(context, listen: false);
              final success = await programProvider.deleteWeek(widget.program.id, widget.week.id);
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Week deleted successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop(); // Go back to program detail
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(programProvider.error ?? 'Failed to delete week'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.fitness_center,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        ),
        title: Text(
          workout.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (workout.dayOfWeek != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workout.dayOfWeekName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (workout.notes != null) ...[
              const SizedBox(height: 2),
              Text(
                workout.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editWorkout(context),
              tooltip: 'Edit workout',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteWorkout(context),
              tooltip: 'Delete workout',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _editWorkout(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWorkoutScreen(
          program: programProvider.selectedProgram!,
          week: programProvider.selectedWeek!,
          workout: workout,
        ),
      ),
    );
    
    if (result == true) {
      // Workout was updated successfully - no action needed as UI updates via stream
    }
  }

  void _deleteWorkout(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Workout',
      content: 'This will permanently delete "${workout.name}" and all its exercises '
               'and sets. This action cannot be undone.',
      deleteButtonText: 'Delete Workout',
    );

    if (confirmed == true) {
      try {
        await programProvider.deleteWorkoutById(workout.id);
        
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Workout "${workout.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
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