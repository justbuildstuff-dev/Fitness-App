# Changelog

All notable changes to FitTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Consolidated Workout Screen** - Streamlined workout tracking interface (#53)
  - Reduced navigation clicks by 40% (from 5 screens → 3 screens)
  - All exercises and sets displayed inline on one screen
  - Inline set editing with type-specific fields (weight, reps, duration, distance)
  - Set completion tracking with checkbox (no strikethrough)
  - Quick set addition (up to 10 sets per exercise)
  - Exercise reordering via drag-and-drop
  - Set count stepper on exercise creation (create 1-10 sets at once)
  - Notes and rest time modal for detailed set tracking
  - Enhanced delete confirmations with cascade counts
  - Batched data loading for improved performance (~45% query reduction)

### Changed
- Updated WeeksScreen to navigate to ConsolidatedWorkoutScreen instead of separate detail screens
- Enhanced CreateExerciseScreen with set count stepper (1-10 sets)
- Improved ProgramProvider with batched set loading (loadAllSetsForWorkout)
- Updated navigation flow to eliminate redundant screens

### Fixed
- #51 - Sets no longer crossed out when completed (improved readability with read-only fields instead)
- #230 - E2E integration test stability improvements
  - Fixed Firebase emulator re-initialization preventing test suite from running
  - Fixed authentication flow in Complete Workflow tests (proper OOB pattern)
  - Fixed Firestore listener cleanup on sign-out (prevents orphaned listeners)
  - Fixed property validation in cascade delete tests (restTime/notes fields)
  - Updated analytics tests to match current UI (monthly heatmap)
  - Improved test reliability: 27.5% → 47.5% pass rate (11/40 → 19/40 passing)

### Deprecated
- WorkoutDetailScreen - Use ConsolidatedWorkoutScreen instead
- ExerciseDetailScreen - Use inline editing in ConsolidatedWorkoutScreen instead

### Technical
- Added FirestoreService.createExerciseWithSets() for atomic exercise + sets creation
- Added ProgramProvider.loadAllSetsForWorkout() for batched set loading
- Comprehensive test coverage for new screens (28+ tests)
- Updated existing tests for setCount parameter compatibility

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
