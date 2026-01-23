import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/exercise_library_provider.dart';
import '../../models/custom_exercise.dart';
import '../../models/muscle_group.dart';
import '../../models/exercise.dart';

/// Screen for creating or editing a custom exercise.
/// In create mode, exercise parameter is null.
/// In edit mode, exercise parameter contains the exercise to edit.
class CustomExerciseFormScreen extends StatefulWidget {
  /// The exercise to edit, or null if creating a new exercise
  final CustomExercise? exercise;

  const CustomExerciseFormScreen({
    super.key,
    this.exercise,
  });

  @override
  State<CustomExerciseFormScreen> createState() =>
      _CustomExerciseFormScreenState();
}

class _CustomExerciseFormScreenState extends State<CustomExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ExerciseType _selectedType = ExerciseType.strength;
  Set<MuscleGroup> _selectedPrimaryMuscles = {};
  Set<MuscleGroup> _selectedSecondaryMuscles = {};
  bool _isLoading = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Populate fields for editing
      _nameController.text = widget.exercise!.name;
      _selectedType = widget.exercise!.exerciseType;
      _selectedPrimaryMuscles = widget.exercise!.primaryMuscles.toSet();
      _selectedSecondaryMuscles = widget.exercise!.secondaryMuscles.toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseLibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Custom Exercise' : 'Create Custom Exercise'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExercise,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'SAVE' : 'CREATE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Custom exercise limit warning
            if (!_isEditing && !provider.canCreateCustomExercise)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have reached the maximum of $maxCustomExercises custom exercises. Delete one to create a new one.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Exercise count info
            if (!_isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${provider.customExerciseCount}/$maxCustomExercises custom exercises',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ),

            // Exercise Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g., My Special Press',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.fitness_center),
                counterText: '${_nameController.text.length}/$maxCustomExerciseNameLength',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: maxCustomExerciseNameLength,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                if (value.trim().length > maxCustomExerciseNameLength) {
                  return 'Name must be $maxCustomExerciseNameLength characters or less';
                }
                // Check name uniqueness
                if (!provider.isNameAvailable(
                  value.trim(),
                  excludeId: _isEditing ? widget.exercise!.id : null,
                )) {
                  return 'An exercise with this name already exists';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Exercise Type
            Text(
              'Exercise Type *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                // Only show strength and bodyweight per PRD
                _TypeChip(
                  type: ExerciseType.strength,
                  isSelected: _selectedType == ExerciseType.strength,
                  onSelected: () =>
                      setState(() => _selectedType = ExerciseType.strength),
                ),
                _TypeChip(
                  type: ExerciseType.bodyweight,
                  isSelected: _selectedType == ExerciseType.bodyweight,
                  onSelected: () =>
                      setState(() => _selectedType = ExerciseType.bodyweight),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Primary Muscles
            Text(
              'Primary Muscles * (select at least one)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.map((muscle) {
                final isSelected = _selectedPrimaryMuscles.contains(muscle);
                final isSecondary = _selectedSecondaryMuscles.contains(muscle);
                return FilterChip(
                  label: Text(muscle.displayName),
                  selected: isSelected,
                  onSelected: isSecondary
                      ? null // Can't select as primary if already secondary
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPrimaryMuscles.add(muscle);
                            } else {
                              _selectedPrimaryMuscles.remove(muscle);
                            }
                          });
                        },
                  backgroundColor: isSecondary
                      ? Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5)
                      : null,
                );
              }).toList(),
            ),
            if (_selectedPrimaryMuscles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Select at least one primary muscle group',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),

            const SizedBox(height: 24),

            // Secondary Muscles
            Text(
              'Secondary Muscles (optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.map((muscle) {
                final isSelected = _selectedSecondaryMuscles.contains(muscle);
                final isPrimary = _selectedPrimaryMuscles.contains(muscle);
                return FilterChip(
                  label: Text(muscle.displayName),
                  selected: isSelected,
                  onSelected: isPrimary
                      ? null // Can't select as secondary if already primary
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSecondaryMuscles.add(muscle);
                            } else {
                              _selectedSecondaryMuscles.remove(muscle);
                            }
                          });
                        },
                  backgroundColor: isPrimary
                      ? Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5)
                      : null,
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Helper Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Custom exercises can be used in any workout\n'
                    '• Choose meaningful names for easy searching\n'
                    '• Primary muscles are the main focus of the exercise\n'
                    '• Secondary muscles assist in the movement',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delete button (edit mode only)
            if (_isEditing)
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _confirmDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'Delete Exercise',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExercise() async {
    // Validate primary muscles first
    if (_selectedPrimaryMuscles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one primary muscle group'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final provider =
        Provider.of<ExerciseLibraryProvider>(context, listen: false);

    try {
      bool success;

      if (_isEditing) {
        // Update existing exercise
        final updatedExercise = widget.exercise!.copyWith(
          name: _nameController.text.trim(),
          exerciseType: _selectedType,
          primaryMuscles: _selectedPrimaryMuscles.toList(),
          secondaryMuscles: _selectedSecondaryMuscles.toList(),
        );
        success = await provider.updateCustomExercise(updatedExercise);
      } else {
        // Create new exercise
        final exerciseId = await provider.createCustomExercise(
          name: _nameController.text.trim(),
          exerciseType: _selectedType,
          primaryMuscles: _selectedPrimaryMuscles.toList(),
          secondaryMuscles: _selectedSecondaryMuscles.toList(),
        );
        success = exerciseId != null;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Exercise updated successfully!'
                  : 'Exercise created successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true); // Return success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to save exercise'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save exercise: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text(
          'Are you sure you want to delete "${widget.exercise!.name}"?\n\n'
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

    if (confirmed == true) {
      await _deleteExercise();
    }
  }

  Future<void> _deleteExercise() async {
    setState(() {
      _isLoading = true;
    });

    final provider =
        Provider.of<ExerciseLibraryProvider>(context, listen: false);

    try {
      final success =
          await provider.deleteCustomExercise(widget.exercise!.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercise deleted successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true); // Return success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to delete exercise'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete exercise: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _TypeChip extends StatelessWidget {
  final ExerciseType type;
  final bool isSelected;
  final VoidCallback onSelected;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(type.displayName),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}
