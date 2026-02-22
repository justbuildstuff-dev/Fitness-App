# Technical Design: Analytics Based on Set Completion Date

**GitHub Issue:** [#370](https://github.com/justbuildstuff-dev/Fitness-App/issues/370)
**PRD:** [Docs/PRDs/Analytics_Completion_Date_PRD.md](../PRDs/Analytics_Completion_Date_PRD.md)
**Status:** Design Complete
**Created:** 2026-02-22
**SA Agent:** In Progress

---

## Current Architecture Analysis

### State Management
- Provider pattern (`ProgramProvider extends ChangeNotifier`) — consistent throughout the app
- Analytics data computed in `AnalyticsService` (singleton) and cached in `ProgramProvider`

### Completion Toggle Flow (Discovered via Codebase Analysis)

The primary UI path for toggling set completion is:
```
SetRow._handleCheckboxChange (lib/widgets/set_row.dart:61)
  → set.copyWith(checked: checked, updatedAt: DateTime.now())
  → widget.onUpdate(updatedSet)
    → ConsolidatedWorkoutScreen._updateSet (lib/screens/workouts/consolidated_workout_screen.dart:309)
      → provider.updateSet(updatedSet)
        → ProgramProvider.updateSet (lib/providers/program_provider.dart:1218)
          → set.copyWith(updatedAt: DateTime.now())  // re-stamps updatedAt
          → _firestoreService.updateSet(updatedSet)
```

A secondary (deprecated) path exists in `ExerciseDetailScreen._toggleSetCompletion` (lib/screens/exercises/exercise_detail_screen.dart:484).

### Date Fields in ExerciseSet (Current)
```
createdAt: DateTime   // when set was created in Firestore
updatedAt: DateTime   // last modification (ANY field change)
checked: bool         // completion status
```
No dedicated completion timestamp exists. Analytics throughout `AnalyticsService` use `set.createdAt` for grouping and dating.

### Key Analytics Methods Using `createdAt` (Must Change)
| Method | File | Current Usage | Required Change |
|--------|------|---------------|-----------------|
| `generateSetBasedHeatmapData` | analytics_service.dart:153 | `set.createdAt.year/month/day` | `completionDate.year/month/day` |
| `getMonthHeatmapData` | analytics_service.dart:244 | `set.createdAt.day` | `completionDate.day` |
| `getExerciseProgress` | analytics_service.dart:452 | `workoutSets.first.createdAt` | `completionDate` of first set |
| `getWeeklyTrends` | analytics_service.dart:646 | `set.createdAt` | `completionDate` |
| `_findPRsForExercise` | analytics_service.dart:959 | `set.createdAt` for sort + achievedAt | `completionDate` |
| `_checkForPRInSet` | analytics_service.dart:1108 | `newSet.createdAt` achievedAt | `completionDate` |
| `_detectPersonalRecords` | analytics_service.dart:959 | sort by `createdAt` | sort by `completionDate` |
| `WorkoutAnalytics.fromWorkoutData` | analytics.dart:57 | all sets regardless of checked | completed sets only |

### Test Files Affected
- `test/models/enhanced_exercise_set_test.dart`
- `test/widgets/set_row_test.dart`
- `test/test_utilities/test_data_factory.dart`
- `test/services/analytics_service_integration_test.dart` (stub — no changes needed)
- `test/models/analytics_test.dart`
- `test/providers/program_provider_analytics_test.dart`

---

## Architecture Overview

This feature adds a single nullable field (`completedAt: DateTime?`) to `ExerciseSet` and propagates its use through the data, service, and widget layers. No new architecture is introduced — the change follows the existing `ExerciseSet` model conventions exactly.

**Strategy:**
1. **Model Layer**: Add `completedAt` field; update `copyWith`, converter, Firestore rules
2. **Widget Layer**: Set/clear `completedAt` at the checkbox toggle site (`SetRow`)
3. **Service Layer**: Add a private `_completionDate(ExerciseSet)` helper and use it consistently throughout `AnalyticsService`

**Fallback for historical data**: `completedAt ?? updatedAt`
- No Firestore migration required
- Backward compatible — null field simply uses `updatedAt` as best approximation

**`_getAllUserSets` inner filter change**: The existing inner set-level date filter (`sets.where((s) => dateRange.contains(s.createdAt))`) is removed. The outer workout-level `createdAt` filter already scopes the query to the correct time window. Removing the inner filter allows sets added to a workout after its creation to be included correctly.

---

## Component Design

### Modified: `ExerciseSet` (lib/models/exercise_set.dart)

Add `completedAt: DateTime?` field. Update `copyWith` to support explicit null-clearing via a `clearCompletedAt` flag (needed to uncheck a set). Update `createDuplicateCopy` to reset `completedAt` to null.

```dart
// New field
final DateTime? completedAt;

// Updated constructor
ExerciseSet({
  ...existing fields...
  this.completedAt,  // nullable, default null
});

// Updated copyWith
ExerciseSet copyWith({
  ...existing params...
  DateTime? completedAt,
  bool clearCompletedAt = false,  // explicit null-clear flag
}) {
  return ExerciseSet(
    ...existing...
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
  );
}

// Updated createDuplicateCopy
return ExerciseSet(
  ...existing...
  checked: false,
  completedAt: null,  // reset alongside checked
);
```

**Follows pattern from:** existing `copyWith` in `lib/models/exercise_set.dart:61`

### Modified: `ExerciseSetConverter` (lib/converters/exercise_set_converter.dart)

```dart
// toFirestore: add completedAt (nullable Timestamp)
'completedAt': set.completedAt != null
    ? Timestamp.fromDate(set.completedAt!)
    : null,

// fromFirestore: read completedAt (nullable)
completedAt: data['completedAt'] != null
    ? (data['completedAt'] as Timestamp).toDate()
    : null,
```

**Follows pattern from:** `createdAt` / `updatedAt` handling in `lib/converters/exercise_set_converter.dart:17`

### Modified: `firestore.rules` (fittrack/firestore.rules)

Add to `validSet` function:
```javascript
&& (data.completedAt == null || isTimestamp(data.completedAt))
```

**Follows pattern from:** `data.checked == null || isBoolean(data.checked)` at line 300

### Modified: `SetRow` (lib/widgets/set_row.dart)

Update `_handleCheckboxChange` to set/clear `completedAt`:

```dart
void _handleCheckboxChange(bool? checked) {
  if (checked == null) return;

  final now = DateTime.now();
  final updatedSet = widget.set.copyWith(
    checked: checked,
    updatedAt: now,
    completedAt: checked ? now : null,
    clearCompletedAt: !checked,  // explicitly null completedAt when unchecking
  );

  widget.onUpdate(updatedSet);
}
```

**Also update:** `ExerciseDetailScreen._toggleSetCompletion` (deprecated screen, same pattern)

### Modified: `AnalyticsService` (lib/services/analytics_service.dart)

**Add private helper** (add near top of class body):
```dart
/// Returns the effective completion date for a checked set.
/// Falls back to updatedAt for sets without an explicit completedAt (historical data).
DateTime _completionDate(ExerciseSet set) => set.completedAt ?? set.updatedAt;
```

**Update `_getAllUserSets`**: Remove the inner set-level `createdAt` filter:
```dart
// BEFORE:
final filteredSets = sets.where((s) => dateRange.contains(s.createdAt));
allSets.addAll(filteredSets);

// AFTER:
allSets.addAll(sets);  // Outer workout filter is sufficient
```

**Update `generateSetBasedHeatmapData`** (line 153):
```dart
// BEFORE:
final date = DateTime(set.createdAt.year, set.createdAt.month, set.createdAt.day);

// AFTER:
final completionDate = _completionDate(set);
final date = DateTime(completionDate.year, completionDate.month, completionDate.day);
```

**Update `getMonthHeatmapData`** (line 244):
```dart
// BEFORE:
final day = set.createdAt.day;

// AFTER:
final day = _completionDate(set).day;
```

**Update `getExerciseProgress`** (line 452):
```dart
// BEFORE:
workoutSets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
final sessionDate = workoutSets.first.createdAt;

// AFTER:
workoutSets.sort((a, b) => _completionDate(a).compareTo(_completionDate(b)));
final sessionDate = _completionDate(workoutSets.first);
```

**Update `getWeeklyTrends`** (line 646):
```dart
// BEFORE (sets):
final weekStart = getWeekStart(set.createdAt);

// AFTER (only include completed sets):
for (final set in allSets.where((s) => s.checked)) {
  final weekStart = getWeekStart(_completionDate(set));
  ...
}
```

**Update `_detectPersonalRecords`** (line 959):
```dart
// BEFORE:
exerciseSets.sort((a, b) => a.createdAt.compareTo(b.createdAt));

// AFTER:
exerciseSets.sort((a, b) => _completionDate(a).compareTo(_completionDate(b)));
```

**Update `_findPRsForExercise`** (achievedAt fields):
```dart
// BEFORE:
achievedAt: set.createdAt,

// AFTER:
achievedAt: _completionDate(set),
```
(Multiple occurrences — all PR type checks within the method)

**Update `_checkForPRInSet`** (achievedAt fields):
```dart
// BEFORE:
achievedAt: newSet.createdAt,

// AFTER:
achievedAt: _completionDate(newSet),
```
(Multiple occurrences within switch cases)

**Update `computeWorkoutAnalytics` / `WorkoutAnalytics.fromWorkoutData`**: Filter to only count completed sets. The `_getAllUserSets` call already fetches all sets; the `fromWorkoutData` factory should only tally checked sets for volume/totalSets. Update the factory to filter by `checked == true`:
```dart
// In WorkoutAnalytics.fromWorkoutData (analytics.dart ~line 57):
for (final set in sets.where((s) => s.checked)) {  // Add checked filter
  totalSetsCount++;
  if (set.weight != null && set.reps != null) {
    volume += set.weight! * set.reps!;
  }
  ...
}
```

---

## Implementation Tasks

| # | Task | Files | Effort |
|---|------|-------|--------|
| 1 | [#371](https://github.com/justbuildstuff-dev/Fitness-App/issues/371) ExerciseSet model + converter + Firestore rules | `exercise_set.dart`, `exercise_set_converter.dart`, `firestore.rules` | 1 day |
| 2 | [#372](https://github.com/justbuildstuff-dev/Fitness-App/issues/372) SetRow checkbox toggle + deprecated screen | `set_row.dart`, `exercise_detail_screen.dart` | 0.5 day |
| 3 | [#373](https://github.com/justbuildstuff-dev/Fitness-App/issues/373) Analytics Service: heatmap methods | `analytics_service.dart` | 0.5 day |
| 4 | [#374](https://github.com/justbuildstuff-dev/Fitness-App/issues/374) Analytics Service: exercise progress + weekly trends | `analytics_service.dart` | 0.5 day |
| 5 | [#375](https://github.com/justbuildstuff-dev/Fitness-App/issues/375) Analytics Service: PRs + WorkoutAnalytics total volume | `analytics_service.dart`, `analytics.dart` | 0.5 day |

**Total Estimated Effort: ~3 days**

---

## Testing Strategy

All tests follow existing patterns in `test/` directory.

### Task 1 Tests (Unit — `test/models/`)
- `enhanced_exercise_set_test.dart`: Add tests for `completedAt` field default null, `copyWith` preserves/sets/clears `completedAt`, `createDuplicateCopy` resets to null, `toMap` includes field
- `test_data_factory.dart`: Update `createSet` factory method to include `completedAt` parameter

### Task 2 Tests (Widget — `test/widgets/`)
- `set_row_test.dart`: Add tests that checking a set sets `completedAt`, unchecking clears it, `completedAt != null` when `checked = true`

### Tasks 3-5 Tests (Unit — `test/providers/`, `test/models/`)
- `program_provider_analytics_test.dart` or `test/models/analytics_test.dart`: Update/add tests for:
  - Heatmap groups by `completedAt`, not `createdAt`
  - Historical sets (no `completedAt`) fall back to `updatedAt`
  - Exercise progress session date uses completion date
  - Weekly trends only count completed sets by completion date
  - PR `achievedAt` uses completion date
  - `WorkoutAnalytics.fromWorkoutData` only counts checked sets

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Historical sets showing wrong dates (updatedAt mismatch) | Low | Low | Documented fallback; `updatedAt` is set at check time historically |
| Firestore rules rejection of new field | Low | High | Add `completedAt` to `validSet` before deploying (Task 1) |
| Analytics showing zero data after change | Low | Medium | Extensive unit tests before merge; fallback ensures data continuity |
| ProgramProvider.updateSet re-stampings `updatedAt` invalidating `completedAt` | None | High | `completedAt` is set before `updateSet` is called; `copyWith(updatedAt:)` does not clear `completedAt` |

---

## Deployment Notes

- Deploy updated Firestore rules before or alongside app update: `firebase deploy --only firestore:rules`
- No data migration required
- `completedAt` being null on existing documents is handled by the `?? updatedAt` fallback
- Feature is backward compatible with existing Firestore data

---

## Implementation Notes

*(Developer Agent: add notes here as you implement)*
