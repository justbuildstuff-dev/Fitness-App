# Firestore Security Rules Validation Strategy

## Overview

This document explains the validation strategy used in FitTrack's Firestore security rules, specifically how we handle optional and required fields to ensure proper data validation while allowing `null` values for optional fields.

## Problem Background

Firestore security rules have subtle behavior differences when handling:
- **Fields omitted entirely** from the document (undefined)
- **Fields explicitly set to null** in the document
- **Fields with actual values**

The original validation pattern `(!data.field || validation)` worked for omitted fields but failed when fields were explicitly set to `null`, causing permission denied errors.

## Standardized Validation Pattern

We now use explicit null checking patterns to clearly distinguish between required and optional fields:

### Required Fields Pattern
```javascript
(data.field != null && validation)
```

**Example:**
```javascript
(data.name != null && isString(data.name) && data.name.size() <= 100)
```

**Behavior:**
- ✅ Field has valid value: passes validation
- ❌ Field is `null`: fails validation (field is required)
- ❌ Field is omitted: fails validation (field is required)

### Optional Fields Pattern
```javascript
(data.field == null || validation)
```

**Example:**
```javascript
(data.description == null || isString(data.description) && data.description.size() <= 500)
```

**Behavior:**
- ✅ Field is `null`: passes validation (optional field)
- ✅ Field is omitted: passes validation (optional field)
- ✅ Field has valid value: passes validation
- ❌ Field has invalid value: fails validation

## Field Classifications by Model

### Program Model
```javascript
function validProgram(data) {
  return (data.name != null && isString(data.name) && data.name.size() <= 100)           // REQUIRED
    && (data.description == null || isString(data.description) && data.description.size() <= 500) // OPTIONAL
    && (data.createdAt != null && isTimestamp(data.createdAt))                           // REQUIRED
    && (data.updatedAt != null && isTimestamp(data.updatedAt))                           // REQUIRED
    && (data.userId != null && isString(data.userId))                                    // REQUIRED
    && (data.isArchived == null || isBoolean(data.isArchived));                          // OPTIONAL
}
```

**Field Classification:**
- **Required**: `name`, `createdAt`, `updatedAt`, `userId`
- **Optional**: `description`, `isArchived`

### Week Model
```javascript
function validWeek(data) {
  return (data.name != null && isString(data.name))                       // REQUIRED
    && (data.order != null && isNumber(data.order) && data.order >= 0)    // REQUIRED
    && (data.notes == null || isString(data.notes))                       // OPTIONAL
    && (data.createdAt != null && isTimestamp(data.createdAt))             // REQUIRED
    && (data.updatedAt != null && isTimestamp(data.updatedAt))             // REQUIRED
    && (data.userId != null && isString(data.userId))                      // REQUIRED
    && (data.programId != null && isString(data.programId));               // REQUIRED
}
```

**Field Classification:**
- **Required**: `name`, `order`, `createdAt`, `updatedAt`, `userId`, `programId`
- **Optional**: `notes`

### Workout Model
```javascript
function validWorkout(data) {
  return (data.name != null && isString(data.name) && data.name.size() <= 200)                          // REQUIRED
    && (data.orderIndex != null && isNumber(data.orderIndex))                                           // REQUIRED
    && (data.dayOfWeek == null || (isNumber(data.dayOfWeek) && data.dayOfWeek >= 1 && data.dayOfWeek <= 7)) // OPTIONAL
    && (data.notes == null || isString(data.notes))                                                     // OPTIONAL
    && (data.createdAt != null && isTimestamp(data.createdAt))                                           // REQUIRED
    && (data.updatedAt != null && isTimestamp(data.updatedAt))                                           // REQUIRED
    && (data.userId != null && isString(data.userId))                                                    // REQUIRED
    && (data.weekId != null && isString(data.weekId))                                                    // REQUIRED
    && (data.programId != null && isString(data.programId));                                             // REQUIRED
}
```

**Field Classification:**
- **Required**: `name`, `orderIndex`, `createdAt`, `updatedAt`, `userId`, `weekId`, `programId`
- **Optional**: `dayOfWeek`, `notes`

