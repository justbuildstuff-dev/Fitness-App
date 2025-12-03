# Test Classification Guide

## Test Types

### Unit Tests
- **Location:** `test/models/`, `test/providers/`, `test/services/` (with `_test.dart` suffix)
- **Purpose:** Test individual functions/classes in isolation
- **Characteristics:**
  - Use mocks for dependencies
  - No Firebase connection
  - Fast (< 1 second per test)
  - High coverage (90%+)
- **Example:** `program_model_validation_test.dart`

### Widget Tests
- **Location:** `test/screens/`, `test/widgets/`
- **Purpose:** Test UI components and interactions
- **Characteristics:**
  - Use `testWidgets()`
  - Mock services and providers
  - Test widget rendering and user interaction
  - Medium speed (1-5 seconds per test)
- **Example:** `create_program_screen_test.dart`

### Integration Tests
- **Location:** `test/services/` (with `_integration_test.dart` suffix)
- **Purpose:** Test actual Firebase integration and cross-component behavior
- **Characteristics:**
  - **MUST** connect to Firebase emulators
  - **MUST** create real data in Firestore
  - **MUST** validate actual Firebase operations
  - Slower (5-30 seconds per test)
  - Use `FirebaseIntegrationTestHelper`
- **Example:** `firestore_cascade_delete_integration_test.dart`

### E2E Tests (Android Emulator)
- **Location:** `integration_test/`
- **Purpose:** Test complete user workflows on real device
- **Characteristics:**
  - Use `flutter drive`
  - Run on Android emulator in CI
  - Full app testing
  - Very slow (5-30 minutes)
- **Example:** `analytics_integration_test.dart`

## Naming Conventions

| Test Type | File Pattern | Example |
|-----------|--------------|---------|
| Unit | `*_test.dart` | `program_model_validation_test.dart` |
| Widget | `*_test.dart` | `create_program_screen_test.dart` |
| Integration | `*_integration_test.dart` | `firestore_cascade_delete_integration_test.dart` |
| E2E | `*_integration_test.dart` | `analytics_integration_test.dart` (in `integration_test/`) |

## When to Write Each Type

### Unit Tests (ALWAYS)
- Every new model class
- Every new service method
- Every provider method
- Target: 90%+ coverage

### Widget Tests (COMMON)
- New screens
- Complex widgets
- User interaction flows
- Accessibility validation

### Integration Tests (REQUIRED FOR SERVICES)
- **REQUIRED:** Any new or modified service method that interacts with Firebase
- **REQUIRED:** Any feature involving Firestore writes, updates, or deletes
- **REQUIRED:** Any authentication-related functionality
- Use template: `test/services/INTEGRATION_TEST_TEMPLATE.dart`

### E2E Tests (SELECTIVE)
- Critical user flows
- Cross-screen workflows
- Complex state management scenarios
- Platform-specific behavior

## CI Workflow Jobs

| Job Name | Test Type | Purpose |
|----------|-----------|---------|
| `unit-tests` | Unit | Fast validation of business logic |
| `widget-tests` | Widget | UI component testing |
| `enhanced-tests` | Integration | **REAL** Firebase integration testing |
| `integration-tests` | E2E | Android emulator end-to-end testing |

## Quality Gates

### Pull Request Requirements

1. **Unit Tests:** 90%+ coverage for modified files
2. **Integration Tests:** Required if `lib/services/*.dart` modified
3. **Widget Tests:** Recommended for new screens
4. **E2E Tests:** Optional (manual review)

### CI Failure Policy

- **Unit test failure:** ❌ Blocks PR merge
- **Widget test failure:** ❌ Blocks PR merge
- **Integration test failure:** ❌ Blocks PR merge
- **E2E test failure (Android):** ⚠️  Advisory (known flaky, see Issue #29)

## Firebase Emulator Configuration

### For Service-Level Integration Tests (`test/`)
- **Execution:** Direct on Ubuntu runner via `flutter test`
- **Firestore:** `localhost:8080`
- **Auth:** `localhost:9099`
- **Helper:** `FirebaseIntegrationTestHelper`

### For E2E Tests (`integration_test/`)
- **Execution:** On Android emulator via `flutter drive`
- **Firestore:** `10.0.2.2:8080` (Android emulator accessing host)
- **Auth:** `10.0.2.2:9099` (Android emulator accessing host)
- **Helper:** `FirebaseEmulatorSetup`

**Critical Distinction:** The host address differs based on WHERE the test runs:
- Tests in `test/` → Run on Ubuntu → Use `localhost`
- Tests in `integration_test/` → Run on Android emulator → Use `10.0.2.2`

## Best Practices

### Unit Tests
- Test one thing per test
- Use descriptive test names
- Mock all external dependencies
- Aim for 100% coverage of critical paths

### Integration Tests
- Clean up test data in `tearDown()`
- Use unique test user emails (timestamp-based)
- Verify actual Firestore documents, not just return values
- Test error conditions (network failures, invalid data)

### Test Organization
```
test/
├── models/           # Pure unit tests
├── services/         # Unit tests + integration tests (*_integration_test.dart)
├── providers/        # State management unit tests
├── screens/          # Widget tests
├── widgets/          # Component widget tests
└── helpers/          # Test utilities (FirebaseIntegrationTestHelper)

integration_test/     # E2E tests only
```

## Example Integration Test Structure

```dart
@Timeout(Duration(seconds: 120))
library;

import 'package:test/test.dart';
import 'package:fittrack/services/firestore_service.dart';
import '../helpers/firebase_integration_test_helper.dart';

void main() {
  setUpAll(() async {
    await FirebaseIntegrationTestHelper.initializeFirebaseEmulators();
  });

  setUp(() async {
    await FirebaseIntegrationTestHelper.clearFirestore();
  });

  tearDown() async {
    await FirebaseIntegrationTestHelper.signOut();
  });

  group('Service Integration Tests', () {
    late FirestoreService service;
    late String userId;

    setUp(() async {
      final user = await FirebaseIntegrationTestHelper.createTestUser();
      userId = user.uid;
      service = FirestoreService();
    });

    test('validates actual Firebase behavior', () async {
      // Seed test data
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
      );

      // Call actual service method
      final result = await service.someMethod(userId, testData['programId']!);

      // Verify against REAL Firestore data
      expect(result, equals(expectedValue));
    });
  });
}
```

## Troubleshooting

### Integration Tests Fail to Connect to Emulators
1. Verify emulators are running: `firebase emulators:start --only auth,firestore`
2. Check ports 8080 and 9099 are not in use
3. Confirm correct host (`localhost` for `test/`, `10.0.2.2` for `integration_test/`)

### Tests Pass Locally But Fail in CI
1. Check CI workflow starts emulators correctly
2. Verify emulator readiness checks pass
3. Review timeout settings (integration tests need more time)

### False Passes in CI
1. Ensure NO error suppression patterns (`|| echo`, `|| true`)
2. Verify tests actually connect to emulators (check test output)
3. Confirm all assertions are being executed

---

**Last Updated:** 2025-11-28
**Related Issues:** #123 (False Pass Integration Tests Fix)
**See Also:** [Testing Framework](TestingFramework.md), [Integration Test Template](../../fittrack/test/services/INTEGRATION_TEST_TEMPLATE.dart)
