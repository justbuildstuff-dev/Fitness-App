# Manual QA Test Plan - Feature #53: ConsolidatedWorkoutScreen

**Feature:** Update user screens to reduce number of clicks (ConsolidatedWorkoutScreen)
**Parent Issue:** #53
**Bug Issue:** #258 (Functional fixes)
**Branch:** feature/issue-53-consolidated-workout
**Beta Build:** https://github.com/justbuildstuff-dev/Fitness-App/actions/runs/20813636317
**QA Agent:** Manual Testing Required
**Date:** 2026-01-08

---

## Overview

This test plan covers manual QA testing for Feature #53 - ConsolidatedWorkoutScreen. The feature consolidates the workout tracking flow from 5 screens down to 3, allowing users to view and manage all exercises and sets for a workout on a single screen.

**Critical:** This feature includes fixes for 5 functional bugs from Issue #258 that MUST be validated.

---

## Test Environment Setup

### Prerequisites
1. **Beta Build:** Download from Firebase App Distribution (QA testers notified)
2. **Test Devices:**
   - Android device (API 21+)
   - iOS device (iOS 12+) if available
3. **Test Data:** Create test program/week/workout with exercises
4. **Network:** Test on WiFi and cellular data

### Installation
1. Download beta build from Firebase notification or App Distribution console
2. Install on test device(s)
3. Launch app and verify it opens without crashes
4. Sign in with test account

---

## Section 1: Functional Bug Fixes (PRIORITY 1 - CRITICAL)

These 5 bugs were fixed in Issue #258 and MUST work correctly:

### Test 1.1: Permission Error When Adding Sets (Bug Fix #1)
**Expected:** No permission errors when adding sets to exercises

**Steps:**
1. Navigate to a workout with at least one exercise
2. Tap "Add Set" button on any exercise
3. Observe the result

**Pass Criteria:**
- ✅ Set is created successfully
- ✅ Success message shown: "Set added successfully"
- ✅ Set appears immediately in the exercise card
- ❌ FAIL if: Permission denied error appears
- ❌ FAIL if: Set not created or error message shown

**Notes:** _____________________________________

---

### Test 1.2: Add Set Button Functionality (Bug Fix #2)
**Expected:** New sets appear immediately without navigation/refresh

**Steps:**
1. Navigate to a workout with exercises
2. Note the current number of sets for an exercise (e.g., "3 sets")
3. Tap "Add Set" button for that exercise
4. Observe the UI immediately (do NOT navigate away)

**Pass Criteria:**
- ✅ Set count increments immediately (e.g., "3 sets" → "4 sets")
- ✅ New set row appears in the exercise card
- ✅ New set has empty/default values
- ✅ Success snackbar shown
- ❌ FAIL if: Set count doesn't update
- ❌ FAIL if: Need to navigate away and back to see new set

**Notes:** _____________________________________

---

### Test 1.3: Set Deletion Functionality (Bug Fix #3)
**Expected:** Deleted sets disappear immediately from UI

**Steps:**
1. Navigate to a workout with exercises that have 2+ sets
2. Note the current number of sets for an exercise (e.g., "4 sets")
3. Tap delete button (trash icon) on a set (not the last set)
4. Confirm deletion in dialog
5. Observe the UI immediately (do NOT navigate away)

**Pass Criteria:**
- ✅ Set count decrements immediately (e.g., "4 sets" → "3 sets")
- ✅ Deleted set row disappears from exercise card
- ✅ Success snackbar shown: "Set deleted successfully"
- ❌ FAIL if: Set still visible after deletion
- ❌ FAIL if: Need to navigate away and back to see deletion

**Notes:** _____________________________________

---

### Test 1.4: Exercise Deletion - No "No Workout Selected" Error (Bug Fix #4)
**Expected:** Exercise deletion works without errors

