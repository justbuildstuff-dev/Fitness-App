# Changelog

All notable changes to FitTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-10-18

### Added
- **Dark Mode Support** - Full dark theme with three options: Light, Dark, and System Default (#1)
  - Settings screen for theme selection accessible from Profile
  - ThemeProvider for efficient theme state management
  - Material Design 3 dark theme implementation (#121212 background)
  - Theme preference persistence using SharedPreferences
  - WCAG AA accessibility compliance for both light and dark themes
  - Instant theme switching without app restart
  - Analytics screen forced to light mode for chart readability

### Changed
- Updated Material Design theming to support dynamic theme switching
- Added Settings navigation from Profile screen

### Technical
- Added `shared_preferences: ^2.2.2` dependency for local storage
- Integrated ThemeProvider into main.dart MultiProvider setup
- Comprehensive test coverage for theme functionality (>90%)

## [1.0.0] - 2025-10-04

### Added
- Initial release of FitTrack
- User authentication with Firebase Auth
- Program and workout management
- Exercise tracking with sets, reps, weight, duration
- Analytics screen with workout statistics
- Offline support with local caching
- Data export functionality (CSV)
- Firebase Firestore integration for cloud sync
- Material Design 3 UI (light mode only)
