# FitTrack Testing Best Practices

## 🎯 Core Testing Principles

### 1. Test Independence and Isolation
```dart
// ✅ Good: Independent test with own setup
test('validates exercise creation', () {
  final exercise = Exercise(
    id: 'test-1',
    name: 'Bench Press',
    // ... complete setup
  );
  expect(exercise.isValidName, isTrue);
});

// ❌ Bad: Test depends on previous test state
test('validates exercise after modification', () {
  // Assumes exercise from previous test exists
  exercise.name = 'Updated Exercise';
  expect(exercise.isValidName, isTrue);
});
```

### 2. Clear Test Documentation
```dart
// ✅ Good: Clear purpose and context
test('validates strength exercise requires reps field', () {
  /// Test Purpose: Verify strength exercises enforce reps requirement
  /// This ensures UI forms show correct validation for strength training
  
  final invalidSet = ExerciseSet(
    setNumber: 1,
    weight: 100.0, // Missing required reps
    // ... other fields
  );
  
  expect(invalidSet.isValidForExerciseType(ExerciseType.strength), isFalse);
});

// ❌ Bad: Unclear purpose
test('strength validation', () {
  // What specifically is being validated?
  final set = ExerciseSet(/* ... */);
  expect(set.isValidForExerciseType(ExerciseType.strength), isFalse);
});
```

### 3. Realistic Test Data
```dart
// ✅ Good: Realistic data using factory
test('calculates workout volume correctly', () {
  final sets = [
    TestDataFactory.createExerciseSet(
      exerciseType: ExerciseType.strength,
      intensity: SetIntensity.moderate,
    ),
    TestDataFactory.createExerciseSet(
      exerciseType: ExerciseType.strength, 
      intensity: SetIntensity.heavy,
    ),
  ];
  
  final volume = calculateVolume(sets);
  expect(volume, greaterThan(0));
});

// ❌ Bad: Unrealistic test data
test('calculates workout volume correctly', () {
  final sets = [
    ExerciseSet(reps: 999999, weight: 999999), // Unrealistic values
  ];
  
  final volume = calculateVolume(sets);
  expect(volume, greaterThan(0));
});
```

---

## 🧪 Unit Testing Best Practices

### Model Testing Patterns

**Comprehensive Model Validation**:
```dart
group('Exercise Model Validation', () {
  test('validates all exercise types have correct field requirements', () {
    final testCases = [
      {'type': ExerciseType.strength, 'requiredFields': ['reps']},
      {'type': ExerciseType.cardio, 'requiredFields': ['duration']},
      {'type': ExerciseType.bodyweight, 'requiredFields': ['reps']},
      {'type': ExerciseType.custom, 'requiredFields': []},
    ];
    
    for (final testCase in testCases) {
      final exercise = TestDataFactory.createExercise(
        exerciseType: testCase['type'] as ExerciseType,
      );
      
      expect(
        exercise.requiredSetFields,
        equals(testCase['requiredFields']),
        reason: 'Exercise type ${testCase['type']} field requirements',
      );
    }
  });
});
```

**Firestore Serialization Testing**:
```dart
test('maintains data integrity through Firestore round-trip', () {
  final originalProgram = TestDataFactory.createProgram(
    name: 'Round Trip Test',
    description: 'Testing serialization',
  );
  
  // Serialize to Firestore format
  final firestoreData = originalProgram.toFirestore();
  
  // Deserialize back to object
  final mockDoc = MockDocumentSnapshot('test-id', firestoreData);
  final deserializedProgram = Program.fromFirestore(mockDoc);
  
  // Verify all fields preserved
  expect(deserializedProgram.name, originalProgram.name);
  expect(deserializedProgram.description, originalProgram.description);
  expect(deserializedProgram.userId, originalProgram.userId);
});
```

### Service Testing Patterns

