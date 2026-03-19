# Technical Design: Superset & Circuit Training Support

**Status:** Approved
**Feature Issue:** #261
**PRD:** `Docs/PRDs/Superset_Training_PRD.md`
**Created:** 2026-03-16
**Architect:** SA Agent

---

## 1. Current Architecture Analysis

### State Management
- **Provider** pattern throughout (`provider: ^6.1.1`)
- `ProgramProvider` is the central state object for all workout/exercise/set operations
- Screens consume `ProgramProvider` via `Consumer<ProgramProvider>` or `Provider.of<ProgramProvider>(context, listen: false)` for mutations

### File Structure (relevant)
```
lib/
  models/          — Pure Dart data models (Exercise, ExerciseSet, Workout…)
  converters/      — Firestore serialization (ExerciseConverter, ExerciseSetConverter…)
  services/        — FirestoreService (singleton + DI constructor for tests)
  providers/       — ProgramProvider (business logic + state)
  screens/         — Screens (workouts/, exercises/)
  widgets/         — Shared widgets (exercise_card.dart, set_row.dart…)
```

### Similar Features Examined
- **Week duplication** (`FirestoreService.duplicateWeek`) — pattern for batched multi-document writes (≤450 ops/batch)
- **ExerciseCard** (`lib/widgets/exercise_card.dart`) — pattern for exercise display widget with drag handle, collapsible sets, 3-dot menu
- **ReorderableListView** in `ConsolidatedWorkoutScreen` — pattern for drag-drop reordering with `orderIndex` recalculation
- **ExercisePickerScreen** — currently single-select with `_ExerciseDetailsSheet` bottom sheet returning `Map<String, dynamic>`

### Testing Patterns
- Unit tests: `test/models/`, `test/providers/`, `test/services/` — use Mockito `@GenerateMocks`, `fake_cloud_firestore`
- Widget tests: `test/screens/`, `test/widgets/` — `WidgetTester`, `MockProgramProvider`
- Integration tests: `test/services/*_integration_test.dart` — connect to Firebase emulators; follow `INTEGRATION_TEST_TEMPLATE.dart`
- **REQUIRED:** New `FirestoreService` method = new integration test file

---

## 2. Architecture Overview

### Strategy
Add superset grouping **as a field on the existing `Exercise` model** rather than a separate collection. Exercises that share a `supersetGroupId` (a UUID string) are members of the same group. `null` means standalone. This is the minimal, backwards-compatible approach that follows the existing `orderIndex` pattern.

Group labels (A, B, C…) and position labels (1, 2, 3…) are **computed at render time** from the sorted exercise list — never stored. This avoids stale labels on reorder.

The `ConsolidatedWorkoutScreen` list is refactored to operate on `WorkoutItem`s (a sealed class wrapping either a standalone exercise or a superset group) rather than raw exercises. This enables the `ReorderableListView` to treat groups as single draggable units.

### Why This Approach
- Follows the `orderIndex` field pattern already on `Exercise` — minimal model change
- No new Firestore collection — no new security rules structure needed
- Backwards compatible: all existing exercises have `supersetGroupId == null` and render identically today
- Label computation at render time is consistent with how `setNumber` display indices work in `SetRow`

### Alternatives Rejected
- **Separate `supersets` collection**: Adds query complexity, extra reads, new security rule structure — over-engineered for v1
- **Nested exercises collection in group**: Breaks the existing flat `exercises` subcollection pattern and complicates all existing queries

---

## 3. Data Model Changes

### 3.1 `Exercise` Model (`lib/models/exercise.dart`)

Add two nullable fields:

```dart
final String? supersetGroupId;  // UUID shared by all exercises in a group; null = standalone
final int? groupOrderIndex;     // Position within the group (0-based); null for standalone
```

**`copyWith` addition:**
```dart
String? supersetGroupId,
int? groupOrderIndex,
bool clearSupersetGroup = false,  // explicitly null out the group
```

**`==` and `hashCode`** must include both new fields.

**`toMap`** adds:
```dart
'supersetGroupId': supersetGroupId,
'groupOrderIndex': groupOrderIndex,
```

### 3.2 `ExerciseConverter` (`lib/converters/exercise_converter.dart`)

**`toFirestore`:** Include `supersetGroupId` and `groupOrderIndex` (both nullable, written as null if absent).

**`fromFirestore`:** Read both fields with null fallback:
```dart
supersetGroupId: data['supersetGroupId'] as String?,
groupOrderIndex: data['groupOrderIndex'] as int?,
```

### 3.3 `TemplateExercise` (`lib/models/templates/templates.dart`)

