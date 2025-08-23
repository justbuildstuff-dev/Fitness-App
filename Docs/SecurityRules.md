# Security Rules Documentation

## Overview

The FitTrack application implements comprehensive Firestore security rules that enforce user-centric data isolation, validate document structure, and provide admin support capabilities. The security model follows the principle of least privilege with defense-in-depth validation at multiple layers.

## Security Architecture

### Core Security Principles

1. **User Data Isolation**: Each user can only access their own data
2. **Hierarchical Security**: Security follows the data hierarchy structure
3. **Defense in Depth**: Multiple validation layers for comprehensive protection
4. **Admin Support**: Controlled admin access for support operations
5. **Input Validation**: Server-side validation for all document fields

### Data Hierarchy and Security
```
users/{userId}/                    ← User can only access own documents
  programs/{programId}/            ← Owner and admin access
    weeks/{weekId}/                ← Inherits parent permissions
      workouts/{workoutId}/        ← Hierarchical security
        exercises/{exerciseId}/    ← Cascading validation
          sets/{setId}             ← Full field validation
```

## Security Rules Structure

### Helper Functions

#### Authentication Checks
```javascript
function isSignedIn() {
  return request.auth != null;
}

function isOwner(userId) {
  return isSignedIn() && request.auth.uid == userId;
}

function isAdmin() {
  return isSignedIn() && request.auth.token.admin == true;
}
```

#### Data Type Validation
```javascript
function isString(v) { return v is string; }
function isNumber(v) { return v is int || v is float; }
function isTimestamp(v) { return v is timestamp; }
function isBoolean(v) { return v is bool; }
```

#### Business Rule Validation
```javascript
function allowedExerciseType(t) {
  return t == 'strength' || t == 'cardio' || t == 'bodyweight' 
      || t == 'custom' || t == 'time-based';
}
```

### User Profile Security

#### Access Control
```javascript
match /users/{userId} {
  // Owner or admin can read user profile
  allow get: if isOwner(userId) || isAdmin();
  
  // Only admins can list users (support operations)
  allow list: if isAdmin();

  // Creation: only authenticated user can create own profile
  allow create: if isSignedIn() && request.auth.uid == userId 
                && validUserProfile(request.resource.data);

  // Updates: owner or admin can update
  allow update: if (isOwner(userId) || isAdmin()) 
                && validUserProfile(request.resource.data);

  // Deletion: admin only (safer than user self-deletion)
  allow delete: if isAdmin();
}
```

#### User Profile Validation
```javascript
function validUserProfile(data) {
  return (!data.displayName || isString(data.displayName) && data.displayName.size() <= 100)
    && (!data.email || isString(data.email))
    && (!data.createdAt || isTimestamp(data.createdAt))
    && (!data.lastLogin || isTimestamp(data.lastLogin))
    && (!data.settings || data.settings is map);
}
```

### Hierarchical Data Security

#### Program Level Security
```javascript
match /programs/{programId} {
  allow get, list: if isOwner(userId) || isAdmin();

  // Create: only owner can create with proper userId validation
  allow create: if isOwner(userId)
                && request.resource.data.userId == request.auth.uid
                && validProgram(request.resource.data);

  // Update/Delete: owner or admin
  allow update, delete: if (isOwner(userId) || isAdmin())
                        && validProgram(request.resource.data);
}
```

#### Week Level Security
```javascript
match /weeks/{weekId} {
  allow get, list: if isOwner(userId) || isAdmin();

  allow create: if isOwner(userId)
                && request.resource.data.userId == request.auth.uid
                && validWeek(request.resource.data);

  allow update, delete: if (isOwner(userId) || isAdmin())
                        && validWeek(request.resource.data);
}
```

#### Workout Level Security
```javascript
match /workouts/{workoutId} {
  allow get, list: if isOwner(userId) || isAdmin();

  allow create: if isOwner(userId)
                && request.resource.data.userId == request.auth.uid
                && validWorkout(request.resource.data);

  allow update, delete: if (isOwner(userId) || isAdmin())
                        && validWorkout(request.resource.data);
}
```

#### Exercise Level Security
```javascript
match /exercises/{exerciseId} {
  allow get, list: if isOwner(userId) || isAdmin();

  allow create: if isOwner(userId)
                && request.resource.data.userId == request.auth.uid
                && validExercise(request.resource.data);

  allow update, delete: if (isOwner(userId) || isAdmin())
                        && validExercise(request.resource.data);
}
```

#### Set Level Security
```javascript
match /sets/{setId} {
  allow get, list: if isOwner(userId) || isAdmin();

  allow create: if isOwner(userId)
                && request.resource.data.userId == request.auth.uid
                && validSet(request.resource.data);

  allow update, delete: if (isOwner(userId) || isAdmin())
                        && validSet(request.resource.data);
}
```

