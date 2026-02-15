import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/screens/analytics/components/streak_section.dart';

void main() {
  Widget buildTestWidget({
    ConfigurableStreak? streak,
    int weeklyTarget = 3,
    ValueChanged<int>? onTargetChanged,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StreakSection(
            streak: streak,
            weeklyTarget: weeklyTarget,
            onTargetChanged: onTargetChanged ?? (_) {},
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  group('StreakSection', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Workout Streak'), findsOneWidget);
    });

    testWidgets('shows current target label', (tester) async {
      await tester.pumpWidget(buildTestWidget(weeklyTarget: 4));

      expect(find.text('Target: 4/wk'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(buildTestWidget(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no streak data when null', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('No streak data'), findsOneWidget);
    });

    testWidgets('shows streak data with flame icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        streak: const ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 5,
          longestStreak: 12,
        ),
      ));

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('5-week streak'), findsOneWidget);
      expect(find.text('Longest: 12 weeks'), findsOneWidget);
    });

    testWidgets('shows single week streak correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        streak: const ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 1,
          longestStreak: 1,
        ),
      ));

      expect(find.text('1-week streak'), findsOneWidget);
      expect(find.text('Longest: 1 week'), findsOneWidget);
    });

    testWidgets('shows no streak message for zero streak', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        streak: const ConfigurableStreak(
          weeklyTarget: 3,
          currentStreak: 0,
          longestStreak: 0,
        ),
      ));

      expect(find.text('No streak'), findsOneWidget);
      expect(find.text('Longest: No record'), findsOneWidget);
    });

    testWidgets('settings icon opens bottom sheet', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Workout Target'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('bottom sheet shows 7 choice chips', (tester) async {
      await tester.pumpWidget(buildTestWidget(weeklyTarget: 3));

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      for (int i = 1; i <= 7; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('bottom sheet save calls onTargetChanged', (tester) async {
      int? changedTarget;
      await tester.pumpWidget(buildTestWidget(
        weeklyTarget: 3,
        onTargetChanged: (value) => changedTarget = value,
      ));

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Select target 5
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(changedTarget, equals(5));
    });

    testWidgets('renders in a Card', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