**Error Handling Validation**:
```dart
test('handles network errors gracefully', () async {
  // Arrange: Configure mock to throw network error
  when(mockFirestore.collection(any))
      .thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'));
  
  // Act & Assert: Verify error handling
  expect(
    () => service.createProgram('user-1', 'Test Program'),
    throwsA(isA<FirebaseException>()),
  );
});

test('retries operations on transient failures', () async {
  // Arrange: First call fails, second succeeds
  when(mockFirestore.collection(any))
      .thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'))
      .thenReturn(mockCollection);
  
  // Act: Service should retry automatically
  final result = await service.createProgramWithRetry('user-1', 'Test Program');
  
  // Assert: Verify success after retry
  expect(result, isNotNull);
  verify(mockFirestore.collection(any)).called(2); // Initial + retry
});
```

---

## 🖼️ Widget Testing Best Practices

### Form Testing Patterns

**Comprehensive Form Validation**:
```dart
group('CreateProgramScreen Form Validation', () {
  testWidgets('validates required fields correctly', (tester) async {
    await _setupScreenTest(tester);
    
    // Test empty form submission
    await tester.tap(find.byKey(Key('submit-button')));
    await tester.pumpAndSettle();
    
    expect(find.text('Please enter a program name'), findsOneWidget);
    verifyNever(mockProvider.createProgram(any));
  });
  
  testWidgets('accepts valid form data', (tester) async {
    await _setupScreenTest(tester);
    
    // Fill valid data
    await tester.enterText(find.byKey(Key('name-field')), 'Valid Program');
    await tester.enterText(find.byKey(Key('description-field')), 'Valid description');
    
    // Submit form
    await tester.tap(find.byKey(Key('submit-button')));
    await tester.pumpAndSettle();
    
    // Verify submission
    final capturedProgram = verify(mockProvider.createProgram(captureAny)).captured.single;
    expect(capturedProgram.name, 'Valid Program');
  });
});

Future<void> _setupScreenTest(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<ProgramProvider>(
      create: (_) => mockProvider,
      child: MaterialApp(home: CreateProgramScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
```

### State Management Testing

**Provider State Changes**:
```dart
testWidgets('responds to loading state changes', (tester) async {
  await tester.pumpWidget(createTestApp());
  
  // Initially not loading
  expect(find.byType(CircularProgressIndicator), findsNothing);
  
  // Trigger loading state
  when(mockProvider.isLoadingPrograms).thenReturn(true);
  mockProvider.notifyListeners();
  await tester.pump();
  
  // Verify loading indicator appears
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  
  // Complete loading
  when(mockProvider.isLoadingPrograms).thenReturn(false);
  when(mockProvider.programs).thenReturn([testProgram]);
  mockProvider.notifyListeners();
  await tester.pump();
  
  // Verify content appears
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text(testProgram.name), findsOneWidget);
});
```

### User Interaction Testing

**Comprehensive Interaction Coverage**:
```dart
group('User Interactions', () {
  testWidgets('handles tap interactions correctly', (tester) async {
    await _setupListScreen(tester);
    
    // Test item tap
    await tester.tap(find.text('Test Program'));
    await tester.pumpAndSettle();
    
    verify(mockProvider.selectProgram(any)).called(1);
  });
  
  testWidgets('handles long press interactions correctly', (tester) async {
    await _setupListScreen(tester);
    
    // Test long press for context menu
    await tester.longPress(find.text('Test Program'));
    await tester.pumpAndSettle();
    
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
  });
  
  testWidgets('handles swipe gestures correctly', (tester) async {
    await _setupListScreen(tester);
    
    // Test swipe for actions
    await tester.drag(find.text('Test Program'), Offset(-200, 0));
    await tester.pumpAndSettle();
    
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });
});
```

---

## 🔗 Integration Testing Best Practices

### Firebase Emulator Testing

**Proper Emulator Setup**:
```dart
group('Firebase Integration', () {
  setUpAll(() async {
    // Configure emulators before any tests
    await FirebaseEmulatorSetup.configure();
    
    // Verify emulator connectivity
    await _verifyEmulatorConnection();
  });
  
  setUp(() async {
    // Create fresh test user for each test
    testUserId = await _createTestUser();
    
    // Seed minimal test data if needed
    await _seedTestData(testUserId);
  });
  
  tearDown(() async {
    // Clean up test user data
    await _cleanupTestData(testUserId);
  });
});

Future<void> _verifyEmulatorConnection() async {
  try {
    await FirebaseAuth.instance.signInAnonymously();
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    throw TestFailure('Firebase emulators not accessible: $e');
  }
}
```

