import 'package:flutter/material.dart';

/// A PopupMenuItem for "Save as Template" action.
/// Used in detail screen app bar menus for programs, weeks, and workouts.
class SaveAsTemplateMenuItem extends PopupMenuItem<String> {
  const SaveAsTemplateMenuItem({super.key})
      : super(
          value: 'save_as_template',
          child: const ListTile(
            leading: Icon(Icons.save_alt),
            title: Text('Save as Template'),
            contentPadding: EdgeInsets.zero,
          ),
        );
}

/// Constants for menu action values
class MenuActions {
  static const String saveAsTemplate = 'save_as_template';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String archive = 'archive';
  static const String duplicate = 'duplicate';
}

/// Helper class for handling "Save as Template" action.
///
/// Usage in detail screens:
/// ```dart
/// PopupMenuButton<String>(
///   onSelected: (value) {
///     if (value == MenuActions.saveAsTemplate) {
///       SaveAsTemplateHelper.handleSaveAsTemplate(
///         context: context,
///         itemType: 'Workout',
///         itemName: workout.name,
///         itemDescription: workout.notes,
///         onSave: (name, description) async {
///           // Use TemplateProvider to save the template
///           final templateProvider = context.read<TemplateProvider>();
///           await templateProvider.saveWorkoutAsTemplate(
///             workout: workout,
///             name: name,
///             description: description,
///           );
///         },
///       );
///     }
///   },
///   itemBuilder: (context) => [
///     SaveAsTemplateMenuItem(),
///     // ... other items
///   ],
/// );
/// ```
class SaveAsTemplateHelper {
  /// Handles the save as template action flow.
  ///
  /// Shows the save template dialog and calls [onSave] with the user-provided
  /// name and description if the user confirms.
  ///
  /// Note: This method requires SaveTemplateDialog from PR #337 to be merged.
  /// Until then, use the placeholder implementation below.
  static Future<void> handleSaveAsTemplate({
    required BuildContext context,
    required String itemType,
    String? itemName,
    String? itemDescription,
    required Future<void> Function(String name, String? description) onSave,
  }) async {
    // Show a placeholder dialog until SaveTemplateDialog is merged
    final result = await _showPlaceholderDialog(
      context,
      itemType: itemType,
      initialName: itemName,
      initialDescription: itemDescription,
    );

    if (result != null && context.mounted) {
      try {
        await onSave(result.name, result.description);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$itemType saved as template "${result.name}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save template: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Placeholder dialog until SaveTemplateDialog is merged from PR #337.
  /// This will be replaced with the actual SaveTemplateDialog.
  static Future<_PlaceholderResult?> _showPlaceholderDialog(
    BuildContext context, {
    required String itemType,
    String? initialName,
    String? initialDescription,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final descriptionController =
        TextEditingController(text: initialDescription ?? '');
    final formKey = GlobalKey<FormState>();

    return showDialog<_PlaceholderResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.save_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Save as $itemType Template'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'Enter a name for the template',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.text_fields),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a template name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add a description for this template',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(_PlaceholderResult(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                ));
              }
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save Template'),
          ),
        ],
      ),
    );
  }
}

/// Internal result class for the placeholder dialog.
/// This will be replaced by SaveTemplateResult from PR #337.
class _PlaceholderResult {
  final String name;
  final String? description;

  _PlaceholderResult({required this.name, this.description});
}
