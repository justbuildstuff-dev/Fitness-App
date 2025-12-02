import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Integration Test Helper for Service-Level Tests
///
/// This helper provides utilities for integration tests in the `test/` directory
/// that run directly on the Ubuntu CI runner (not Android emulator).
///
/// **CRITICAL DISTINCTION:**
/// - Tests in `test/` → Run on Ubuntu runner → Use `localhost`
/// - Tests in `integration_test/` → Run on Android emulator → Use `10.0.2.2`
///
/// This helper is for SERVICE-LEVEL integration tests that:
/// - Connect to Firebase emulators
/// - Create real data in Firestore
/// - Validate actual Firebase operations
/// - Run fast (seconds, not minutes)
class FirebaseIntegrationTestHelper {
  /// Firebase emulator configuration for Ubuntu runner
  /// Uses localhost because tests run directly on CI runner, not Android emulator
  static const _authEmulatorHost = 'localhost';
  static const _authEmulatorPort = 9099;
  static const _firestoreEmulatorHost = 'localhost';
  static const _firestoreEmulatorPort = 8080;

  /// Track initialization state
  static bool _initialized = false;

  /// Initialize Firebase to connect to local emulators
  ///
  /// This method MUST be called in setUpAll() before any tests run.
  /// It configures Firebase to use localhost emulators instead of production.
  ///
  /// Example:
  /// ```dart
  /// setUpAll(() async {
  ///   await FirebaseIntegrationTestHelper.initializeFirebaseEmulators();
  /// });
  /// ```
  static Future<void> initializeFirebaseEmulators() async {
    if (_initialized) return;

    // Ensure Flutter binding is initialized for Firebase
    TestWidgetsFlutterBinding.ensureInitialized();

    try {
      // Initialize Firebase app
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'demo-project', // Emulator uses demo-project
        ),
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }

    // Connect to emulators
    try {
      FirebaseAuth.instance.useAuthEmulator(_authEmulatorHost, _authEmulatorPort);
    } catch (e) {
      // Already configured - ignore
    }

    try {
      FirebaseFirestore.instance.useFirestoreEmulator(
        _firestoreEmulatorHost,
        _firestoreEmulatorPort,
      );
    } catch (e) {
      // Already configured - ignore
    }

    _initialized = true;
    print('✅ Firebase emulators connected (localhost:$_firestoreEmulatorPort, localhost:$_authEmulatorPort)');
  }

  /// Create a test user and sign in
  ///
  /// Creates a new user in the Auth emulator and returns the User object.
  /// Use timestamp-based emails to avoid conflicts between test runs.
  ///
  /// Example:
  /// ```dart
  /// final user = await FirebaseIntegrationTestHelper.createTestUser();
  /// final userId = user.uid;
  /// ```
  static Future<User> createTestUser({
    String? email,
    String password = 'testpassword123',
  }) async {
    // Use timestamp for unique email if not provided
    final testEmail = email ?? 'test-${DateTime.now().millisecondsSinceEpoch}@fittrack.test';

    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: testEmail,
      password: password,
    );

    print('✅ Test user created: ${userCredential.user!.uid} ($testEmail)');
    return userCredential.user!;
  }

  /// Clear all Firestore data (emulator only!)
  ///
  /// Deletes all documents from specified collections.
  /// ONLY safe to use with emulator - never run against production!
  ///
  /// Example:
  /// ```dart
  /// setUp(() async {
  ///   await FirebaseIntegrationTestHelper.clearFirestore();
  /// });
  /// ```
  static Future<void> clearFirestore({
    List<String> collections = const ['users'],
  }) async {
    final db = FirebaseFirestore.instance;

    for (final collection in collections) {
      final snapshot = await db.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    print('✅ Firestore data cleared (${collections.length} collections)');
  }

  /// Sign out current user
  ///
  /// Should be called in tearDown() to clean up authentication state.
  ///
  /// Example:
  /// ```dart
  /// tearDown(() async {
  ///   await FirebaseIntegrationTestHelper.signOut();
  /// });
  /// ```
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Seed a complete program hierarchy in Firestore
  ///
  /// Creates a realistic test data structure:
  /// Program → Weeks → Workouts → Exercises → Sets
  ///
  /// Returns a map with programId and userId for use in tests.
  ///
  /// Example:
  /// ```dart
  /// final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
  ///   userId: userId,
  ///   weekCount: 2,
  ///   workoutsPerWeek: 3,
  /// );
  /// final programId = testData['programId']!;
  /// ```
  static Future<Map<String, String>> seedProgramHierarchy({
    required String userId,
    int weekCount = 2,
    int workoutsPerWeek = 3,
    int exercisesPerWorkout = 2,
    int setsPerExercise = 3,
  }) async {
    final db = FirebaseFirestore.instance;

    // Create program
    final programRef = await db
        .collection('users')
        .doc(userId)
        .collection('programs')
        .add({
      'name': 'Test Program',
      'description': 'Integration test program',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': userId,
    });

    // Create weeks
    for (int w = 0; w < weekCount; w++) {
      final weekRef = await programRef.collection('weeks').add({
        'weekNumber': w + 1,
        'name': 'Week ${w + 1}',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      // Create workouts
      for (int wo = 0; wo < workoutsPerWeek; wo++) {
        final workoutRef = await weekRef.collection('workouts').add({
          'name': 'Workout ${wo + 1}',
          'day': wo + 1,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': userId,
        });

        // Create exercises
        for (int e = 0; e < exercisesPerWorkout; e++) {
          final exerciseRef = await workoutRef.collection('exercises').add({
            'name': 'Exercise ${e + 1}',
            'exerciseType': 'strength',
            'order': e,
            'userId': userId,
          });

          // Create sets
          for (int s = 0; s < setsPerExercise; s++) {
            await exerciseRef.collection('sets').add({
              'setNumber': s + 1,
              'reps': 10,
              'weight': 100.0,
              'checked': false,
              'userId': userId,
            });
          }
        }
      }
    }

    print('✅ Test hierarchy seeded: programId=${programRef.id}');
    print('   → $weekCount weeks, ${weekCount * workoutsPerWeek} workouts, '
        '${weekCount * workoutsPerWeek * exercisesPerWorkout} exercises, '
        '${weekCount * workoutsPerWeek * exercisesPerWorkout * setsPerExercise} sets');

    return {
      'programId': programRef.id,
      'userId': userId,
    };
  }
}