**Real Data Operations**:
```dart
testWidgets('persists workout data correctly', (tester) async {
  // Create workout through UI
  await _createWorkoutThroughUI(tester, 'Test Workout');
  
  // Verify data persisted in Firestore
  final workouts = await FirestoreService.instance
      .getWorkouts(testUserId, programId, weekId)
      .first;
  
  expect(workouts, hasLength(1));
  expect(workouts.first.name, 'Test Workout');
  
  // Verify data structure is correct
  expect(workouts.first.userId, testUserId);
  expect(workouts.first.programId, programId);
  expect(workouts.first.weekId, weekId);
});
```

### Cross-Component Testing

**Service Integration**:
```dart
test('analytics service integrates with workout data correctly', () async {
  // Create workout data through service
  final program = await firestoreService.createProgram(testUserId, 'Test Program');
  final week = await firestoreService.createWeek(testUserId, program.id, 'Week 1');
  final workout = await firestoreService.createWorkout(testUserId, program.id, week.id, 'Workout 1');
  
  // Generate analytics
  final analytics = await analyticsService.calculateAnalytics(testUserId);
  
  // Verify analytics reflect workout data
  expect(analytics.totalWorkouts, equals(1));
  expect(analytics.userId, equals(testUserId));
});
```

---

## ⚡ Performance Testing Best Practices

### Benchmark Validation

**Operation Performance**:
```dart
test('program creation meets performance benchmark', () async {
  final stopwatch = Stopwatch()..start();
  
  await service.createProgram(testUserId, 'Performance Test Program');
  
  stopwatch.stop();
  TestConfig.validatePerformance(stopwatch.elapsed, 'program_creation');
});
```

**Memory Usage Monitoring**:
```dart
test('large dataset processing maintains memory efficiency', () async {
  final initialMemory = await _getCurrentMemoryUsage();
  
  final largeDataset = PerformanceDatasets.createLargeDataset();
  await processLargeDataset(largeDataset);
  
  final finalMemory = await _getCurrentMemoryUsage();
  final memoryIncrease = finalMemory - initialMemory;
  
  expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // < 50MB
});
```

### Stress Testing

**Concurrent Operations**:
```dart
test('handles concurrent program operations', () async {
  final operations = List.generate(50, (i) => 
    service.createProgram(testUserId, 'Concurrent Program $i'));
  
  final results = await Future.wait(operations);
  
  expect(results, hasLength(50));
  expect(results.every((id) => id.isNotEmpty), isTrue);
});
```

---

## 🎨 UI Testing Best Practices

### Accessibility Testing

**Screen Reader Support**:
```dart
testWidgets('provides proper accessibility labels', (tester) async {
  await tester.pumpWidget(createTestApp());
  
  // Verify semantic labels
  expect(find.bySemanticsLabel('Program Name'), findsOneWidget);
  expect(find.bySemanticsLabel('Create Program'), findsOneWidget);
  
  // Test keyboard navigation
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  final focusedWidget = FocusManager.instance.primaryFocus;
  expect(focusedWidget, isNotNull);
});
```

**Theme and Responsive Testing**:
```dart
group('Theme Integration', () {
  testWidgets('works with light theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: YourScreen(),
      ),
    );
    
    expect(find.byType(YourScreen), findsOneWidget);
  });
  
  testWidgets('works with dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: YourScreen(),
      ),
    );
    
    expect(find.byType(YourScreen), findsOneWidget);
  });
});

group('Responsive Design', () {
  testWidgets('adapts to small screens', (tester) async {
    await tester.binding.setSurfaceSize(Size(320, 568)); // iPhone SE
    
    await tester.pumpWidget(createTestApp());
    
    // Verify all elements remain accessible
    expect(find.text('Programs'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
});
```

