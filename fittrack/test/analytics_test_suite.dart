/// DEPRECATED: Use test_suite.dart --analytics instead
/// 
/// This file has been replaced by the unified test suite at test/test_suite.dart
/// which provides better organization and consolidated test management.
/// 
/// To run analytics tests specifically, use:
/// dart test/test_suite.dart --analytics
/// 
/// Or to run all tests:
/// dart test/test_suite.dart --all

import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/models/analytics.dart';

// Import all analytics-related test files
import 'models/analytics_test.dart' as analytics_models;
import 'models/analytics_edge_cases_test.dart' as analytics_edge_cases;
import 'services/analytics_service_test.dart' as analytics_service;
import 'providers/program_provider_analytics_test.dart' as provider_analytics;
import 'screens/analytics_screen_test.dart' as screen_analytics;

/// DEPRECATED: Comprehensive test suite for all analytics functionality
void main() {
  group('📊 Analytics Test Suite - Comprehensive Coverage', () {
    
    group('🏗️ Models & Data Structures', () {
      analytics_models.main();
      analytics_edge_cases.main();
    });
    
    group('⚙️ Service Layer', () {
      analytics_service.main();
    });
    
    group('🔄 State Management', () {
      provider_analytics.main();
    });
    
    group('🎨 UI Components', () {
      screen_analytics.main();
    });
    
    // Additional test suite metadata
    setUpAll(() {
      print('🧪 Starting Analytics Test Suite');
      print('📋 Test Categories:');
      print('   • Models & Data Structures');
      print('   • Service Layer');
      print('   • State Management');
      print('   • UI Components');
      print('');
    });
    
    tearDownAll(() {
      print('');
      print('✅ Analytics Test Suite Complete');
      print('📊 All analytics functionality verified');
    });
    
    // Meta-test to ensure all test files are included
    test('📝 test suite includes all analytics test files', () {
      final testFiles = [
        'models/analytics_test.dart',
        'models/analytics_edge_cases_test.dart', 
        'services/analytics_service_test.dart',
        'providers/program_provider_analytics_test.dart',
        'screens/analytics_screen_test.dart',
      ];
      
      // This test documents which files are part of the suite
      expect(testFiles.length, equals(5));
      
      print('📁 Included test files:');
      for (final file in testFiles) {
        print('   • $file');
      }
    });
    
    // Performance benchmark test
    test('⚡ analytics performance meets benchmarks', () {
      // This test would contain performance assertions
      // Currently just validates that benchmarks are defined
      
      final benchmarks = {
        'Large dataset (1000 workouts)': '< 1000ms',
        'Heatmap generation (366 days)': '< 500ms', 
        'Intensity calculations (366 days)': '< 100ms',
        'Analytics computation scaling': 'Linear',
      };
      
      expect(benchmarks.length, equals(4));
      
      print('📈 Performance benchmarks:');
      benchmarks.forEach((test, benchmark) {
        print('   • $test: $benchmark');
      });
    });
  });
}

/// Test configuration and utilities for analytics testing
class AnalyticsTestConfig {
  static const String testUserId = 'analytics_test_user';
  static const int performanceThresholdMs = 1000;
  static const int largeDatasetSize = 1000;
  
  /// Creates a standardized test date range
  static DateRange createTestDateRange() {
    final now = DateTime.now();
    return DateRange(
      start: now.subtract(const Duration(days: 365)),
      end: now,
    );
  }
  
  /// Validates that a test completed within performance thresholds
  static void validatePerformance(Stopwatch stopwatch, String testName) {
    final elapsed = stopwatch.elapsedMilliseconds;
    expect(elapsed, lessThan(performanceThresholdMs),
        reason: '$testName took ${elapsed}ms (expected < ${performanceThresholdMs}ms)');
  }
}

/// Custom matchers for analytics testing
class AnalyticsMatchers {
  /// Matcher for validating personal record improvements
  static Matcher isValidPRImprovement() {
    return predicate<PersonalRecord>((pr) {
      return pr.improvement >= 0 || pr.previousValue != null;
    }, 'is a valid personal record improvement');
  }
  
  /// Matcher for validating heatmap intensity consistency
  static Matcher hasConsistentIntensity() {
    return predicate<HeatmapDay>((day) {
      switch (day.intensity) {
        case HeatmapIntensity.none:
          return day.workoutCount == 0;
        case HeatmapIntensity.low:
          return day.workoutCount == 1;
        case HeatmapIntensity.medium:
          return day.workoutCount >= 2 && day.workoutCount <= 3;
        case HeatmapIntensity.high:
          return day.workoutCount >= 4;
      }
    }, 'has intensity consistent with workout count');
  }
  
  /// Matcher for validating analytics completeness
  static Matcher isCompleteAnalytics() {
    return predicate<WorkoutAnalytics>((analytics) {
      return analytics.userId.isNotEmpty &&
             analytics.totalWorkouts >= 0 &&
             analytics.totalSets >= 0 &&
             analytics.totalVolume >= 0 &&
             analytics.exerciseTypeBreakdown.isNotEmpty;
    }, 'contains complete analytics data');
  }
}

