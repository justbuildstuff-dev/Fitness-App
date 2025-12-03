import 'package:flutter/material.dart';

/// Modal dialog for editing set notes and rest time
/// Opens from the notes button in SetRow widget
class SetNotesModal extends StatefulWidget {
  final String? initialNotes;
  final int? initialRestTime; // in seconds
  final int maxNoteLength;

  const SetNotesModal({
    super.key,
    this.initialNotes,
    this.initialRestTime,
    this.maxNoteLength = 250,
  });

  /// Show the modal and return the updated notes and rest time
  /// Returns Map with 'notes' and 'restTime' keys, or null if cancelled
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    String? initialNotes,
    int? initialRestTime,
    int maxNoteLength = 250,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SetNotesModal(
        initialNotes: initialNotes,
        initialRestTime: initialRestTime,
        maxNoteLength: maxNoteLength,
      ),
    );
  }

  @override
  State<SetNotesModal> createState() => _SetNotesModalState();
}

class _SetNotesModalState extends State<SetNotesModal> {
  late TextEditingController _notesController;
  late int _restTimeSeconds;
  int _characterCount = 0;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _restTimeSeconds = widget.initialRestTime ?? 60; // Default 60 seconds
    _characterCount = _notesController.text.length;

    _notesController.addListener(() {
      setState(() {
        _characterCount = _notesController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatRestTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.note_alt,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Set Notes'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notes text field
            TextField(
              controller: _notesController,
              maxLength: widget.maxNoteLength,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Add notes about this set...',
                border: const OutlineInputBorder(),
                helperText: '$_characterCount/${widget.maxNoteLength} characters',
              ),
            ),

            const SizedBox(height: 24),

            // Rest time section
            Text(
              'Rest Time',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            // Rest time slider
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _restTimeSeconds.toDouble(),
                    min: 0,
                    max: 300, // 5 minutes
                    divisions: 60, // 5-second increments
                    label: _formatRestTime(_restTimeSeconds),
                    onChanged: (value) {
                      setState(() {
                        _restTimeSeconds = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _formatRestTime(_restTimeSeconds),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Quick rest time buttons
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _QuickRestButton(
                  label: '30s',
                  seconds: 30,
                  selected: _restTimeSeconds == 30,
                  onTap: () => setState(() => _restTimeSeconds = 30),
                ),
                _QuickRestButton(
                  label: '1m',
                  seconds: 60,
                  selected: _restTimeSeconds == 60,
                  onTap: () => setState(() => _restTimeSeconds = 60),
                ),
                _QuickRestButton(
                  label: '90s',
                  seconds: 90,
                  selected: _restTimeSeconds == 90,
                  onTap: () => setState(() => _restTimeSeconds = 90),
                ),
                _QuickRestButton(
                  label: '2m',
                  seconds: 120,
                  selected: _restTimeSeconds == 120,
                  onTap: () => setState(() => _restTimeSeconds = 120),
                ),
                _QuickRestButton(
                  label: '3m',
                  seconds: 180,
                  selected: _restTimeSeconds == 180,
                  onTap: () => setState(() => _restTimeSeconds = 180),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              'restTime': _restTimeSeconds == 0 ? null : _restTimeSeconds,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Quick rest time selection button
class _QuickRestButton extends StatelessWidget {
  final String label;
  final int seconds;
  final bool selected;
  final VoidCallback onTap;

  const _QuickRestButton({
    required this.label,
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
