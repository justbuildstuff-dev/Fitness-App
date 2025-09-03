# FitTrack Testing Suite

A comprehensive, production-ready testing framework for the FitTrack Flutter mobile application.

## 🚀 Quick Start

### Run All Tests
```bash
cd fittrack
dart test/unified_test_runner.dart --all
```

### Run Specific Test Categories
```bash
# Unit tests only
dart test/unified_test_runner.dart --unit

# Widget tests only  
dart test/unified_test_runner.dart --widget

# Integration tests (requires Firebase emulators)
dart test/unified_test_runner.dart --integration

# Performance tests
dart test/unified_test_runner.dart --performance
```

## 📁 Test Structure

```
test/
├── README.md                              # This file
├── unified_test_runner.dart               # Main test runner  
├── COMPREHENSIVE_TESTING_GUIDE.md         # Complete testing guide
├── TESTING_BEST_PRACTICES.md              # Best practices and patterns
├── models/                                # Pure Dart unit tests (fast)
│   ├── enhanced_exercise_test.dart        # Exercise model validation
│   ├── enhanced_exercise_set_test.dart    # ExerciseSet model validation
│   ├── enhanced_program_test.dart         # Program model validation
│   └── [other model tests...]            # All use package:test
├── services/                              # Pure business logic tests
│   └── firestore_service_logic_test.dart # Service logic (no Firebase)
├── screens/                               # Flutter widget tests
│   ├── enhanced_create_program_screen_test.dart  # Screen UI testing
│   └── [screen tests...]                 # Use flutter_test + mocked providers
├── widgets/                               # Custom component tests
│   ├── enhanced_delete_confirmation_dialog_test.dart  # Dialog testing
│   └── [widget tests...]                 # Use flutter_test + mocked providers
├── integration/                           # Firebase + Flutter integration
│   ├── enhanced_complete_workflow_test.dart      # End-to-end workflows
│   ├── program_provider_edit_delete_test.dart    # Provider + Firebase
│   ├── enhanced_firestore_service_test.dart      # Service + Firebase  
│   └── [Firebase-dependent tests...]             # Use emulator
├── mocks/                                 # Mock utilities and configurations
│   └── firebase_mocks.dart               # Firebase mocking utilities
├── test_utilities/                        # Test helpers and utilities
│   ├── mock_providers.dart                # Provider mocking utilities
│   └── test_data_factory.dart            # Test data generation
└── performance/                           # Performance and load tests
```

## 🎯 Test Coverage

### Target Coverage by Component
- **Models**: 100% (critical data validation)
- **Services**: 95% (core functionality)  
- **Providers**: 90% (state management)
- **UI Components**: 85% (UI testing limitations)

### Current Status
- **Total Tests**: 150+ comprehensive tests
- **Test Categories**: Unit, Widget, Integration, E2E, Performance
- **Frameworks**: flutter_test, mockito, integration_test
- **Infrastructure**: Firebase emulators, CI/CD integration

## 🧪 Test Categories

### 1. Unit Tests (50% of suite) - **Pure Dart, Super Fast**
Test individual components in isolation without any Flutter or Firebase dependencies.

**Coverage**: Models, Pure business logic  
**Framework**: `package:test` (not flutter_test)  
**Speed**: < 50ms per test  
**Dependencies**: None (no Flutter, no Firebase)

```bash
# Fast unit tests using Dart VM directly
dart test test/models/ test/services/
```

### 2. Widget Tests (30% of suite) - **Flutter UI Testing**  
Test UI components and user interactions with mocked backends.

**Coverage**: Screens, Custom Widgets, Forms  
**Framework**: `flutter_test` with mocked providers  
**Speed**: < 5 seconds per test  
**Dependencies**: Mocked providers/services (no Firebase calls)

```bash
flutter test test/screens/ test/widgets/
```

### 3. Integration Tests (20% of suite) - **Firebase + Flutter**
Test complete component interactions with Firebase emulators.

**Coverage**: Providers + Firebase, Service + Firebase, E2E workflows  
**Framework**: `flutter_test` + Firebase emulator  
**Speed**: < 30 seconds per test  
**Dependencies**: Firebase emulators, Flutter framework

```bash
firebase emulators:start --only auth,firestore --detached
flutter test test/integration/
firebase emulators:kill
```

### 4. End-to-End Tests (10% of suite)
Test complete user journeys on real devices/emulators.

**Coverage**: Critical user flows, Cross-platform validation  
**Speed**: < 2 minutes per test  
**Dependencies**: Device/emulator, Firebase emulators

## 🔧 Development Workflow

