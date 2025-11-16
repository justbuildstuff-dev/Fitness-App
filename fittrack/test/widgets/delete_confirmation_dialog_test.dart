import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/delete_confirmation_dialog.dart';
import 'package:fittrack/models/cascade_delete_counts.dart';

void main() {
  group('DeleteConfirmationDialog Widget Tests', () {
    testWidgets('displays basic dialog without cascade counts', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Item',
                    content: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog elements
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays dialog with item name highlight', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Workout',
                    content: 'Are you sure you want to delete this workout?',
                    itemName: 'Chest Day',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify item name is displayed
      expect(find.text('Chest Day'), findsOneWidget);
    });

    testWidgets('displays cascade counts for week deletion', (WidgetTester tester) async {
      const cascadeCounts = CascadeDeleteCounts(
        workouts: 3,
        exercises: 12,
        sets: 48,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Week',
                    content: 'Are you sure you want to delete this week?',
                    itemName: 'Week 1',
                    cascadeCounts: cascadeCounts,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify cascade count header
      expect(find.text('This will delete:'), findsOneWidget);

      // Verify individual counts
      expect(find.text('3 workouts'), findsOneWidget);
      expect(find.text('12 exercises'), findsOneWidget);
      expect(find.text('48 sets'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    });

    testWidgets('displays cascade counts for workout deletion (no workouts)', (WidgetTester tester) async {
      const cascadeCounts = CascadeDeleteCounts(
        workouts: 0,
        exercises: 5,
        sets: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Workout',
                    content: 'Are you sure?',
                    cascadeCounts: cascadeCounts,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show exercises and sets, but not workouts
      expect(find.text('5 exercises'), findsOneWidget);
      expect(find.text('20 sets'), findsOneWidget);
      expect(find.text('workouts'), findsNothing);
      expect(find.byIcon(Icons.fitness_center), findsNothing);
    });

    testWidgets('displays cascade counts for exercise deletion (only sets)', (WidgetTester tester) async {
      const cascadeCounts = CascadeDeleteCounts(
        workouts: 0,
        exercises: 0,
        sets: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Exercise',
                    content: 'Are you sure?',
                    cascadeCounts: cascadeCounts,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should only show sets
      expect(find.text('4 sets'), findsOneWidget);
      expect(find.text('workouts'), findsNothing);
      expect(find.text('exercises'), findsNothing);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsNothing);
      expect(find.byIcon(Icons.list), findsNothing);
    });

    testWidgets('does not display cascade section when counts are zero', (WidgetTester tester) async {
      const cascadeCounts = CascadeDeleteCounts(
        workouts: 0,
        exercises: 0,
        sets: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Set',
                    content: 'Are you sure?',
                    cascadeCounts: cascadeCounts,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cascade section should not appear
      expect(find.text('This will delete:'), findsNothing);
    });

    testWidgets('does not display cascade section when cascadeCounts is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Item',
                    content: 'Are you sure?',
                    cascadeCounts: null,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Cascade section should not appear
      expect(find.text('This will delete:'), findsNothing);
    });

    testWidgets('uses correct singular/plural forms for counts', (WidgetTester tester) async {
      const cascadeCounts = CascadeDeleteCounts(
        workouts: 1,
        exercises: 1,
        sets: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Week',
                    content: 'Are you sure?',
                    cascadeCounts: cascadeCounts,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should use singular forms
      expect(find.text('1 workout'), findsOneWidget);
      expect(find.text('1 exercise'), findsOneWidget);
      expect(find.text('1 set'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses dialog returning false', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Item',
                    content: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed with false
      expect(result, equals(false));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Delete button dismisses dialog returning true', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Item',
                    content: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed with true
      expect(result, equals(true));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('uses custom delete button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Item',
                    content: 'Are you sure?',
                    deleteButtonText: 'Remove',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify custom button text
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('displays all elements in correct visual hierarchy', (WidgetTester tester) async {
      const cascadeCounts = CascadeDeleteCounts(
        workouts: 2,
        exercises: 6,
        sets: 18,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  DeleteConfirmationDialog.show(
                    context: context,
                    title: 'Delete Week',
                    content: 'This will delete all child items.',
                    itemName: 'Week 1 - Upper Body',
                    cascadeCounts: cascadeCounts,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify all major sections exist
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Delete Week'), findsOneWidget);
      expect(find.text('This will delete all child items.'), findsOneWidget);
      expect(find.text('Week 1 - Upper Body'), findsOneWidget);
      expect(find.text('This will delete:'), findsOneWidget);
      expect(find.text('2 workouts'), findsOneWidget);
      expect(find.text('6 exercises'), findsOneWidget);
      expect(find.text('18 sets'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
