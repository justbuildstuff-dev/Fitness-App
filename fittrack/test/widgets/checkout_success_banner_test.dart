import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/checkout_success_banner.dart';

Widget _buildSubject() {
  return const MaterialApp(
    home: Scaffold(body: CheckoutSuccessBanner()),
  );
}

void main() {
  setUp(() {
    CheckoutSuccessService.pendingWelcome = false;
  });

  group('CheckoutSuccessBanner', () {
    testWidgets('is invisible when pendingWelcome is false', (tester) async {
      CheckoutSuccessService.pendingWelcome = false;

      await tester.pumpWidget(_buildSubject());

      expect(find.text('Welcome to Overload Pro!'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows banner when pendingWelcome is true', (tester) async {
      CheckoutSuccessService.pendingWelcome = true;

      await tester.pumpWidget(_buildSubject());

      expect(find.text('Welcome to Overload Pro!'), findsOneWidget);
      expect(
        find.text('Your subscription is now active. All Pro features are unlocked.'),
        findsOneWidget,
      );
    });

    testWidgets('shows workspace_premium icon when visible', (tester) async {
      CheckoutSuccessService.pendingWelcome = true;

      await tester.pumpWidget(_buildSubject());

      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('dismisses banner on close tap', (tester) async {
      CheckoutSuccessService.pendingWelcome = true;

      await tester.pumpWidget(_buildSubject());
      expect(find.text('Welcome to Overload Pro!'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.text('Welcome to Overload Pro!'), findsNothing);
    });

    testWidgets('dismiss clears pendingWelcome flag', (tester) async {
      CheckoutSuccessService.pendingWelcome = true;

      await tester.pumpWidget(_buildSubject());
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(CheckoutSuccessService.pendingWelcome, isFalse);
    });

    testWidgets('does not re-appear after dismiss even if pendingWelcome re-set', (tester) async {
      CheckoutSuccessService.pendingWelcome = true;

      await tester.pumpWidget(_buildSubject());
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Even if the flag is re-set (e.g., by a test), the _dismissed bool
      // on the widget state keeps it invisible within the same widget lifecycle.
      CheckoutSuccessService.pendingWelcome = true;
      await tester.pump();

      expect(find.text('Welcome to Overload Pro!'), findsNothing);
    });

    testWidgets('uses primaryContainer card color', (tester) async {
      CheckoutSuccessService.pendingWelcome = true;

      await tester.pumpWidget(_buildSubject());

      final card = tester.widget<Card>(find.byType(Card));
      final colorScheme = Theme.of(tester.element(find.byType(Card))).colorScheme;
      expect(card.color, colorScheme.primaryContainer);
    });
  });

  group('CheckoutSuccessService', () {
    test('pendingWelcome defaults to false', () {
      expect(CheckoutSuccessService.pendingWelcome, isFalse);
    });

    test('dismiss() sets pendingWelcome to false', () {
      CheckoutSuccessService.pendingWelcome = true;
      CheckoutSuccessService.dismiss();
      expect(CheckoutSuccessService.pendingWelcome, isFalse);
    });
  });
}
