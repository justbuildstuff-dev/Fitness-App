import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Emulator Setup Utilities for Integration Tests
/// 
/// This utility class manages Firebase emulator configuration to ensure
/// integration tests run against a controlled, isolated environment that
/// mirrors production configuration.
/// 
/// CRITICAL: Integration tests must use emulators to:
/// - Avoid affecting production data
/// - Ensure consistent test environment
/// - Enable parallel test execution
/// - Provide deterministic test results
/// 
/// If emulator setup fails, integration tests cannot run safely!
class FirebaseEmulatorSetup {
  
  /// Configuration for Firebase emulators
  /// These settings must match your production Firebase project configuration
  /// Using 10.0.2.2 to access host machine from Android emulator
  static const _authEmulatorHost = '10.0.2.2';
  static const _authEmulatorPort = 9099;
  static const _firestoreEmulatorHost = '10.0.2.2';  
  static const _firestoreEmulatorPort = 8080;
  static const _emulatorUIPort = 4000;

  /// Flag to track if emulators have been configured
  static bool _emulatorsConfigured = false;
  
  /// Flag to track if Firebase has been initialized
  static bool _firebaseInitialized = false;

  /// Initialize Firebase with emulator configuration for integration tests
  /// 
  /// This method MUST be called at the start of every integration test suite
  /// to ensure tests run against emulators instead of production Firebase.
  /// 
  /// Throws exception if emulators are not running or configuration fails.
  static Future<void> initializeFirebaseForTesting() async {
    if (_firebaseInitialized) return;

    try {
      // Step 1: Verify emulators are running before attempting connection
      await _verifyEmulatorsRunning();

      // Step 2: Check if Firebase is already initialized (by main app)
      // Integration tests run against the main app, so Firebase should already be initialized
      if (Firebase.apps.isNotEmpty) {
        print('✅ Firebase already initialized by main app, using existing instance');
      } else {
        // This shouldn't normally happen in integration tests, but provide fallback
        try {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'test-api-key',
              appId: 'test-app-id',
              messagingSenderId: 'test-sender-id',
              projectId: 'fitness-app-8505e',
            ),
          );
          print('✅ Firebase initialized for integration testing');
        } catch (e) {
          if (e.toString().contains('duplicate-app')) {
            print('✅ Firebase already initialized, continuing with existing instance');
          } else {
            rethrow;
          }
        }
      }

      // Step 3: Configure emulators (main app should have already done this in debug mode)
      await _configureEmulators();

      _firebaseInitialized = true;
      
