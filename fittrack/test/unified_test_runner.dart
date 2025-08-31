/// Unified test runner for FitTrack comprehensive test suite
/// 
/// Features:
/// - Run all tests or specific categories
/// - Performance monitoring and benchmarking
/// - Coverage analysis and reporting
/// - Firebase emulator management
/// - Detailed result reporting
/// 
/// Usage:
/// dart test/unified_test_runner.dart --all
/// dart test/unified_test_runner.dart --unit
/// dart test/unified_test_runner.dart --widget
/// dart test/unified_test_runner.dart --integration
/// dart test/unified_test_runner.dart --performance

import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) async {
  final testRunner = UnifiedTestRunner();
  
  if (arguments.isEmpty || arguments.contains('--help')) {
    testRunner.printUsage();
    return;
  }
  
  try {
    await testRunner.run(arguments);
  } catch (e) {
    print('❌ Test execution failed: $e');
    exit(1);
  }
}

class UnifiedTestRunner {
  final List<TestSuiteResult> _results = [];
  late DateTime _startTime;
  
  /// Main test execution method
  Future<void> run(List<String> arguments) async {
    _startTime = DateTime.now();
    
    print('🧪 FitTrack Comprehensive Test Suite');
    print('📅 Started: ${_startTime.toIso8601String()}');
    print('');
    
    final shouldRunAll = arguments.contains('--all');
    final shouldRunUnit = arguments.contains('--unit') || shouldRunAll;
    final shouldRunWidget = arguments.contains('--widget') || shouldRunAll;
    final shouldRunIntegration = arguments.contains('--integration') || shouldRunAll;
    final shouldRunPerformance = arguments.contains('--performance') || shouldRunAll;
    final shouldRunEnhanced = arguments.contains('--enhanced') || shouldRunAll;
    final withCoverage = arguments.contains('--coverage') || shouldRunAll;
    
    try {
      if (shouldRunUnit) {
        await _runUnitTests(withCoverage);
      }
      
      if (shouldRunWidget) {
        await _runWidgetTests();
      }
      
      if (shouldRunIntegration) {
        await _runIntegrationTests();
      }
      
      if (shouldRunPerformance) {
        await _runPerformanceTests();
      }
      
      if (shouldRunEnhanced) {
        await _runEnhancedTests();
      }
      
      await _generateSummaryReport();
      
    } catch (e) {
      print('❌ Test execution error: $e');
      rethrow;
    }
  }

  /// Run unit tests (models, services, providers)
  Future<void> _runUnitTests(bool withCoverage) async {
    print('🔬 Running Unit Tests...');
    
    final args = [
      'test',
      'test/models/*_test.dart',
      'test/services/*_test.dart', 
      'test/providers/*_test.dart',
    ];
    
    if (withCoverage) {
      args.add('--coverage');
    }
    
    final result = await _runFlutterTest('Unit Tests', args);
    _results.add(result);
    
    if (withCoverage) {
      await _generateCoverageReport();
    }
  }

  /// Run widget tests (screens, widgets)
  Future<void> _runWidgetTests() async {
    print('🖼️  Running Widget Tests...');
    
    final result = await _runFlutterTest('Widget Tests', [
      'test',
      'test/screens/*_test.dart',
      'test/widgets/*_test.dart',
    ]);
    
    _results.add(result);
  }

  /// Run integration tests with Firebase emulators
  Future<void> _runIntegrationTests() async {
    print('🔗 Running Integration Tests...');
    
    // Start Firebase emulators
    print('🔥 Starting Firebase emulators...');
    final emulatorProcess = await _startFirebaseEmulators();
    
    try {
      // Wait for emulators to be ready
      await _waitForEmulators();
      
      final result = await _runFlutterTest('Integration Tests', [
        'test',
        'test/integration/*_test.dart',
      ]);
      
      _results.add(result);
      
    } finally {
      // Always stop emulators
      await _stopFirebaseEmulators(emulatorProcess);
    }
  }

  /// Run performance and load tests
  Future<void> _runPerformanceTests() async {
    print('⚡ Running Performance Tests...');
    
    final result = await _runFlutterTest('Performance Tests', [
      'test',
      'test/performance/',
      '--reporter=verbose',
    ]);
    
    _results.add(result);
  }

  /// Run enhanced comprehensive tests
  Future<void> _runEnhancedTests() async {
    print('🎯 Running Enhanced Test Suite...');
    
    // Start emulators for enhanced integration tests
    final emulatorProcess = await _startFirebaseEmulators();
    
    try {
      await _waitForEmulators();
      
      final result = await _runFlutterTest('Enhanced Tests', [
        'test',
        'test/models/enhanced_*.dart',
        'test/services/enhanced_*.dart',
        'test/screens/enhanced_*.dart',
        'test/widgets/enhanced_*.dart',
        'test/integration/enhanced_*.dart',
        '--reporter=verbose',
      ]);
      
      _results.add(result);
      
    } finally {
      await _stopFirebaseEmulators(emulatorProcess);
    }
  }

