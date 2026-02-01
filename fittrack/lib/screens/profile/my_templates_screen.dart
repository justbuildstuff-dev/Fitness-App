import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/template_provider.dart';
import '../../models/templates/templates.dart';

/// Screen for managing the user's saved templates.
/// Accessible from the Profile/Settings screen.
/// Shows tabs for Workout, Week, and Program templates.
class MyTemplatesScreen extends StatefulWidget {
  const MyTemplatesScreen({super.key});

  @override
  State<MyTemplatesScreen> createState() => _MyTemplatesScreenState();
}

class _MyTemplatesScreenState extends State<MyTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Templates'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Workouts'),
            Tab(text: 'Weeks'),
            Tab(text: 'Programs'),
          ],
        ),
      ),
      body: Consumer<TemplateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(context, provider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _WorkoutTemplatesTab(
                templates: provider.workoutTemplates,
                onDelete: (template) => _confirmDeleteWorkoutTemplate(
                  context,
                  provider,
                  template,
                ),
              ),
              _WeekTemplatesTab(
                templates: provider.weekTemplates,
                onDelete: (template) => _confirmDeleteWeekTemplate(
                  context,
                  provider,
                  template,
                ),
              ),
              _ProgramTemplatesTab(
                templates: provider.programTemplates,
                onDelete: (template) => _confirmDeleteProgramTemplate(
                  context,
                  provider,
                  template,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, TemplateProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Failed to load templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.clearError(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteWorkoutTemplate(
    BuildContext context,
    TemplateProvider provider,
    WorkoutTemplate template,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await _showDeleteConfirmation(
      context,
      'Delete Workout Template',
      'Are you sure you want to delete "${template.name}"?',
    );

    if (confirmed == true) {
      final success = await provider.deleteWorkoutTemplate(template.id);
      _showDeleteResultWithMessenger(
          scaffoldMessenger, errorColor, success, 'Workout template');
    }
  }

  Future<void> _confirmDeleteWeekTemplate(
    BuildContext context,
    TemplateProvider provider,
    WeekTemplate template,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await _showDeleteConfirmation(
      context,
      'Delete Week Template',
      'Are you sure you want to delete "${template.name}"?',
    );

    if (confirmed == true) {
      final success = await provider.deleteWeekTemplate(template.id);
      _showDeleteResultWithMessenger(
          scaffoldMessenger, errorColor, success, 'Week template');
    }
  }

  Future<void> _confirmDeleteProgramTemplate(
    BuildContext context,
    TemplateProvider provider,
    ProgramTemplate template,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await _showDeleteConfirmation(
      context,
      'Delete Program Template',
      'Are you sure you want to delete "${template.name}"?',
    );

    if (confirmed == true) {
      final success = await provider.deleteProgramTemplate(template.id);
      _showDeleteResultWithMessenger(
          scaffoldMessenger, errorColor, success, 'Program template');
    }
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String title,
    String content,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
  }

  void _showDeleteResultWithMessenger(
    ScaffoldMessengerState messenger,
    Color errorColor,
    bool success,
    String itemType,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '$itemType deleted successfully'
              : 'Failed to delete $itemType',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? null : errorColor,
      ),
    );
  }
}

/// Tab content for workout templates
class _WorkoutTemplatesTab extends StatelessWidget {
  final List<WorkoutTemplate> templates;
  final void Function(WorkoutTemplate) onDelete;

  const _WorkoutTemplatesTab({
    required this.templates,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.fitness_center,
        title: 'No Workout Templates',
        subtitle: 'Save workouts as templates to reuse them later',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          name: template.name,
          description: template.description,
          subtitle:
              '${template.exerciseCount} exercises \u2022 ${template.totalSetCount} sets',
          icon: Icons.fitness_center,
          iconColor: Theme.of(context).colorScheme.primary,
          onDelete: () => onDelete(template),
        );
      },
    );
  }
}

/// Tab content for week templates
class _WeekTemplatesTab extends StatelessWidget {
  final List<WeekTemplate> templates;
  final void Function(WeekTemplate) onDelete;

  const _WeekTemplatesTab({
    required this.templates,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.calendar_view_week,
        title: 'No Week Templates',
        subtitle: 'Save training weeks as templates to reuse them later',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          name: template.name,
          description: template.description,
          subtitle:
              '${template.workoutCount} workouts \u2022 ${template.totalExerciseCount} exercises',
          icon: Icons.calendar_view_week,
          iconColor: Theme.of(context).colorScheme.secondary,
          onDelete: () => onDelete(template),
        );
      },
    );
  }
}

/// Tab content for program templates
class _ProgramTemplatesTab extends StatelessWidget {
  final List<ProgramTemplate> templates;
  final void Function(ProgramTemplate) onDelete;

  const _ProgramTemplatesTab({
    required this.templates,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.folder_special,
        title: 'No Program Templates',
        subtitle: 'Save entire programs as templates to reuse them later',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TemplateCard(
          name: template.name,
          description: template.description,
          subtitle:
              '${template.weekCount} weeks \u2022 ${template.totalWorkoutCount} workouts',
          icon: Icons.folder_special,
          iconColor: Theme.of(context).colorScheme.tertiary,
          onDelete: () => onDelete(template),
        );
      },
    );
  }
}

/// Empty state widget for template tabs
Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    ),
  );
}

/// Card widget for displaying a template
class _TemplateCard extends StatelessWidget {
  final String name;
  final String? description;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.name,
    this.description,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: onDelete,
              tooltip: 'Delete template',
            ),
          ],
        ),
      ),
    );
  }
}