### Exercise Model
```javascript
function validExercise(data) {
  return (data.name != null && isString(data.name) && data.name.size() <= 200)                     // REQUIRED
    && (data.exerciseType != null && isString(data.exerciseType) && allowedExerciseType(data.exerciseType)) // REQUIRED
    && (data.orderIndex != null && isNumber(data.orderIndex))                                       // REQUIRED
    && (data.notes == null || isString(data.notes))                                                 // OPTIONAL
    && (data.createdAt != null && isTimestamp(data.createdAt))                                       // REQUIRED
    && (data.updatedAt != null && isTimestamp(data.updatedAt))                                       // REQUIRED
    && (data.userId != null && isString(data.userId))                                                // REQUIRED
    && (data.workoutId != null && isString(data.workoutId))                                          // REQUIRED
    && (data.weekId != null && isString(data.weekId))                                                // REQUIRED
    && (data.programId != null && isString(data.programId));                                         // REQUIRED
}
```

**Field Classification:**
- **Required**: `name`, `exerciseType`, `orderIndex`, `createdAt`, `updatedAt`, `userId`, `workoutId`, `weekId`, `programId`
- **Optional**: `notes`

### ExerciseSet Model
```javascript
function validSet(data) {
  // at least one of reps/duration/distance must be present
  let hasMetric = (data.reps != null) || (data.duration != null) || (data.distance != null);

  return (data.setNumber != null && isNumber(data.setNumber) && data.setNumber >= 0)  // REQUIRED
    && hasMetric                                                                       // SPECIAL: At least one metric required
    && (data.reps == null || isNumber(data.reps) && data.reps >= 0)                   // OPTIONAL
    && (data.weight == null || isNumber(data.weight) && data.weight >= 0)             // OPTIONAL
    && (data.duration == null || isNumber(data.duration) && data.duration >= 0)       // OPTIONAL
    && (data.distance == null || isNumber(data.distance) && data.distance >= 0)       // OPTIONAL
    && (data.restTime == null || isNumber(data.restTime) && data.restTime >= 0)       // OPTIONAL
    && (data.checked == null || isBoolean(data.checked))                              // OPTIONAL
    && (data.notes == null || isString(data.notes))                                   // OPTIONAL
    && (data.createdAt != null && isTimestamp(data.createdAt))                        // REQUIRED
    && (data.updatedAt != null && isTimestamp(data.updatedAt))                        // REQUIRED
    && (data.userId != null && isString(data.userId))                                 // REQUIRED
    && (data.exerciseId != null && isString(data.exerciseId))                         // REQUIRED
    && (data.workoutId != null && isString(data.workoutId))                           // REQUIRED
    && (data.weekId != null && isString(data.weekId))                                 // REQUIRED
    && (data.programId != null && isString(data.programId));                          // REQUIRED
}
```

**Field Classification:**
- **Required**: `setNumber`, `createdAt`, `updatedAt`, `userId`, `exerciseId`, `workoutId`, `weekId`, `programId`
- **Optional**: `reps`, `weight`, `duration`, `distance`, `restTime`, `checked`, `notes`
- **Special**: At least one of `reps`, `duration`, or `distance` must be non-null

### UserProfile Model
```javascript
function validUserProfile(data) {
  return (data.displayName == null || isString(data.displayName) && data.displayName.size() <= 100) // OPTIONAL
    && (data.email == null || isString(data.email))                                                  // OPTIONAL
    && (data.createdAt != null && isTimestamp(data.createdAt))                                        // REQUIRED
    && (data.lastLogin == null || isTimestamp(data.lastLogin))                                        // OPTIONAL
    && (data.settings == null || data.settings is map);                                              // OPTIONAL
}
```

**Field Classification:**
- **Required**: `createdAt`
- **Optional**: `displayName`, `email`, `lastLogin`, `settings`

## Client-Side Implementation Alignment

Our Dart models use the `toFirestore()` method to serialize data. The models correctly handle optional fields and **must include all hierarchical ID fields** required by security rules.

### Critical Implementation Requirements

All `toFirestore()` methods must include the hierarchical ID fields that the security rules validate:

