# Technical Design: Duplicate Week Enhancement

**Issue:** #50 - Update to duplicate week functionality
**Status:** Design Phase
**Created:** 2025-10-26
**Last Updated:** 2025-10-26

## Table of Contents
1. [Overview](#overview)
2. [Current Implementation Analysis](#current-implementation-analysis)
3. [Requirements](#requirements)
4. [Architecture](#architecture)
5. [Implementation Details](#implementation-details)
6. [Testing Strategy](#testing-strategy)
7. [Rollout Plan](#rollout-plan)
8. [Success Metrics](#success-metrics)

---

## Overview

### Problem Statement
The current week duplication functionality has three issues:
1. **UX Issue**: Duplicate button is in the top AppBar menu, not alongside Edit/Delete actions
2. **Naming Issue**: Duplicated weeks are named "[Name] (Copy)" without increment numbers
3. **Bug**: Null Timestamp error appears briefly during duplication

### Impact
- **Severity:** MEDIUM - Feature works but UX is suboptimal
- **User Experience:** Users expect duplication to be in row-level menu with smart naming
- **Workaround:** Current functionality works, users manually rename copies

### Goal
Enhance week duplication with:
- Better UI placement (3-dot menu on each week row)
- Smart copy naming with auto-incrementing numbers
- Fix null Timestamp handling

---

## Current Implementation Analysis

### Existing Implementation

**Files:**
- `fittrack/lib/services/firestore_service.dart:451-650` - Core duplication logic
- `fittrack/lib/providers/program_provider.dart:413-435` - Provider wrapper
- `fittrack/lib/screens/weeks/weeks_screen.dart:42-318` - UI implementation

**Current Naming Logic (Line 514):**
```dart
'name': srcWeekData['name'] != null ? '${srcWeekData['name']} (Copy)' : 'Week (Copy)',
```
- Simple append " (Copy)" to source name
- No increment numbers
- No conflict detection

**Current UI Structure:**
- AppBar has PopupMenuButton with "Duplicate Week", "Edit Week", "Delete Week"
- Menu at screen level, not row level
- Works but not standard UX pattern

**Deep Copy Implementation:**
- ✅ Works correctly with batched writes
- ✅ Resets `checked: false` for sets
- ✅ Preserves weight and other fields
- ✅ Generates new IDs for all documents
- ⚠️ Has Timestamp null handling issues

### What Works Well

1. **Batched Writes**: Correctly uses WriteBatch with 450-operation limit
2. **Deep Copy**: Properly duplicates Week → Workouts → Exercises → Sets hierarchy
3. **Field Handling**: Uses `ExerciseSet.createDuplicateCopy()` for smart field copying
4. **Ownership Verification**: Checks userId matches before duplication

### What Needs Improvement

1. **Naming Algorithm**: Need smart increment logic
2. **UI Placement**: Move duplicate to row-level 3-dot menu
3. **Timestamp Handling**: Need better null safety
4. **User Feedback**: Loading states could be improved

---

## Requirements

### Functional Requirements

**1. Smart Copy Naming Algorithm**

| Source Name | Existing Copies | Result |
|-------------|----------------|--------|
| "Week 1" | None | "Week 1 Copy 1" |
| "Week 1" | "Week 1 Copy 1" | "Week 1 Copy 2" |
| "Week 1 Copy 1" | "Week 1 Copy 2" | "Week 1 Copy 3" |
| "Upper Body" | None | "Upper Body Copy 1" |
| "Week 1" | "Week 1 Copy 1", "Week 1 Copy 3" | "Week 1 Copy 2" (fills gap) |

**Algorithm Requirements:**
- Extract base name (remove existing " Copy N" suffix)
- Query all week names in program
- Find all copies with pattern "\\s+Copy\\s+(\\d+)"
- Find highest N, increment by 1
- Handle gaps in numbering (fill lowest available)

**2. UI Enhancement**

Current structure:
```
AppBar
  └─ PopupMenuButton (screen-level)
       ├─ Duplicate Week
       ├─ Edit Week
       └─ Delete Week
```

New structure:
```
Week Row
  └─ PopupMenuButton (row-level, aligned right)
       ├─ Duplicate (with copy icon)
       ├─ Edit (placeholder)
       └─ Delete (placeholder)
```

**3. Timestamp Bug Fix**

Issues:
- `updatedAt` and `completedAt` may be null in source documents
- Calling `.toDate()` on null throws error
- Brief error flash shown to user

Solution:
- Check for null before field access
- Omit null Timestamp fields from duplicate
- Always set `createdAt: FieldValue.serverTimestamp()` for new documents
- Wrap in try-catch, log to console only

### Non-Functional Requirements

| Requirement | Target | Measurement |
|-------------|--------|-------------|
| **Performance** | Duplication completes in < 5 seconds for 10 workouts | Firebase Performance Monitoring |
| **Batch Size** | ≤ 450 operations per batch | Code validation |
| **Error Handling** | No user-visible Timestamp errors | Manual testing |
| **Loading State** | Immediate feedback on button press | UX testing |

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     WeeksScreen (UI)                         │
│                                                              │
│  Week Rows (ListView)                                       │
│    ├─ Week Card                                             │
│    │    ├─ Week Name                                        │
│    │    ├─ Workout Count                                    │
│    │    └─ PopupMenuButton (NEW: row-level)                │
│    │         ├─ Duplicate (with icon)                       │
│    │         ├─ Edit (placeholder)                          │
│    │         └─ Delete (placeholder)                        │
└──────────────────────────────────────────────────────────────┘
                           │
                           ├─ duplicateWeek() call
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                   ProgramProvider                            │
│                                                              │
│  duplicateWeek(programId, weekId)                           │
│    1. Show loading state                                    │
│    2. Call FirestoreService.duplicateWeek()                 │
│    3. Handle result / error                                 │
│    4. Update UI state                                       │
└──────────────────────────────────────────────────────────────┘
                           │
                           ├─ firestore operations
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                  FirestoreService                            │
│                                                              │
│  duplicateWeek(userId, programId, weekId)                   │
│    1. Generate smart name (NEW)                             │
│    2. Create new week with smart name                       │
│    3. Deep copy workouts/exercises/sets                     │
│    4. Use batched writes (≤450 ops)                         │
│    5. Handle Timestamps safely (FIXED)                      │
│    6. Return mapping result                                 │
└──────────────────────────────────────────────────────────────┘
                           │
                           ├─ query week names
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                  SmartCopyNaming (NEW)                       │
│                                                              │
│  generateCopyName(sourceName, existingNames)                │
│    1. Extract base name                                     │
│    2. Find all "Copy N" variants                            │
│    3. Calculate next available number                       │
│    4. Return "Base Copy N"                                  │
└──────────────────────────────────────────────────────────────┘
```

### Data Flow

**Before Enhancement:**
```
User clicks AppBar menu → "Duplicate Week"
    ↓
ProgramProvider.duplicateWeek()
    ↓
FirestoreService.duplicateWeek()
    ├─ Creates week: "[Name] (Copy)"
    ├─ Deep copies workouts/exercises/sets
    └─ May throw Timestamp error
    ↓
Success/Error message shown
```

**After Enhancement:**
```
User clicks row 3-dot menu → "Duplicate"
    ↓
ProgramProvider.duplicateWeek()
    ├─ Set loading state (immediate feedback)
    ↓
FirestoreService.duplicateWeek()
    ├─ Query all week names in program
    ├─ Generate smart name with SmartCopyNaming
    ├─ Creates week: "[Name] Copy N"
    ├─ Deep copies workouts/exercises/sets
    ├─ Safe Timestamp handling (no errors)
    └─ Return result
    ↓
Success message: "Week duplicated successfully!"
Duplicated week appears in list
```

---

## Implementation Details

### 1. Smart Copy Naming Algorithm

**New Helper Class:** `fittrack/lib/utils/smart_copy_naming.dart`

```dart
class SmartCopyNaming {
  /// Generate smart copy name with auto-incrementing numbers
  ///
  /// Examples:
  /// - "Week 1" + [] → "Week 1 Copy 1"
  /// - "Week 1" + ["Week 1 Copy 1"] → "Week 1 Copy 2"
  /// - "Week 1 Copy 1" + ["Week 1 Copy 2"] → "Week 1 Copy 3"
  /// - "Week 1" + ["Week 1 Copy 1", "Week 1 Copy 3"] → "Week 1 Copy 2" (fills gap)
  static String generateCopyName(String sourceName, List<String> existingNames) {
    // 1. Extract base name (remove " Copy N" suffix if present)
    final baseName = _extractBaseName(sourceName);

    // 2. Find all existing copy numbers for this base name
    final copyNumbers = <int>[];
    final copyPattern = RegExp(r'^' + RegExp.escape(baseName) + r'\s+Copy\s+(\d+)$');

    for (final name in existingNames) {
      final match = copyPattern.firstMatch(name);
      if (match != null) {
        final number = int.tryParse(match.group(1) ?? '');
        if (number != null) {
          copyNumbers.add(number);
        }
      }
    }

    // 3. Find next available number (fills gaps)
    if (copyNumbers.isEmpty) {
      return '$baseName Copy 1';
    }

    copyNumbers.sort();

    // Check for gaps in sequence
    for (int i = 1; i <= copyNumbers.length; i++) {
      if (!copyNumbers.contains(i)) {
        return '$baseName Copy $i';
      }
    }

    // No gaps, use next number
    final nextNumber = copyNumbers.last + 1;
    return '$baseName Copy $nextNumber';
  }

  /// Extract base name by removing " Copy N" suffix
  static String _extractBaseName(String name) {
    final copyPattern = RegExp(r'\s+Copy\s+\d+$');
    return name.replaceFirst(copyPattern, '').trim();
  }
}
```

### 2. Update FirestoreService.duplicateWeek()

**File:** `fittrack/lib/services/firestore_service.dart`

**Changes at line 451-650:**

```dart
Future<Map<String, dynamic>> duplicateWeek({
  required String userId,
  required String programId,
  required String weekId,
}) async {
  try {
    // ... existing batch management code ...

    // 1) Load source week
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
    if (srcWeekData == null) {
      throw Exception('Source week data not found');
    }

    // Verify userId
    if (srcWeekData['userId'] != null && srcWeekData['userId'] != userId) {
      throw Exception('You do not own this week');
    }

    // NEW: Query all week names in program for smart naming
    final allWeeksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .get();

    final existingNames = allWeeksSnapshot.docs
        .map((doc) => doc.data()['name'] as String?)
        .where((name) => name != null)
        .cast<String>()
        .toList();

    // NEW: Generate smart copy name
    final sourceName = srcWeekData['name'] as String? ?? 'Week';
    final newWeekName = SmartCopyNaming.generateCopyName(sourceName, existingNames);

    // 2) Create new Week document with smart name
    final newWeekRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc();

    final newWeekData = {
      'name': newWeekName,  // CHANGED: use smart name
      'order': srcWeekData['order'],
      'notes': srcWeekData['notes'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'programId': programId,
    };

    // FIXED: Handle null Timestamps safely
    // Only copy non-null, non-Timestamp fields
    // Omit updatedAt and completedAt from source (always use new timestamps)

    await addToBatch(newWeekRef, newWeekData);

    // ... rest of existing deep copy logic remains unchanged ...

    return mapping;
  } catch (e) {
    // IMPROVED: Better error logging
    debugPrint('[FirestoreService] duplicateWeek error: $e');
    throw Exception('Failed to duplicate week: $e');
  }
}
```

### 3. Update WeeksScreen UI

**File:** `fittrack/lib/screens/weeks/weeks_screen.dart`

**Remove AppBar PopupMenuButton:**

Current AppBar (lines 42-62):
```dart
actions: [
  PopupMenuButton<String>(  // ← REMOVE THIS
    onSelected: (value) => _handleMenuAction(context, value),
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'duplicate', child: ListTile(...)),
      const PopupMenuItem(value: 'edit', child: ListTile(...)),
      const PopupMenuItem(value: 'delete', child: ListTile(...)),
    ],
  ),
],
```

**Add Row-Level PopupMenuButton to _WeekCard:**

New structure:
```dart
class _WeekCard extends StatelessWidget {
  final Week week;
  final VoidCallback onTap;
  final Function(String) onMenuAction;  // NEW: callback for menu actions

  const _WeekCard({
    required this.week,
    required this.onTap,
    required this.onMenuAction,  // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: // ... existing week icon ...
        title: // ... existing week name ...
        subtitle: // ... existing workout count ...
        trailing: Row(  // NEW: Add menu button
          mainAxisSize: MainAxisSize.min,
          children: [
            // Existing trailing content (if any)

            // NEW: 3-dot menu button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: onMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.content_copy),
                    title: Text('Duplicate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  enabled: false,  // Placeholder for future
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  enabled: false,  // Placeholder for future
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**Update _handleMenuAction:**

```dart
void _handleMenuAction(BuildContext context, String action, Week week) async {
  final programProvider = Provider.of<ProgramProvider>(context, listen: false);

  switch (action) {
    case 'duplicate':
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final result = await programProvider.duplicateWeek(
          programId: week.programId,
          weekId: week.id,
        );

        // Close loading dialog
        if (context.mounted) Navigator.of(context).pop();

        if (result != null) {
          // Success
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Week duplicated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Error handled by provider
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(programProvider.error ?? 'Failed to duplicate week'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) Navigator.of(context).pop();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      break;

    case 'edit':
      // Placeholder - show coming soon message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit functionality coming soon')),
      );
      break;

    case 'delete':
      // Placeholder - show coming soon message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete functionality coming soon')),
      );
      break;
  }
}
```

### 4. Timestamp Safety Enhancements

**Current Issue:**
```dart
// This can throw if updatedAt is null
'updatedAt': srcWeekData['updatedAt']?.toDate(),
```

**Safe Implementation:**

```dart
// Helper function to safely copy Timestamp field
Timestamp? _safeTimestamp(Map<String, dynamic> data, String field) {
  try {
    final value = data[field];
    if (value == null) return null;
    if (value is Timestamp) return value;
    return null;
  } catch (e) {
    debugPrint('[FirestoreService] Error reading Timestamp field $field: $e');
    return null;
  }
}

// Usage in duplication:
final newWeekData = {
  'name': newWeekName,
  'order': srcWeekData['order'],
  'notes': srcWeekData['notes'],
  'createdAt': FieldValue.serverTimestamp(),  // Always new timestamp
  'updatedAt': FieldValue.serverTimestamp(),  // Always new timestamp
  // Don't copy completedAt - fresh week shouldn't be completed
  'userId': userId,
  'programId': programId,
};
```

---

## Testing Strategy

### Unit Tests

**File:** `fittrack/test/utils/smart_copy_naming_test.dart`

```dart
void main() {
  group('SmartCopyNaming.generateCopyName', () {
    test('first duplicate should add Copy 1', () {
      expect(
        SmartCopyNaming.generateCopyName('Week 1', []),
        'Week 1 Copy 1',
      );
    });

    test('second duplicate should add Copy 2', () {
      expect(
        SmartCopyNaming.generateCopyName('Week 1', ['Week 1 Copy 1']),
        'Week 1 Copy 2',
      );
    });

    test('duplicating a copy should increment correctly', () {
      expect(
        SmartCopyNaming.generateCopyName(
          'Week 1 Copy 1',
          ['Week 1 Copy 2'],
        ),
        'Week 1 Copy 3',
      );
    });

    test('should fill gaps in numbering', () {
      expect(
        SmartCopyNaming.generateCopyName(
          'Week 1',
          ['Week 1 Copy 1', 'Week 1 Copy 3'],
        ),
        'Week 1 Copy 2',
      );
    });

    test('should work with custom names', () {
      expect(
        SmartCopyNaming.generateCopyName('Upper Body', []),
        'Upper Body Copy 1',
      );
    });

    test('should handle empty source name', () {
      expect(
        SmartCopyNaming.generateCopyName('', []),
        ' Copy 1',
      );
    });

    test('should extract base name correctly', () {
      expect(
        SmartCopyNaming._extractBaseName('Week 1 Copy 3'),
        'Week 1',
      );
    });
  });
}
```

**File:** `fittrack/test/services/firestore_service_test.dart`

```dart
group('duplicateWeek with smart naming', () {
  test('should generate smart copy name', () async {
    // Setup mock Firestore
    // Test that duplicate creates week with "Week 1 Copy 1" name
  });

  test('should handle null Timestamps without error', () async {
    // Setup week with null updatedAt
    // Verify duplication succeeds without throwing
  });
});
```

### Integration Tests

**File:** `fittrack/integration_test/week_duplication_test.dart`

```dart
void main() {
  group('Week Duplication', () {
    testWidgets('duplicate week from row menu', (tester) async {
      // Login
      // Create a program and week
      // Tap 3-dot menu on week row
      // Tap "Duplicate"
      // Verify loading indicator shows
      // Verify success message
      // Verify new week appears with "Copy 1" suffix
    });

    testWidgets('duplicate multiple times increments number', (tester) async {
      // Create week "Week 1"
      // Duplicate → verify "Week 1 Copy 1"
      // Duplicate again → verify "Week 1 Copy 2"
      // Duplicate again → verify "Week 1 Copy 3"
    });

    testWidgets('duplicate a copy increments correctly', (tester) async {
      // Create "Week 1"
      // Duplicate → "Week 1 Copy 1"
      // Duplicate "Week 1 Copy 1" → "Week 1 Copy 2"
    });
  });
}
```

### Manual Testing

#### Test Plan: Smart Naming

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Create week "Week 1" | Week created | ☐ |
| 2 | Duplicate "Week 1" | New week "Week 1 Copy 1" appears | ☐ |
| 3 | Duplicate "Week 1" again | New week "Week 1 Copy 2" appears | ☐ |
| 4 | Delete "Week 1 Copy 2" | Week deleted | ☐ |
| 5 | Duplicate "Week 1" again | New week "Week 1 Copy 2" appears (fills gap) | ☐ |
| 6 | Rename week to "Upper Body" | Week renamed | ☐ |
| 7 | Duplicate "Upper Body" | New week "Upper Body Copy 1" appears | ☐ |

#### Test Plan: UI Enhancement

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | View weeks list | Each week row has 3-dot menu icon | ☐ |
| 2 | Tap 3-dot menu on a week | Menu shows Duplicate, Edit, Delete | ☐ |
| 3 | Verify icon | Duplicate has copy icon | ☐ |
| 4 | Verify enabled state | Duplicate is enabled, Edit/Delete disabled | ☐ |
| 5 | Tap "Duplicate" | Loading indicator shows immediately | ☐ |
| 6 | Wait for completion | Success message appears | ☐ |
| 7 | Verify new week | Duplicated week appears in list | ☐ |

#### Test Plan: Timestamp Bug Fix

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Create week with workouts/exercises/sets | Week created | ☐ |
| 2 | Duplicate week | No error flash appears | ☐ |
| 3 | Check console logs | No Timestamp null errors | ☐ |
| 4 | Verify duplicated week | All data copied correctly | ☐ |

---

## Rollout Plan

### Phase 1: Foundation (Week 1, Days 1-2)

**Tasks:**
- Create `SmartCopyNaming` utility class
- Write unit tests for naming algorithm
- Update FirestoreService to query week names
- Integrate smart naming into duplication logic

**Validation:**
- Unit tests pass
- Manual test: duplicate creates "Week 1 Copy 1"

### Phase 2: Timestamp Fixes (Week 1, Day 3)

**Tasks:**
- Add `_safeTimestamp()` helper function
- Update duplication to use safe Timestamp handling
- Remove null Timestamp fields from duplicates
- Add error logging

**Validation:**
- No Timestamp errors in console
- Duplication works with weeks that have null timestamps

### Phase 3: UI Enhancement (Week 1, Days 4-5)

**Tasks:**
- Remove AppBar PopupMenuButton
- Add row-level 3-dot menu to _WeekCard
- Update _handleMenuAction to accept week parameter
- Add loading indicator during duplication
- Improve success/error messages

**Validation:**
- 3-dot menu appears on each week row
- Duplicate, Edit, Delete options visible
- Edit and Delete are disabled (placeholders)

### Phase 4: Integration Testing (Week 2, Days 1-3)

**Tasks:**
- Write integration tests for duplication flow
- Test naming algorithm with real Firestore
- Test multiple duplications in sequence
- Test gap filling in numbering

**Validation:**
- All integration tests pass
- Manual testing confirms smart naming works

### Phase 5: Production Deployment (Week 2, Days 4-5)

**Tasks:**
- Deploy to beta testers
- Monitor Firebase Crashlytics
- Monitor user feedback
- Fix any issues discovered

**Validation:**
- No increase in crash rate
- Positive user feedback on new naming
- No duplicate-related errors

---

## Success Metrics

### Primary Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **Duplicate Success Rate** | ~95% (estimate) | 100% | Firebase Analytics |
| **User Satisfaction** | Unknown | 90% positive | User surveys |
| **Time to Duplicate** | ~3-5 seconds | < 5 seconds | Performance monitoring |

### Secondary Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **Menu Discovery** | 0% (not visible) | 80%+ find menu | Analytics event tracking |
| **Naming Confusion** | High (manual rename) | Low (< 10% rename) | Track rename actions |
| **Timestamp Errors** | Occasional | 0 | Crashlytics |

### Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Batch Operations** | ≤ 450 per batch | Code validation |
| **Query Efficiency** | Single query for week names | Code review |
| **Test Coverage** | ≥ 80% | Coverage report |

---

## Risk Analysis

### High Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Breaking existing duplication** | Users lose functionality | Low | Comprehensive testing, gradual rollout |
| **Performance degradation** | Slow duplication | Low | Additional query is cached, minimal impact |

### Medium Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Naming conflicts** | Duplicate names created | Low | Thorough testing of edge cases |
| **UI layout issues** | Poor UX on small screens | Medium | Test on various screen sizes |

### Low Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **User confusion** | Don't find new menu | Low | Clear icon, standard placement |

---

## Alternative Solutions Considered

### Alternative 1: Keep AppBar Menu

**Approach:** Improve naming but keep menu in AppBar

**Pros:**
- Less code changes
- No risk of breaking UI

**Cons:**
- ❌ Not standard UX pattern
- ❌ Less discoverable
- ❌ Doesn't match Edit/Delete pattern

**Decision:** ❌ Rejected - Poor UX

### Alternative 2: Simple Increment Without Gap Filling

**Approach:** Always use max(N) + 1, don't fill gaps

**Pros:**
- Simpler algorithm
- Faster (no need to check all numbers)

**Cons:**
- ❌ Creates gaps: "Copy 1", "Copy 3", "Copy 4"
- ❌ Less clean numbering

**Decision:** ❌ Rejected - Gap filling provides better UX

### Alternative 3: Use Timestamps in Name

**Approach:** Name duplicates "Week 1 (2025-10-26 10:30)"

**Pros:**
- Unique guaranteed
- Shows when created

**Cons:**
- ❌ Long, cluttered names
- ❌ Not user-friendly
- ❌ Timezone issues

**Decision:** ❌ Rejected - Poor UX

---

## Appendix

### Code References

**Key Files:**
- `fittrack/lib/services/firestore_service.dart:451-650` - Duplication logic
- `fittrack/lib/providers/program_provider.dart:413-435` - Provider wrapper
- `fittrack/lib/screens/weeks/weeks_screen.dart:42-318` - UI
- `fittrack/lib/utils/smart_copy_naming.dart` - NEW: Naming algorithm

### Related Documentation

- [Architecture Overview](../Architecture/ArchitectureOverview.md)
- [Data Models](../Architecture/DataModels.md)
- [Firestore Service Component](../Components/FirestoreService.md)
- [Testing Framework](../Testing/TestingFramework.md)

### External References

- [Firestore Batched Writes](https://firebase.google.com/docs/firestore/manage-data/transactions#batched-writes)
- [Flutter PopupMenuButton](https://api.flutter.dev/flutter/material/PopupMenuButton-class.html)
- [Dart RegExp](https://api.dart.dev/stable/dart-core/RegExp-class.html)

---

**Document Version:** 1.0
**Last Review:** 2025-10-26
**Next Review:** After implementation complete
