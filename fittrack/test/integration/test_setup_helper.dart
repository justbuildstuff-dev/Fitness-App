import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/providers/exercise_library_provider.dart';
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
  /// This method does NOT initialize Firebase to avoid platform channel errors
  static Future<void> initializeFirebaseForWidgetTests() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // For widget tests, we don't need to initialize Firebase at all
    // The providers should be mocked and won't use Firebase platform channels
    // This prevents PlatformException channel-error issues
    
    return;
  }

  /// Create a test app wrapper with mocked providers
  /// This prevents real Firebase operations during widget testing
  ///
  /// Note: Providers are wrapped around MaterialApp (not inside home)
  /// so they are available to all routes pushed via Navigator
  static Widget createTestAppWithMockedProviders({
    required Widget child,
    app_auth.AuthProvider? authProvider,
    ProgramProvider? programProvider,
    ExerciseLibraryProvider? exerciseLibraryProvider,
  }) {
    final providers = <SingleChildWidget>[
      if (authProvider != null)
        ChangeNotifierProvider<app_auth.AuthProvider>.value(
          value: authProvider,
        ),
      if (programProvider != null)
        ChangeNotifierProvider<ProgramProvider>.value(
          value: programProvider,
        ),
      if (exerciseLibraryProvider != null)
        ChangeNotifierProvider<ExerciseLibraryProvider>.value(
          value: exerciseLibraryProvider,
        ),
    ];

    // If no providers, just return MaterialApp with child
    if (providers.isEmpty) {
      return MaterialApp(home: child);
    }

    // Wrap MaterialApp with providers so they're available to all routes
    return MultiProvider(
      providers: providers,
      child: MaterialApp(home: child),
    );
  }

  /// Create a minimal MaterialApp wrapper for testing individual widgets
  static Widget createBasicTestApp({required Widget child}) {
    return MaterialApp(
      home: child,
    );
  }
}

