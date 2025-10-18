# Data Models Documentation

## Overview

The FitTrack application uses a hierarchical data model that mirrors the Firestore document structure. All models implement consistent patterns for Firestore serialization, validation, and type safety. The models follow the technical specification requirements and maintain referential integrity through parent ID fields.

## Hierarchical Structure

The data models follow the strict hierarchy defined in the specification:

```
Program
└── Week
    └── Workout
        └── Exercise
            └── ExerciseSet

Analytics Models (Client-side computed):
├── WorkoutAnalytics      (Aggregated statistics)
├── ActivityHeatmapData   (Activity visualization data)
├── PersonalRecord        (Achievement tracking)
├── DateRange            (Time period utilities)
└── HeatmapDay           (Daily activity representation)
```

Each model maintains references to its parent documents through ID fields, enabling efficient queries and security validation.

## Common Patterns

### Standard Fields
All models include these standard fields:
- `id`: String - Firestore document ID
- `createdAt`: DateTime - Document creation timestamp  
- `updatedAt`: DateTime - Last modification timestamp
- `userId`: String - Owner's authentication UID (security field)

### Factory Constructors
- `fromFirestore()`: Deserializes Firestore DocumentSnapshot to model instance
- Type-safe conversion with null handling and defaults

### Serialization
- `toFirestore()`: Converts model to Map<String, dynamic> for Firestore storage
- Handles Timestamp conversion and null values

### Immutability
- `copyWith()`: Creates modified copies while maintaining immutability
- Selective field updates with type safety

### Validation
- Built-in validation methods for business rules
- Field-specific validation based on technical specification

## Model Definitions

### Program

**Purpose**: Top-level container for training programs

**Fields**:
```dart
final String id;           // Firestore document ID
final String name;         // Required, max 100 characters
final String? description; // Optional, max 500 characters
final DateTime createdAt;  // Auto-generated
final DateTime updatedAt;  // Auto-updated
final String userId;       // Owner reference (security)
final bool isArchived;     // Soft delete flag
```

**Validation Rules**:
- `name`: Required, trimmed, 1-100 characters
- `description`: Optional, max 500 characters
- `isArchived`: Defaults to false

**Usage Guidelines**:
```dart
// Creating a new program
final program = Program(
  id: '', // Will be set by Firestore
  name: 'Push/Pull/Legs',
  description: 'Classic 3-day split routine',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  userId: currentUserId,
);

// Validation
assert(program.isValidName);
assert(program.isValidDescription);
```

**Firestore Mapping**:
```json
{
  "name": "Push/Pull/Legs",
  "description": "Classic 3-day split routine",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z", 
  "userId": "user123",
  "isArchived": false
}
```

### Week

**Purpose**: Weekly training blocks within programs

**Fields**:
```dart
final String id;          // Firestore document ID
final String name;        // Display name (default: "Week {order}")
final int order;          // 1-based ordering within program
final String? notes;      // Optional week notes
final DateTime createdAt; // Auto-generated
final DateTime updatedAt; // Auto-updated  
final String userId;      // Owner reference (security)
final String programId;   // Parent program reference
```

**Validation Rules**:
- `name`: Required, non-empty after trim
- `order`: Must be > 0 (1-based indexing)
- `programId`: Required parent reference

**Ordering Behavior**:
- `order` field maintains sequence within program
- Reordering updates all affected weeks
- UI should prevent duplicate order values

**Usage Guidelines**:
```dart
// Creating a new week
final week = Week(
  id: '',
  name: 'Week 1: Foundation',
  order: 1,
  notes: 'Focus on form and technique',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  userId: currentUserId,
  programId: parentProgramId,
);

// Validation
assert(week.isValidName);
assert(week.isValidOrder);
```

### Workout

**Purpose**: Individual training sessions within weeks

**Fields**:
```dart
final String id;           // Firestore document ID
final String name;         // Workout name (e.g., "Push Day")
final int? dayOfWeek;      // Optional: 1-7 (Mon-Sun)
final int orderIndex;      // 0-based ordering within week
final String? notes;       // Optional workout notes
final DateTime createdAt;  // Auto-generated
final DateTime updatedAt;  // Auto-updated
final String userId;       // Owner reference (security)
final String weekId;       // Parent week reference
final String programId;    // Grandparent program reference
```

