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
      title: Text(title),
      content: Text(content),
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