Add `String? supersetGroupId` so group membership is preserved when saving/applying workout templates.

### 3.4 Firestore Security Rules (`fittrack/firestore.rules`)

Add `supersetGroupId` and `groupOrderIndex` to the allowed optional fields in the exercise validation function.

---

## 4. New Utility: `WorkoutItem` and Label Computation

**New file:** `lib/utils/workout_item.dart`

```dart
// Sealed class — a workout item is either a standalone exercise or a superset group
sealed class WorkoutItem {}

class StandaloneExercise extends WorkoutItem {
  final Exercise exercise;
  StandaloneExercise(this.exercise);
}

class SupersetGroup extends WorkoutItem {
  final String groupId;
  final List<Exercise> exercises; // sorted by groupOrderIndex
  SupersetGroup({required this.groupId, required this.exercises});
}
```

**`groupExercises(List<Exercise> exercises) → List<WorkoutItem>`**
- Sort input by `orderIndex`
- Walk sorted list: group consecutive exercises sharing the same `supersetGroupId` into `SupersetGroup`s; standalone exercises become `StandaloneExercise`s
- Non-consecutive exercises with the same `supersetGroupId` are treated as the same group (sorted by `groupOrderIndex`)

**`computeGroupLabel(int groupIndex) → String`**
- `groupIndex` is the position of the group in the `WorkoutItem` list (0-based)
- Returns A, B, C … Z, AA, AB … (using standard base-26 encoding)
- Only called for `SupersetGroup` items

**Unit tests:** `test/utils/workout_item_test.dart`

---

## 5. New Widget: `SupersetGroupCard`

**New file:** `lib/widgets/superset_group_card.dart`

Wraps multiple `ExerciseCard`s inside a visually distinct container (outlined `Card` with a coloured header strip).

```dart
class SupersetGroupCard extends StatefulWidget {
  final String groupLabel;            // 'A', 'B', 'C'…
  final List<Exercise> exercises;
  final Map<String, List<ExerciseSet>> setsMap; // exerciseId → sets
  final int outerIndex;               // for outer ReorderableDragStartListener
  final bool isReorderEnabled;
  final VoidCallback onDeleteGroup;
  final Function(int oldIndex, int newIndex) onReorderWithinGroup;
  final VoidCallback Function(Exercise) onAddSet;
  final VoidCallback Function(Exercise) onEditName;
  final Function(ExerciseSet) onUpdateSet;
  final Function(String exerciseId, String setId) onDeleteSet;
}
```

**Layout:**
- Outer `Card` with a `Container` header showing:
  - Drag handle (`ReorderableDragStartListener` using `outerIndex`)
  - Coloured badge: "Superset · A"
  - 3-dot `PopupMenuButton` with "Delete Superset" option
- Below header: inner `ReorderableListView` (shrinkWrap + NeverScrollableScrollPhysics) with `ExerciseCard` items, each prefixed by their position label (A1, A2…)
- `ExerciseCard` receives `isReorderEnabled: true` with its `index` within the inner list

**Inner reorder callback:**
- `onReorderWithinGroup(oldIndex, newIndex)` — called by inner `ReorderableListView.onReorder`
- Parent (`ConsolidatedWorkoutScreen`) handles `groupOrderIndex` updates for exercises in the group

---

## 6. `ExercisePickerScreen` Multi-Select Mode

**File:** `lib/screens/exercises/exercise_picker_screen.dart`

Add constructor parameter:
```dart
final bool isMultiSelect;       // default false
final int initialSetCount;      // default 1 (used in multi-select to set sets for all exercises)
```

**When `isMultiSelect: true`:**
- `_ExerciseListTile` shows a checkbox (using `_selectedIds: Set<String>` state)
- Tapping an exercise tile toggles selection instead of opening the detail bottom sheet
- A bottom bar replaces the FAB: "Add [N] exercises (3 sets each)" with a set count stepper (1–10)
- "Add" button pops with `List<Map<String, dynamic>>` — one entry per selected exercise
- AppBar title changes to "Select Exercises"
- Minimum of 2 exercises must be selected before the Add button is enabled (shows disabled state with tooltip "Select at least 2 exercises")

**Return shape (multi-select):**
```dart
// Navigator.pop(context, result) where result is:
List<Map<String, dynamic>> [
  {'name': String, 'exerciseType': ExerciseType, 'isLibrary': bool, 'sourceId': String, 'setCount': int},
  ...
]
```

Single-select mode is unchanged.

---

## 7. FAB Menu in `ConsolidatedWorkoutScreen`

