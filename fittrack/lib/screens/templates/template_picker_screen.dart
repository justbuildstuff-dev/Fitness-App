import 'package:flutter/material.dart';
import '../../models/templates/templates.dart';

/// Template source filter for distinguishing pre-built vs user templates
enum TemplateSource {
  all,
  prebuilt,
  user;

  String get displayName {
    switch (this) {
      case TemplateSource.all:
        return 'All';
      case TemplateSource.prebuilt:
        return 'Pre-built';
      case TemplateSource.user:
        return 'My Templates';
    }
  }
}

/// Generic template picker screen that works for all template types.
///
/// Shows a list of templates with loading, error, and empty states.
/// Templates can be filtered by source (pre-built vs user-created).
class TemplatePickerScreen<T> extends StatefulWidget {
  /// Screen title (e.g., "Select Workout Template")
  final String title;

  /// List of templates to display
  final List<T> templates;

  /// Builder for each template list item
  final Widget Function(BuildContext context, T template) itemBuilder;

  /// Callback when a template is selected
  final void Function(T template) onSelect;

  /// Whether data is loading
  final bool isLoading;

  /// Error message to display
  final String? error;

  /// Callback to retry loading on error
  final VoidCallback? onRetry;

  /// Widget to show when no templates exist
  final Widget? emptyStateWidget;

  /// Function to check if a template is pre-built
  final bool Function(T template)? isPrebuilt;

  /// Whether to show the source filter chips
  final bool showSourceFilter;

  const TemplatePickerScreen({
    super.key,
    required this.title,
    required this.templates,
    required this.itemBuilder,
    required this.onSelect,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.emptyStateWidget,
    this.isPrebuilt,
    this.showSourceFilter = true,
  });

  @override
  State<TemplatePickerScreen<T>> createState() =>
      _TemplatePickerScreenState<T>();
}

class _TemplatePickerScreenState<T> extends State<TemplatePickerScreen<T>> {
  TemplateSource _selectedSource = TemplateSource.all;

  List<T> get _filteredTemplates {
    if (!widget.showSourceFilter ||
        widget.isPrebuilt == null ||
        _selectedSource == TemplateSource.all) {
      return widget.templates;
    }

    return widget.templates.where((template) {
      final isPrebuilt = widget.isPrebuilt!(template);
      return _selectedSource == TemplateSource.prebuilt
          ? isPrebuilt
          : !isPrebuilt;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (widget.isLoading && widget.templates.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (widget.error != null && widget.templates.isEmpty) {
      return _buildErrorState();
    }

    // Empty state
    if (widget.templates.isEmpty) {
      return widget.emptyStateWidget ?? _buildDefaultEmptyState();
    }

    // Content
    return Column(
      children: [
        if (widget.showSourceFilter && widget.isPrebuilt != null)
          _buildSourceFilter(),
        _buildResultsCount(),
        Expanded(
          child: _filteredTemplates.isEmpty
              ? _buildFilteredEmptyState()
              : _buildTemplateList(),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
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
              widget.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No templates available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create templates from your workouts\nto reuse them later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    final sourceText = _selectedSource == TemplateSource.prebuilt
        ? 'pre-built'
        : 'user-created';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No $sourceText templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSource = TemplateSource.all;
                });
              },
              child: const Text('Show all templates'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TemplateSource.values.map((source) {
            final isSelected = _selectedSource == source;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(source.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSource = source;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    final count = _filteredTemplates.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$count template${count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return InkWell(
          onTap: () => widget.onSelect(template),
          borderRadius: BorderRadius.circular(12),
          child: widget.itemBuilder(context, template),
        );
      },
    );
  }
}

/// A default template list tile for workout templates.
class WorkoutTemplateListTile extends StatelessWidget {
  final WorkoutTemplate template;
  final bool showPrebuiltBadge;

  const WorkoutTemplateListTile({
    super.key,
    required this.template,
    this.showPrebuiltBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = template.exercises.length;
    final totalSets = template.exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.sets.length,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showPrebuiltBadge && template.isPrebuilt)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pre-built',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}, $totalSets set${totalSets == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  if (template.description != null &&
                      template.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      template.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// A default template list tile for week templates.
class WeekTemplateListTile extends StatelessWidget {
  final WeekTemplate template;
  final bool showPrebuiltBadge;

  const WeekTemplateListTile({
    super.key,
    required this.template,
    this.showPrebuiltBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final workoutCount = template.workouts.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showPrebuiltBadge && template.isPrebuilt)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pre-built',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$workoutCount workout${workoutCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  if (template.description != null &&
                      template.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      template.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// A default template list tile for program templates.
class ProgramTemplateListTile extends StatelessWidget {
  final ProgramTemplate template;
  final bool showPrebuiltBadge;

  const ProgramTemplateListTile({
    super.key,
    required this.template,
    this.showPrebuiltBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final weekCount = template.weeks.length;
    final totalWorkouts = template.weeks.fold<int>(
      0,
      (sum, week) => sum + week.workouts.length,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showPrebuiltBadge && template.isPrebuilt)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pre-built',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$weekCount week${weekCount == 1 ? '' : 's'}, $totalWorkouts workout${totalWorkouts == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  if (template.description != null &&
                      template.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      template.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
