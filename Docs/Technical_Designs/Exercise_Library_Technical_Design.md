# Exercise Library & Custom Exercises - Technical Design

## Overview

This document describes the technical architecture for implementing the Exercise Library and Custom Exercises feature (#259).

**Related Documents:**
- PRD: [Docs/PRDs/Exercise_Library_PRD.md](../PRDs/Exercise_Library_PRD.md)
- GitHub Issue: #259

## Current Architecture Analysis

### State Management
- **Pattern:** Provider with ChangeNotifier
- **App-level state:** `ProgramProvider`, `ThemeProvider`, `AuthProvider`
- **Screen-level state:** StatefulWidget with local state
- **Reference:** `lib/providers/program_provider.dart`, `lib/providers/theme_provider.dart`

### File Organization
```
lib/
  models/          # Data models (Program, Week, Workout, Exercise, etc.)
  providers/       # ChangeNotifier providers
  screens/         # Screen widgets organized by feature
  services/        # Firebase services (FirestoreService, AnalyticsService)
  widgets/         # Reusable widgets
  converters/      # Firestore document converters
  utils/           # Utility functions
```

### Similar Features Examined
- **ThemeProvider:** Enum-based selection with SharedPreferences persistence
- **CreateExerciseScreen:** Form-based creation with validation
- **ProgramProvider:** CRUD operations with Firestore, stream subscriptions

### Testing Approach
- Unit tests with Mockito for mocking SharedPreferences/Firestore
- Widget tests for UI components
- Integration tests with Firebase emulators
- Test files mirror source structure in `test/` directory

## Architecture Overview

### High-Level Approach

The Exercise Library will use a **hybrid data source pattern**:
1. **Library Exercises:** Bundled JSON asset file (offline-first, read-only)
2. **Custom Exercises:** Firestore collection per user (CRUD operations)
3. **Unified Search:** Provider merges both sources for seamless UX

This follows existing patterns:
- Provider pattern (like `ThemeProvider`, `ProgramProvider`)
- JSON asset loading (standard Flutter pattern)
- Firestore CRUD (like existing exercise operations in `ProgramProvider`)

### Design Decisions

#### Decision 1: Library Data Storage
**Options Considered:**
1. Bundled JSON file in assets - Offline-first, no network dependency
2. Firestore shared collection - Centralized but requires network
3. External API - Up-to-date but adds dependency

**Chosen:** Option 1 - Bundled JSON file

**Rationale:**
- Works offline (critical for gym environments)
- No external dependencies
- Fast load times
- Easy to update via app releases
- Follows Flutter best practices for static data

#### Decision 2: Custom Exercises Storage Location
**Options Considered:**
1. `users/{userId}/customExercises/{exerciseId}` - New top-level subcollection
2. `users/{userId}/settings/customExercises` - Nested in settings document
3. Extend existing `exercises` collection - Mix with workout exercises

**Chosen:** Option 1 - New subcollection under user

**Rationale:**
- Clean separation from workout exercises
- Follows existing pattern (`users/{userId}/programs/...`)
- Easy to query all custom exercises for a user
- Security rules already enforce `request.auth.uid == userId`

#### Decision 3: Exercise Picker Integration
**Options Considered:**
1. Replace CreateExerciseScreen entirely - Full redesign
2. Add library picker as modal/bottom sheet before CreateExerciseScreen
3. Modify CreateExerciseScreen to include library search

**Chosen:** Option 2 - New ExercisePickerScreen with modal flow

**Rationale:**
- Minimal changes to working CreateExerciseScreen
- Clear user flow: Pick from library OR create custom
- Can navigate to CreateExerciseScreen for custom exercises
- Preserves existing edit functionality

## Component Design

### New Components

#### 1. MuscleGroup Enum
**Location:** `lib/models/muscle_group.dart`
**Purpose:** Define muscle group categories for filtering
**Pattern:** Similar to `ExerciseType` enum in `lib/models/exercise.dart`

```dart
enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest: return 'Chest';
      case MuscleGroup.back: return 'Back';
      case MuscleGroup.shoulders: return 'Shoulders';
      case MuscleGroup.arms: return 'Arms';
      case MuscleGroup.legs: return 'Legs';
      case MuscleGroup.core: return 'Core';
    }
  }
}
```

#### 2. LibraryExercise Model
**Location:** `lib/models/library_exercise.dart`
**Purpose:** Represent exercises in the bundled library
**Pattern:** Similar to existing models with `fromJson` factory

```dart
class LibraryExercise {
  final String id;
  final String name;
  final ExerciseType exerciseType;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final bool isLibrary; // Always true for library exercises

  factory LibraryExercise.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### 3. CustomExercise Model
**Location:** `lib/models/custom_exercise.dart`
**Purpose:** Represent user-created custom exercises
**Pattern:** Similar to existing models with Firestore serialization

```dart
class CustomExercise {
  final String id;
  final String name;
  final ExerciseType exerciseType;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLibrary; // Always false for custom exercises

  factory CustomExercise.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();
  CustomExercise copyWith({...});
}
```

#### 4. ExerciseLibraryProvider
**Location:** `lib/providers/exercise_library_provider.dart`
**Purpose:** Manage library and custom exercises, provide unified search
**Pattern:** ChangeNotifier like `ThemeProvider`, `ProgramProvider`

```dart
class ExerciseLibraryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String? _userId;

  List<LibraryExercise> _libraryExercises = [];
  List<CustomExercise> _customExercises = [];
  bool _isLoading = false;
  String? _error;

  // Load library from bundled JSON asset
  Future<void> loadLibrary();

  // Load custom exercises from Firestore
  Future<void> loadCustomExercises();

  // Unified search across library + custom
  List<dynamic> searchExercises(String query, {MuscleGroup? muscleGroup, ExerciseType? type});

  // Custom exercise CRUD
  Future<String?> createCustomExercise({...});
  Future<bool> updateCustomExercise(CustomExercise exercise);
  Future<bool> deleteCustomExercise(String exerciseId);

  // Validation
  bool canCreateCustomExercise(); // Check < 20 limit
  bool isNameAvailable(String name); // Check uniqueness
}
```

#### 5. ExercisePickerScreen
**Location:** `lib/screens/exercises/exercise_picker_screen.dart`
**Purpose:** Browse/search library, select exercise for workout
**Pattern:** Similar to existing list screens with search

Key UI elements:
- Search bar with autocomplete
- Filter chips for muscle groups and exercise types
- ListView of exercises (grouped or flat based on filters)
- Tap to view details, "Add" button to select
- FAB or button to "Create Custom Exercise"

#### 6. ExerciseDetailSheet
**Location:** `lib/widgets/exercise_detail_sheet.dart`
**Purpose:** Show exercise details before adding to workout
**Pattern:** Bottom sheet modal (common Flutter pattern)

#### 7. CustomExerciseFormScreen
**Location:** `lib/screens/exercises/custom_exercise_form_screen.dart`
**Purpose:** Create/edit custom exercises
**Pattern:** Similar to CreateExerciseScreen form layout

#### 8. MyExercisesScreen
**Location:** `lib/screens/profile/my_exercises_screen.dart`
**Purpose:** Manage custom exercises from Profile
**Pattern:** List with edit/delete actions (like existing list screens)

### Modified Components

#### 1. CreateExerciseScreen
**Location:** `lib/screens/exercises/create_exercise_screen.dart`
**Changes:**
- Add "Pick from Library" button at top
- Navigate to ExercisePickerScreen when tapped
- Receive selected exercise data and auto-fill form

#### 2. ConsolidatedWorkoutScreen
**Location:** `lib/screens/workouts/consolidated_workout_screen.dart`
**Changes:**
- Modify `_addExercise` to show ExercisePickerScreen first
- Pass selected exercise data to CreateExerciseScreen

#### 3. ProfileScreen / SettingsScreen
**Location:** `lib/screens/profile/profile_screen.dart`
**Changes:**
- Add "My Exercises" menu item linking to MyExercisesScreen

#### 4. main.dart
**Location:** `lib/main.dart`
**Changes:**
- Register ExerciseLibraryProvider in MultiProvider

#### 5. Firestore Security Rules
**Location:** `firestore.rules`
**Changes:**
- Add rules for `users/{userId}/customExercises/{exerciseId}` collection

### File Structure

```
lib/
  models/
    muscle_group.dart                    [NEW] - MuscleGroup enum
    library_exercise.dart                [NEW] - Library exercise model
    custom_exercise.dart                 [NEW] - Custom exercise model
  providers/
    exercise_library_provider.dart       [NEW] - Library/custom provider
  screens/
    exercises/
      exercise_picker_screen.dart        [NEW] - Library browser
      custom_exercise_form_screen.dart   [NEW] - Custom exercise form
      create_exercise_screen.dart        [MODIFIED] - Add library picker
    profile/
      my_exercises_screen.dart           [NEW] - Manage custom exercises
      profile_screen.dart                [MODIFIED] - Add My Exercises link
    workouts/
      consolidated_workout_screen.dart   [MODIFIED] - Use exercise picker
  widgets/
    exercise_detail_sheet.dart           [NEW] - Exercise detail modal
  main.dart                              [MODIFIED] - Register provider

