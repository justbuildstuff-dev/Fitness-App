---
name: Flutter Code Quality Standards
description: Code quality standards, style guide, and best practices for Flutter/Dart development
---

# Flutter Code Quality Standards Skill

This skill defines code quality standards, style conventions, and best practices for Flutter/Dart development in the FitTrack project.

## Core Principles

1. **Readability** - Code is read more than written
2. **Consistency** - Follow existing patterns
3. **Simplicity** - Simple solutions over clever ones
4. **Testability** - Write code that's easy to test
5. **Maintainability** - Think 6 months ahead

## Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style).

### Key Rules

**DO:**
- Use `lowerCamelCase` for variables, methods, parameters
- Use `UpperCamelCase` for classes, enums, typedefs, type parameters
- Use `lowercase_with_underscores` for library/file names
- Use `SCREAMING_CAPS` for constants
- Prefix private members with underscore: `_privateMethod()`

**Examples:**
```dart
// ✅ Good
class ThemeProvider extends ChangeNotifier {
  static const String themeKey = 'THEME_KEY';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get currentThemeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
  }
}

// ❌ Bad
class theme_provider extends ChangeNotifier {
  String ThemeKey = 'theme_key';
  ThemeMode thememode = ThemeMode.system;

  ThemeMode GetThemeMode() => thememode;
}
```

## File Organization

### Project Structure

```
lib/
  main.dart                    # App entry point
  providers/                   # State management (ChangeNotifier)
    theme_provider.dart
    auth_provider.dart
  services/                    # Business logic, API calls
    auth_service.dart
    workout_service.dart
  screens/                     # Full-screen pages
    home/
      home_screen.dart
    settings/
      settings_screen.dart
  widgets/                     # Reusable components
    custom_button.dart
    workout_card.dart
  models/                      # Data models
    user.dart
    workout.dart
  utils/                       # Helper functions
    validators.dart
    formatters.dart
  constants/                   # App-wide constants
    colors.dart
    strings.dart
    routes.dart

test/                          # Mirror lib/ structure
  providers/
    theme_provider_test.dart
  services/
    auth_service_test.dart
```

### File Naming

- One class per file (usually)
- File name matches class name in snake_case
- Test files: `[name]_test.dart`

**Examples:**
- `theme_provider.dart` contains `class ThemeProvider`
- `settings_screen.dart` contains `class SettingsScreen`
- `custom_button.dart` contains `class CustomButton`

## Import Organization

### Import Order

1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Project imports

**Separate groups with blank line:**

```dart
// ✅ Good
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fittrack/providers/theme_provider.dart';
import 'package:fittrack/constants/colors.dart';

// ❌ Bad - mixed order, no grouping
import 'package:fittrack/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
```

### Import Naming

Use relative imports for project files:
```dart
// ✅ Good
import 'package:fittrack/providers/theme_provider.dart';

// ❌ Bad - absolute path
import '../../providers/theme_provider.dart';
```

## Code Formatting

### Use `dart format`

Before every commit:
```bash
dart format .
```

### Line Length

- Max 80 characters preferred
- Max 120 characters acceptable for readability
- Use line breaks for long method chains

```dart
// ✅ Good
final theme = Theme.of(context)
    .textTheme
    .headline1
    ?.copyWith(color: Colors.blue);

// ❌ Bad - too long
final theme = Theme.of(context).textTheme.headline1?.copyWith(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold);
```

### Indentation

- 2 spaces (Dart standard)
- No tabs

### Trailing Commas

**Always use trailing commas** for function arguments and collections:

```dart
// ✅ Good - enables better formatting
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Hello'),
      Text('World'),
    ],
  );
}

// ❌ Bad - no trailing comma
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Hello'),
      Text('World')
    ]
  );
}
```

## Naming Conventions

### Variables

**Descriptive names over short names:**

```dart
// ✅ Good
final selectedThemeMode = ThemeMode.dark;
final authenticatedUser = await authService.signIn();

// ❌ Bad - unclear
final mode = ThemeMode.dark;
final user = await authService.signIn();
```

**Boolean variables:**

Use affirmative names with `is`, `has`, `can`:

```dart
// ✅ Good
bool isLoading = true;
bool hasError = false;
bool canEdit = true;

// ❌ Bad
bool loading = true;
bool error = false;
bool editable = true;
```

### Methods

**Verb-noun format:**

```dart
// ✅ Good
Future<void> loadWorkouts() async { }
void updateTheme(ThemeMode mode) { }
bool validateEmail(String email) { }

// ❌ Bad - noun only
Future<void> workouts() async { }
void theme(ThemeMode mode) { }
bool email(String email) { }
```

### Classes

**Noun or noun phrase:**

```dart
// ✅ Good
class ThemeProvider { }
class WorkoutService { }
class UserProfile { }

// ❌ Bad - verb
class ManageTheme { }
class DoWorkout { }
```

## Constants and Configuration

