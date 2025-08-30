# DEPRECATED: Use Docs/TestingFramework.md instead

This file has been replaced by the unified testing framework documentation at `../Docs/TestingFramework.md` which provides comprehensive guidance for all testing in the FitTrack application, including analytics testing.

**Please refer to**: `../Docs/TestingFramework.md` for complete testing documentation.

---

# Analytics Testing Documentation (DEPRECATED)

## Test Structure

### 📁 Test Files Organization

```
test/
├── analytics_test_suite.dart           # Main test suite runner
├── models/
│   ├── analytics_test.dart             # Basic analytics models testing
│   └── analytics_edge_cases_test.dart  # Edge cases and performance testing
├── services/
│   └── analytics_service_test.dart     # Service layer testing
├── providers/
│   └── program_provider_analytics_test.dart # State management testing
├── screens/
│   └── analytics_screen_test.dart      # UI component testing
└── integration/
    └── analytics_integration_test.dart # End-to-end testing
```

## Test Categories

### 🏗️ Models & Data Structures Tests

**File**: `test/models/analytics_test.dart`

**Coverage**:
- ✅ WorkoutAnalytics computation and validation
- ✅ ActivityHeatmapData generation and accuracy
- ✅ PersonalRecord tracking and improvement calculation
- ✅ DateRange utilities and boundary handling
- ✅ HeatmapDay and intensity calculations

**Key Tests**:
```dart
// Analytics computation
test('computes analytics from workout data correctly', () { ... });

// Heatmap generation  
test('computes heatmap data from workouts', () { ... });

// Personal records
test('calculates improvement correctly', () { ... });
test('handles first PR correctly', () { ... });
```

### 🧪 Edge Cases & Performance Tests

**File**: `test/models/analytics_edge_cases_test.dart`

**Coverage**:
- ✅ Large dataset handling (1000+ workouts)
- ✅ Performance benchmarking (< 1000ms for large datasets)
- ✅ Missing data handling
- ✅ Extreme value handling
- ✅ Leap year calculations
- ✅ Memory efficiency

**Performance Benchmarks**:
- Large dataset (1000 workouts): **< 1000ms**
- Heatmap generation (366 days): **< 500ms**  
- Intensity calculations (366 days): **< 100ms**
- Analytics computation: **Linear scaling**

### ⚙️ Service Layer Tests

**File**: `test/services/analytics_service_test.dart`

**Coverage**:
- ✅ Analytics computation methods
- ✅ Personal record detection algorithms
- ✅ Cache management and expiry
- ✅ Error handling and resilience
- ✅ Data filtering and aggregation

**Mock Dependencies**:
```dart
@GenerateMocks([FirestoreService])
```

### 🔄 State Management Tests

**File**: `test/providers/program_provider_analytics_test.dart`

**Coverage**:
- ✅ Analytics loading states
- ✅ Error handling in provider layer
- ✅ Personal record integration
- ✅ Cache refresh functionality
- ✅ Concurrent operations handling

**Mock Dependencies**:
```dart
@GenerateMocks([FirestoreService, AnalyticsService])
```

### 🎨 UI Component Tests

**File**: `test/screens/analytics_screen_test.dart`

**Coverage**:
- ✅ Loading states and indicators
- ✅ Error states and retry functionality
- ✅ Empty states and user guidance
- ✅ Data display accuracy
- ✅ User interactions (refresh, date range selection)
- ✅ Component integration

**Widget Testing**:
```dart
testWidgets('displays loading indicator when analytics are loading', (tester) { ... });
testWidgets('displays error when analytics fail to load', (tester) { ... });
testWidgets('displays analytics components when data is available', (tester) { ... });
```

### 🌐 Integration Tests

**File**: `test_integration/analytics_integration_test.dart`

**Coverage**:
- ✅ End-to-end analytics flow
- ✅ Real data creation and analytics computation
- ✅ Personal record detection with real workflows
- ✅ Heatmap accuracy with varied data
- ✅ Date range filtering
- ✅ Error handling and recovery

## Running Tests

### Run All Analytics Tests

```bash
# Run the complete analytics test suite
flutter test test/analytics_test_suite.dart

# Run individual test files
flutter test test/models/analytics_test.dart
flutter test test/services/analytics_service_test.dart
flutter test test/screens/analytics_screen_test.dart
```

### Run Integration Tests

```bash
# Run analytics integration tests
flutter test test_integration/analytics_integration_test.dart

# Run with device connection for UI testing
flutter drive --target=test_integration/analytics_integration_test.dart
```

### Run Performance Tests

```bash
# Run edge cases and performance tests
flutter test test/models/analytics_edge_cases_test.dart --reporter=verbose
```

## Test Data Setup

