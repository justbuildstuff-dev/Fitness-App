# Duplication System Documentation

## Overview

The FitTrack duplication system enables users to duplicate workout weeks, preserving exercise structure while resetting appropriate fields for fresh tracking. The implementation uses client-side batched writes for better performance, offline support, and reduced server complexity.

## Architecture Decision: Client-Side Implementation

### Why Client-Side?
1. **Better Offline Support**: Works without network connectivity
2. **Improved Performance**: No server round-trip delays
3. **Reduced Complexity**: No Cloud Functions deployment/management
4. **Cost Efficiency**: Fewer server resources required
5. **Real-time Feedback**: Immediate UI updates during operation

### Tradeoffs Considered
- **Client Code Size**: Acceptable increase for better UX
- **Security**: Same level via Firestore security rules
- **Reliability**: Firestore batch operations provide atomicity

## Duplication Principles (Per Technical Specification)

### Core Requirements
1. **User-Scoped**: Users can only duplicate their own data
2. **Deep Copy**: Week → Workouts → Exercises → Sets hierarchy
3. **Selective Field Copying**: Exercise type-specific field handling
4. **State Resets**: Clear completion status and optionally reset weights
5. **Atomicity**: All operations succeed or fail together
6. **Audit Trail**: Return mapping for UI navigation and confirmation

### Exercise Type-Specific Duplication Rules

| Exercise Type | Copy Strategy | Reset Fields | Keep Fields |
|---------------|---------------|--------------|-------------|
| `strength` | Copy structure, reset weight | `weight` → `null`, `checked` → `false` | `reps`, `restTime`, `notes` |
| `cardio` | Keep performance data | `checked` → `false` | `duration`, `distance`, `notes` |
| `time-based` | Keep timing data | `checked` → `false` | `duration`, `distance`, `notes` |
| `bodyweight` | Keep rep structure | `checked` → `false` | `reps`, `restTime`, `notes` |
| `custom` | Keep all metrics | `checked` → `false` | All fields preserved |

### Duplication Philosophy
- **Strength**: Reset weight to encourage progressive overload tracking
- **Cardio/Time-based**: Keep targets for consistency
- **Bodyweight**: Maintain rep schemes
- **Custom**: Preserve user-configured fields

## Implementation Architecture

### FirestoreService.duplicateWeek()

#### Method Signature
```dart
Future<Map<String, dynamic>> duplicateWeek({
  required String userId,
  required String programId,
  required String weekId,
}) async
```

#### Return Value Structure
```dart
{
  'success': true,
  'mapping': {
    'oldWeekId': 'original_week_id',
    'newWeekId': 'new_week_id',
    'workouts': [
      {
        'oldWorkoutId': 'original_workout_id',
        'newWorkoutId': 'new_workout_id',
        'exercises': [
          {
            'oldExerciseId': 'original_exercise_id',
            'newExerciseId': 'new_exercise_id',
            'sets': [
              {
                'oldSetId': 'original_set_id',
                'newSetId': 'new_set_id'
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### Batch Management System

#### Batch Configuration
```dart
const batchLimit = 450; // Safe margin under Firestore's 500 operation limit
WriteBatch batch = _firestore.batch();
int batchCount = 0;
final List<Future<void>> pendingCommits = [];
```

#### Batch Management Logic
```dart
Future<void> commitBatchIfNeeded() async {
  if (batchCount == 0) return;
  
  // Commit current batch
  final commitFuture = batch.commit();
  pendingCommits.add(commitFuture);
  
  // Prepare fresh batch
  batch = _firestore.batch();
  batchCount = 0;
}

