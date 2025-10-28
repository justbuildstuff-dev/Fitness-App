# Delete Functionality Fix - Technical Design

**Feature:** Fix Delete Functionality for Weeks, Workouts, and Exercises
**Issue:** #49
**Priority:** HIGH
**Type:** Bug Fix
**Created:** 2025-01-26
**Status:** Design Phase

---

## Table of Contents
1. [Overview](#overview)
2. [Root Cause Analysis](#root-cause-analysis)
3. [Technical Architecture](#technical-architecture)
4. [Implementation Details](#implementation-details)
5. [Testing Strategy](#testing-strategy)
6. [Rollout Plan](#rollout-plan)

---

## Overview

### Problem Statement
Users cannot delete weeks, workouts, or exercises. When attempting deletion:
- **Weeks & Workouts**: Screen flashes but deletion doesn't occur
- **Exercises**: Error message appears: "Failed to delete exercise: No Workout selected"
- Confirmation dialogs lack cascade information (e.g., "This will delete X workouts, Y exercises, Z sets")

### Goals
1. Fix context/state management issues preventing deletions
2. Add cascade count information to confirmation dialogs
3. Ensure proper loading states and error feedback
4. Maintain data integrity with batched atomic operations

### Non-Goals
- Implementing undo functionality
- Soft delete (archive) for weeks/workouts/exercises
- Bulk delete operations
- Delete animations or transitions

---

## Root Cause Analysis

### Current Implementation Status

**What Works:**
- ✅ Cascade delete logic exists in `FirestoreService`:
  - `_deleteWeekCascade()` (lines 374-448)
  - `_deleteWorkoutCascade()` (lines 778-852)
  - `_deleteExerciseCascade()` (lines 992-1061)
- ✅ All methods use batched writes (≤450 operations per batch)
- ✅ Provider methods wrap Firestore calls properly
- ✅ Some screens already use `DeleteConfirmationDialog`

**What's Broken:**

1. **Missing Context in Some Delete Calls**
   - `ProgramProvider.deleteWeekById()` requires `_selectedProgram` (line 396)
   - `ProgramProvider.deleteWorkoutById()` requires `_selectedProgram` and `_selectedWeek` (lines 613-614)
   - `ProgramProvider.deleteExerciseById()` requires `_selectedProgram`, `_selectedWeek`, and `_selectedWorkout` (lines 799-800)
   - **Issue**: If user navigates to delete screen without proper selection chain, context is missing

2. **Inconsistent Delete Button Locations**
   - **Program Detail Screen** ([program_detail_screen.dart:442-445](../../fittrack/lib/screens/programs/program_detail_screen.dart#L442-L445)):
     - Inline delete buttons on week cards
     - Uses `deleteWeekById()` which requires `_selectedProgram`
   - **Weeks Screen** ([weeks_screen.dart:331-333](../../fittrack/lib/screens/weeks/weeks_screen.dart#L331-L333)):
     - Menu delete option
     - Uses `deleteWeek(programId, weekId)` with explicit IDs

3. **Confirmation Dialogs Missing Cascade Information**
   - Current dialogs show generic warnings
   - Don't display child count (e.g., "This will delete 5 workouts, 15 exercises, 45 sets")
   - No way to calculate counts before showing dialog

4. **Error Handling Issues**
   - "Failed to delete exercise: No Workout selected" → thrown when `_selectedWorkout == null`
   - Error occurs in `updateExerciseFields()` (line 769) and `deleteExerciseById()` (line 800)
   - If user navigates directly to exercise detail screen, workout may not be selected

### Why Screen Flashes Without Deletion

When delete is clicked:
1. Delete method called
2. If context (programId, weekId, etc.) is missing → exception thrown
3. Provider sets `_error` state
4. UI rebuilds due to `notifyListeners()`
5. Error state not displayed (no error UI in card widgets)
6. Result: Screen flash (rebuild) but no deletion, no visible error

---

## Technical Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          UI Layer                                │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐  │
│  │ Program Screen │  │  Week Screen   │  │ Workout Screen   │  │
│  │                │  │                │  │                  │  │
│  │ [Week Cards]   │  │[Workout Cards] │  │[Exercise Cards]  │  │
│  │  - Delete Btn  │  │  - Delete Btn  │  │  - Delete Btn    │  │
│  └────────┬───────┘  └────────┬───────┘  └────────┬─────────┘  │
└───────────┼──────────────────┼──────────────────┼──────────────┘
            │                   │                   │
            ▼                   ▼                   ▼
┌───────────────────────────────────────────────────────────────┐
│                    Enhanced Confirmation Dialog                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Delete Week "Week 1"?                                   │ │
│  │                                                           │ │
│  │  This will delete:                                       │ │
│  │  • 3 workouts                                            │ │
│  │  • 9 exercises                                           │ │
│  │  • 27 sets                                               │ │
│  │                                                           │ │
│  │  This action cannot be undone.                           │ │
│  │                                                           │ │
│  │         [Cancel]              [Delete]                   │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────┬──────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                    Provider Layer                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              ProgramProvider                              │  │
│  │                                                           │  │
│  │  NEW: getDeleteCounts(type, ids) → CascadeDeleteCounts   │  │
│  │  FIX: deleteWeekById() → check & use context             │  │
│  │  FIX: deleteWorkoutById() → check & use context          │  │
│  │  FIX: deleteExerciseById() → check & use context         │  │
│  └──────────────────────────┬────────────────────────────────┘  │
└─────────────────────────────┼──────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                    Service Layer                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              FirestoreService                             │  │
│  │                                                           │  │
│  │  NEW: countWorkoutsInWeek(userId, programId, weekId)     │  │
│  │  NEW: countExercisesInWorkout(...)                       │  │
│  │  NEW: countSetsInExercise(...)                           │  │
│  │  NEW: getCascadeDeleteCounts(type, ids) → counts         │  │
│  │                                                           │  │
│  │  EXISTING (No Changes):                                  │  │
│  │  • _deleteWeekCascade() - batched writes                 │  │
│  │  • _deleteWorkoutCascade() - batched writes              │  │
│  │  • _deleteExerciseCascade() - batched writes             │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### Data Flow

**Delete Flow (After Fix):**

```
1. User clicks delete button
   ↓
2. UI calls getCascadeDeleteCounts() to fetch child counts
   ↓
3. Show Enhanced Confirmation Dialog with counts
   ↓
4. User confirms deletion
   ↓
5. UI shows loading indicator (disable buttons)
   ↓
6. Call deleteXById() with proper context
   ↓
7. Provider validates context (programId, weekId, etc.)
   ↓
8. FirestoreService executes cascade delete (batched writes)
   ↓
9. Stream updates trigger UI refresh (item disappears)
   ↓
10. Show success snackbar
```

**Error Flow:**

```
1. Delete operation fails (network, permissions, etc.)
   ↓
2. Provider catches exception, sets _error state
   ↓
3. UI displays error snackbar with message
   ↓
4. Loading indicator removed, buttons re-enabled
   ↓
5. User can retry or cancel
```

---

## Implementation Details

### 1. New Model: CascadeDeleteCounts

**File:** `fittrack/lib/models/cascade_delete_counts.dart` (NEW)

```dart
/// Represents the count of child entities that will be deleted
/// in a cascade delete operation
class CascadeDeleteCounts {
  final int workouts;
  final int exercises;
  final int sets;

  const CascadeDeleteCounts({
    this.workouts = 0,
    this.exercises = 0,
    this.sets = 0,
  });

  /// Total number of items that will be deleted
  int get totalItems => workouts + exercises + sets;

  /// Whether any items will be deleted
  bool get hasItems => totalItems > 0;

  /// Human-readable summary for confirmation dialogs
  String getSummary() {
    final List<String> parts = [];
    if (workouts > 0) parts.add('$workouts workout${workouts > 1 ? 's' : ''}');
    if (exercises > 0) parts.add('$exercises exercise${exercises > 1 ? 's' : ''}');
    if (sets > 0) parts.add('$sets set${sets > 1 ? 's' : ''}');
    return parts.join(', ');
  }
}
```

**Rationale:** Encapsulates cascade count logic, provides formatted summary for UI.

---

### 2. FirestoreService Enhancements

**File:** `fittrack/lib/services/firestore_service.dart`

#### 2.1 Count Methods (NEW)

```dart
/// Count workouts in a week
Future<int> countWorkoutsInWeek(
  String userId,
  String programId,
  String weekId,
) async {
  final snapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('programs')
      .doc(programId)
      .collection('weeks')
      .doc(weekId)
      .collection('workouts')
      .count()
      .get();
  return snapshot.count ?? 0;
}

/// Count exercises in a workout
Future<int> countExercisesInWorkout(
  String userId,
  String programId,
  String weekId,
  String workoutId,
) async {
  final snapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('programs')
      .doc(programId)
      .collection('weeks')
      .doc(weekId)
      .collection('workouts')
      .doc(workoutId)
      .collection('exercises')
      .count()
      .get();
  return snapshot.count ?? 0;
}

/// Count sets in an exercise
Future<int> countSetsInExercise(
  String userId,
  String programId,
  String weekId,
  String workoutId,
  String exerciseId,
) async {
  final snapshot = await _firestore
      .collection('users')
      .doc(userId)
      .collection('programs')
      .doc(programId)
      .collection('weeks')
      .doc(weekId)
      .collection('workouts')
      .doc(workoutId)
      .collection('exercises')
      .doc(exerciseId)
      .collection('sets')
      .count()
      .get();
  return snapshot.count ?? 0;
}
```

#### 2.2 Cascade Count Aggregation (NEW)

```dart
/// Get counts of all child entities that will be deleted
Future<CascadeDeleteCounts> getCascadeDeleteCounts({
  required String userId,
  required String programId,
  String? weekId,
  String? workoutId,
  String? exerciseId,
}) async {
  try {
    // Deleting a week
    if (weekId != null && workoutId == null && exerciseId == null) {
      int totalExercises = 0;
      int totalSets = 0;

      // Get all workouts in week
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .get();

      final workoutCount = workoutsSnapshot.docs.length;

      // For each workout, count exercises and sets
      for (final workoutDoc in workoutsSnapshot.docs) {
        final exercisesSnapshot = await workoutDoc.reference
            .collection('exercises')
            .get();

        totalExercises += exercisesSnapshot.docs.length;

        for (final exerciseDoc in exercisesSnapshot.docs) {
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .count()
              .get();
          totalSets += (setsSnapshot.count ?? 0);
        }
      }

      return CascadeDeleteCounts(
        workouts: workoutCount,
        exercises: totalExercises,
        sets: totalSets,
      );
    }

    // Deleting a workout
    if (weekId != null && workoutId != null && exerciseId == null) {
      int totalExercises = 0;
      int totalSets = 0;

      final exercisesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .get();

      totalExercises = exercisesSnapshot.docs.length;

      for (final exerciseDoc in exercisesSnapshot.docs) {
        final setsSnapshot = await exerciseDoc.reference
            .collection('sets')
            .count()
            .get();
        totalSets += (setsSnapshot.count ?? 0);
      }

      return CascadeDeleteCounts(
        exercises: totalExercises,
        sets: totalSets,
      );
    }

    // Deleting an exercise
    if (weekId != null && workoutId != null && exerciseId != null) {
      final setsCount = await countSetsInExercise(
        userId,
        programId,
        weekId,
        workoutId,
        exerciseId,
      );

      return CascadeDeleteCounts(sets: setsCount);
    }

    // Invalid parameters
    return const CascadeDeleteCounts();
  } catch (e) {
    debugPrint('Error getting cascade delete counts: $e');
    return const CascadeDeleteCounts();
  }
}
```

**Rationale:**
- Uses Firestore `.count()` queries for efficiency (doesn't fetch full documents)
- Handles all three deletion scenarios (week, workout, exercise)
- Returns zero counts on error (graceful degradation - dialog still shows warning)

---

### 3. ProgramProvider Enhancements

**File:** `fittrack/lib/providers/program_provider.dart`

#### 3.1 New Method: getCascadeDeleteCounts

```dart
/// Get cascade delete counts for confirmation dialogs
Future<CascadeDeleteCounts> getCascadeDeleteCounts({
  String? weekId,
  String? workoutId,
  String? exerciseId,
}) async {
  if (_userId == null) return const CascadeDeleteCounts();

  String? programId;
  String? resolvedWeekId = weekId;
  String? resolvedWorkoutId = workoutId;

  // Determine programId and resolve IDs based on context
  if (exerciseId != null) {
    // Deleting exercise - need program, week, workout, exercise IDs
    if (_selectedProgram == null || _selectedWeek == null || _selectedWorkout == null) {
      return const CascadeDeleteCounts();
    }
    programId = _selectedProgram!.id;
    resolvedWeekId = _selectedWeek!.id;
    resolvedWorkoutId = _selectedWorkout!.id;
  } else if (workoutId != null) {
    // Deleting workout - need program, week, workout IDs
    if (_selectedProgram == null || _selectedWeek == null) {
      return const CascadeDeleteCounts();
    }
    programId = _selectedProgram!.id;
    resolvedWeekId = _selectedWeek!.id;
  } else if (weekId != null) {
    // Deleting week - need program, week IDs
    if (_selectedProgram == null) {
      return const CascadeDeleteCounts();
    }
    programId = _selectedProgram!.id;
  } else {
    return const CascadeDeleteCounts();
  }

  return await _firestoreService.getCascadeDeleteCounts(
    userId: _userId!,
    programId: programId!,
    weekId: resolvedWeekId,
    workoutId: resolvedWorkoutId,
    exerciseId: exerciseId,
  );
}
```

#### 3.2 Fix: deleteWeekById with Context Validation

```dart
/// Delete a week by ID (with exception throwing for UI error handling)
Future<void> deleteWeekById(String weekId) async {
  if (_userId == null) throw Exception('User not authenticated');
  if (_selectedProgram == null) throw Exception('No program selected');

  try {
    _error = null;
    notifyListeners();

    await _firestoreService.deleteWeek(_userId!, _selectedProgram!.id, weekId);

    // Weeks will be automatically updated via the stream
  } catch (e) {
    _error = 'Failed to delete week: $e';
    notifyListeners();
    rethrow;
  }
}
```

**Change:** No code changes needed - already validates `_selectedProgram`

#### 3.3 Fix: deleteWorkoutById with Context Validation

```dart
/// Delete a workout by ID (with exception throwing for UI error handling)
Future<void> deleteWorkoutById(String workoutId) async {
  if (_userId == null) throw Exception('User not authenticated');
  if (_selectedProgram == null) throw Exception('No program selected');
  if (_selectedWeek == null) throw Exception('No week selected');

  try {
    _error = null;
    notifyListeners();

    await _firestoreService.deleteWorkout(
      _userId!,
      _selectedProgram!.id,
      _selectedWeek!.id,
      workoutId,
    );

    // Workouts will be automatically updated via the stream
  } catch (e) {
    _error = 'Failed to delete workout: $e';
    notifyListeners();
    rethrow;
  }
}
```

**Change:** No code changes needed - already validates both `_selectedProgram` and `_selectedWeek`

#### 3.4 Fix: deleteExerciseById with Context Validation

```dart
/// Delete an exercise by ID (with exception throwing for UI error handling)
Future<void> deleteExerciseById(String exerciseId) async {
  if (_userId == null) throw Exception('User not authenticated');
  if (_selectedProgram == null) throw Exception('No program selected');
  if (_selectedWeek == null) throw Exception('No week selected');
  if (_selectedWorkout == null) throw Exception('No workout selected');

  try {
    _error = null;
    notifyListeners();

    await _firestoreService.deleteExercise(
      _userId!,
      _selectedProgram!.id,
      _selectedWeek!.id,
      _selectedWorkout!.id,
      exerciseId,
    );

    // Exercises will be automatically updated via the stream
  } catch (e) {
    _error = 'Failed to delete exercise: $e';
    notifyListeners();
    rethrow;
  }
}
```

**Change:** No code changes needed - already validates all required context

**Root Cause Fix:** The validation is already in place. The real issue is that the UI doesn't ensure proper selection chain before calling delete. See UI fixes below.

---

### 4. Enhanced Delete Confirmation Dialog

**File:** `fittrack/lib/widgets/delete_confirmation_dialog.dart`

#### 4.1 Enhanced Dialog Widget (REPLACE EXISTING)

```dart
import 'package:flutter/material.dart';
import '../models/cascade_delete_counts.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? itemName;
  final String deleteButtonText;
  final VoidCallback? onConfirm;
  final CascadeDeleteCounts? cascadeCounts;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.itemName,
    this.deleteButtonText = 'Delete',
    this.onConfirm,
    this.cascadeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content),

          // Item name highlight
          if (itemName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                itemName!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],

          // Cascade count information
          if (cascadeCounts != null && cascadeCounts!.hasItems) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will delete:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (cascadeCounts!.workouts > 0)
                    _buildCountRow(
                      context,
                      Icons.fitness_center,
                      '${cascadeCounts!.workouts} workout${cascadeCounts!.workouts > 1 ? 's' : ''}',
                    ),
                  if (cascadeCounts!.exercises > 0)
                    _buildCountRow(
                      context,
                      Icons.list,
                      '${cascadeCounts!.exercises} exercise${cascadeCounts!.exercises > 1 ? 's' : ''}',
                    ),
                  if (cascadeCounts!.sets > 0)
                    _buildCountRow(
                      context,
                      Icons.format_list_numbered,
                      '${cascadeCounts!.sets} set${cascadeCounts!.sets > 1 ? 's' : ''}',
                    ),
                ],
              ),
            ),
          ],

          // Warning message
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'This action cannot be undone.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(deleteButtonText),
        ),
      ],
    );
  }

  Widget _buildCountRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// Show enhanced delete confirmation dialog with cascade counts
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? itemName,
    String deleteButtonText = 'Delete',
    CascadeDeleteCounts? cascadeCounts,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        content: content,
        itemName: itemName,
        deleteButtonText: deleteButtonText,
        cascadeCounts: cascadeCounts,
      ),
    );
  }
}
```

**Changes:**
- Added `cascadeCounts` parameter
- Display cascade count information in highlighted box
- Icons for each entity type (workouts, exercises, sets)
- "This action cannot be undone" warning

---

### 5. UI Screen Fixes

#### 5.1 Program Detail Screen - Week Delete

**File:** `fittrack/lib/screens/programs/program_detail_screen.dart`

**Location:** `_WeekCard._deleteWeek()` method (lines 470-507)

**Current Code:**
```dart
void _deleteWeek(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Week',
    content: 'This will permanently delete "${week.name}" and all its workouts, '
             'exercises, and sets. This action cannot be undone.',
    deleteButtonText: 'Delete Week',
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteWeekById(week.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Week "${week.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete week: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

**Fixed Code:**
```dart
void _deleteWeek(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  // Fetch cascade counts before showing dialog
  final cascadeCounts = await programProvider.getCascadeDeleteCounts(
    weekId: week.id,
  );

  if (!context.mounted) return;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Week',
    content: 'Are you sure you want to delete this week?',
    itemName: week.name,
    deleteButtonText: 'Delete Week',
    cascadeCounts: cascadeCounts,
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteWeekById(week.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Week "${week.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete week: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

**Changes:**
1. Fetch cascade counts before showing dialog
2. Pass counts to dialog
3. Simplified content message (dialog now shows counts)
4. Added `itemName` parameter for visual highlight

#### 5.2 Weeks Screen - Week Delete (Menu)

**File:** `fittrack/lib/screens/weeks/weeks_screen.dart`

**Location:** `_showDeleteDialog()` method (lines 337-384)

**Current Code:**
```dart
void _showDeleteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Week'),
      content: Text(
        'Are you sure you want to delete "${widget.week.name}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final programProvider = Provider.of<ProgramProvider>(context, listen: false);
            final success = await programProvider.deleteWeek(widget.program.id, widget.week.id);

            if (context.mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Week deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop(); // Go back to program detail
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(programProvider.error ?? 'Failed to delete week'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('DELETE'),
        ),
      ],
    ),
  );
}
```

**Fixed Code:**
```dart
void _showDeleteDialog(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  // Fetch cascade counts
  final cascadeCounts = await programProvider.getCascadeDeleteCounts(
    weekId: widget.week.id,
  );

  if (!context.mounted) return;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Week',
    content: 'Are you sure you want to delete this week?',
    itemName: widget.week.name,
    deleteButtonText: 'Delete Week',
    cascadeCounts: cascadeCounts,
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteWeekById(widget.week.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Week "${widget.week.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop(); // Go back to program detail
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete week: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

**Changes:**
1. Changed from `showDialog` to enhanced `DeleteConfirmationDialog.show`
2. Fetch cascade counts before dialog
3. Use try-catch with exception handling (deleteWeekById throws exceptions)
4. Consistent error messaging

#### 5.3 Weeks Screen - Workout Delete (Inline)

**File:** `fittrack/lib/screens/weeks/weeks_screen.dart`

**Location:** `_WorkoutCard._deleteWorkout()` method (lines 538-575)

**Current Code:**
```dart
void _deleteWorkout(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Workout',
    content: 'This will permanently delete "${workout.name}" and all its exercises '
             'and sets. This action cannot be undone.',
    deleteButtonText: 'Delete Workout',
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteWorkoutById(workout.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Workout "${workout.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete workout: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

**Fixed Code:**
```dart
void _deleteWorkout(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  // Fetch cascade counts
  final cascadeCounts = await programProvider.getCascadeDeleteCounts(
    workoutId: workout.id,
  );

  if (!context.mounted) return;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Workout',
    content: 'Are you sure you want to delete this workout?',
    itemName: workout.name,
    deleteButtonText: 'Delete Workout',
    cascadeCounts: cascadeCounts,
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteWorkoutById(workout.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Workout "${workout.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete workout: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

**Changes:**
1. Fetch cascade counts before dialog
2. Simplified content, added itemName
3. Pass cascadeCounts to dialog

#### 5.4 Workout Detail Screen - Workout Delete (Menu)

**File:** `fittrack/lib/screens/workouts/workout_detail_screen.dart`

**Location:** Add new `_showDeleteConfirmation()` method, called from line 58

**Current Implementation:** Basic AlertDialog (needs to be replaced)

**New Method to Add:**
```dart
void _showDeleteConfirmation(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  // Fetch cascade counts
  final cascadeCounts = await programProvider.getCascadeDeleteCounts(
    workoutId: widget.workout.id,
  );

  if (!context.mounted) return;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Workout',
    content: 'Are you sure you want to delete this workout?',
    itemName: widget.workout.name,
    deleteButtonText: 'Delete Workout',
    cascadeCounts: cascadeCounts,
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteWorkoutById(widget.workout.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Workout "${widget.workout.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop(); // Go back to week screen
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete workout: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

#### 5.5 Workout Detail Screen - Exercise Delete (Inline)

**File:** `fittrack/lib/screens/workouts/workout_detail_screen.dart`

**Location:** Find `_deleteExercise()` method in the exercise card widget

**Implementation:** Similar pattern - fetch cascade counts, show enhanced dialog

#### 5.6 Exercise Detail Screen - Exercise Delete (Menu)

**File:** `fittrack/lib/screens/exercises/exercise_detail_screen.dart`

**Location:** Add `_showDeleteConfirmation()` method, called from line 60

**New Method to Add:**
```dart
void _showDeleteConfirmation(BuildContext context) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final errorColor = Theme.of(context).colorScheme.error;

  // Fetch cascade counts
  final cascadeCounts = await programProvider.getCascadeDeleteCounts(
    exerciseId: widget.exercise.id,
  );

  if (!context.mounted) return;

  final confirmed = await DeleteConfirmationDialog.show(
    context: context,
    title: 'Delete Exercise',
    content: 'Are you sure you want to delete this exercise?',
    itemName: widget.exercise.name,
    deleteButtonText: 'Delete Exercise',
    cascadeCounts: cascadeCounts,
  );

  if (confirmed == true) {
    try {
      await programProvider.deleteExerciseById(widget.exercise.id);

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Exercise "${widget.exercise.name}" deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.pop(); // Go back to workout screen
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete exercise: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
```

---

## Testing Strategy

### Unit Tests

**File:** `fittrack/test/services/firestore_service_delete_test.dart` (NEW)

```dart
// Test cascade count methods
- testCountWorkoutsInWeek()
- testCountExercisesInWorkout()
- testCountSetsInExercise()
- testGetCascadeDeleteCountsForWeek()
- testGetCascadeDeleteCountsForWorkout()
- testGetCascadeDeleteCountsForExercise()
- testGetCascadeDeleteCountsWithInvalidParams()
```

**File:** `fittrack/test/providers/program_provider_delete_test.dart` (UPDATE EXISTING)

```dart
// Add new tests
- testGetCascadeDeleteCountsForWeek()
- testGetCascadeDeleteCountsForWorkout()
- testGetCascadeDeleteCountsForExercise()
- testGetCascadeDeleteCountsWithoutContext()
- testDeleteWeekByIdWithoutSelectedProgram()
- testDeleteWorkoutByIdWithoutSelectedWeek()
- testDeleteExerciseByIdWithoutSelectedWorkout()
```

**File:** `fittrack/test/widgets/delete_confirmation_dialog_test.dart` (UPDATE EXISTING)

```dart
// Add cascade count display tests
- testDialogShowsCascadeCountsForWeek()
- testDialogShowsCascadeCountsForWorkout()
- testDialogShowsCascadeCountsForExercise()
- testDialogWithoutCascadeCounts()
- testDialogWithZeroCounts()
```

### Widget Tests

**File:** `fittrack/test/screens/delete_flow_test.dart` (NEW)

```dart
// Test full delete flow for each entity type
- testWeekDeleteFlowFromProgramDetailScreen()
- testWeekDeleteFlowFromWeeksScreen()
- testWorkoutDeleteFlowFromWeeksScreen()
- testWorkoutDeleteFlowFromWorkoutDetailScreen()
- testExerciseDeleteFlowFromWorkoutDetailScreen()
- testExerciseDeleteFlowFromExerciseDetailScreen()
- testDeleteCancellation()
- testDeleteWithNetworkError()
```

### Integration Tests

**File:** `fittrack/integration_test/delete_functionality_test.dart` (NEW)

```dart
// End-to-end delete tests with Firebase emulator
- testDeleteWeekWithCascade()
- testDeleteWorkoutWithCascade()
- testDeleteExerciseWithCascade()
- testDeleteCountAccuracy()
- testConcurrentDeletes()
- testDeletePermissionDenied()
```

### Manual Testing Checklist

#### Week Deletion
- [ ] Delete week from program detail screen (inline button)
- [ ] Delete week from weeks screen (menu option)
- [ ] Verify cascade counts appear correctly in dialog
- [ ] Verify all child entities deleted (workouts, exercises, sets)
- [ ] Verify success message displays
- [ ] Verify week disappears from UI immediately
- [ ] Test with empty week (0 workouts)
- [ ] Test with week containing multiple workouts
- [ ] Cancel deletion and verify no changes

#### Workout Deletion
- [ ] Delete workout from weeks screen (inline button)
- [ ] Delete workout from workout detail screen (menu option)
- [ ] Verify cascade counts appear correctly in dialog
- [ ] Verify all child entities deleted (exercises, sets)
- [ ] Verify success message displays
- [ ] Verify workout disappears from UI immediately
- [ ] Test with empty workout (0 exercises)
- [ ] Test with workout containing multiple exercises
- [ ] Cancel deletion and verify no changes

#### Exercise Deletion
- [ ] Delete exercise from workout detail screen (inline button)
- [ ] Delete exercise from exercise detail screen (menu option)
- [ ] Verify cascade counts appear correctly in dialog
- [ ] Verify all child entities deleted (sets)
- [ ] Verify success message displays
- [ ] Verify exercise disappears from UI immediately
- [ ] Test with empty exercise (0 sets)
- [ ] Test with exercise containing multiple sets
- [ ] Cancel deletion and verify no changes

#### Error Scenarios
- [ ] Test delete with network offline
- [ ] Test delete with expired auth token
- [ ] Test delete with Firestore permissions denied
- [ ] Verify error messages display correctly
- [ ] Verify UI remains stable after error

#### Context Validation
- [ ] Verify "No program selected" error no longer occurs
- [ ] Verify "No week selected" error no longer occurs
- [ ] Verify "No workout selected" error no longer occurs
- [ ] Test navigation directly to exercise screen (deep link)

---

## Rollout Plan

### Phase 1: Foundation (Week 1)

**Tasks:**
1. Create `CascadeDeleteCounts` model
2. Implement count methods in `FirestoreService`
3. Write unit tests for count methods
4. Implement `getCascadeDeleteCounts()` in `FirestoreService`
5. Write unit tests for cascade count aggregation

**Deliverables:**
- `cascade_delete_counts.dart`
- Updated `firestore_service.dart` with count methods
- `firestore_service_delete_test.dart` with 80%+ coverage

**Acceptance Criteria:**
- All unit tests pass
- Count methods return accurate counts from Firestore
- Cascade count aggregation handles all three entity types

---

### Phase 2: Provider Integration (Week 1)

**Tasks:**
1. Implement `getCascadeDeleteCounts()` in `ProgramProvider`
2. Validate context handling in existing delete methods
3. Write unit tests for provider cascade count method
4. Update existing provider delete tests

**Deliverables:**
- Updated `program_provider.dart` with cascade count method
- Updated `program_provider_delete_test.dart` with new tests

**Acceptance Criteria:**
- Provider correctly resolves context for all delete scenarios
- Unit tests pass with 80%+ coverage
- No regressions in existing delete functionality

---

### Phase 3: UI Components (Week 2)

**Tasks:**
1. Update `DeleteConfirmationDialog` widget
2. Write widget tests for enhanced dialog
3. Update all screen delete methods to use enhanced dialog:
   - `program_detail_screen.dart` - week delete
   - `weeks_screen.dart` - week & workout delete
   - `workout_detail_screen.dart` - workout & exercise delete
   - `exercise_detail_screen.dart` - exercise delete

**Deliverables:**
- Updated `delete_confirmation_dialog.dart`
- Updated screen files with enhanced delete flows
- Widget tests for enhanced dialog

**Acceptance Criteria:**
- Dialog displays cascade counts correctly
- All delete buttons show enhanced confirmation
- Widget tests pass with 80%+ coverage
- UI/UX matches design specifications

---

### Phase 4: Testing & QA (Week 2)

**Tasks:**
1. Write integration tests with Firebase emulator
2. Perform manual testing (checklist above)
3. Fix any bugs found during testing
4. Performance testing (large cascades)
5. Accessibility review

**Deliverables:**
- `delete_functionality_test.dart` integration tests
- Manual testing sign-off
- Bug fixes (if any)
- Performance report

**Acceptance Criteria:**
- All automated tests pass (unit, widget, integration)
- Manual testing checklist 100% complete
- No critical or high-severity bugs
- Delete operations complete within 5 seconds for cascades up to 500 items

---

### Phase 5: Documentation & Deployment (Week 3)

**Tasks:**
1. Update component documentation
2. Update release notes
3. Create deployment checklist
4. Deploy to beta environment
5. Beta testing (real devices)
6. Deploy to production

**Deliverables:**
- Updated documentation in `Docs/`
- Release notes in `Docs/Releases/`
- Deployment checklist
- Beta testing report

**Acceptance Criteria:**
- Documentation complete and accurate
- Beta testing successful (no critical issues)
- Production deployment successful
- Post-deployment verification complete

---

## File Changes Summary

### New Files
- `fittrack/lib/models/cascade_delete_counts.dart` - Cascade count model
- `fittrack/test/services/firestore_service_delete_test.dart` - Service tests
- `fittrack/test/screens/delete_flow_test.dart` - Widget tests
- `fittrack/integration_test/delete_functionality_test.dart` - Integration tests

### Modified Files
- `fittrack/lib/services/firestore_service.dart` - Add count methods
- `fittrack/lib/providers/program_provider.dart` - Add cascade count method
- `fittrack/lib/widgets/delete_confirmation_dialog.dart` - Enhance with cascade counts
- `fittrack/lib/screens/programs/program_detail_screen.dart` - Fix week delete
- `fittrack/lib/screens/weeks/weeks_screen.dart` - Fix week & workout delete
- `fittrack/lib/screens/workouts/workout_detail_screen.dart` - Fix workout & exercise delete
- `fittrack/lib/screens/exercises/exercise_detail_screen.dart` - Fix exercise delete
- `fittrack/test/providers/program_provider_delete_test.dart` - Add tests
- `fittrack/test/widgets/delete_confirmation_dialog_test.dart` - Add tests

### No Changes Required
- `fittrack/lib/services/firestore_service.dart` cascade delete methods (already working)
- `fittrack/lib/providers/program_provider.dart` delete validation (already correct)
- Firestore security rules (already enforce authorization)

---

## Risk Assessment

### High Risk
- **Large Cascade Deletes**: Deleting a week with 100+ workouts could timeout
  - **Mitigation**: Batched writes already implemented (≤450 ops/batch)
  - **Monitoring**: Add performance logging for cascade deletes >50 items

### Medium Risk
- **Count Query Performance**: Aggregating counts for large hierarchies could be slow
  - **Mitigation**: Use Firestore `.count()` queries (optimized, don't fetch documents)
  - **Fallback**: If count takes >2s, show dialog without counts

### Low Risk
- **UI State During Count Fetch**: Brief loading delay before dialog appears
  - **Mitigation**: Acceptable UX trade-off for better information
  - **Alternative**: Show dialog immediately with "Calculating..." then update (more complex)

- **Context Missing on Deep Link**: User deep links directly to exercise screen
  - **Current Behavior**: Exception thrown, error displayed
  - **Post-Fix Behavior**: Same (exception with clear message)
  - **Future Enhancement**: Load full context chain on screen init

---

## Performance Considerations

### Count Query Optimization
- Firestore `.count()` queries are server-side aggregations (no document fetches)
- Expected latency: 100-300ms per count query
- Worst case (week delete): 1 week count + N workout counts + M exercise counts
  - Example: Week with 10 workouts, avg 5 exercises each = 1 + 10 + 50 = 61 queries
  - Parallel execution: ~1-2 seconds total
- **Optimization**: Cache counts at parent level (future enhancement)

### Delete Operation Performance
- Batched writes limit: 450 operations per batch
- Each entity deletion = 1 operation
- Example: Week with 10 workouts × 5 exercises × 3 sets = 10 + 50 + 150 = 210 ops
  - Single batch: ~500-1000ms
- Large week (100 workouts × 5 exercises × 3 sets = 1,600 ops):
  - 4 batches: ~2-4 seconds
- **Monitoring**: Log delete duration, alert if >5 seconds

---

## Security Considerations

### Authorization
- All delete operations require authentication (`userId != null`)
- Firestore security rules enforce per-user data scoping
- Existing rules already validate `request.auth.uid == userId`
- No changes required to security rules

### Data Integrity
- Cascade deletes are atomic (batched writes)
- If any operation fails, entire batch is rolled back
- No orphaned data possible

### Audit Logging
- Current: No audit trail for deletions
- Future Enhancement: Add cloud function to log deletes to audit collection

---

## Accessibility

### Confirmation Dialogs
- ✅ Screen reader support (existing AlertDialog)
- ✅ Keyboard navigation (existing AlertDialog)
- ✅ High contrast mode support (theme-aware colors)
- ✅ Clear hierarchy (title, content, actions)
- ⚠️ Cascade counts should be announced by screen readers
  - Ensure proper semantic structure

### Delete Buttons
- ✅ Tooltips on icon buttons ("Delete week", "Delete workout", etc.)
- ✅ Color not sole indicator (text + icon)
- ✅ Sufficient touch target size (IconButton 48x48dp)

---

## Dependencies

### Flutter Packages
- `cloud_firestore` (existing) - Firestore operations
- `provider` (existing) - State management
- `flutter_test` (existing) - Testing

### No New Dependencies Required

---

## Implementation Notes

### Code Style
- Follow existing Dart style guide
- Use `lints` package rules
- Document public APIs with `///` comments
- Use named parameters for clarity

### Error Messages
- User-facing: Simple, actionable ("Failed to delete week. Try again later.")
- Console logs: Detailed for debugging ("deleteWeek failed: [FirebaseException] permission-denied...")

### Loading States
- Show loading indicator during count fetch: No (too brief, causes flicker)
- Show loading indicator during delete: Yes (via provider `isLoading` state)
- Disable delete button during operation: Yes

---

## Future Enhancements

### Undo Functionality
- Implement soft delete (add `isDeleted` flag)
- Store deleted entities in temporary collection
- Provide "Undo" button in snackbar (5-second window)
- Permanent delete after 30 days

### Bulk Delete
- Select multiple weeks/workouts/exercises
- Single confirmation dialog with aggregate counts
- Optimized batched deletion

### Delete Analytics
- Track deletion frequency (detect user frustration)
- A/B test confirmation dialog variations
- Monitor cascade delete performance

### Context Recovery
- On direct navigation (deep link), fetch full context chain
- Load program → week → workout in sequence
- Populate provider state before screen renders

---

## Appendix A: Error Messages

### User-Facing Messages

| Scenario | Message |
|----------|---------|
| Week deleted successfully | `Week "[name]" deleted successfully` |
| Workout deleted successfully | `Workout "[name]" deleted successfully` |
| Exercise deleted successfully | `Exercise "[name]" deleted successfully` |
| Network error | `Failed to delete [entity]. Check your connection and try again.` |
| Permission denied | `Failed to delete [entity]. You don't have permission.` |
| Generic error | `Failed to delete [entity]. Try again later.` |
| Missing context | `Failed to delete [entity]: Missing context. Please navigate from the main screen.` |

### Developer/Console Logs

| Scenario | Log Message |
|----------|-------------|
| Missing userId | `deleteWeekById failed: User not authenticated` |
| Missing program | `deleteWeekById failed: No program selected` |
| Missing week | `deleteWorkoutById failed: No week selected` |
| Missing workout | `deleteExerciseById failed: No workout selected` |
| Firestore error | `deleteWeek failed: [FirebaseException] [error code]: [error message]` |
| Count query failed | `getCascadeDeleteCounts failed: [error], returning zero counts` |

---

## Appendix B: GitHub Issue Task Breakdown

### Task 1: Implement Cascade Count Model & Service Methods
**Estimate:** 3 hours
**Files:**
- Create `cascade_delete_counts.dart`
- Update `firestore_service.dart` (count methods)
- Create `firestore_service_delete_test.dart`

**Acceptance Criteria:**
- Model has `workouts`, `exercises`, `sets` fields
- Model provides `getSummary()` method
- Count methods use Firestore `.count()` queries
- Unit tests cover all count methods with 80%+ coverage

---

### Task 2: Implement Cascade Count Aggregation in FirestoreService
**Estimate:** 4 hours
**Files:**
- Update `firestore_service.dart` (`getCascadeDeleteCounts`)
- Update `firestore_service_delete_test.dart`

**Acceptance Criteria:**
- Handles week, workout, exercise deletion scenarios
- Returns accurate counts for all child entities
- Handles errors gracefully (returns zero counts)
- Unit tests cover all scenarios with 80%+ coverage

---

### Task 3: Implement Cascade Count Method in ProgramProvider
**Estimate:** 2 hours
**Files:**
- Update `program_provider.dart` (`getCascadeDeleteCounts`)
- Update `program_provider_delete_test.dart`

**Acceptance Criteria:**
- Resolves context (programId, weekId, workoutId) correctly
- Calls FirestoreService cascade count method
- Returns zero counts if context missing
- Unit tests cover all scenarios with 80%+ coverage

---

### Task 4: Enhance DeleteConfirmationDialog Widget
**Estimate:** 3 hours
**Files:**
- Update `delete_confirmation_dialog.dart`
- Update `delete_confirmation_dialog_test.dart`

**Acceptance Criteria:**
- Accepts `cascadeCounts` parameter
- Displays cascade count information in highlighted box
- Shows icons for each entity type
- Displays "This action cannot be undone" warning
- Widget tests cover all display scenarios

---

### Task 5: Update Program Detail Screen - Week Delete
**Estimate:** 1 hour
**Files:**
- Update `program_detail_screen.dart` (`_WeekCard._deleteWeek`)

**Acceptance Criteria:**
- Fetches cascade counts before showing dialog
- Uses enhanced DeleteConfirmationDialog
- Displays success/error messages correctly
- Manual testing passes

---

### Task 6: Update Weeks Screen - Week & Workout Delete
**Estimate:** 2 hours
**Files:**
- Update `weeks_screen.dart` (`_showDeleteDialog`, `_WorkoutCard._deleteWorkout`)

**Acceptance Criteria:**
- Both delete methods fetch cascade counts
- Both use enhanced DeleteConfirmationDialog
- Consistent error handling
- Manual testing passes

---

### Task 7: Update Workout Detail Screen - Workout & Exercise Delete
**Estimate:** 2 hours
**Files:**
- Update `workout_detail_screen.dart` (`_showDeleteConfirmation`, exercise delete method)

**Acceptance Criteria:**
- Both delete methods fetch cascade counts
- Both use enhanced DeleteConfirmationDialog
- Proper navigation after successful delete
- Manual testing passes

---

### Task 8: Update Exercise Detail Screen - Exercise Delete
**Estimate:** 1 hour
**Files:**
- Update `exercise_detail_screen.dart` (`_showDeleteConfirmation`)

**Acceptance Criteria:**
- Fetches cascade counts before showing dialog
- Uses enhanced DeleteConfirmationDialog
- Proper navigation after successful delete
- Manual testing passes

---

### Task 9: Write Integration Tests
**Estimate:** 4 hours
**Files:**
- Create `delete_functionality_test.dart`

**Acceptance Criteria:**
- Tests week, workout, exercise cascade deletes end-to-end
- Verifies cascade count accuracy
- Tests error scenarios (network, permissions)
- All tests pass with Firebase emulator

---

### Task 10: Manual Testing & Bug Fixes
**Estimate:** 4 hours
**Files:**
- Various (bug fixes as needed)

**Acceptance Criteria:**
- Complete manual testing checklist 100%
- Fix all critical and high-severity bugs
- Regression testing passes
- Performance testing passes

---

### Task 11: Documentation & Release Preparation
**Estimate:** 2 hours
**Files:**
- Update `Docs/Components/FirestoreService.md`
- Update `Docs/Architecture/StateManagement.md`
- Create release notes in `Docs/Releases/`

**Acceptance Criteria:**
- All documentation updated and accurate
- Release notes include user-facing changes
- Implementation notes added to technical design

---

**Total Estimated Effort:** ~28 hours (3.5 developer days)

---

## Appendix C: Notion Technical Design Summary

**For SA Agent:** Create the following summary in Notion "Technical Designs" database:

**Title:** Delete Functionality Fix - Technical Design

**Properties:**
- Feature: Delete Functionality Fix
- Issue: #49
- Status: Design Complete
- Priority: High
- Type: Bug Fix
- Estimated Effort: 28 hours
- Target Release: v1.2.0

**Summary:**

Fix delete functionality for weeks, workouts, and exercises by:
1. Adding cascade count information to confirmation dialogs
2. Ensuring proper context/state management for all delete operations
3. Improving error feedback and loading states

**Key Technical Changes:**
- New `CascadeDeleteCounts` model for structured count data
- Firestore count query methods (`.count()` API)
- Enhanced `DeleteConfirmationDialog` with cascade information
- Updated all delete flows in 6 screen files

**Testing Strategy:**
- Unit tests for count methods and provider integration
- Widget tests for enhanced dialogs
- Integration tests for end-to-end delete flows
- Manual testing checklist (40+ test cases)

**Rollout:** 5-phase plan over 3 weeks

**Link to Full Design:** [Delete_Functionality_Fix_Technical_Design.md](../../Docs/Technical_Designs/Delete_Functionality_Fix_Technical_Design.md)

---

*End of Technical Design Document*
