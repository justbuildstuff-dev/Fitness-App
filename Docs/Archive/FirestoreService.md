# FirestoreService Documentation

## Overview

The `FirestoreService` is the central data access layer for the FitTrack application. It implements a client-side architecture with comprehensive CRUD operations, batched writes, and offline persistence support. This service follows the hierarchical data model specified in the technical specification.

## Architecture Principles

### Hierarchical Data Structure
All data follows the strict hierarchy defined in the specification:
```
users/{userId}/
  programs/{programId}/
    weeks/{weekId}/
      workouts/{workoutId}/
        exercises/{exerciseId}/
          sets/{setId}
```

### Security-First Design
- Every document includes a `userId` field matching `request.auth.uid`
- Queries use direct collection paths rather than `collectionGroup` for better security
- All operations validate ownership through hierarchical paths

### Client-Side Architecture
- **No Cloud Functions dependency** for core operations
- Local batched writes for complex operations like duplication
- Offline persistence enabled through Firestore SDK
- Optimized for offline-first user experience

## Core Components

### Singleton Pattern
```dart
static final FirestoreService _instance = FirestoreService._internal();
static FirestoreService get instance => _instance;
```

### Offline Persistence
```dart
static Future<void> enableOfflinePersistence() async
```
Enables Firestore offline persistence. Must be called before any other Firestore operations.

## User Profile Operations

### getUserProfile(String userId)
- **Returns**: `Stream<Map<String, dynamic>?>`
- **Purpose**: Real-time user profile data
- **Security**: Owner or admin access only

### createUserProfile({userId, displayName, email, settings})
- **Purpose**: Initialize user profile on first auth
- **Validation**: Required userId, optional metadata
- **Timestamps**: Auto-sets createdAt and lastLogin

### updateUserProfile({userId, displayName, email, settings})
- **Purpose**: Update user profile data
- **Behavior**: Only updates provided fields
- **Timestamps**: Auto-sets updatedAt

### updateLastLogin(String userId)
- **Purpose**: Track user activity
- **Usage**: Called during authentication flow

## Program Operations

### getPrograms(String userId)
- **Returns**: `Stream<List<Program>>`
- **Query Pattern**: Direct collection path under user
- **Ordering**: `createdAt` descending
- **Filtering**: Excludes archived programs

### getProgram(String userId, String programId)
- **Returns**: `Stream<Program?>`
- **Purpose**: Single program with real-time updates
- **Security**: User-scoped query path

### createProgram(Program program)
- **Returns**: `Future<String>` (document ID)
- **Validation**: Program model handles field validation
- **Timestamps**: Auto-generated server timestamps

### updateProgram(Program program)
- **Behavior**: Updates entire program document
- **Timestamps**: Auto-updates `updatedAt` field

### archiveProgram(String userId, String programId)
- **Purpose**: Soft delete via `isArchived: true`
- **Preserves**: All nested data for potential recovery

### deleteProgram(String userId, String programId)
- **WARNING**: Hard delete - use with caution
- **TODO**: Implement cascade delete via Cloud Function
- **Current**: Only deletes program document

## Week Operations

### getWeeks(String userId, String programId)
- **Returns**: `Stream<List<Week>>`
- **Query Pattern**: Direct collection path under program
- **Ordering**: `order` field ascending
- **Real-time**: Updates automatically via Firestore listeners

### getWeek(String userId, String programId, String weekId)
- **Returns**: `Stream<Week?>`
- **Purpose**: Single week with real-time updates

### createWeek(Week week)
- **Returns**: `Future<String>` (document ID)
- **Validation**: Requires programId in week model
- **Ordering**: Client manages `order` field

### updateWeek(Week week)
- **Behavior**: Full document update
- **Timestamps**: Auto-updates `updatedAt`

### deleteWeek(String userId, String programId, String weekId)
- **TODO**: Implement cascade delete for nested collections
- **Current**: Only deletes week document

## Duplication System

### duplicateWeek({userId, programId, weekId})
- **Returns**: `Future<Map<String, dynamic>>` with mapping
- **Architecture**: Client-side batched writes (no Cloud Functions)
- **Batch Management**: 450 operations per batch (safe margin under 500 limit)
- **Deep Copy**: Week → Workouts → Exercises → Sets

#### Duplication Principles (Per Specification)
1. **Exercise Type-Specific Field Copying**:
   - `strength` → Copy `reps`, `weight`, `restTime`
   - `cardio`/`time-based` → Copy `duration`, `distance`
   - `bodyweight` → Copy `reps`, `restTime`
   - `custom` → Copy all relevant fields

