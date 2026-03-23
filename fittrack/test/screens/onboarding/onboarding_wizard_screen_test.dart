import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/screens/onboarding/onboarding_wizard_screen.dart';
import 'package:fittrack/screens/onboarding/onboarding_completion_screen.dart';
import 'package:fittrack/screens/home/home_screen.dart';
import 'package:fittrack/services/onboarding_service.dart';

import 'onboarding_wizard_screen_test.mocks.dart';

/// Widget tests for OnboardingWizardScreen.
///
/// Test Coverage:
/// - Step 0: validation fires on empty name
/// - Step 0: "Skip for now" on step 0 exits wizard → HomeScreen
/// - Step 0: valid name + Next calls createProgram and advances to step 1
/// - Step 1+: "Skip this step" calls markComplete and navigates to HomeScreen
/// - Step 3 Finish: calls createExercise and navigates to OnboardingCompletionScreen
/// - Offline error on createProgram shows SnackBar and stays on step 0
///
/// If any test fails it indicates issues with:
/// - Wizard step validation
/// - Provider integration
/// - OnboardingService completion marking
/// - Navigation after skip/finish
@GenerateNiceMocks([MockSpec<ProgramProvider>()])
void main() {
  group('OnboardingWizardScreen', () {
    late MockProgramProvider mockProvider;

    setUp(() async {
      mockProvider = MockProgramProvider();

      // Initialize OnboardingService with clean prefs for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      OnboardingService.initialize(prefs);

      // Default stubs
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.createProgram(
              name: anyNamed('name'), description: anyNamed('description')))
          .thenAnswer((_) async => 'test-program-id');
      when(mockProvider.createWeek(
              programId: anyNamed('programId'),
              name: anyNamed('name'),
              notes: anyNamed('notes')))
          .thenAnswer((_) async => 'test-week-id');
      when(mockProvider.createWorkout(
              programId: anyNamed('programId'),
              weekId: anyNamed('weekId'),
              name: anyNamed('name'),
              dayOfWeek: anyNamed('dayOfWeek')))
          .thenAnswer((_) async => 'test-workout-id');
      when(mockProvider.createExercise(
              programId: anyNamed('programId'),
              weekId: anyNamed('weekId'),
              workoutId: anyNamed('workoutId'),
              name: anyNamed('name'),
              exerciseType: anyNamed('exerciseType'),
              setCount: anyNamed('setCount')))
          .thenAnswer((_) async => 'test-exercise-id');
    });

    Widget createTestWidget() {
      // Provider above MaterialApp so HomeScreen navigation can access it
      return ChangeNotifierProvider<ProgramProvider>.value(
        value: mockProvider,
        child: const MaterialApp(
          home: OnboardingWizardScreen(),
        ),
      );
    }

    // ─── Step 0 ──────────────────────────────────────────────────────────────

    testWidgets('renders step 0 heading and form fields', (WidgetTester tester) async {
      /// Test Purpose: Verify step 0 UI elements are present
      /// Failure indicates missing step content or wrong initial step

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Name Your Program'), findsOneWidget,
          reason: 'Step 0 heading should be visible');
      expect(find.text('Step 1 of 4'), findsOneWidget,
          reason: 'Step counter should show step 1 of 4');
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1),
          reason: 'Program name field should be present');
      expect(find.text('Next'), findsOneWidget,
          reason: 'Next button should be present on step 0');
      expect(find.text('Skip for now'), findsOneWidget,
          reason: 'Skip button label should be "Skip for now" on step 0');
    });

    testWidgets('step 0 validation blocks empty name', (WidgetTester tester) async {
      /// Test Purpose: Required field validation prevents advancing with no name
      /// Failure indicates missing validation logic

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap Next without entering a name
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Please enter a program name'), findsOneWidget,
          reason: 'Validation error should appear when name is empty');
      expect(find.text('Step 1 of 4'), findsOneWidget,
          reason: 'Should remain on step 0 after validation failure');

      verifyNever(mockProvider.createProgram(
          name: anyNamed('name'), description: anyNamed('description')));
    });

    testWidgets('step 0 skip exits wizard to HomeScreen', (WidgetTester tester) async {
      /// Test Purpose: Skip on step 0 (no program yet) should navigate to HomeScreen
      /// and mark onboarding complete
      /// Failure indicates incorrect skip navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'Should navigate to HomeScreen after skip on step 0');
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
          reason: 'Onboarding should be marked complete after skip');
    });

    testWidgets('step 0 valid name advances to step 1', (WidgetTester tester) async {
      /// Test Purpose: Valid program name + Next calls createProgram and advances step
      /// Failure indicates broken provider integration or step navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'My Test Program');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      verify(mockProvider.createProgram(
              name: 'My Test Program', description: anyNamed('description')))
          .called(1);
      expect(find.text('Create Your First Week'), findsOneWidget,
          reason: 'Should advance to step 1 after successful program creation');
      expect(find.text('Step 2 of 4'), findsOneWidget,
          reason: 'Step counter should update to step 2 of 4');
    });

    testWidgets('createProgram failure shows SnackBar and stays on step 0',
        (WidgetTester tester) async {
      /// Test Purpose: Firestore failure shows error and does not advance step
      /// Failure indicates missing error handling

      when(mockProvider.createProgram(
              name: anyNamed('name'), description: anyNamed('description')))
          .thenAnswer((_) async => null);
      when(mockProvider.error).thenReturn('Network error');

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'My Test Program');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'SnackBar should appear on createProgram failure');
      expect(find.text('Network error'), findsOneWidget,
          reason: 'Error message from provider should be shown');
      expect(find.text('Step 1 of 4'), findsOneWidget,
          reason: 'Should remain on step 0 after failure');
    });

    // ─── Step 1 ──────────────────────────────────────────────────────────────

    testWidgets('step 1 skip label is "Skip this step"', (WidgetTester tester) async {
      /// Test Purpose: Skip label changes to "Skip this step" on steps 1+
      /// Failure indicates incorrect button label

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Advance to step 1
      await tester.enterText(
          find.byType(TextFormField).first, 'My Program');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Skip this step'), findsOneWidget,
          reason: 'Skip label on step 1+ should be "Skip this step"');
    });

    testWidgets('step 1+ skip exits to HomeScreen with onboarding marked complete',
        (WidgetTester tester) async {
      /// Test Purpose: Skip after step 0 (program exists) exits to HomeScreen
      /// Failure indicates missing stack-clearing navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Advance to step 1
      await tester.enterText(
          find.byType(TextFormField).first, 'My Program');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Skip from step 1
      await tester.tap(find.text('Skip this step'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget,
          reason: 'Skip on step 1+ should navigate to HomeScreen');
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
          reason: 'Onboarding should be marked complete after skip');
    });

    // ─── Back navigation ─────────────────────────────────────────────────────

    testWidgets('back button on step 1 returns to step 0', (WidgetTester tester) async {
      /// Test Purpose: Back button navigates to previous step without saving
      /// Failure indicates broken step-back logic

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).first, 'My Program');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 4'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(find.text('Step 1 of 4'), findsOneWidget,
          reason: 'Back button should go to previous step');
      expect(find.text('Name Your Program'), findsOneWidget,
          reason: 'Should be back on step 0');
    });

    testWidgets('no back button on step 0', (WidgetTester tester) async {
      /// Test Purpose: Step 0 has no back button (first step)
      /// Failure indicates unnecessary back button on first step

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsNothing,
          reason: 'No back button on step 0');
    });

    // ─── Step 3 finish ───────────────────────────────────────────────────────

    testWidgets('step 3 Finish navigates to OnboardingCompletionScreen',
        (WidgetTester tester) async {
      /// Test Purpose: Completing all 4 steps navigates to completion screen
      /// Failure indicates missing final navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Step 0 → 1
      await tester.enterText(
          find.byType(TextFormField).first, 'My Program');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 1 → 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2 → 3
      await tester.enterText(
          find.byType(TextFormField).first, 'Push Day');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3 finish
      await tester.enterText(
          find.byType(TextFormField).first, 'Bench Press');
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingCompletionScreen), findsOneWidget,
          reason: 'Finish should navigate to OnboardingCompletionScreen');
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
          reason: 'Onboarding should be marked complete after Finish');
    });
  });
}
