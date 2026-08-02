import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/models/subscription.dart';
import 'package:fittrack/providers/subscription_provider.dart';
import 'package:fittrack/widgets/pro_gate_widget.dart';

Widget _buildSubject({
  required SubscriptionProvider sub,
  required Widget child,
}) {
  // Provider must wrap MaterialApp so modal bottom sheets inherit it through
  // the root navigator's overlay (showModalBottomSheet creates a new route).
  return ChangeNotifierProvider<SubscriptionProvider>.value(
    value: sub,
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late SubscriptionProvider sub;

  // Monetization is parked (kMonetizationEnabled = false by default), so
  // ProGateWidget always renders its child directly in production — see the
  // dedicated "monetization parked" group below. The rest of this suite
  // verifies the gating logic still works, ready to be re-enabled.
  setUp(() {
    kMonetizationEnabled = true;
    sub = SubscriptionProvider();
  });

  tearDown(() {
    sub.dispose();
    kMonetizationEnabled = false;
  });

  group('ProGateWidget - free tier', () {
    testWidgets('shows lock icon', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows paywall headline', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text("Track every rep's progress"), findsOneWidget);
    });

    testWidgets('shows optional subtext when provided', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            paywallSubtext: 'Available on Overload Pro.',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text('Available on Overload Pro.'), findsOneWidget);
    });

    testWidgets('does not show subtext when not provided', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text('Available on Overload Pro.'), findsNothing);
    });

    testWidgets('shows Upgrade to Pro button', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text('Upgrade to Pro'), findsOneWidget);
    });

    testWidgets('child is still in the tree but pointer-ignored (blurred)', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      // Child is present (blurred behind overlay) but wrapped in IgnorePointer.
      // Filter to ignoring:true because Flutter's framework adds IgnorePointer(ignoring:false)
      // nodes internally (e.g. Scaffold focus management).
      expect(find.text('Premium Content'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
        findsOneWidget,
      );
    });

    testWidgets('tapping Upgrade to Pro opens PaywallScreen', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pumpAndSettle();

      expect(find.text('Overload Pro'), findsOneWidget);
    });

    testWidgets('paywall opens with correct headline', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pumpAndSettle();

      expect(find.text("Track every rep's progress"), findsWidgets);
    });
  });

  group('ProGateWidget - pro tier', () {
    setUp(() {
      sub.setSubscriptionInfoForTest(
        const SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
        ),
      );
    });

    testWidgets('renders child directly without overlay', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Upgrade to Pro'), findsNothing);
    });

    testWidgets('no blur or IgnorePointer wrapping child', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      // Only check for IgnorePointer with ignoring:true — framework internal nodes
      // (ignoring:false) are present in both free and pro trees.
      expect(
        find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
        findsNothing,
      );
    });
  });

  group('ProGateWidget - isProOverride', () {
    testWidgets('treats override as pro — renders child directly', (tester) async {
      sub.setProOverrideForTest(value: true);

      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });
  });

  group('ProGateWidget - state transitions', () {
    testWidgets('switches to pro view when subscription upgrades', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      // Free state — lock shown
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      sub.setSubscriptionInfoForTest(
        const SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
        ),
      );
      await tester.pump();

      // Pro state — no lock
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Premium Content'), findsOneWidget);
    });
  });

  group('ProGateWidget - monetization parked (production default)', () {
    setUp(() => kMonetizationEnabled = false);

    testWidgets('renders child directly with no lock, regardless of tier', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          sub: sub,
          child: const ProGateWidget(
            paywallHeadline: 'Track every rep\'s progress',
            child: Text('Premium Content'),
          ),
        ),
      );

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Upgrade to Pro'), findsNothing);
    });
  });
}