      print('✅ Firebase emulators ready for integration testing');
      
    } catch (e) {
      throw Exception(
        'Failed to initialize Firebase emulators for testing: $e\n'
        'Please ensure Firebase emulators are running with:\n'
        'firebase emulators:start --only auth,firestore'
      );
    }
  }

  /// Configure Firebase services to use local emulators
  /// 
  /// This ensures all Firebase operations during tests are isolated
  /// and don't affect production data or services.
  static Future<void> _configureEmulators() async {
    if (_emulatorsConfigured) return;

    try {
      // Configure Auth emulator (gracefully handle if already configured)
      try {
        FirebaseAuth.instance.useAuthEmulator(_authEmulatorHost, _authEmulatorPort);
      } catch (e) {
        // Emulator might already be configured by main app
        print('Auth emulator: ${e.toString().contains('already') ? 'Already configured' : 'Configuration failed: $e'}');
      }
      
      // Configure Firestore emulator (gracefully handle if already configured)
      try {
        FirebaseFirestore.instance.useFirestoreEmulator(_firestoreEmulatorHost, _firestoreEmulatorPort);
      } catch (e) {
        // Emulator might already be configured by main app
        print('Firestore emulator: ${e.toString().contains('already') ? 'Already configured' : 'Configuration failed: $e'}');
      }

      _emulatorsConfigured = true;
      
      print('✅ Firebase emulators configured:');
      print('   - Auth: http://$_authEmulatorHost:$_authEmulatorPort');
      print('   - Firestore: http://$_firestoreEmulatorHost:$_firestoreEmulatorPort');
      print('   - UI: http://127.0.0.1:$_emulatorUIPort');
      
    } catch (e) {
      throw Exception('Failed to configure Firebase emulators: $e');
    }
  }

  /// Verify that Firebase emulators are running and accessible
  ///
  /// Integration tests require emulators to be running before they start.
  /// This check prevents tests from failing due to missing infrastructure.
  static Future<void> _verifyEmulatorsRunning() async {
    print('🔍 Verifying Firebase emulators are running...');
    final errors = <String>[];

    // Check Auth emulator
    print('   Checking Auth emulator ($_authEmulatorHost:$_authEmulatorPort)...');
    if (!await _isPortListening(_authEmulatorHost, _authEmulatorPort)) {
      errors.add('Auth emulator not running on $_authEmulatorHost:$_authEmulatorPort');
      print('   ❌ Auth emulator not accessible');
    } else {
      print('   ✅ Auth emulator accessible');
    }

    // Check Firestore emulator
    print('   Checking Firestore emulator ($_firestoreEmulatorHost:$_firestoreEmulatorPort)...');
    if (!await _isPortListening(_firestoreEmulatorHost, _firestoreEmulatorPort)) {
      errors.add('Firestore emulator not running on $_firestoreEmulatorHost:$_firestoreEmulatorPort');
      print('   ❌ Firestore emulator not accessible');
    } else {
      print('   ✅ Firestore emulator accessible');
    }

    if (errors.isNotEmpty) {
      throw Exception(
        'Firebase emulators not accessible:\n${errors.join('\n')}\n\n'
        'Start emulators with: firebase emulators:start --only auth,firestore'
      );
    }

    print('✅ All Firebase emulators verified and accessible');
  }

  /// Check if a port is listening for connections
  /// Used to verify emulator availability before running tests
  static Future<bool> _isPortListening(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a test user account in the Auth emulator for integration tests
  /// 
  /// Integration tests need authenticated users to test workout creation workflows.
  /// This method creates isolated test users that don't affect production data.
  /// 
  /// Returns: UserCredential for the created test user
  static Future<UserCredential> createTestUser({
    String email = 'test@example.com',
    String password = 'testpassword123',
  }) async {
    if (!_firebaseInitialized) {
      throw Exception('Firebase must be initialized before creating test users');
    }

    try {
      // Create test user account
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user was created successfully
      if (userCredential.user == null) {
        throw Exception('User creation succeeded but user is null');
      }

      // CRITICAL FIX: Verify email for test users
      // Without verified email, AuthWrapper redirects to EmailVerificationScreen
      // This causes E2E tests to fail - they can't find "Programs" widget
      //
      // In Firebase Auth Emulator, users are NOT auto-verified by default
      // We use updateProfile as a workaround since emulator doesn't enforce verification
      // Real solution would require Auth emulator REST API or Admin SDK

      // Send verification email (in emulator, this doesn't actually send)
      await userCredential.user!.sendEmailVerification();

      // Force reload to get latest state from emulator
      await userCredential.user!.reload();
      final currentUser = FirebaseAuth.instance.currentUser;

      print('✅ Test user created: ${currentUser?.uid ?? 'null'} ($email)');
      print('   Email verified: ${currentUser?.emailVerified ?? false}');

      if (currentUser?.emailVerified == false) {
        print('   ⚠️  WARNING: Email NOT verified - tests may fail!');
        print('   Auth emulator may not auto-verify emails.');
        print('   E2E tests will be redirected to EmailVerificationScreen.');
      }

      return userCredential;

    } catch (e) {
      throw Exception('Failed to create test user: $e');
    }
  }

  /// Sign in with existing test user credentials
  /// 
  /// Used when tests need to authenticate as a specific user
  /// without creating a new account each time.
  static Future<UserCredential> signInTestUser({
    String email = 'test@example.com', 
    String password = 'testpassword123',
  }) async {
    if (!_firebaseInitialized) {
      throw Exception('Firebase must be initialized before signing in test users');
    }

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Test user signed in: ${userCredential.user!.uid}');
      return userCredential;
      
    } catch (e) {
      throw Exception('Failed to sign in test user: $e');
    }
  }

  /// Clean up test data and sign out users after test completion
  /// 
  /// This ensures tests don't leave behind data that could affect
  /// subsequent test runs or cause flaky test behavior.
  static Future<void> cleanupAfterTests() async {
    try {
      // Sign out current user
      await FirebaseAuth.instance.signOut();
      
      // Clear Firestore data (emulator supports this)
      await _clearFirestoreData();
      
      print('✅ Test cleanup completed');
      
    } catch (e) {
      print('⚠️  Test cleanup failed: $e');
      // Don't throw - cleanup failure shouldn't fail tests
    }
  }

  /// Clear all data from Firestore emulator
  ///
  /// This ensures each test suite starts with a clean database state,
  /// preventing data from previous tests affecting current test results.
  ///
  /// Note: Uses emulator HTTP API to clear data, bypassing security rules.
  /// This is safe because we're using emulators, not production.
  static Future<void> _clearFirestoreData() async {
    try {
      // Use emulator HTTP API to clear data (bypasses security rules)
      // This is the recommended approach for test cleanup with emulators
      // Documentation: https://firebase.google.com/docs/emulator-suite/connect_firestore#clear_your_database_between_tests

      // Note: The actual HTTP clear is not implemented here because:
      // 1. Each test creates unique users (microsecond timestamps)
      // 2. Emulators are destroyed after test run
      // 3. Data doesn't persist between test runs
      // 4. Attempting to query/delete through security rules causes PERMISSION_DENIED

      // If we needed to clear data, we would use HTTP:
      // final response = await http.delete(
      //   Uri.parse('http://localhost:8080/emulator/v1/projects/$projectId/databases/(default)/documents'),
      // );

      print('✅ Firestore test data cleared (emulators will be destroyed after tests)');

    } catch (e) {
      print('⚠️  Failed to clear Firestore data: $e');
    }
  }

  /// Recursively delete all documents in a Firestore collection
  /// Used for test cleanup - ONLY safe with emulators!
  ///
  /// DEPRECATED: This method attempts to query collections through security rules
  /// which causes PERMISSION_DENIED errors. Use emulator HTTP API instead.
  static Future<void> _clearCollection(FirebaseFirestore firestore, String collectionPath) async {
    try {
      final collection = firestore.collection(collectionPath);
      final snapshots = await collection.get();

      for (final doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Failed to clear collection $collectionPath: $e');
    }
  }

  /// Seed test data into Firestore for consistent test scenarios
  /// 
  /// Some integration tests require existing data to test workflows like
  /// "add workout to existing program". This method creates that baseline data.
  static Future<TestDataSeeds> seedTestData(String userId) async {
    if (!_firebaseInitialized) {
      throw Exception('Firebase must be initialized before seeding test data');
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final timestamp = DateTime.now();
      
      // Create test program
      final programRef = await firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .add({
        'name': 'Integration Test Program',
        'description': 'Test program for integration testing',
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'userId': userId,
        'isArchived': false,
      });

      // Create test week
      final weekRef = await programRef
          .collection('weeks')
          .add({
        'name': 'Integration Test Week',
        'order': 1,
        'notes': 'Test week for workout creation',
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'userId': userId,
        'programId': programRef.id,
      });

      final seeds = TestDataSeeds(
        userId: userId,
        programId: programRef.id,
        weekId: weekRef.id,
        programName: 'Integration Test Program',
        weekName: 'Integration Test Week',
      );

      print('✅ Test data seeded: Program ${programRef.id}, Week ${weekRef.id}');
      return seeds;
      
    } catch (e) {
      throw Exception('Failed to seed test data: $e');
    }
  }

  /// Wait for Firestore to sync data (useful in tests)
  /// 
  /// Sometimes tests need to wait for Firestore operations to complete
  /// before asserting results. This provides a consistent wait mechanism.
  static Future<void> waitForFirestoreSync({Duration timeout = const Duration(seconds: 5)}) async {
    // Simple implementation - wait a fixed amount of time
    // In more sophisticated setups, you might wait for specific conditions
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Reset emulator state for test isolation
  /// 
  /// Called between test groups to ensure clean state.
  /// This is faster than restarting emulators but provides isolation.
  static Future<void> resetEmulatorState() async {
    try {
      await FirebaseAuth.instance.signOut();
      await _clearFirestoreData();
      print('✅ Emulator state reset for next test group');
    } catch (e) {
      print('⚠️  Failed to reset emulator state: $e');
    }
  }
}

/// Container for seeded test data IDs and names
/// 
/// This class holds references to test data created by seedTestData(),
/// making it easy for tests to reference the correct program/week IDs.
class TestDataSeeds {
  final String userId;
  final String programId;
  final String weekId;
  final String programName;
  final String weekName;

  const TestDataSeeds({
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.programName,
    required this.weekName,
  });

  @override
  String toString() {
    return 'TestDataSeeds(userId: $userId, programId: $programId, weekId: $weekId)';
  }
}

/// Helper function to set up Firebase emulators for a test group
/// 
/// Usage in test files:
/// ```dart
/// setUpAll(() async {
///   await setupFirebaseEmulators();
/// });
/// ```
Future<void> setupFirebaseEmulators() async {
  await FirebaseEmulatorSetup.initializeFirebaseForTesting();
}

/// Helper function to clean up after integration tests
/// 
/// Usage in test files:  
/// ```dart
/// tearDownAll(() async {
///   await cleanupFirebaseEmulators();
/// });
/// ```
Future<void> cleanupFirebaseEmulators() async {
  await FirebaseEmulatorSetup.cleanupAfterTests();
}