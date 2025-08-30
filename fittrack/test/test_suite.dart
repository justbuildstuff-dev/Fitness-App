#!/usr/bin/env dart

/// Comprehensive Test Suite Runner for FitTrack Application
/// 
/// This is the unified entry point for all testing in the FitTrack application.
/// It consolidates unit tests, widget tests, and integration tests into a single
/// cohesive testing framework that ensures all functionality works correctly.
/// 
/// Usage:
/// dart test/test_suite.dart [--unit] [--widget] [--integration] [--all] [--analytics]
/// 
/// Test Categories:
/// - Unit Tests: Model validation, business logic, service methods
/// - Widget Tests: UI component behavior, user interactions  
/// - Integration Tests: End-to-end workflows with Firebase emulators
/// - Analytics Tests: Specialized tests for analytics functionality
/// 
/// Requirements:
/// - Flutter SDK installed and in PATH
/// - Firebase CLI installed for integration tests
/// - Firebase emulators configured for the project

import 'dart:io';
import 'test_config.dart';

// Import all test modules
import 'models/analytics_test.dart' as analytics_models;
import 'models/analytics_edge_cases_test.dart' as analytics_edge_cases;
import 'models/exercise_test.dart' as exercise_models;
import 'models/exercise_set_test.dart' as exercise_set_models;
import 'models/program_test.dart' as program_models;
import 'models/week_test.dart' as week_models;
import 'models/workout_test.dart' as workout_models;

import 'services/analytics_service_test.dart' as analytics_service;

import 'providers/program_provider_analytics_test.dart' as provider_analytics;
import 'providers/program_provider_workout_test.dart' as provider_workout;

import 'screens/analytics_screen_test.dart' as screen_analytics;
import 'screens/create_exercise_screen_test.dart' as screen_create_exercise;
import 'screens/create_set_screen_test.dart' as screen_create_set;
import 'screens/create_workout_screen_test.dart' as screen_create_workout;
import 'screens/weeks_screen_workout_test.dart' as screen_weeks_workout;

void main(List<String> arguments) async {
  print('🧪 FitTrack Comprehensive Test Suite');
  print('=' * 60);
  
  final runUnit = arguments.contains('--unit') || arguments.contains('--all') || arguments.isEmpty;
  final runWidget = arguments.contains('--widget') || arguments.contains('--all') || arguments.isEmpty;
  final runIntegration = arguments.contains('--integration') || arguments.contains('--all');
  final runAnalytics = arguments.contains('--analytics') || arguments.contains('--all');
  
  var exitCode = 0;
  
  try {
    // Step 1: Run Unit Tests
    if (runUnit) {
      print('\n📋 Running Unit Tests...');
      print('-' * 40);
      exitCode = await runUnitTests();
      if (exitCode != 0) {
        print('❌ Unit tests failed with exit code: $exitCode');
        exit(exitCode);
      }
      print('✅ Unit tests passed!');
    }
    
    // Step 2: Run Widget Tests
    if (runWidget) {
      print('\n🎨 Running Widget Tests...');
      print('-' * 40);
      exitCode = await runWidgetTests();
      if (exitCode != 0) {
        print('❌ Widget tests failed with exit code: $exitCode');
        exit(exitCode);
      }
      print('✅ Widget tests passed!');
    }
    
    // Step 3: Run Analytics Tests
    if (runAnalytics) {
      print('\n📊 Running Analytics Tests...');
      print('-' * 40);
      exitCode = await runAnalyticsTests();
      if (exitCode != 0) {
        print('❌ Analytics tests failed with exit code: $exitCode');
        exit(exitCode);
      }
      print('✅ Analytics tests passed!');
    }
    
    // Step 4: Run Integration Tests
    if (runIntegration) {
      print('\n🔗 Running Integration Tests...');
      print('-' * 40);
      exitCode = await runIntegrationTests();
      if (exitCode != 0) {
        print('❌ Integration tests failed with exit code: $exitCode');
        exit(exitCode);
      }
      print('✅ Integration tests passed!');
    }
    
    print('\n🎉 All selected tests passed successfully!');
    print('✅ FitTrack application functionality verified');
    
  } catch (e) {
    print('❌ Test runner failed: $e');
    exit(1);
  }
}

/// Run all unit tests for models, services, and business logic
Future<int> runUnitTests() async {
  final testFiles = [
    // Model tests
    'test/models/exercise_test.dart',
    'test/models/exercise_set_test.dart',
    'test/models/program_test.dart',
    'test/models/week_test.dart',
    'test/models/workout_test.dart',
    
    // Service tests (non-analytics)
    // Add other service tests here as they are created
    
    // Provider tests (non-analytics, non-widget)
    'test/providers/program_provider_workout_test.dart',
  ];
  
  for (final testFile in testFiles) {
    print('Running $testFile...');
    final result = await Process.run(
      'flutter',
      ['test', testFile],
      workingDirectory: '.',
    );
    
    if (result.exitCode != 0) {
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
      return result.exitCode;
    }
  }
  
  return 0;
}