**Validation Rules**:
- `name`: Required, max 200 characters  
- `dayOfWeek`: Optional, 1-7 if specified
- `orderIndex`: 0-based for consistent sorting

**Parent References**:
- Maintains both `weekId` and `programId` for efficient querying
- Enables security validation at multiple levels

### Exercise

**Purpose**: Individual exercises within workouts

**Fields**:
```dart
final String id;              // Firestore document ID  
final String name;            // Exercise name
final ExerciseType exerciseType; // Type enum (affects set validation)
final int orderIndex;         // 0-based ordering within workout
final String? notes;          // Optional exercise notes
final DateTime createdAt;     // Auto-generated
final DateTime updatedAt;     // Auto-updated
final String userId;          // Owner reference (security)
final String workoutId;       // Parent workout reference
final String weekId;          // Grandparent week reference  
final String programId;       // Great-grandparent program reference
```

**Exercise Types**:

The `ExerciseType` enum defines validation rules and UI behavior:

```dart
enum ExerciseType {
  strength,    // Reps + optional weight + rest time
  cardio,      // Duration + optional distance  
  bodyweight,  // Reps + rest time
  custom,      // Flexible - at least one metric required
  timeBased;   // Alias for cardio/time-based exercises
}
```

**Type-Specific Field Requirements**:

| Exercise Type | Required Fields | Optional Fields | Duplication Behavior |
|---------------|----------------|-----------------|---------------------|
| `strength` | `reps` | `weight`, `restTime` | Keep all fields |
| `cardio` | `duration` | `distance` | Keep both fields |
| `bodyweight` | `reps` | `restTime` | Keep both fields |
| `custom` | Any metric | All fields | Keep all fields |
| `timeBased` | `duration` | `distance` | Keep both fields |

**Helper Methods**:
```dart
// Get required fields for UI validation
List<String> get requiredSetFields;

// Get optional fields for UI display  
List<String> get optionalSetFields;

// Validation
bool get isValidName => name.trim().isNotEmpty && name.trim().length <= 200;
```

**Usage Guidelines**:
```dart
// Creating a strength exercise
final exercise = Exercise(
  id: '',
  name: 'Bench Press',
  exerciseType: ExerciseType.strength,
  orderIndex: 0,
  notes: '3x8-10 reps, progressive overload',
  // ... other required fields
);

// Type-specific validation
final requiredFields = exercise.requiredSetFields; // ['reps']
final optionalFields = exercise.optionalSetFields; // ['weight', 'restTime']
```

### ExerciseSet

**Purpose**: Individual sets within exercises with type-specific validation

**Fields**:
```dart
final String id;          // Firestore document ID
final int setNumber;      // 1-based set number within exercise  
final int? reps;          // Number of repetitions (nullable)
final double? weight;     // Weight in kg (nullable)
final int? duration;      // Duration in seconds (nullable)
final double? distance;   // Distance in meters (nullable) 
final int? restTime;      // Rest time in seconds (nullable)
final bool checked;       // Completion status
final String? notes;      // Optional set notes
final DateTime createdAt; // Auto-generated
final DateTime updatedAt; // Auto-updated
final String userId;      // Owner reference (security)
final String exerciseId;  // Parent exercise reference
final String workoutId;   // Grandparent workout reference
final String weekId;      // Great-grandparent week reference
final String programId;   // Great-great-grandparent program reference
```

**Validation Methods**:

```dart
// Exercise type-specific validation
bool isValidForExerciseType(ExerciseType exerciseType);

// General metric requirement (at least one must be present)
bool get hasAtLeastOneMetric;

// Numeric field validation (all must be non-negative)
bool get hasValidNumericValues;

// Comprehensive validation
bool isValid(ExerciseType exerciseType);
```

**Validation Logic by Exercise Type**:

```dart
bool isValidForExerciseType(ExerciseType exerciseType) {
  switch (exerciseType) {
    case ExerciseType.strength:
      return reps != null && reps! > 0;
    case ExerciseType.cardio:
    case ExerciseType.timeBased:
      return duration != null && duration! > 0;
    case ExerciseType.bodyweight:
      return reps != null && reps! > 0;
    case ExerciseType.custom:
      return hasAtLeastOneMetric;
  }
}
```

