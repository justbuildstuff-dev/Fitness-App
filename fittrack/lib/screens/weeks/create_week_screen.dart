import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';

class CreateWeekScreen extends StatefulWidget {
  final Program program;

  const CreateWeekScreen({
    super.key,
    required this.program,
  });

  @override
  State<CreateWeekScreen> createState() => _CreateWeekScreenState();
}

class _CreateWeekScreenState extends State<CreateWeekScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Auto-generate week name based on existing weeks
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final nextWeekNumber = programProvider.weeks.length + 1;
    _nameController.text = 'Week $nextWeekNumber';
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
        title: const Text('Create Week'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createWeek,
            child: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('CREATE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Consumer<ProgramProvider>(
                    builder: (context, programProvider, child) {
                      final nextWeekNumber = programProvider.weeks.length + 1;
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '$nextWeekNumber',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create New Week',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a new week to "${widget.program.name}"',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Week Name
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Week Name',
                hintText: 'e.g., Week 1, Foundation Week',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
                helperText: 'Give this week a descriptive name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a week name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Week Notes
            TextFormField(
              controller: _notesController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add notes about this week\'s focus, goals, or special instructions...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onFieldSubmitted: (_) => _createWeek(),
            ),
            const SizedBox(height: 32),

            // Tips Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Week Planning Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _TipItem(
                      text: 'After creating your week, add workouts for different days',
                    ),
                    const _TipItem(
                      text: 'Each workout can contain multiple exercises with sets',
                    ),
                    const _TipItem(
                      text: 'Use the duplicate feature to copy successful weeks',
                    ),
                    const _TipItem(
                      text: 'Order your weeks logically for progression tracking',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createWeek() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    
    final weekId = await programProvider.createWeek(
      programId: widget.program.id,
      name: _nameController.text,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text,
    );

    setState(() {
      _isCreating = false;
    });

    if (weekId != null) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Week created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(programProvider.error ?? 'Failed to create week'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}