  /// Execute Flutter test command
  Future<TestSuiteResult> _runFlutterTest(String suiteName, List<String> args) async {
    final stopwatch = Stopwatch()..start();
    
    final process = await Process.start('flutter', args, workingDirectory: 'fittrack');
    
    final stdout = <String>[];
    final stderr = <String>[];
    
    process.stdout.transform(utf8.decoder).listen(stdout.add);
    process.stderr.transform(utf8.decoder).listen(stderr.add);
    
    final exitCode = await process.exitCode;
    stopwatch.stop();
    
    final result = TestSuiteResult(
      name: suiteName,
      success: exitCode == 0,
      duration: stopwatch.elapsed,
      stdout: stdout.join('\n'),
      stderr: stderr.join('\n'),
      testCount: _extractTestCount(stdout.join('\n')),
    );
    
    if (result.success) {
      print('✅ $suiteName completed successfully (${result.duration.inSeconds}s, ${result.testCount} tests)');
    } else {
      print('❌ $suiteName failed (${result.duration.inSeconds}s)');
      print('Error output:');
      print(result.stderr);
    }
    
    return result;
  }

  /// Start Firebase emulators for integration testing
  Future<Process> _startFirebaseEmulators() async {
    final process = await Process.start(
      'firebase',
      ['emulators:start', '--only', 'auth,firestore', '--detached'],
      workingDirectory: 'fittrack',
    );
    
    // Give emulators time to start
    await Future.delayed(Duration(seconds: 3));
    
    return process;
  }

  /// Wait for Firebase emulators to be ready
  Future<void> _waitForEmulators() async {
    final maxAttempts = 30;
    var attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        // Check Auth emulator
        final authResponse = await Process.run('curl', ['-f', 'http://localhost:9099/']);
        // Check Firestore emulator  
        final firestoreResponse = await Process.run('curl', ['-f', 'http://localhost:8082/']);
        
        if (authResponse.exitCode == 0 && firestoreResponse.exitCode == 0) {
          print('✅ Firebase emulators ready');
          return;
        }
      } catch (e) {
        // Emulators not ready yet
      }
      
