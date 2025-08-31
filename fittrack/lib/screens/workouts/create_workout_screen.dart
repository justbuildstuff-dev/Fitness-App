import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout? workout; // null for create, populated for edit

  const CreateWorkoutScreen({
    super.key,
    required this.program,
    required this.week,
    this.workout,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedDayOfWeek;
  bool _isLoading = false;

  bool get _isEditing => widget.workout != null;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // Populate fields for editing
      _nameController.text = widget.workout!.name;
      _notesController.text = widget.workout!.notes ?? '';
      _selectedDayOfWeek = widget.workout!.dayOfWeek;
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
        title: Text(_isEditing ? 'Edit Workout' : 'Create Workout'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveWorkout,
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
                      _isEditing ? 'Editing workout for:' : 'Creating workout for:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.program.name} → ${widget.week.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Workout Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name *',
                hintText: 'e.g., Push Day, Upper Body, Cardio',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a workout name';
                }
                if (value.trim().length > 200) {
                  return 'Workout name must be 200 characters or less';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Day of Week (Optional)
            DropdownButtonFormField<int?>(
              value: _selectedDayOfWeek,
              decoration: const InputDecoration(
                labelText: 'Day of Week (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('No specific day'),
                ),
                ...List.generate(_daysOfWeek.length, (index) {
                  return DropdownMenuItem<int>(
                    value: index + 1, // 1-7 for Monday-Sunday
                    child: Text(_daysOfWeek[index]),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDayOfWeek = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Notes (Optional)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any notes or instructions for this workout',
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
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                    '• Give your workout a descriptive name\n'
                    '• Optionally assign it to a specific day\n'
                    '• Use notes to add instructions or reminders\n'
                    '• After creating, you can add exercises to this workout',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  void _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    try {
      if (_isEditing) {
        // Update existing workout
        await programProvider.updateWorkoutFields(
          widget.workout!.id,
          name: _nameController.text.trim(),
          dayOfWeek: _selectedDayOfWeek,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create new workout
        final workoutId = await programProvider.createWorkout(
          programId: widget.program.id,
          weekId: widget.week.id,
          name: _nameController.text.trim(),
          dayOfWeek: _selectedDayOfWeek,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );

        if (mounted) {
          if (workoutId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workout created successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  programProvider.error ?? 'Failed to create workout',
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
            content: Text(_isEditing ? 'Failed to update workout: $e' : 'Failed to create workout: $e'),
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