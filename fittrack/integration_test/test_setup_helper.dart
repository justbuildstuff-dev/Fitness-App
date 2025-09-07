import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/exercise_set.dart';

/// Test setup utilities for integration tests
/// 
/// This helper provides standardized test setup that properly handles
/// Firebase initialization and provider mocking for different test types.
class TestSetupHelper {
  
  /// Initialize Firebase for widget tests that don't need real Firebase functionality
  /// This creates a minimal Firebase app to prevent initialization errors
  static Future<void> initializeFirebaseForWidgetTests() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Check if Firebase is already initialized
    try {
      Firebase.app();
      return; // Already initialized
    } catch (e) {
      // Firebase not initialized, proceed with initialization
    }

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-fittrack-widget',
      ),
    );
  }

  /// Create a test app wrapper with mocked providers
  /// This prevents real Firebase operations during widget testing
  static Widget createTestAppWithMockedProviders({
    required Widget child,
    app_auth.AuthProvider? authProvider,
    ProgramProvider? programProvider,
  }) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          if (authProvider != null)
            ChangeNotifierProvider<app_auth.AuthProvider>.value(
              value: authProvider,
            ),
          if (programProvider != null)
            ChangeNotifierProvider<ProgramProvider>.value(
              value: programProvider,
            ),
        ],
        child: child,
      ),
    );
  }

  /// Create a minimal MaterialApp wrapper for testing individual widgets
  static Widget createBasicTestApp({required Widget child}) {
    return MaterialApp(
      home: child,
    );
  }
}