### Define Constants

**Never hardcode values:**

```dart
// ✅ Good
class AppStrings {
  static const String appName = 'FitTrack';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
}

class AppKeys {
  static const String themeKey = 'THEME_MODE';
  static const String userIdKey = 'USER_ID';
}

// Usage
Text(AppStrings.darkMode)
prefs.getString(AppKeys.themeKey)

// ❌ Bad - hardcoded
Text('Dark Mode')
prefs.getString('theme_mode')
```

### Group Related Constants

```dart
// ✅ Good
class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
}

class AppDurations {
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
```

## Comments and Documentation

### When to Comment

**DO comment:**
- Complex algorithms
- Non-obvious decisions
- Workarounds or hacks
- Public API methods
- **WHY** something is done

**DON'T comment:**
- Obvious code
- **WHAT** the code does (code should be self-documenting)

### Documentation Comments

Use `///` for public API:

```dart
/// Manages theme state for the application.
///
/// Persists theme choice using SharedPreferences and notifies
/// listeners when theme changes.
class ThemeProvider extends ChangeNotifier {
  /// Gets the current theme mode.
  ThemeMode get currentThemeMode => _themeMode;

  /// Sets the theme mode and persists to storage.
  ///
  /// Throws [Exception] if storage write fails.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }
}
```

### Inline Comments

```dart
// ✅ Good - explains WHY
// We initialize theme synchronously to prevent flash of wrong theme
final themeMode = _loadThemeSync();

// ❌ Bad - explains WHAT (obvious from code)
// Load the theme mode
final themeMode = _loadThemeSync();
```

## Error Handling

### Always Handle Errors

**Use try-catch for async operations:**

```dart
// ✅ Good
Future<void> saveTheme(ThemeMode mode) async {
  try {
    await _prefs.setString(_themeKey, mode.name);
  } on Exception catch (e) {
    debugPrint('Failed to save theme: $e');
    rethrow; // Or handle gracefully
  }
}

// ❌ Bad - no error handling
Future<void> saveTheme(ThemeMode mode) async {
  await _prefs.setString(_themeKey, mode.name);
}
```

### Meaningful Error Messages

```dart
// ✅ Good
throw Exception('Failed to load user workouts: user not authenticated');

// ❌ Bad
throw Exception('Error');
```

### User-Facing Errors

```dart
// ✅ Good - user-friendly message
void _handleError(Exception e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Unable to save settings. Please try again.'),
    ),
  );
  debugPrint('Error details: $e'); // Log technical details
}

// ❌ Bad - technical message to user
void _handleError(Exception e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Exception: $e')),
  );
}
```

## Null Safety

### Use Null Safety Properly

**Prefer non-nullable:**

```dart
// ✅ Good
String userName = 'Guest';
int count = 0;

// Only nullable when actually can be null
String? email; // User might not have email
```

### Null Checks

```dart
// ✅ Good
if (user?.email != null) {
  sendEmail(user!.email);
}

// Or
final email = user?.email;
if (email != null) {
  sendEmail(email); // Type-promoted to non-nullable
}

// ❌ Bad - unnecessary null check
if (userName != null) { // userName is non-nullable
  print(userName);
}
```

## Async/Await

### Always Await Async Calls

```dart
// ✅ Good
Future<void> loadData() async {
  final data = await service.fetchData();
  setState(() => _data = data);
}

// ❌ Bad - forgot await
Future<void> loadData() async {
  final data = service.fetchData(); // Returns Future, not data!
  setState(() => _data = data);
}
```

### Use `unawaited` for Fire-and-Forget

```dart
import 'package:flutter/foundation.dart';

// ✅ Good - explicit fire-and-forget
void trackEvent(String event) {
  unawaited(analytics.logEvent(event));
}

// ❌ Bad - implicit fire-and-forget (linter warning)
void trackEvent(String event) {
  analytics.logEvent(event); // Warning: unawaited_futures
}
```

## State Management (Provider Pattern)

### ChangeNotifier Pattern

```dart
// ✅ Good - follows Provider pattern
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get currentThemeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Optimization

    _themeMode = mode;
    await _persistTheme(mode);
    notifyListeners(); // Notify after state change
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
```

### Provider Registration

```dart
// ✅ Good - in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
    ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
  ],
  child: MyApp(),
)
```

### Provider Access

```dart
// ✅ Good - in build method
final themeProvider = Provider.of<ThemeProvider>(context);
// Or
final themeProvider = context.watch<ThemeProvider>();

// For methods (not rebuilding on changes)
final themeProvider = context.read<ThemeProvider>();

// ❌ Bad - listening in lifecycle methods
@override
void initState() {
  super.initState();
  final provider = Provider.of<ThemeProvider>(context); // Error!
}
```

## Widget Best Practices

### Extract Widgets

**Extract complex UI into separate widgets:**