```dart
// Workout model example  
Map<String, dynamic> toFirestore() {
  return {
    'name': name,              // Always present (required)
    'dayOfWeek': dayOfWeek,    // Can be null (optional)
    'orderIndex': orderIndex,  // Always present (required)
    'notes': notes,            // Can be null (optional)
    'createdAt': Timestamp.fromDate(createdAt),  // Always present (required)
    'updatedAt': Timestamp.fromDate(updatedAt),  // Always present (required)
    'userId': userId,          // Always present (required)
    'weekId': weekId,          // Always present (required) - CRITICAL
    'programId': programId,    // Always present (required) - CRITICAL
  };
}
```

```dart
// Exercise model example
Map<String, dynamic> toFirestore() {
  return {
    'name': name,
    'exerciseType': exerciseType.toFirestore(),
    'orderIndex': orderIndex,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'userId': userId,
    'workoutId': workoutId,    // Always present (required) - CRITICAL
    'weekId': weekId,          // Always present (required) - CRITICAL
    'programId': programId,    // Always present (required) - CRITICAL
  };
}
```

```dart
// ExerciseSet model example
Map<String, dynamic> toFirestore() {
  return {
    'setNumber': setNumber,
    'reps': reps,              // Can be null (optional)
    'weight': weight,          // Can be null (optional)
    'duration': duration,      // Can be null (optional)
    'distance': distance,      // Can be null (optional)
    'restTime': restTime,      // Can be null (optional)
    'checked': checked,        // Can be null (optional)
    'notes': notes,            // Can be null (optional)
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'userId': userId,
    'exerciseId': exerciseId,  // Always present (required) - CRITICAL
    'workoutId': workoutId,    // Always present (required) - CRITICAL
    'weekId': weekId,          // Always present (required) - CRITICAL
    'programId': programId,    // Always present (required) - CRITICAL
  };
}
```

### Key Points

1. **Hierarchical IDs are Required**: Security rules validate these fields as non-null
2. **Optional Fields**: When `description` or `notes` is `null`, it gets serialized as `null` in Firestore, not omitted entirely
3. **Validation Alignment**: Client serialization must match exactly what security rules expect

## Benefits of This Approach

1. **Explicit Intent**: Clear distinction between required and optional fields
2. **Null Safety**: Proper handling of `null` values for optional fields
3. **Type Safety**: Validation only runs when fields have values
4. **Consistency**: Same pattern used across all validation functions
5. **Maintainability**: Easy to understand and modify field requirements

## Migration Impact

This validation strategy addresses two critical issues that were causing permission denied errors:

### 1. Null Validation Fix
Fixed the regression where optional fields set to `null` were causing permission denied errors by updating the validation pattern from `(!data.field || validation)` to `(data.field == null || validation)`.

### 2. Missing Hierarchical ID Fields Fix
Fixed the critical issue where `toFirestore()` methods in Workout, Exercise, and ExerciseSet models were missing required hierarchical ID fields that security rules validate.

**The complete fix ensures:**

- ✅ Programs with empty descriptions can be created
- ✅ Exercises with null notes can be created  
- ✅ Sets with null optional metrics can be created
- ✅ Workouts include required `weekId` and `programId` fields
- ✅ Exercises include required `workoutId`, `weekId`, and `programId` fields
- ✅ Sets include required `exerciseId`, `workoutId`, `weekId`, and `programId` fields
- ✅ All existing functionality continues to work
- ✅ Type validation still enforces correct data types when values are provided

**Critical Note:** Without the hierarchical ID fields in `toFirestore()`, users would experience "Property weekId is undefined" errors even with proper null validation, as the security rules require these fields to enforce the hierarchical access control model.

## File Synchronization

The canonical security rules file:
- **Canonical Version**: `fittrack/firestore.rules`

Changes should be made directly to the fittrack version for deployment.

## Testing Strategy

The validation strategy is tested through:
1. **Unit Tests**: Model serialization tests verify correct `toFirestore()` behavior
2. **Integration Tests**: Firebase emulator tests with actual rule validation
3. **End-to-End Tests**: Complete user workflows with various field combinations

This validation strategy ensures robust, predictable behavior for all FitTrack data operations while maintaining flexibility for optional fields.