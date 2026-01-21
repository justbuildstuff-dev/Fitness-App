# FitTrack v1.2.0 Release Notes

**Release Date:** 2026-01-21
**Version:** 1.2.0+4
**Platforms:** Android, iOS

## What's New

### Color Scheme Selector - Personalize Your FitTrack Experience

Make FitTrack truly yours with 4 vibrant color palettes! Choose the color scheme that matches your personality and workout energy.

**Available Color Schemes:**

- **Classic Blue** (default) - The familiar Material Blue theme you know and love
- **Energetic Orange** - High-energy, motivating palette perfect for intense workouts
- **Electric Purple** - Modern, trendy palette with youthful energy
- **Crimson Power** - Intense, powerful palette for serious training

**Key Features:**
- Easy selection from Settings > Appearance > Color Scheme dropdown
- Works with all theme modes (Light, Dark, System) - 12 total combinations!
- Your preference persists across app restarts
- Instant switching - no restart required
- Color preview circles in the dropdown for easy selection
- All palettes meet WCAG AA accessibility standards

**Where to Find It:**
Profile > Settings > Appearance > Color Scheme

### Enhanced Delete Functionality with Cascade Information

Deleting weeks, workouts, and exercises is now more reliable and informative! We've overhauled delete confirmation dialogs to show exactly what will be affected.

**Key Improvements:**
- Clear cascade information showing how many child items will be deleted
- Visual item highlighting in confirmation dialogs
- Better error handling with clear, actionable messages
- Professional UI with warning icons and "cannot be undone" messaging

### Global Bottom Navigation Bar

Navigate FitTrack faster with the new persistent bottom navigation bar!

- One-tap access to Programs, Analytics, and Profile from anywhere
- Smart section highlighting based on current screen
- Clean navigation stack management

### Consolidated Workout Screen

Streamlined workout tracking with 40% fewer navigation clicks!

- All exercises and sets displayed inline on one screen
- Inline set editing with type-specific fields
- Quick set addition and drag-and-drop exercise reordering
- Notes and rest time modal for detailed tracking

## Benefits

- **Personalization:** Express yourself with 4 distinct color themes
- **Accessibility:** All color schemes meet WCAG AA contrast standards
- **Consistency:** Theme works seamlessly across all screens
- **Flexibility:** Mix and match color schemes with light/dark modes

## Technical Improvements

### Color Scheme Feature (#44)
- Extended ThemeProvider with ColorSchemeType enum
- Material 3 ColorScheme.fromSeed() for consistent color generation
- SharedPreferences persistence with key 'color_scheme'
- 15 new unit tests for ThemeProvider color scheme methods
- 9 new widget tests for Settings color scheme UI
- Semantic accessibility labels for screen reader support

### Code Quality
- All automated tests passing (Unit, Widget, Integration)
- WCAG AA accessibility verified for all color palettes
- Clean implementation following existing provider patterns

## Known Issues

- #281: Set row layout cramped on mobile (Weight label truncated) - Separate bug, does not affect color scheme feature

## Upgrade Notes

This update is fully backward compatible. Existing users will default to "Classic Blue" theme - the same appearance they've always had. The new color scheme option is entirely opt-in.

---

**GitHub Issue:** [#44 - Color Scheme Selector](https://github.com/justbuildstuff-dev/Fitness-App/issues/44)
**Technical Design:** [Color Scheme Selector Technical Design](https://github.com/justbuildstuff-dev/Fitness-App/blob/main/Docs/Technical_Designs/Color_Scheme_Selector_Technical_Design.md)

## Implementation Tasks Completed

- Task #269: Extend ThemeProvider with ColorSchemeType
- Task #270: Update main.dart Theme Configuration
- Task #271: Add Color Scheme Dropdown to Settings
- Task #272: Write Unit Tests for Color Scheme
- Task #273: Write Widget Tests for Settings Color Scheme UI
- Task #274: Visual Verification and Accessibility Audit
