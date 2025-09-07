import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/providers/program_provider.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_auth.AuthProvider>.value(
          value: authProvider ?? MockAuthProvider(),
        ),
        ChangeNotifierProvider<ProgramProvider>.value(
          value: programProvider ?? MockProgramProvider(),
        ),
      ],
      child: MaterialApp(
        home: child,
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

/// Mock AuthProvider for widget tests
class MockAuthProvider extends Mock implements app_auth.AuthProvider {
  @override
  bool get isAuthenticated => false;
  
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
  
  @override
  String? get successMessage => null;
  
  @override
  void dispose() {
    // Override to prevent calling super.dispose() on mock
  }
  
  @override
  void notifyListeners() {
    // Override to prevent issues with mock
  }
}

/// Mock ProgramProvider for widget tests  
class MockProgramProvider extends Mock implements ProgramProvider {
  @override
  bool get isLoading => false;
  
  @override
  bool get isLoadingAnalytics => false;
  
  @override
  String? get error => null;
  
  @override
  List get programs => [];
  
  @override
  List get weeks => [];
  
  @override
  List get workouts => [];
  
  @override
  List get exercises => [];
  
  @override
  List get sets => [];
  
  @override
  void dispose() {
    // Override to prevent calling super.dispose() on mock
  }
  
  @override
  void notifyListeners() {
    // Override to prevent issues with mock
  }
}