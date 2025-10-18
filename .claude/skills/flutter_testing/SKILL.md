---
name: Flutter Testing Patterns
description: Comprehensive guide for writing unit, widget, and integration tests in Flutter with Firebase
---

# Flutter Testing Patterns Skill

This skill provides standardized patterns and best practices for writing tests in Flutter applications, including unit tests, widget tests, and integration tests.

## Testing Philosophy

**Test-Driven Development (TDD):**
- Write tests as you code, not after
- Tests define what "done" means
- Coverage is a requirement, not optional

**Test Pyramid:**
```
        /\
       /  \  Integration Tests (Few)
      /____\
     /      \  Widget Tests (Some)
    /________\
   /          \  Unit Tests (Many)
  /__________  \
```

- Many unit tests (fast, isolated)
- Some widget tests (UI behavior)
- Few integration tests (full flows)

## Test File Organization

### File Structure

Mirror your `lib/` structure in `test/`:

```
lib/
  providers/
    theme_provider.dart
  screens/
    settings/
      settings_screen.dart
  services/
    auth_service.dart
  widgets/
    custom_button.dart

test/
  providers/
    theme_provider_test.dart        # Unit tests
  screens/
    settings/
      settings_screen_test.dart     # Widget tests
  services/
    auth_service_test.dart          # Unit tests
  widgets/
    custom_button_test.dart         # Widget tests
  integration/
    settings_flow_test.dart         # Integration tests

integration_test/
  app_test.dart                     # E2E tests
```

### Naming Conventions

- Test file: `[original_file_name]_test.dart`
- Test group: `'ClassName'` or `'Feature Name'`
- Test case: `'should [expected behavior] when [condition]'`

**Examples:**
```dart
void main() {
  group('ThemeProvider', () {
    test('should default to system theme when initialized', () {
      // ...
    });

    test('should persist theme mode when setThemeMode called', () {
      // ...
    });

    test('should notify listeners when theme changes', () {
      // ...
    });
  });
}
```

## Unit Tests

### When to Write Unit Tests

- Providers (state management)
- Services (business logic)
- Utilities and helpers
- Data models
- Validators

### Unit Test Structure

**Standard pattern:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Import the class being tested
import 'package:fittrack/providers/theme_provider.dart';

// Import dependencies
import 'package:shared_preferences/shared_preferences.dart';

// Generate mocks
@GenerateMocks([SharedPreferences])
import 'theme_provider_test.mocks.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider provider;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      // Setup runs before each test
      mockPrefs = MockSharedPreferences();
      provider = ThemeProvider(mockPrefs);
    });

    tearDown(() {
      // Cleanup runs after each test
      provider.dispose();
    });

    test('should default to system theme when initialized', () {
      // Arrange (setup is in setUp())

      // Act (nothing needed for default state)

      // Assert
      expect(provider.currentThemeMode, ThemeMode.system);
    });

    test('should persist theme mode when setThemeMode called', () async {
      // Arrange
      when(mockPrefs.setString(any, any))
          .thenAnswer((_) async => true);

      // Act
      await provider.setThemeMode(ThemeMode.dark);

      // Assert
      verify(mockPrefs.setString('theme_mode', 'dark')).called(1);
      expect(provider.currentThemeMode, ThemeMode.dark);
    });

    test('should notify listeners when theme changes', () async {
      // Arrange
      when(mockPrefs.setString(any, any))
          .thenAnswer((_) async => true);

      var notified = false;
      provider.addListener(() => notified = true);

      // Act
      await provider.setThemeMode(ThemeMode.light);

      // Assert
      expect(notified, true);
    });

    test('should handle save error gracefully', () async {
      // Arrange
      when(mockPrefs.setString(any, any))
          .thenThrow(Exception('Save failed'));

      // Act & Assert
      expect(
        () => provider.setThemeMode(ThemeMode.dark),
        throwsException,
      );
    });
  });
}
```

### Mocking Dependencies

**Using Mockito for common dependencies:**

**SharedPreferences:**
```dart
@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();

    // Setup default returns
    when(mockPrefs.getString(any)).thenReturn(null);
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
  });
}
```

**Firebase Auth:**
```dart
@GenerateMocks([FirebaseAuth, User])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');
  });
}
```

**Firestore:**
```dart
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();

    when(mockFirestore.collection(any)).thenReturn(mockCollection);
  });
}
```

### Coverage Requirements

**Target coverage by component type:**
- Providers/State Management: **90-100%**
- Services/Business Logic: **80-100%**
- Utilities/Helpers: **90-100%**
- Data Models: **80-100%**

**Overall project target: 80%+**

### Common Unit Test Patterns

**Testing async methods:**
```dart
test('should load data asynchronously', () async {
  // Arrange
  when(mockService.fetchData()).thenAnswer((_) async => testData);

  // Act
  await provider.loadData();

  // Assert
  expect(provider.data, testData);
  expect(provider.isLoading, false);
});
```

**Testing error handling:**
```dart
test('should set error state when load fails', () async {
  // Arrange
  when(mockService.fetchData()).thenThrow(Exception('Network error'));

  // Act
  await provider.loadData();

  // Assert
  expect(provider.hasError, true);
  expect(provider.errorMessage, contains('Network error'));
});
```

**Testing state changes:**
```dart
test('should transition through loading states', () async {
  // Arrange
  when(mockService.fetchData()).thenAnswer(
    (_) => Future.delayed(Duration(milliseconds: 100), () => testData),
  );

  // Act
  final future = provider.loadData();

  // Assert loading state
  expect(provider.isLoading, true);

  await future;

  // Assert loaded state
  expect(provider.isLoading, false);
  expect(provider.data, testData);
});
```

## Widget Tests

### When to Write Widget Tests

- Custom widgets
- Screens/Pages
- UI components with logic
- User interactions
- Accessibility

### Widget Test Structure

**Standard pattern:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fittrack/screens/settings/settings_screen.dart';
import 'package:fittrack/providers/theme_provider.dart';

void main() {
  group('SettingsScreen', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider(MockSharedPreferences());
    });

    Widget buildTestWidget() {
      return ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('should display theme toggle', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(buildTestWidget());

      // Assert
      expect(find.text('Theme'), findsOneWidget);
      expect(find.byType(SegmentedButton), findsOneWidget);
    });

    testWidgets('should change theme when toggle tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(buildTestWidget());

      // Act
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Assert
      expect(themeProvider.currentThemeMode, ThemeMode.dark);
    });

    testWidgets('should have accessible labels', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(buildTestWidget());

      // Assert
      final semantics = tester.getSemantics(find.byType(SegmentedButton));
      expect(semantics.label, contains('Theme'));
    });
  });
}
```

