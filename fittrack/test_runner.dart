#!/usr/bin/env dart

/// DEPRECATED: Use test/test_suite.dart instead
/// 
/// This file has been replaced by the unified test suite at test/test_suite.dart
/// which provides better organization and consolidated test management.
/// 
/// To run tests, use:
/// dart test/test_suite.dart [--unit] [--widget] [--integration] [--analytics] [--all]

import 'dart:io';

void main(List<String> arguments) async {
  print('🚀 FitTrack Test Runner - Workout Creation Functionality');
  print('=' * 60);

  final runUnit = arguments.contains('--unit') || arguments.contains('--all') || arguments.isEmpty;
  final runWidget = arguments.contains('--widget') || arguments.contains('--all') || arguments.isEmpty;
  final runIntegration = arguments.contains('--integration') || arguments.contains('--all');

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

    // Step 3: Run Integration Tests
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

    print('\n🎉 All tests passed successfully!');
    print('✅ Workout creation functionality is working correctly');

  } catch (e) {
    print('❌ Test runner failed: $e');
    exit(1);
  }
}

/// Run all unit tests for models and business logic
Future<int> runUnitTests() async {
  final testFiles = [
    'test/models/workout_test.dart',
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
    'test/screens/create_workout_screen_test.dart',
    'test/screens/weeks_screen_workout_test.dart',
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
    print('Running integration tests...');
    final result = await Process.run(
      'flutter',
      ['test', 'test_integration/'],
      workingDirectory: '.',
    );

    if (result.exitCode != 0) {
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
      return result.exitCode;
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