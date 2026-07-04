import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../providers/template_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/navigation_section.dart';
import '../../models/templates/templates.dart';
import '../../services/firestore_service.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/create_options_sheet.dart';
import '../subscription/paywall_screen.dart';
import '../templates/template_picker_screen.dart';
import '../templates/template_preview_sheet.dart';
import '../weeks/weeks_screen.dart';
import '../weeks/create_week_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  final Program program;

  const ProgramDetailScreen({
    super.key,
    required this.program,
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Select the program and load weeks when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programProvider = Provider.of<ProgramProvider>(context, listen: false);
      programProvider.selectProgram(widget.program);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Program'),
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
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archive Program'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Program Header
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
                      child: Icon(
                        Icons.fitness_center,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.program.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.program.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.program.description!,
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
                    final weekCount = programProvider.weeks.length;
                    return Row(
                      children: [
                        _StatCard(
                          icon: Icons.view_week,
                          label: 'Weeks',
                          value: '$weekCount',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        _StatCard(
                          icon: Icons.calendar_today,
                          label: 'Created',
                          value: _formatDate(widget.program.createdAt),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Weeks List
          Expanded(
            child: Consumer<ProgramProvider>(
              builder: (context, programProvider, child) {
                if (programProvider.isLoadingWeeks) {
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
                          'Error loading weeks',
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
                            programProvider.loadWeeks(widget.program.id);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (programProvider.weeks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_week,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Weeks Yet',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first week to start building your program',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreateWeek(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Week'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    programProvider.loadWeeks(widget.program.id);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: programProvider.weeks.length,
                    itemBuilder: (context, index) {
                      final week = programProvider.weeks[index];
                      return _WeekCard(
                        program: widget.program,
                        week: week,
                        weekNumber: index + 1,
                        onTap: () => _navigateToWeek(context, week),
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
        onPressed: () => _navigateToCreateWeek(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const GlobalBottomNavBar(
        currentSection: NavigationSection.programs,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit program screen
        break;
      case 'save_as_template':
        _saveProgramAsTemplate(context);
        break;
      case 'archive':
        _showArchiveDialog(context);
        break;
    }
  }

  void _showArchiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Program'),
        content: Text(
          'Are you sure you want to archive "${widget.program.name}"? You can restore it later from archived programs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final errorColor = Theme.of(context).colorScheme.error;
              
              navigator.pop();
              final programProvider = Provider.of<ProgramProvider>(context, listen: false);
              final success = await programProvider.archiveProgram(widget.program.id);
              
              if (context.mounted) {
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Program archived successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  navigator.pop(); // Go back to programs list
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(programProvider.error ?? 'Failed to archive program'),
                      backgroundColor: errorColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('ARCHIVE'),
          ),
        ],
      ),
    );
  }

  void _saveProgramAsTemplate(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    if (sub.isFree) {
      PaywallScreen.show(
        context,
        headline: 'That workout\'s good enough to save.',
        subtext: 'Pro gives you unlimited custom templates.',
      );
      return;
    }

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    final firestoreService = FirestoreService.instance;

    // Get weeks for this program
    final weeks = programProvider.weeks;

    if (weeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No weeks to save as template'),
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

    // Build template weeks with workouts, exercises, and sets
    final templateWeeks = <TemplateWeek>[];

    try {
      for (final week in weeks) {
        // Fetch workouts for this week
        final workouts = await firestoreService.getWorkouts(
          programProvider.userId!,
          widget.program.id,
          week.id,
        ).first;

        final templateWorkouts = <TemplateWorkout>[];

        for (final workout in workouts) {
          // Fetch exercises for this workout
          final exercises = await firestoreService.getExercises(
            programProvider.userId!,
            widget.program.id,
            week.id,
            workout.id,
          ).first;

          final templateExercises = <TemplateExercise>[];

          for (final exercise in exercises) {
            // Fetch sets for this exercise
            final sets = await firestoreService.getSets(
              programProvider.userId!,
              widget.program.id,
              week.id,
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

        templateWeeks.add(TemplateWeek(
          name: week.name,
          order: week.order,
          notes: week.notes,
          workouts: templateWorkouts,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading program data: $e'),
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
    final nameController = TextEditingController(text: widget.program.name);
    final descriptionController = TextEditingController(text: widget.program.description ?? '');
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
            const Expanded(child: Text('Save as Program Template')),
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
      final templateId = await templateProvider.saveProgramAsTemplate(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        weeks: templateWeeks,
      );

      if (templateId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Program saved as template "${nameController.text.trim()}"'),
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

  void _navigateToCreateWeek(BuildContext context) async {
    final option = await CreateOptionsSheet.show(
      context,
      itemType: 'Week',
      startFreshDescription: 'Create a blank week and add workouts manually',
      fromTemplateDescription: 'Start with a saved week template',
    );

    if (option == null || !context.mounted) return;

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    if (option == CreateOption.startFresh) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateWeekScreen(program: widget.program),
        ),
      );

      // Refresh weeks list when returning from create week screen
      if (mounted) {
        programProvider.loadWeeks(widget.program.id);
      }
    } else if (option == CreateOption.fromTemplate) {
      _navigateToWeekTemplatePicker(context);
    }
  }

  void _navigateToWeekTemplatePicker(BuildContext context) {
    final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplatePickerScreen<WeekTemplate>(
          title: 'Select Week Template',
          templates: templateProvider.weekTemplates,
          isLoading: templateProvider.isLoading,
          error: templateProvider.error,
          showSourceFilter: false, // No pre-built week templates
          itemBuilder: (context, template) => ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_view_week,
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
              '${template.workoutCount} ${template.workoutCount == 1 ? 'workout' : 'workouts'} · ${template.totalExerciseCount} exercises',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
          onSelect: (template) async {
            // Show preview sheet
            final confirmed = await WeekTemplatePreviewSheet.show(
              context,
              template: template,
            );

            if (confirmed == true && context.mounted) {
              // Get existing week names for smart naming
              final existingNames = programProvider.weeks
                  .map((w) => w.name)
                  .toList();

              // Get next order
              final nextOrder = programProvider.weeks.isEmpty
                  ? 1
                  : programProvider.weeks.map((w) => w.order).reduce((a, b) => a > b ? a : b) + 1;

              final weekId = await templateProvider.applyWeekTemplate(
                template: template,
                programId: widget.program.id,
                order: nextOrder,
                existingWeekNames: existingNames,
              );

              if (weekId != null && context.mounted) {
                // Pop back to program detail screen
                Navigator.of(context).pop();

                // Refresh weeks list
                programProvider.loadWeeks(widget.program.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Week created from "${template.name}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(templateProvider.error ?? 'Failed to create week'),
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
                  Icons.calendar_view_week,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Week Templates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Save a week as a template to use it here',
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

  void _navigateToWeek(BuildContext context, Week week) {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    programProvider.selectWeek(week);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeeksScreen(program: widget.program, week: week),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

class _WeekCard extends StatelessWidget {
  final Program program;
  final Week week;
  final int weekNumber;
  final VoidCallback onTap;

  const _WeekCard({
    required this.program,
    required this.week,
    required this.weekNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // InkWell + sibling PopupMenuButton inside Card avoids MergeSemantics.
    // See _ProgramCard in programs_screen.dart for the detailed explanation.
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$weekNumber',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            week.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (week.notes != null)
                            Text(
                              week.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.content_copy),
                  title: Text('Duplicate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'duplicate':
        _duplicateWeek(context);
        break;
      case 'edit':
        _editWeek(context);
        break;
      case 'delete':
        _deleteWeek(context);
        break;
    }
  }

  void _duplicateWeek(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await programProvider.duplicateWeek(
        programId: programProvider.selectedProgram!.id,
        weekId: week.id,
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
  }

  void _editWeek(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWeekScreen(
          program: programProvider.selectedProgram!,
          week: week,
        ),
      ),
    );
    
    if (result == true) {
      // Week was updated successfully - no action needed as UI updates via stream
    }
  }

  void _deleteWeek(BuildContext context) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await programProvider.getCascadeDeleteCounts(
      weekId: week.id,
    );

    if (!context.mounted) return;

    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Week',
      content: 'Are you sure you want to delete this week?',
      itemName: week.name,
      deleteButtonText: 'Delete Week',
      cascadeCounts: cascadeCounts,
    );

    if (confirmed == true) {
      try {
        // Use full delete method with explicit IDs (not deleteWeekById)
        await programProvider.deleteWeek(
          program.id,
          week.id,
        );

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Week "${week.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
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