**Steps:**
1. Navigate to a workout with at least one exercise
2. Tap the 3-dot menu on any exercise card
3. Tap "Delete Exercise"
4. Observe the delete confirmation dialog
5. Confirm deletion

**Pass Criteria:**
- ✅ Delete confirmation dialog shows with cascade counts
- ✅ Dialog shows how many sets will be deleted
- ✅ After confirmation, exercise is deleted successfully
- ✅ Success message shown with exercise name
- ❌ FAIL if: "No workout selected" error appears
- ❌ FAIL if: Any error during deletion
- ❌ FAIL if: Exercise not deleted after confirmation

**Notes:** _____________________________________

---

### Test 1.5: Exercise Creation - Sets Appear Immediately (Bug Fix #5)
**Expected:** When creating a new exercise with sets, all sets appear on screen immediately

**Steps:**
1. Navigate to a workout
2. Tap the floating "+" button (bottom right)
3. Enter exercise name: "Test Exercise"
4. Select exercise type: "Strength"
5. Set number of sets: 3 (using stepper)
6. Tap "Create"
7. Observe the workout screen immediately (do NOT navigate away)

**Pass Criteria:**
- ✅ New exercise card appears immediately
- ✅ Exercise card shows "3 sets"
- ✅ All 3 set rows are visible and expanded
- ✅ Each set has empty/default values (reps: 0, weight: empty)
- ❌ FAIL if: Exercise appears but sets don't show
- ❌ FAIL if: Need to navigate away and back to see sets
- ❌ FAIL if: Wrong number of sets created

**Notes:** _____________________________________

---

## Section 2: Acceptance Criteria Validation (PRIORITY 2)

### Test 2.1: Consolidated Workout Screen

**Test 2.1.1: Screen Layout and Header**
**Steps:**
1. Navigate: Programs → Select Program → Select Week → Select Workout

**Pass Criteria:**
- ✅ Workout name displayed at top of screen
- ✅ Back button navigates to Week screen
- ✅ Edit button visible in app bar (pencil icon)
- ✅ Delete button visible in app bar menu (3 dots)
- ✅ Floating action button (FAB) visible bottom right

**Notes:** _____________________________________

**Test 2.1.2: Empty State**
**Steps:**
1. Create a new workout with no exercises

**Pass Criteria:**
- ✅ Empty state message displayed
- ✅ "Create First Exercise" button or similar prompt shown
- ✅ Tapping button opens create exercise modal

**Notes:** _____________________________________

---

### Test 2.2: Exercise Cards

**Test 2.2.1: Exercise Card Display**
**Steps:**
1. Navigate to a workout with 3+ exercises, each with 2+ sets

**Pass Criteria:**
- ✅ Each exercise displayed as a card
- ✅ Exercise name shown at top of card
- ✅ Exercise type icon shown (dumbbell for strength, running for cardio, etc.)
- ✅ Set count displayed (e.g., "3 sets")
- ✅ Collapse/expand arrow visible
- ✅ Sets are expanded by default

**Notes:** _____________________________________

**Test 2.2.2: Add Set Button**
**Steps:**
1. Find an exercise with fewer than 10 sets
2. Locate the "Add Set" button (+ icon)

**Pass Criteria:**
- ✅ "Add Set" button visible next to exercise name
- ✅ Button enabled (not grayed out)
- ✅ Tapping button adds a new set (see Test 1.2)

**Notes:** _____________________________________

**Test 2.2.3: Add Set Button - Maximum Sets**
**Steps:**
1. Create an exercise or add sets until it has 10 sets
2. Observe the "Add Set" button

**Pass Criteria:**
- ✅ Button is disabled (grayed out)
- ✅ Tooltip shows: "Maximum 10 sets per exercise"
- ✅ Tapping button does nothing

**Notes:** _____________________________________

**Test 2.2.4: Exercise Menu (3-Dot)**
**Steps:**
1. Tap the 3-dot menu on an exercise card
2. Observe the menu options