```dart
// ✅ Good - extracted widget
class ThemeToggle extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeToggle({
    Key? key,
    required this.currentMode,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
      ],
      selected: {currentMode},
      onSelectionChanged: (Set<ThemeMode> newSelection) {
        onChanged(newSelection.first);
      },
    );
  }
}

// ❌ Bad - 50-line build method in screen
```

### Const Widgets

**Use `const` for immutable widgets:**

```dart
// ✅ Good - const where possible
const Text('Dark Mode')
const SizedBox(height: 16)
const Icon(Icons.settings)

// Creates widget once, reuses everywhere
```

### Keys

**Use keys for stateful widgets in lists:**

```dart
// ✅ Good
ListView.builder(
  itemBuilder: (context, index) {
    return WorkoutCard(
      key: ValueKey(workouts[index].id),
      workout: workouts[index],
    );
  },
)
```

## Performance

### Build Method Optimization

**Keep build methods pure:**

```dart
// ✅ Good - pure, no side effects
@override
Widget build(BuildContext context) {
  return Text(title);
}

// ❌ Bad - side effects in build
@override
Widget build(BuildContext context) {
  fetchData(); // BAD - builds can be called frequently
  return Text(title);
}
```

### Avoid Rebuilds

```dart
// ✅ Good - selective listening
final themeMode = context.select<ThemeProvider, ThemeMode>(
  (provider) => provider.currentThemeMode,
);

// ❌ Bad - rebuilds on any provider change
final provider = context.watch<ThemeProvider>();
final themeMode = provider.currentThemeMode;
```

## Accessibility

### Semantic Labels

```dart
// ✅ Good
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: _openSettings,
  tooltip: 'Settings',
  semanticLabel: 'Open settings',
)

// ❌ Bad - no semantic label
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: _openSettings,
)
```

### Sufficient Contrast

Follow Material Design or WCAG AA standards:
- Normal text: 4.5:1 contrast ratio
- Large text: 3:1 contrast ratio

## Linter Configuration

### analysis_options.yaml

Use strict linting:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - avoid_print
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - unawaited_futures
    - require_trailing_commas
```

### Fix Linter Warnings

**Zero linter warnings before commit:**

```bash
flutter analyze
# Fix all issues, then:
flutter analyze --no-fatal-warnings
```

## Pre-Commit Checklist

Before creating a PR, verify:

- [ ] Code formatted: `dart format .`
- [ ] No linter warnings: `flutter analyze`
- [ ] Tests pass: `flutter test`
- [ ] No hardcoded values (use constants)
- [ ] Error handling implemented
- [ ] Comments explain complex logic
- [ ] Accessibility labels present
- [ ] Imports organized
- [ ] No unused imports/variables
- [ ] Null safety used correctly
- [ ] Follows existing patterns

## Code Review Standards

### What Reviewers Check

1. **Correctness** - Does it work?
2. **Tests** - Are there tests? Do they pass?
3. **Readability** - Can I understand this in 6 months?
4. **Patterns** - Does it follow existing code patterns?
5. **Performance** - Any obvious performance issues?
6. **Security** - Any security concerns?
7. **Accessibility** - Are semantic labels present?

### Addressing Review Comments

- Respond to every comment
- Make requested changes or explain why not
- Re-request review after changes

## Common Anti-Patterns to Avoid

### ❌ God Objects

```dart
// Bad - does everything
class AppManager {
  void login() { }
  void loadWorkouts() { }
  void saveTheme() { }
  void sendNotification() { }
}

// Good - single responsibility
class AuthService { void login() { } }
class WorkoutService { void loadWorkouts() { } }
class ThemeProvider { void saveTheme() { } }
```

### ❌ Tight Coupling

```dart
// Bad - directly creates dependencies
class WorkoutScreen extends StatelessWidget {
  final service = WorkoutService(); // Tight coupling

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: service.loadWorkouts(),
      // ...
    );
  }
}

// Good - inject dependencies
class WorkoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = context.read<WorkoutService>(); // Injected via Provider
    return FutureBuilder(
      future: service.loadWorkouts(),
      // ...
    );
  }
}
```

### ❌ Magic Numbers

```dart
// Bad
final height = screenHeight * 0.3;
await Future.delayed(Duration(milliseconds: 500));

// Good
class AppSizes {
  static const double cardHeightRatio = 0.3;
}
class AppDurations {
  static const Duration animation = Duration(milliseconds: 500);
}

final height = screenHeight * AppSizes.cardHeightRatio;
await Future.delayed(AppDurations.animation);
```

## Quick Reference

**File naming:** `snake_case.dart`
**Class naming:** `UpperCamelCase`
**Variable naming:** `lowerCamelCase`
**Constant naming:** `SCREAMING_CAPS` or `lowerCamelCase` in class
**Max line length:** 80 preferred, 120 acceptable
**Indentation:** 2 spaces
**Always use:** Trailing commas, const where possible, await for async
**Never:** Hardcode values, skip error handling, ignore linter warnings
