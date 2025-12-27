import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:fittrack/providers/auth_provider.dart' as app;
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/screens/auth/auth_wrapper.dart';
import 'package:fittrack/screens/auth/sign_in_screen.dart';
import 'package:fittrack/screens/auth/email_verification_screen.dart';
import 'package:fittrack/screens/home/home_screen.dart';

import 'auth_wrapper_test.mocks.dart';

/// Widget tests for AuthWrapper routing logic
///
/// Test Coverage:
/// - Loading state display
/// - Route to SignInScreen when not authenticated
/// - Route to EmailVerificationScreen when authenticated but not verified
/// - Route to HomeScreen when authenticated and verified
/// - Null user handling
///
/// If any test fails, it indicates issues with:
/// - Authentication routing logic
/// - Email verification flow
/// - User session management
@GenerateMocks([app.AuthProvider, User])
@GenerateNiceMocks([MockSpec<ProgramProvider>()])
void main() {
  group('AuthWrapper Routing Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockUser mockUser;
    late MockProgramProvider mockProgramProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockUser = MockUser();
      mockProgramProvider = MockProgramProvider();

      // Default mock setup
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockAuthProvider.isEmailVerified).thenReturn(false);
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.error).thenReturn(null); // Stub error getter to prevent MissingStubError
      when(mockAuthProvider.userProfile).thenReturn(null); // Stub userProfile getter for HomeScreen

      // Stub mockUser properties used by HomeScreen
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.uid).thenReturn('test-user-123');
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<app.AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ProgramProvider>.value(value: mockProgramProvider),
          ],
          child: const AuthWrapper(),
        ),
      );
    }

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      /// Test Purpose: Verify loading state display during auth check
      /// Users need visual feedback during authentication state check
      /// Failure indicates missing loading state UX

      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'Should display loading indicator when isLoading is true');
      expect(find.byType(SignInScreen), findsNothing,
        reason: 'Should not show SignInScreen while loading');
      expect(find.byType(EmailVerificationScreen), findsNothing,
        reason: 'Should not show EmailVerificationScreen while loading');
      expect(find.byType(HomeScreen), findsNothing,
        reason: 'Should not show HomeScreen while loading');
    });

    testWidgets('routes to SignInScreen when not authenticated', (WidgetTester tester) async {
      /// Test Purpose: Verify unauthenticated users see sign in screen
      /// Critical for authentication flow
      /// Failure indicates broken auth routing

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(SignInScreen), findsOneWidget,
        reason: 'Should display SignInScreen when not authenticated');
      expect(find.byType(EmailVerificationScreen), findsNothing,
        reason: 'Should not show EmailVerificationScreen');
      expect(find.byType(HomeScreen), findsNothing,
        reason: 'Should not show HomeScreen');
    });

    testWidgets('routes to EmailVerificationScreen when authenticated but not verified', (WidgetTester tester) async {
      /// Test Purpose: Verify unverified users see verification screen
      /// Critical for email verification flow
      /// Failure indicates broken verification routing

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(false);
      when(mockAuthProvider.user).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockAuthProvider.successMessage).thenReturn(null);
      when(mockAuthProvider.sendEmailVerification()).thenAnswer((_) async {});
      when(mockAuthProvider.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      // EmailVerificationScreen has 60s timer, complete it to allow test to finish
      await tester.pumpAndSettle(const Duration(seconds: 61));

      expect(find.byType(EmailVerificationScreen), findsOneWidget,
        reason: 'Should display EmailVerificationScreen when authenticated but not verified');
      expect(find.byType(SignInScreen), findsNothing,
        reason: 'Should not show SignInScreen');
      expect(find.byType(HomeScreen), findsNothing,
        reason: 'Should not show HomeScreen until verified');
    });

    testWidgets('routes to HomeScreen when authenticated and verified', (WidgetTester tester) async {
      /// Test Purpose: Verify verified users see home screen
      /// Critical for normal app access after verification
      /// Failure indicates broken main app routing

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(true);
      when(mockAuthProvider.user).thenReturn(mockUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(HomeScreen), findsOneWidget,
        reason: 'Should display HomeScreen when authenticated and verified');
      expect(find.byType(SignInScreen), findsNothing,
        reason: 'Should not show SignInScreen');
      expect(find.byType(EmailVerificationScreen), findsNothing,
        reason: 'Should not show EmailVerificationScreen when verified');
    });

    testWidgets('handles null user gracefully when not authenticated', (WidgetTester tester) async {
      /// Test Purpose: Verify null user doesn't cause crash
      /// Edge case protection for auth state
      /// Failure indicates insufficient null safety

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockAuthProvider.user).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(SignInScreen), findsOneWidget,
        reason: 'Should display SignInScreen when user is null');
      expect(find.byType(AuthWrapper), findsOneWidget,
        reason: 'Should not crash when user is null');
    });

    testWidgets('loading indicator is centered on screen', (WidgetTester tester) async {
      /// Test Purpose: Verify loading indicator positioning
      /// Good UX requires centered loading indicator
      /// Failure indicates poor loading state UX

      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      // Find the Center widget containing the loading indicator
      final centerFinder = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(Center),
      );

      expect(centerFinder, findsOneWidget,
        reason: 'Loading indicator should be centered');
    });

    testWidgets('uses Consumer to rebuild on auth state changes', (WidgetTester tester) async {
      /// Test Purpose: Verify AuthWrapper responds to auth state changes
      /// Critical for reactive routing based on auth state
      /// Failure indicates broken reactive UI

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(SignInScreen), findsOneWidget,
        reason: 'Should initially show SignInScreen');

      // Simulate authentication
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(true);
      when(mockAuthProvider.user).thenReturn(mockUser);

      // Trigger rebuild by pumping
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(HomeScreen), findsOneWidget,
        reason: 'Should update to HomeScreen after authentication');
    });

    testWidgets('transitions from loading to sign in correctly', (WidgetTester tester) async {
      /// Test Purpose: Verify smooth transition from loading to sign in
      /// Critical for app startup flow
      /// Failure indicates jarring UX during startup

      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish loading
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(SignInScreen), findsOneWidget,
        reason: 'Should transition to SignInScreen after loading');
      expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'Should hide loading indicator');
    });

    testWidgets('transitions from sign in to verification correctly', (WidgetTester tester) async {
      /// Test Purpose: Verify smooth transition during signup flow
      /// Critical for new user onboarding
      /// Failure indicates broken signup flow

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() for initial SignInScreen

      expect(find.byType(SignInScreen), findsOneWidget);

      // User signs up (authenticated but not verified)
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(false);
      when(mockAuthProvider.user).thenReturn(mockUser);
      when(mockUser.email).thenReturn('newuser@example.com');
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockAuthProvider.successMessage).thenReturn(null);
      when(mockAuthProvider.sendEmailVerification()).thenAnswer((_) async {});
      when(mockAuthProvider.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      // EmailVerificationScreen has 60s timer, complete it to allow test to finish
      await tester.pumpAndSettle(const Duration(seconds: 61));

      expect(find.byType(EmailVerificationScreen), findsOneWidget,
        reason: 'Should transition to EmailVerificationScreen after signup');
      expect(find.byType(SignInScreen), findsNothing,
        reason: 'Should hide SignInScreen');
    });

    testWidgets('transitions from verification to home correctly', (WidgetTester tester) async {
      /// Test Purpose: Verify smooth transition after email verification
      /// Critical for completing signup flow
      /// Failure indicates broken verification flow

      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(false);
      when(mockAuthProvider.user).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockAuthProvider.successMessage).thenReturn(null);
      when(mockAuthProvider.sendEmailVerification()).thenAnswer((_) async {});
      when(mockAuthProvider.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      // EmailVerificationScreen has 60s timer, complete it to allow test to finish
      await tester.pumpAndSettle(const Duration(seconds: 61));

      expect(find.byType(EmailVerificationScreen), findsOneWidget);

      // User verifies email
      when(mockAuthProvider.isEmailVerified).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() for HomeScreen to avoid infinite timer timeout

      expect(find.byType(HomeScreen), findsOneWidget,
        reason: 'Should transition to HomeScreen after verification');
      expect(find.byType(EmailVerificationScreen), findsNothing,
        reason: 'Should hide EmailVerificationScreen');
    });

    testWidgets('shows loading indicator in Scaffold', (WidgetTester tester) async {
      /// Test Purpose: Verify loading indicator is in proper container
      /// Ensures loading state has proper app structure
      /// Failure indicates incomplete loading state implementation

      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      final scaffoldFinder = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(Scaffold),
      );

      expect(scaffoldFinder, findsOneWidget,
        reason: 'Loading indicator should be within a Scaffold');
    });

    testWidgets('routing priority: loading > sign in > verification > home', (WidgetTester tester) async {
      /// Test Purpose: Verify routing priority order is correct
      /// Ensures proper flow through authentication states
      /// Failure indicates incorrect routing logic

      // Priority 1: Loading
      when(mockAuthProvider.isLoading).thenReturn(true);
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'Loading should have highest priority');

      // Priority 2: Not authenticated (even if verified flag is true)
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockAuthProvider.isEmailVerified).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() to avoid infinite timer timeout

      expect(find.byType(SignInScreen), findsOneWidget,
        reason: 'Sign in should show when not authenticated');

      // Priority 3: Authenticated but not verified
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isEmailVerified).thenReturn(false);
      when(mockAuthProvider.user).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.reload()).thenAnswer((_) async {});
      when(mockAuthProvider.successMessage).thenReturn(null);
      when(mockAuthProvider.sendEmailVerification()).thenAnswer((_) async {});
      when(mockAuthProvider.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      // EmailVerificationScreen has 60s timer, complete it to allow test to finish
      await tester.pumpAndSettle(const Duration(seconds: 61));

      expect(find.byType(EmailVerificationScreen), findsOneWidget,
        reason: 'Verification screen should show when not verified');

      // Priority 4: Authenticated and verified
      when(mockAuthProvider.isEmailVerified).thenReturn(true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() for HomeScreen to avoid infinite timer timeout

      expect(find.byType(HomeScreen), findsOneWidget,
        reason: 'Home screen should show when authenticated and verified');
    });
  });
}
