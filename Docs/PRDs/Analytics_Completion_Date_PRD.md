# PRD: Analytics Based on Set Completion Date

**GitHub Issue:** [#370](https://github.com/justbuildstuff-dev/Fitness-App/issues/370)
**Priority:** Medium
**Platform:** Both (iOS & Android)
**Status:** Requirements Gathering
**Created:** 2026-02-22
**Feature Type:** Enhancement

---

## Overview

Update all analytics calculations to use the date a set was **completed** (checked off) rather than the date it was created. This requires adding a `completedAt` timestamp to `ExerciseSet`, populated when `checked` transitions to `true`, and updating the analytics service to use this field for grouping, filtering, and dating all analytics output.

## User Problem

Users typically plan their workouts in advance — creating workout structures and sets ahead of time. Currently, analytics (heatmap activity, volume totals, exercise progress charts, personal records) are grouped by the date a set was **created**, not when it was **completed**. This means:

1. A workout planned on Monday but performed on Wednesday shows up in Monday's heatmap and stats
2. The activity heatmap does not accurately reflect actual training days
3. Volume and progress charts misrepresent when improvements were actually achieved
4. Personal record dates are incorrect — they show when the set was entered, not when it was lifted

---

## Existing Implementation

The `ExerciseSet` model currently has:
- `createdAt: DateTime` — when the set document was created in Firestore
- `updatedAt: DateTime` — last modification timestamp (updated on every field change)
- `checked: bool` — completion status (default: `false`)

There is **no dedicated completion timestamp**. The analytics service (`lib/services/analytics_service.dart`) uses `set.createdAt` throughout for:
- Heatmap day grouping (`generateSetBasedHeatmapData`, `getMonthHeatmapData`)
- Exercise progress session dates (`getExerciseProgress`)
- Weekly trend volume grouping (`getWeeklyTrends`)
- Personal record achievement dates (`_findPRsForExercise`, `_checkForPRInSet`)
- Date-range filtering of sets (`_getAllUserSets`)

The `_toggleSetCompletion` method in `exercise_detail_screen.dart` already sets `updatedAt: DateTime.now()` when toggling `checked`, making `updatedAt` a reasonable proxy for existing data.

---

## User Stories

### US-1: Heatmap Reflects Actual Workout Days

As a user viewing my activity heatmap,
I want each day's activity count to reflect the sets I actually completed on that day,
so that the heatmap accurately shows my training schedule.

**Acceptance Criteria:**
- [ ] Monthly heatmap calendar groups checked sets by `completedAt` date (not `createdAt`)
- [ ] A set checked on Wednesday appears in Wednesday's count, regardless of when the workout was created
- [ ] Current streak and longest streak calculations use completion date
- [ ] Sets that are unchecked are not shown in heatmap counts
- [ ] Historical sets without `completedAt` fall back to `updatedAt` for display
- [ ] Works on both iOS and Android

### US-2: Volume and Key Statistics Reflect Completion Date

As a user reviewing my training stats for a date range,
I want volume totals and set counts to be based on when I completed those sets,
so that "This Month" stats actually represent work done this month.

**Acceptance Criteria:**
- [ ] Total volume for a date range counts only sets with a `completedAt` (or `updatedAt` fallback) within that range
- [ ] Date-range filtering in analytics queries uses completion date, not creation date
- [ ] Weekly trend volume is grouped by the week the set was completed
- [ ] Key statistics (total sets, total volume, workouts per week) reflect completion dates
- [ ] Completion percentage calculation is unaffected (it's already set-level, not date-dependent)
- [ ] Works on both iOS and Android

### US-3: Exercise Progress Charts Plot on Completion Date

As a user viewing my exercise progress chart,
I want each data point to be plotted on the date I completed that session,
so that the X-axis accurately represents my training timeline.

**Acceptance Criteria:**
- [ ] Each data point on the exercise progress chart uses `completedAt` (or `updatedAt` fallback) as the session date
- [ ] Sets within a workout session are grouped by their completion date, not creation date
- [ ] If sets in a session are completed across midnight, they group to the date of the first completed set in that session
- [ ] Chart date range filtering uses completion date for inclusion
- [ ] Works on both iOS and Android

### US-4: Personal Records Show Accurate Achievement Date

As a user reviewing my personal records,
I want each PR to display the date I actually achieved it,
so that I know the real date of my best performance.

**Acceptance Criteria:**
- [ ] `PersonalRecord.achievedAt` is populated from `set.completedAt` (or `updatedAt` fallback)
- [ ] PR detection sorts sets by completion date when scanning for progression
- [ ] "New PRs this period" count uses completion date to determine if a PR falls within the selected range
- [ ] Works on both iOS and Android

### US-5: Completion Timestamp Captured at Check-Off

As a user marking a set as complete,
I want the app to record the exact time I checked it off,
so that my analytics accurately reflect when I trained.

**Acceptance Criteria:**
- [ ] `ExerciseSet` gains a `completedAt: DateTime?` field (nullable, null by default)
- [ ] `completedAt` is set to `DateTime.now()` when `checked` transitions from `false` to `true`
- [ ] `completedAt` is cleared (set to `null`) when a set is unchecked
- [ ] `completedAt` is stored as a Firestore `Timestamp` field
- [ ] `completedAt` is included in `ExerciseSet.copyWith()`, `toMap()`, and the Firestore converter
- [ ] Duplicated sets have `completedAt` reset to `null` (alongside `checked: false`)
- [ ] Firestore security rules updated to allow the `completedAt` field
- [ ] Works on both iOS and Android

### US-6: Historical Data Remains Visible

As a user with existing workout history,
I want my past analytics to remain visible after this update,
so that I don't lose my historical progress data.

**Acceptance Criteria:**
- [ ] Sets without a `completedAt` field (created before this feature) use `updatedAt` as the fallback completion date
- [ ] Fallback logic is: `completedAt ?? updatedAt` for all checked sets
- [ ] Historical heatmap, volume, and progress data continues to render correctly
- [ ] No migration or backfill of existing Firestore data is required
- [ ] Works on both iOS and Android

---

## Non-Functional Requirements

- **Performance**: No additional Firestore reads required — `completedAt` is a field on the already-fetched set document
- **Backward Compatibility**: The `completedAt` field is nullable; all existing documents without it gracefully fall back to `updatedAt`
- **Cache**: Existing 5-minute analytics cache is unaffected; cache keys do not need to change
- **Firestore Rules**: `completedAt` must be added as an allowed field in `firestore.rules` validation

---

## Out of Scope

- Migrating or backfilling `completedAt` on existing Firestore documents
- Showing `completedAt` time (not date) in the UI
- Any changes to how sets are created or deleted
- Changes to the `workout.createdAt` date used for workout-level analytics (workouts do not have a completion concept)

---

## Success Metrics

- Heatmap shows correct training days for workouts planned in advance
- Volume and PR dates match the actual day training occurred
- No regressions in analytics loading, caching, or display
- All existing and new analytics tests pass

---

## Dependencies

- `ExerciseSet` model (`lib/models/exercise_set.dart`)
- `ExerciseSetConverter` (`lib/converters/exercise_set_converter.dart`)
- `AnalyticsService` (`lib/services/analytics_service.dart`)
- `exercise_detail_screen.dart` — `_toggleSetCompletion` method
- `firestore.rules` — field validation
- Any other screen that calls `set.copyWith(checked: ...)`

---

## Priority

**Medium** — Analytics correctness improvement. Does not block core workout tracking functionality.