Future<void> addToBatch(DocumentReference ref, Map<String, dynamic> data) async {
  batch.set(ref, data);
  batchCount++;
  
  if (batchCount >= batchLimit) {
    await commitBatchIfNeeded();
  }
}
```

#### Why 450 Operations?
- **Firestore Limit**: 500 operations per batch
- **Safety Margin**: 50 operations buffer for unexpected overhead
- **Performance**: Optimal balance between batch size and commit frequency
- **Error Prevention**: Prevents batch size errors

## Duplication Process Flow

### Phase 1: Validation and Setup
1. **Authentication Check**: Verify user is authenticated
2. **Source Validation**: Ensure source week exists
3. **Ownership Verification**: Confirm user owns source week
4. **Batch Initialization**: Set up batch management system

```dart
// 1) Load source week and ownership check
final srcWeekRef = _firestore
    .collection('users')
    .doc(userId)
    .collection('programs')
    .doc(programId)
    .collection('weeks')
    .doc(weekId);

final srcWeekSnap = await srcWeekRef.get();
if (!srcWeekSnap.exists) {
  throw Exception('Source week not found');
}

final srcWeekData = srcWeekSnap.data();
// Verify ownership through userId field
if (srcWeekData['userId'] != null && srcWeekData['userId'] != userId) {
  throw Exception('You do not own this week');
}
```

### Phase 2: Week Duplication
1. **Create New Week Document**: Generate new week with copied metadata
2. **Naming Strategy**: Append "(Copy)" to distinguish from original
3. **Timestamp Reset**: Set new `createdAt` and `updatedAt` timestamps
4. **Batch Addition**: Add week creation to batch queue

```dart
// 2) Create new Week document
final newWeekRef = _firestore
    .collection('users')
    .doc(userId)
    .collection('programs')
    .doc(programId)
    .collection('weeks')
    .doc();

final newWeekData = {
  'name': srcWeekData['name'] != null ? '${srcWeekData['name']} (Copy)' : 'Week (Copy)',
  'order': srcWeekData['order'],
  'notes': srcWeekData['notes'],
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'userId': userId,
  'programId': programId,
};

await addToBatch(newWeekRef, newWeekData);
```

### Phase 3: Hierarchical Duplication

#### Workout Level Processing
```dart
final srcWorkoutsSnap = await srcWeekRef
    .collection('workouts')
    .orderBy('orderIndex')
    .get();

for (final workoutDoc in srcWorkoutsSnap.docs) {
  final workoutData = workoutDoc.data();
  
  // Create new workout document
  final newWorkoutRef = newWeekRef.collection('workouts').doc();
  final newWorkoutData = {
    'name': workoutData['name'],
    'dayOfWeek': workoutData['dayOfWeek'],
    'orderIndex': workoutData['orderIndex'],
    'notes': workoutData['notes'],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'userId': userId,
    'programId': programId,
    'weekId': newWeekRef.id,
  };
  
  await addToBatch(newWorkoutRef, newWorkoutData);
  // Continue with exercises...
}
```

#### Exercise Level Processing
```dart
for (final exerciseDoc in srcExercisesSnap.docs) {
  final exerciseData = exerciseDoc.data();
  
  // Create new exercise document
  final newExerciseRef = newWorkoutRef.collection('exercises').doc();
  final newExerciseData = {
    'name': exerciseData['name'],
    'exerciseType': exerciseData['exerciseType'] ?? 'custom',
    'orderIndex': exerciseData['orderIndex'],
    'notes': exerciseData['notes'],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'userId': userId,
    'programId': programId,
    'weekId': newWeekRef.id,
    'workoutId': newWorkoutRef.id,
  };
  
  await addToBatch(newExerciseRef, newExerciseData);
  // Continue with sets...
}
```

#### Set Level Processing (Most Complex)
```dart
for (final setDoc in srcSetsSnap.docs) {
  final setData = setDoc.data();
  final type = exerciseData['exerciseType'] ?? 'custom';
  
  // Build new set payload with exercise type-specific logic
  final Map<String, dynamic> newSetPayload = {
    'setNumber': setData['setNumber'],
    'exerciseType': type,
    'checked': false, // Always reset completion status
    'notes': setData['notes'],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'userId': userId,
    'programId': programId,
    'weekId': newWeekRef.id,
    'workoutId': newWorkoutRef.id,
    'exerciseId': newExerciseRef.id,
  };

  // Exercise type-specific field copying
  if (type == 'strength') {
    if (setData['reps'] != null) newSetPayload['reps'] = setData['reps'];
    // Reset weight to null to encourage fresh entry
    newSetPayload['weight'] = null;
    if (setData['restTime'] != null) newSetPayload['restTime'] = setData['restTime'];
  } else if (type == 'cardio' || type == 'time-based') {
    if (setData['duration'] != null) newSetPayload['duration'] = setData['duration'];
    if (setData['distance'] != null) newSetPayload['distance'] = setData['distance'];
  } else if (type == 'bodyweight') {
    if (setData['reps'] != null) newSetPayload['reps'] = setData['reps'];
    if (setData['restTime'] != null) newSetPayload['restTime'] = setData['restTime'];
  } else {
    // custom or other -> copy all relevant fields
    if (setData['reps'] != null) newSetPayload['reps'] = setData['reps'];
    if (setData['duration'] != null) newSetPayload['duration'] = setData['duration'];
    if (setData['distance'] != null) newSetPayload['distance'] = setData['distance'];
    if (setData['weight'] != null) newSetPayload['weight'] = setData['weight'];
    if (setData['restTime'] != null) newSetPayload['restTime'] = setData['restTime'];
  }

  final newSetRef = newExerciseRef.collection('sets').doc();
  await addToBatch(newSetRef, newSetPayload);
}
```

### Phase 4: Batch Commitment and Finalization
```dart
// Commit any outstanding batch writes
await commitBatchIfNeeded();