      attempts++;
      await Future.delayed(Duration(seconds: 1));
    }
    
    throw Exception('Firebase emulators failed to start within timeout');
  }

  /// Stop Firebase emulators
  Future<void> _stopFirebaseEmulators(Process? emulatorProcess) async {
    try {
      await Process.run('firebase', ['emulators:kill'], workingDirectory: 'fittrack');
      print('🔥 Firebase emulators stopped');
    } catch (e) {
      print('⚠️  Warning: Failed to stop emulators cleanly: $e');
    }
  }

  /// Generate coverage report
  Future<void> _generateCoverageReport() async {
    print('📊 Generating coverage report...');
    
    try {
      final process = await Process.run(
        'genhtml',
        ['coverage/lcov.info', '-o', 'coverage/html'],
        workingDirectory: 'fittrack',
      );
      
      if (process.exitCode == 0) {
        print('✅ Coverage report generated at fittrack/coverage/html/index.html');
      } else {
        print('⚠️  Coverage report generation failed: ${process.stderr}');
      }
    } catch (e) {
      print('⚠️  Coverage report error: $e');
    }
  }

  /// Generate comprehensive test summary
  Future<void> _generateSummaryReport() async {
    final totalDuration = DateTime.now().difference(_startTime);
    final totalTests = _results.fold<int>(0, (sum, result) => sum + result.testCount);
    final successfulSuites = _results.where((r) => r.success).length;
    final failedSuites = _results.where((r) => !r.success).length;
    
    print('');
    print('📋 Test Suite Summary Report');
    print('════════════════════════════════════════');
    print('⏱️  Total Duration: ${_formatDuration(totalDuration)}');
    print('🧪 Total Tests: $totalTests');
    print('✅ Successful Suites: $successfulSuites/${_results.length}');
    print('❌ Failed Suites: $failedSuites');
    print('');
    
    print('📊 Individual Suite Results:');
    for (final result in _results) {
      final icon = result.success ? '✅' : '❌';
      print('$icon ${result.name}: ${result.testCount} tests in ${_formatDuration(result.duration)}');
    }
    
    print('');
    
    if (failedSuites > 0) {
      print('❌ OVERALL RESULT: FAILED');
      print('');
      print('Failed Test Suites:');
      for (final result in _results.where((r) => !r.success)) {
        print('• ${result.name}');
        if (result.stderr.isNotEmpty) {
          print('  Error: ${result.stderr.split('\n').first}');
        }
      }
      exit(1);
    } else {
      print('✅ OVERALL RESULT: SUCCESS');
      print('🎉 All test suites passed successfully!');
    }
    
    // Write detailed report to file
    await _writeDetailedReport(totalDuration, totalTests);
  }

  /// Write detailed test report to file
  Future<void> _writeDetailedReport(Duration totalDuration, int totalTests) async {
    final report = StringBuffer();
    report.writeln('# FitTrack Test Execution Report');
    report.writeln('');
    report.writeln('**Execution Date**: ${DateTime.now().toIso8601String()}');
    report.writeln('**Total Duration**: ${_formatDuration(totalDuration)}');
    report.writeln('**Total Tests**: $totalTests');
    report.writeln('');
    
    report.writeln('## Test Suite Results');
    report.writeln('');
    for (final result in _results) {
      report.writeln('### ${result.name}');
      report.writeln('- **Status**: ${result.success ? "✅ PASSED" : "❌ FAILED"}');
      report.writeln('- **Duration**: ${_formatDuration(result.duration)}');
      report.writeln('- **Test Count**: ${result.testCount}');
      if (!result.success && result.stderr.isNotEmpty) {
        report.writeln('- **Error**: ${result.stderr.split('\n').first}');
      }
      report.writeln('');
    }
    
    report.writeln('## Coverage Summary');
    report.writeln('Coverage reports available in `coverage/html/index.html`');
    report.writeln('');
    
    report.writeln('## Performance Benchmarks');
    report.writeln('All performance tests should meet established benchmarks:');
    report.writeln('- Unit tests: < 100ms each');
    report.writeln('- Widget tests: < 5s each');
    report.writeln('- Integration tests: < 30s each');
    report.writeln('- Full suite: < 5 minutes');
    
    await File('fittrack/test/TEST_EXECUTION_REPORT.md').writeAsString(report.toString());
    print('📄 Detailed report saved to fittrack/test/TEST_EXECUTION_REPORT.md');
  }

  /// Extract test count from Flutter test output
  int _extractTestCount(String output) {
    final regex = RegExp(r'All tests passed! \((\d+) tests\)');
    final match = regex.firstMatch(output);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    
    // Alternative pattern for different output formats
    final regex2 = RegExp(r'(\d+) tests passed');
    final match2 = regex2.firstMatch(output);
    if (match2 != null) {
      return int.parse(match2.group(1)!);
    }
    
    return 0;
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else if (seconds > 0) {
      return '${seconds}.${(milliseconds / 100).floor()}s';
    } else {
      return '${milliseconds}ms';
    }
  }

  /// Print usage instructions
  void printUsage() {
    print('🧪 FitTrack Unified Test Runner');
    print('');
    print('Usage: dart test/unified_test_runner.dart [options]');
    print('');
    print('Options:');
    print('  --all         Run all test suites (default if no options specified)');
    print('  --unit        Run unit tests only (models, services, providers)');
    print('  --widget      Run widget tests only (screens, widgets)');
    print('  --integration Run integration tests only (requires Firebase emulators)');
    print('  --performance Run performance tests only');
    print('  --enhanced    Run enhanced comprehensive tests');
    print('  --coverage    Generate coverage report (included with --all)');
    print('  --help        Show this help message');
    print('');
    print('Examples:');
    print('  dart test/unified_test_runner.dart --all');
    print('  dart test/unified_test_runner.dart --unit --coverage');
    print('  dart test/unified_test_runner.dart --widget --integration');
    print('');
    print('Prerequisites:');
    print('  - Flutter SDK 3.10+ installed');
    print('  - Firebase CLI installed (for integration tests)');
    print('  - Dependencies installed: flutter pub get');
  }
}

/// Test suite execution result
class TestSuiteResult {
  final String name;
  final bool success;
  final Duration duration;
  final String stdout;
  final String stderr;
  final int testCount;
  
  TestSuiteResult({
    required this.name,
    required this.success,
    required this.duration,
    required this.stdout,
    required this.stderr,
    required this.testCount,
  });
}

