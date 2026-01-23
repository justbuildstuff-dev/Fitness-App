# Exercise Library & Custom Exercises

## Overview

Add a pre-built exercise library with ~100-150 common exercises (Strength and Bodyweight) and allow users to create, edit, and delete their own custom exercises. This feature reduces friction by enabling exercise selection from a searchable database rather than manual entry each time.

**GitHub Issue:** #259
**Priority:** High
**Platform:** iOS & Android
**Status:** Ready for Design

## User Problem

Users currently must type exercise names manually for every exercise they create. This leads to:
- Wasted time on repetitive data entry
- Inconsistent naming (e.g., "Bench Press" vs "Barbell Bench Press" vs "Flat Bench")
- Poor PR tracking due to name variations
- No standardized muscle group metadata

## User Stories

### US-1: Browse Exercise Library
As a user creating a workout, I want to browse exercises from a pre-built library, so that I can quickly add exercises without typing.

**Acceptance Criteria:**
- [ ] Library displays exercises organized by category
- [ ] Can filter by muscle group (Chest, Back, Shoulders, Arms, Legs, Core)
- [ ] Can filter by exercise type (Strength, Bodyweight)
- [ ] Can search exercises by name
- [ ] Library exercises are read-only (cannot be modified or deleted)

### US-2: Search Exercise Library
As a user adding an exercise to my workout, I want to search exercises by name with autocomplete, so that I can quickly find and select the exercise I want.

**Acceptance Criteria:**
- [ ] Search field provides autocomplete suggestions as user types
- [ ] Results show both library exercises and user's custom exercises
- [ ] Results display exercise name and primary muscle group
- [ ] Minimum 2 characters before search triggers
- [ ] Search is case-insensitive

### US-3: Add Exercise from Library
As a user, I want to select an exercise from the library and have it auto-populate in my workout, so that I don't have to enter exercise details manually.

**Acceptance Criteria:**
- [ ] Selecting a library exercise creates exercise in workout
- [ ] Auto-fills: exercise name, exercise type, primary muscle group, secondary muscle groups
- [ ] Set count starts at 1 (user selects how many sets)
- [ ] User can still modify the exercise instance in their workout (rename, etc.)
- [ ] Works on both iOS and Android

### US-4: Create Custom Exercise
As a user, I want to create my own custom exercises that aren't in the library, so that I can track unique or specialized exercises.

**Acceptance Criteria:**
- [ ] Can create custom exercise with: name, exercise type, primary muscle group(s), secondary muscle group(s)
- [ ] Custom exercise name limited to 50 characters
- [ ] At least one primary muscle group required
- [ ] Cannot create duplicate names (case-insensitive) within user's custom exercises
- [ ] Maximum 20 custom exercises per user
- [ ] Custom exercises stored per-user (not visible to other users)

### US-5: Manage Custom Exercises
As a user, I want to edit and delete my custom exercises, so that I can maintain my personal exercise library.

**Acceptance Criteria:**
- [ ] Can edit custom exercise name, type, and muscle groups
- [ ] Can delete custom exercise from personal library
- [ ] Deletion shows confirmation dialog
- [ ] Deleting custom exercise does NOT affect existing workouts using that exercise (workouts keep data as-is)
- [ ] Cannot edit or delete library exercises (only custom)

### US-6: View Exercise Details
As a user browsing the library, I want to see exercise details before adding, so that I can confirm it's the correct exercise.

**Acceptance Criteria:**
- [ ] Tapping exercise shows detail view
- [ ] Detail view displays: name, exercise type, primary muscles, secondary muscles
- [ ] "Add to Workout" button in detail view
- [ ] "Create Custom" option if browsing from workout creation context

## Functional Requirements

- FR-1: Exercise library bundled with app (offline-first, no API dependency)
- FR-2: Library contains ~100-150 AI-generated exercises (Strength + Bodyweight categories)
- FR-3: Custom exercises stored in Firestore under `users/{userId}/customExercises/{exerciseId}`
- FR-4: Exercise name max 50 characters, trimmed of whitespace
- FR-5: Custom exercises limited to 20 per user
- FR-6: Custom exercise names must be unique per user (case-insensitive)
- FR-7: Library exercises are immutable (read-only)
- FR-8: Search combines library + custom exercises in results