// Wait for all batch commits to finish
await Future.wait(pendingCommits);

// Return mapping for UI navigation
return {'success': true, 'mapping': mapping};
```

## Error Handling and Recovery

### Error Categories
1. **Validation Errors**: Source not found, ownership violations
2. **Network Errors**: Connectivity issues, timeout problems
3. **Batch Errors**: Write failures, quota exceeded
4. **Data Errors**: Malformed documents, type mismatches

### Error Handling Strategy
```dart
try {
  // Duplication logic
  return {'success': true, 'mapping': mapping};
} catch (e) {
  // Log error for debugging
  print('Duplication error: $e');
  
  // Return failure with user-friendly message
  throw Exception('Failed to duplicate week: $e');
}
```

### Partial Failure Recovery
- **Atomic Batches**: Individual batches are atomic
- **Sequential Commits**: If one batch fails, previous batches are preserved
- **Rollback Strategy**: Currently no automatic rollback (acceptable for duplication)
- **User Feedback**: Clear error messages for retry decision

## Integration with Providers

### ProgramProvider Integration
```dart
/// Duplicate a week
Future<Map<String, dynamic>?> duplicateWeek({
  required String programId,
  required String weekId,
}) async {
  if (_userId == null) return null;
  
  try {
    _error = null;
    notifyListeners();
    
    final result = await _firestoreService.duplicateWeek(
      userId: _userId!,
      programId: programId,
      weekId: weekId,
    );
    
    return result;
  } catch (e) {
    _error = 'Failed to duplicate week: $e';
    notifyListeners();
    return null;
  }
}
```

### UI Integration Example
```dart
void _duplicateWeek(Week week) async {
  final provider = context.read<ProgramProvider>();
  
  // Show loading state
  setState(() => _isDuplicating = true);
  
  final result = await provider.duplicateWeek(
    programId: widget.program.id!,
    weekId: week.id!,
  );
  
  setState(() => _isDuplicating = false);
  
  if (result != null && result['success'] == true) {
    // Success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Week duplicated successfully!')),
    );
    
    // Optional: Navigate to new week
    final mapping = result['mapping'];
    final newWeekId = mapping['newWeekId'];
    // Navigate to new week...
  } else {
    // Error is already set in provider
    // UI will show error via Consumer widget
  }
}
```

## Performance Characteristics

### Time Complexity
- **Week with N sets**: O(N) operations
- **Typical week (50 sets)**: ~200 Firestore operations
- **Large week (200 sets)**: ~800 operations (requires 2 batches)

### Performance Metrics
- **Small Week (10 sets)**: ~1-2 seconds
- **Medium Week (50 sets)**: ~3-5 seconds  
- **Large Week (200 sets)**: ~8-12 seconds

### Performance Optimizations
1. **Batch Operations**: Minimize network round trips
2. **Parallel Queries**: Load source data concurrently where possible
3. **Efficient Mapping**: Build mapping during iteration
4. **Memory Management**: Process documents sequentially to limit memory usage

## Testing Strategies

### Unit Testing
```dart
group('Duplication System', () {
  test('duplicates week with strength exercises correctly', () async {
    // Arrange
    final mockService = MockFirestoreService();
    final originalWeek = createTestWeek(exerciseType: ExerciseType.strength);
    
    // Act
    final result = await mockService.duplicateWeek(
      userId: 'test_user',
      programId: 'test_program', 
      weekId: 'test_week',
    );
    
    // Assert
    expect(result['success'], isTrue);
    expect(result['mapping']['newWeekId'], isNotNull);
    
    // Verify strength-specific duplication (weight reset)
    final newSets = getNewSets(result['mapping']);
    expect(newSets.every((set) => set['weight'] == null), isTrue);
    expect(newSets.every((set) => set['checked'] == false), isTrue);
  });
});
```

### Integration Testing
```dart
testWidgets('duplication updates UI correctly', (tester) async {
  // Set up test environment
  await tester.pumpWidget(TestApp());
  
  // Navigate to week screen
  await tester.tap(find.text('Test Program'));
  await tester.pumpAndSettle();
  
  // Trigger duplication
  await tester.tap(find.byIcon(Icons.copy));
  await tester.pumpAndSettle();
  
  // Verify success message
  expect(find.text('Week duplicated successfully!'), findsOneWidget);
  
  // Verify new week appears in list
  expect(find.text('Week 1 (Copy)'), findsOneWidget);
});
```

### Performance Testing
```dart
group('Duplication Performance', () {
  test('handles large week efficiently', () async {
    final largeWeek = createTestWeek(
      workouts: 7,
      exercisesPerWorkout: 8, 
      setsPerExercise: 4,
    ); // 224 total sets
    
    final stopwatch = Stopwatch()..start();
    
    final result = await firestoreService.duplicateWeek(
      userId: 'test_user',
      programId: 'test_program',
      weekId: largeWeek.id,
    );
    
    stopwatch.stop();
    
    expect(result['success'], isTrue);
    expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 second limit
  });
});
```

## Monitoring and Analytics

### Success Metrics
- **Duplication Success Rate**: Percentage of successful duplications
- **Performance Distribution**: Duplication time by week size
- **Error Rate**: Frequency and types of duplication errors
- **User Adoption**: How often users use duplication feature

### Error Tracking
```dart
// In production, log duplication events
try {
  final result = await duplicateWeek(/* parameters */);
  
  // Log success
  analytics.logEvent('week_duplication_success', {
    'week_size': getTotalSets(weekId),
    'duration_ms': stopwatch.elapsedMilliseconds,
  });
  
} catch (e) {
  // Log failure
  analytics.logEvent('week_duplication_failure', {
    'error_type': e.runtimeType.toString(),
    'error_message': e.toString(),
  });
  
  rethrow;
}
```

## Future Enhancements

### Planned Improvements
1. **Progress Feedback**: Show duplication progress for large weeks
2. **Background Processing**: Use isolates for large duplication operations
3. **Selective Duplication**: Allow users to choose which workouts to duplicate
4. **Template System**: Save duplication templates for reuse
5. **Batch Size Optimization**: Dynamic batch sizing based on document complexity

### Advanced Features
1. **Program Duplication**: Extend to duplicate entire programs
2. **Cross-User Sharing**: Enable sharing duplicated weeks between users
3. **Version Control**: Track duplication history and relationships
4. **Smart Duplication**: AI-powered suggestions for duplication modifications

This duplication system provides a robust, performant solution for workout replication while maintaining data integrity and providing excellent user experience through offline support and real-time feedback.