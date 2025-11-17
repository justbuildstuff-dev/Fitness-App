import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import 'set_notes_modal.dart';

/// A row widget that displays a single set with inline editing capabilities
/// Fields displayed depend on exercise type (strength, cardio, bodyweight, custom)
class SetRow extends StatefulWidget {
  final ExerciseSet set;
  final ExerciseType exerciseType;
  final bool isLastSet; // If true, delete button is disabled
  final Function(ExerciseSet updatedSet) onUpdate;
  final VoidCallback? onDelete;

  const SetRow({
    super.key,
    required this.set,
    required this.exerciseType,
    required this.isLastSet,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _durationController;
  late TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.set.duration?.toString() ?? '',
    );
    _distanceController = TextEditingController(
      text: widget.set.distance?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _handleCheckboxChange(bool? checked) {
    if (checked == null) return;

    final updatedSet = widget.set.copyWith(
      checked: checked,
      updatedAt: DateTime.now(),
    );

    widget.onUpdate(updatedSet);
  }

  void _handleWeightChange() {
    final value = _weightController.text.trim();
    final weight = value.isEmpty ? null : double.tryParse(value);

    final updatedSet = widget.set.copyWith(
      weight: weight,
      updatedAt: DateTime.now(),
    );

    widget.onUpdate(updatedSet);
  }

  void _handleRepsChange() {
    final value = _repsController.text.trim();
    final reps = value.isEmpty ? null : int.tryParse(value);

    final updatedSet = widget.set.copyWith(
      reps: reps,
      updatedAt: DateTime.now(),
    );

    widget.onUpdate(updatedSet);
  }

  void _handleDurationChange() {
    final value = _durationController.text.trim();
    final duration = value.isEmpty ? null : int.tryParse(value);

    final updatedSet = widget.set.copyWith(
      duration: duration,
      updatedAt: DateTime.now(),
    );

    widget.onUpdate(updatedSet);
  }

  void _handleDistanceChange() {
    final value = _distanceController.text.trim();
    final distance = value.isEmpty ? null : double.tryParse(value);

    final updatedSet = widget.set.copyWith(
      distance: distance,
      updatedAt: DateTime.now(),
    );

    widget.onUpdate(updatedSet);
  }

  Future<void> _handleNotesButtonTap() async {
    final result = await SetNotesModal.show(
      context: context,
      initialNotes: widget.set.notes,
      initialRestTime: widget.set.restTime,
    );

    if (result != null && mounted) {
      final updatedSet = widget.set.copyWith(
        notes: result['notes'] as String?,
        restTime: result['restTime'] as int?,
        updatedAt: DateTime.now(),
      );

      widget.onUpdate(updatedSet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReadOnly = widget.set.checked;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Set number
            SizedBox(
              width: 40,
              child: Text(
                '${widget.set.setNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: 8),

            // Fields based on exercise type
            Expanded(
              child: _buildFieldsForExerciseType(isReadOnly),
            ),

            const SizedBox(width: 8),

            // Notes button
            IconButton(
              icon: Icon(
                widget.set.notes != null && widget.set.notes!.isNotEmpty
                    ? Icons.note_alt
                    : Icons.note_add,
                size: 20,
              ),
              onPressed: isReadOnly ? null : _handleNotesButtonTap,
              tooltip: 'Add notes',
              color: widget.set.notes != null && widget.set.notes!.isNotEmpty
                  ? theme.colorScheme.primary
                  : null,
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: widget.isLastSet || isReadOnly ? null : widget.onDelete,
              tooltip: widget.isLastSet
                  ? 'Cannot delete last set'
                  : 'Delete set',
              color: Colors.red,
              disabledColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),

            // Completion checkbox
            Checkbox(
              value: widget.set.checked,
              onChanged: _handleCheckboxChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsForExerciseType(bool isReadOnly) {
    switch (widget.exerciseType) {
      case ExerciseType.strength:
        return _buildStrengthFields(isReadOnly);
      case ExerciseType.cardio:
      case ExerciseType.timeBased:
        return _buildCardioFields(isReadOnly);
      case ExerciseType.bodyweight:
        return _buildBodyweightFields(isReadOnly);
      case ExerciseType.custom:
        return _buildCustomFields(isReadOnly);
    }
  }

  Widget _buildStrengthFields(bool isReadOnly) {
    return Row(
      children: [
        // Weight field (optional)
        Expanded(
          flex: 2,
          child: TextField(
            controller: _weightController,
            enabled: !isReadOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Weight',
              hintText: '0',
              suffixText: 'kg',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleWeightChange(),
          ),
        ),

        const SizedBox(width: 8),

        // Reps field (required)
        Expanded(
          flex: 2,
          child: TextField(
            controller: _repsController,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Reps *',
              hintText: '0',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleRepsChange(),
          ),
        ),
      ],
    );
  }

  Widget _buildCardioFields(bool isReadOnly) {
    return Row(
      children: [
        // Duration field (required)
        Expanded(
          flex: 2,
          child: TextField(
            controller: _durationController,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Duration *',
              hintText: '0',
              suffixText: 'sec',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleDurationChange(),
          ),
        ),

        const SizedBox(width: 8),

        // Distance field (optional)
        Expanded(
          flex: 2,
          child: TextField(
            controller: _distanceController,
            enabled: !isReadOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Distance',
              hintText: '0',
              suffixText: 'm',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleDistanceChange(),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyweightFields(bool isReadOnly) {
    return Row(
      children: [
        // Reps field (required)
        Expanded(
          flex: 2,
          child: TextField(
            controller: _repsController,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Reps *',
              hintText: '0',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleRepsChange(),
          ),
        ),

        // Spacer to match other row layouts
        const Expanded(flex: 2, child: SizedBox()),
      ],
    );
  }

  Widget _buildCustomFields(bool isReadOnly) {
    // For custom exercises, show all available fields
    return Row(
      children: [
        // Reps field
        Expanded(
          flex: 2,
          child: TextField(
            controller: _repsController,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Reps',
              hintText: '0',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleRepsChange(),
          ),
        ),

        const SizedBox(width: 8),

        // Duration field
        Expanded(
          flex: 2,
          child: TextField(
            controller: _durationController,
            enabled: !isReadOnly,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Time',
              hintText: '0',
              suffixText: 's',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(
              color: isReadOnly
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
            onChanged: (_) => _handleDurationChange(),
          ),
        ),
      ],
    );
  }
}
