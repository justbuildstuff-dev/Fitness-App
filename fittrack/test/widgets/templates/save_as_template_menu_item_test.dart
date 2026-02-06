import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/save_as_template_menu_item.dart';

void main() {
  group('SaveAsTemplateMenuItem Widget Tests', () {
    testWidgets('displays correct text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const SaveAsTemplateMenuItem(),
                ],
              ),
            ],
          ),
        ),
      ));

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Save as Template'), findsOneWidget);
    });

    testWidgets('displays save icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const SaveAsTemplateMenuItem(),
                ],
              ),
            ],
          ),
        ),
      ));

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_alt), findsOneWidget);
    });

    testWidgets('returns correct value when selected', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => selectedValue = value,
                itemBuilder: (context) => [
                  const SaveAsTemplateMenuItem(),
                ],
              ),
            ],
          ),
        ),
      ));

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap the menu item
      await tester.tap(find.text('Save as Template'));
      await tester.pumpAndSettle();

      expect(selectedValue, equals('save_as_template'));
    });
  });

  group('MenuActions Constants', () {
    test('saveAsTemplate has correct value', () {
      expect(MenuActions.saveAsTemplate, equals('save_as_template'));
    });

    test('edit has correct value', () {
      expect(MenuActions.edit, equals('edit'));
    });

    test('delete has correct value', () {
      expect(MenuActions.delete, equals('delete'));
    });

    test('archive has correct value', () {
      expect(MenuActions.archive, equals('archive'));
    });

    test('duplicate has correct value', () {
      expect(MenuActions.duplicate, equals('duplicate'));
    });
  });

  group('SaveAsTemplateHelper Widget Tests', () {
    Widget buildTestWidget({
      required String itemType,
      String? itemName,
      String? itemDescription,
      required Future<void> Function(String name, String? description) onSave,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                SaveAsTemplateHelper.handleSaveAsTemplate(
                  context: context,
                  itemType: itemType,
                  itemName: itemName,
                  itemDescription: itemDescription,
                  onSave: onSave,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays dialog with correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save as Workout Template'), findsOneWidget);
    });

    testWidgets('displays save_alt icon in dialog title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Program',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_alt), findsOneWidget);
    });

    testWidgets('displays Template Name input field', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Template Name'), findsOneWidget);
    });

    testWidgets('displays Description input field', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Description (Optional)'), findsOneWidget);
    });

    testWidgets('pre-fills name from itemName parameter', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        itemName: 'My Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('My Workout'), findsOneWidget);
    });

    testWidgets('pre-fills description from itemDescription parameter',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        itemDescription: 'A great workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('A great workout'), findsOneWidget);
    });

    testWidgets('displays Cancel button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('displays Save Template button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save Template'), findsOneWidget);
    });

    testWidgets('validates empty name field', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Try to save without entering a name
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a template name'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses dialog without calling onSave',
        (tester) async {
      bool onSaveCalled = false;

      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {
          onSaveCalled = true;
        },
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(onSaveCalled, isFalse);
      expect(find.text('Save as Workout Template'), findsNothing);
    });

    testWidgets('Save Template calls onSave with correct parameters',
        (tester) async {
      String? savedName;
      String? savedDescription;

      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {
          savedName = name;
          savedDescription = description;
        },
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter template name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'My Template',
      );

      // Enter description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'Test description',
      );

      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(savedName, equals('My Template'));
      expect(savedDescription, equals('Test description'));
    });

    testWidgets('Save Template with empty description passes null',
        (tester) async {
      String? savedName;
      String? savedDescription = 'not null';

      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {
          savedName = name;
          savedDescription = description;
        },
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter template name only
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'My Template',
      );

      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(savedName, equals('My Template'));
      expect(savedDescription, isNull);
    });

    testWidgets('shows success snackbar after save', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'Test Template',
      );

      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(
        find.text('Workout saved as template "Test Template"'),
        findsOneWidget,
      );
    });

    testWidgets('shows error snackbar when onSave throws', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {
          throw Exception('Save failed');
        },
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'Test Template',
      );

      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Failed to save template'),
        findsOneWidget,
      );
    });

    testWidgets('trims whitespace from name', (tester) async {
      String? savedName;

      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {
          savedName = name;
        },
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        '  My Template  ',
      );

      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(savedName, equals('My Template'));
    });

    testWidgets('works with different item types', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Week',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save as Week Template'), findsOneWidget);
    });

    testWidgets('displays text_fields icon for name field', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('displays description icon for description field',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        onSave: (name, description) async {},
      ));

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.description), findsOneWidget);
    });
  });
}