2. **State Resets**:
   - `checked: false` for all sets
   - New timestamps for all documents
   - New Firestore-generated IDs

3. **Batch Operations**:
   - Automatic batch management with commit chunking
   - Atomic operations within each batch
   - Sequential batch commits for operations >450

4. **Return Mapping**:
   ```dart
   {
     'success': true,
     'mapping': {
       'oldWeekId': 'original_id',
       'newWeekId': 'new_id',
       'workouts': [
         {
           'oldWorkoutId': 'original_workout_id',
           'newWorkoutId': 'new_workout_id',
           'exercises': [...],
           'sets': [...]
         }
       ]
     }
   }
   ```

#### Error Handling
- Source validation (existence and ownership)
- Batch commit error recovery
- Detailed error messages for debugging

## Workout Operations

### Standard CRUD Operations
- `getWorkouts(userId, programId, weekId)` → `Stream<List<Workout>>`
- `getWorkout(userId, programId, weekId, workoutId)` → `Stream<Workout?>`
- `createWorkout(Workout workout)` → `Future<String>`
- `updateWorkout(Workout workout)` → `Future<void>`
- `deleteWorkout(userId, programId, weekId, workoutId)` → `Future<void>`

### Query Characteristics
- **Ordering**: `orderIndex` field for drag-and-drop support
- **Hierarchy**: Nested under weeks collection
- **Security**: User-scoped paths only

## Exercise Operations

### Standard CRUD Operations
- `getExercises(userId, programId, weekId, workoutId)` → `Stream<List<Exercise>>`
- `getExercise(userId, programId, weekId, workoutId, exerciseId)` → `Stream<Exercise?>`
- `createExercise(Exercise exercise)` → `Future<String>`
- `updateExercise(Exercise exercise)` → `Future<void>`
- `deleteExercise(userId, programId, weekId, workoutId, exerciseId)` → `Future<void>`

### Exercise Types (Per Specification)
- `strength` → Requires `reps`, optional `weight`, `restTime`
- `cardio` → Requires `duration`, optional `distance`
- `time-based` → Same as cardio
- `bodyweight` → Requires `reps`
- `custom` → Flexible user-defined fields

## Set Operations

### Standard CRUD Operations
- `getSets(userId, programId, weekId, workoutId, exerciseId)` → `Stream<List<ExerciseSet>>`
- `getSet(userId, programId, weekId, workoutId, exerciseId, setId)` → `Stream<ExerciseSet?>`
- `createSet(ExerciseSet set)` → `Future<String>`
- `updateSet(ExerciseSet set)` → `Future<void>`
- `deleteSet(userId, programId, weekId, workoutId, exerciseId, setId)` → `Future<void>`

### Validation Rules (Per Specification)
- **Required**: At least one metric (`reps` OR `duration` OR `distance`)
- **Constraints**: All numeric fields ≥ 0
- **Ordering**: `setNumber` field for consistent ordering

## Delete Operations