**Pass Criteria:**
- ✅ Menu opens with options
- ✅ "Edit Name" option visible
- ✅ "Delete Exercise" option visible
- ✅ Icons shown for each option

**Notes:** _____________________________________

**Test 2.2.5: Edit Exercise Name**
**Steps:**
1. Tap 3-dot menu → "Edit Name"
2. Enter new name: "Updated Exercise Name"
3. Save

**Pass Criteria:**
- ✅ Edit name dialog opens
- ✅ Current name pre-filled
- ✅ After saving, exercise name updates immediately
- ✅ No navigation required

**Notes:** _____________________________________

**Test 2.2.6: Exercise Reordering (Drag Handle)**
**Steps:**
1. Find a workout with 2+ exercises
2. Locate drag handle icon on left of exercise card
3. Long-press drag handle and drag exercise up or down

**Pass Criteria:**
- ✅ Drag handle visible on each exercise card
- ✅ Exercises can be dragged to reorder
- ✅ Order persists after release
- ✅ Order persists after navigating away and back

**Notes:** _____________________________________

---

### Test 2.3: Set Rows

**Test 2.3.1: Set Row Display - Strength Exercise**
**Steps:**
1. Create or navigate to a strength exercise
2. Observe the set row fields

**Pass Criteria:**
- ✅ Set number displayed (1, 2, 3, etc.)
- ✅ Checkbox visible on left
- ✅ "Reps *" field visible (required)
- ✅ "Weight" field visible (optional)
- ✅ Notes button visible (note icon)
- ✅ Delete button visible (trash icon)

**Notes:** _____________________________________

**Test 2.3.2: Set Row Display - Cardio Exercise**
**Steps:**
1. Create or navigate to a cardio exercise
2. Observe the set row fields

**Pass Criteria:**
- ✅ Set number displayed
- ✅ Checkbox visible
- ✅ "Duration *" field visible (required)
- ✅ "Distance" field visible (optional)
- ✅ Notes and Delete buttons visible

**Notes:** _____________________________________

**Test 2.3.3: Set Row Display - Bodyweight Exercise**
**Steps:**
1. Create or navigate to a bodyweight exercise
2. Observe the set row fields

**Pass Criteria:**
- ✅ "Reps *" field visible (required)
- ✅ NO "Weight" field shown
- ✅ Checkbox, notes, delete buttons visible

**Notes:** _____________________________________

**Test 2.3.4: Set Completion - Checkbox Behavior**
**Steps:**
1. Navigate to an uncompleted set
2. Enter values: Reps = 10, Weight = 100
3. Tap the checkbox to mark set complete
4. Observe the set row

