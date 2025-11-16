import 'package:flutter/material.dart';
import '../models/cascade_delete_counts.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? itemName;
  final String deleteButtonText;
  final VoidCallback? onConfirm;
  final CascadeDeleteCounts? cascadeCounts;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.itemName,
    this.deleteButtonText = 'Delete',
    this.onConfirm,
    this.cascadeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content),

          // Item name highlight
          if (itemName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                itemName!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],

          // Cascade count information
          if (cascadeCounts != null && cascadeCounts!.hasItems) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will delete:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (cascadeCounts!.workouts > 0)
                    _buildCountRow(
                      context,
                      Icons.fitness_center,
                      '${cascadeCounts!.workouts} workout${cascadeCounts!.workouts > 1 ? 's' : ''}',
                    ),
                  if (cascadeCounts!.exercises > 0)
                    _buildCountRow(
                      context,
                      Icons.list,
                      '${cascadeCounts!.exercises} exercise${cascadeCounts!.exercises > 1 ? 's' : ''}',
                    ),
                  if (cascadeCounts!.sets > 0)
                    _buildCountRow(
                      context,
                      Icons.format_list_numbered,
                      '${cascadeCounts!.sets} set${cascadeCounts!.sets > 1 ? 's' : ''}',
                    ),
                ],
              ),
            ),
          ],

          // Warning message
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'This action cannot be undone.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(deleteButtonText),
        ),
      ],
    );
  }

  Widget _buildCountRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// Show enhanced delete confirmation dialog with cascade counts
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? itemName,
    String deleteButtonText = 'Delete',
    CascadeDeleteCounts? cascadeCounts,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        content: content,
        itemName: itemName,
        deleteButtonText: deleteButtonText,
        cascadeCounts: cascadeCounts,
      ),
    );
  }
}
