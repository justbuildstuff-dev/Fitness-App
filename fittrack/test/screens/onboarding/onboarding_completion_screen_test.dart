import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/providers/subscription_provider.dart';
import 'package:fittrack/screens/onboarding/onboarding_completion_screen.dart';
import 'package:fittrack/screens/onboarding/pro_info_placeholder_screen.dart';

/// Widget tests for OnboardingCompletionScreen and ProInfoPlaceholderScreen.
///
/// Test Coverage:
/// - Completion screen renders program name
/// - Completion screen renders heading
/// - "Go to My Programs" button present
/// - Pro text link present and uses subdued styling (TextButton, not ElevatedButton)
/// - Null programName falls back to 'your program'
/// - Pro link navigates to ProInfoPlaceholderScreen
///
/// No Firebase or OnboardingService dependency — screens are purely presentational.
void main() {
  Widget buildCompletion({String? programName}) {
    return MaterialApp(
      home: OnboardingCompletionScreen(programName: programName),
    );
  }

  group('OnboardingCompletionScreen', () {
    testWidgets('renders heading "You\'re all set!"', (WidgetTester tester) async {
      /// Test Purpose: Verify celebration heading is displayed
      /// Failure indicates heading text missing or changed

      await tester.pumpWidget(buildCompletion(programName: 'Push Pull Legs'));
      await tester.pump();

      expect(find.text("You're all set!"), findsOneWidget,
          reason: 'Heading should read "You\'re all set!"');
    });

    testWidgets('renders program name in body text', (WidgetTester tester) async {
      /// Test Purpose: Verify program name is injected into body copy
      /// Failure indicates programName parameter not used in display

      await tester.pumpWidget(buildCompletion(programName: 'Push Pull Legs'));
      await tester.pump();

      expect(find.textContaining('Push Pull Legs'), findsOneWidget,
          reason: 'Body text should contain the program name');
    });

    testWidgets('falls back to "your program" when programName is null', (WidgetTester tester) async {
      /// Test Purpose: Verify null safety for programName parameter
      /// Failure indicates missing null guard

      await tester.pumpWidget(buildCompletion());
      await tester.pump();

      expect(find.textContaining('your program'), findsOneWidget,
          reason: 'Should display fallback text when programName is null');
    });

    testWidgets('"Go to My Programs" ElevatedButton is present', (WidgetTester tester) async {
      /// Test Purpose: Verify primary CTA is present
      /// Failure indicates primary navigation button missing

      await tester.pumpWidget(buildCompletion(programName: 'Test'));
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Go to My Programs'), findsOneWidget,
          reason: '"Go to My Programs" ElevatedButton should be present');
    });

    group('Pro link (monetization enabled)', () {
      // Monetization is parked (kMonetizationEnabled = false by default), so
      // the link is hidden in production — see the "monetization parked"
      // group below. These verify the link still works correctly for
      // whenever it's re-enabled.
      setUp(() => kMonetizationEnabled = true);
      tearDown(() => kMonetizationEnabled = false);

      testWidgets('Pro link uses TextButton (not ElevatedButton or FilledButton)', (WidgetTester tester) async {
        /// Test Purpose: Verify Pro link is styled as subdued footnote, not a primary action
        /// Failure indicates incorrect button type — Pro link must look like a footnote

        await tester.pumpWidget(buildCompletion(programName: 'Test'));
        await tester.pump();

        expect(find.widgetWithText(TextButton, 'Explore Overload Pro →'), findsOneWidget,
            reason: 'Pro link must be a TextButton, not ElevatedButton or FilledButton');
        expect(find.widgetWithText(ElevatedButton, 'Explore Overload Pro →'), findsNothing,
            reason: 'Pro link must NOT be an ElevatedButton');
      });

      testWidgets('tapping Pro link navigates to ProInfoPlaceholderScreen', (WidgetTester tester) async {
        /// Test Purpose: Verify Pro link destination
        /// Failure indicates navigation wired to wrong screen

        await tester.pumpWidget(buildCompletion(programName: 'Test'));
        await tester.pump();

        await tester.tap(find.widgetWithText(TextButton, 'Explore Overload Pro →'));
        await tester.pumpAndSettle();

        expect(find.byType(ProInfoPlaceholderScreen), findsOneWidget,
            reason: 'Pro link should navigate to ProInfoPlaceholderScreen');
      });
    });

    testWidgets('Pro link is hidden when monetization is parked (production default)', (WidgetTester tester) async {
      /// Test Purpose: Verify the dangling Pro link doesn't appear while
      /// monetization is parked, since it leads to a "Coming Soon" dead end.

      await tester.pumpWidget(buildCompletion(programName: 'Test'));
      await tester.pump();

      expect(find.text('Explore Overload Pro →'), findsNothing,
          reason: 'Pro link should not render while kMonetizationEnabled is false');
    });

    testWidgets('check circle icon is displayed', (WidgetTester tester) async {
      /// Test Purpose: Verify celebration icon renders
      /// Failure indicates icon widget missing

      await tester.pumpWidget(buildCompletion(programName: 'Test'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget,
          reason: 'Check circle icon should be displayed');
    });
  });

  group('ProInfoPlaceholderScreen', () {
    testWidgets('renders AppBar with Overload Pro title', (WidgetTester tester) async {
      /// Test Purpose: Verify placeholder screen has correct title
      /// Failure indicates title missing or incorrect

      await tester.pumpWidget(
        const MaterialApp(home: ProInfoPlaceholderScreen()),
      );
      await tester.pump();

      expect(find.text('Overload Pro'), findsOneWidget,
          reason: 'AppBar should display "Overload Pro"');
    });

    testWidgets('renders coming soon message', (WidgetTester tester) async {
      /// Test Purpose: Verify placeholder content is displayed
      /// Failure indicates body text missing

      await tester.pumpWidget(
        const MaterialApp(home: ProInfoPlaceholderScreen()),
      );
      await tester.pump();

      expect(find.textContaining('Coming Soon'), findsOneWidget,
          reason: 'Should display "Coming Soon" text');
      expect(find.textContaining('unlimited programs'), findsOneWidget,
          reason: 'Should describe Pro features');
    });

    testWidgets('renders lock icon', (WidgetTester tester) async {
      /// Test Purpose: Verify lock icon renders on placeholder screen
      /// Failure indicates icon widget missing

      await tester.pumpWidget(
        const MaterialApp(home: ProInfoPlaceholderScreen()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget,
          reason: 'Lock icon should be displayed');
    });
  });
}