assets/
  data/
    exercise_library.json                [NEW] - Bundled library data

test/
  models/
    muscle_group_test.dart               [NEW]
    library_exercise_test.dart           [NEW]
    custom_exercise_test.dart            [NEW]
  providers/
    exercise_library_provider_test.dart  [NEW]
  screens/
    exercises/
      exercise_picker_screen_test.dart   [NEW]
      custom_exercise_form_screen_test.dart [NEW]
    profile/
      my_exercises_screen_test.dart      [NEW]
  widgets/
    exercise_detail_sheet_test.dart      [NEW]
```

## Data Model

### Library Exercise JSON Schema
```json
{
  "exercises": [
    {
      "id": "lib_barbell_bench_press",
      "name": "Barbell Bench Press",
      "exerciseType": "strength",
      "primaryMuscles": ["chest"],
      "secondaryMuscles": ["triceps", "shoulders"]
    },
    {
      "id": "lib_pull_up",
      "name": "Pull-up",
      "exerciseType": "bodyweight",
      "primaryMuscles": ["back"],
      "secondaryMuscles": ["arms"]
    }
  ]
}
```

### Firestore Structure
```
users/{userId}/
  customExercises/{exerciseId}/
    {
      "id": "custom_abc123",
      "name": "My Special Press",
      "exerciseType": "strength",
      "primaryMuscles": ["chest"],
      "secondaryMuscles": ["shoulders"],
      "userId": "user123",
      "createdAt": Timestamp,
      "updatedAt": Timestamp
    }
