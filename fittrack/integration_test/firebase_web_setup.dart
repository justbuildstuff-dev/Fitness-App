import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Alternative Firebase Setup for Linux Desktop Integration Tests
/// 
/// This setup avoids platform channel issues by using Firebase Web SDK
/// configuration for Linux desktop environment, which is more compatible
/// with headless CI systems.
class FirebaseWebSetup {
  
  static const _authEmulatorHost = '127.0.0.1';
  static const _authEmulatorPort = 9099;
  static const _firestoreEmulatorHost = '127.0.0.1';  
  static const _firestoreEmulatorPort = 8080;

  static bool _firebaseInitialized = false;
  static bool _emulatorsConfigured = false;

  /// Initialize Firebase using web-compatible approach for Linux desktop
  /// 
  /// This bypasses platform channel issues by using Firebase configuration
  /// similar to web platform, which works better in headless environments.
  static Future<void> initializeFirebaseForLinuxTesting() async {
    if (_firebaseInitialized) return;

    try {
      print('🔍 Setting up Firebase for Linux desktop testing...');
      
      // Step 1: Verify emulators are accessible
      await _verifyEmulatorsRunning();
      
      // Step 2: Initialize Firebase with web-style configuration
      print('🚀 Initializing Firebase with web-compatible config for Linux...');
      
      // Check if already initialized by main app
      if (Firebase.apps.isNotEmpty) {
        print('✅ Firebase already initialized, using existing app');
      } else {
        // Initialize with minimal configuration optimized for testing
        await Firebase.initializeApp(
          name: 'integration_test_app',
          options: const FirebaseOptions(
            apiKey: 'demo-key',
            appId: 'demo-app',
            messagingSenderId: 'demo-sender',
            projectId: 'demo-project',  // Use demo project for emulators
            authDomain: 'localhost',
            storageBucket: 'demo-project.appspot.com',
          ),
        );
        print('✅ Firebase initialized for integration testing');
      }

      // Step 3: Configure emulators
      await _configureEmulators();
      
      _firebaseInitialized = true;
      print('✅ Firebase Linux desktop setup completed successfully');
      
    } catch (e, stackTrace) {
      print('❌ Firebase Linux setup failed: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Configure Firebase services to use local emulators
  static Future<void> _configureEmulators() async {
    if (_emulatorsConfigured) return;

    try {
      print('🔧 Configuring Firebase emulators...');
      
      // Get the Firebase app instance
      FirebaseApp app;
      if (Firebase.apps.where((app) => app.name == 'integration_test_app').isNotEmpty) {
        app = Firebase.app('integration_test_app');
      } else {
        app = Firebase.app();
      }
      
      // Configure Auth emulator
      try {
        FirebaseAuth.instanceFor(app: app).useAuthEmulator(
          _authEmulatorHost, 
          _authEmulatorPort,
        );
        print('✅ Auth emulator configured');
      } catch (e) {
        if (e.toString().contains('already')) {
          print('✅ Auth emulator already configured');
        } else {
          print('⚠️ Auth emulator config failed: $e');
        }
      }
      
      // Configure Firestore emulator
      try {
        FirebaseFirestore.instanceFor(app: app).useFirestoreEmulator(
          _firestoreEmulatorHost, 
          _firestoreEmulatorPort,
        );
        print('✅ Firestore emulator configured');
      } catch (e) {
        if (e.toString().contains('already')) {
          print('✅ Firestore emulator already configured');
        } else {
          print('⚠️ Firestore emulator config failed: $e');
        }
      }

      _emulatorsConfigured = true;
      print('✅ Emulator configuration completed');
      
    } catch (e) {
      print('❌ Emulator configuration failed: $e');
      rethrow;
    }
  }

  /// Verify that Firebase emulators are running and accessible
  static Future<void> _verifyEmulatorsRunning() async {
    final errors = <String>[];

    // Check Auth emulator
    if (!await _isPortListening(_authEmulatorHost, _authEmulatorPort)) {
      errors.add('Auth emulator not running on $_authEmulatorHost:$_authEmulatorPort');
    } else {
      print('✅ Auth emulator accessible on port $_authEmulatorPort');
    }

    // Check Firestore emulator  
    if (!await _isPortListening(_firestoreEmulatorHost, _firestoreEmulatorPort)) {
      errors.add('Firestore emulator not running on $_firestoreEmulatorHost:$_firestoreEmulatorPort');
    } else {
      print('✅ Firestore emulator accessible on port $_firestoreEmulatorPort');
    }

    if (errors.isNotEmpty) {
      throw Exception(
        'Firebase emulators not accessible:\n${errors.join('\n')}'
      );
    }
  }

  /// Check if a port is listening for connections
  static Future<bool> _isPortListening(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a test user account for integration tests
  static Future<UserCredential> createTestUser({
    String email = 'test@example.com',
    String password = 'testpassword123',
  }) async {
    if (!_firebaseInitialized) {
      throw Exception('Firebase must be initialized before creating test users');
    }

    try {
      // Get the appropriate Firebase Auth instance
      FirebaseAuth auth;
      if (Firebase.apps.where((app) => app.name == 'integration_test_app').isNotEmpty) {
        auth = FirebaseAuth.instanceFor(app: Firebase.app('integration_test_app'));
      } else {
        auth = FirebaseAuth.instance;
      }

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Test user created: ${userCredential.user!.uid}');
      return userCredential;
      
    } catch (e) {
      print('❌ Failed to create test user: $e');
      rethrow;
    }
  }

  /// Clean up test data after tests
  static Future<void> cleanupAfterTests() async {
    try {
      // Sign out from all auth instances
      if (Firebase.apps.isNotEmpty) {
        for (final app in Firebase.apps) {
          try {
            await FirebaseAuth.instanceFor(app: app).signOut();
          } catch (e) {
            print('⚠️ Failed to sign out from app ${app.name}: $e');
          }
        }
      }
      
      print('✅ Test cleanup completed');
      
    } catch (e) {
      print('⚠️ Test cleanup failed: $e');
    }
  }

  /// Reset setup state (for test isolation)
  static void reset() {
    _firebaseInitialized = false;
    _emulatorsConfigured = false;
  }
}

/// Helper functions for easy integration
Future<void> setupFirebaseEmulatorsLinux() async {
  await FirebaseWebSetup.initializeFirebaseForLinuxTesting();
}

Future<void> cleanupFirebaseEmulatorsLinux() async {
  await FirebaseWebSetup.cleanupAfterTests();
}