# Workout Templates & Pre-built Programs - Technical Design

**GitHub Issue:** [#260](https://github.com/justbuildstuff-dev/Fitness-App/issues/260)
**PRD:** [Docs/PRDs/Workout_Templates_PRD.md](../PRDs/Workout_Templates_PRD.md)
**Status:** Design Complete
**Created:** 2026-01-30
**SA Agent:** Solutions Architect

---

## Current Architecture Analysis

### Discovered Patterns

| Pattern | Location | Usage |
|---------|----------|-------|
| **State Management** | Provider pattern with ChangeNotifier | `lib/providers/*.dart` |
| **Week Duplication** | Batched writes, 450-op limit, deep copy | `lib/services/firestore_service.dart:472-704` |
| **Smart Naming** | Auto-suffix with gap-filling | `lib/utils/smart_copy_naming.dart` |
| **Hybrid Data Source** | Bundled JSON + Firestore | `lib/providers/exercise_library_provider.dart` |
| **Create/Edit Screens** | Dual-mode with form validation | `lib/screens/*/create_*_screen.dart` |
| **Converters** | Separate Firestore serialization | `lib/converters/*.dart` |

### Similar Features Examined

1. **Week Duplication** - Deep copy with batched writes, type-specific field handling
2. **Exercise Library** - Pre-built read-only content + user-created content hybrid
3. **Custom Exercises** - Per-user Firestore storage with 20-item limit

This design follows these existing patterns for consistency.

---

## Architecture Overview

### High-Level Strategy

The Workout Templates feature uses a **two-source hybrid architecture** similar to the Exercise Library:

1. **Pre-built Programs**: Stored in Firebase Firestore (server-side for updateability), cached locally for offline access
2. **User Templates**: Stored in per-user Firestore collections with real-time sync

### Why This Approach

- **Follows existing ExerciseLibraryProvider pattern** for consistency
- **Server-side pre-built programs** allows adding new programs without app updates (per PRD requirement)
- **Reuses week duplication logic** for template application (deep copy with batched writes)
- **Maintains offline-first experience** through local caching

### Alternatives Considered

| Alternative | Rejected Because |
|-------------|------------------|
| Bundled JSON for pre-built | PRD requires server-side storage for flexibility |
| Live references to templates | PRD specifies templates are snapshots with no live link |
| Single unified collection | Separate collections better support future community sharing |

---

## Component Design

### New Components

#### 1. Template Models

**Location:** `lib/models/templates/`

```dart
// lib/models/templates/workout_template.dart
class WorkoutTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateExercise> exercises;
  final DateTime createdAt;
  final String userId;           // Empty for pre-built
  final bool isPrebuilt;         // true for server templates
  final String? sourceUserId;    // For future community attribution

  int get exerciseCount => exercises.length;
  int get totalSetCount => exercises.fold(0, (sum, e) => sum + e.sets.length);
}

// lib/models/templates/week_template.dart
class WeekTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateWorkout> workouts;
  final DateTime createdAt;
  final String userId;
  final bool isPrebuilt;

  int get workoutCount => workouts.length;
  int get totalExerciseCount => workouts.fold(0, (sum, w) => sum + w.exercises.length);
}

// lib/models/templates/program_template.dart
class ProgramTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateWeek> weeks;
  final DateTime createdAt;
  final String userId;
  final bool isPrebuilt;

  int get weekCount => weeks.length;
  int get totalWorkoutCount => weeks.fold(0, (sum, w) => sum + w.workouts.length);
}
```

**Nested Template Structures (denormalized for efficient reads):**

```dart
// lib/models/templates/template_exercise.dart
class TemplateExercise {
  final String name;
  final ExerciseType exerciseType;
  final int orderIndex;
  final String? notes;
  final List<TemplateSet> sets;
}

// lib/models/templates/template_set.dart
class TemplateSet {
  final int setNumber;
  final int? reps;
  final int? duration;      // seconds
  final double? distance;   // meters (NOT weight - always reset)
  final int? restTime;      // seconds
  final String? notes;
}

// lib/models/templates/template_workout.dart
class TemplateWorkout {
  final String name;
  final int? dayOfWeek;
  final int orderIndex;
  final String? notes;
  final List<TemplateExercise> exercises;
}

// lib/models/templates/template_week.dart
class TemplateWeek {
  final String name;
  final int order;
  final String? notes;
  final List<TemplateWorkout> workouts;
}
```

#### 2. Template Provider

**Location:** `lib/providers/template_provider.dart`

```dart
class TemplateProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String? _userId;

  // Pre-built programs (cached from Firestore)
  List<ProgramTemplate> _prebuiltPrograms = [];
  bool _isPrebuiltLoaded = false;
  bool _isLoadingPrebuilt = false;

  // User templates (real-time sync)
  List<WorkoutTemplate> _workoutTemplates = [];
  List<WeekTemplate> _weekTemplates = [];
  List<ProgramTemplate> _programTemplates = [];

  StreamSubscription? _workoutTemplatesSubscription;
  StreamSubscription? _weekTemplatesSubscription;
  StreamSubscription? _programTemplatesSubscription;

  String? _error;

  // Template limits
  static const int maxWorkoutTemplates = 10;
  static const int maxWeekTemplates = 10;
  static const int maxProgramTemplates = 10;

  // Public getters
  List<ProgramTemplate> get prebuiltPrograms => _prebuiltPrograms;
  List<WorkoutTemplate> get workoutTemplates => _workoutTemplates;
  List<WeekTemplate> get weekTemplates => _weekTemplates;
  List<ProgramTemplate> get programTemplates => _programTemplates;
  bool get isLoading => _isLoadingPrebuilt;
  String? get error => _error;

  // Combined getters for UI (pre-built + user templates)
  List<ProgramTemplate> get allProgramTemplates => [
    ..._prebuiltPrograms,
    ..._programTemplates,
  ];

  // Limit checks
  bool get canSaveWorkoutTemplate => _workoutTemplates.length < maxWorkoutTemplates;
  bool get canSaveWeekTemplate => _weekTemplates.length < maxWeekTemplates;
  bool get canSaveProgramTemplate => _programTemplates.length < maxProgramTemplates;
}
```

**Key Methods:**

```dart
// Load pre-built programs (cached)
Future<void> loadPrebuiltPrograms() async {
  if (_isPrebuiltLoaded) return;
  _isLoadingPrebuilt = true;
  notifyListeners();

  try {
    _prebuiltPrograms = await _firestoreService.getPrebuiltPrograms();
    _isPrebuiltLoaded = true;
  } catch (e) {
    _error = 'Failed to load pre-built programs: $e';
  } finally {
    _isLoadingPrebuilt = false;
    notifyListeners();
  }
}

// Subscribe to user templates
void _subscribeToUserTemplates() {
  if (_userId == null) return;

  _workoutTemplatesSubscription = _firestoreService
      .getUserWorkoutTemplates(_userId!)
      .listen((templates) {
        _workoutTemplates = templates;
        notifyListeners();
      });
  // Similar for week and program templates
}

// Save workout as template
Future<bool> saveWorkoutAsTemplate({
  required Workout workout,
  required List<Exercise> exercises,
  required Map<String, List<ExerciseSet>> setsByExercise,
  String? customName,
}) async {
  if (!canSaveWorkoutTemplate) {
    _error = 'Maximum 10 workout templates reached';
    notifyListeners();
    return false;
  }

  try {
    final template = WorkoutTemplate.fromWorkout(
      workout: workout,
      exercises: exercises,
      setsByExercise: setsByExercise,
      name: customName ?? workout.name,
      userId: _userId!,
    );

    await _firestoreService.saveWorkoutTemplate(template);
    return true;
  } catch (e) {
    _error = 'Failed to save template: $e';
    notifyListeners();
    return false;
  }
}

// Apply template (create workout from template)
Future<String?> applyWorkoutTemplate({
  required WorkoutTemplate template,
  required String weekId,
  required String programId,
  required List<String> existingWorkoutNames,
}) async {
  try {
    final workoutName = SmartCopyNaming.generateCopyName(
      template.name,
      existingWorkoutNames,
    );

    return await _firestoreService.createWorkoutFromTemplate(
      template: template,
      workoutName: workoutName,
      weekId: weekId,
      programId: programId,
      userId: _userId!,
    );
  } catch (e) {
    _error = 'Failed to apply template: $e';
    notifyListeners();
    return null;
  }
}
```

#### 3. Template Converters

**Location:** `lib/converters/template_converters.dart`

```dart
class WorkoutTemplateConverter {
  static Map<String, dynamic> toFirestore(WorkoutTemplate template) {
    return {
      'name': template.name,
      'description': template.description,
      'exercises': template.exercises.map((e) => TemplateExerciseConverter.toMap(e)).toList(),
      'createdAt': Timestamp.fromDate(template.createdAt),
      'userId': template.userId,
      'isPrebuilt': template.isPrebuilt,
    };
  }

  static WorkoutTemplate fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutTemplate(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      exercises: (data['exercises'] as List<dynamic>?)
          ?.map((e) => TemplateExerciseConverter.fromMap(e))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      isPrebuilt: data['isPrebuilt'] ?? false,
    );
  }
}
```

#### 4. Firestore Service Extensions

**Location:** `lib/services/firestore_service.dart` (additions)

```dart
// Pre-built programs collection (admin-managed)
static const String _prebuiltProgramsCollection = 'prebuiltPrograms';

// User template collections
CollectionReference _userWorkoutTemplates(String userId) =>
    _firestore.collection('users').doc(userId).collection('workoutTemplates');

CollectionReference _userWeekTemplates(String userId) =>
    _firestore.collection('users').doc(userId).collection('weekTemplates');

CollectionReference _userProgramTemplates(String userId) =>
    _firestore.collection('users').doc(userId).collection('programTemplates');

// Fetch pre-built programs (with caching)
Future<List<ProgramTemplate>> getPrebuiltPrograms() async {
  final snapshot = await _firestore
      .collection(_prebuiltProgramsCollection)
      .orderBy('order')
      .get(const GetOptions(source: Source.serverAndCache));

  return snapshot.docs
      .map((doc) => ProgramTemplateConverter.fromFirestore(doc))
      .toList();
}

// Stream user templates
Stream<List<WorkoutTemplate>> getUserWorkoutTemplates(String userId) {
  return _userWorkoutTemplates(userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => WorkoutTemplateConverter.fromFirestore(doc))
          .toList());
}

// Create workout from template (uses batched writes like week duplication)
Future<String> createWorkoutFromTemplate({
  required WorkoutTemplate template,
  required String workoutName,
  required String weekId,
  required String programId,
  required String userId,
}) async {
  const batchLimit = 450;
  WriteBatch batch = _firestore.batch();
  int batchCount = 0;

  // Create workout document
  final workoutRef = _firestore
      .collection('users').doc(userId)
      .collection('programs').doc(programId)
      .collection('weeks').doc(weekId)
      .collection('workouts').doc();

  final workoutData = {
    'name': workoutName,
    'dayOfWeek': null,
    'orderIndex': await _getNextWorkoutOrder(userId, programId, weekId),
    'notes': null,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'userId': userId,
    'weekId': weekId,
    'programId': programId,
  };

  batch.set(workoutRef, workoutData);
  batchCount++;

  // Create exercises and sets from template
  for (final templateExercise in template.exercises) {
    final exerciseRef = workoutRef.collection('exercises').doc();

    final exerciseData = {
      'name': templateExercise.name,
      'exerciseType': templateExercise.exerciseType.toMap(),
      'orderIndex': templateExercise.orderIndex,
      'notes': templateExercise.notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'workoutId': workoutRef.id,
      'weekId': weekId,
      'programId': programId,
    };

    batch.set(exerciseRef, exerciseData);
    batchCount++;

    // Create sets (reset weight/checked, preserve structure)
    for (final templateSet in templateExercise.sets) {
      if (batchCount >= batchLimit) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }

      final setRef = exerciseRef.collection('sets').doc();

      final setData = {
        'setNumber': templateSet.setNumber,
        'reps': templateSet.reps,
        'weight': null,  // Always reset
        'duration': templateSet.duration,
        'distance': null,  // Always reset
        'restTime': templateSet.restTime,
        'checked': false,  // Always reset
        'notes': templateSet.notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': userId,
        'exerciseId': exerciseRef.id,
        'workoutId': workoutRef.id,
        'weekId': weekId,
        'programId': programId,
      };

      batch.set(setRef, setData);
      batchCount++;
    }
  }

  await batch.commit();
  return workoutRef.id;
}
```

#### 5. UI Components

**Template Picker Screen (Reusable)**

**Location:** `lib/screens/templates/template_picker_screen.dart`

```dart
class TemplatePickerScreen<T> extends StatelessWidget {
  final String title;
  final List<T> templates;
  final Widget Function(T template) previewBuilder;
  final void Function(T template) onSelect;
  final bool isLoading;
  final String? error;

  // Shows list of templates with preview on tap
  // Returns selected template to caller
}
```

**Template Preview Bottom Sheet**

**Location:** `lib/widgets/template_preview_sheet.dart`

```dart
class TemplatePreviewSheet extends StatelessWidget {
  final dynamic template;  // WorkoutTemplate, WeekTemplate, or ProgramTemplate
  final VoidCallback onUse;
  final bool isLoading;

  // Shows template details based on type:
  // - Workout: List of exercises with set counts
  // - Week: List of workouts with exercise counts
  // - Program: List of weeks with workout counts
}
```

**Save as Template Dialog**

**Location:** `lib/widgets/save_template_dialog.dart`

```dart
class SaveTemplateDialog extends StatelessWidget {
  final String defaultName;
  final String templateType;  // "workout", "week", or "program"
  final bool canSave;  // Based on limit check
  final Future<bool> Function(String name) onSave;
}
```

**My Templates Screen**

**Location:** `lib/screens/templates/my_templates_screen.dart`

```dart
class MyTemplatesScreen extends StatelessWidget {
  // Three expandable sections:
  // - Workout Templates (count/10)
  // - Week Templates (count/10)
  // - Program Templates (count/10)
  // Each with delete/rename options
}
```

### Modified Components

#### 1. CreateProgramScreen

**Location:** `lib/screens/programs/create_program_screen.dart`

**Changes:**
- Add "From Template" button in app bar or as FAB option
- When tapped, navigate to TemplatePickerScreen with program templates
- On template selection, create program and all children from template

#### 2. CreateWeekScreen

**Location:** `lib/screens/weeks/create_week_screen.dart`

**Changes:**
- Add "From Template" button
- Navigate to TemplatePickerScreen with week templates
- Apply template with calculated order

#### 3. CreateWorkoutScreen

**Location:** `lib/screens/workouts/create_workout_screen.dart`

**Changes:**
- Add "From Template" button
- Navigate to TemplatePickerScreen with workout templates
- Apply template with auto-suffix naming

#### 4. ConsolidatedWorkoutScreen

**Location:** `lib/screens/workouts/consolidated_workout_screen.dart`

**Changes:**
- Add "Save as Template" to overflow menu
- Show SaveTemplateDialog when tapped
- Call TemplateProvider.saveWorkoutAsTemplate()

#### 5. WeeksScreen

**Location:** `lib/screens/weeks/weeks_screen.dart`

**Changes:**
- Add "Save as Template" to overflow menu (existing menu pattern)
- Show SaveTemplateDialog when tapped

#### 6. ProgramDetailScreen

**Location:** `lib/screens/programs/program_detail_screen.dart`

**Changes:**
- Add "Save as Template" to overflow menu
- Show SaveTemplateDialog when tapped

#### 7. ProfileScreen

**Location:** `lib/screens/profile/profile_screen.dart`

**Changes:**
- Add "My Templates" list tile in settings section
- Navigate to MyTemplatesScreen when tapped

#### 8. main.dart

**Changes:**
- Add TemplateProvider to MultiProvider setup

---

## File Structure

```
lib/
├── models/
│   └── templates/
│       ├── workout_template.dart       [NEW]
│       ├── week_template.dart          [NEW]
│       ├── program_template.dart       [NEW]
│       ├── template_exercise.dart      [NEW]
│       ├── template_set.dart           [NEW]
│       ├── template_workout.dart       [NEW]
│       └── template_week.dart          [NEW]
├── providers/
│   └── template_provider.dart          [NEW]
├── converters/
│   └── template_converters.dart        [NEW]
├── services/
│   └── firestore_service.dart          [MODIFIED - add template methods]
├── screens/
│   ├── templates/
│   │   ├── template_picker_screen.dart [NEW]
│   │   └── my_templates_screen.dart    [NEW]
│   ├── programs/
│   │   └── create_program_screen.dart  [MODIFIED - add From Template]
│   ├── weeks/
│   │   ├── create_week_screen.dart     [MODIFIED - add From Template]
│   │   └── weeks_screen.dart           [MODIFIED - add Save as Template]
│   ├── workouts/
│   │   ├── create_workout_screen.dart  [MODIFIED - add From Template]
│   │   └── consolidated_workout_screen.dart [MODIFIED - add Save as Template]
│   └── profile/
│       └── profile_screen.dart         [MODIFIED - add My Templates]
├── widgets/
│   ├── template_preview_sheet.dart     [NEW]
│   └── save_template_dialog.dart       [NEW]
└── main.dart                           [MODIFIED - add TemplateProvider]

test/
├── models/
│   └── templates/
│       ├── workout_template_test.dart  [NEW]
│       ├── week_template_test.dart     [NEW]
│       └── program_template_test.dart  [NEW]
├── providers/
│   └── template_provider_test.dart     [NEW]
├── services/
│   └── template_service_test.dart      [NEW]
└── widgets/
    ├── template_picker_test.dart       [NEW]
    └── template_preview_test.dart      [NEW]

assets/
└── data/
    └── prebuilt_programs.json          [NEW - seed data for Firebase]

firestore.rules                         [MODIFIED - add template rules]
```

---

## Firestore Structure

### Pre-built Programs (Admin Collection)

```
/prebuiltPrograms/{programId}
  ├── name: "Push Pull Legs"
  ├── description: "Classic 6-day split..."
  ├── order: 1  // Display order
  ├── weeks: [
  │   {
  │     name: "Week 1",
  │     order: 1,
  │     workouts: [
  │       {
  │         name: "Push A",
  │         dayOfWeek: 1,
  │         orderIndex: 0,
  │         exercises: [
  │           {
  │             name: "Bench Press",
  │             exerciseType: "strength",
  │             orderIndex: 0,
  │             sets: [
  │               { setNumber: 1, reps: 8, restTime: 120 },
  │               { setNumber: 2, reps: 8, restTime: 120 },
  │               ...
  │             ]
  │           },
  │           ...
  │         ]
  │       },
  │       ...
  │     ]
  │   },
  │   ...
  │ ]
  ├── isPrebuilt: true
  └── createdAt: Timestamp
```

### User Templates

```
/users/{userId}/workoutTemplates/{templateId}
  ├── name: "My Push Day"
  ├── description: null
  ├── exercises: [
  │   {
  │     name: "Bench Press",
  │     exerciseType: "strength",
  │     orderIndex: 0,
  │     notes: null,
  │     sets: [
  │       { setNumber: 1, reps: 8, restTime: 120 },
  │       ...
  │     ]
  │   },
  │   ...
  │ ]
  ├── createdAt: Timestamp
  ├── userId: "user123"
  └── isPrebuilt: false

/users/{userId}/weekTemplates/{templateId}
  └── (similar structure with workouts array)

/users/{userId}/programTemplates/{templateId}
  └── (similar structure with weeks array)
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Pre-built programs - read-only for authenticated users
    match /prebuiltPrograms/{programId} {
      allow read: if request.auth != null;
      allow write: if false;  // Admin-only via Firebase Console/Admin SDK
    }

    // User workout templates
    match /users/{userId}/workoutTemplates/{templateId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
        && request.auth.uid == userId
        && request.resource.data.userId == userId;
    }

    // User week templates
    match /users/{userId}/weekTemplates/{templateId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
        && request.auth.uid == userId
        && request.resource.data.userId == userId;
    }

    // User program templates
    match /users/{userId}/programTemplates/{templateId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
        && request.auth.uid == userId
        && request.resource.data.userId == userId;
    }
  }
}
```

---

## Implementation Tasks

### Task Breakdown

| # | Task | Dependencies | Estimate |
|---|------|--------------|----------|
| 1 | Create template data models | None | 1 day |
| 2 | Create template converters | Task 1 | 0.5 days |
| 3 | Add template Firestore service methods | Task 2 | 1.5 days |
| 4 | Create TemplateProvider | Task 3 | 1 day |
| 5 | Add Firestore security rules for templates | Task 3 | 0.5 days |
| 6 | Create pre-built programs seed data | Task 1 | 1 day |
| 7 | Create template picker screen | Task 4 | 1 day |
| 8 | Create template preview bottom sheet | Task 4 | 0.5 days |
| 9 | Create save template dialog | Task 4 | 0.5 days |
| 10 | Add "From Template" to create screens | Task 7, 8 | 1 day |
| 11 | Add "Save as Template" to detail screens | Task 9 | 1 day |
| 12 | Create My Templates screen | Task 4 | 1 day |
| 13 | Integrate TemplateProvider in main.dart | Task 4 | 0.5 days |
| 14 | Write unit tests for models and provider | All | 1 day |
| 15 | Write widget tests for UI components | All | 1 day |

### Task Dependencies Diagram

```
Task 1 (Models)
    ↓
Task 2 (Converters)
    ↓
Task 3 (Firestore Service) → Task 5 (Security Rules)
    ↓
Task 4 (Provider) ← Task 6 (Seed Data)
    ↓
    ├── Task 7 (Picker Screen)
    │       ↓
    │   Task 10 (From Template)
    │
    ├── Task 8 (Preview Sheet)
    │
    ├── Task 9 (Save Dialog)
    │       ↓
    │   Task 11 (Save as Template)
    │
    └── Task 12 (My Templates)
            ↓
        Task 13 (Integration)
            ↓
        Task 14 & 15 (Tests)
```

---

## Testing Strategy

### Unit Tests

**Coverage Target:** 90%+

| Component | Tests |
|-----------|-------|
| Template Models | Constructor, fromMap, toMap, copyWith, validation |
| Template Converters | toFirestore, fromFirestore, edge cases |
| TemplateProvider | Load, save, delete, apply, limit enforcement |
| SmartCopyNaming (existing) | Already tested, verify integration |

### Widget Tests

| Screen | Tests |
|--------|-------|
| TemplatePickerScreen | Renders templates, selection, empty state, loading |
| TemplatePreviewSheet | Shows correct info for each type, use button |
| SaveTemplateDialog | Validation, save callback, limit message |
| MyTemplatesScreen | Sections, delete, rename |
| CreateScreens + Template | From Template button, navigation, creation |

### Integration Tests

| Flow | Tests |
|------|-------|
| Save workout as template | Complete flow from workout → template → verify saved |
| Create from template | Select template → create → verify structure |
| Pre-built program | Browse → select → create → verify all content |
| Template limits | Create 10 → attempt 11th → verify error |

---

## Performance Considerations

1. **Batched Writes**: Reuse 450-op limit pattern from week duplication
2. **Denormalized Templates**: Single document read for template preview
3. **Lazy Loading**: Pre-built programs loaded on first access, cached
4. **Stream Subscriptions**: Real-time sync for user templates

---

## Security Considerations

1. **User Scoping**: All user templates scoped by `userId` in Firestore rules
2. **Pre-built Read-Only**: No client writes to pre-built collection
3. **Template Content**: Copied on use, no live reference to protect source
4. **Limit Enforcement**: Client-side + server-side validation for template limits

---

## Accessibility Considerations

1. **Screen Reader Labels**: All buttons, lists, and interactive elements labeled
2. **Focus Management**: Proper focus handling in dialogs and pickers
3. **Loading States**: Announce loading completion
4. **Error Messages**: Accessible error announcements

---

## Platform-Specific Notes

### iOS
- Bottom sheets use CupertinoModalPopupRoute for native feel
- Swipe-to-delete in My Templates

### Android
- Material 3 bottom sheets
- Long-press context menu option for delete

---

## Rollback Plan

1. **Feature Flag**: Add `enableTemplates` flag to disable UI if issues found
2. **Data Safety**: Templates are isolated - no impact on existing user data
3. **Firestore Rules**: Can be reverted independently
4. **Provider Removal**: TemplateProvider can be removed from MultiProvider

---

## Implementation Notes

*Added during QA — documents bugs found and lessons learned.*

### Bug #1: Missing `isArchived` field in program creation from template

**Symptom:** `PERMISSION_DENIED` when applying program templates via batched writes.
**Root Cause:** `createProgramFromTemplate` did not include `isArchived: false` in the program document data. Firestore security rules (`validProgram`) require this field, causing the entire batch write to fail.
**Fix:** Added `'isArchived': false` to `programData` in `firestore_service.dart:createProgramFromTemplate`.
**Lesson:** When adding new Firestore write paths, always cross-reference the security rules validation functions to ensure all required fields are included.

### Bug #2: Null timestamp crash when loading programs

**Symptom:** `TypeError: null is not a subtype of type 'Timestamp'` in `ProgramConverter.fromFirestore`.
**Root Cause:** When `FieldValue.serverTimestamp()` is used in a batched write, the local cache initially stores `null` for the timestamp field until the server confirms. `ProgramConverter` assumed `createdAt` was always a non-null `Timestamp`.
**Fix:** Added `_parseTimestamp` helper in `ProgramConverter` that returns `DateTime.now()` as fallback for null values.
**Lesson:** Any Firestore converter that reads timestamp fields must handle null gracefully when using `FieldValue.serverTimestamp()` in writes, due to the local optimistic write behavior.

### Bug #3: Firestore number type conversion in template models

**Symptom:** Potential `TypeError` when parsing template data from Firestore.
**Root Cause:** Firestore stores all numbers as doubles internally (JavaScript number type). Template models used `as int?` casts which can fail when the value is a `double`.
**Fix:** Added `_parseIntOrNull` and `_parseIntOrDefault` safe parsing helpers to all template model classes (`TemplateSet`, `TemplateExercise`, `TemplateWorkout`, `TemplateWeek`).
**Lesson:** Always use safe number parsing when reading int fields from Firestore. Never use direct `as int?` casts.

### Bug #4: Template picker stuck on loading spinner on first visit

**Symptom:** Template picker shows infinite loading spinner on first navigation; works correctly on subsequent visits.
**Root Cause:** `_navigateToTemplatePicker` in `programs_screen.dart` captured `templateProvider.prebuiltPrograms` and `templateProvider.isLoadingPrebuilt` as static values with `listen: false`. On first visit, `loadPrebuiltPrograms()` was still in-flight, so the screen got `templates: []` and `isLoading: true` that never updated.
**Fix:** Wrapped `TemplatePickerScreen` in a `Consumer<TemplateProvider>` so the screen rebuilds reactively when the provider finishes loading.
**Lesson:** When navigating to screens that depend on async provider data, use `Consumer` or `context.watch` in the route builder — not `listen: false` snapshots.

---

## Future Enhancements (Out of Scope)

1. **Community Templates**: Add `isPublic` flag, query public templates
2. **Template Categories**: Add `category` field, filter UI
3. **Template Editing**: Allow modifying template content (complex)
4. **Template Versioning**: Track template versions
5. **Import/Export**: Share templates via JSON/deep links
