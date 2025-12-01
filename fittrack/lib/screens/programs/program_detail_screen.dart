import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../models/week.dart';
import '../../widgets/delete_confirmation_dialog.dart';
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
                        week: week,
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
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit program screen
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

  void _navigateToCreateWeek(BuildContext context) async {
    final navigator = Navigator.of(context);
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => CreateWeekScreen(program: widget.program),
      ),
    );
    
    // Refresh weeks list when returning from create week screen
    if (mounted) {
      programProvider.loadWeeks(widget.program.id);
    }
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
  final Week week;
  final VoidCallback onTap;

  const _WeekCard({
    required this.week,
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
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${week.order}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        title: Text(
          week.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: week.notes != null
            ? Text(
                week.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: PopupMenuButton<String>(
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
        onTap: onTap,
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
        await programProvider.deleteWeekById(week.id);

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