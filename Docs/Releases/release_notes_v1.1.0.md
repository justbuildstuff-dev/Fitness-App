# FitTrack v1.1.0 Release Notes

**Release Date:** October 18, 2025
**Version:** 1.1.0+3
**Platforms:** Android, iOS

## What's New

### Dark Mode Support

FitTrack now supports dark mode! Enjoy a more comfortable viewing experience during evening workouts or in low-light conditions.

**Key Features:**
- **Three Theme Options:** Choose between Light, Dark, or System Default (automatically matches your device settings)
- **Instant Switching:** Theme changes take effect immediately - no app restart required
- **Persistent Preference:** Your theme choice is saved and remembered across app sessions
- **Material Design 3:** Professional, polished appearance following the latest Material Design standards
- **Accessibility:** WCAG AA compliant contrast ratios ensure readability in both light and dark themes
- **Battery Savings:** Dark mode can help extend battery life on OLED/AMOLED displays

**Where to Find It:**
Go to Profile → Settings → Appearance to select your preferred theme.

**Note:** The Analytics screen will always display in light mode to ensure charts and statistics remain easily readable.

## Benefits

- **Reduced Eye Strain:** Perfect for logging workouts in the evening or before bed
- **Better Battery Life:** Dark mode uses less power on OLED displays
- **Modern Experience:** Join the dark mode revolution with a sleek, contemporary look
- **Flexible Choice:** Use what works best for you - light, dark, or automatic

## Technical Improvements

- Added ThemeProvider for efficient state management
- Implemented local preference storage with SharedPreferences
- Integrated Material Design 3 theming system
- Comprehensive test coverage (>90%) for theme functionality

## Bug Fixes

None - this is a new feature release.

## Known Issues

None reported.

## Upgrade Notes

This update is fully backward compatible. Existing users will default to System theme (matching device settings) on first launch after updating.

---

**GitHub Issue:** [#1 - Dark Mode Support](https://github.com/justbuildstuff-dev/Fitness-App/issues/1)
**PRD:** [Dark Mode Support](https://www.notion.so/Dark-Mode-Support-283879be578981518800ce4913bff27c)