---

## 🔍 Debugging Test Failures

### Diagnostic Commands

**Verbose Test Output**:
```bash
# Run with detailed output
flutter test test/models/exercise_test.dart --reporter=verbose

# Run specific test by name
flutter test --plain-name="creates valid exercise"

# Run with coverage and verbose
flutter test --coverage --reporter=verbose test/models/
```

**Mock Debugging**:
```dart
test('debugs mock interactions', () async {
  // Enable mock logging
  when(mockService.createProgram(any, any))
      .thenAnswer((invocation) async {
        print('Mock called with: ${invocation.positionalArguments}');
        return 'mock-id';
      });
  
  await service.createProgram('user-1', 'Test Program');
  
  // Verify mock was called correctly
  verify(mockService.createProgram('user-1', 'Test Program')).called(1);
});
```

### Common Issues and Solutions

**Widget Test Issues**:
```dart
// Issue: Widget not found
// Solution: Ensure widget exists in tree and use proper finders
expect(find.text('Button Text'), findsOneWidget);
expect(find.byKey(Key('unique-key')), findsOneWidget);
expect(find.byType(ElevatedButton), findsOneWidget);

// Issue: Async operations not completing
// Solution: Use pumpAndSettle() for async operations
await tester.tap(find.byKey(Key('submit-button')));
await tester.pumpAndSettle(); // Wait for async completion

// Issue: Provider state not updating
// Solution: Ensure mock provider notifies listeners
when(mockProvider.programs).thenReturn(newPrograms);
mockProvider.notifyListeners();
await tester.pump(); // Trigger rebuild
```

**Integration Test Issues**:
```bash
# Issue: Emulators not running
firebase emulators:list
firebase emulators:start --only auth,firestore

# Issue: Port conflicts
netstat -an | grep 8080
netstat -an | grep 9099

# Issue: Stale emulator data
firebase emulators:exec --only firestore "rm -rf firestore-debug.log"
```

---

## 📊 Test Quality Metrics

### Coverage Monitoring

**Track Coverage Trends**:
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# View coverage by component
lcov --list coverage/lcov.info
```

**Coverage Quality Gates**:
- Models: 100% (critical data validation)
- Services: 95% (core functionality)
- Providers: 90% (state management)
- UI Components: 85% (UI testing complexity)

### Performance Monitoring

**Performance Regression Detection**:
```dart
test('operation performance regression check', () async {
  final benchmarkResults = <Duration>[];
  
  // Run operation multiple times
  for (int i = 0; i < 10; i++) {
    final stopwatch = Stopwatch()..start();
    await performOperation();
    stopwatch.stop();
    benchmarkResults.add(stopwatch.elapsed);
  }
  
  // Calculate average performance
  final averageMs = benchmarkResults
      .map((d) => d.inMilliseconds)
      .reduce((a, b) => a + b) / benchmarkResults.length;
  
  expect(averageMs, lessThan(500)); // Performance regression check
});
```

### Test Suite Health

**Test Execution Monitoring**:
```bash
# Monitor test execution time
time flutter test

# Check for flaky tests
for i in {1..10}; do flutter test test/flaky_test.dart; done

# Profile memory usage
flutter test --profile test/memory_intensive_test.dart
```

---

## 🔄 Continuous Integration Best Practices

### Pre-commit Hooks

**Test Automation** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash
cd fittrack

# Run linting
flutter analyze

# Run unit tests
flutter test test/models/ test/services/ test/providers/

# Check coverage
flutter test --coverage
lcov --summary coverage/lcov.info

# Verify no test files are missing
find lib/ -name "*.dart" -not -path "*/test/*" | \
  xargs -I {} bash -c 'test -f "test/$(dirname {})/$(basename {} .dart)_test.dart" || echo "Missing test for {}"'
```

### Build Pipeline Integration

