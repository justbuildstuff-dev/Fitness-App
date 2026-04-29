import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../services/app_analytics_service.dart';
import '../../services/app_review_service.dart';
import '../../services/lifecycle_notification_service.dart';
import '../../services/returning_user_service.dart';
import '../../providers/template_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/navigation_section.dart';
import '../../models/templates/templates.dart';
import '../../utils/workout_item.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/pr_notification_banner.dart';
import '../../widgets/save_as_template_menu_item.dart';
import '../../widgets/superset_group_card.dart';
import '../exercises/exercise_picker_screen.dart';

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

class _ConsolidatedWorkoutScreenState extends State<ConsolidatedWorkoutScreen>
    with WidgetsBindingObserver {
  // Track which exercises are currently adding sets (for debouncing)
  final Set<String> _addingSetForExercise = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppAnalyticsService.instance.logWorkoutStarted();
    AppReviewService.tryRecordWorkoutStarted();
    LifecycleNotificationService.tryRecordWorkoutLogged();
    ReturningUserService.recordLastActiveProgram(widget.program.id);
    // Load exercises and all sets when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWorkoutData();
    }
  }

  void _loadWorkoutData() {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    // Load exercises (live stream)
    programProvider.loadExercises(
      widget.program.id,
      widget.week.id,
      widget.workout.id,
    );

    // Load all sets for all exercises
    programProvider.loadAllSetsForWorkout(
      programId: widget.program.id,
      weekId: widget.week.id,
      workoutId: widget.workout.id,
    );
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
                case MenuActions.saveAsTemplate:
                  _saveAsTemplate(context);
                  break;
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const SaveAsTemplateMenuItem(),
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
        onPressed: () => _showAddMenu(context),
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const GlobalBottomNavBar(
        currentSection: NavigationSection.programs,
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
    final items = groupExercises(exercises);

    // Pre-compute group labels (A, B, C…) for each item so the itemBuilder
    // can look them up by index without mutable state inside the closure.
    final groupLabels = <int, String>{};
    int supersetCount = 0;
    for (int i = 0; i < items.length; i++) {
      if (items[i] is SupersetGroup) {
        groupLabels[i] = computeGroupLabel(supersetCount++);
      }
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      buildDefaultDragHandles: false,
      physics: const AlwaysScrollableScrollPhysics(),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(animation.value);
            final elevation = lerpDouble(0, 6, t)!;
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(8),
              child: child,
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) =>
          _reorderWorkoutItems(context, items, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is StandaloneExercise) {
          final exercise = item.exercise;
          final sets = provider.getSetsForExercise(exercise.id);
          final isAddingSet = _addingSetForExercise.contains(exercise.id);

          return ExerciseCard(
            key: ValueKey(exercise.id),
            exercise: exercise,
            sets: sets,
            isReorderEnabled: true,
            index: index,
            onAddSet: isAddingSet || sets.length >= 10
                ? null
                : () => _addSet(context, exercise),
            onEditName: () => _editExerciseName(context, exercise),
            onDelete: () => _deleteExercise(context, exercise),
            onUpdateSet: (updatedSet) => _updateSet(context, updatedSet),
            onDeleteSet: (exerciseId, setId) =>
                _deleteSet(context, exerciseId, setId),
          );
        } else {
          final group = item as SupersetGroup;
          final groupLabel = groupLabels[index]!;
          final setsMap = <String, List<ExerciseSet>>{
            for (final ex in group.exercises)
              ex.id: provider.getSetsForExercise(ex.id),
          };

          return SupersetGroupCard(
            key: ValueKey(group.groupId),
            groupLabel: groupLabel,
            exercises: group.exercises,
            setsMap: setsMap,
            outerIndex: index,
            isReorderEnabled: true,
            onDeleteGroup: () => _deleteSuperset(context, group),
            onReorderWithinGroup: (oldInner, newInner) =>
                _reorderWithinGroup(context, group, oldInner, newInner),
            onAddSet: (exercise) => _addSet(context, exercise),
            onEditName: (exercise) => _editExerciseName(context, exercise),
            onUpdateSet: (updatedSet) => _updateSet(context, updatedSet),
            onDeleteSet: (exerciseId, setId) =>
                _deleteSet(context, exerciseId, setId),
          );
        }
      },
    );
  }

  Future<void> _reorderWorkoutItems(
    BuildContext context,
    List<WorkoutItem> items,
    int oldIndex,
    int newIndex,
  ) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);

    if (newIndex > oldIndex) newIndex -= 1;

    try {
      final reordered = List<WorkoutItem>.from(items);
      final moved = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, moved);

      // Flatten to exercises in display order and assign new orderIndex values
      int globalOrder = 0;
      for (final item in reordered) {
        if (item is StandaloneExercise) {
          if (item.exercise.orderIndex != globalOrder) {
            await provider.updateExercise(
              item.exercise.copyWith(
                orderIndex: globalOrder,
                updatedAt: DateTime.now(),
              ),
            );
          }
          globalOrder++;
        } else {
          final group = item as SupersetGroup;
          for (final ex in group.exercises) {
            if (ex.orderIndex != globalOrder) {
              await provider.updateExercise(
                ex.copyWith(orderIndex: globalOrder, updatedAt: DateTime.now()),
              );
            }
            globalOrder++;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reorderWithinGroup(
    BuildContext context,
    SupersetGroup group,
    int oldIndex,
    int newIndex,
  ) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    if (newIndex > oldIndex) newIndex -= 1;

    try {
      final exercises = List<Exercise>.from(group.exercises);
      final moved = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, moved);

      for (int i = 0; i < exercises.length; i++) {
        if (exercises[i].groupOrderIndex != i) {
          await provider.updateExercise(
            exercises[i].copyWith(
              groupOrderIndex: i,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder superset: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteSuperset(BuildContext context, SupersetGroup group) async {
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final exerciseNames = group.exercises.map((e) => e.name).join(', ');
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Superset',
      content: 'This will delete all exercises in the superset group:',
      itemName: exerciseNames,
      deleteButtonText: 'Delete Superset',
    );

    if (confirmed == true && context.mounted) {
      try {
        await provider.deleteSupersetGroup(
          programId: widget.program.id,
          weekId: widget.week.id,
          workoutId: widget.workout.id,
          supersetGroupId: group.groupId,
        );

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Superset deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete superset: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _addSet(BuildContext context, Exercise exercise) async {
    // Prevent rapid successive additions
    if (_addingSetForExercise.contains(exercise.id)) {
      return;
    }

    setState(() {
      _addingSetForExercise.add(exercise.id);
    });

    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final setId = await provider.createSet(
        programId: widget.program.id,
        weekId: widget.week.id,
        workoutId: widget.workout.id,
        exerciseId: exercise.id,
      );

      if (mounted) {
        setState(() {
          _addingSetForExercise.remove(exercise.id);
        });

        if (setId != null) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Set added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to add set: ${provider.error ?? "Unknown error"}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addingSetForExercise.remove(exercise.id);
        });

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
      return;
    }

    // Show PR banner when user checks off a set (the natural "set done" moment)
    if (updatedSet.checked && mounted) {
      final exercises = provider.exercises;
      final exercise = exercises.cast<Exercise?>().firstWhere(
        (e) => e?.id == updatedSet.exerciseId,
        orElse: () => null,
      );
      if (exercise != null) {
        final pr = await provider.checkForPersonalRecord(updatedSet, exercise);
        if (pr != null && context.mounted) {
          PRNotificationBanner.show(context, pr);
        }
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
        final success = await provider.deleteSet(
          widget.program.id,
          widget.week.id,
          widget.workout.id,
          exerciseId,
          setId,
        );

        if (mounted && success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Set deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (mounted && !success) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete set: ${provider.error ?? "Unknown error"}'),
              backgroundColor: Theme.of(context).colorScheme.error,
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

  void _deleteExercise(BuildContext context, Exercise exercise) async {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Fetch cascade counts before showing dialog
    final cascadeCounts = await programProvider.getCascadeDeleteCounts(
      programId: widget.program.id,
      weekId: widget.week.id,
      workoutId: widget.workout.id,
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
        // Use full delete method with explicit IDs (not deleteExerciseById)
        // deleteExerciseById requires _selectedWorkout to be set, but this screen
        // receives workout as a navigation parameter
        final success = await programProvider.deleteExercise(
          widget.program.id,
          widget.week.id,
          widget.workout.id,
          exercise.id,
        );

        if (context.mounted && success) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Exercise "${exercise.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (context.mounted && !success) {
          final errorColor = Theme.of(context).colorScheme.error;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete exercise: ${programProvider.error ?? "Unknown error"}'),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  void _saveAsTemplate(BuildContext context) {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final exercises = programProvider.exercises;

    // Convert exercises to template format
    final templateExercises = exercises.map((exercise) {
      final sets = programProvider.getSetsForExercise(exercise.id);
      return TemplateExercise(
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
      );
    }).toList();

    SaveAsTemplateHelper.handleSaveAsTemplate(
      context: context,
      itemType: 'Workout',
      itemName: widget.workout.name,
      itemDescription: widget.workout.notes,
      onSave: (name, description) async {
        final templateProvider = Provider.of<TemplateProvider>(context, listen: false);
        final result = await templateProvider.saveWorkoutAsTemplate(
          name: name,
          description: description,
          exercises: templateExercises,
        );

        if (result == null && context.mounted) {
          throw Exception(templateProvider.error ?? 'Failed to save template');
        }
      },
    );
  }

  void _addExercise(BuildContext context) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    // Navigate to exercise picker and get selected exercise data
    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(),
      ),
    );

    if (result != null && mounted) {
      // Extract exercise data from picker result
      final String name = result['name'] as String;
      final ExerciseType exerciseType = result['exerciseType'] as ExerciseType;
      final int setCount = result['setCount'] as int? ?? 1;

      // Create the exercise in the workout with specified number of sets
      final exerciseId = await provider.createExercise(
        programId: widget.program.id,
        weekId: widget.week.id,
        workoutId: widget.workout.id,
        name: name,
        exerciseType: exerciseType,
        setCount: setCount,
      );

      if (exerciseId != null && mounted) {
        // Refresh exercises list and load all sets for the workout
        provider.loadExercises(
          widget.program.id,
          widget.week.id,
          widget.workout.id,
        );

        await provider.loadAllSetsForWorkout(
          programId: widget.program.id,
          weekId: widget.week.id,
          workoutId: widget.workout.id,
        );

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Added "$name" with $setCount set${setCount > 1 ? 's' : ''} to workout'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to add exercise: ${provider.error ?? "Unknown error"}'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Add Exercise'),
              onTap: () {
                Navigator.pop(context);
                _addExercise(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Add Superset'),
              subtitle: const Text('Select 2+ exercises to pair together'),
              onTap: () {
                Navigator.pop(context);
                _addSuperset(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addSuperset(BuildContext context) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final results = await navigator.push<List<Map<String, dynamic>>>(
      MaterialPageRoute(
        builder: (context) => const ExercisePickerScreen(isMultiSelect: true),
      ),
    );

    if (results == null || !mounted) return;

    if (results.length < 2) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 exercises to create a superset'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final exercises = results
        .map((r) => (
              name: r['name'] as String,
              exerciseType: r['exerciseType'] as ExerciseType,
            ))
        .toList();
    final setCount = (results.first['setCount'] as int?) ?? 3;

    final ids = await provider.createSuperset(
      programId: widget.program.id,
      weekId: widget.week.id,
      workoutId: widget.workout.id,
      exercises: exercises,
      setCount: setCount,
    );

    if (!mounted) return;

    if (ids != null) {
      await provider.loadAllSetsForWorkout(
        programId: widget.program.id,
        weekId: widget.week.id,
        workoutId: widget.workout.id,
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Superset added with ${ids.length} exercises'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content:
              Text('Failed to add superset: ${provider.error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
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
      programId: widget.program.id,
      weekId: widget.week.id,
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