### getCascadeDeleteCounts({userId, programId, weekId?, workoutId?, exerciseId?})
- **Returns**: `Future<CascadeDeleteCounts>`
- **Purpose**: Calculate total entities affected by a delete operation
- **Usage**: Called before showing delete confirmation dialog
- **Implementation Status**: ✅ Complete (Added in Task #55)

#### Parameters
- **userId** (required): User performing the delete
- **programId** (required): Program context for the delete
- **weekId** (optional): Week to delete or parent of workout/exercise
- **workoutId** (optional): Workout to delete or parent of exercise
- **exerciseId** (optional): Exercise to delete

#### Behavior by Scenario

**Week Deletion** (`weekId` provided, `workoutId` and `exerciseId` null):
- Counts all workouts in the week
- Counts all exercises across all workouts
- Counts all sets across all exercises
- Returns `CascadeDeleteCounts(workouts: X, exercises: Y, sets: Z)`

**Workout Deletion** (`weekId` and `workoutId` provided, `exerciseId` null):
- Counts all exercises in the workout
- Counts all sets across all exercises
- Returns `CascadeDeleteCounts(exercises: X, sets: Y)`

**Exercise Deletion** (`weekId`, `workoutId`, and `exerciseId` all provided):
- Counts all sets in the exercise
- Returns `CascadeDeleteCounts(sets: X)`

**Error Handling**:
- Invalid parameters → Returns `CascadeDeleteCounts()` (zero counts)
- Firestore errors → Returns `CascadeDeleteCounts()` (zero counts)
- Empty collections → Returns appropriate zero counts

#### Performance Characteristics
- Uses Firestore `.count()` queries for set counts (efficient)
- Uses `.get().docs.length` for workout/exercise counts
- Nested queries for week deletion (multiple round trips)
- Typical response time: 500ms - 2s for week deletion

#### Example Usage
```dart
final counts = await FirestoreService.instance.getCascadeDeleteCounts(
  userId: currentUser.uid,
  programId: program.id,
  weekId: week.id,
);

if (counts.hasItems) {
  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Week',
    itemName: week.name,
    cascadeCounts: counts,
  );
}
```

#### Implementation Notes
- Added as part of Delete Functionality Fix (Issue #49)
- Supports all three delete scenarios: Week, Workout, Exercise
- Integrated with UI delete flows in multiple screens
- See [Delete_Functionality_Fix_Technical_Design.md](../Technical_Designs/Delete_Functionality_Fix_Technical_Design.md) for full details

## Batch Operations

### batchUpdateSets(List<ExerciseSet> sets)
- **Purpose**: Bulk updates for workout completion
- **Limits**: Standard Firestore 500 operations per batch
- **Usage**: Mark multiple sets as completed

### Reorder Operations
All reorder methods use batched updates with proper hierarchical paths:

#### reorderWeeks({userId, programId, weekIds})
- Updates `order` field (1-based indexing)
- Maintains week sequence in program

#### reorderWorkouts({userId, programId, weekId, workoutIds})
- Updates `orderIndex` field
- Supports drag-and-drop UI

#### reorderExercises({userId, programId, weekId, workoutId, exerciseIds})
- Updates `orderIndex` field
- Maintains exercise sequence in workout

#### reorderSets({userId, programId, weekId, workoutId, exerciseId, setIds})
- Updates `setNumber` field
- Supports set reordering within exercise

## Usage Guidelines

### Error Handling
```dart
try {
  final result = await FirestoreService.instance.createProgram(program);
  // Handle success
} catch (e) {
  // Handle specific error types
  // Show user-friendly messages
}
```

### Stream Subscriptions
```dart
StreamSubscription? _subscription;

void _loadData() {
  _subscription?.cancel();
  _subscription = FirestoreService.instance
      .getPrograms(userId)
      .listen(
        (programs) => setState(() => _programs = programs),
        onError: (error) => _handleError(error),
      );
}

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### Offline Operations
- All operations work offline with Firestore persistence
- Queued writes sync automatically when online
- Optimistic UI updates supported

## Security Considerations

### Data Validation
- All document IDs are Firestore-generated (no client-specified IDs)
- User ID validation at service layer
- Hierarchical path validation prevents unauthorized access

### Query Patterns
- **Direct collection paths** only (no collectionGroup queries)
- User-scoped queries: `/users/{userId}/programs/{programId}/...`
- Admin operations require special handling (see Security Rules docs)

## Modification Guidelines

### Adding New Operations
1. Follow the hierarchical path pattern
2. Include userId validation
3. Use proper error handling
4. Add real-time stream methods for UI reactivity
5. Include comprehensive documentation

### Exercise Type Extensions
When adding new exercise types:
1. Update duplication logic in `duplicateWeek`
2. Add validation in security rules
3. Update UI components to handle new fields
4. Maintain backward compatibility

### Batch Operation Limits
- Stay under 450 operations per batch
- Implement batch chunking for large operations
- Use sequential commits for multi-batch operations
- Provide progress feedback for long operations

### Testing Requirements
1. Unit tests for all CRUD operations
2. Integration tests with Firebase Emulator
3. Offline persistence testing
4. Duplication logic validation
5. Error handling scenarios

## Dependencies

### Required Packages
- `cloud_firestore` - Core Firestore functionality
- Firebase project configuration
- Proper security rules deployment

### Related Components
- Models (Program, Week, Workout, Exercise, ExerciseSet)
- Providers (for state management integration)
- Authentication (for user context)

## Performance Considerations

### Query Optimization
- Use indexed fields for ordering (`createdAt`, `orderIndex`, `order`)
- Limit result sets with pagination where appropriate
- Cancel unused stream subscriptions

### Offline Performance
- Firestore offline persistence reduces network calls
- Local caching improves response times
- Queued writes prevent data loss

### Batch Optimization
- Group related operations in single batches
- Use appropriate batch sizes (450 operations max)
- Implement retry logic for failed batches

This service is the foundation of the FitTrack application's data layer. All modifications should maintain consistency with the technical specification and preserve the security-first, offline-capable architecture.