```

### Security Rules Addition
```
match /users/{userId}/customExercises/{exerciseId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  allow create: if request.auth != null
    && request.auth.uid == userId
    && request.resource.data.userId == userId
    && request.resource.data.name is string
    && request.resource.data.name.size() <= 50
    && request.resource.data.name.size() > 0;
}
```

## Implementation Tasks

### Task 1: Create MuscleGroup Enum and Models
- Create `lib/models/muscle_group.dart` with MuscleGroup enum
- Create `lib/models/library_exercise.dart` with LibraryExercise model
- Create `lib/models/custom_exercise.dart` with CustomExercise model
- Write unit tests for all models

**Estimated effort:** 0.5 days

### Task 2: Generate Exercise Library JSON
- Create AI-generated JSON with ~120 exercises
- Categories: Strength (barbell, dumbbell, machine, cable), Bodyweight
- Include proper muscle group mappings
- Add to `assets/data/exercise_library.json`
- Update `pubspec.yaml` to include asset

**Estimated effort:** 0.5 days

### Task 3: Create ExerciseLibraryProvider
- Create `lib/providers/exercise_library_provider.dart`
- Implement JSON asset loading for library
- Implement Firestore CRUD for custom exercises
- Implement unified search with filters
- Implement validation (20 limit, name uniqueness)
- Write unit tests with mocked dependencies

**Estimated effort:** 1 day

### Task 4: Update Firestore Security Rules
- Add rules for `customExercises` subcollection
- Test rules with emulator
- Deploy rules

**Estimated effort:** 0.25 days

### Task 5: Create ExercisePickerScreen
- Create `lib/screens/exercises/exercise_picker_screen.dart`
- Implement search bar with debounced input
- Implement filter chips for muscle groups and exercise types
- Implement exercise list with library/custom distinction
- Navigate to detail sheet on tap
- Navigate to CustomExerciseFormScreen for "Create Custom"
- Write widget tests

**Estimated effort:** 1 day

### Task 6: Create ExerciseDetailSheet Widget
- Create `lib/widgets/exercise_detail_sheet.dart`
- Display exercise details (name, type, muscles)
- "Add to Workout" action button
- Write widget tests

**Estimated effort:** 0.5 days

### Task 7: Create CustomExerciseFormScreen
- Create `lib/screens/exercises/custom_exercise_form_screen.dart`
- Form with: name (50 char limit), type dropdown, muscle group checkboxes
- Validation: required fields, name uniqueness, 20 exercise limit
- Edit mode: pre-populate form with existing data
- Write widget tests

**Estimated effort:** 0.75 days

### Task 8: Create MyExercisesScreen
- Create `lib/screens/profile/my_exercises_screen.dart`
- List user's custom exercises with edit/delete actions
- Swipe to delete with confirmation dialog
- Tap to edit (navigate to CustomExerciseFormScreen)
- Empty state when no custom exercises
- Write widget tests

**Estimated effort:** 0.5 days

### Task 9: Integrate with Existing Screens
- Modify ConsolidatedWorkoutScreen to use ExercisePickerScreen
- Modify CreateExerciseScreen to accept pre-filled data from picker
- Add "My Exercises" to ProfileScreen/SettingsScreen
- Register ExerciseLibraryProvider in main.dart
- Write integration tests

**Estimated effort:** 0.75 days

### Task 10: Final Testing and Polish
- End-to-end testing of full user flow
- Accessibility testing (semantic labels)
- Performance testing (search responsiveness)
- Edge case testing (20 limit, duplicate names, etc.)
- Fix any issues found

**Estimated effort:** 0.5 days

## Task Dependencies

```
Task 1 (Models)
    ↓