## Validation Functions

### Program Validation
```javascript
function validProgram(data) {
  return (!data.name || isString(data.name) && data.name.size() <= 100)
    && (!data.description || isString(data.description) && data.description.size() <= 500)
    && (!data.createdAt || isTimestamp(data.createdAt))
    && (!data.userId || isString(data.userId));
}
```

**Validation Rules**:
- `name`: Optional string, max 100 characters
- `description`: Optional string, max 500 characters  
- `createdAt`: Optional timestamp (server-generated)
- `userId`: Optional string (must match auth.uid if provided)

### Week Validation
```javascript
function validWeek(data) {
  return (!data.name || isString(data.name))
    && (!data.order || isNumber(data.order) && data.order >= 0)
    && (!data.createdAt || isTimestamp(data.createdAt))
    && (!data.userId || isString(data.userId));
}
```

**Validation Rules**:
- `name`: Optional string (any length)
- `order`: Optional number, must be >= 0 (1-based ordering)
- `createdAt`: Optional timestamp
- `userId`: Optional string

### Workout Validation
```javascript
function validWorkout(data) {
  return (!data.name || isString(data.name) && data.name.size() <= 200)
    && (!data.orderIndex || isNumber(data.orderIndex))
    && (!data.dayOfWeek || (isNumber(data.dayOfWeek) && data.dayOfWeek >= 1 && data.dayOfWeek <= 7))
    && (!data.notes || isString(data.notes))
    && (!data.userId || isString(data.userId));
}
```

**Validation Rules**:
- `name`: Optional string, max 200 characters
- `orderIndex`: Optional number (0-based)
- `dayOfWeek`: Optional number, 1-7 (Monday-Sunday)
- `notes`: Optional string (any length)
- `userId`: Optional string

### Exercise Validation
```javascript
function validExercise(data) {
  return (!data.name || isString(data.name) && data.name.size() <= 200)
    && (!data.exerciseType || (isString(data.exerciseType) && allowedExerciseType(data.exerciseType)))
    && (!data.orderIndex || isNumber(data.orderIndex))
    && (!data.notes || isString(data.notes))
    && (!data.userId || isString(data.userId));
}
```

**Validation Rules**:
- `name`: Optional string, max 200 characters
- `exerciseType`: Optional string, must be valid exercise type
- `orderIndex`: Optional number
- `notes`: Optional string
- `userId`: Optional string

**Valid Exercise Types**:
- `strength`: For weight-based exercises
- `cardio`: For cardiovascular exercises
- `bodyweight`: For bodyweight exercises
- `custom`: For user-defined exercises
- `time-based`: For time-based exercises

### Set Validation (Most Complex)
```javascript
function validSet(data) {
  // At least one metric must be present
  let hasMetric = (data.reps != null) || (data.duration != null) || (data.distance != null);

  return (!data.setNumber || isNumber(data.setNumber) && data.setNumber >= 0)
    && hasMetric
    && (!data.reps || isNumber(data.reps) && data.reps >= 0)
    && (!data.weight || isNumber(data.weight) && data.weight >= 0)
    && (!data.duration || isNumber(data.duration) && data.duration >= 0)
    && (!data.distance || isNumber(data.distance) && data.distance >= 0)
    && (!data.restTime || isNumber(data.restTime) && data.restTime >= 0)
    && (!data.userId || isString(data.userId));
}
```

**Validation Rules**:
- `setNumber`: Optional number, must be >= 0
- **Metric Requirement**: At least one of `reps`, `duration`, or `distance` must be present
- `reps`: Optional number, must be >= 0
- `weight`: Optional number, must be >= 0
- `duration`: Optional number (seconds), must be >= 0
- `distance`: Optional number (meters), must be >= 0
- `restTime`: Optional number (seconds), must be >= 0
- `userId`: Optional string

## Admin Support Features

### Admin Access Control
```javascript
function isAdmin() {
  return isSignedIn() && request.auth.token.admin == true;
}
```

#### Admin Capabilities
1. **Read Access**: Admins can read any user's data for support
2. **User Management**: Admins can list users and access profiles
3. **Data Operations**: Admins can update/delete any document
4. **Duplication Management**: Admins can manage duplication requests
5. **Audit Access**: Admins can read duplication logs

#### Setting Admin Claims
Admin privileges are granted through Firebase Auth custom claims:

```javascript
// Firebase Admin SDK (server-side)
await admin.auth().setCustomUserClaims(uid, { admin: true });
```

### Duplication Request Security