Replace the current FAB `onPressed: () => _addExercise(context)` with a modal bottom sheet menu:

```dart
FloatingActionButton(
  onPressed: () => _showAddMenu(context),
  child: const Icon(Icons.add),
)

void _showAddMenu(BuildContext context) {
  showModalBottomSheet(context: context, builder: (_) => _AddExerciseMenu(
    onAddExercise: () { Navigator.pop(context); _addExercise(context); },
    onAddSuperset: () { Navigator.pop(context); _addSuperset(context); },
  ));
}
```

**`_addSuperset(context)`:**
1. Navigate to `ExercisePickerScreen(isMultiSelect: true)`
2. Returns `List<Map<String, dynamic>>` (≥2 exercises)
3. If only 1 selected: show snackbar "Select at least 2 exercises to create a superset" and return
4. Generate `supersetGroupId` using `const Uuid().v4()`
5. Call `provider.createSuperset(...)` with the list of exercise specs

---

## 8. Provider & Service Changes

### 8.1 `ProgramProvider` — new method

```dart
Future<String?> createSuperset({
  required String programId,
  required String weekId,
  required String workoutId,
  required List<({String name, ExerciseType exerciseType, int setCount})> exercises,
  required String supersetGroupId,
}) async { ... }
```

- Calculates `startingOrderIndex` (max existing + 1)
- Calls `FirestoreService.instance.createSupersetWithExercises(...)`
- Calls `loadExercises` and `loadAllSetsForWorkout` to refresh

```dart
Future<bool> deleteSuperset({
  required String programId,
  required String weekId,
  required String workoutId,
  required String supersetGroupId,
}) async { ... }
```

- Finds all exercises in provider state with matching `supersetGroupId`
- Calls `FirestoreService.instance.deleteSupersetGroup(...)`

### 8.2 `FirestoreService` — new methods

```dart
/// Create N exercises (as a superset) with their sets in a single batch
Future<List<String>> createSupersetWithExercises({
  required String userId,
  required String programId,
  required String weekId,
  required String workoutId,
  required String supersetGroupId,
  required List<({String name, ExerciseType exerciseType, int setCount})> exercises,
  required int startingOrderIndex,
}) async { ... }
```

Pattern: follows `createExerciseWithSets` but loops over multiple exercises, assigning consecutive `orderIndex` and `groupOrderIndex` values (0, 1, 2…).

```dart
/// Cascade delete all exercises and their sets for a given supersetGroupId
Future<void> deleteSupersetGroup({
  required String userId,
  required String programId,
  required String weekId,
  required String workoutId,
  required List<String> exerciseIds, // IDs of all exercises in the group
}) async { ... }
```

Pattern: follows `_deleteExerciseCascade` but batches deletions for all exercises in the group.

### 8.3 `FirestoreService.duplicateWeek` update

In the exercise duplication loop (currently at line ~602), add `supersetGroupId` and `groupOrderIndex` to the copied fields:

```dart
'supersetGroupId': exerciseData['supersetGroupId'],
'groupOrderIndex': exerciseData['groupOrderIndex'],
```

---

## 9. `ConsolidatedWorkoutScreen` Refactor

**`_buildExercisesList`** is refactored to:
1. Convert `List<Exercise>` → `List<WorkoutItem>` using `groupExercises()`
2. Build `ReorderableListView` with `WorkoutItem`s as items
3. `SupersetGroup` → render `SupersetGroupCard(key: ValueKey(group.groupId), outerIndex: index, ...)`
4. `StandaloneExercise` → render existing `ExerciseCard(key: ValueKey(exercise.id), index: index, ...)`

**`_reorderWorkoutItems(oldIndex, newIndex)`** (replaces `_reorderExercises`):
- Moves a `WorkoutItem` within the `WorkoutItem` list
- Recalculates `orderIndex` for **all** exercises globally (0, 1, 2…) accounting for the exercises inside moved groups
- Calls `provider.updateExercise(...)` for each affected exercise

**`_reorderWithinGroup(String groupId, int oldIndex, int newIndex)`:**
- Swaps `groupOrderIndex` values for the two exercises
- Calls `provider.updateExercise(...)` for each
- Triggers label recomputation on next build

**`_deleteSuperset(String supersetGroupId)`:**
- Shows `DeleteConfirmationDialog` listing all exercises in the group
- Calls `provider.deleteSuperset(...)`

---

## 10. Firestore Index

No new composite indexes needed. The superset group queries are filtered in-memory (already have all exercises loaded for the workout via `loadExercises`).

---

## 11. Testing Strategy

### Unit Tests

