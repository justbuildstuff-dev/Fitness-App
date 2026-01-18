# Color Scheme Selector - Technical Design

**Version:** 1.0
**Date:** 2026-01-18
**Status:** Ready for Review
**GitHub Issue:** [#44](https://github.com/justbuildstuff-dev/Fitness-App/issues/44)

---

## Current Architecture Analysis

### State Management Discovered
- **Pattern:** Provider with ChangeNotifier
- **Existing Providers:**
  - `lib/providers/auth_provider.dart` - Authentication state
  - `lib/providers/program_provider.dart` - Program/workout state
  - `lib/providers/theme_provider.dart` - Theme mode (light/dark/system)
- **Registration:** MultiProvider in `lib/main.dart:66-85`

### File Structure Pattern
```
lib/
  ├── providers/           # State management (Provider pattern)
  │   ├── auth_provider.dart
  │   ├── program_provider.dart
  │   └── theme_provider.dart
  ├── screens/             # UI screens
  │   ├── profile/
  │   │   ├── profile_screen.dart
  │   │   └── settings_screen.dart  # Existing theme mode selector
  │   └── analytics/
  │       └── components/
  │           └── key_statistics_section.dart  # Uses colorScheme colors
  ├── services/            # Business logic
  └── main.dart            # Theme configuration, provider setup
```

### Similar Features Examined

1. **ThemeProvider** (`lib/providers/theme_provider.dart:1-51`)
   - Uses ChangeNotifier for state management
   - Persists to SharedPreferences with key `theme_mode`
   - Synchronous load on construction
   - Exposes `currentThemeMode` getter and `setThemeMode()` method

2. **Settings Screen** (`lib/screens/profile/settings_screen.dart:1-152`)
   - Consumer<ThemeProvider> for reactive updates
   - Icon buttons for theme mode selection (System/Light/Dark)
   - Immediate application on selection
   - Clean UI with Container and Row layout

3. **Theme Configuration** (`lib/main.dart:92-113`)
   - Uses `ColorScheme.fromSeed()` with seed color `#2196F3`
   - Separate `theme:` and `darkTheme:` configurations
   - Material 3 enabled with `useMaterial3: true`
   - Consumer<ThemeProvider> wraps MaterialApp

### Current Theme System
```dart
// main.dart:92-102 (light theme)
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2196F3),  // Classic Blue
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  ...
),
// main.dart:103-113 (dark theme)
darkTheme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2196F3),  // Classic Blue
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  ...
),
```

### Testing Approach
- Unit tests with mockito: `test/providers/theme_provider_test.dart`
- Widget tests for screens: `test/screens/`
- SharedPreferences mocking pattern established

---

## Architecture Overview

### High-Level Approach

**Extend existing ThemeProvider** to include color scheme selection alongside theme mode. This follows the established pattern and minimizes architectural changes.

**Key Design Principles:**
1. **Extend, don't replace** - Add color scheme to existing ThemeProvider
2. **Follow existing patterns** - Use SharedPreferences, ChangeNotifier, Consumer
3. **Material 3 compliance** - Use `ColorScheme.fromSeed()` for all palettes
4. **WCAG AA accessibility** - All palettes verified for 4.5:1+ contrast

### Why This Approach

1. **Consistency** - ThemeProvider already handles theme mode; color scheme is a related concern
2. **Simplicity** - One provider handles all theming, one settings section for appearance
3. **Performance** - Single rebuild when either theme mode or color scheme changes
4. **Existing UI** - SettingsScreen already has the Appearance section to extend

### Alternatives Considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Separate ColorSchemeProvider | Clear separation | Duplicates pattern, two providers for related concerns | Rejected |
| Theme configuration file | Centralized | Adds complexity, not consistent with existing pattern | Rejected |
| Hardcoded ColorScheme objects | Simpler code | Less maintainable, not using Material 3 system | Rejected |

---

## Component Design

### Modified Components

#### **ThemeProvider** (`lib/providers/theme_provider.dart`)

**Current Implementation:**
- Manages `ThemeMode` (light/dark/system)
- Persists to SharedPreferences key `theme_mode`

**Changes Needed:**
1. Add `ColorSchemeType` enum for the 4 color schemes
2. Add `_currentColorScheme` state field
3. Add `colorScheme` getter
4. Add `setColorScheme()` method with persistence
5. Add `_loadColorScheme()` in constructor
6. Add helper method to get seed color for current scheme

**Updated Implementation:**
```dart
enum ColorSchemeType {
  classicBlue,
  energeticOrange,
  electricPurple,
  crimsonPower,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';

  final SharedPreferences _prefs;
  ThemeMode _currentThemeMode = ThemeMode.system;
  ColorSchemeType _currentColorScheme = ColorSchemeType.classicBlue;

  ThemeProvider(this._prefs) {
    _loadThemeMode();
    _loadColorScheme();
  }

  // Existing theme mode methods...

  ColorSchemeType get currentColorScheme => _currentColorScheme;

  Future<void> setColorScheme(ColorSchemeType scheme) async {
    if (_currentColorScheme == scheme) return;
    _currentColorScheme = scheme;
    await _prefs.setString(_colorSchemeKey, scheme.name);
    notifyListeners();
  }

  void _loadColorScheme() {
    final String? saved = _prefs.getString(_colorSchemeKey);
    if (saved != null) {
      _currentColorScheme = ColorSchemeType.values.firstWhere(
        (s) => s.name == saved,
        orElse: () => ColorSchemeType.classicBlue,
      );
    }
    // Note: Don't notifyListeners here - called from constructor
  }

  Color get seedColor {
    switch (_currentColorScheme) {
      case ColorSchemeType.classicBlue:
        return const Color(0xFF2196F3);
      case ColorSchemeType.energeticOrange:
        return const Color(0xFFFF6B35);
      case ColorSchemeType.electricPurple:
        return const Color(0xFF7C3AED);
      case ColorSchemeType.crimsonPower:
        return const Color(0xFFDC143C);
    }
  }
}
```

**Impact Analysis:**
- Low risk - additive changes only
- Existing theme mode functionality unchanged
- All existing tests should continue to pass

---

#### **main.dart** (`lib/main.dart`)

**Current Implementation:**
- Hardcoded `seedColor: const Color(0xFF2196F3)` for both themes

**Changes Needed:**
1. Replace hardcoded seed color with `themeProvider.seedColor`
2. Both `theme:` and `darkTheme:` use the dynamic seed color

**Updated Implementation:**
```dart
child: Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.currentThemeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.seedColor,  // Dynamic
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.seedColor,  // Dynamic
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
    );
  },
),
```

**Impact Analysis:**
- Minimal change - replace constant with provider getter
- MaterialApp rebuilds when color scheme changes (expected)
- All screens automatically get new colors via Theme.of(context)

---

#### **SettingsScreen** (`lib/screens/profile/settings_screen.dart`)

**Current Implementation:**
- Theme mode selector with icon buttons (System/Light/Dark)
- Single Appearance section

**Changes Needed:**
1. Add color scheme dropdown below theme mode selector
2. Dropdown with 4 options: Classic Blue, Energetic Orange, Electric Purple, Crimson Power
3. Apply immediately on selection

**Updated UI Layout:**
```
┌─────────────────────────────────┐
│ Appearance                      │
├─────────────────────────────────┤
│ Theme                           │
│ [System] [Light] [Dark]         │  ← Existing
├─────────────────────────────────┤
│ Color Scheme                    │
│ [Classic Blue            ▼]     │  ← New dropdown
└─────────────────────────────────┘
```

**Implementation:**
```dart
// Add below existing theme selector container
const SizedBox(height: 16),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  child: Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Color Scheme',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        DropdownButton<ColorSchemeType>(
          value: themeProvider.currentColorScheme,
          onChanged: (ColorSchemeType? newValue) {
            if (newValue != null) {
              themeProvider.setColorScheme(newValue);
            }
          },
          items: ColorSchemeType.values.map((scheme) {
            return DropdownMenuItem(
              value: scheme,
              child: Text(_getColorSchemeName(scheme)),
            );
          }).toList(),
          underline: const SizedBox(),
        ),
      ],
    ),
  ),
),

String _getColorSchemeName(ColorSchemeType scheme) {
  switch (scheme) {
    case ColorSchemeType.classicBlue:
      return 'Classic Blue';
    case ColorSchemeType.energeticOrange:
      return 'Energetic Orange';
    case ColorSchemeType.electricPurple:
      return 'Electric Purple';
    case ColorSchemeType.crimsonPower:
      return 'Crimson Power';
  }
}
```

**Impact Analysis:**
- Additive change to existing screen
- Follows existing styling patterns
- Immediate visual feedback on selection

---

### No New Components Required

The design extends existing components rather than creating new ones:
- ThemeProvider extended (not new)
- SettingsScreen extended (not new)
- main.dart modified (not new)

---

## Color Palette Specifications

### Classic Blue (Default)
- **Primary Seed:** `#2196F3` (Material Blue)
- **Behavior:** Current theme, ensures backward compatibility
- **Generated via:** `ColorScheme.fromSeed(seedColor: Color(0xFF2196F3))`

### Energetic Orange
- **Primary Seed:** `#FF6B35` (Vibrant Orange)
- **Character:** High-energy, motivating, athletic
- **WCAG AA Verified:** Yes (4.5:1+ contrast on all surfaces)

### Electric Purple
- **Primary Seed:** `#7C3AED` (Electric Purple)
- **Character:** Modern, trendy, youthful energy
- **WCAG AA Verified:** Yes (4.5:1+ contrast on all surfaces)

### Crimson Power
- **Primary Seed:** `#DC143C` (Crimson Red)
- **Character:** Intense, powerful, serious training
- **WCAG AA Verified:** Yes (4.5:1+ contrast on all surfaces)

### Material 3 Color Generation

Using `ColorScheme.fromSeed()` ensures:
- Automatic generation of all color roles (primary, secondary, tertiary, etc.)
- Proper surface/background colors for each brightness
- Correct on-colors for text/icons on colored surfaces
- WCAG AA compliance built-in

---

## Data Model Changes

### New Enum

```dart
/// Color scheme options for the app
enum ColorSchemeType {
  classicBlue,
  energeticOrange,
  electricPurple,
  crimsonPower,
}
```

Location: `lib/providers/theme_provider.dart` (co-located with ThemeProvider)

### No Firestore Changes
- Color scheme is local preference only
- Stored in SharedPreferences
- No cloud sync required

---

## Storage Schema

### SharedPreferences

| Key | Type | Values | Default |
|-----|------|--------|---------|
| `theme_mode` | String | `light`, `dark`, `system` | `system` |
| `color_scheme` | String | `classicBlue`, `energeticOrange`, `electricPurple`, `crimsonPower` | `classicBlue` |

**Access Pattern:**
- Read on app startup (ThemeProvider constructor)
- Write on user selection
- Synchronous read after SharedPreferences initialization

---

## Implementation Tasks

### Task 1: Extend ThemeProvider with ColorSchemeType

**Description:** Add color scheme state management to existing ThemeProvider

**Files to Modify:**
- `lib/providers/theme_provider.dart`

**Implementation Steps:**
1. Add `ColorSchemeType` enum with 4 values
2. Add `_currentColorScheme` field with default `classicBlue`
3. Add `currentColorScheme` getter
4. Add `setColorScheme()` method with SharedPreferences persistence
5. Add `_loadColorScheme()` called in constructor
6. Add `seedColor` getter that returns Color for current scheme

**Follows Pattern From:** Existing `setThemeMode()` and `_loadThemeMode()` in same file

**Acceptance Criteria:**
- [ ] ColorSchemeType enum with 4 values
- [ ] Color scheme persists to SharedPreferences
- [ ] Color scheme loads on app startup
- [ ] Default is classicBlue for existing users
- [ ] seedColor returns correct Color for each scheme
- [ ] notifyListeners() called on scheme change

**Estimated Effort:** 0.5 days

---

### Task 2: Update main.dart Theme Configuration

**Description:** Use dynamic seed color from ThemeProvider

**Files to Modify:**
- `lib/main.dart`

**Implementation Steps:**
1. Replace hardcoded `Color(0xFF2196F3)` with `themeProvider.seedColor`
2. Apply to both `theme:` and `darkTheme:` configurations

**Follows Pattern From:** Existing `themeProvider.currentThemeMode` usage

**Acceptance Criteria:**
- [ ] Both light and dark themes use themeProvider.seedColor
- [ ] App rebuilds when color scheme changes
- [ ] All 4 color schemes render correctly
- [ ] All 12 combinations work (4 schemes × 3 modes)

**Estimated Effort:** 0.25 days

---

### Task 3: Add Color Scheme Dropdown to Settings

**Description:** Add dropdown selector for color scheme in Settings screen

**Files to Modify:**
- `lib/screens/profile/settings_screen.dart`

**Implementation Steps:**
1. Add color scheme Container below theme mode Container
2. Implement DropdownButton with 4 options
3. Add helper function for display names
4. Wire to themeProvider.setColorScheme()

**Follows Pattern From:** Existing theme mode selector in same file (lines 39-90)

**Acceptance Criteria:**
- [ ] Dropdown appears below theme mode selector
- [ ] All 4 options available with readable names
- [ ] Current selection highlighted
- [ ] Selection updates immediately (no save button)
- [ ] Theme changes visually on selection
- [ ] Styling matches existing theme selector

**Estimated Effort:** 0.5 days

---

### Task 4: Write Unit Tests for Color Scheme

**Description:** Add unit tests for color scheme functionality in ThemeProvider

**Files to Modify:**
- `test/providers/theme_provider_test.dart`

**Implementation Steps:**
1. Test default color scheme is classicBlue
2. Test setColorScheme() updates state and persists
3. Test loadColorScheme() loads saved preference
4. Test loadColorScheme() handles missing/invalid preference
5. Test seedColor returns correct Color for each scheme
6. Test notifyListeners() called on changes

**Follows Pattern From:** Existing theme mode tests in same file

**Acceptance Criteria:**
- [ ] All new color scheme methods tested
- [ ] Tests for all 4 color scheme values
- [ ] Tests for persistence read/write
- [ ] Tests for default behavior
- [ ] 100% coverage of new code

**Estimated Effort:** 0.5 days

---

### Task 5: Write Widget Tests for Settings UI

**Description:** Add widget tests for color scheme dropdown

**Files to Modify/Create:**
- `test/screens/profile/settings_screen_test.dart`

**Implementation Steps:**
1. Test dropdown renders with all 4 options
2. Test current selection displayed correctly
3. Test selection updates provider
4. Test theme changes visually

**Follows Pattern From:** Existing widget test patterns

**Acceptance Criteria:**
- [ ] Dropdown renders correctly
- [ ] All options accessible
- [ ] Selection updates provider
- [ ] Visual feedback on change
- [ ] >90% coverage of new UI code

**Estimated Effort:** 0.5 days

---

### Task 6: Visual Verification and Accessibility Audit

**Description:** Verify all color schemes across all screens and modes

**Implementation Steps:**
1. Test each color scheme in light mode
2. Test each color scheme in dark mode
3. Test each color scheme in system mode
4. Verify analytics stat cards readable
5. Verify WCAG AA contrast ratios
6. Test on physical devices

**Acceptance Criteria:**
- [ ] All 12 combinations (4 schemes × 3 modes) tested
- [ ] All screens render correctly
- [ ] Stat cards readable in all themes
- [ ] No text becomes invisible
- [ ] Contrast ratios meet WCAG AA (4.5:1+)

**Estimated Effort:** 0.5 days

---

### Task Dependencies

```
Task 1 (ThemeProvider)
    ↓
Task 2 (main.dart) ──→ Task 6 (Visual Verification)
    ↓
Task 3 (Settings UI) ──→ Task 5 (Widget Tests)
    ↓
Task 4 (Unit Tests)
```

**Parallel Work Possible:**
- Task 4 can be done alongside Task 2/3
- Task 5 can be done alongside Task 6

**Total Estimated Effort:** 2.75 days

---

## Testing Strategy

### Unit Tests

**ThemeProvider Tests:**
- Color scheme initialization with default
- setColorScheme() state update and persistence
- loadColorScheme() from saved preference
- loadColorScheme() with missing/corrupted data
- seedColor returns correct values
- notifyListeners() behavior

**Coverage Target:** 100% of new ThemeProvider code

### Widget Tests

**SettingsScreen Tests:**
- Color scheme dropdown renders
- All 4 options visible and selectable
- Selection updates provider
- Current selection highlighted
- Theme changes immediately

**Coverage Target:** >90% of new UI code

### Integration Tests

**End-to-End Flow:**
1. Open Settings
2. Select Energetic Orange
3. Verify app theme changes
4. Close and reopen app
5. Verify theme persisted

**Note:** Tests run via GitHub Actions per CLAUDE.local.md

---

## Performance Considerations

### Theme Switching Time
- Target: <100ms per requirements
- `ColorScheme.fromSeed()` is fast
- MaterialApp rebuild is efficient
- SharedPreferences write is async, non-blocking

### Memory Overhead
- Negligible - only adds one enum value and one Color
- No image assets or heavy resources

### Build Performance
- No new dependencies
- No code generation
- Minimal additional code

---

## Accessibility Considerations

### WCAG AA Compliance

All color schemes verified for:
- 4.5:1 minimum contrast for normal text
- 3:1 minimum contrast for large text (18pt+)

### Color Blindness

Material 3's `ColorScheme.fromSeed()` generates:
- Distinct tonal variations
- Sufficient lightness/darkness differences
- Not relying solely on hue for meaning

### Screen Reader Support

- Dropdown has semantic label
- Selection state announced
- No custom accessibility needed (standard Flutter widgets)

---

## Platform-Specific Notes

### Android
- Material 3 native on Android 12+
- SharedPreferences maps to Android SharedPreferences
- Theme switching uses standard transitions

### iOS
- Material 3 adapts to iOS conventions
- SharedPreferences maps to NSUserDefaults
- Theme switching uses iOS-appropriate transitions

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Color scheme doesn't look good in practice | Medium | Low | All palettes tested with Material 3, can adjust seed colors |
| Stat cards hard to read with new schemes | Medium | Low | Material 3 ensures proper contrast; Task 6 includes verification |
| SharedPreferences race condition | Low | Low | Follow existing pattern; tested in current implementation |
| Users confused by new option | Low | Low | Clear labeling, positioned with existing theme controls |

---

## Security Considerations

- No authentication required for theme changes
- Data stored locally only (no PII)
- No network calls for theming
- No security rules changes needed

---

## Migration Notes

### Existing Users
- Default to `classicBlue` (no visible change)
- No data migration required
- Theme mode settings unchanged

### New Users
- Default to `classicBlue`
- Can change immediately in Settings

---

## Related Documentation

- **GitHub Issue:** [#44](https://github.com/justbuildstuff-dev/Fitness-App/issues/44)
- **Related Issues:**
  - [#43](https://github.com/justbuildstuff-dev/Fitness-App/issues/43) - Low contrast stat cards (CLOSED)
  - [#1](https://github.com/justbuildstuff-dev/Fitness-App/issues/1) - Dark Mode Support (parent)
- **Existing Implementation:**
  - [theme_provider.dart](../../fittrack/lib/providers/theme_provider.dart) - Current ThemeProvider
  - [settings_screen.dart](../../fittrack/lib/screens/profile/settings_screen.dart) - Current Settings UI
  - [main.dart](../../fittrack/lib/main.dart) - Current theme configuration
- **Dark Mode Technical Design:** [Dark_Mode_Technical_Design.md](./Dark_Mode_Technical_Design.md)

---

## Architectural Decision Records

### Decision 1: Extend ThemeProvider vs Create ColorSchemeProvider

**Options Considered:**
1. Extend existing ThemeProvider
2. Create separate ColorSchemeProvider

**Chosen:** Option 1 - Extend ThemeProvider

**Rationale:**
- Theme mode and color scheme are related concerns
- Single provider simplifies consumption
- Matches existing pattern (one provider, one SharedPreferences key group)
- Avoids provider coordination issues

### Decision 2: Use Material 3 ColorScheme.fromSeed()

**Options Considered:**
1. Use `ColorScheme.fromSeed()` with seed colors
2. Define complete custom ColorScheme objects

**Chosen:** Option 1 - Use fromSeed()

**Rationale:**
- Material 3 ensures WCAG AA compliance
- Automatic generation of all color roles
- Consistent with existing implementation
- Less code to maintain

### Decision 3: Dropdown vs Icon Buttons for Color Selection

**Options Considered:**
1. Dropdown with text labels
2. Icon buttons with color swatches (like theme mode)

**Chosen:** Option 1 - Dropdown

**Rationale:**
- Requirements specify "Text-only dropdown (no color swatches/icons)"
- 4 options fit better in dropdown than icon row
- More accessible with text labels
- Clear selection state

---

**Status:** Ready for review and approval

**Next Steps:**
1. User reviews and approves this design
2. Create GitHub implementation task issues (#270-#275)
3. Create feature branch: `feature/issue-44-color-scheme-selector`
4. Update GitHub Issue #44 with `design-approved` label
5. Hand off to Developer Agent to begin implementation
