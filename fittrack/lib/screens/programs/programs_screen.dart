import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../providers/template_provider.dart';
import '../../models/program.dart';
import '../../models/navigation_section.dart';
import '../../models/templates/templates.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/error_display.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/create_options_sheet.dart';
import '../templates/template_picker_screen.dart';
import '../templates/template_preview_sheet.dart';
import '../../widgets/returning_user_banner.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/paywall_screen.dart';
import 'program_detail_screen.dart';
import 'create_program_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
            return ErrorDisplay(
              message: 'Unable to load your programs. Please check your connection and try again.',
              technicalError: programProvider.error,
              onRetry: () {
                // Get fresh provider reference in case it was recreated
                final provider = Provider.of<ProgramProvider>(context, listen: false);
                provider.clearError();
                provider.loadPrograms();
              },
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Programs Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first workout program to get started',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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

          return Column(
            children: [
              const ReturningUserBanner(),
              Expanded(
                child: RefreshIndicator(
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateProgram(context),
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const GlobalBottomNavBar(
        currentSection: NavigationSection.programs,
      ),
    );
  }

  void _navigateToCreateProgram(BuildContext context) async {
    final sub = context.read<SubscriptionProvider>();
    final programCount = context.read<ProgramProvider>().programs.length;
    if (sub.isFree && programCount >= sub.maxPrograms) {
      PaywallScreen.show(
        context,
        headline: 'You\'ve built 3 programs. Serious lifters run more.',
        subtext: 'Unlock unlimited programs with Pro.',
      );
      return;
    }

    final option = await CreateOptionsSheet.show(
      context,
      itemType: 'Program',
      startFreshDescription: 'Create a blank program and add weeks manually',
      fromTemplateDescription: 'Start with a pre-built or saved program template',
    );

    if (option == null || !context.mounted) return;

    if (option == CreateOption.startFresh) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreateProgramScreen(),
        ),
      );
    } else if (option == CreateOption.fromTemplate) {
      _navigateToTemplatePicker(context);
    }
  }

  void _navigateToTemplatePicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Consumer<TemplateProvider>(
          builder: (context, templateProvider, _) {
            final allTemplates = [
              ...templateProvider.prebuiltPrograms,
              ...templateProvider.programTemplates,
            ];

            return TemplatePickerScreen<ProgramTemplate>(
              title: 'Select Program Template',
              templates: allTemplates,
              isLoading: templateProvider.isLoadingPrebuilt,
              error: templateProvider.error,
              isPrebuilt: (template) => template.isPrebuilt,
              showSourceFilter: true,
              itemBuilder: (context, template) => ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: template.isPrebuilt
                        ? Theme.of(context).colorScheme.tertiaryContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    template.isPrebuilt ? Icons.star : Icons.fitness_center,
                    color: template.isPrebuilt
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${template.weekCount} ${template.weekCount == 1 ? 'week' : 'weeks'} · ${template.totalWorkoutCount} workouts',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
              onSelect: (template) async {
                final sub = context.read<SubscriptionProvider>();
                if (sub.isFree && template.isPrebuilt) {
                  PaywallScreen.show(
                    context,
                    headline: 'Start with an expert-built program.',
                    subtext: '6+ structured programs included with Pro.',
                  );
                  return;
                }
                // Show preview sheet
                final confirmed = await ProgramTemplatePreviewSheet.show(
                  context,
                  template: template,
                );

                if (confirmed == true && context.mounted) {
                  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
                  // Apply the template
                  final existingNames = programProvider.programs
                      .map((p) => p.name)
                      .toList();

                  final programId = await templateProvider.applyProgramTemplate(
                    template: template,
                    existingProgramNames: existingNames,
                  );

                  if (programId != null && context.mounted) {
                    // Pop back to programs screen
                    Navigator.of(context).pop();

                    // Refresh programs list
                    programProvider.loadPrograms();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Program created from "${template.name}"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(templateProvider.error ?? 'Failed to create program'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          emptyStateWidget: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard_customize,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Templates Available',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Save a program as a template to use it here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
            );
          },
        ),
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
    // Semantics wrapper exposes the card as a labelled button in the accessibility
    // tree so Playwright E2E tests can target it with getByRole('button', {name}).
    // Flutter does not expose ListTile.onTap as flt-tappable when the tile has
    // interactive trailing children — only the trailing row gets flt-tappable.
    // excludeSemantics is intentionally omitted so the inner edit/delete buttons
    // remain individually reachable by screen readers (WCAG 4.1.2 compliance).
    // Flutter's flt-tappable click handlers call stopPropagation, so activating
    // an inner button does not bubble up to this outer card button.
    return Semantics(
      label: program.name,
      button: true,
      onTap: onTap,
      child: Card(
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Created ${_formatDate(program.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (program.updatedAt != program.createdAt) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Updated ${_formatDate(program.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
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
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Program',
      content: 'This will permanently delete "${program.name}" and all its weeks, '
               'workouts, exercises, and sets. This action cannot be undone.',
      deleteButtonText: 'Delete Program',
    );

    if (confirmed == true) {
      try {
        await programProvider.deleteProgram(program.id);
        
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Program "${program.name}" deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete program: $e'),
              backgroundColor: errorColor,
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