**Parallel Test Execution**:
```yaml
# GitHub Actions parallel testing
strategy:
  matrix:
    test-type: [unit, widget, integration]
    
steps:
- name: Run ${{ matrix.test-type }} tests
  run: |
    case ${{ matrix.test-type }} in
      unit) flutter test test/models/ test/services/ test/providers/ ;;
      widget) flutter test test/screens/ test/widgets/ ;;
      integration) 
        firebase emulators:start --detached
        flutter test test/integration/
        firebase emulators:kill ;;
    esac
```

### Quality Reporting

**Test Results Integration**:
```yaml
- name: Publish Test Results
  uses: dorny/test-reporter@v1
  if: always()
  with:
    name: Flutter Tests
    path: test-results.json
    reporter: flutter-json
    
- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: coverage/lcov.info
    flags: flutter
```

---

## 🔧 Advanced Testing Techniques

### Property-Based Testing

**Automated Test Case Generation**:
```dart
test('exercise validation handles all possible name inputs', () {
  final testCases = _generateNameTestCases();
  
  for (final testCase in testCases) {
    final exercise = Exercise(
      name: testCase.name,
      // ... other fields
    );
    
    expect(
      exercise.isValidName,
      equals(testCase.expectedValid),
      reason: 'Name: "${testCase.name}" should be ${testCase.expectedValid ? "valid" : "invalid"}',
    );
  }
});

List<NameTestCase> _generateNameTestCases() {
  return [
    NameTestCase('Valid Name', true),
    NameTestCase('', false),
    NameTestCase('A' * 200, true), // At limit
    NameTestCase('A' * 201, false), // Over limit
    NameTestCase('   ', false), // Whitespace only
    NameTestCase('🏋️ Émojis ñ', true), // Unicode support
  ];
}
```

### Snapshot Testing

**UI Regression Prevention**:
```dart
testWidgets('program list layout matches snapshot', (tester) async {
  final programs = [
    TestDataFactory.createProgram(name: 'Program 1'),
    TestDataFactory.createProgram(name: 'Program 2', isArchived: true),
  ];
  
  await tester.pumpWidget(createTestAppWithPrograms(programs));
  await tester.pumpAndSettle();
  
  await expectLater(
    find.byType(ProgramsScreen),
    matchesGoldenFile('programs_screen_standard.png'),
  );
});
```

### Test Data Management

**Realistic Test Scenarios**:
```dart
class TestScenarios {
  /// New user with no data
  static Map<String, dynamic> newUser() {
    return {'programs': [], 'analytics': null};
  }
  
  /// Established user with complete data
  static Map<String, dynamic> establishedUser() {
    return DatasetBuilder()
        .addProgram(name: 'Strength Program')
        .addWeek()
        .addWorkout(template: WorkoutTemplate.strength)
        .addExercise(exerciseType: ExerciseType.strength)
        .addSet(intensity: SetIntensity.moderate)
        .build();
  }
  
  /// Power user with extensive data
  static Map<String, dynamic> powerUser() {
    return PerformanceDatasets.createLargeDataset();
  }
}
```

---

## 📝 Test Review Checklist

### Before Submitting Tests

**Code Quality**:
- [ ] Test names are descriptive and specific
- [ ] Each test has clear purpose documentation
- [ ] Tests follow AAA pattern (Arrange-Act-Assert)
- [ ] No test depends on other test execution
- [ ] Proper setup and teardown for resources

**Coverage Quality**:
- [ ] All business logic paths tested
- [ ] Edge cases and error conditions covered
- [ ] Performance requirements validated
- [ ] Accessibility features tested
- [ ] Cross-platform behavior verified

**Mock Quality**:
- [ ] Mocks are realistic and comprehensive
- [ ] Error conditions properly simulated
- [ ] Mock data follows business rules
- [ ] No over-mocking (test real logic when possible)

**Performance**:
- [ ] Tests complete within time limits
- [ ] No memory leaks in test execution
- [ ] Performance benchmarks included
- [ ] Large dataset handling validated

---

This comprehensive guide ensures all FitTrack tests maintain high quality, provide reliable validation, and support confident development and deployment.