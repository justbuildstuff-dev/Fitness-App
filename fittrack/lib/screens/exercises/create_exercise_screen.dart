import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';

class CreateExerciseScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;
  final Exercise? exercise; // null for create, populated for edit

  const CreateExerciseScreen({
    super.key,
    required this.program,
    required this.week,
    required this.workout,
    this.exercise,
  });

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  ExerciseType _selectedType = ExerciseType.strength;
  bool _isLoading = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // Populate fields for editing
      _nameController.text = widget.exercise!.name;
      _notesController.text = widget.exercise!.notes ?? '';
      _selectedType = widget.exercise!.exerciseType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exercise' : 'Create Exercise'),
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
            // Header Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Editing exercise for:' : 'Creating exercise for:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.program.name} → ${widget.week.name} → ${widget.workout.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Exercise Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g., Bench Press, Squat, Push-ups',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                if (value.trim().length > 200) {
                  return 'Exercise name must be 200 characters or less';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Exercise Type
            DropdownButtonFormField<ExerciseType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Exercise Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ExerciseType.values.map((type) {
                return DropdownMenuItem<ExerciseType>(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Exercise Type Info
            _buildExerciseTypeInfo(),

            const SizedBox(height: 16),

            // Notes (Optional)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any notes or instructions for this exercise',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 32),

            // Helper Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                    '• Choose the exercise type that matches your activity\n'
                    '• Exercise type determines which fields you can track\n'
                    '• After creating, you can add sets to this exercise\n'
                    '• Use notes for form cues or specific instructions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTypeInfo() {
    String title;
    String description;
    List<String> fields;

    switch (_selectedType) {
      case ExerciseType.strength:
        title = 'Strength Exercise';
        description = 'Track reps and weight for traditional strength training';
        fields = ['Reps (required)', 'Weight (optional)', 'Rest Time (optional)'];
        break;
      case ExerciseType.cardio:
        title = 'Cardio Exercise';
        description = 'Track time and distance for cardiovascular activities';
        fields = ['Duration (required)', 'Distance (optional)'];
        break;
      case ExerciseType.timeBased:
        title = 'Time-based Exercise';
        description = 'Track duration and distance for time-based activities';
        fields = ['Duration (required)', 'Distance (optional)'];
        break;
      case ExerciseType.bodyweight:
        title = 'Bodyweight Exercise';
        description = 'Track reps for bodyweight movements';
        fields = ['Reps (required)', 'Rest Time (optional)'];
        break;
      case ExerciseType.custom:
        title = 'Custom Exercise';
        description = 'Flexible tracking with any combination of metrics';
        fields = ['Any metric (at least one required)'];
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Trackable fields:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...fields.map((field) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '• $field',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    try {
      if (_isEditing) {
        // Update existing exercise
        await programProvider.updateExerciseFields(
          widget.exercise!.id,
          name: _nameController.text.trim(),
          exerciseType: _selectedType,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercise updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create new exercise
        final exerciseId = await programProvider.createExercise(
          programId: widget.program.id,
          weekId: widget.week.id,
          workoutId: widget.workout.id,
          name: _nameController.text.trim(),
          exerciseType: _selectedType,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );

        if (mounted) {
          if (exerciseId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Exercise created successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  programProvider.error ?? 'Failed to create exercise',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Failed to update exercise: $e' : 'Failed to create exercise: $e'),
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