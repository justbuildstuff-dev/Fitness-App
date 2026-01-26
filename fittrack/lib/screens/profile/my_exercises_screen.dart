import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/exercise_library_provider.dart';
import '../../models/custom_exercise.dart';
import '../exercises/custom_exercise_form_screen.dart';

/// Screen for managing the user's custom exercises.
/// Accessible from the Profile/Settings screen.
class MyExercisesScreen extends StatelessWidget {
  const MyExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exercises'),
        elevation: 0,
      ),
      body: Consumer<ExerciseLibraryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.customExercises.isEmpty) {
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
                      'Failed to load exercises',
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
                  ],
                ),
              ),
            );
          }

          if (provider.customExercises.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Header with count
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.customExerciseCount}/$maxCustomExercises exercises',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    if (provider.canCreateCustomExercise)
                      TextButton.icon(
                        onPressed: () => _navigateToCreate(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                  ],
                ),
              ),

              // Exercise list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.customExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = provider.customExercises[index];
                    return _ExerciseCard(
                      exercise: exercise,
                      onTap: () => _navigateToEdit(context, exercise),
                      onDelete: () => _confirmDelete(context, exercise),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ExerciseLibraryProvider>(
        builder: (context, provider, child) {
          if (!provider.canCreateCustomExercise) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _navigateToCreate(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Custom Exercises Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own exercises to use in workouts',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreate(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Exercise'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CustomExerciseFormScreen(),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, CustomExercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomExerciseFormScreen(exercise: exercise),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CustomExercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${exercise.name}"?\n\n'
          'Workouts that use this exercise will keep their data, '
          'but the exercise will be removed from your custom library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider =
          Provider.of<ExerciseLibraryProvider>(context, listen: false);
      final success = await provider.deleteCustomExercise(exercise.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Exercise deleted successfully'
                  : provider.error ?? 'Failed to delete exercise',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                success ? null : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  final CustomExercise exercise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.exerciseType.displayName} • ${exercise.primaryMuscles.map((m) => m.displayName).join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onTap,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
