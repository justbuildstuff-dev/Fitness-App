import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';

class CreateSetScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;
  final Exercise exercise;

  const CreateSetScreen({
    super.key,
    required this.program,
    required this.week,
    required this.workout,
    required this.exercise,
  });

  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _durationSecondsController = TextEditingController();
  final _distanceController = TextEditingController();
  final _restTimeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCreating = false;

  // Track which fields are relevant for this exercise type
  late List<String> _requiredFields;
  late List<String> _optionalFields;

  @override
  void initState() {
    super.initState();
    _requiredFields = widget.exercise.requiredSetFields;
    _optionalFields = widget.exercise.optionalSetFields;
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    _distanceController.dispose();
    _restTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Set'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createSet,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Info
            _buildHeaderInfo(),
            
            const SizedBox(height: 24),

            // Exercise Type Fields
            ..._buildFieldsForExerciseType(),

            const SizedBox(height: 16),

            // Notes (always optional)
            _buildNotesField(),

            const SizedBox(height: 32),

            // Helper Text
            _buildHelperText(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adding set to:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(widget.exercise.exerciseType.displayName),
              backgroundColor: _getTypeColor().withOpacity(0.1),
              labelStyle: TextStyle(
                color: _getTypeColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForExerciseType() {
    final fields = <Widget>[];

    // Reps field (for strength, bodyweight, custom)
    if (_requiredFields.contains('reps') || _optionalFields.contains('reps')) {
      fields.add(_buildRepsField());
      fields.add(const SizedBox(height: 16));
    }

    // Weight field (for strength, custom)
    if (_requiredFields.contains('weight') || _optionalFields.contains('weight')) {
      fields.add(_buildWeightField());
      fields.add(const SizedBox(height: 16));
    }

    // Duration field (for cardio, time-based, custom)
    if (_requiredFields.contains('duration') || _optionalFields.contains('duration')) {
      fields.add(_buildDurationField());
      fields.add(const SizedBox(height: 16));
    }

    // Distance field (for cardio, time-based, custom)
    if (_requiredFields.contains('distance') || _optionalFields.contains('distance')) {
      fields.add(_buildDistanceField());
      fields.add(const SizedBox(height: 16));
    }

    // Rest Time field (for strength, bodyweight, custom)
    if (_requiredFields.contains('restTime') || _optionalFields.contains('restTime')) {
      fields.add(_buildRestTimeField());
      fields.add(const SizedBox(height: 16));
    }

    return fields;
  }

  Widget _buildRepsField() {
    return TextFormField(
      controller: _repsController,
      decoration: InputDecoration(
        labelText: 'Reps${_requiredFields.contains('reps') ? ' *' : ''}',
        hintText: 'Number of repetitions',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.repeat),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (_requiredFields.contains('reps') && (value == null || value.trim().isEmpty)) {
          return 'Please enter number of reps';
        }
        if (value != null && value.trim().isNotEmpty) {
          final reps = int.tryParse(value);
          if (reps == null || reps < 0) {
            return 'Please enter a valid number of reps';
          }
        }
        return null;
      },
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: InputDecoration(
        labelText: 'Weight${_requiredFields.contains('weight') ? ' *' : ''} (kg)',
        hintText: 'Weight in kilograms',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.fitness_center),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (_requiredFields.contains('weight') && (value == null || value.trim().isEmpty)) {
          return 'Please enter weight';
        }
        if (value != null && value.trim().isNotEmpty) {
          final weight = double.tryParse(value);
          if (weight == null || weight < 0) {
            return 'Please enter a valid weight';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDurationField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _durationMinutesController,
            decoration: InputDecoration(
              labelText: 'Minutes${_requiredFields.contains('duration') ? ' *' : ''}',
              hintText: '0',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.schedule),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (_requiredFields.contains('duration')) {
                final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
                final seconds = int.tryParse(_durationSecondsController.text) ?? 0;
                if (minutes == 0 && seconds == 0) {
                  return 'Duration required';
                }
              }
              if (value != null && value.trim().isNotEmpty) {
                final minutes = int.tryParse(value);
                if (minutes == null || minutes < 0) {
                  return 'Invalid';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _durationSecondsController,
            decoration: const InputDecoration(
              labelText: 'Seconds',
              hintText: '0',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final seconds = int.tryParse(value);
                if (seconds == null || seconds < 0 || seconds >= 60) {
                  return 'Must be 0-59';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceField() {
    return TextFormField(
      controller: _distanceController,
      decoration: InputDecoration(
        labelText: 'Distance${_requiredFields.contains('distance') ? ' *' : ''} (km)',
        hintText: 'Distance in kilometers',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.straighten),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (_requiredFields.contains('distance') && (value == null || value.trim().isEmpty)) {
          return 'Please enter distance';
        }
        if (value != null && value.trim().isNotEmpty) {
          final distance = double.tryParse(value);
          if (distance == null || distance < 0) {
            return 'Please enter a valid distance';
          }
        }
        return null;
      },
    );
  }

  Widget _buildRestTimeField() {
    return TextFormField(
      controller: _restTimeController,
      decoration: InputDecoration(
        labelText: 'Rest Time${_requiredFields.contains('restTime') ? ' *' : ''} (seconds)',
        hintText: 'Rest time in seconds',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.pause),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (_requiredFields.contains('restTime') && (value == null || value.trim().isEmpty)) {
          return 'Please enter rest time';
        }
        if (value != null && value.trim().isNotEmpty) {
          final restTime = int.tryParse(value);
          if (restTime == null || restTime < 0) {
            return 'Please enter a valid rest time';
          }
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any notes for this set',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
      ),
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildHelperText() {
    return Container(
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
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.exercise.exerciseType.displayName} Exercise',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getExerciseTypeDescription(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (_requiredFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Required fields: ${_requiredFields.map(_formatFieldName).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getExerciseTypeDescription() {
    switch (widget.exercise.exerciseType) {
      case ExerciseType.strength:
        return 'Track repetitions and weight. Add rest time to track recovery between sets.';
      case ExerciseType.cardio:
        return 'Track duration and optionally distance for cardio activities.';
      case ExerciseType.timeBased:
        return 'Track duration and optionally distance for time-based exercises.';
      case ExerciseType.bodyweight:
        return 'Track repetitions for bodyweight movements. Add rest time if desired.';
      case ExerciseType.custom:
        return 'Track any combination of metrics that make sense for this exercise.';
    }
  }

  String _formatFieldName(String field) {
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

  void _createSet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check that at least one metric is provided
    final hasReps = _repsController.text.trim().isNotEmpty;
    final hasDuration = _durationMinutesController.text.trim().isNotEmpty || 
                       _durationSecondsController.text.trim().isNotEmpty;
    final hasDistance = _distanceController.text.trim().isNotEmpty;
    final hasWeight = _weightController.text.trim().isNotEmpty;

    if (!hasReps && !hasDuration && !hasDistance && !hasWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one metric'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);

    // Parse values
    final reps = _repsController.text.trim().isEmpty 
        ? null 
        : int.tryParse(_repsController.text);
    
    final weight = _weightController.text.trim().isEmpty 
        ? null 
        : double.tryParse(_weightController.text);
    
    // Convert minutes and seconds to total seconds
    int? duration;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    final seconds = int.tryParse(_durationSecondsController.text) ?? 0;
    if (minutes > 0 || seconds > 0) {
      duration = minutes * 60 + seconds;
    }
    
    // Convert km to meters for storage
    final distanceKm = _distanceController.text.trim().isEmpty 
        ? null 
        : double.tryParse(_distanceController.text);
    final distance = distanceKm != null ? distanceKm * 1000 : null;
    
    final restTime = _restTimeController.text.trim().isEmpty 
        ? null 
        : int.tryParse(_restTimeController.text);

    final setId = await programProvider.createSet(
      programId: widget.program.id,
      weekId: widget.week.id,
      workoutId: widget.workout.id,
      exerciseId: widget.exercise.id,
      reps: reps,
      weight: weight,
      duration: duration,
      distance: distance,
      restTime: restTime,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    setState(() {
      _isCreating = false;
    });

    if (mounted) {
      if (setId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set added successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              programProvider.error ?? 'Failed to add set',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}