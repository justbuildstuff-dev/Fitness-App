import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/create_options_sheet.dart';

void main() {
  group('CreateOptionsSheet Widget Tests', () {
    Widget buildTestWidget({
      required String itemType,
      String? startFreshDescription,
      String? fromTemplateDescription,
      bool templatesAvailable = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await CreateOptionsSheet.show(
                  context,
                  itemType: itemType,
                  startFreshDescription: startFreshDescription,
                  fromTemplateDescription: fromTemplateDescription,
                  templatesAvailable: templatesAvailable,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
    }

    testWidgets('displays sheet with correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Workout'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Create Workout'), findsOneWidget);
      expect(
        find.text('Choose how you want to create your new workout'),
        findsOneWidget,
      );
    });

    testWidgets('displays Start Fresh option', (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Program'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Start Fresh'), findsOneWidget);
    });

    testWidgets('displays From Template option', (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Week'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('From Template'), findsOneWidget);
    });

    testWidgets('displays custom descriptions when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Program',
        startFreshDescription: 'Create a blank program',
        fromTemplateDescription: 'Use a saved template',
      ));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Create a blank program'), findsOneWidget);
      expect(find.text('Use a saved template'), findsOneWidget);
    });

    testWidgets('Start Fresh option returns correct value', (tester) async {
      CreateOption? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await CreateOptionsSheet.show(
                  context,
                  itemType: 'Workout',
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Fresh'));
      await tester.pumpAndSettle();

      expect(result, equals(CreateOption.startFresh));
    });

    testWidgets('From Template option returns correct value', (tester) async {
      CreateOption? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await CreateOptionsSheet.show(
                  context,
                  itemType: 'Workout',
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('From Template'));
      await tester.pumpAndSettle();

      expect(result, equals(CreateOption.fromTemplate));
    });

    testWidgets('disabled From Template shows correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        itemType: 'Workout',
        templatesAvailable: false,
      ));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('No templates available'), findsOneWidget);
    });

    testWidgets('disabled From Template option does not respond to tap',
        (tester) async {
      CreateOption? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await CreateOptionsSheet.show(
                  context,
                  itemType: 'Workout',
                  templatesAvailable: false,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Try tapping the disabled From Template option
      await tester.tap(find.text('From Template'));
      await tester.pumpAndSettle();

      // Sheet should still be visible, result should still be null
      expect(find.text('Create Workout'), findsOneWidget);
      expect(result, isNull);
    });

    testWidgets('dismissing sheet returns null', (tester) async {
      CreateOption? result;
      bool sheetCompleted = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await CreateOptionsSheet.show(
                  context,
                  itemType: 'Workout',
                );
                sheetCompleted = true;
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Dismiss by tapping outside
      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(sheetCompleted, isTrue);
      expect(result, isNull);
    });

    testWidgets('displays drag handle', (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Workout'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Find the drag handle container (40x4 with rounded corners)
      final dragHandleFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.constraints?.maxWidth == 40 &&
          widget.constraints?.maxHeight == 4);

      expect(dragHandleFinder, findsOneWidget);
    });

    testWidgets('displays chevron icons on options', (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Workout'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('displays add_circle_outline icon for Start Fresh',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Workout'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('displays dashboard_customize icon for From Template',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(itemType: 'Workout'));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.dashboard_customize), findsOneWidget);
    });
  });
}