/// Run all widget tests for UI components
Future<int> runWidgetTests() async {
  final testFiles = [
    'test/screens/create_exercise_screen_test.dart',
    'test/screens/create_set_screen_test.dart', 
    'test/screens/create_workout_screen_test.dart',
    'test/screens/weeks_screen_workout_test.dart',
    'test/widget_test.dart',
  ];
  
  for (final testFile in testFiles) {
    print('Running $testFile...');
    final result = await Process.run(
      'flutter',
      ['test', testFile],
      workingDirectory: '.',
    );
    
    if (result.exitCode != 0) {
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
      return result.exitCode;
    }
  }
  
  return 0;
}

/// Run all analytics-specific tests
Future<int> runAnalyticsTests() async {
  final testFiles = [
    // Analytics model tests
    'test/models/analytics_test.dart',
    'test/models/analytics_edge_cases_test.dart',
    
    // Analytics service tests
    'test/services/analytics_service_test.dart',
    
    // Analytics provider tests
    'test/providers/program_provider_analytics_test.dart',
    
    // Analytics UI tests
    'test/screens/analytics_screen_test.dart',
  ];
  
  for (final testFile in testFiles) {
    print('Running $testFile...');
    final result = await Process.run(
      'flutter',
      ['test', testFile],
      workingDirectory: '.',
    );
    
    if (result.exitCode != 0) {
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
      return result.exitCode;
    }
  }
  
  return 0;
}

/// Run integration tests against Firebase emulators
Future<int> runIntegrationTests() async {
  // Step 1: Check if Firebase CLI is available
  try {
    final firebaseCheck = await Process.run('firebase', ['--version']);
    print('Firebase CLI version: ${firebaseCheck.stdout.toString().trim()}');
  } catch (e) {
    print('❌ Firebase CLI not found. Please install it first:');
    print('   npm install -g firebase-tools');
    return 1;
  }
  
  // Step 2: Check if emulators are already running
  final emulatorStatus = await checkEmulatorsRunning();
  bool shouldStopEmulators = false;
  
  if (!emulatorStatus) {
    print('🔧 Starting Firebase emulators...');
    
    // Start emulators in background
    final emulatorProcess = await Process.start(
      'firebase',
      ['emulators:start', '--only', 'auth,firestore'],
      workingDirectory: '.',
    );
    
    // Wait for emulators to start
    print('⏳ Waiting for emulators to initialize...');
    await Future.delayed(Duration(seconds: 10));
    
    // Verify emulators are now running
    if (!await checkEmulatorsRunning()) {
      print('❌ Failed to start Firebase emulators');
      emulatorProcess.kill();
      return 1;
    }
    
    shouldStopEmulators = true;
    print('✅ Firebase emulators started');
  } else {
    print('✅ Firebase emulators already running');
  }
  
  try {
    // Step 3: Run integration tests
    final testFiles = [
      'test/integration/analytics_integration_test.dart',
      'test/integration/workout_creation_integration_test.dart',
    ];
    
    for (final testFile in testFiles) {
      print('Running $testFile...');
      final result = await Process.run(
        'flutter',
        ['test', testFile],
        workingDirectory: '.',
      );
      
      if (result.exitCode != 0) {
        print('STDOUT: ${result.stdout}');
        print('STDERR: ${result.stderr}');
        return result.exitCode;
      }
    }
    
    return 0;
    
  } finally {
    // Step 4: Clean up emulators if we started them
    if (shouldStopEmulators) {
      print('🧹 Stopping Firebase emulators...');
      await Process.run('pkill', ['-f', 'firebase.*emulators']);
    }
  }
}

/// Check if Firebase emulators are running
Future<bool> checkEmulatorsRunning() async {
  try {
    // Check Auth emulator (port 9099)
    final authSocket = await Socket.connect('127.0.0.1', 9099, timeout: Duration(seconds: 2));
    authSocket.destroy();
    
    // Check Firestore emulator (port 8080)
    final firestoreSocket = await Socket.connect('127.0.0.1', 8080, timeout: Duration(seconds: 2));
    firestoreSocket.destroy();
    
    return true;
  } catch (e) {
    return false;
  }
}

/// Test configuration and utilities
class TestConfig {
  static const String testUserId = 'fittrack_test_user';
  static const int performanceThresholdMs = 1000;
  static const int largeDatasetSize = 1000;
  
  /// Print test suite summary
  static void printTestSummary() {
    print('\n📊 Test Suite Summary:');
    print('├── Unit Tests: Models, Services, Business Logic');
    print('├── Widget Tests: UI Components, User Interactions');  
    print('├── Analytics Tests: Analytics Models, Services, UI');
    print('└── Integration Tests: End-to-end Workflows');
  }
}