### Widget Test Helpers

**Pumping widgets:**
```dart
// Render widget and trigger one frame
await tester.pumpWidget(widget);

// Wait for animations to complete
await tester.pumpAndSettle();

// Trigger specific duration
await tester.pump(Duration(milliseconds: 500));
```

**Finding widgets:**
```dart
// By type
find.byType(ElevatedButton)

// By text
find.text('Save')

// By key
find.byKey(Key('save-button'))

// By icon
find.byIcon(Icons.settings)

// By widget instance
find.byWidget(myWidget)

// Descendant
find.descendant(
  of: find.byType(Card),
  matching: find.text('Title'),
)
```

**Interacting with widgets:**
```dart
// Tap
await tester.tap(find.text('Save'));
await tester.pumpAndSettle();

// Long press
await tester.longPress(find.byKey(Key('item')));

// Drag
await tester.drag(find.byType(ListView), Offset(0, -200));
await tester.pumpAndSettle();

// Enter text
await tester.enterText(find.byType(TextField), 'Hello');

// Scroll until visible
await tester.scrollUntilVisible(
  find.text('Item 50'),
  100.0,
);
```

### Testing Provider Integration

**With ChangeNotifierProvider:**
```dart
Widget buildTestWidget() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
    ],
    child: MaterialApp(home: MyScreen()),
  );
}
```

**Verifying provider interactions:**
```dart
testWidgets('should call provider method on tap', (tester) async {
  // Arrange
  final mockProvider = MockThemeProvider();
  await tester.pumpWidget(buildTestWidgetWith(mockProvider));

  // Act
  await tester.tap(find.text('Dark Mode'));
  await tester.pumpAndSettle();

  // Assert
  verify(mockProvider.setThemeMode(ThemeMode.dark)).called(1);
});
```

### Testing Accessibility

**Semantic labels:**
```dart
testWidgets('should have semantic labels for screen readers', (tester) async {
  await tester.pumpWidget(buildTestWidget());

  final semantics = tester.getSemantics(find.byType(IconButton));
  expect(semantics.label, isNotNull);
  expect(semantics.label, isNotEmpty);
});
```

**Contrast ratios:**
```dart
testWidgets('should have sufficient contrast', (tester) async {
  await tester.pumpWidget(buildTestWidget());

  final text = tester.widget<Text>(find.text('Title'));
  final container = tester.widget<Container>(find.byType(Container));

  // Verify colors meet WCAG AA standards
  // (Usually done with visual testing tools)
});
```

### Widget Test Best Practices

**Do:**
- Test user-visible behavior, not implementation
- Use `pumpAndSettle()` after interactions
- Test both happy path and error states
- Verify accessibility
- Use descriptive test names

**Don't:**
- Access private widget state
- Test framework behavior (Flutter already does)
- Make tests dependent on each other
- Hardcode pixel values (use finders)

## Integration Tests

### When to Write Integration Tests

- Multi-screen flows
- Navigation paths
- Data persistence across screens
- Firebase integration
- Offline/online behavior

### Integration Test Structure

**File location:** `test/integration/` or `integration_test/`

