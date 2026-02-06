import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/save_template_dialog.dart';

void main() {
  group('SaveTemplateDialog Widget Tests', () {
    Widget buildTestWidget({
      String templateType = 'Workout',
      String? initialName,
      String? initialDescription,
      void Function(SaveTemplateResult?)? onResult,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await SaveTemplateDialog.show(
                  context: context,
                  templateType: templateType,
                  initialName: initialName,
                  initialDescription: initialDescription,
                );
                onResult?.call(result);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays dialog with correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget(templateType: 'Workout'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Save as Workout Template'), findsOneWidget);
    });

    testWidgets('displays template type in description', (tester) async {
      await tester.pumpWidget(buildTestWidget(templateType: 'Week'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(
        find.text('Save this week as a reusable template.'),
        findsOneWidget,
      );
    });

    testWidgets('displays name input field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Template Name'), findsOneWidget);
      expect(find.text('Enter a name for the template'), findsOneWidget);
    });

    testWidgets('displays description input field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Description (Optional)'), findsOneWidget);
    });

    testWidgets('displays Cancel and Save Template buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Template'), findsOneWidget);
    });

    testWidgets('pre-fills name when initialName provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialName: 'My Template'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('My Template'), findsOneWidget);
    });

    testWidgets('pre-fills description when initialDescription provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialDescription: 'A test description',
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('A test description'), findsOneWidget);
    });

    testWidgets('validates name is required', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Try to save without entering a name
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a template name'), findsOneWidget);
    });

    testWidgets('validates name minimum length', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter a single character
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'A',
      );
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses dialog', (tester) async {
      SaveTemplateResult? result;
      bool dialogClosed = false;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) {
          result = r;
          dialogClosed = true;
        },
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogClosed, isTrue);
      expect(result, isNull);
    });

    testWidgets('Save Template returns SaveTemplateResult with name',
        (tester) async {
      SaveTemplateResult? result;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter a valid name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'My Test Template',
      );
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, equals('My Test Template'));
      expect(result!.description, isNull);
    });

    testWidgets('Save Template returns SaveTemplateResult with description',
        (tester) async {
      SaveTemplateResult? result;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter name and description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'My Template',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'A test description',
      );
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, equals('My Template'));
      expect(result!.description, equals('A test description'));
    });

    testWidgets('trims whitespace from name', (tester) async {
      SaveTemplateResult? result;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter name with whitespace
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        '  My Template  ',
      );
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(result!.name, equals('My Template'));
    });

    testWidgets('empty description is returned as null', (tester) async {
      SaveTemplateResult? result;

      await tester.pumpWidget(buildTestWidget(
        onResult: (r) => result = r,
      ));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Template Name'),
        'My Template',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        '   ',
      );
      await tester.tap(find.text('Save Template'));
      await tester.pumpAndSettle();

      expect(result!.description, isNull);
    });

    testWidgets('displays save icon on Save Template button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('displays save_alt icon in title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_alt), findsOneWidget);
    });

    testWidgets('displays info message about template content', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(
        find.text('The template will include all exercises and sets.'),
        findsOneWidget,
      );
    });
  });
}
