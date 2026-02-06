import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/screens/templates/template_picker_screen.dart';

/// A simple test template for testing TemplatePickerScreen
class TestTemplate {
  final String id;
  final String name;
  final bool isPrebuilt;

  const TestTemplate({
    required this.id,
    required this.name,
    this.isPrebuilt = false,
  });
}

void main() {
  group('TemplatePickerScreen Widget Tests', () {
    final testTemplates = [
      const TestTemplate(id: '1', name: 'Template 1', isPrebuilt: true),
      const TestTemplate(id: '2', name: 'Template 2', isPrebuilt: false),
      const TestTemplate(id: '3', name: 'Template 3', isPrebuilt: true),
    ];

    Widget buildTestWidget({
      String title = 'Select Template',
      List<TestTemplate> templates = const [],
      bool isLoading = false,
      String? error,
      VoidCallback? onRetry,
      Widget? emptyStateWidget,
      bool Function(TestTemplate)? isPrebuilt,
      bool showSourceFilter = true,
      TestTemplate? selectedTemplate,
      void Function(TestTemplate)? onSelect,
    }) {
      return MaterialApp(
        home: TemplatePickerScreen<TestTemplate>(
          title: title,
          templates: templates,
          itemBuilder: (context, template) => ListTile(
            title: Text(template.name),
            subtitle: Text(template.isPrebuilt ? 'Pre-built' : 'User'),
          ),
          onSelect: onSelect ?? (template) {},
          isLoading: isLoading,
          error: error,
          onRetry: onRetry,
          emptyStateWidget: emptyStateWidget,
          isPrebuilt: isPrebuilt,
          showSourceFilter: showSourceFilter,
        ),
      );
    }

    testWidgets('displays screen title', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        title: 'Select Workout Template',
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
      ));

      expect(find.text('Select Workout Template'), findsOneWidget);
    });

    testWidgets('displays loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isLoading: true,
        templates: [],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error state with message', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        error: 'Network error occurred',
        templates: [],
      ));

      expect(find.text('Failed to load templates'), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
    });

    testWidgets('displays retry button when error and onRetry provided',
        (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(buildTestWidget(
        error: 'Network error',
        templates: [],
        onRetry: () => retryCalled = true,
      ));

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });

    testWidgets('displays default empty state when no templates',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(templates: []));

      expect(find.text('No templates available'), findsOneWidget);
    });

    testWidgets('displays custom empty state widget when provided',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: [],
        emptyStateWidget: const Center(
          child: Text('Custom Empty State'),
        ),
      ));

      expect(find.text('Custom Empty State'), findsOneWidget);
    });

    testWidgets('displays template list when templates exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
      ));

      expect(find.text('Template 1'), findsOneWidget);
      expect(find.text('Template 2'), findsOneWidget);
      expect(find.text('Template 3'), findsOneWidget);
    });

    testWidgets('displays template count', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
      ));

      expect(find.text('3 templates'), findsOneWidget);
    });

    testWidgets('displays singular template count', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: [testTemplates.first],
        isPrebuilt: (t) => t.isPrebuilt,
      ));

      expect(find.text('1 template'), findsOneWidget);
    });

    testWidgets('displays source filter chips when showSourceFilter is true',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
        showSourceFilter: true,
      ));

      // Use widgetWithText to specifically find FilterChip widgets
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pre-built'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'My Templates'), findsOneWidget);
    });

    testWidgets('hides source filter when showSourceFilter is false',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        showSourceFilter: false,
      ));

      // FilterChips should not exist when showSourceFilter is false
      expect(find.widgetWithText(FilterChip, 'Pre-built'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'My Templates'), findsNothing);
    });

    testWidgets('filters templates by pre-built when filter selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
        showSourceFilter: true,
      ));

      // Tap Pre-built filter chip specifically
      await tester.tap(find.widgetWithText(FilterChip, 'Pre-built'));
      await tester.pumpAndSettle();

      // Should show only pre-built templates
      expect(find.text('Template 1'), findsOneWidget);
      expect(find.text('Template 3'), findsOneWidget);
      expect(find.text('Template 2'), findsNothing);
      expect(find.text('2 templates'), findsOneWidget);
    });

    testWidgets('filters templates by user when filter selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
        showSourceFilter: true,
      ));

      // Tap My Templates filter
      await tester.tap(find.text('My Templates'));
      await tester.pumpAndSettle();

      // Should show only user templates
      expect(find.text('Template 2'), findsOneWidget);
      expect(find.text('Template 1'), findsNothing);
      expect(find.text('Template 3'), findsNothing);
      expect(find.text('1 template'), findsOneWidget);
    });

    testWidgets('calls onSelect when template is tapped', (tester) async {
      TestTemplate? selectedTemplate;

      await tester.pumpWidget(buildTestWidget(
        templates: testTemplates,
        isPrebuilt: (t) => t.isPrebuilt,
        onSelect: (template) => selectedTemplate = template,
      ));

      await tester.tap(find.text('Template 2'));
      await tester.pumpAndSettle();

      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.id, equals('2'));
      expect(selectedTemplate!.name, equals('Template 2'));
    });

    testWidgets('shows filtered empty state when filter matches nothing',
        (tester) async {
      // Only pre-built templates
      final prebuiltOnly = [
        const TestTemplate(id: '1', name: 'Template 1', isPrebuilt: true),
      ];

      await tester.pumpWidget(buildTestWidget(
        templates: prebuiltOnly,
        isPrebuilt: (t) => t.isPrebuilt,
        showSourceFilter: true,
      ));

      // Tap My Templates filter
      await tester.tap(find.text('My Templates'));
      await tester.pumpAndSettle();

      expect(find.text('No user-created templates'), findsOneWidget);
      expect(find.text('Show all templates'), findsOneWidget);
    });

    testWidgets('Show all templates button resets filter', (tester) async {
      // Only pre-built templates
      final prebuiltOnly = [
        const TestTemplate(id: '1', name: 'Template 1', isPrebuilt: true),
      ];

      await tester.pumpWidget(buildTestWidget(
        templates: prebuiltOnly,
        isPrebuilt: (t) => t.isPrebuilt,
        showSourceFilter: true,
      ));

      // Tap My Templates filter
      await tester.tap(find.text('My Templates'));
      await tester.pumpAndSettle();

      // Tap Show all templates
      await tester.tap(find.text('Show all templates'));
      await tester.pumpAndSettle();

      // Should show all templates again
      expect(find.text('Template 1'), findsOneWidget);
    });

    testWidgets('displays error icon in error state', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        error: 'Error',
        templates: [],
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays folder icon in default empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget(templates: []));

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('displays search_off icon in filtered empty state',
        (tester) async {
      final prebuiltOnly = [
        const TestTemplate(id: '1', name: 'Template 1', isPrebuilt: true),
      ];

      await tester.pumpWidget(buildTestWidget(
        templates: prebuiltOnly,
        isPrebuilt: (t) => t.isPrebuilt,
        showSourceFilter: true,
      ));

      await tester.tap(find.text('My Templates'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });
  });

  group('TemplateSource enum', () {
    test('all displayName is All', () {
      expect(TemplateSource.all.displayName, equals('All'));
    });

    test('prebuilt displayName is Pre-built', () {
      expect(TemplateSource.prebuilt.displayName, equals('Pre-built'));
    });

    test('user displayName is My Templates', () {
      expect(TemplateSource.user.displayName, equals('My Templates'));
    });
  });
}
