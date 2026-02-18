# Changelog

All notable changes to FitTrack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] - 2026-02-18

### Added
- **Exercise Progress Charts** - View progress for any exercise over time with line charts (#262)
  - Searchable exercise picker with type filtering
  - Strength exercises show max weight per session
  - Bodyweight exercises show max reps per session
  - Cardio exercises show distance and duration trends
  - Time range selector: 1 month, 3 months, 6 months, All time
- **Estimated 1RM Tracking** - See theoretical max strength trend on exercise charts (#262)
  - Epley formula calculation from working sets (reps <= 10)
  - Dual-line chart: "Actual Weight" vs "Est. 1RM"
- **Muscle Group Volume Breakdown** - Horizontal bar chart showing training balance (#262)
  - Six muscle groups: Chest, Back, Shoulders, Arms, Legs, Core
  - Set count and percentage per muscle group
  - Uses exercise library muscle group assignments
- **Training Trends** - Weekly volume and frequency trend charts (#262)
  - Weekly total volume (weight x reps) line chart
  - Weekly workout frequency line chart
  - 4-week moving average smoothing
- **Configurable Workout Streaks** - Set weekly target and track consistency (#262)
  - Configurable target: 1-7 workouts per week (default: 3)
  - Current streak and longest streak display
  - Flame icon streak indicator
  - Streak persists in Firestore user preferences
- **PR Celebration Notifications** - Inline banner when a new PR is set (#262)
  - Appears on workout screen after saving a set that beats a PR
  - Shows exercise name, PR type, new value, improvement amount
  - Auto-dismisses after 5 seconds or tap to dismiss
  - "NEW" badge on recent PRs in Analytics PR list

### Changed
- Analytics screen reorganized into 3-tab layout: Overview, Exercise, Trends
- Existing analytics content (heatmap, key stats, charts) moved to Overview tab

### Fixed
- #366 - PR notification not triggering after set creation (wiring missing)
- #367 - Exercise chart legend label changed from 'Weight' to 'Actual Weight'
- Fixed flaky configurable streak tests (calendar week boundary issue)

### Technical
- Added `ExerciseProgressData` and `OneRepMaxEstimate` data models
- Added `ConfigurableStreak` model with user-set weekly target
- Added `LineChartWidget` and `BarChartWidget` using Flutter `CustomPainter`
- Added `ExercisePickerSection` with searchable exercise selection
- Added `ExerciseProgressSection` with time range selector and dual-line charts
- Added `MuscleGroupSection` and `TrainingTrendsSection` components
- Added `StreakSection` with configurable target and flame indicator
- Added `PRNotificationBanner` with navigator overlay persistence pattern
- Extended `AnalyticsService` with per-exercise, 1RM, muscle group, and streak methods
- Extended `ProgramProvider` with analytics loading and PR detection
- All chart data cached with 5-minute TTL matching existing pattern
- 1,446 automated tests passing (805 unit + 579 widget + 48 integration + 14 performance)

## [1.4.0] - 2026-02-13

### Added
- **Pre-built Program Templates** - Start training faster with ready-made programs (#260)
  - Browse curated program templates (Push Pull Legs, Upper/Lower, Full Body, etc.)
  - Preview full program structure before applying (weeks, workouts, exercises, sets)
  - One-tap program creation from any template
  - Server-side templates allow new programs without app updates
  - Offline support with local caching
- **Save as Template** - Turn your workouts, weeks, and programs into reusable templates (#260)
  - Save any workout as a template from the workout detail screen
  - Save weeks and programs as templates from their respective screens
  - Up to 10 templates per type (workout, week, program)
  - Custom naming with validation
- **Template Picker** - Unified template selection experience (#260)
  - Filter by source: All, Pre-built, My Templates
  - Preview bottom sheet with full structure breakdown
  - Template statistics (exercises, sets, workouts, weeks)
  - Smart copy naming avoids duplicate names
- **My Templates Screen** - Manage all saved templates from Profile (#260)
  - Three sections: Workouts, Weeks, Programs
  - Delete templates with confirmation
  - Rename templates inline
  - Template count indicators with limits (10 per type)
- **Create from Template** - "From Template" option on all create screens (#260)
  - Programs: Choose between "Start Fresh" or "From Template"
  - Weeks: Apply week templates with auto-ordering
  - Workouts: Apply workout templates with exercise and set structure

### Fixed
- #348 - Permission denied when creating programs from templates (missing `isArchived` field)
- #348 - Null timestamp crash when loading programs created from templates
- #348 - Firestore number type conversion errors in template model parsing
- #348 - Template picker stuck on loading spinner on first visit

### Technical
- Added `ProgramTemplate`, `WeekTemplate`, `WorkoutTemplate` models with nested template structures
- Added `TemplateProvider` with real-time stream subscriptions and pre-built program caching
- Added `TemplatePickerScreen<T>` generic reusable template picker widget
- Added `TemplatePreviewSheet` bottom sheets for program, week, and workout previews
- Added `SaveTemplateDialog` with limit enforcement and validation
- Added template Firestore service methods (CRUD + deep copy application)
- Added Firestore security rules for `workoutTemplates`, `weekTemplates`, `programTemplates` collections
- Added pre-built programs seed data in `prebuiltPrograms` Firestore collection
- Safe number parsing helpers for Firestore double-to-int conversion
- Null-safe timestamp handling in `ProgramConverter` for optimistic writes
- Reactive `Consumer<TemplateProvider>` pattern for template picker loading state

## [1.3.0] - 2026-01-30

### Added
- **Exercise Library** - Pre-built library of 128 exercises organized by muscle group (#259)
  - Browse exercises by muscle group (Chest, Back, Shoulders, Arms, Legs, Core)
  - Filter by exercise type (Strength, Bodyweight)
  - Filter by source (All, Library, My Exercises)
  - Search exercises by name with real-time filtering
  - View exercise details including primary and secondary muscle groups
  - One-tap add exercises to workouts with set count selector (1-10 sets)
  - Bundled JSON data for offline-first experience
- **Custom Exercises** - Create and manage personal exercises (#259)
  - Create up to 20 custom exercises per user
  - Name, exercise type, and muscle group configuration
  - Edit and delete custom exercises from My Exercises screen
  - Custom exercises appear alongside library exercises in search
  - Firestore storage with per-user data isolation
- **My Exercises Screen** - Manage custom exercises from Settings
  - View all custom exercises with edit/delete options
  - Navigate to create new custom exercises
  - Usage count display (how many workouts use each exercise)
- **Exercise Picker Screen** - Unified exercise selection interface
  - Combined search across library and custom exercises
  - Filter chips for muscle group, exercise type, and source
  - Exercise detail bottom sheet with muscle group info
  - Set count selector before adding to workout
  - "Create Custom" button for quick custom exercise creation

### Changed
- Workout screen now uses Exercise Picker for adding exercises
- Exercise cards display visible drag handle for reordering
- Improved exercise type icons (Strength, Bodyweight, Cardio, Time-based, Custom)

### Fixed
- #302 - Firestore permission denied for custom exercises (rules deployed)
- #303 - Create Custom button navigation now works correctly
- #304 - Set count selector added when adding exercises to workout
- #305 - Muscle filter now only matches primary muscles per PRD
- #306 - Exercise card drag handle now visible for reordering
- #311 - Set row excessive right padding removed
- #312 - Added "My Exercises" filter option in Exercise Picker

### Technical
- Added `MuscleGroup` enum with 6 muscle groups
- Added `LibraryExercise` model for bundled exercises
- Added `CustomExercise` model for user-created exercises
- Added `ExerciseLibraryProvider` for unified exercise management
- Added Firestore security rules for `customExercises` collection
- 128 exercises bundled in `assets/exercise_library.json`
- Comprehensive test coverage (unit, widget, integration tests)

## [1.2.0] - 2026-01-21

### Added
- **Color Scheme Selector** - Personalize your app with 4 vibrant color palettes (#44)
  - Classic Blue (default) - Material Blue, same as before
  - Energetic Orange - High-energy, motivating palette for athletic performance
  - Electric Purple - Modern, trendy palette with youthful energy
  - Crimson Power - Intense, powerful palette for serious training
  - Dropdown selector in Settings screen below Theme Mode
  - Color scheme persists across app restarts (SharedPreferences)
  - Works with all theme modes (Light, Dark, System) - 12 total combinations
  - Instant switching without app restart
  - WCAG AA accessibility compliance for all palettes
  - Material 3 ColorScheme.fromSeed() for consistent color generation
- **Global Bottom Navigation Bar** - Persistent navigation across all screens (#52)
  - One-tap access to Programs, Analytics, and Profile from anywhere in the app
  - Bottom navigation appears on all full-page screens (Programs, Program Details, Weeks, Workouts, Analytics, Profile)
  - Smart section highlighting based on current screen location
  - Navigation stack clearing for clean section switching
  - Modal screens (Create*) correctly excluded from bottom nav
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
- HomeScreen now accepts `initialIndex` parameter for programmatic tab selection
- Navigation behavior: Tapping bottom nav clears entire navigation stack
- Back button after bottom nav navigation exits app instead of returning to previous screens
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
- Created `NavigationSection` enum for type-safe section management
- Created `GlobalBottomNavBar` reusable widget component
- Added 25+ tests for navigation functionality (unit + widget tests)
- Follows standard mobile app navigation patterns (Instagram, Twitter, etc.)
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