### Before Writing Code
1. Review existing tests for similar functionality
2. Understand the component's role and requirements
3. Plan test coverage for new functionality

### Writing Tests
1. Use `TestDataFactory` for realistic test data
2. Follow AAA pattern (Arrange-Act-Assert)
3. Include comprehensive documentation
4. Test both success and failure scenarios

### After Writing Code
1. Run relevant test suites
2. Update existing tests if behavior changed
3. Verify coverage meets requirements
4. Update documentation if needed

## 🔍 Debugging Test Failures

### Common Issues

**Unit Test Failures**:
```bash
# Mock not configured properly
setUp(() {
  mockService = MockFirestoreService();
  when(mockService.method(any)).thenAnswer((_) async => result);
});

# Async operations not handled
when(mockProvider.loadData()).thenAnswer((_) async => {});
```

**Widget Test Failures**:
```bash
# Widget not found
await tester.pumpAndSettle(); // Wait for async operations
expect(find.byKey(Key('widget-key')), findsOneWidget);

# Provider state not updating  
mockProvider.notifyListeners();
await tester.pump(); // Trigger rebuild
```

**Integration Test Failures**:
```bash
# Check emulators are running
firebase emulators:list

# Verify ports available
netstat -an | grep 8080
netstat -an | grep 9099

# Clear emulator data
firebase emulators:exec --only firestore "rm -rf firestore-debug.log"
```

## 📊 Performance Benchmarks

### Target Performance
- **Unit Tests**: < 100ms each
- **Widget Tests**: < 5 seconds each  
- **Integration Tests**: < 30 seconds each
- **Full Suite**: < 5 minutes total

### Memory Requirements
- **Standard Operations**: < 10MB increase
- **Large Dataset Processing**: < 50MB increase
- **UI Rendering**: < 16ms per frame

## 🛡️ Quality Gates

### Pre-commit Requirements
- ✅ All tests pass
- ✅ Coverage meets targets (>90% overall)
- ✅ Performance benchmarks met
- ✅ No linting errors
- ✅ Documentation updated

### CI/CD Integration
- Automated test execution on every PR
- Coverage reporting and tracking
- Performance regression detection
- Security and dependency scanning

## 📚 Documentation

### Essential Reads
1. **[COMPREHENSIVE_TESTING_GUIDE.md](COMPREHENSIVE_TESTING_GUIDE.md)** - Complete testing guide
2. **[TESTING_BEST_PRACTICES.md](TESTING_BEST_PRACTICES.md)** - Best practices and patterns
3. **[Firebase Emulator Setup](integration/firebase_emulator_setup.dart)** - Integration test setup

### Test Examples
- **[Enhanced Exercise Test](models/enhanced_exercise_test.dart)** - Model testing patterns
- **[Enhanced Create Program Screen Test](screens/enhanced_create_program_screen_test.dart)** - Widget testing patterns
- **[Enhanced Complete Workflow Test](integration/enhanced_complete_workflow_test.dart)** - Integration testing patterns

## 🚨 Troubleshooting

### Test Environment Issues

**Dependencies**:
```bash
cd fittrack
flutter pub get
dart pub run build_runner build
```

**Firebase Emulators**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators
firebase emulators:start --only auth,firestore

# Check emulator status
firebase emulators:list
```

### Performance Issues

**Slow Tests**:
- Reduce test data size for unit tests
- Use `pump()` instead of `pumpAndSettle()` when possible
- Check for memory leaks in mocks

**CI/CD Issues**:
- Verify Flutter version compatibility
- Check emulator startup timeouts
- Validate artifact upload permissions

## 🎯 Contributing New Tests

### Adding Model Tests
1. Create test file: `test/models/{model_name}_test.dart`
2. Use `TestDataFactory` for test data
3. Include comprehensive edge case coverage
4. Document test purpose and coverage

### Adding Widget Tests
1. Create test file: `test/screens/{screen_name}_test.dart`
2. Use `MockProviderSetup` for provider mocking
3. Test user interactions and state changes
4. Include accessibility testing

### Adding Integration Tests
1. Create test file: `test/integration/{feature}_integration_test.dart`
2. Use Firebase emulators for real data operations
3. Test complete user workflows
4. Include performance validation

## 📈 Continuous Improvement

### Regular Maintenance
- Monitor test execution performance
- Update mock data to reflect production patterns
- Review and refactor slow or flaky tests
- Update documentation with framework changes

### Scaling Strategy
- Add parallel test execution for larger suites
- Implement test result caching
- Add visual regression testing
- Expand performance testing coverage

---

**For detailed information, see [COMPREHENSIVE_TESTING_GUIDE.md](COMPREHENSIVE_TESTING_GUIDE.md)**