import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? itemName;
  final String deleteButtonText;
  final VoidCallback? onConfirm;
  
  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.itemName,
    this.deleteButtonText = 'Delete',
    this.onConfirm,
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
          if (itemName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
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

  /// Show the delete confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String deleteButtonText = 'Delete',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        content: content,
        deleteButtonText: deleteButtonText,
      ),
    );
  }
}