/// Test execution utilities
class TestExecutionUtils {
  /// Check if Firebase emulators are required and available
  static Future<bool> checkFirebaseEmulatorsAvailable() async {
    try {
      final result = await Process.run('firebase', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verify test environment setup
  static Future<void> verifyTestEnvironment() async {
    print('🔍 Verifying test environment...');
    
    // Check Flutter installation
    final flutterResult = await Process.run('flutter', ['--version']);
    if (flutterResult.exitCode != 0) {
      throw Exception('Flutter not found or not properly installed');
    }
    
    // Check dependencies
    final pubResult = await Process.run('flutter', ['pub', 'deps'], workingDirectory: 'fittrack');
    if (pubResult.exitCode != 0) {
      throw Exception('Dependencies not installed. Run: flutter pub get');
    }
    
    // Check for test files
    final testDir = Directory('fittrack/test');
    if (!testDir.existsSync()) {
      throw Exception('Test directory not found');
    }
    
    print('✅ Test environment verified');
  }

  /// Clean up test artifacts
  static Future<void> cleanupTestArtifacts() async {
    final artifactPaths = [
      'fittrack/test-results-*.json',
      'fittrack/.dart_tool/test/',
      'fittrack/build/unit_test_assets/',
    ];
    
    for (final path in artifactPaths) {
      try {
        final dir = Directory(path);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, Duration> _benchmarks = {
    'unit_tests': Duration(seconds: 30),
    'widget_tests': Duration(minutes: 2),
    'integration_tests': Duration(minutes: 3),
    'performance_tests': Duration(minutes: 1),
    'full_suite': Duration(minutes: 5),
  };

  /// Validate test suite performance
  static void validateSuitePerformance(String suiteName, Duration elapsed) {
    final benchmark = _benchmarks[suiteName.toLowerCase().replaceAll(' ', '_')];
    
    if (benchmark != null && elapsed > benchmark) {
      print('⚠️  Performance warning: $suiteName took ${elapsed.inSeconds}s (benchmark: ${benchmark.inSeconds}s)');
    }
  }

  /// Generate performance report
  static String generatePerformanceReport(List<TestSuiteResult> results) {
    final report = StringBuffer();
    report.writeln('## Performance Analysis');
    report.writeln('');
    
    for (final result in results) {
      final benchmark = _benchmarks[result.name.toLowerCase().replaceAll(' ', '_')];
      final benchmarkMet = benchmark == null || result.duration <= benchmark;
      final icon = benchmarkMet ? '✅' : '⚠️';
      
      report.writeln('$icon **${result.name}**: ${result.duration.inSeconds}s');
      if (benchmark != null) {
        report.writeln('   - Benchmark: ${benchmark.inSeconds}s');
        report.writeln('   - Status: ${benchmarkMet ? "PASSED" : "EXCEEDED"}');
      }
      report.writeln('');
    }
    
    return report.toString();
  }
}

/// Memory usage monitoring
class MemoryMonitor {
  /// Get current memory usage
  static Future<int> getCurrentMemoryUsage() async {
    try {
      final result = await Process.run('ps', ['-o', 'rss=', '-p', '${Platform.environment['PPID']}']);
      if (result.exitCode == 0) {
        return int.parse(result.stdout.toString().trim()) * 1024; // Convert KB to bytes
      }
    } catch (e) {
      // Platform-specific memory monitoring would go here
    }
    
    return 0;
  }

  /// Monitor memory usage during test execution
  static Future<MemoryUsageReport> monitorTestExecution(Future<void> Function() testFunction) async {
    final initialMemory = await getCurrentMemoryUsage();
    var peakMemory = initialMemory;
    
    // Monitor memory during execution
    final memoryTimer = Stream.periodic(Duration(milliseconds: 100), (_) async {
      final currentMemory = await getCurrentMemoryUsage();
      if (currentMemory > peakMemory) {
        peakMemory = currentMemory;
      }
    });
    
    final subscription = memoryTimer.listen((_) {});
    
    try {
      await testFunction();
    } finally {
      subscription.cancel();
    }
    
    final finalMemory = await getCurrentMemoryUsage();
    
    return MemoryUsageReport(
      initialMemory: initialMemory,
      peakMemory: peakMemory,
      finalMemory: finalMemory,
      memoryIncrease: finalMemory - initialMemory,
    );
  }
}

/// Memory usage report
class MemoryUsageReport {
  final int initialMemory;
  final int peakMemory;
  final int finalMemory;
  final int memoryIncrease;
  
  MemoryUsageReport({
    required this.initialMemory,
    required this.peakMemory,
    required this.finalMemory,
    required this.memoryIncrease,
  });
  
  /// Format memory size for display
  String formatMemorySize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  @override
  String toString() {
    return 'Memory: ${formatMemorySize(initialMemory)} → ${formatMemorySize(finalMemory)} '
           '(peak: ${formatMemorySize(peakMemory)}, increase: ${formatMemorySize(memoryIncrease)})';
  }
}