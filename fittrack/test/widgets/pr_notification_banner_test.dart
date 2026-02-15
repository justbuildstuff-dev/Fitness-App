import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/widgets/pr_notification_banner.dart';

void main() {
  PersonalRecord createPR({
    PRType prType = PRType.maxWeight,
    double value = 100,
    double? previousValue = 95,
    String exerciseName = 'Bench Press',
  }) {
    return PersonalRecord(
      id: 'pr1',
      userId: 'user1',
      exerciseId: 'ex1',
      exerciseName: exerciseName,
      exerciseType: ExerciseType.strength,
      prType: prType,
      value: value,
      previousValue: previousValue,
      achievedAt: DateTime.now(),
      workoutId: 'w1',
      setId: 's1',
    );
  }

  Widget buildTestWidget({
    required PersonalRecord pr,
    VoidCallback? onDismissed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PRNotificationBanner(
          pr: pr,
          onDismissed: onDismissed,
        ),
      ),
    );
  }

  group('PRNotificationBanner', () {
    testWidgets('shows New PR! title', (tester) async {
      await tester.pumpWidget(buildTestWidget(pr: createPR()));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('New PR!'), findsOneWidget);
    });

    testWidgets('shows exercise name and PR type', (tester) async {
      await tester.pumpWidget(buildTestWidget(pr: createPR()));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('Bench Press'), findsOneWidget);
      expect(find.textContaining('Max Weight'), findsOneWidget);
    });

    testWidgets('shows value and improvement for max weight', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        pr: createPR(value: 100, previousValue: 95),
      ));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('100.0kg'), findsOneWidget);
      expect(find.textContaining('+5.0kg'), findsOneWidget);
    });

    testWidgets('shows value without improvement when no previous',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        pr: createPR(previousValue: null),
      ));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('100.0kg'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('shows trophy icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(pr: createPR()));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('shows close icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(pr: createPR()));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('dismisses on tap', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(buildTestWidget(
        pr: createPR(),
        onDismissed: () => dismissed = true,
      ));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('New PR!'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('auto-dismisses after 5 seconds', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(buildTestWidget(
        pr: createPR(),
        onDismissed: () => dismissed = true,
      ));
      await tester.pump(const Duration(milliseconds: 350));

      // Not dismissed yet
      expect(dismissed, isFalse);

      // Advance past auto-dismiss timer
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('formats reps correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        pr: createPR(prType: PRType.maxReps, value: 15, previousValue: 12),
      ));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('15 reps'), findsOneWidget);
      expect(find.textContaining('+3 reps'), findsOneWidget);
    });

    testWidgets('formats duration correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        pr: createPR(
            prType: PRType.maxDuration, value: 125, previousValue: null),
      ));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('2m 5s'), findsOneWidget);
    });

    testWidgets('has semantics live region', (tester) async {
      await tester.pumpWidget(buildTestWidget(pr: createPR()));
      await tester.pump(const Duration(milliseconds: 350));

      final semantics = find.bySemanticsLabel(
        RegExp(r'New personal record: Bench Press'),
      );
      expect(semantics, findsOneWidget);
    });
  });
}