**Duplication Support**:

The `createDuplicateCopy()` method implements the specification's duplication rules:

```dart
ExerciseSet createDuplicateCopy({
  required String newId,
  required String newExerciseId, 
  required String newWorkoutId,
  required String newWeekId,
  required String newProgramId,
  required ExerciseType exerciseType,
});
```

**Duplication Behavior by Exercise Type**:
- **Strength**: Reset `weight` to null, keep `reps` and `restTime`
- **Cardio/Time-based**: Keep `duration` and `distance`  
- **Bodyweight**: Keep `reps` and `restTime`
- **Custom**: Keep all fields
- **All types**: Reset `checked` to false, update timestamps

**Display Formatting**:

```dart  
String get displayString; // "12 reps × 100kg" or "30s × 2km"
```

Formats set data for UI display with appropriate units and separators.

**Usage Guidelines**:

```dart
// Creating a strength set
final set = ExerciseSet(
  id: '',
  setNumber: 1,
  reps: 12,
  weight: 100.0,
  restTime: 90,
  checked: false,
  // ... other required fields
);

// Validation for strength exercise
assert(set.isValidForExerciseType(ExerciseType.strength)); // true
assert(set.hasValidNumericValues); // true
assert(set.isValid(ExerciseType.strength)); // true

// Display formatting
print(set.displayString); // "12 reps × 100kg × rest: 90s"

// Duplication
final duplicatedSet = set.createDuplicateCopy(
  newId: 'new_set_id',
  newExerciseId: 'new_exercise_id',
  newWorkoutId: 'new_workout_id', 
  newWeekId: 'new_week_id',
  newProgramId: 'new_program_id',
  exerciseType: ExerciseType.strength,
);
// duplicatedSet.weight will be 135.0 (preserved for progressive overload)
// duplicatedSet.checked will be false
```

## Best Practices

### Model Creation
1. Always validate models before persisting to Firestore
2. Use factory constructors for Firestore deserialization  
3. Maintain parent ID references for security and querying
4. Set appropriate timestamps (usually server-side)

### Validation Strategy
```dart
// Client-side validation before save
if (!program.isValidName || !program.isValidDescription) {
  throw ValidationException('Invalid program data');
}

// Server-side validation in Firestore rules provides final security
```

### Error Handling
```dart
try {
  final program = Program.fromFirestore(doc);
} catch (e) {
  // Handle malformed data gracefully
  // Log error for debugging
  // Provide fallback values
}
```

### Immutability
```dart
// Correct: Create new instance
final updatedProgram = program.copyWith(
  name: 'New Program Name',
  updatedAt: DateTime.now(),
);

// Incorrect: Models are immutable
// program.name = 'New Name'; // Won't compile
```

### Type Safety
```dart
// Use enum values, not strings
final exercise = Exercise(
  exerciseType: ExerciseType.strength, // ✓
  // exerciseType: 'strength', // ✗
);

// Validate exercise type-specific requirements
final isValid = set.isValidForExerciseType(exercise.exerciseType);
```

## Security Considerations

### User ID Fields
Every model includes a `userId` field that must match `request.auth.uid`:
- Enables efficient user-scoped queries
- Provides defense-in-depth security  
- Simplifies Firestore security rules
- Required for all document operations

### Parent References
Models maintain references to all ancestor documents:
- Enables hierarchical security validation
- Supports efficient querying patterns
- Prevents unauthorized access to nested data
- Required for proper cascade operations

### Field Validation
- Client-side validation provides user feedback
- Server-side Firestore rules enforce final validation
- Both must align with technical specification
- All numeric fields validated as non-negative

## Testing Guidelines

### Unit Tests
Test each model's validation logic:
```dart
group('Program Model', () {
  test('validates name length', () {
    final program = Program(/* valid data */);
    expect(program.isValidName, isTrue);
    
    final invalidProgram = program.copyWith(name: 'x' * 101);
    expect(invalidProgram.isValidName, isFalse);
  });
  
  test('serializes to/from Firestore', () {
    final original = Program(/* test data */);
    final firestore = original.toFirestore();
    final doc = MockDocumentSnapshot(firestore);
    final deserialized = Program.fromFirestore(doc);
    
    expect(deserialized.name, equals(original.name));
  });
});
```

