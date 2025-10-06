# Dark Mode Support - Technical Design

**Version:** 1.0
**Date:** 2025-10-06
**Status:** In Review
**Related PRD:** [Dark Mode Support](https://www.notion.so/Dark-Mode-Support-283879be578981518800ce4913bff27c)
**GitHub Issue:** [#1](https://github.com/justbuildstuff-dev/Fitness-App/issues/1)

---

## Current Architecture Analysis

**State management discovered:** Provider pattern (ChangeNotifierProvider)
- `lib/providers/auth_provider.dart` - Manages authentication state
- `lib/providers/program_provider.dart` - Manages program/workout state
- Providers registered in `lib/main.dart` using MultiProvider

**File structure pattern:**
```
lib/
  ├── providers/           # State management (Provider pattern)
  ├── screens/            # UI screens organized by feature
  │   ├── profile/        # Profile-related screens
  │   ├── analytics/      # Analytics screens
  │   └── ...
  ├── services/           # Business logic and Firebase interactions
  └── main.dart           # App entry point, theme config, provider setup
```

**Similar features examined:**
1. **AuthProvider** (`lib/providers/auth_provider.dart`)
   - Uses ChangeNotifier for state management
   - Persists state via Firebase Auth
   - Exposes reactive state to UI

2. **Material Design 3 Theme** (`lib/main.dart:41-48`)
   - Already has light and dark ColorSchemes defined
   - Uses `ThemeData.from(colorScheme:)`
   - Currently hardcoded to light theme (`themeMode: ThemeMode.light`)

**Testing approach:**
- Unit tests with mockito for providers (`test/providers/*_test.dart`)
- Widget tests for screens (`test/screens/*_test.dart`)
- Integration tests with Firebase emulator (`test/integration/*_test.dart`)

---

## Architecture Overview

**Approach:** Extend existing Material Design 3 theme system with dynamic theme control

**Why this approach:**
- Follows existing Provider pattern used throughout the app
- Material Design 3 themes already defined - just need dynamic switching
- SharedPreferences used for local persistence (no Firestore sync needed per requirements)
- Leverages MaterialApp's built-in `themeMode` parameter
- Minimal architectural changes - extends, doesn't replace

**Alternatives considered:**
- **Riverpod/Bloc migration**: Rejected - unnecessary refactoring, breaks consistency
- **Custom theme system**: Rejected - Material Design 3 provides everything needed
- **Firestore theme sync**: Rejected - requirements specify local-only storage

---

## Component Design

### New Components

#### **ThemeProvider** (`lib/providers/theme_provider.dart`)
- **Responsibility:** Manage app theme mode state and persistence
- **Dependencies:** SharedPreferences
- **State Management:** ChangeNotifier (matches existing provider pattern)
- **Follows pattern from:** `lib/providers/auth_provider.dart`
- **Key Methods/Properties:**
  - `ThemeMode currentThemeMode` - Current theme mode (light/dark/system)
  - `Future<void> setThemeMode(ThemeMode mode)` - Update and persist theme
  - `Future<void> loadThemeMode()` - Load persisted theme on startup
  - `bool get isDarkMode` - Helper for current dark mode status

**Implementation details:**
```dart
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferences _prefs;

  ThemeMode get currentThemeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> loadThemeMode() async {
    final String? saved = _prefs.getString(_themeKey);
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
}
```

#### **SettingsScreen** (`lib/screens/profile/settings_screen.dart`)
- **Responsibility:** UI for user preferences including theme selection
- **Dependencies:** ThemeProvider (via Provider.of)
- **State Management:** StatelessWidget consuming ThemeProvider
- **Follows pattern from:** `lib/screens/profile/profile_screen.dart`
- **Key UI Elements:**
  - AppBar with back navigation
  - Theme mode selector (RadioListTile or SegmentedButton)
  - Options: Light, Dark, System Default
  - Immediate visual feedback on selection

**Layout structure:**
```dart
Scaffold(
  appBar: AppBar(title: Text('Settings')),
  body: ListView(
    children: [
      ListTile(title: Text('Appearance', style: Theme...headlineSmall)),
      RadioListTile<ThemeMode>(
        title: Text('Light'),
        value: ThemeMode.light,
        // ... onChanged updates ThemeProvider
      ),
      RadioListTile<ThemeMode>(
        title: Text('Dark'),
        value: ThemeMode.dark,
        // ... onChanged updates ThemeProvider
      ),
      RadioListTile<ThemeMode>(
        title: Text('System Default'),
        value: ThemeMode.system,
        // ... onChanged updates ThemeProvider
      ),
    ],
  ),
)
```

### Modified Components

#### **main.dart** (`lib/main.dart`)
**Current implementation:**
- Registers providers (AuthProvider, ProgramProvider) via MultiProvider
- Defines Material Design 3 light and dark ColorSchemes
- Creates MaterialApp with hardcoded `themeMode: ThemeMode.light`

**Changes needed:**
1. Add `shared_preferences` initialization before runApp()
2. Add ThemeProvider to MultiProvider
3. Wrap MaterialApp in Consumer<ThemeProvider>
4. Bind `themeMode` to `themeProvider.currentThemeMode`
5. Call `themeProvider.loadThemeMode()` during initialization

**Impact analysis:**
- Low risk - adds provider, doesn't modify existing ones
- MaterialApp rebuild on theme change (expected behavior)
- No breaking changes to existing screens

**Testing impact:**
- Update `test/main_test.dart` to mock SharedPreferences
- Verify MultiProvider includes ThemeProvider

#### **ProfileScreen** (`lib/screens/profile/profile_screen.dart`)
**Current implementation:**
- Displays user profile information
- Has navigation buttons for various profile features

**Changes needed:**
- Add "Settings" navigation button/tile
- Navigate to SettingsScreen on tap

**Impact analysis:**
- Minimal - adds one UI element
- No logic changes
- Follows existing navigation pattern

**Testing impact:**
- Add widget test for Settings navigation

#### **AnalyticsScreen** (`lib/screens/analytics/analytics_screen.dart`)
**Current implementation:**
- Displays workout analytics with charts
- Uses charting library (fl_chart assumed based on typical Flutter analytics)

**Changes needed:**
- Wrap entire screen in Theme widget
- Force `brightness: Brightness.light` regardless of app theme
- Ensures charts remain readable in light theme

**Implementation:**
```dart
@override
Widget build(BuildContext context) {
  return Theme(
    data: Theme.of(context).copyWith(
      brightness: Brightness.light,
      // Optionally override specific chart colors
    ),
    child: Scaffold(
      // ... existing analytics UI
    ),
  );
}
```

**Impact analysis:**
- Isolated to analytics screen only
- Charts always render with light theme colors
- Prevents readability issues with chart libraries

**Testing impact:**
- Add widget test verifying Theme override

---

## Data Model Changes

### No New Models Required
- Theme preference is stored as string enum value ("light", "dark", "system")
- No complex data structures needed

### No Modified Models
- Existing user/program/workout models unchanged
- Theme is app-level state, not user profile data

---

## Storage Schema

### SharedPreferences

**Key naming convention:** Based on existing local storage patterns
- **Key:** `theme_mode`
- **Values:** `"light"`, `"dark"`, `"system"`
- **Default:** `"system"` (if key doesn't exist)
- **Access pattern:** Read on app startup, write on user change

**Why SharedPreferences:**
- Local-only storage per requirements
- Synchronous reads after initialization
- No network dependency
- Consistent with Flutter best practices for user preferences

### Firestore

**No Firestore changes required**
- Requirements explicitly state local-only storage
- No cloud sync needed for theme preference
- Keeps implementation simple and fast

---

## Implementation Tasks

Break down into 8 implementable tasks, ordered by dependency:

### **Task 1: Add shared_preferences Dependency**
- Add `shared_preferences: ^2.2.2` to `pubspec.yaml`
- Run `flutter pub get`
- Files: `pubspec.yaml`
- Follows pattern from: Existing dependencies in pubspec.yaml
- Acceptance criteria:
  - [ ] Dependency added to pubspec.yaml
  - [ ] No dependency conflicts
  - [ ] `flutter pub get` succeeds
- Estimated effort: 0.1 days

### **Task 2: Create ThemeProvider**
- Depends on: Task 1
- Create `lib/providers/theme_provider.dart`
- Implement ChangeNotifier with SharedPreferences persistence
- Files: `lib/providers/theme_provider.dart` (create)
- Follows pattern from: `lib/providers/auth_provider.dart`
- Acceptance criteria:
  - [ ] ThemeProvider extends ChangeNotifier
  - [ ] Exposes currentThemeMode getter
  - [ ] setThemeMode() persists to SharedPreferences and notifies listeners
  - [ ] loadThemeMode() reads from SharedPreferences
  - [ ] Defaults to ThemeMode.system if no saved preference
  - [ ] Unit tests pass with 100% coverage
- Estimated effort: 1 day

### **Task 3: Integrate ThemeProvider in main.dart**
- Depends on: Task 2
- Initialize SharedPreferences in main()
- Add ThemeProvider to MultiProvider
- Wrap MaterialApp with Consumer<ThemeProvider>
- Bind themeMode to provider
- Files: `lib/main.dart` (modify)
- Follows pattern from: Existing MultiProvider setup in main.dart
- Acceptance criteria:
  - [ ] SharedPreferences initialized before runApp()
  - [ ] ThemeProvider added to MultiProvider
  - [ ] MaterialApp wrapped in Consumer<ThemeProvider>
  - [ ] themeMode bound to themeProvider.currentThemeMode
  - [ ] App builds without errors
  - [ ] Theme persists across app restarts
- Estimated effort: 0.5 days

### **Task 4: Create Settings Screen UI**
- Depends on: Task 3
- Create `lib/screens/profile/settings_screen.dart`
- Implement theme mode selector with RadioListTile
- Files: `lib/screens/profile/settings_screen.dart` (create)
- Follows pattern from: `lib/screens/profile/profile_screen.dart`
- Acceptance criteria:
  - [ ] Settings screen created with AppBar
  - [ ] Three RadioListTile options (Light, Dark, System)
  - [ ] Current selection reflects ThemeProvider state
  - [ ] Selecting option updates ThemeProvider
  - [ ] Theme changes immediately on selection
  - [ ] Widget tests pass
- Estimated effort: 1 day

### **Task 5: Wire Settings Navigation**
- Depends on: Task 4
- Add Settings button to ProfileScreen
- Navigate to SettingsScreen on tap
- Files: `lib/screens/profile/profile_screen.dart` (modify)
- Follows pattern from: Existing navigation in ProfileScreen
- Acceptance criteria:
  - [ ] Settings tile added to ProfileScreen
  - [ ] Tapping navigates to SettingsScreen
  - [ ] Back navigation works correctly
  - [ ] Widget test verifies navigation
- Estimated effort: 0.25 days

### **Task 6: Override Analytics Theme**
- Depends on: Task 3
- Wrap AnalyticsScreen in Theme widget forcing light mode
- Files: `lib/screens/analytics/analytics_screen.dart` (modify)
- Follows pattern from: Theme.of(context) usage in existing screens
- Acceptance criteria:
  - [ ] AnalyticsScreen wrapped in Theme widget
  - [ ] Theme forces brightness: Brightness.light
  - [ ] Charts render correctly in both app light/dark modes
  - [ ] Widget test verifies theme override
- Estimated effort: 0.25 days

### **Task 7: Write ThemeProvider Unit Tests**
- Depends on: Task 2
- Create comprehensive unit tests for ThemeProvider
- Files: `test/providers/theme_provider_test.dart` (create)
- Follows pattern from: `test/providers/auth_provider_test.dart`
- Acceptance criteria:
  - [ ] Test initialization with default ThemeMode.system
  - [ ] Test setThemeMode() updates state and persists
  - [ ] Test loadThemeMode() loads saved preference
  - [ ] Test loadThemeMode() handles missing preference
  - [ ] Test notifyListeners() called on changes
  - [ ] 100% code coverage
- Estimated effort: 0.5 days

### **Task 8: Write Widget and Integration Tests**
- Depends on: Tasks 4, 5, 6
- Create widget tests for SettingsScreen
- Create integration test for theme switching flow
- Files:
  - `test/screens/profile/settings_screen_test.dart` (create)
  - `test/widget/theme_switching_test.dart` (create)
- Follows pattern from: `test/screens/profile/profile_screen_test.dart`
- Acceptance criteria:
  - [ ] Widget test: SettingsScreen renders with all options
  - [ ] Widget test: Selecting theme updates provider
  - [ ] Widget test: AnalyticsScreen theme override
  - [ ] Integration test: Full theme switch flow (open settings, change theme, verify UI updates)
  - [ ] All tests pass with >90% coverage
- Estimated effort: 1 day

**Total estimated effort:** 4.6 days

---

## Testing Strategy

Based on existing test patterns discovered in codebase:

### What needs testing coverage:

**Unit Tests:**
- ThemeProvider state management logic
- Theme persistence (SharedPreferences read/write)
- Default behavior when no saved preference
- Expected coverage: 100% of ThemeProvider code

**Widget Tests:**
- SettingsScreen UI renders correctly
- Theme selection updates provider
- Visual state reflects current theme
- AnalyticsScreen theme override
- Expected coverage: >90% of new UI code

**Integration Tests:**
- End-to-end theme switching flow:
  1. App starts with system theme
  2. Navigate to Settings
  3. Change to dark theme
  4. Verify app UI switches to dark
  5. Restart app
  6. Verify theme persisted
- Analytics screen remains light in dark mode
- Expected coverage: Critical user paths

**Each implementation task includes:**
- "Write tests" in acceptance criteria
- Reference to similar existing tests
- Minimum coverage requirement (90-100%)

**Testing will be validated by Testing Agent after implementation.**

---

## Performance Considerations

**Theme switching time:** <200ms per requirements
- MaterialApp rebuild is efficient
- Only UI re-renders, no business logic affected
- SharedPreferences write is async, doesn't block UI

**Memory overhead:** Negligible
- ThemeProvider is singleton
- SharedPreferences cached in memory
- No image assets duplicated for themes

**Build performance:** No impact
- shared_preferences is lightweight dependency
- No code generation required
- Standard Flutter package

**Network usage:** None
- Fully local operation
- No API calls or Firestore sync

---

## Security Considerations

Based on existing security patterns in codebase:

**Authentication requirements:** None
- Theme is local device preference
- No user authentication needed for theme changes

**Data validation:**
- ThemeMode enum prevents invalid values
- SharedPreferences handles type safety
- Default fallback if corrupted data

**Firestore security rules:** No changes needed
- No Firestore data involved

**User data privacy:**
- Theme preference stored locally only
- No PII or sensitive data
- No analytics tracking of theme choice

---

## Accessibility

Follow existing accessibility patterns:

**WCAG compliance level:** AA (per requirements)
- Material Design 3 themes ensure proper contrast ratios
- Light theme: dark text on light background
- Dark theme: light text on dark background
- All contrast ratios meet WCAG AA standards

**Screen reader support:**
- RadioListTile provides semantic labels
- Theme changes announced to screen readers
- No custom accessibility implementation needed

**Platform accessibility features:**
- System theme option respects OS dark mode setting
- Works with platform high contrast modes
- Supports platform text scaling

**Existing accessibility helpers to reuse:**
- MaterialApp's built-in accessibility support
- Semantics widgets from existing screens

---

## Platform-Specific Notes

**Android:**
- Material Design 3 provides native Android 12+ dynamic colors support
- Theme switching uses standard Android transitions
- SharedPreferences maps to Android SharedPreferences API
- System theme option respects Android dark mode toggle

**iOS:**
- Material Design 3 adapts to iOS design language
- Theme switching uses iOS-appropriate transitions
- SharedPreferences maps to NSUserDefaults
- System theme option respects iOS dark mode toggle

**Consistency check:**
- Follows same platform patterns as existing AuthProvider
- Uses same SharedPreferences approach as other local storage
- Navigation follows existing iOS/Android patterns in ProfileScreen

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |
| Chart library incompatible with dark theme | Medium | Force light theme on analytics screen (Task 6) |
| SharedPreferences initialization delays app startup | Low | Initialize async before runApp(), show splash screen |
| Theme switch causes janky UI rebuild | Medium | MaterialApp handles efficiently, test performance (Task 8) |
| Custom widgets don't respect theme | Medium | Use Theme.of(context) consistently, test all screens |
| Breaking existing theme assumptions | Low | Material Design 3 themes already defined, minimal change |

---

## Dependencies

### External packages:

**New:**
- `shared_preferences: ^2.2.2` - Local key-value storage
  - Stable, maintained by Flutter team
  - No version conflicts with existing dependencies

**Existing (no changes):**
- `provider` - Already in use for state management
- `flutter` - No version change required

### Internal dependencies:

**Existing services/components this relies on:**
- MaterialApp configuration in `lib/main.dart`
- MultiProvider setup in `lib/main.dart`
- Existing Material Design 3 ColorSchemes
- Provider pattern from `lib/providers/auth_provider.dart`

**Existing patterns being extended:**
- ChangeNotifier/Provider state management
- Screen navigation from ProfileScreen
- Theme.of(context) usage throughout app

### Breaking changes:

**None** - This is purely additive:
- New provider added, existing providers unchanged
- New screen added, existing screens unchanged
- Existing Material Design 3 themes used, just made dynamic
- No API changes to existing components

---

## Migration Notes

**No migration required** - This is a new feature:
- No existing data to migrate
- First-time users default to system theme
- Existing users (if any) will see system theme by default
- No backward compatibility concerns

---

## Open Questions

### For user/BA to answer:

- [x] Should theme preference be per-user or per-device? **Decision: Per-device (local storage only)**
- [ ] Should we add theme preview in settings before applying?
- [ ] Should we animate the theme transition?

### For research:

- [ ] Does fl_chart (or current chart library) support dark mode natively?
  - **Action:** Check during Task 6 implementation
  - **Fallback:** Force light theme as designed

---

## Implementation Order

Logical sequence based on dependencies:

1. **Foundation** - Task 1 (Add shared_preferences) - No dependencies
2. **Core State** - Task 2 (ThemeProvider), Task 7 (ThemeProvider tests) - Builds on #1
3. **App Integration** - Task 3 (main.dart integration) - Builds on #2
4. **UI Implementation** - Task 4 (Settings Screen) - Builds on #3
5. **Navigation** - Task 5 (Wire Settings) - Builds on #4
6. **Special Cases** - Task 6 (Analytics override) - Builds on #3
7. **Validation** - Task 8 (Widget/Integration tests) - Builds on #4, #5, #6

**Parallel work possible:**
- Tasks 7 can be done alongside Task 3
- Tasks 4, 5, 6 can be done in any order after Task 3

**Total estimated effort:** 4.6 days

---

## Architectural Decision Records

### **Decision 1: Use Provider pattern instead of introducing new state management**

**Rationale:**
- App already uses Provider extensively (AuthProvider, ProgramProvider)
- Introducing Riverpod/Bloc would create inconsistency
- Provider is sufficient for theme state management
- Team already familiar with ChangeNotifier pattern

**Consequences:**
- Consistent codebase architecture
- No learning curve for developers
- Easy to test with existing patterns
- Future features should continue using Provider for consistency

### **Decision 2: Store theme in SharedPreferences instead of Firestore**

**Rationale:**
- Requirements specify local-only storage
- Theme is device preference, not user data
- Faster (no network call)
- Works offline by default
- Simpler implementation

**Consequences:**
- Theme preference doesn't sync across devices
- If requirements change to support sync, migration needed
- No server-side analytics on theme preference
- Reduced Firebase costs

### **Decision 3: Force light theme on analytics screen**

**Rationale:**
- Chart libraries often have poor dark mode support
- Analytics readability is critical
- Consistent chart appearance for all users
- Avoids complex chart color customization

**Consequences:**
- Analytics screen always light regardless of app theme
- May feel inconsistent to users in dark mode
- Simpler implementation (no chart color mapping)
- Can revisit if chart library adds better dark mode support

### **Decision 4: Use Material Design 3 themes (no custom theme system)**

**Rationale:**
- MD3 themes already defined in main.dart
- MD3 provides WCAG AA compliant colors out of the box
- Platform-appropriate design (Android + iOS)
- Reduces maintenance burden

**Consequences:**
- Limited color customization (MD3 palette only)
- Consistent with Material Design guidelines
- Easier to maintain and test
- Accessibility guaranteed by MD3 design

---

## Related Documentation

- **PRD:** [Dark Mode Support](https://www.notion.so/Dark-Mode-Support-283879be578981518800ce4913bff27c)
- **GitHub Issue:** [#1 - Dark Mode Support](https://github.com/justbuildstuff-dev/Fitness-App/issues/1)
- **Similar Features:**
  - [`lib/providers/auth_provider.dart`](../fittrack/lib/providers/auth_provider.dart) - Provider pattern reference
  - [`lib/main.dart`](../fittrack/lib/main.dart) - MultiProvider setup and Material Design 3 themes
  - [`lib/screens/profile/profile_screen.dart`](../fittrack/lib/screens/profile/profile_screen.dart) - Navigation pattern
- **Architecture Docs:**
  - [CLAUDE.md](../CLAUDE.md) - Project architecture and development workflow
  - [TestingFramework.md](./TestingFramework.md) - Testing patterns and requirements

---

**Status:** Ready for review and approval

**Next Steps:**
1. User reviews and approves this design
2. Create GitHub implementation task issues (#2-#9)
3. Update GitHub Issue #1 with `design-approved` label
4. Hand off to Developer Agent to begin implementation with Task #2