**Pass Criteria:**
- ✅ Checkbox becomes checked
- ✅ Fields become read-only (grayed out, disabled)
- ✅ Values are locked and can't be edited
- ✅ NO strikethrough on text (Bug #51 fix)
- ✅ NO color change (text stays same color)
- ✅ Data persists to Firestore immediately

**Notes:** _____________________________________

**Test 2.3.5: Set Completion - Unchecking**
**Steps:**
1. Find a completed set (checked)
2. Tap the checkbox to uncheck it

**Pass Criteria:**
- ✅ Checkbox becomes unchecked
- ✅ Fields become editable again
- ✅ Values remain (not cleared)
- ✅ Can now edit reps, weight, etc.

**Notes:** _____________________________________

**Test 2.3.6: Set Notes Modal**
**Steps:**
1. Tap the notes button (note icon) on any set
2. Observe the modal

**Pass Criteria:**
- ✅ Modal opens
- ✅ Text field for notes visible (250 char limit)
- ✅ Rest time picker visible
- ✅ Can enter notes and set rest time
- ✅ Save button saves and closes modal
- ✅ Notes icon changes appearance when notes exist (filled vs outline)

**Notes:** _____________________________________

**Test 2.3.7: Delete Set - Confirmation**
**Steps:**
1. Find an exercise with 2+ sets
2. Tap delete button (trash icon) on a set (NOT the last set)

**Pass Criteria:**
- ✅ Confirmation dialog appears
- ✅ Dialog shows warning message
- ✅ "Cancel" and "Delete" buttons visible
- ✅ Tapping "Cancel" closes dialog, set remains
- ✅ Tapping "Delete" removes set (see Test 1.3)

**Notes:** _____________________________________

**Test 2.3.8: Delete Set - Last Set Prevention**
**Steps:**
1. Find or create an exercise with exactly 1 set
2. Try to tap the delete button on the last set

**Pass Criteria:**
- ✅ Delete button is disabled (grayed out) OR
- ✅ Tapping delete shows error: "Cannot delete last set"
- ✅ Set is NOT deleted

**Notes:** _____________________________________

**Test 2.3.9: Set Fields - Data Entry and Validation**
**Steps:**
1. Navigate to an uncompleted strength set
2. Enter valid data: Reps = 12, Weight = 50.5
3. Navigate away (back button)
4. Navigate back to same workout

**Pass Criteria:**
- ✅ Fields accept numeric input
- ✅ Weight accepts decimals (50.5)
- ✅ Data saves automatically
- ✅ Data persists after navigation

**Notes:** _____________________________________

---

### Test 2.4: Exercise Creation Flow

**Test 2.4.1: Create Exercise Modal**
**Steps:**
1. Navigate to a workout
2. Tap FAB (floating + button) or "Create First Exercise"

**Pass Criteria:**
- ✅ Modal opens
- ✅ Exercise name field visible
- ✅ Exercise type selector visible (Strength, Cardio, Bodyweight, Time-Based, Custom)
- ✅ Sets stepper visible (+ and - buttons)
- ✅ Default sets = 1
- ✅ Notes field visible (optional)

**Notes:** _____________________________________

**Test 2.4.2: Create Exercise - Set Count Stepper**
**Steps:**
1. Open create exercise modal
2. Use + button to increase sets
3. Use - button to decrease sets

**Pass Criteria:**
- ✅ + button increments count (1 → 2 → 3...)
- ✅ - button decrements count (3 → 2 → 1)
- ✅ Minimum sets = 1 (- button disabled at 1)
- ✅ Maximum sets = 10 (+ button disabled at 10)

**Notes:** _____________________________________

**Test 2.4.3: Create Exercise - Complete Flow**
**Steps:**
1. Open create exercise modal
2. Enter name: "Bench Press"
3. Select type: "Strength"
4. Set sets count: 5
5. Tap "Create" button
6. Observe the workout screen

**Pass Criteria:**
- ✅ Modal closes
- ✅ New exercise card appears immediately
- ✅ Exercise name = "Bench Press"
- ✅ Exercise type icon = strength (dumbbell)
- ✅ 5 set rows visible
- ✅ All sets have default values (reps: 0, weight: empty)
- ✅ User remains on workout screen (no navigation)

**Notes:** _____________________________________

---

### Test 2.5: Data Persistence and Sync

**Test 2.5.1: Completed Sets Persist**
**Steps:**
1. Mark a set as complete (checkbox)
2. Enter reps and weight
3. Force quit app
4. Relaunch app
5. Navigate to same workout

**Pass Criteria:**
- ✅ Set is still checked
- ✅ Values are still present
- ✅ Set is still read-only

**Notes:** _____________________________________

**Test 2.5.2: Exercise Deletion Cascades**
**Steps:**
1. Note an exercise with 5 sets
2. Delete the exercise
3. Confirm deletion
4. Check Firestore console or analytics (if accessible)

**Pass Criteria:**
- ✅ Exercise is deleted
- ✅ All 5 sets are deleted (cascade delete)
- ✅ Analytics data related to exercise is cleaned up
- ✅ Deletion confirmation dialog shows: "This will delete 5 sets"

**Notes:** _____________________________________

**Test 2.5.3: Real-time Sync (Multi-device)**
**Steps:**
1. Open same workout on two devices (if available)
2. On Device A: Add a set to an exercise
3. Observe Device B

**Pass Criteria:**
- ✅ New set appears on Device B automatically (within 2-3 seconds)
- ✅ No manual refresh needed

**Notes:** _____________________________________

---

## Section 3: Edge Cases and Error Handling

### Test 3.1: Network Conditions

**Test 3.1.1: Offline - Data Entry**
**Steps:**
1. Navigate to a workout
2. Turn off WiFi and cellular data
3. Add a new set
4. Enter reps and weight
5. Turn network back on

**Pass Criteria:**
- ✅ UI updates immediately even offline
- ✅ No crash or error
- ✅ When network returns, data syncs to Firestore
- ✅ Success message or indicator shown

**Notes:** _____________________________________

**Test 3.1.2: Slow Network**
**Steps:**
1. Enable network throttling (if available) or use slow network
2. Navigate to a workout
3. Add a set

**Pass Criteria:**
- ✅ Loading indicator shown while syncing
- ✅ No timeout errors
- ✅ Set is created successfully
- ✅ No duplicate sets created

**Notes:** _____________________________________

---

### Test 3.2: Boundary Conditions

**Test 3.2.1: Maximum Sets (10)**
**Steps:**
1. Create an exercise with 10 sets
2. Try to add an 11th set

**Pass Criteria:**
- ✅ Add Set button is disabled
- ✅ Tooltip shows max limit message
- ✅ Cannot add more than 10 sets

**Notes:** _____________________________________

**Test 3.2.2: Large Numbers**
**Steps:**
1. Enter very large values: Reps = 9999, Weight = 9999.99
2. Save and verify

**Pass Criteria:**
- ✅ Values are accepted and saved
- ✅ Display doesn't break or overflow
- ✅ Values persist correctly

**Notes:** _____________________________________

**Test 3.2.3: Decimal Precision**
**Steps:**
1. Enter weight: 45.25
2. Save and reload

**Pass Criteria:**
- ✅ Decimal values accepted
- ✅ Precision maintained (45.25, not 45.3 or 45)

**Notes:** _____________________________________

---

### Test 3.3: UI and UX

**Test 3.3.1: Screen Rotation**
**Steps:**
1. Navigate to workout screen
2. Rotate device to landscape
3. Rotate back to portrait

**Pass Criteria:**
- ✅ Layout adapts correctly
- ✅ No data loss during rotation
- ✅ Scroll position maintained (or reasonable)

**Notes:** _____________________________________

**Test 3.3.2: Rapid Actions**
**Steps:**
1. Rapidly tap "Add Set" button 5 times quickly
2. Observe the result

**Pass Criteria:**
- ✅ Only 5 sets are created (no duplicates)
- ✅ Button disabled during processing OR
- ✅ Debouncing prevents multiple creates

**Notes:** _____________________________________

**Test 3.3.3: Long Exercise/Workout Names**
**Steps:**
1. Create exercise with very long name (100 characters)
2. Observe display on exercise card

**Pass Criteria:**
- ✅ Name displays correctly (truncated with ... if needed)
- ✅ Layout doesn't break
- ✅ Full name visible in edit dialog

**Notes:** _____________________________________

**Test 3.3.4: Many Exercises (10+)**
**Steps:**
1. Create a workout with 15 exercises, each with 5 sets
2. Navigate to workout screen

**Pass Criteria:**
- ✅ All exercises load and display
- ✅ Scrolling is smooth
- ✅ No performance lag
- ✅ No memory issues or crashes

**Notes:** _____________________________________

---

## Section 4: Regression Testing

### Test 4.1: Existing Features Still Work

**Test 4.1.1: Programs Screen**
**Steps:**
1. Navigate to Programs screen
2. Create new program
3. View program details

**Pass Criteria:**
- ✅ Programs screen loads correctly
- ✅ Can create new program
- ✅ Program list displays correctly

**Notes:** _____________________________________

**Test 4.1.2: Weeks Screen**
**Steps:**
1. Navigate to a program
2. View weeks list
3. Create new week
4. View week details

**Pass Criteria:**
- ✅ Weeks screen loads correctly
- ✅ Can create new week
- ✅ Week list displays correctly

**Notes:** _____________________________________

**Test 4.1.3: Navigation Flow**
**Steps:**
1. Navigate: Home → Programs → Select Program → Weeks → Select Week → Workouts → Select Workout
2. Use back button to navigate backward

**Pass Criteria:**
- ✅ All navigation works correctly
- ✅ Back button navigates to correct previous screen
- ✅ No unexpected navigation behavior

**Notes:** _____________________________________

**Test 4.1.4: Analytics (if applicable)**
**Steps:**
1. Complete several sets in a workout
2. Check analytics/progress screens

**Pass Criteria:**
- ✅ Analytics data is tracked correctly
- ✅ Completed sets appear in analytics
- ✅ No errors in analytics features

**Notes:** _____________________________________

---

## Section 5: Cross-Platform Testing (iOS vs Android)

**Note:** If testing on both platforms, execute the above tests on BOTH Android and iOS.

### Platform-Specific Checks

**Test 5.1: Platform UI Consistency**
**Steps:**
1. Compare UI elements on Android vs iOS

**Pass Criteria:**
- ✅ Material Design on Android (Material 3)
- ✅ Cupertino/iOS styling on iOS (if applicable)
- ✅ Consistent behavior across platforms
- ✅ No platform-specific crashes

**Notes:** _____________________________________

---

## Test Results Summary

### Critical Functional Fixes (Section 1)
- [ ] Test 1.1: Permission error - PASS / FAIL
- [ ] Test 1.2: Add Set functionality - PASS / FAIL
- [ ] Test 1.3: Set deletion - PASS / FAIL
- [ ] Test 1.4: Exercise deletion error - PASS / FAIL
- [ ] Test 1.5: Exercise creation sets - PASS / FAIL

### Acceptance Criteria (Section 2)
- [ ] 2.1: Consolidated Workout Screen - PASS / FAIL
- [ ] 2.2: Exercise Cards - PASS / FAIL
- [ ] 2.3: Set Rows - PASS / FAIL
- [ ] 2.4: Exercise Creation - PASS / FAIL
- [ ] 2.5: Data Persistence - PASS / FAIL

### Edge Cases (Section 3)
- [ ] 3.1: Network Conditions - PASS / FAIL
- [ ] 3.2: Boundary Conditions - PASS / FAIL
- [ ] 3.3: UI/UX - PASS / FAIL

### Regression (Section 4)
- [ ] 4.1: Existing Features - PASS / FAIL

### Cross-Platform (Section 5)
- [ ] 5.1: Platform Consistency - PASS / FAIL / N/A

---

## Final QA Decision

**Overall Status:** ⬜ APPROVE FOR DEPLOYMENT / ⬜ REJECT - NEEDS FIXES

**Critical Bugs Found:** (List any critical issues)
-

**High Priority Bugs Found:** (List any high priority issues)
-

**Medium/Low Issues Found:** (List any medium/low priority issues that don't block deployment)
-

**QA Tester Name:** _____________________________________

**Date Completed:** _____________________________________

**Devices Tested:**
- Android: _____________________________________
- iOS: _____________________________________

**Additional Notes:**




---

## Next Steps

**If QA APPROVED:**
1. Document results on Issue #53
2. Add label: `qa-approved`
3. Remove label: `ready-for-qa`
4. Hand off to Deployment Agent

**If QA REJECTED:**
1. Create bug issues for each critical/high priority bug
2. Document all issues on Issue #53
3. Hand back to Developer Agent
4. Developer fixes bugs and resubmits to Testing Agent
