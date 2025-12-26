import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:fittrack/providers/auth_provider.dart' as app;
import 'package:fittrack/screens/auth/email_verification_screen.dart';

import 'email_verification_screen_test.mocks.dart';

/// Widget tests for EmailVerificationScreen
///
/// Test Coverage:
/// - Screen rendering with correct UI elements
/// - Email address display
/// - Auto-check timer behavior
/// - Resend button functionality and cooldown
/// - Sign out button
/// - Success and error message display
/// - Navigation after verification
///
/// If any test fails, it indicates issues with:
/// - Email verification UI/UX
/// - Auto-verification detection
/// - User feedback mechanisms
@GenerateMocks([app.AuthProvider, User])
void main() {
  group('EmailVerificationScreen Widget Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockUser mockUser;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockUser = MockUser();

      // Default mock setup
      when(mockAuthProvider.user).thenReturn(mockUser);
      when(mockAuthProvider.isEmailVerified).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.successMessage).thenReturn(null);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockAuthProvider.sendEmailVerification()).thenAnswer((_) async {});
      when(mockAuthProvider.signOut()).thenAnswer((_) async {});
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<app.AuthProvider>.value(
          value: mockAuthProvider,
          child: const EmailVerificationScreen(),
        ),
      );
    }

    testWidgets('renders with correct title and instructions', (WidgetTester tester) async {
      /// Test Purpose: Verify basic screen structure and messaging
      /// Users need clear instructions about email verification process
      /// Failure indicates poor UX or missing UI elements

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.text('Verify Email'), findsOneWidget,
        reason: 'Should display screen title');
      expect(find.text('Verify Your Email'), findsOneWidget,
        reason: 'Should display main heading');
      expect(find.text('We sent a verification link to:'), findsOneWidget,
        reason: 'Should display email instruction');
      expect(find.text('Click the link in the email to verify your account.'), findsOneWidget,
        reason: 'Should display verification instructions');
      expect(find.text('This page will update automatically when verified.'), findsOneWidget,
        reason: 'Should mention auto-update behavior');
    });

    testWidgets('displays user email address', (WidgetTester tester) async {
      /// Test Purpose: Verify email address is shown to user
      /// Users need to confirm which email to check
      /// Failure indicates missing user feedback

      when(mockUser.email).thenReturn('user@example.com');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.text('user@example.com'), findsOneWidget,
        reason: 'Should display the user email address');
    });

    testWidgets('displays email icon', (WidgetTester tester) async {
      /// Test Purpose: Verify visual email icon is present
      /// Icons improve visual communication
      /// Failure indicates incomplete UI design

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.byIcon(Icons.email_outlined), findsOneWidget,
        reason: 'Should display email icon');
    });

    testWidgets('shows sign out button in app bar', (WidgetTester tester) async {
      /// Test Purpose: Verify sign out option is available
      /// Users need ability to switch accounts if wrong email
      /// Failure indicates missing critical navigation

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.text('Sign Out'), findsOneWidget,
        reason: 'Should display sign out button in app bar');
    });

    testWidgets('sign out button calls authProvider.signOut', (WidgetTester tester) async {
      /// Test Purpose: Verify sign out button functionality
      /// Users need working sign out to switch accounts
      /// Failure indicates broken authentication flow

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial render

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete any timers

      verify(mockAuthProvider.signOut()).called(1);
    });

    testWidgets('displays resend countdown message initially', (WidgetTester tester) async {
      /// Test Purpose: Verify resend cooldown message is shown
      /// Users need to know when they can resend email
      /// Failure indicates poor UX feedback

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Just initial render, don't complete timer yet

      expect(find.textContaining('You can resend in 60 seconds'), findsOneWidget,
        reason: 'Should display resend countdown message initially');
    });

    testWidgets('shows resend button after cooldown period', (WidgetTester tester) async {
      /// Test Purpose: Verify resend button appears after cooldown
      /// Users need ability to request new verification email
      /// Failure indicates broken resend functionality

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial render

      // Initially should not show resend button
      expect(find.text('Resend Email'), findsNothing,
        reason: 'Should not show resend button initially');

      // Fast forward 60 seconds - pumpAndSettle with duration completes the timer
      await tester.pumpAndSettle(const Duration(seconds: 61));

      // Should now show resend button
      expect(find.text('Resend Email'), findsOneWidget,
        reason: 'Should show resend button after 60 seconds');
    });

    testWidgets('resend button calls sendEmailVerification', (WidgetTester tester) async {
      /// Test Purpose: Verify resend button triggers email send
      /// Users need working resend functionality
      /// Failure indicates broken email verification flow

      await tester.pumpWidget(createTestWidget());
      // Fast forward to show resend button
      await tester.pumpAndSettle(const Duration(seconds: 61));

      // Tap resend button
      await tester.tap(find.text('Resend Email'));
      await tester.pump();

      verify(mockAuthProvider.sendEmailVerification()).called(1);
    });

    testWidgets('resend button resets cooldown after click', (WidgetTester tester) async {
      /// Test Purpose: Verify resend button cooldown resets after use
      /// Prevents spam and implements proper rate limiting
      /// Failure indicates rate limiting doesn't work

      await tester.pumpWidget(createTestWidget());
      // Fast forward to show resend button
      await tester.pumpAndSettle(const Duration(seconds: 61));

      // Tap resend button - this triggers a new 60s timer
      await tester.tap(find.text('Resend Email'));
      await tester.pump(); // Process tap

      // Resend button should be hidden again (new timer started)
      expect(find.text('Resend Email'), findsNothing,
        reason: 'Resend button should be hidden after click');
      expect(find.textContaining('You can resend in 60 seconds'), findsOneWidget,
        reason: 'Should show cooldown message again');
    });

    testWidgets('displays success message when set', (WidgetTester tester) async {
      /// Test Purpose: Verify success message display
      /// Users need confirmation that email was sent
      /// Failure indicates missing user feedback

      when(mockAuthProvider.successMessage).thenReturn('Verification email sent! Please check your inbox.');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.text('Verification email sent! Please check your inbox.'), findsOneWidget,
        reason: 'Should display success message');
      expect(find.byIcon(Icons.check_circle), findsOneWidget,
        reason: 'Should display success icon');
    });

    testWidgets('displays error message when set', (WidgetTester tester) async {
      /// Test Purpose: Verify error message display
      /// Users need to see when email send fails
      /// Failure indicates poor error handling UX

      when(mockAuthProvider.error).thenReturn('Failed to send verification email: Network error');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.textContaining('Failed to send verification email'), findsOneWidget,
        reason: 'Should display error message');
      expect(find.byIcon(Icons.error), findsOneWidget,
        reason: 'Should display error icon');
    });

    testWidgets('success message has green styling', (WidgetTester tester) async {
      /// Test Purpose: Verify success message visual styling
      /// Color coding helps users quickly identify message type
      /// Failure indicates inconsistent UI design

      when(mockAuthProvider.successMessage).thenReturn('Success message');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      final successContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Success message'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = successContainer.decoration as BoxDecoration;
      expect((decoration.border as Border).top.color, equals(Colors.green),
        reason: 'Success message should have green border');
    });

    testWidgets('error message has red styling', (WidgetTester tester) async {
      /// Test Purpose: Verify error message visual styling
      /// Color coding helps users quickly identify errors
      /// Failure indicates inconsistent UI design

      when(mockAuthProvider.error).thenReturn('Error message');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      final errorContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Error message'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = errorContainer.decoration as BoxDecoration;
      expect((decoration.border as Border).top.color, equals(Colors.red),
        reason: 'Error message should have red border');
    });

    testWidgets('displays spam folder tip', (WidgetTester tester) async {
      /// Test Purpose: Verify helpful spam folder tip is shown
      /// Users often miss emails in spam - this is important UX
      /// Failure indicates missing helpful hint

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      expect(find.textContaining('Check your spam folder'), findsOneWidget,
        reason: 'Should display spam folder tip');
    });

    testWidgets('auto-check timer reloads user periodically', (WidgetTester tester) async {
      /// Test Purpose: Verify auto-check timer calls user.reload
      /// This is critical for detecting email verification completion
      /// Failure indicates broken auto-verification detection

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Reset verification count
      clearInteractions(mockUser);

      // Pump 3 seconds (one timer tick)
      await tester.pump(const Duration(seconds: 3));

      // Should have called reload
      verify(mockUser.reload()).called(greaterThan(0));
    });

    testWidgets('auto-check timer stops when widget disposed', (WidgetTester tester) async {
      /// Test Purpose: Verify timer cleanup on widget disposal
      /// Memory leaks from active timers must be prevented
      /// Failure indicates resource leak

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial render

      // Remove widget - this should cancel timers
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete any timers

      // Reset and pump more time
      clearInteractions(mockUser);
      await tester.pump(const Duration(seconds: 3));

      // Should NOT call reload after disposal
      verifyNever(mockUser.reload());
    });

    testWidgets('handles null user email gracefully', (WidgetTester tester) async {
      /// Test Purpose: Verify screen handles null email without crash
      /// Edge case protection for data integrity
      /// Failure indicates insufficient null safety

      when(mockUser.email).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      // Should display empty string or placeholder, not crash
      expect(find.byType(EmailVerificationScreen), findsOneWidget,
        reason: 'Should render without crashing when email is null');
    });

    testWidgets('handles null user gracefully', (WidgetTester tester) async {
      /// Test Purpose: Verify screen handles null user without crash
      /// Edge case protection for auth state
      /// Failure indicates insufficient null safety

      when(mockAuthProvider.user).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 61)); // Complete 60s timer

      // Should display empty string for email, not crash
      expect(find.byType(EmailVerificationScreen), findsOneWidget,
        reason: 'Should render without crashing when user is null');
    });

    testWidgets('resend button has refresh icon', (WidgetTester tester) async {
      /// Test Purpose: Verify resend button has appropriate icon
      /// Visual cues improve user understanding
      /// Failure indicates incomplete UI design

      await tester.pumpWidget(createTestWidget());
      // Fast forward to show resend button
      await tester.pumpAndSettle(const Duration(seconds: 61));

      // Button is ElevatedButton.icon, so just verify icon exists
      expect(find.byIcon(Icons.refresh), findsOneWidget,
        reason: 'Resend button should have refresh icon');
      expect(find.text('Resend Email'), findsOneWidget,
        reason: 'Resend button text should be visible');
    });

    testWidgets('displays all UI elements in correct hierarchy', (WidgetTester tester) async {
      /// Test Purpose: Verify complete UI structure
      /// Comprehensive check of all screen elements
      /// Failure indicates missing or misplaced UI components

      when(mockUser.email).thenReturn('complete@test.com');

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Just initial render, check elements before timer completes

      // Verify all major elements exist
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('We sent a verification link to:'), findsOneWidget);
      expect(find.text('complete@test.com'), findsOneWidget);
      expect(find.text('Click the link in the email to verify your account.'), findsOneWidget);
      expect(find.text('This page will update automatically when verified.'), findsOneWidget);
      expect(find.textContaining('You can resend in 60 seconds'), findsOneWidget);
      expect(find.textContaining('Check your spam folder'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