Task 2 (JSON Library) ──→ Task 3 (Provider) ──→ Task 5 (Picker Screen)
                              ↓                       ↓
                         Task 4 (Rules)         Task 6 (Detail Sheet)
                              ↓                       ↓
                         Task 7 (Form Screen) ──→ Task 8 (My Exercises)
                                                      ↓
                                                Task 9 (Integration)
                                                      ↓
                                                Task 10 (Testing)
```

**Critical Path:** Task 1 → Task 3 → Task 5 → Task 9 → Task 10

## Testing Strategy

### Unit Tests
- MuscleGroup enum: displayName, values
- LibraryExercise: fromJson/toJson, validation
- CustomExercise: fromFirestore/toFirestore, copyWith, validation
- ExerciseLibraryProvider: all methods with mocked Firestore

**Coverage Target:** 90%+

### Widget Tests
- ExercisePickerScreen: search, filters, selection
- ExerciseDetailSheet: rendering, action buttons
- CustomExerciseFormScreen: validation, submission
- MyExercisesScreen: list rendering, edit/delete actions

### Integration Tests
- Full flow: Open picker → Search → Select → Add to workout
- Custom exercise CRUD with Firebase emulators
- Offline behavior for library exercises

## Performance Considerations

- **Library Loading:** Load JSON once at app start, cache in provider
- **Search Debouncing:** 300ms debounce on search input
- **Lazy Loading:** If library grows large, implement pagination/virtualization
- **Firestore Queries:** Use orderBy for consistent ordering

## Accessibility Considerations

- All filter chips have semantic labels
- Exercise list items are focusable with screen reader
- Form fields have proper labels and error announcements
- Buttons have descriptive tooltips

## Security Considerations

- Firestore rules enforce userId matching
- Custom exercise limit (20) prevents abuse
- Name length limit (50) prevents database bloat
- No user data shared between accounts

## Platform-Specific Notes

### iOS
- Bottom sheet uses Cupertino-style gesture if needed
- Keyboard handling for search field

### Android
- Material Design 3 components throughout
- Back button behavior from picker screen

## Future Enhancements (Out of Scope)

- Exercise images/videos
- Exercise instructions/form tips
- Cardio/time-based exercises in library
- Exercise categories beyond strength/bodyweight
- Sharing custom exercises between users
- Cloud sync for library updates