**`test/models/exercise_test.dart`** (new or extend existing):
- `supersetGroupId` is null by default, serialises/deserialises correctly
- `copyWith` with `clearSupersetGroup: true` sets it to null

**`test/utils/workout_item_test.dart`** (new):
- `groupExercises` correctly groups exercises sharing a `supersetGroupId`
- Standalone exercises produce `StandaloneExercise` items
- Label computation: first group → "A", second → "B", etc.
- Edge case: all exercises standalone (no groups)
- Edge case: all exercises in one group

**`test/providers/program_provider_superset_test.dart`** (new):
- `createSuperset` calls FirestoreService with correct args
- `deleteSuperset` calls correct service method and refreshes state
- Mock FirestoreService via Mockito `@GenerateMocks([FirestoreService])`

### Widget Tests

**`test/widgets/superset_group_card_test.dart`** (new):
- Renders group label badge ("Superset · A")
- Shows A1, A2 labels on child exercises
- 3-dot menu contains "Delete Superset"
- Drag handle present

**`test/screens/consolidated_workout_screen_test.dart`** (update):
- Existing tests still pass (standalone exercises render as before)
- Add: workout with grouped exercises renders `SupersetGroupCard`
- Add: FAB tap shows menu with "Add Exercise" and "Add Superset" options

**`test/screens/exercises/exercise_picker_screen_test.dart`** (update):
- Add: `isMultiSelect: true` shows checkboxes
- Add: selecting 2+ exercises enables Add button
- Add: selecting 1 exercise keeps Add button disabled

### Integration Test (REQUIRED — new FirestoreService method)

**`test/services/superset_integration_test.dart`** (new):
- Follows `INTEGRATION_TEST_TEMPLATE.dart`
- Connects to Firebase emulators (localhost:8080, localhost:9099)
- Test: create superset with 2 exercises → verify both docs exist with same `supersetGroupId`
- Test: delete superset group → verify all exercises and sets cascade deleted
- Test: duplicate week with superset → verify `supersetGroupId` preserved in new week

---

## 12. Implementation Tasks (Ordered by Dependency)

| # | Task | Files | Est. |
|---|------|-------|------|
| T1 | Exercise model + converter + Firestore rules | `lib/models/exercise.dart`, `lib/converters/exercise_converter.dart`, `firestore.rules` | 1 day |
| T2 | `WorkoutItem` utility + label computation | `lib/utils/workout_item.dart`, `test/utils/workout_item_test.dart` | 0.5 day |
| T3 | `SupersetGroupCard` widget | `lib/widgets/superset_group_card.dart`, `test/widgets/superset_group_card_test.dart` | 1 day |
| T4 | `ExercisePickerScreen` multi-select mode | `lib/screens/exercises/exercise_picker_screen.dart`, `test/screens/exercises/exercise_picker_screen_test.dart` | 1 day |
| T5 | FirestoreService superset create/delete + `duplicateWeek` update | `lib/services/firestore_service.dart`, `test/services/superset_integration_test.dart` | 1.5 days |
| T6 | `ProgramProvider` superset methods | `lib/providers/program_provider.dart`, `test/providers/program_provider_superset_test.dart` | 1 day |
| T7 | `ConsolidatedWorkoutScreen` refactor + FAB menu | `lib/screens/workouts/consolidated_workout_screen.dart`, `test/screens/consolidated_workout_screen_test.dart` | 1.5 days |
| T8 | Template model update (`TemplateExercise.supersetGroupId`) | `lib/models/templates/templates.dart`, converters, `_saveAsTemplate` in screen | 0.5 day |

**Total estimated:** ~7 days

**Dependency order:**
```
T1 (model) → T2 (utility) → T3 (group card widget)
T1 → T5 (service) → T6 (provider) → T7 (screen)
T4 (picker multi-select) → T7 (screen)
T1 → T8 (templates)
```

Start with T1 — everything depends on it.

---

## 13. Risk & Mitigations

| Risk | Mitigation |
|------|-----------|
| Nested `ReorderableListView` scroll conflicts | Use `NeverScrollableScrollPhysics` on inner list; outer scroll handles page scroll |
| Batch write limit for large supersets | Reuse `commitBatchIfNeeded` pattern from `duplicateWeek` (≤450 ops/batch) |
| `supersetGroupId` collision across workouts | UUIDs from `uuid` package are collision-resistant; group IDs only need to be unique within a workout |
| Analytics queries counting grouped exercises | No change needed — analytics operates on sets, not exercise groups |
| Existing widget tests break on model changes | `supersetGroupId` is nullable with null default — backwards compatible; test factories need `supersetGroupId: null` (implicit) |
