# PRD: Superset & Circuit Training Support

**Status:** Ready for Design
**Priority:** Medium
**Platform:** Both (iOS + Android)
**Feature Type:** New Feature
**GitHub Issue:** #261
**Created:** 2026-03-16

---

## 1. Problem Statement

Workout exercises are currently displayed as a flat, ordered list. Users following structured training programs (PPL, bodybuilding splits, hypertrophy programs) frequently use supersets — where two or more exercises are performed back-to-back before resting. There is no way to represent or track this grouping in the app today.

This creates two problems:
1. **During program building:** Users can't express the intended structure of their program. A superset between Bench Press and DB Row looks the same as two unrelated exercises.
2. **During workout tracking:** Users have no visual grouping to guide them through the intended back-to-back sequence.

The goal is to allow exercises to be grouped into labeled superset groups (A1, A2, etc.) when building or editing workouts, and to display those groups visually during tracking.

---

## 2. Users

**Primary:** Intermediate and advanced lifters following structured programs who use supersets, tri-sets, or giant sets as part of their training methodology.

**Secondary:** Any user who wants to organise exercises into logical groups within a workout.

---

## 3. Existing Implementation Notes

Relevant to the SA when designing:

- **Exercise ordering:** Every `Exercise` document has an `orderIndex: int` (0-based) field. Display order is driven by this field. Reordering recalculates all `orderIndex` values.
- **Workout detail UI:** `ConsolidatedWorkoutScreen` renders exercises in a `ReorderableListView` using `ExerciseCard` widgets. This is the only active screen (WorkoutDetailScreen is deprecated).
- **Add exercise flow:** FAB → `_addExercise()` → navigate to `ExercisePickerScreen` → returns `Map<String, dynamic>` → `provider.createExercise()`.
- **Exercise model:** Currently has no group/superset concept. A new field (e.g. `supersetGroupId`) will need to be added.
- **ExerciseCard widget:** Renders a single exercise with its sets. Will need a new "group card" wrapper component for grouped exercises.

---

## 4. User Stories

### Story 1: Add a Superset to a Workout

**As an** intermediate/advanced lifter building a workout,
**I want to** add a group of exercises as a superset,
**so that** I can represent the intended back-to-back structure of my program.

**Acceptance Criteria:**
1. The "Add Exercise" button (FAB) presents a menu with two options: "Add Exercise" and "Add Superset."
2. Tapping "Add Superset" opens the exercise picker in multi-select mode.
3. The user can select 2 or more exercises from the picker and confirm.
4. Confirmed exercises are added to the workout as a labeled superset group (A1, A2, A3… for the exercises within the group).
5. The group is displayed as a single visual card containing all grouped exercises in order.
6. If only 1 exercise is selected and the user confirms, it is added as a regular standalone exercise (or an error/prompt is shown to select at least 2).

---

### Story 2: View a Superset Group in Workout Detail

**As a** user viewing a workout,
**I want to** see superset exercises grouped together in a visual card with A1/A2 labels,
**so that** I can clearly identify which exercises belong together.

**Acceptance Criteria:**
1. Grouped exercises are wrapped in a distinct "group card" UI component, visually separated from standalone exercises.
2. Each exercise within the group is labelled with its position: A1, A2, A3, etc.
3. Group labels auto-assign alphabetically (A, B, C…) based on group order within the workout; exercises within each group are numbered (1, 2, 3…).
4. Each exercise within the group card still displays its own sets inline, consistent with the existing ExerciseCard behaviour.
5. Standalone exercises outside groups display exactly as they do today.

---

### Story 3: Reorder Exercises Within a Superset Group

**As a** user editing a workout with a superset,
**I want to** reorder exercises within a group,
**so that** I can control which is A1 and which is A2.

**Acceptance Criteria:**
1. Exercises within a group can be dragged and reordered via drag handles, just like standalone exercises.
2. After reordering, the A1/A2/A3 labels update to reflect the new order.
3. Reordering within a group does not affect exercises outside the group.

---

### Story 4: Reorder Groups and Standalone Exercises

**As a** user editing a workout,
**I want to** reorder superset groups and standalone exercises relative to each other,
**so that** I can control the overall workout structure.

**Acceptance Criteria:**
1. Superset group cards can be dragged and reordered relative to other group cards and standalone exercises.
2. When a group is moved, all exercises within it move together as a unit.
3. Group labels (A, B, C…) update to reflect the new order after reordering.
4. Existing reorder functionality for standalone exercises is not broken.

---

### Story 5: Delete a Superset Group

**As a** user who wants to change their workout structure,
**I want to** delete a superset group,
**so that** I can remove it and re-add exercises in a different configuration.

**Acceptance Criteria:**
1. A superset group card has a delete option (e.g. via a 3-dot menu on the group card).
2. Tapping delete shows a confirmation prompt before proceeding.
3. Confirming deletes all exercises and their sets within the group from Firestore.
4. After deletion, remaining groups and standalone exercises retain correct ordering and labels.

---

### Story 6: Track a Workout Containing Supersets

**As a** user doing a workout that contains superset groups,
**I want to** log my sets within each exercise of the group,
**so that** I can track my performance without any change to how I log sets.

**Acceptance Criteria:**
1. During an active workout session, superset groups are displayed with the same group card visual as during program building.
2. Sets within each grouped exercise are logged the same way as standalone exercises (check off, enter reps/weight, etc.).
3. No new workflow is introduced for logging sets within a superset — users log exercise by exercise as they do today.
4. All existing set functionality (add set, delete set, check off, edit values) works the same within grouped exercises.

---

## 5. Out of Scope (v1)

- Rest timers (no changes to existing rest timer behaviour)
- Editing a group in-place (add/remove exercises from an existing group) — users delete and re-add
- Retroactively grouping exercises in existing workouts — groups only apply to newly added exercises
- Alternating set logging UI (log A1 set → A2 set → rest → repeat)
- Circuits with timed transitions
- Wearable or notification integration

---

## 6. Non-Functional Requirements

- **Performance:** Adding a superset (2–5 exercises) should complete within the same response time as adding a single exercise.
- **Offline support:** Group structure should be consistent with existing offline behaviour (no additional offline requirements beyond what exists today).
- **Data integrity:** Deleting a group must cascade delete all exercises and sets within it.
- **Backwards compatibility:** Existing workouts with no groups must display and function identically to today.

---

## 7. Dependencies

- Relies on `ConsolidatedWorkoutScreen` as the active workout UI (WorkoutDetailScreen is deprecated and will not be updated).
- Requires data model change to `Exercise` (new group field).
- Requires new Firestore collection or field for group metadata (SA to decide).
- `ExercisePickerScreen` needs multi-select mode.
- Week duplication logic (`DuplicateService` or equivalent) must preserve group structure when duplicating weeks.

---

## 8. Success Metrics

- Users can create a superset group in ≤3 taps from the workout detail screen.
- Group labels display correctly (A1/A2/B1/B2) after creation and after reordering.
- No regression in existing workout creation or set logging flows.
- All CI tests pass (unit, widget, integration).
