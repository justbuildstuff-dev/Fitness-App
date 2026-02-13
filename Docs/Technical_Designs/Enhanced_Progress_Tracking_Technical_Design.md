# Enhanced Progress Tracking & Charts - Technical Design

**GitHub Issue:** [#262](https://github.com/justbuildstuff-dev/Fitness-App/issues/262)
**PRD:** [Docs/PRDs/Enhanced_Progress_Tracking_PRD.md](../PRDs/Enhanced_Progress_Tracking_PRD.md)
**Status:** Design Complete
**Created:** 2026-02-13
**SA Agent:** Solutions Architect

---

## Current Architecture Analysis

### Discovered Patterns

| Pattern | Location | Usage |
|---------|----------|-------|
| **State Management** | Provider pattern with ChangeNotifier | `lib/providers/*.dart` |
| **Analytics Service** | Singleton with 5-min map-based cache | `lib/services/analytics_service.dart` |
| **Analytics Screen** | Consumer<ProgramProvider> with 3 sections | `lib/screens/analytics/analytics_screen.dart` |
| **Data Traversal** | Hierarchical: programs→weeks→workouts→exercises→sets | `analytics_service.dart:409-508` |
| **Chart Rendering** | Container-based bar charts (no CustomPainter yet) | `charts_section.dart:87-216` |
| **PR Detection** | checkForNewPR() in AnalyticsService, wired via ProgramProvider | `analytics_service.dart:340-361`, `program_provider.dart:1405-1429` |
| **Streak Calculation** | Daily consecutive streaks from set counts | `analytics_service.dart:775-812` |
| **Exercise Library** | Bundled JSON (128 exercises) + Firestore custom exercises | `exercise_library_provider.dart` |
| **MuscleGroup** | 6-value enum (chest, back, shoulders, arms, legs, core) | `lib/models/muscle_group.dart` |
| **User Settings** | `settings` map in `users/{userId}` document | `user_profile.dart:9`, `firestore.rules:242` |
| **Converters** | Separate Firestore serialization layer | `lib/converters/*.dart` |

### Similar Features Examined

1. **ExerciseTypeChart** (`charts_section.dart:87-216`) - Container-based proportional bar chart with legend, colors mapped per ExerciseType
2. **MonthlyHeatmapSection** (`monthly_heatmap_section.dart`) - PageView with caching, swipe navigation, intensity-based cell colors
3. **PersonalRecordTile** (`charts_section.dart:268-420`) - PR display with type-specific icons, colors, time-ago formatting, improvement badges
4. **KeyStatisticsSection** (`key_statistics_section.dart`) - 8 metric cards in grid layout with formatted values

### Key Codebase Constraints

1. **Exercise model has no `muscleGroup` field** - `lib/models/exercise.dart:57-187` only stores `name` and `exerciseType`. To map exercises to muscle groups, we must match exercise names to `LibraryExercise` or `CustomExercise` via `ExerciseLibraryProvider.getLibraryExerciseById()` / `searchExercises()`.

2. **Exercise model has no `libraryExerciseId`** - Exercises are created by name, not linked to library entries. Name-based matching is required for muscle group lookup.

3. **PR detection exists but is NOT wired to UI** - `ProgramProvider.checkForPersonalRecord()` (line 1405) exists and updates `_recentPRs`, but `CreateSetScreen._saveSet()` (line 480) does not call it after creating a set.

4. **UserProfile.settings** is a nullable `Map<String, dynamic>` validated by Firestore rules as `data.settings == null || data.settings is map` - no schema changes needed for `workoutTarget`.

5. **No CustomPainter exists yet** - All current charts use Container widgets. This feature introduces the first CustomPainter-based charts.

This design follows existing patterns for consistency.

---

## Architecture Overview

### High-Level Strategy

Extend the existing analytics infrastructure with four new capabilities:

1. **Per-exercise time-series data** computed from existing sets, displayed in CustomPainter line charts
2. **Muscle group volume aggregation** using name-based exercise library matching
3. **Configurable weekly streak tracking** replacing the current daily streak with user-set targets
4. **PR inline notifications** by wiring existing `checkForPersonalRecord()` into the set creation flow

### Why This Approach

- **Extends AnalyticsService** (`analytics_service.dart`) rather than creating a new service - follows singleton pattern
- **Uses existing data traversal** (`_getAllUserSets`, `_getAllUserExercises`) - no new Firestore queries or collections
- **Stores streak target in `UserProfile.settings`** map - Firestore rules already validate `settings is map`, no rule changes
- **CustomPainter for charts** as specified in PRD - provides full control over rendering, no external dependency
- **Tab-based Analytics screen** to organize growing content without overwhelming scroll

### Alternatives Considered

| Alternative | Rejected Because |
|-------------|------------------|
| `fl_chart` package for charts | PRD requires no external charting library; CustomPainter matches existing pattern direction |
| New Firestore collection for computed analytics | All data computable client-side from existing sets; adds unnecessary complexity |
| Separate ProgressProvider | Analytics data already flows through ProgramProvider; adding another proxy provider adds complexity |
| Daily streak with workout detection | PRD specifies weekly configurable targets (Mon-Sun calendar weeks) |

---

## Component Design

### New Components

#### 1. Analytics Data Models

**Location:** `lib/models/analytics.dart` (extend existing file)

```dart
/// Per-exercise progress data point (one per workout session)
class ExerciseProgressPoint {
  final DateTime date;
  final String workoutId;
  final double? maxWeight;      // Highest weight in session
  final int? maxReps;           // Highest reps in session
  final double? totalVolume;    // Sum(weight * reps) for session
  final int? totalDuration;     // Sum duration for session
  final double? totalDistance;   // Sum distance for session
  final double? estimated1RM;   // Epley formula from best set
}

/// Aggregated exercise progress for charting
class ExerciseProgressData {
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final List<ExerciseProgressPoint> dataPoints;
  final DateRange dateRange;
}

/// Muscle group volume breakdown
class MuscleGroupVolume {
  final MuscleGroup muscleGroup;
  final int totalSets;
  final double percentage;      // Of total sets across all groups
}

/// Weekly training trend data point
class WeeklyTrendPoint {
  final DateTime weekStart;     // Monday of the week
  final double totalVolume;     // Sum(weight * reps) for the week
  final int workoutCount;       // Number of workouts that week
}

/// Configurable streak data
class ConfigurableStreak {
  final int weeklyTarget;       // 1-7 workouts per week
  final int currentStreak;      // Consecutive weeks meeting target
  final int longestStreak;      // Longest streak ever
}
```

#### 2. 1RM Calculation Utility

**Location:** `lib/utils/one_rm_calculator.dart`

```dart
class OneRMCalculator {
  /// Epley formula (primary): weight * (1 + reps / 30)
  static double epley(double weight, int reps);

  /// Brzycki formula (alternative): weight * (36 / (37 - reps))
  static double brzycki(double weight, int reps);

  /// Calculate estimated 1RM from best set in a session
  /// Returns null if reps > 10 or weight <= 0
  static double? estimateFromSets(List<ExerciseSet> sets);
}
```

#### 3. Custom Chart Painters

**Location:** `lib/widgets/charts/`

```dart
// lib/widgets/charts/line_chart_painter.dart
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> primaryData;
  final List<ChartDataPoint>? secondaryData;  // For 1RM overlay
  final DateRange dateRange;
  final Color primaryColor;
  final Color? secondaryColor;
  final ChartDataPoint? selectedPoint;
  // Renders: axes, gridlines, data points, connecting lines, labels
}

// lib/widgets/charts/bar_chart_painter.dart
class BarChartPainter extends CustomPainter {
  final List<BarChartEntry> entries;  // MuscleGroup volumes
  // Renders: horizontal bars with labels, values, percentages
}

// lib/widgets/charts/chart_data.dart
class ChartDataPoint {
  final DateTime date;
  final double value;
  final String? label;
}

class BarChartEntry {
  final String label;
  final double value;
  final double percentage;
  final Color color;
}
```

#### 4. Exercise Progress Chart Screen

**Location:** `lib/screens/analytics/exercise_progress_screen.dart`

- Exercise selection with search (reuses `ExerciseLibraryProvider.searchExercises()` pattern)
- Only shows exercises the user has actually logged (filtered from sets data)
- Line chart with time range selector (1M, 3M, 6M, All)
- Strength: Max Weight line + Est. 1RM line (dual-line)
- Other types: Primary metric line only
- Tap on data point shows tooltip with exact values

#### 5. Analytics Tab Structure

**Location:** `lib/screens/analytics/analytics_screen.dart` (modified)

Current: `SingleChildScrollView` with 3 sections
New: `TabBarView` with 3 tabs:

| Tab | Contents | Status |
|-----|----------|--------|
| **Overview** | Monthly Heatmap, Key Statistics, Exercise Type Breakdown, PR List | Existing (reorganized) |
| **Exercise** | Exercise Progress Charts (per-exercise selection) | New |
| **Trends** | Muscle Group Volume, Weekly Training Trends, Configurable Streak | New |

#### 6. PR Notification Banner

**Location:** `lib/widgets/pr_notification_banner.dart`

```dart
class PRNotificationBanner extends StatefulWidget {
  final PersonalRecord record;
  final VoidCallback onDismiss;
  // Shows: exercise name, PR type, new value, improvement
  // Auto-dismisses after 5 seconds
  // Slide-in animation from top
}
```

### Modified Components

#### 1. AnalyticsService (`lib/services/analytics_service.dart`)

**New public methods:**

```dart
/// Compute per-exercise progress data
Future<ExerciseProgressData> getExerciseProgress({
  required String userId,
  required String exerciseId,
  required String exerciseName,
  required ExerciseType exerciseType,
  required DateRange dateRange,
});

/// Compute muscle group volume breakdown
Future<List<MuscleGroupVolume>> getMuscleGroupVolume({
  required String userId,
  required DateRange dateRange,
  required List<LibraryExercise> libraryExercises,
  required List<CustomExercise> customExercises,
});

/// Compute weekly training trends
Future<List<WeeklyTrendPoint>> getWeeklyTrends({
  required String userId,
  required DateRange dateRange,
});

/// Compute configurable weekly streak
Future<ConfigurableStreak> getConfigurableStreak({
  required String userId,
  required int weeklyTarget,
});

/// Get list of exercises the user has logged (for exercise picker)
Future<List<({String exerciseId, String exerciseName, ExerciseType exerciseType})>> getLoggedExercises({
  required String userId,
});
```

**Implementation notes:**
- All methods use existing `_getAllUserSets()` and `_getAllUserExercises()` for data access
- All results cached using existing `_cache` map with 5-min TTL
- `getMuscleGroupVolume()` receives library/custom exercise lists to avoid cross-provider dependency
- `getConfigurableStreak()` groups workouts by ISO week (Mon-Sun) and counts consecutive weeks meeting target

#### 2. ProgramProvider (`lib/providers/program_provider.dart`)

**New fields and methods:**

```dart
// New fields
ExerciseProgressData? _exerciseProgress;
List<MuscleGroupVolume>? _muscleGroupVolume;
List<WeeklyTrendPoint>? _weeklyTrends;
ConfigurableStreak? _configurableStreak;
int _weeklyWorkoutTarget = 3;  // Default

// New getters
ExerciseProgressData? get exerciseProgress;
List<MuscleGroupVolume>? get muscleGroupVolume;
List<WeeklyTrendPoint>? get weeklyTrends;
ConfigurableStreak? get configurableStreak;
int get weeklyWorkoutTarget;

// New methods
Future<void> loadExerciseProgress(String exerciseId, String exerciseName, ExerciseType exerciseType, DateRange dateRange);
Future<void> loadMuscleGroupVolume(DateRange dateRange);
Future<void> loadWeeklyTrends(DateRange dateRange);
Future<void> loadConfigurableStreak();
Future<void> setWeeklyWorkoutTarget(int target);
Future<List<({String exerciseId, String exerciseName, ExerciseType exerciseType})>> getLoggedExercises();
```

#### 3. CreateSetScreen (`lib/screens/sets/create_set_screen.dart`)

**Change:** After successful set creation (line 576), call `checkForPersonalRecord()` and show `PRNotificationBanner` if PR detected.

```dart
// After line 576 (setId != null)
if (setId != null) {
  // Check for PR (fire and forget - don't block navigation)
  _checkForPR(programProvider, setId);
  // ... existing success handling
}
```

#### 4. ChartsSection (`lib/screens/analytics/components/charts_section.dart`)

**Change:** Add "NEW" badge to `PersonalRecordTile` for PRs achieved within last 7 days. The `achievedAt` field already exists on `PersonalRecord`.

#### 5. Firestore Security Rules (`fittrack/firestore.rules`)

**No changes needed.** The `validUserProfile` function already allows `settings` as a nullable map:
```
data.settings == null || data.settings is map
```

The `workoutTarget` integer will be stored as `settings.workoutTarget` in the user document.

---

## Data Flow

### Exercise Progress Chart Flow

```
User taps Exercise tab
  → ProgramProvider.getLoggedExercises()
    → AnalyticsService._getAllUserExercises() (deduplicated by name)
  → User selects exercise from list
  → ProgramProvider.loadExerciseProgress(exerciseId, dateRange)
    → AnalyticsService.getExerciseProgress()
      → _getAllUserSets() filtered by exerciseId
      → Group sets by workout date
      → Compute max weight, volume, 1RM per session
    → ProgramProvider notifies listeners
  → ExerciseProgressScreen renders LineChartPainter
```

### Muscle Group Volume Flow

```
User navigates to Trends tab
  → ProgramProvider.loadMuscleGroupVolume(dateRange)
    → AnalyticsService.getMuscleGroupVolume(
        libraryExercises: from ExerciseLibraryProvider,
        customExercises: from ExerciseLibraryProvider)
      → _getAllUserExercises() + _getAllUserSets()
      → For each exercise: match name to library/custom → get primaryMuscles[0]
      → Count sets per MuscleGroup
    → ProgramProvider notifies listeners
  → TrendsTab renders BarChartPainter
```

### Exercise-to-MuscleGroup Matching Strategy

Since `Exercise` model doesn't store `muscleGroup` or `libraryExerciseId`, matching is done by exercise name:

1. Get all user exercises from the date range
2. For each exercise name, search `ExerciseLibraryProvider`:
   - First check custom exercises by exact name match
   - Then check library exercises by exact name match
3. If match found: use `primaryMuscles[0]` as the muscle group
4. If no match: categorize as "Other"
5. Cache the name-to-muscleGroup mapping for the session

This approach works because exercises are created by selecting from the library/custom list, so names should match.

### PR Notification Flow

```
User saves set on CreateSetScreen
  → _saveSet() calls ProgramProvider.createSet()
  → After success: ProgramProvider.checkForPersonalRecord(set, exercise)
    → AnalyticsService.checkForNewPR() (already implemented)
    → If PR: ProgramProvider adds to _recentPRs, notifies listeners
  → CreateSetScreen shows PRNotificationBanner overlay
  → Banner auto-dismisses after 5 seconds
```

---

## Implementation Tasks

### Task 1: Analytics Data Models & 1RM Utility

**Files to create/modify:**
- Modify: `lib/models/analytics.dart` - Add `ExerciseProgressPoint`, `ExerciseProgressData`, `MuscleGroupVolume`, `WeeklyTrendPoint`, `ConfigurableStreak`
- Create: `lib/utils/one_rm_calculator.dart` - 1RM calculation utility
- Add `DateRange` factory constructors: `last3Months()`, `last6Months()`, `allTime()`

**Dependencies:** None (foundation task)

**Acceptance Criteria:**
- [ ] All 5 new model classes created with proper fields
- [ ] `OneRMCalculator.epley()` and `brzycki()` return correct values
- [ ] 1RM returns null when reps > 10 or weight <= 0
- [ ] `DateRange` has 1M, 3M, 6M, All factory constructors
- [ ] Unit tests for all models and 1RM calculator

**Reference:** Follow model patterns from `analytics.dart:105-204` (PersonalRecord)

---

### Task 2: AnalyticsService Extensions

**Files to modify:**
- `lib/services/analytics_service.dart` - Add 5 new public methods

**Dependencies:** Task 1 (models)

**New methods:**
1. `getExerciseProgress()` - Per-exercise time-series data with 1RM
2. `getMuscleGroupVolume()` - Sets-per-muscle-group using name matching
3. `getWeeklyTrends()` - Weekly volume + frequency aggregation
4. `getConfigurableStreak()` - Weekly streak with configurable target
5. `getLoggedExercises()` - Deduplicated list of exercises user has logged

**Acceptance Criteria:**
- [ ] All 5 methods implemented with caching (5-min TTL)
- [ ] `getExerciseProgress()` correctly aggregates max weight, volume, 1RM per session
- [ ] `getMuscleGroupVolume()` matches exercises by name to library/custom exercises
- [ ] `getWeeklyTrends()` groups by ISO week (Mon-Sun)
- [ ] `getConfigurableStreak()` counts consecutive weeks meeting target
- [ ] `getLoggedExercises()` returns deduplicated names across all programs
- [ ] Unit tests for all methods with mocked FirestoreService

**Reference:** Follow method patterns from `analytics_service.dart:25-60` (computeWorkoutAnalytics)

---

### Task 3: ProgramProvider Extensions

**Files to modify:**
- `lib/providers/program_provider.dart` - Add fields, getters, methods for new analytics

**Dependencies:** Task 2 (service methods)

**New additions:**
- Fields: `_exerciseProgress`, `_muscleGroupVolume`, `_weeklyTrends`, `_configurableStreak`, `_weeklyWorkoutTarget`
- Methods: `loadExerciseProgress()`, `loadMuscleGroupVolume()`, `loadWeeklyTrends()`, `loadConfigurableStreak()`, `setWeeklyWorkoutTarget()`, `getLoggedExercises()`
- `setWeeklyWorkoutTarget()` persists to `users/{userId}` settings map via FirestoreService
- `loadAnalytics()` extended to also load configurable streak

**Acceptance Criteria:**
- [ ] All new fields, getters, and methods added
- [ ] `setWeeklyWorkoutTarget()` persists to Firestore user settings
- [ ] `loadConfigurableStreak()` reads target from user settings (default: 3)
- [ ] `loadAnalytics()` includes streak data in concurrent load
- [ ] Unit tests for new provider methods

**Reference:** Follow provider patterns from `program_provider.dart:1325-1435`

---

### Task 4: CustomPainter Chart Widgets

**Files to create:**
- `lib/widgets/charts/chart_data.dart` - `ChartDataPoint`, `BarChartEntry`
- `lib/widgets/charts/line_chart_painter.dart` - `LineChartPainter` CustomPainter
- `lib/widgets/charts/line_chart_widget.dart` - `LineChartWidget` StatefulWidget wrapper
- `lib/widgets/charts/bar_chart_painter.dart` - `BarChartPainter` CustomPainter
- `lib/widgets/charts/bar_chart_widget.dart` - `BarChartWidget` StatelessWidget wrapper
- `lib/widgets/charts/time_range_selector.dart` - Segmented control for 1M/3M/6M/All

**Dependencies:** Task 1 (ChartDataPoint model)

**LineChartPainter features:**
- X-axis: dates with auto-spaced labels
- Y-axis: metric values with gridlines
- Primary line: solid color with filled data points
- Secondary line: dashed (for 1RM overlay)
- Touch detection: tap data point shows tooltip
- Empty state: centered message
- Responsive: adapts to available width/height
- Accessibility: Semantics labels for data points

**BarChartPainter features:**
- Horizontal bars with muscle group labels
- Value and percentage labels
- Color-coded bars (one per MuscleGroup)
- Responsive height based on entry count

**Acceptance Criteria:**
- [ ] LineChartPainter renders line chart with points, lines, axes, gridlines
- [ ] Supports dual-line mode (primary + secondary with legend)
- [ ] BarChartPainter renders horizontal bar chart with labels
- [ ] TimeRangeSelector switches between 1M/3M/6M/All
- [ ] Charts handle empty data gracefully
- [ ] All chart widgets have Semantics for accessibility
- [ ] Widget tests verify rendering for various data scenarios

**Reference:** Cell sizing pattern from `monthly_calendar_view.dart:137-146` for responsive dimensions

---

### Task 5: Analytics Screen Tab Navigation

**Files to modify:**
- `lib/screens/analytics/analytics_screen.dart` - Convert to TabBarView

**Files to create:**
- `lib/screens/analytics/components/overview_tab.dart` - Existing content extracted
- `lib/screens/analytics/components/exercise_tab.dart` - Exercise progress tab
- `lib/screens/analytics/components/trends_tab.dart` - Trends tab

**Dependencies:** Task 3 (provider data), Task 4 (chart widgets)

**Tab structure:**
- **Overview** tab: Monthly Heatmap + Key Statistics + Exercise Type Breakdown + PR List (existing content, moved)
- **Exercise** tab: Exercise picker → Exercise progress chart with time range
- **Trends** tab: Configurable Streak card + Muscle Group Volume chart + Weekly Training Trends chart

**Acceptance Criteria:**
- [ ] Analytics screen uses `DefaultTabController` with `TabBar` + `TabBarView`
- [ ] Overview tab shows all existing content (no regression)
- [ ] Exercise tab has exercise search/filter and chart area
- [ ] Trends tab has streak, muscle group volume, and weekly trends sections
- [ ] Tab state preserved when switching tabs
- [ ] Pull-to-refresh works across all tabs
- [ ] Widget tests verify tab navigation

**Reference:** Follow existing screen pattern from `analytics_screen.dart:14-155`

---

### Task 6: Exercise Progress Chart Screen

**Files to create:**
- `lib/screens/analytics/components/exercise_progress_section.dart` - Chart display
- `lib/screens/analytics/components/exercise_picker.dart` - Searchable exercise list

**Dependencies:** Task 4 (LineChartWidget), Task 5 (Exercise tab)

**Exercise Picker:**
- Shows only exercises user has actually logged (from `getLoggedExercises()`)
- Searchable by name
- Shows exercise type chip
- Tapping selects and loads chart

**Chart Display:**
- Time range selector (1M, 3M, 6M, All) - default 3M
- LineChartWidget with exercise-type-specific metrics:
  - Strength: Max Weight (primary) + Est. 1RM (secondary dashed line) + legend
  - Bodyweight: Max Reps (primary)
  - Cardio/Time-based: Duration (primary), optionally Distance
  - Custom: Volume or most relevant metric
- Empty state when no data in range
- Loading spinner while computing

**Acceptance Criteria:**
- [ ] Exercise picker shows deduplicated logged exercises with search
- [ ] Selecting exercise loads progress chart for default 3M range
- [ ] Strength exercises show dual-line chart (weight + est. 1RM)
- [ ] Other exercise types show single-line chart with appropriate metric
- [ ] Time range selector updates chart data
- [ ] Empty state shown when no data in selected range
- [ ] Single data point renders without connecting line
- [ ] Widget tests verify chart rendering for each exercise type

**Reference:** Search pattern from `exercise_library_provider.dart:319-345`

---

### Task 7: Muscle Group Volume & Training Trends

**Files to create:**
- `lib/screens/analytics/components/muscle_group_section.dart` - Volume breakdown
- `lib/screens/analytics/components/training_trends_section.dart` - Weekly trends

**Dependencies:** Task 4 (BarChartWidget, LineChartWidget), Task 5 (Trends tab)

**Muscle Group Volume Section:**
- Horizontal bar chart (BarChartWidget) showing sets per muscle group
- 6 groups + "Other" if applicable
- Each bar: muscle group name, set count, percentage
- Color-coded per muscle group
- Time range matches analytics period (current month by default)

**Training Trends Section:**
- Two line charts (stacked vertically):
  1. Weekly total volume (weight × reps)
  2. Weekly workout frequency (count per week)
- Time range selector shared with Exercise tab (1M/3M/6M/All)
- 4-week moving average overlay line
- Tap on point shows tooltip with value and week range

**Acceptance Criteria:**
- [ ] Muscle group volume shows horizontal bar chart with all 6 groups
- [ ] Unmatched exercises grouped as "Other"
- [ ] Weekly volume trend chart renders correctly
- [ ] Weekly frequency trend chart renders correctly
- [ ] Moving average line smooths data
- [ ] Empty states for all charts
- [ ] Widget tests for both sections

**Reference:** Bar chart style from `charts_section.dart:87-216` (ExerciseTypeChart)

---

### Task 8: Configurable Streak & PR Notifications

**Files to create:**
- `lib/screens/analytics/components/streak_section.dart` - Streak display + target setting
- `lib/widgets/pr_notification_banner.dart` - Inline PR notification

**Files to modify:**
- `lib/screens/sets/create_set_screen.dart` - Wire up PR detection after set creation
- `lib/screens/analytics/components/charts_section.dart` - Add "NEW" badge to recent PRs

**Dependencies:** Task 3 (provider streak data), Task 5 (Trends tab)

**Streak Section:**
- Flame icon with current streak count ("12-week streak")
- Longest streak alongside
- Gear icon → bottom sheet with stepper for weekly target (1-7)
- Default: 3 workouts/week
- Streak recalculates when target changes

**PR Notification Banner:**
- Shown inline on workout screen after set saved (not system notification)
- Shows: exercise name, PR type, new value, improvement amount
- Auto-dismisses after 5 seconds
- Tappable to dismiss
- Slide-in animation

**PR "NEW" Badge:**
- In PersonalRecordTile: show "NEW" chip for PRs achieved within last 7 days
- Based on `pr.achievedAt` comparison to `DateTime.now()`

**Acceptance Criteria:**
- [ ] Streak section shows current/longest streak with flame icon
- [ ] Gear icon opens target picker (1-7 stepper)
- [ ] Target persists in Firestore user settings
- [ ] Streak recalculates immediately on target change
- [ ] PR banner appears on CreateSetScreen when new PR detected
- [ ] Banner auto-dismisses after 5 seconds
- [ ] Banner shows exercise name, PR type, value, improvement
- [ ] "NEW" badge on PR tiles for PRs within last 7 days
- [ ] Unit/widget tests for streak calculation and PR banner

**Reference:** PR display patterns from `charts_section.dart:268-420` (PersonalRecordTile)

---

## Testing Strategy

### Unit Tests

| Area | File | Tests |
|------|------|-------|
| 1RM Calculator | `test/utils/one_rm_calculator_test.dart` | Epley/Brzycki formulas, edge cases (reps>10, weight=0) |
| Analytics Models | `test/models/analytics_test.dart` | New model constructors, serialization |
| AnalyticsService | `test/services/analytics_service_test.dart` | All 5 new methods with mocked data |
| ProgramProvider | `test/providers/program_provider_test.dart` | New load methods, streak target persistence |

### Widget Tests

| Area | File | Tests |
|------|------|-------|
| LineChartWidget | `test/widgets/charts/line_chart_widget_test.dart` | Single/dual line, empty state, tap interaction |
| BarChartWidget | `test/widgets/charts/bar_chart_widget_test.dart` | Bar rendering, labels, empty state |
| TimeRangeSelector | `test/widgets/charts/time_range_selector_test.dart` | Selection callbacks |
| Analytics Tabs | `test/screens/analytics/analytics_screen_test.dart` | Tab navigation, data loading |
| Exercise Picker | `test/screens/analytics/exercise_picker_test.dart` | Search, selection |
| Streak Section | `test/screens/analytics/streak_section_test.dart` | Display, target change |
| PR Banner | `test/widgets/pr_notification_banner_test.dart` | Display, auto-dismiss, dismissal |

### Integration Tests

| Area | File | Tests |
|------|------|-------|
| Analytics Service | `test/services/analytics_service_integration_test.dart` | Real Firestore data traversal for new methods |
| Streak Persistence | `test/services/streak_persistence_integration_test.dart` | Firestore user settings read/write |

### Coverage Targets

- Unit tests: 90%+ on new models, utils, service methods
- Widget tests: Key interactions (tab switch, exercise selection, time range change)
- Integration tests: Analytics data computation with real Firestore data

---

## Technical Decisions

### 1. Tab-Based Analytics Screen

**Decision:** Convert Analytics from scrollable sections to 3-tab layout.

**Rationale:** Adding 4 new chart types (exercise progress, muscle group, volume trend, frequency trend) plus streak section to a single scroll would make the screen extremely long. Tabs provide logical grouping:
- Overview: Quick stats (what exists today)
- Exercise: Drill-down per exercise
- Trends: Aggregate patterns over time

### 2. Name-Based Exercise-to-MuscleGroup Matching

**Decision:** Match exercise names to `LibraryExercise`/`CustomExercise` for muscle group lookup.

**Rationale:** The `Exercise` model has no `muscleGroup` or `libraryExerciseId` field. Adding it would require a data migration. Name matching works because exercises are created by selecting from the library, so names match. Cache the mapping per session.

**Risk:** If user manually types an exercise name that doesn't match library, it won't have a muscle group. Mitigated by grouping as "Other".

### 3. CustomPainter for All New Charts

**Decision:** Use `CustomPainter` for line charts and bar charts.

**Rationale:** PRD explicitly requires it. No external charting dependency. Full control over styling and interaction. First CustomPainter in the project sets a reusable pattern for future charts.

### 4. Streak Target in User Settings Map

**Decision:** Store `workoutTarget` in `users/{userId}.settings` map rather than a new field.

**Rationale:** `validUserProfile` Firestore rule already validates `settings` as a nullable map. No rule changes needed. Simple key-value storage for a single preference.

### 5. Fire-and-Forget PR Detection

**Decision:** Check for PR after set creation without blocking the save flow.

**Rationale:** PR detection requires fetching 1 year of historical data. This shouldn't delay the user's set save confirmation. The banner is shown asynchronously after navigation back.

---

## Performance Considerations

- **Exercise progress chart rendering**: Pre-compute all data points before passing to CustomPainter. For 1000+ sessions, downsample to ~100 visible points by averaging nearby dates.
- **Muscle group volume**: O(exercises × library_size) name matching. Cache the name→muscleGroup map for the session.
- **All computed data**: Cached for 5 minutes matching existing pattern. `clearCache()` invalidates all.
- **Tab lazy loading**: Only load Exercise/Trends tab data when user navigates to that tab (not on initial Analytics load).

## Accessibility Considerations

- Charts have `Semantics` labels describing the data ("Bench Press: 80kg on Jan 15, 85kg on Feb 1...")
- Time range selector is keyboard/screen-reader accessible
- Streak section has clear text descriptions
- PR banner announces via `Semantics.liveRegion` for screen readers
- All colors meet WCAG AA contrast ratios (use theme colors)

## Security Considerations

- No new Firestore collections or rules needed
- `workoutTarget` stored in user's own settings (owner-only access enforced by existing rules)
- All data computed client-side from user's own data

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Name-based exercise matching fails for renamed exercises | Muscle group volume inaccurate | Use exerciseId as secondary lookup; group unmatched as "Other" |
| Large data sets (1000+ sessions) slow chart rendering | Poor UX | Downsample data points; lazy loading per tab |
| CustomPainter complexity for first implementation | Slower dev | Provide clear paint() structure; start with simple line then add features |
| PR detection latency after set save | Banner shows late | Show banner on next screen (exercise list) rather than blocking save |
| Weekly streak calculation complexity across year boundaries | Incorrect streaks | Use ISO 8601 week numbering; thorough unit tests |

---

## File Summary

### New Files (14)

| File | Purpose |
|------|---------|
| `lib/utils/one_rm_calculator.dart` | 1RM calculation (Epley, Brzycki) |
| `lib/widgets/charts/chart_data.dart` | Chart data models |
| `lib/widgets/charts/line_chart_painter.dart` | CustomPainter for line charts |
| `lib/widgets/charts/line_chart_widget.dart` | Line chart widget wrapper |
| `lib/widgets/charts/bar_chart_painter.dart` | CustomPainter for bar charts |
| `lib/widgets/charts/bar_chart_widget.dart` | Bar chart widget wrapper |
| `lib/widgets/charts/time_range_selector.dart` | 1M/3M/6M/All segmented control |
| `lib/widgets/pr_notification_banner.dart` | Inline PR notification |
| `lib/screens/analytics/components/overview_tab.dart` | Existing analytics content |
| `lib/screens/analytics/components/exercise_tab.dart` | Exercise progress tab |
| `lib/screens/analytics/components/trends_tab.dart` | Trends tab |
| `lib/screens/analytics/components/exercise_progress_section.dart` | Exercise chart + picker |
| `lib/screens/analytics/components/muscle_group_section.dart` | Muscle group volume |
| `lib/screens/analytics/components/training_trends_section.dart` | Weekly trends |
| `lib/screens/analytics/components/streak_section.dart` | Configurable streak |

### Modified Files (5)

| File | Changes |
|------|---------|
| `lib/models/analytics.dart` | Add 5 new model classes |
| `lib/services/analytics_service.dart` | Add 5 new public methods |
| `lib/providers/program_provider.dart` | Add fields, getters, load methods |
| `lib/screens/analytics/analytics_screen.dart` | Convert to TabBarView |
| `lib/screens/sets/create_set_screen.dart` | Wire PR detection after save |
| `lib/screens/analytics/components/charts_section.dart` | Add "NEW" badge to PR tiles |

### No Changes Needed

| File | Reason |
|------|--------|
| `fittrack/firestore.rules` | `settings is map` already validated |
| `lib/models/exercise.dart` | No schema change needed |
| `lib/models/exercise_set.dart` | No schema change needed |
| `lib/providers/exercise_library_provider.dart` | Already has lookup methods |