**Standard pattern:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fittrack/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Flow Integration Test', () {
    setUpAll(() async {
      // Initialize Firebase with emulator
      await Firebase.initializeApp();
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    });

    testWidgets('should persist theme across app restarts', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Change theme
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Restart app
      await tester.restartAndRestore();
      await tester.pumpAndSettle();

      // Verify theme persisted
      // (Check that app is in dark mode)
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });

    testWidgets('should sync settings with Firebase', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(Key('email')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password')), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Change setting
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Verify Firebase was updated
      final userId = 'test-user-id'; // Get from auth
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      expect(doc.data()?['theme'], 'dark');
    });
  });
}
```

### Firebase Emulator Testing

**Setup in test:**
```dart
setUpAll(() async {
  await Firebase.initializeApp();

  // Use emulators
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
});

tearDownAll() async {
  // Clean up test data
  await FirebaseAuth.instance.signOut();

  // Clear Firestore data
  // (Usually done via emulator REST API)
}
```

### Integration Test Best Practices

**Do:**
- Test realistic user flows
- Use Firebase emulator (don't test against production!)
- Clean up test data after tests
- Test offline/online transitions
- Test error recovery

**Don't:**
- Test every possible path (that's what unit tests are for)
- Depend on external services
- Leave test data in emulator
- Make tests too long (split into multiple tests)

## Test Execution

### Running Tests Locally

**Note: Windows permission issues - use GitHub Actions for actual testing**

**Commands:**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/theme_provider_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests (if permissions work)
flutter test integration_test/

# Run with verbose output
flutter test --verbose
```

### GitHub Actions Testing

**Workflow file:** `.github/workflows/fittrack_test_suite.yml`

**Runs on:**
- Pull requests
- Pushes to develop/main
- Manual trigger

**Test stages:**
1. Unit tests
2. Widget tests
3. Integration tests
4. Performance tests
5. Security checks

**Status check:** `all-tests-passed` - Single check for pass/fail

### Coverage Reports

**Generate coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**View coverage:**
- Open `coverage/html/index.html`
- Check overall percentage
- Identify untested code

**Coverage requirements:**
- Overall: 80%+
- Critical paths: 90%+
- New code: Must not decrease coverage

## Common Testing Patterns for FitTrack

### Testing Firebase Auth

```dart
test('should sign in user with email and password', () async {
  // Arrange
  when(mockAuth.signInWithEmailAndPassword(
    email: anyNamed('email'),
    password: anyNamed('password'),
  )).thenAnswer((_) async => mockUserCredential);

  when(mockUserCredential.user).thenReturn(mockUser);
  when(mockUser.uid).thenReturn('test-uid');

  // Act
  final user = await authService.signIn('test@example.com', 'password123');

  // Assert
  expect(user, isNotNull);
  expect(user?.uid, 'test-uid');
});
```

### Testing Firestore Queries

```dart
test('should fetch user workouts from Firestore', () async {
  // Arrange
  final mockQuery = MockQuery();
  final mockSnapshot = MockQuerySnapshot();
  final mockDocs = [mockDoc1, mockDoc2];

  when(mockFirestore.collection('users')).thenReturn(mockCollection);
  when(mockCollection.doc('user-id')).thenReturn(mockDocRef);
  when(mockDocRef.collection('workouts')).thenReturn(mockSubCollection);
  when(mockSubCollection.get()).thenAnswer((_) async => mockSnapshot);
  when(mockSnapshot.docs).thenReturn(mockDocs);

  // Act
  final workouts = await workoutService.getWorkouts('user-id');

  // Assert
  expect(workouts.length, 2);
});
```

### Testing Navigation

```dart
testWidgets('should navigate to settings on tap', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(),
    routes: {
      '/settings': (context) => SettingsScreen(),
    },
  ));

  // Act
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  // Assert
  expect(find.byType(SettingsScreen), findsOneWidget);
});
```

## Debugging Tests

### Common Issues

**Test timeout:**
```dart
// Increase timeout for slow tests
test('slow operation', () async {
  // ...
}, timeout: Timeout(Duration(seconds: 30)));
```

**Flaky tests:**
```dart
// Use pumpAndSettle to wait for animations
await tester.pumpAndSettle();

// Or pump specific duration
await tester.pump(Duration(milliseconds: 500));
```

**Async issues:**
```dart
// Always await async operations
await tester.tap(find.text('Save'));
await tester.pumpAndSettle(); // Wait for async work
```

### Debug Output

```dart
// Print during tests
test('debug test', () {
  debugPrint('Current state: ${provider.state}');
  // ...
});

// Dump widget tree
testWidgets('debug widget', (tester) async {
  await tester.pumpWidget(myWidget);
  debugDumpApp(); // Print entire widget tree
});
```

## Quick Reference

**Test types by speed:**
- Unit tests: Milliseconds (run constantly)
- Widget tests: Seconds (run before commit)
- Integration tests: Minutes (run on PR)

**When to write each type:**
- Business logic → Unit test
- UI component → Widget test
- Multi-screen flow → Integration test

**Coverage targets:**
- Providers/Services: 90-100%
- Widgets/Screens: 80-100%
- Overall project: 80%+

**Test naming:**
- File: `[name]_test.dart`
- Group: `'ClassName'`
- Test: `'should [behavior] when [condition]'`