#### Duplication Request Rules
```javascript
match /duplicationRequests/{requestId} {
  // Creation: only owner can create with proper validation
  allow create: if isOwner(userId)
                && request.resource.data.userId == request.auth.uid
                && validDuplicationRequest(request.resource.data);

  // Read: owner can read own requests, admins can read all
  allow get: if isOwner(userId) || isAdmin();
  allow list: if isOwner(userId) || isAdmin();

  // Update/Delete: only admin can modify (prevents client tampering)
  allow update, delete: if isAdmin();
}
```

#### Duplication Request Validation
```javascript
function validDuplicationRequest(data) {
  return (data.userId == request.auth.uid)
    && (data.requestTs is timestamp)
    && (data.programId == null || isString(data.programId))
    && (data.weekId == null || isString(data.weekId))
    && (data.entityType == null || (data.entityType in ['program', 'week', 'workout', 'exercise']));
}
```

### Audit Logging Security

#### Duplication Log Rules
```javascript
match /duplicationLogs/{logId} {
  // Creation: only admin (server) can create logs
  allow create: if isAdmin();
  
  // Read: owner can read own logs, admins can read all
  allow get: if isOwner(userId) || isAdmin();
  allow list: if isAdmin();
  
  // Update/Delete: only admin
  allow update, delete: if isAdmin();
}
```

## Security Best Practices

### Client-Side Security
```javascript
// Always validate userId matches authenticated user
allow create: if isOwner(userId)
              && request.resource.data.userId == request.auth.uid
              && validationFunction(request.resource.data);
```

### Server-Side Security
```javascript
// Use server timestamps to prevent client manipulation
createdAt: admin.firestore.FieldValue.serverTimestamp()

// Validate all fields even if optional
function validProgram(data) {
  return (!data.name || isString(data.name) && data.name.size() <= 100)
    // ... other validations
}
```

### Defense in Depth
1. **Client Validation**: Immediate user feedback
2. **Firestore Rules**: Server-side enforcement
3. **Admin SDK**: Privileged operations validation
4. **Audit Logging**: Security event tracking

## Testing Security Rules

### Firebase Emulator Testing
```javascript
// rules-test.js
import { assertSucceeds, assertFails } from '@firebase/rules-unit-testing';

describe('Program Security', () => {
  test('allows user to create own program', async () => {
    const db = getAuthedDb('user123');
    await assertSucceeds(
      db.collection('users/user123/programs').add({
        name: 'Test Program',
        userId: 'user123',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      })
    );
  });

  test('denies user creating program for another user', async () => {
    const db = getAuthedDb('user123');
    await assertFails(
      db.collection('users/user456/programs').add({
        name: 'Test Program',
        userId: 'user456',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      })
    );
  });
});
```

### Integration Testing
```dart
// Flutter integration tests
testWidgets('security rules prevent unauthorized access', (tester) async {
  // Sign in as user1
  await signInTestUser('user1@example.com');
  
  // Try to access user2's data - should fail
  expect(
    () => FirestoreService.instance.getPrograms('user2_id'),
    throwsA(isA<FirebaseException>()),
  );
});
```

## Deployment and Monitoring

### Security Rules Deployment
```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Validate rules before deployment
firebase firestore:rules:get

# Test rules with emulator
firebase emulators:exec --only firestore "npm test"
```

### Security Monitoring
1. **Firebase Console**: Monitor rule violations
2. **Cloud Logging**: Track security events
3. **Audit Trails**: Monitor admin operations
4. **Performance Impact**: Monitor rule evaluation performance

### Rule Updates
1. **Version Control**: All rules in source control
2. **Testing**: Comprehensive test suite before deployment
3. **Staging**: Test in staging environment first
4. **Rollback**: Plan for quick rollback if issues occur

## Common Security Patterns

### User Ownership Validation
```javascript
// Pattern for all user data
allow read, write: if isOwner(userId)
                   && request.resource.data.userId == request.auth.uid;
```

### Hierarchical Permission Inheritance
```javascript
// Child collections inherit parent security
match /users/{userId}/programs/{programId}/weeks/{weekId} {
  // Inherits userId check from parent path
  allow read, write: if isOwner(userId);
}
```

### Field-Level Validation
```javascript
// Validate individual fields with type checking
function validDocument(data) {
  return (!data.field1 || isString(data.field1))
    && (!data.field2 || isNumber(data.field2) && data.field2 >= 0)
    && (!data.field3 || data.field3 in ['value1', 'value2']);
}
```

### Admin Override Pattern
```javascript
// Allow owner or admin access
allow read, write: if isOwner(userId) || isAdmin();
```

This comprehensive security rules system ensures data isolation, validates all inputs, provides admin support capabilities, and maintains audit trails for the FitTrack application while following security best practices.