### Integration Tests  
Test with actual Firestore operations:
```dart
testWidgets('creates and retrieves program', (tester) async {
  final program = Program(/* test data */);
  final id = await FirestoreService.instance.createProgram(program);
  
  final retrieved = await FirestoreService.instance
      .getProgram(userId, id)
      .first;
      
  expect(retrieved?.name, equals(program.name));
});
```

### Validation Tests
Test exercise type-specific validation:
```dart
group('ExerciseSet Validation', () {
  test('strength sets require reps', () {
    final set = ExerciseSet(reps: null, /* other fields */);
    expect(set.isValidForExerciseType(ExerciseType.strength), isFalse);
    
    final validSet = set.copyWith(reps: 10);
    expect(validSet.isValidForExerciseType(ExerciseType.strength), isTrue);
  });
});
```

## Extension Guidelines

### Adding New Exercise Types
1. Add enum value to `ExerciseType`
2. Update `fromString()` and `toFirestore()` methods
3. Define required/optional fields in `Exercise` model
4. Add validation logic to `ExerciseSet.isValidForExerciseType()`
5. Update duplication logic in `createDuplicateCopy()`
6. Update Firestore security rules
7. Add comprehensive tests

### Adding Model Fields
1. Add field to model class with appropriate type
2. Update `fromFirestore()` with null handling and defaults  
3. Update `toFirestore()` method
4. Add field to `copyWith()` method
5. Update validation methods if needed
6. Add migration strategy for existing data
7. Update Firestore security rules if needed

### Model Relationships
When adding new hierarchical relationships:
1. Maintain parent ID references in child models
2. Update `fromFirestore()` to accept parent IDs
3. Add appropriate security validation
4. Consider cascade delete implications
5. Update FirestoreService query methods
6. Test hierarchical security rules

## Analytics Models

### WorkoutAnalytics
**Location**: `lib/models/analytics.dart`

Client-side computed analytics for workout performance tracking:

```dart
class WorkoutAnalytics {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalWorkouts;
  final int totalSets;
  final double totalVolume;
  final int totalDuration;
  final Map<ExerciseType, int> exerciseTypeBreakdown;
  final List<String> completedWorkoutIds;
}
```

**Key Features**:
- Computed from existing workout data
- Date range flexible analytics
- Exercise type distribution analysis
- Performance metrics calculation

### ActivityHeatmapData
**Location**: `lib/models/analytics.dart`

GitHub-style activity heatmap for workout consistency visualization:

```dart
class ActivityHeatmapData {
  final String userId;
  final int year;
  final Map<DateTime, int> dailyWorkoutCounts;
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
}
```

**Key Features**:
- Daily workout count tracking
- Streak calculation (current and longest)
- Yearly activity overview
- Heatmap intensity computation

### PersonalRecord
**Location**: `lib/models/analytics.dart`

Personal achievement tracking with improvement analysis:

```dart
class PersonalRecord {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final PRType prType;
  final double value;
  final double? previousValue;
  final DateTime achievedAt;
  final String workoutId;
  final String setId;
}
```

**Key Features**:
- Multiple PR types (weight, reps, volume, duration, distance)
- Improvement calculation
- Achievement timestamps
- Exercise-specific records

### Supporting Models

#### DateRange
Flexible date range utilities for analytics filtering:
```dart
class DateRange {
  final DateTime start;
  final DateTime end;
  // Factory methods: thisWeek(), thisMonth(), thisYear(), last30Days()
}
```

#### HeatmapDay & HeatmapIntensity
Daily activity representation for heatmap visualization:
```dart
class HeatmapDay {
  final DateTime date;
  final int workoutCount;
  final HeatmapIntensity intensity;
}

enum HeatmapIntensity { none, low, medium, high }
```

### Analytics Model Principles

1. **Client-Side Computation**: All analytics computed from existing data, no additional storage
2. **Real-time Accuracy**: Always computed from current dataset
3. **Performance Optimization**: Efficient algorithms with caching strategies
4. **Type Safety**: Strong typing for all analytics data
5. **Immutable Design**: Consistent with other application models

This documentation provides the foundation for understanding and extending the FitTrack data models while maintaining consistency with the technical specification and security requirements.