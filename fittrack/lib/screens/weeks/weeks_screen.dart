import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../providers/template_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/navigation_section.dart';
import '../../models/templates/templates.dart';
import '../../services/firestore_service.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/create_options_sheet.dart';
import '../templates/template_picker_screen.dart';
import '../templates/template_preview_sheet.dart';
import '../workouts/create_workout_screen.dart';
import '../workouts/consolidated_workout_screen.dart';

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
                value: 'save_as_template',
                child: ListTile(
                  leading: Icon(Icons.save_alt),
                  title: Text('Save as Template'),
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
            child: Consumer<ProgramProvider>(
              builder: (context, programProvider, child) {
                final weekIndex = programProvider.weeks.indexWhere((w) => w.id == widget.week.id);
                final weekNumber = weekIndex >= 0 ? weekIndex + 1 : widget.week.order;
                final workoutCount = programProvider.workouts.length;
                return Column(
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
                              '$weekNumber',
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
                    Row(
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
                          value: '$weekNumber',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                );
              },
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
                        program: widget.program,
                        week: widget.week,
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
      bottomNavigationBar: const GlobalBottomNavBar(
        currentSection: NavigationSection.programs,
      ),
    );
  }

  void _navigateToCreateWorkout(BuildContext context) async {
    final option = await CreateOptionsSheet.show(
      context,
      itemType: 'Workout',
      startFreshDescription: 'Create a blank workout and add exercises manually',
      fromTemplateDescription: 'Start with a saved workout template',
    );

    if (option == null || !context.mounted) return;

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    if (option == CreateOption.startFresh) {
      final result = await Navigator.of(context).push<bool>(
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
    } else if (option == CreateOption.fromTemplate) {
      _navigateToWorkoutTemplatePicker(context);
    }
  }

  void _navigateToWorkoutTemplatePicker(BuildContext context) {
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplatePickerScreen<WorkoutTemplate>(
          title: 'Select Workout Template',
          templates: templateProvider.workoutTemplates,
          isLoading: templateProvider.isLoading,
          error: templateProvider.error,
          showSourceFilter: false, // No pre-built workout templates
          itemBuilder: (context, template) => ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              template.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${template.exerciseCount} ${template.exerciseCount == 1 ? 'exercise' : 'exercises'} · ${template.totalSetCount} sets',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
          onSelect: (template) async {
            // Show preview sheet
            final confirmed = await WorkoutTemplatePreviewSheet.show(
              context,
              template: template,
            );

            if (confirmed == true && context.mounted) {
              // Get existing workout names for smart naming
              final existingNames = programProvider.workouts
                  .map((w) => w.name)
                  .toList();

              // Get next order index
              final nextOrder = programProvider.workouts.isEmpty
                  ? 0
                  : programProvider.workouts.map((w) => w.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

              final workoutId = await templateProvider.applyWorkoutTemplate(
                template: template,
                weekId: widget.week.id,
                programId: widget.program.id,
                orderIndex: nextOrder,
                existingWorkoutNames: existingNames,
              );

              if (workoutId != null && context.mounted) {
                // Pop back to weeks screen
                Navigator.of(context).pop();

                // Refresh workouts list
                programProvider.loadWorkouts(widget.program.id, widget.week.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Workout created from "${template.name}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(templateProvider.error ?? 'Failed to create workout'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          emptyStateWidget: Center(
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
                  'No Workout Templates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Save a workout as a template to use it here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWorkout(BuildContext context, Workout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConsolidatedWorkoutScreen(
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
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final errorColor = Theme.of(context).colorScheme.error;

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          final result = await programProvider.duplicateWeek(
            programId: widget.program.id,
            weekId: widget.week.id,
          );

          if (context.mounted) {
            Navigator.of(context).pop(); // Dismiss loading dialog

            if (result != null && result['success'] == true) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Week duplicated successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // Navigate back to program detail screen to see the duplicated week
              Navigator.of(context).pop();
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(programProvider.error ?? 'Failed to duplicate week'),
                  backgroundColor: errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context).pop(); // Dismiss loading dialog
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error duplicating week: $e'),
                backgroundColor: errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;

      case 'edit':
        // TODO: Navigate to edit week screen
        break;

      case 'save_as_template':
        _saveWeekAsTemplate(context);
        break;

      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _saveWeekAsTemplate(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);

    // Workouts should already be loaded since we're on the week screen
    final workouts = programProvider.workouts;

    if (workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workouts to save as template'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading dialog while building template data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Build template workouts with exercises and sets
    final templateWorkouts = <TemplateWorkout>[];
    final firestoreService = FirestoreService.instance;

    try {
      for (final workout in workouts) {
        // Fetch exercises for this workout using stream.first
        final exercises = await firestoreService.getExercises(
          programProvider.userId!,
          widget.program.id,
          widget.week.id,
          workout.id,
        ).first;

        final templateExercises = <TemplateExercise>[];

        for (final exercise in exercises) {
          // Fetch sets for this exercise using stream.first
          final sets = await firestoreService.getSets(
            programProvider.userId!,
            widget.program.id,
            widget.week.id,
            workout.id,
            exercise.id,
          ).first;

          templateExercises.add(TemplateExercise(
            name: exercise.name,
            exerciseType: exercise.exerciseType,
            orderIndex: exercise.orderIndex,
            notes: exercise.notes,
            supersetGroupId: exercise.supersetGroupId,
            sets: sets.map((set) => TemplateSet(
              setNumber: set.setNumber,
              reps: set.reps,
              duration: set.duration,
              restTime: set.restTime,
              notes: set.notes,
            )).toList(),
          ));
        }

        templateWorkouts.add(TemplateWorkout(
          name: workout.name,
          dayOfWeek: workout.dayOfWeek,
          orderIndex: workout.orderIndex,
          notes: workout.notes,
          exercises: templateExercises,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workout data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Dismiss loading dialog
    Navigator.of(context).pop();

    // Show save dialog
    final nameController = TextEditingController(text: widget.week.name);
    final descriptionController = TextEditingController(text: widget.week.notes ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.save_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Save as Week Template')),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'Enter a name for the template',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a template name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add a description for this template',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save Template'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final templateId = await templateProvider.saveWeekAsTemplate(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        workouts: templateWorkouts,
      );

      if (templateId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Week saved as template "${nameController.text.trim()}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(templateProvider.error ?? 'Failed to save template'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await programProvider.getCascadeDeleteCounts(
      weekId: widget.week.id,
    );

    if (!context.mounted) return;

    // Show enhanced dialog with cascade counts
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Week',
      content: 'Are you sure you want to delete this week?',
      itemName: widget.week.name,
      deleteButtonText: 'Delete Week',
      cascadeCounts: cascadeCounts,
    );

    if (confirmed == true) {
      try {
        // Use full delete method with explicit IDs (not deleteWeekById)
        await programProvider.deleteWeek(
          widget.program.id,
          widget.week.id,
        );

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Week "${widget.week.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(); // Go back to program detail
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete week: $e'),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
  final Program program;
  final Week week;
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutCard({
    required this.program,
    required this.week,
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

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await programProvider.getCascadeDeleteCounts(
      workoutId: workout.id,
    );

    if (!context.mounted) return;

    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Workout',
      content: 'Are you sure you want to delete this workout?',
      itemName: workout.name,
      deleteButtonText: 'Delete Workout',
      cascadeCounts: cascadeCounts,
    );

    if (confirmed == true) {
      try {
        // Use full delete method with explicit IDs (not deleteWorkoutById)
        await programProvider.deleteWorkout(
          program.id,
          week.id,
          workout.id,
        );

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