## Non-Functional Requirements

- NFR-1: Performance - Library search returns results within 200ms
- NFR-2: Offline - Library exercises work fully offline; custom exercises require sync
- NFR-3: Accessibility - All list items and buttons have semantic labels for screen readers
- NFR-4: Platform Consistency - Same behavior on iOS and Android

## Data Model

### Library Exercise (bundled JSON)
```json
{
  "id": "lib_bench_press_barbell",
  "name": "Barbell Bench Press",
  "exerciseType": "strength",
  "primaryMuscles": ["chest"],
  "secondaryMuscles": ["triceps", "shoulders"],
  "isLibrary": true
}
```

### Custom Exercise (Firestore)
```
users/{userId}/customExercises/{exerciseId}
{
  "id": "custom_123",
  "name": "My Special Exercise",
  "exerciseType": "strength",
  "primaryMuscles": ["chest"],
  "secondaryMuscles": ["triceps"],
  "userId": "user123",
  "createdAt": timestamp,
  "updatedAt": timestamp,
  "isLibrary": false
}
```

### Muscle Groups (Enum)
- Chest
- Back
- Shoulders
- Arms
- Legs
- Core

### Exercise Types (Existing Enum)
- strength
- bodyweight

## User Flow

### Adding Exercise to Workout
1. User taps "Add Exercise" on workout screen
2. Exercise picker opens with search bar and filter options
3. User can: search by name, filter by muscle group, filter by type
4. User taps exercise to see details
5. User taps "Add" to add exercise to workout
6. Exercise created with auto-filled metadata, 1 set

### Creating Custom Exercise
1. User searches for exercise, doesn't find it
2. User taps "Create Custom Exercise"
3. Form opens: name, type dropdown, muscle group checkboxes
4. User fills form and taps "Save"
5. Custom exercise saved to user's library
6. Exercise immediately added to current workout

### Managing Custom Exercises
1. User goes to Profile > My Exercises (or similar)
2. List shows user's custom exercises
3. User can tap to edit or swipe to delete
4. Edit opens form with existing values
5. Delete shows confirmation, then removes from custom library

## Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| User enters duplicate custom exercise name | Show error: "You already have an exercise with this name" |
| User exceeds 20 custom exercises | Disable "Create" button, show message: "Maximum 20 custom exercises. Delete one to add more." |
| User enters name > 50 characters | Truncate input at 50 characters |
| User deletes custom exercise used in workouts | Workouts keep existing data; exercise just won't appear in library |
| Search returns no results | Show "No exercises found. Create a custom exercise?" |
| Network error saving custom exercise | Show error toast, allow retry |
| Library exercise name matches custom exercise name | Both appear in search results, labeled "Library" vs "Custom" |

## Technical Considerations

- **Data Source:** AI-generated JSON file bundled with app (~100-150 exercises)
- **Storage:** Library = local asset; Custom = Firestore per-user collection
- **Security:** Firestore rules enforce `request.auth.uid == userId` for custom exercises
- **Existing Integration:** Modify CreateExerciseScreen to use exercise picker
- **Offline:** Library always available; custom exercises cached locally

## Success Metrics

- Reduction in average time to add exercise to workout
- % of exercises added from library vs manual entry
- Number of custom exercises created per user
- Search usage frequency

## Overall Acceptance Criteria

- [ ] Users can browse and search a library of 100+ exercises
- [ ] Users can filter by muscle group and exercise type
- [ ] Selecting library exercise auto-fills workout exercise data
- [ ] Users can create up to 20 custom exercises
- [ ] Users can edit and delete their custom exercises
- [ ] Custom exercise deletion does not affect existing workouts
- [ ] Feature works offline for library exercises
- [ ] Feature works identically on iOS and Android
