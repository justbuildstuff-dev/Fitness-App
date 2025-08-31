import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../models/program.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import 'program_detail_screen.dart';
import 'create_program_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        elevation: 0,
      ),
      body: Consumer<ProgramProvider>(
        builder: (context, programProvider, child) {
          if (programProvider.isLoadingPrograms) {
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
                    'Error loading programs',
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
                      programProvider.loadPrograms();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (programProvider.programs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Programs Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first workout program to get started',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateProgram(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Program'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              programProvider.loadPrograms();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: programProvider.programs.length,
              itemBuilder: (context, index) {
                final program = programProvider.programs[index];
                return _ProgramCard(
                  program: program,
                  onTap: () => _navigateToProgram(context, program),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateProgram(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateProgram(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateProgramScreen(),
      ),
    );
  }

  void _navigateToProgram(BuildContext context, Program program) {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    programProvider.selectProgram(program);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(program: program),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.fitness_center,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          program.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.description != null) ...[
              const SizedBox(height: 4),
              Text(
                program.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(program.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                if (program.updatedAt != program.createdAt) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${_formatDate(program.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editProgram(context),
              tooltip: 'Edit program',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteProgram(context),
              tooltip: 'Delete program',
            ),
          ],
        ),
      ),
    );
  }

  void _editProgram(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProgramScreen(program: program),
      ),
    );
    
    if (result == true) {
      // Program was updated successfully - no action needed as UI updates via stream
    }
  }

  void _deleteProgram(BuildContext context) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Program',
      content: 'This will permanently delete "${program.name}" and all its weeks, '
               'workouts, exercises, and sets. This action cannot be undone.',
      deleteButtonText: 'Delete Program',
    );

    if (confirmed == true) {
      try {
        final programProvider = Provider.of<ProgramProvider>(context, listen: false);
        await programProvider.deleteProgram(program.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Program "${program.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete program: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}