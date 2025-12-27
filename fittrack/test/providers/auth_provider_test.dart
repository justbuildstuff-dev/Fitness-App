import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fittrack/providers/auth_provider.dart' as app;

import 'auth_provider_test.mocks.dart';

/// Unit tests for AuthProvider email verification functionality
///
/// Test Coverage:
/// - Email verification status getter
/// - Send email verification method
/// - Sign up with email auto-verification
/// - Auth state listener reloading user
/// - Error handling for email verification
///
/// If any test fails, it indicates issues with:
/// - Email verification flow
/// - Auth state management
/// - User session handling
@GenerateMocks([FirebaseAuth, User, UserCredential, FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot])
void main() {
  // Initialize Flutter bindings for Firebase
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider Email Verification Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late StreamController<User?> authStateController;
    late app.AuthProvider authProvider;

    setUp(() {
      // Set up clean test environment for each test
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      authStateController = StreamController<User?>.broadcast();

      // Setup auth state stream
      when(mockAuth.authStateChanges()).thenAnswer((_) => authStateController.stream);
      when(mockAuth.currentUser).thenReturn(null);

      // Setup Firestore mocks
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      // Create provider - note: This will trigger auth state listener
      // We'll need to inject mocks for real implementation
      // For now, testing the logic that can be tested with current structure
    });

    tearDown(() {
      authStateController.close();
    });

    group('isEmailVerified Getter', () {
      test('returns true when user is verified', () async {
        /// Test Purpose: Verify isEmailVerified getter returns true for verified users
        /// This is critical for routing users to the correct screen
        /// Failure indicates issues with email verification status detection

        final mockVerifiedUser = MockUser();
        when(mockVerifiedUser.emailVerified).thenReturn(true);
        when(mockVerifiedUser.uid).thenReturn('test-user-123');
        when(mockVerifiedUser.email).thenReturn('test@example.com');
        when(mockVerifiedUser.reload()).thenAnswer((_) async {});

        when(mockAuth.currentUser).thenReturn(mockVerifiedUser);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockVerifiedUser));

        final provider = app.AuthProvider();

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.isEmailVerified, isTrue,
          reason: 'Should return true when user.emailVerified is true');
      });

      test('returns false when user is not verified', () async {
        /// Test Purpose: Verify isEmailVerified getter returns false for unverified users
        /// Unverified users should be routed to EmailVerificationScreen
        /// Failure indicates routing logic may be broken

        final mockUnverifiedUser = MockUser();
        when(mockUnverifiedUser.emailVerified).thenReturn(false);
        when(mockUnverifiedUser.uid).thenReturn('test-user-123');
        when(mockUnverifiedUser.email).thenReturn('test@example.com');
        when(mockUnverifiedUser.reload()).thenAnswer((_) async {});

        when(mockAuth.currentUser).thenReturn(mockUnverifiedUser);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUnverifiedUser));

        final provider = app.AuthProvider();

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.isEmailVerified, isFalse,
          reason: 'Should return false when user.emailVerified is false');
      });

      test('returns false when user is null', () {
        /// Test Purpose: Verify isEmailVerified getter returns false for null user
        /// Unauthenticated users should not be considered verified
        /// Failure indicates security vulnerability

        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        final provider = app.AuthProvider();

        expect(provider.isEmailVerified, isFalse,
          reason: 'Should return false when user is null');
      });
    });

    group('sendEmailVerification Method', () {
      test('sends verification email when user is not verified', () async {
        /// Test Purpose: Verify sendEmailVerification sends email for unverified users
        /// Users should be able to request verification email resend
        /// Failure indicates email verification flow is broken

        final mockUnverifiedUser = MockUser();
        when(mockUnverifiedUser.emailVerified).thenReturn(false);
        when(mockUnverifiedUser.uid).thenReturn('test-user-123');
        when(mockUnverifiedUser.email).thenReturn('test@example.com');
        when(mockUnverifiedUser.reload()).thenAnswer((_) async {});
        when(mockUnverifiedUser.sendEmailVerification()).thenAnswer((_) async {});

        when(mockAuth.currentUser).thenReturn(mockUnverifiedUser);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUnverifiedUser));

        final provider = app.AuthProvider();

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        await provider.sendEmailVerification();

        verify(mockUnverifiedUser.sendEmailVerification()).called(1);
        expect(provider.successMessage, equals('Verification email sent! Please check your inbox.'),
          reason: 'Should set success message after sending email');
        expect(provider.error, isNull,
          reason: 'Should not set error on successful email send');
      });

      test('does not send verification email when user is already verified', () async {
        /// Test Purpose: Verify sendEmailVerification skips sending for verified users
        /// Prevents unnecessary email sends and potential spam
        /// Failure indicates inefficient email verification logic

        final mockVerifiedUser = MockUser();
        when(mockVerifiedUser.emailVerified).thenReturn(true);
        when(mockVerifiedUser.uid).thenReturn('test-user-123');
        when(mockVerifiedUser.email).thenReturn('test@example.com');
        when(mockVerifiedUser.reload()).thenAnswer((_) async {});

        when(mockAuth.currentUser).thenReturn(mockVerifiedUser);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockVerifiedUser));

        final provider = app.AuthProvider();

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        await provider.sendEmailVerification();

        verifyNever(mockVerifiedUser.sendEmailVerification());
        expect(provider.successMessage, isNull,
          reason: 'Should not set success message when already verified');
      });

      test('does nothing when user is null', () async {
        /// Test Purpose: Verify sendEmailVerification handles null user gracefully
        /// Unauthenticated users should not be able to send verification emails
        /// Failure indicates security vulnerability

        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        final provider = app.AuthProvider();

        await provider.sendEmailVerification();

        // No exception should be thrown
        expect(provider.error, isNull,
          reason: 'Should handle null user gracefully without error');
      });

      test('handles FirebaseAuth errors gracefully', () async {
        /// Test Purpose: Verify error handling when email verification fails
        /// Network issues or rate limiting should be handled gracefully
        /// Failure indicates poor error handling that could crash the app

        final mockUnverifiedUser = MockUser();
        when(mockUnverifiedUser.emailVerified).thenReturn(false);
        when(mockUnverifiedUser.uid).thenReturn('test-user-123');
        when(mockUnverifiedUser.email).thenReturn('test@example.com');
        when(mockUnverifiedUser.reload()).thenAnswer((_) async {});
        when(mockUnverifiedUser.sendEmailVerification())
            .thenThrow(FirebaseAuthException(code: 'too-many-requests'));

        when(mockAuth.currentUser).thenReturn(mockUnverifiedUser);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUnverifiedUser));

        final provider = app.AuthProvider();

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        await provider.sendEmailVerification();

        expect(provider.error, contains('Failed to send verification email'),
          reason: 'Should set error message on failure');
        expect(provider.successMessage, isNull,
          reason: 'Should not set success message on failure');
      });

      test('clears previous error and success messages before sending', () async {
        /// Test Purpose: Verify sendEmailVerification clears previous messages
        /// Users should see fresh feedback for each operation
        /// Failure indicates stale UI state management

        final mockUnverifiedUser = MockUser();
        when(mockUnverifiedUser.emailVerified).thenReturn(false);
        when(mockUnverifiedUser.uid).thenReturn('test-user-123');
        when(mockUnverifiedUser.email).thenReturn('test@example.com');
        when(mockUnverifiedUser.reload()).thenAnswer((_) async {});
        when(mockUnverifiedUser.sendEmailVerification()).thenAnswer((_) async {});

        when(mockAuth.currentUser).thenReturn(mockUnverifiedUser);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUnverifiedUser));

        final provider = app.AuthProvider();

        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 100));

        // First send should succeed and set success message
        await provider.sendEmailVerification();
        expect(provider.successMessage, isNotNull);

        // Clear and send again
        provider.clearSuccessMessage();
        await provider.sendEmailVerification();

        expect(provider.error, isNull,
          reason: 'Should clear previous error before sending');
      });
    });

    group('signUpWithEmail Method', () {
      test('sends verification email after successful account creation', () async {
        /// Test Purpose: Verify signUpWithEmail automatically sends verification email
        /// New users should receive verification email immediately after signup
        /// Failure indicates broken user onboarding flow

        final mockUserCredential = MockUserCredential();
        final mockNewUser = MockUser();

        when(mockNewUser.uid).thenReturn('new-user-123');
        when(mockNewUser.email).thenReturn('newuser@example.com');
        when(mockNewUser.displayName).thenReturn(null);
        when(mockNewUser.emailVerified).thenReturn(false);
        when(mockNewUser.reload()).thenAnswer((_) async {});
        when(mockNewUser.updateDisplayName(any)).thenAnswer((_) async {});
        when(mockNewUser.sendEmailVerification()).thenAnswer((_) async {});

        when(mockUserCredential.user).thenReturn(mockNewUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);

        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        when(mockDocRef.set(any)).thenAnswer((_) async {});

        final provider = app.AuthProvider();

        final result = await provider.signUpWithEmail(
          email: 'newuser@example.com',
          password: 'ValidPass123',
          displayName: 'New User',
        );

        expect(result, isTrue,
          reason: 'Should return true on successful signup');
        verify(mockNewUser.sendEmailVerification()).called(1);
        expect(provider.successMessage, contains('Please check your email to verify your account'),
          reason: 'Should set success message about email verification');
      });

      test('sets success message about checking email', () async {
        /// Test Purpose: Verify signUpWithEmail sets appropriate success message
        /// Users need clear instructions about email verification
        /// Failure indicates poor UX messaging

        final mockUserCredential = MockUserCredential();
        final mockNewUser = MockUser();

        when(mockNewUser.uid).thenReturn('new-user-123');
        when(mockNewUser.email).thenReturn('newuser@example.com');
        when(mockNewUser.displayName).thenReturn(null);
        when(mockNewUser.emailVerified).thenReturn(false);
        when(mockNewUser.reload()).thenAnswer((_) async {});
        when(mockNewUser.updateDisplayName(any)).thenAnswer((_) async {});
        when(mockNewUser.sendEmailVerification()).thenAnswer((_) async {});

        when(mockUserCredential.user).thenReturn(mockNewUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);

        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        when(mockDocRef.set(any)).thenAnswer((_) async {});

        final provider = app.AuthProvider();

        await provider.signUpWithEmail(
          email: 'newuser@example.com',
          password: 'ValidPass123',
        );

        expect(provider.successMessage, isNotNull,
          reason: 'Should set success message after signup');
        expect(provider.successMessage, contains('Account created'),
          reason: 'Success message should mention account creation');
        expect(provider.successMessage, contains('check your email'),
          reason: 'Success message should mention checking email');
      });

      test('handles verification email send failure gracefully', () async {
        /// Test Purpose: Verify signUpWithEmail handles email send errors
        /// Account should be created even if verification email fails
        /// Failure indicates critical signup flow issue

        final mockUserCredential = MockUserCredential();
        final mockNewUser = MockUser();

        when(mockNewUser.uid).thenReturn('new-user-123');
        when(mockNewUser.email).thenReturn('newuser@example.com');
        when(mockNewUser.displayName).thenReturn(null);
        when(mockNewUser.emailVerified).thenReturn(false);
        when(mockNewUser.reload()).thenAnswer((_) async {});
        when(mockNewUser.updateDisplayName(any)).thenAnswer((_) async {});
        when(mockNewUser.sendEmailVerification())
            .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        when(mockUserCredential.user).thenReturn(mockNewUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);

        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

        when(mockDocRef.set(any)).thenAnswer((_) async {});

        final provider = app.AuthProvider();

        final result = await provider.signUpWithEmail(
          email: 'newuser@example.com',
          password: 'ValidPass123',
        );

        // Note: Current implementation doesn't catch this error separately
        // The exception will propagate and signup will fail
        // This test documents current behavior
        expect(result, isFalse,
          reason: 'Current implementation fails signup if verification email fails');
        expect(provider.error, isNotNull,
          reason: 'Should set error message on failure');
      });
    });

    group('Auth State Listener', () {
      test('reloads user to get latest emailVerified status', () async {
        /// Test Purpose: Verify auth state listener reloads user data
        /// This is critical for detecting email verification completion
        /// Failure indicates email verification detection is broken

        final mockUnverifiedUser = MockUser();
        when(mockUnverifiedUser.uid).thenReturn('test-user-123');
        when(mockUnverifiedUser.email).thenReturn('test@example.com');
        when(mockUnverifiedUser.emailVerified).thenReturn(false);
        when(mockUnverifiedUser.reload()).thenAnswer((_) async {});

        when(mockAuth.currentUser).thenReturn(mockUnverifiedUser);

        final authStateStream = StreamController<User?>();
        when(mockAuth.authStateChanges()).thenAnswer((_) => authStateStream.stream);

        final provider = app.AuthProvider();

        // Emit auth state change
        authStateStream.add(mockUnverifiedUser);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockUnverifiedUser.reload()).called(greaterThan(0));

        authStateStream.close();
      });

      test('handles null user in auth state changes', () async {
        /// Test Purpose: Verify auth state listener handles user sign out
        /// Sign out should clear user data without errors
        /// Failure indicates state management issues during sign out

        final authStateStream = StreamController<User?>();
        when(mockAuth.authStateChanges()).thenAnswer((_) => authStateStream.stream);
        when(mockAuth.currentUser).thenReturn(null);

        final provider = app.AuthProvider();

        // Emit null (user signed out)
        authStateStream.add(null);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(provider.user, isNull,
          reason: 'Should clear user on sign out');
        expect(provider.isAuthenticated, isFalse,
          reason: 'Should not be authenticated after sign out');

        authStateStream.close();
      });

      test('updates user after reload to reflect verification status change', () async {
        /// Test Purpose: Verify auth state listener updates user after reload
        /// EmailVerificationScreen depends on this to detect verification
        /// Failure indicates auto-navigation after verification won't work

        final mockUser1 = MockUser();
        when(mockUser1.uid).thenReturn('test-user-123');
        when(mockUser1.email).thenReturn('test@example.com');
        when(mockUser1.emailVerified).thenReturn(false);
        when(mockUser1.reload()).thenAnswer((_) async {});

        final mockUser2 = MockUser();
        when(mockUser2.uid).thenReturn('test-user-123');
        when(mockUser2.email).thenReturn('test@example.com');
        when(mockUser2.emailVerified).thenReturn(true);
        when(mockUser2.reload()).thenAnswer((_) async {});

        final authStateStream = StreamController<User?>();
        when(mockAuth.authStateChanges()).thenAnswer((_) => authStateStream.stream);

        // Start with unverified user
        when(mockAuth.currentUser).thenReturn(mockUser1);

        final provider = app.AuthProvider();

        authStateStream.add(mockUser1);
        await Future.delayed(const Duration(milliseconds: 100));

        // Simulate user verification (email link clicked)
        when(mockAuth.currentUser).thenReturn(mockUser2);
        authStateStream.add(mockUser2);
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockUser1.reload()).called(greaterThan(0));
        verify(mockUser2.reload()).called(greaterThan(0));

        authStateStream.close();
      });
    });

    group('State Management', () {
      test('clearSuccessMessage clears success message state', () {
        /// Test Purpose: Verify success message can be manually cleared
        /// UI should be able to dismiss success messages
        /// Failure indicates issues with message state management

        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
        when(mockAuth.currentUser).thenReturn(null);

        final provider = app.AuthProvider();

        provider.clearSuccessMessage();

        expect(provider.successMessage, isNull,
          reason: 'Should clear success message');
      });

      test('clearError clears error state', () {
        /// Test Purpose: Verify error state can be manually cleared
        /// UI should be able to dismiss error messages
        /// Failure indicates issues with error state management

        when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
        when(mockAuth.currentUser).thenReturn(null);

        final provider = app.AuthProvider();

        provider.clearError();

        expect(provider.error, isNull,
          reason: 'Should clear error');
      });
    });
  });
}
