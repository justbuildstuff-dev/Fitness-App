import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/screens/onboarding/onboarding_carousel_screen.dart';
import 'package:fittrack/screens/onboarding/onboarding_wizard_screen.dart';
import 'package:fittrack/screens/home/home_screen.dart';
import 'package:fittrack/services/onboarding_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;

import 'onboarding_carousel_screen_test.mocks.dart';

/// Widget tests for OnboardingCarouselScreen.
///
/// Test Coverage:
/// - First page renders correct content
/// - Skip button is present on all pages
/// - "Next" advances to next page
/// - "Set Up My First Program" button appears on page 4
/// - "Skip to App" button appears only on page 4
/// - AppBar Skip navigates to OnboardingWizardScreen
/// - "Set Up My First Program" navigates to OnboardingWizardScreen
/// - "Skip to App" marks onboarding complete and navigates to HomeScreen
/// - Dot indicators render
///
/// If any test fails it indicates issues with:
/// - Carousel page navigation
/// - Skip/CTA button visibility logic
/// - OnboardingService completion marking
@GenerateNiceMocks([MockSpec<ProgramProvider>(), MockSpec<app_auth.AuthProvider>()])
void main() {
  late MockProgramProvider mockProgramProvider;
  late MockAuthProvider mockAuthProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    OnboardingService.initialize(prefs);

    mockProgramProvider = MockProgramProvider();
    mockAuthProvider = MockAuthProvider();
  });

  Widget createTestWidget() {
    // Providers above MaterialApp so they are accessible from all pushed routes
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProgramProvider>.value(value: mockProgramProvider),
        ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
      ],
      child: const MaterialApp(
        home: OnboardingCarouselScreen(),
      ),
    );
  }

  group('OnboardingCarouselScreen', () {
    testWidgets('renders first page with correct title', (WidgetTester tester) async {
      /// Test Purpose: Verify first carousel page is displayed on launch
      /// Failure indicates wrong initial page or missing content

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Structured Training'), findsOneWidget,
          reason: 'First page title should be visible');
      expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget,
          reason: 'First page icon should be visible');
    });

    testWidgets('Skip button is visible on first page', (WidgetTester tester) async {
      /// Test Purpose: Skip is always available from any page
      /// Failure indicates missing skip button

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Skip'), findsOneWidget,
          reason: 'Skip button should be visible on page 1');
    });

    testWidgets('"Next" button advances to page 2', (WidgetTester tester) async {
      /// Test Purpose: Next button advances carousel pages
      /// Failure indicates broken page navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Track Every Set'), findsOneWidget,
          reason: 'Next should advance to page 2 — Track Every Set');
    });

    testWidgets('"Set Up My First Program" appears only on last page',
        (WidgetTester tester) async {
      /// Test Purpose: CTA button is only visible on final page
      /// Failure indicates wrong button visibility logic

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Not visible on page 1
      expect(find.text('Set Up My First Program'), findsNothing,
          reason: 'CTA should not appear on page 1');

      // Navigate to last page (page 4, index 3)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Set Up My First Program'), findsOneWidget,
          reason: 'CTA should appear on the last page');
    });

    testWidgets('"Skip to App" appears only on last page', (WidgetTester tester) async {
      /// Test Purpose: "Skip to App" is exclusive to the final page
      /// Failure indicates incorrect button visibility

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Skip to App'), findsNothing,
          reason: '"Skip to App" should not appear on page 1');

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Skip to App'), findsOneWidget,
          reason: '"Skip to App" should appear on the last page');
    });

    testWidgets('AppBar Skip navigates to OnboardingWizardScreen',
        (WidgetTester tester) async {
      /// Test Purpose: Skip button routes to wizard, not HomeScreen
      /// Failure indicates wrong skip destination

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingWizardScreen), findsOneWidget,
          reason: 'Skip should navigate to OnboardingWizardScreen');
    });

    testWidgets('"Set Up My First Program" navigates to OnboardingWizardScreen',
        (WidgetTester tester) async {
      /// Test Purpose: Primary CTA on last page goes to wizard
      /// Failure indicates broken CTA navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Set Up My First Program'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingWizardScreen), findsOneWidget,
          reason: 'CTA should navigate to OnboardingWizardScreen');
    });

    testWidgets('"Skip to App" marks onboarding complete and navigates to HomeScreen',
        (WidgetTester tester) async {
      /// Test Purpose: "Skip to App" bypasses wizard and marks onboarding done
      /// Failure indicates missing markComplete call or wrong navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Skip to App'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: '"Skip to App" should navigate to HomeScreen');
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
          reason: 'Onboarding should be marked complete after Skip to App');
    });

    testWidgets('dot indicators render for all 4 pages', (WidgetTester tester) async {
      /// Test Purpose: Dot indicators show page position
      /// Failure indicates missing or incorrect dot indicator implementation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // 4 dot indicators exist (each has a Semantics label)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label?.startsWith('Page') ?? false),
        ),
        findsNWidgets(4),
        reason: 'Should render 4 dot indicators with Semantics labels',
      );
    });
  });
}