### Mock Data Generators

The test suite includes comprehensive mock data generators:

```dart
// Create test workouts
List<Workout> _createTestWorkouts() { ... }

// Create test exercises  
List<Exercise> _createTestExercises() { ... }

// Create test sets
List<ExerciseSet> _createTestSets() { ... }
```

### Test Scenarios

**Basic Analytics**:
- 2 workouts, 4 exercises, 8 sets
- Multiple exercise types
- Volume and duration tracking

**Personal Records**:
- Progressive weight increases
- Rep improvements
- Duration achievements

**Heatmap Testing**:
- Year-long workout data
- Varied workout frequencies
- Streak calculations

## Test Coverage Goals

### Code Coverage Targets
- **Models**: 100% line coverage
- **Services**: 95% line coverage  
- **Providers**: 90% line coverage
- **UI Components**: 85% line coverage

### Functional Coverage
- ✅ All analytics computations
- ✅ All PR types and detection
- ✅ All UI states and interactions
- ✅ All error scenarios
- ✅ Performance edge cases

## Performance Testing

### Benchmarks

| Operation | Target Time | Large Dataset |
|-----------|-------------|---------------|
| Analytics Computation | < 100ms | < 1000ms (1000 workouts) |
| Heatmap Generation | < 50ms | < 500ms (366 days) |
| PR Detection | < 10ms | < 100ms (100 exercises) |
| UI Rendering | < 16ms | < 100ms (complex layouts) |

### Memory Usage
- Maximum memory growth: **< 50MB** for large datasets
- Memory leak detection for long-running operations
- Efficient data structure usage validation

## Continuous Integration

### GitHub Actions Integration

```yaml
- name: Run Analytics Tests
  run: |
    flutter test test/analytics_test_suite.dart
    flutter test test/models/analytics_edge_cases_test.dart --reporter=verbose
```

### Test Reporting
- Coverage reports generated for all analytics code
- Performance metrics tracked over time
- Failed test notifications with detailed logs

## Mock Strategies

### Service Layer Mocking
```dart
// Mock FirestoreService for controlled data
when(mockFirestoreService.getPrograms(any))
    .thenAnswer((_) => Stream.value(testPrograms));
```

### Provider Mocking
```dart
// Mock ProgramProvider for UI testing
when(mockProvider.currentAnalytics).thenReturn(testAnalytics);
when(mockProvider.isLoadingAnalytics).thenReturn(false);
```

### Data Mocking
- Predictable test data for consistent results
- Edge case data for boundary testing
- Large datasets for performance testing

## Testing Best Practices

### Test Organization
1. **Arrange**: Set up test data and mocks
2. **Act**: Execute the operation being tested
3. **Assert**: Verify expected outcomes

### Error Testing
```dart
test('handles analytics loading errors gracefully', () {
  // Arrange: Set up error condition
  when(service.computeAnalytics()).thenThrow(Exception('Network error'));
  
  // Act: Attempt operation
  await provider.loadAnalytics();
  
  // Assert: Verify graceful handling
  expect(provider.error, isNotNull);
  expect(provider.isLoading, isFalse);
});
```

### Performance Testing
```dart
test('large dataset processing is efficient', () {
  final stopwatch = Stopwatch()..start();
  
  // Process large dataset
  final result = computeAnalytics(largeDataset);
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

## Debugging Failed Tests

### Common Issues

1. **Timing Issues**: Use `await tester.pumpAndSettle()` for async operations
2. **Mock Setup**: Ensure all required mocks are configured
3. **Data Dependencies**: Verify test data matches expected formats
4. **State Management**: Clear state between tests

### Debug Commands

```bash
# Run tests with verbose output
flutter test --reporter=verbose

# Run single test with debugging
flutter test test/models/analytics_test.dart --plain-name="specific test name"

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Future Test Enhancements

### Planned Additions
1. **Snapshot Testing**: UI component snapshot comparisons
2. **Property-Based Testing**: Generate random test cases
3. **Load Testing**: Simulate high user loads
4. **Accessibility Testing**: Verify analytics screens are accessible

### Test Automation
1. **Scheduled Runs**: Nightly performance regression tests
2. **PR Validation**: All analytics tests must pass before merge
3. **Release Testing**: Comprehensive test suite before releases

## Contributing to Tests

### Adding New Tests
1. Follow existing test structure and naming conventions
2. Include both positive and negative test cases
3. Add performance tests for new computations
4. Update this documentation with new test coverage

### Test Maintenance
1. Update tests when analytics features change
2. Maintain performance benchmarks as codebase evolves
3. Keep mock data representative of real usage patterns

This comprehensive testing strategy ensures the analytics features are reliable, performant, and maintainable across all development phases.