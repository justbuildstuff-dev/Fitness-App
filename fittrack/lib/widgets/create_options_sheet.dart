import 'package:flutter/material.dart';

/// Option for how to create a new item
enum CreateOption {
  /// Create from scratch with blank fields
  startFresh,

  /// Create using a template
  fromTemplate,
}

/// A bottom sheet that presents options for creating new items.
/// Users can choose to start fresh or use a template.
class CreateOptionsSheet extends StatelessWidget {
  /// The type of item being created (e.g., "Program", "Week", "Workout")
  final String itemType;

  /// Description for the "Start Fresh" option
  final String? startFreshDescription;

  /// Description for the "From Template" option
  final String? fromTemplateDescription;

  /// Whether templates are available
  final bool templatesAvailable;

  const CreateOptionsSheet({
    super.key,
    required this.itemType,
    this.startFreshDescription,
    this.fromTemplateDescription,
    this.templatesAvailable = true,
  });

  /// Shows the sheet and returns the selected option, or null if cancelled.
  static Future<CreateOption?> show(
    BuildContext context, {
    required String itemType,
    String? startFreshDescription,
    String? fromTemplateDescription,
    bool templatesAvailable = true,
  }) {
    return showModalBottomSheet<CreateOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateOptionsSheet(
        itemType: itemType,
        startFreshDescription: startFreshDescription,
        fromTemplateDescription: fromTemplateDescription,
        templatesAvailable: templatesAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Create $itemType',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to create your new ${itemType.toLowerCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),

            // Start Fresh option
            _CreateOptionCard(
              icon: Icons.add_circle_outline,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Start Fresh',
              description: startFreshDescription ??
                  'Create a blank ${itemType.toLowerCase()} and add content manually',
              onTap: () => Navigator.of(context).pop(CreateOption.startFresh),
            ),
            const SizedBox(height: 12),

            // From Template option
            _CreateOptionCard(
              icon: Icons.dashboard_customize,
              iconColor: Theme.of(context).colorScheme.tertiary,
              title: 'From Template',
              description: fromTemplateDescription ??
                  'Start with a pre-built or saved template',
              onTap: templatesAvailable
                  ? () => Navigator.of(context).pop(CreateOption.fromTemplate)
                  : null,
              enabled: templatesAvailable,
              disabledMessage:
                  templatesAvailable ? null : 'No templates available',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Card for a single create option
class _CreateOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool enabled;
  final String? disabledMessage;

  const _CreateOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.enabled = true,
    this.disabledMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onTap == null;
    final opacity = isDisabled ? 0.5 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3 * opacity),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15 * opacity),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor.withValues(alpha: opacity),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: opacity),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDisabled && disabledMessage != null
                          ? disabledMessage!
                          : description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6 * opacity),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4 * opacity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
