# PRD: Workout Templates & Pre-built Programs

**GitHub Issue:** [#260](https://github.com/justbuildstuff-dev/Fitness-App/issues/260)
**Priority:** High
**Platform:** Both (iOS & Android)
**Status:** Ready for Design
**Created:** 2026-01-30
**BA Agent:** Requirements Complete

---

## Overview

Enable users to save workouts, weeks, and programs as reusable templates, and provide a library of pre-built training programs. This feature dramatically reduces setup friction by allowing users to create new training content from proven templates rather than building from scratch.

## User Problem

New users face significant setup friction when starting to use FitTrack. Creating a complete training program requires manually configuring programs, weeks, workouts, exercises, and sets - a process that can take 15-30 minutes before a user can even start training. This friction leads to drop-off during the critical first-week onboarding period. Experienced users also waste time recreating similar workout structures repeatedly.

---

## User Stories

### US-1: Browse Pre-built Programs

As a new user who wants to start training immediately,
I want to browse a library of pre-built training programs,
so that I can begin a proven program without spending time creating one from scratch.

**Acceptance Criteria:**
- [ ] Pre-built programs are accessible from the Programs screen via "From Template" option
- [ ] At least 5 pre-built programs are available: Push/Pull/Legs (6-day), Upper/Lower (4-day), Full Body (3-day), 5x5 Strength (3-day), Bro Split (5-day)
- [ ] Each program shows a preview with: program name, description, number of weeks, list of workouts per week
- [ ] Programs are fetched from Firebase (server-side storage)
- [ ] Works offline after initial fetch (cached locally)
- [ ] Works on both iOS and Android

### US-2: Create Program from Pre-built Template

As a user who has selected a pre-built program,
I want to create a copy of that program in my account,
so that I can start using it immediately and customize it if needed.

**Acceptance Criteria:**
- [ ] Tapping "Use Template" creates a full copy of the program (all weeks, workouts, exercises, sets)
- [ ] Program name uses auto-suffix if duplicate exists (e.g., "Push Pull Legs", "Push Pull Legs (1)")
- [ ] All weight/distance values are reset to empty (user fills in their own)
- [ ] All set `checked` values are reset to false
- [ ] Exercise types, set counts, and rep targets are preserved from template
- [ ] Created program appears in user's program list immediately
- [ ] User can edit/customize the created program after creation

### US-3: Save Workout as Template

As a user who has created a workout I want to reuse,
I want to save that workout as a template,
so that I can quickly apply the same workout structure to other weeks.

**Acceptance Criteria:**
- [ ] "Save as Template" option available in workout detail screen menu
- [ ] User can provide a custom name for the template (defaults to workout name)
- [ ] Template captures: workout name, all exercises (names, types, order), all sets (set numbers, rep targets, rest times)
- [ ] Weight values are NOT saved in template (always start fresh)
- [ ] User can save up to 10 workout templates
- [ ] Error message shown if limit reached with option to manage templates
- [ ] Confirmation shown after successful save

### US-4: Save Week as Template

As a user who has created a training week I want to reuse,
I want to save that week as a template,
so that I can quickly duplicate my weekly structure in other programs.

**Acceptance Criteria:**
- [ ] "Save as Template" option available in week detail screen menu
- [ ] User can provide a custom name for the template (defaults to week name)
- [ ] Template captures: week name, all workouts with their exercises and sets
- [ ] Weight values are NOT saved in template
- [ ] User can save up to 10 week templates
- [ ] Error message shown if limit reached with option to manage templates
- [ ] Confirmation shown after successful save

### US-5: Save Program as Template

As a user who has created a complete program I want to share or reuse,
I want to save that program as a template,
so that I can recreate it or use it as a starting point for variations.

**Acceptance Criteria:**
- [ ] "Save as Template" option available in program detail screen menu
- [ ] User can provide a custom name for the template (defaults to program name)
- [ ] Template captures: program name, description, all weeks/workouts/exercises/sets structure
- [ ] Weight values are NOT saved in template
- [ ] User can save up to 10 program templates
- [ ] Error message shown if limit reached with option to manage templates
- [ ] Confirmation shown after successful save

### US-6: Create Workout from User Template

As a user who wants to add a familiar workout to a week,
I want to create a workout from one of my saved templates,
so that I don't have to manually recreate the same exercises and sets.

**Acceptance Criteria:**
- [ ] "From Template" option available on CreateWorkoutScreen
- [ ] Template picker shows flat list of user's workout templates
- [ ] Preview shows: template name, list of exercises with set counts
- [ ] Selecting template and confirming creates workout with all exercises and sets
- [ ] Workout name uses auto-suffix if duplicate exists in same week
- [ ] Weight values start empty, checked values start false
- [ ] User can continue editing workout after creation from template

### US-7: Create Week from User Template

As a user who wants to add a structured week to a program,
I want to create a week from one of my saved templates,
so that I can quickly set up a full training week.

**Acceptance Criteria:**
- [ ] "From Template" option available on CreateWeekScreen
- [ ] Template picker shows flat list of user's week templates
- [ ] Preview shows: template name, list of workouts with exercise counts
- [ ] Selecting template creates week with all workouts, exercises, and sets
- [ ] Week order is calculated (next available in program)
- [ ] Week name uses auto-suffix if duplicate exists
- [ ] All weight values empty, all checked values false

### US-8: Manage User Templates

As a user who has saved templates,
I want to view, edit, and delete my templates,
so that I can keep my template library organized.

**Acceptance Criteria:**
- [ ] "My Templates" accessible from Settings/Profile screen
- [ ] Shows three sections: Workout Templates, Week Templates, Program Templates
- [ ] Each template shows: name, content summary (exercise count/workout count/week count)
- [ ] Swipe or menu option to delete template
- [ ] Delete confirmation dialog shown
- [ ] Option to rename template
- [ ] Editing template content is NOT supported (must delete and re-save)
- [ ] Deleting template does NOT affect workouts/weeks/programs created from it

---

## Functional Requirements

| ID | Requirement |
|----|-------------|
| FR-1 | Pre-built program library stored in Firebase with offline caching |
| FR-2 | User templates stored in Firestore under `users/{userId}/templates/` collections |
| FR-3 | Template limits enforced: 10 workout + 10 week + 10 program templates per user |
| FR-4 | Auto-suffix naming using existing `SmartCopyNaming` pattern |
| FR-5 | Deep copy operations using batched writes (≤450 ops per batch) |
| FR-6 | Template creation preserves structure but resets tracking values (weight, checked) |
| FR-7 | Templates are snapshots - no live link to source content |
| FR-8 | Template deletion does not cascade to created content |

---

## Non-Functional Requirements

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-1 | Performance | Template application completes within 3 seconds for largest program (6 weeks × 6 workouts × 6 exercises × 5 sets = 1,080 sets) |
| NFR-2 | Offline | Pre-built programs available offline after first fetch; user templates always available offline |
| NFR-3 | Accessibility | All template selection UI elements have semantic labels for screen readers |
| NFR-4 | Platform | Consistent experience on iOS and Android |
| NFR-5 | Scalability | Architecture supports future community template sharing without fundamental rework |

---

## User Flows

### Flow 1: New User Starts with Pre-built Program

1. User signs up and lands on empty Programs screen
2. User taps FAB → sees "Create Program" and "From Template" options
3. User taps "From Template"
4. Template picker shows pre-built programs with previews
5. User selects "Push Pull Legs (6-day)"
6. User sees preview: 2 weeks, 6 workouts/week, workout names
7. User taps "Use Template"
8. System creates full program copy with all content
9. User sees new program in list, navigates to first workout, starts training

### Flow 2: User Saves Workout as Template

1. User is on ConsolidatedWorkoutScreen viewing "Push Day"
2. User taps overflow menu → "Save as Template"
3. Dialog shows template name field (pre-filled with "Push Day")
4. User confirms
5. Success snackbar: "Workout saved as template"
6. Template is now available in user's template library

### Flow 3: User Creates Workout from Template

1. User is on WeeksScreen, taps FAB to add workout
2. User taps "From Template" on CreateWorkoutScreen
3. Template picker shows user's workout templates
4. User taps "Push Day" template, sees preview
5. User taps "Use Template"
6. Workout created with all exercises and empty sets
7. User can optionally edit name/details before saving

---

## Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| User at template limit (10) tries to save another | Error dialog: "You've reached the limit of 10 [type] templates. Delete an existing template to save a new one." with button to "Manage Templates" |
| Network error while fetching pre-built programs | Show cached programs if available; otherwise show error with retry button |
| Template application fails mid-batch | Rollback all changes, show error, user can retry |
| User tries to create from deleted template | Template should be removed from cache; show "Template no longer available" |
| Duplicate name in target location | Auto-suffix applied: "Push Day" → "Push Day (1)" |
| Very large template (1000+ sets) | Progress indicator during creation; batched writes handle size |

---

## Technical Considerations

### Architecture

- Follows existing Exercise Library pattern (bundled JSON for pre-built, Firestore for user data)
- Pre-built programs: Firebase Firestore collection `prebuiltPrograms/` (server-side, admin-managed)
- User templates: Firestore collections under `users/{userId}/workoutTemplates/`, `weekTemplates/`, `programTemplates/`
- Reuse existing `SmartCopyNaming` utility for auto-suffix
- Reuse batched write pattern from week duplication

### Data Model (High-Level)

- `WorkoutTemplate`: name, exercises[], sets[][], createdAt, userId
- `WeekTemplate`: name, workouts[] (each with exercises/sets), createdAt, userId
- `ProgramTemplate`: name, description, weeks[] (each with workouts/exercises/sets), createdAt, userId
- Pre-built programs: Same structure but stored in admin-controlled collection

### Security

- User templates scoped by userId in Firestore rules
- Pre-built programs: read-only for all authenticated users
- Template content copied on use (no reference to original)

### Future Extensibility

- Architecture should support adding `isPublic` flag to templates
- Collection structure should allow querying public templates across users
- Consider adding `sourceUserId` field for attribution (not displayed in v1)

---

## Pre-built Programs Content

The following 5 programs will be included at launch:

### 1. Push Pull Legs (6-day)

**Description:** Classic 6-day split hitting each muscle group twice per week. Ideal for intermediate to advanced lifters.

**Structure:**
- Week 1-4 (repeating):
  - Day 1: Push A (Chest/Shoulders/Triceps)
  - Day 2: Pull A (Back/Biceps)
  - Day 3: Legs A (Quads/Hamstrings/Calves)
  - Day 4: Push B (Chest/Shoulders/Triceps)
  - Day 5: Pull B (Back/Biceps)
  - Day 6: Legs B (Quads/Hamstrings/Calves)

### 2. Upper Lower (4-day)

**Description:** Efficient 4-day split for balanced development. Great for intermediate lifters with moderate time availability.

**Structure:**
- Week 1-4 (repeating):
  - Day 1: Upper A
  - Day 2: Lower A
  - Day 3: Rest
  - Day 4: Upper B
  - Day 5: Lower B

### 3. Full Body (3-day)

**Description:** Beginner-friendly 3-day program hitting all muscle groups each session. Perfect for new lifters or those with limited time.

**Structure:**
- Week 1-4 (repeating):
  - Day 1: Full Body A
  - Day 2: Rest
  - Day 3: Full Body B
  - Day 4: Rest
  - Day 5: Full Body C

### 4. 5x5 Strength (3-day)

**Description:** Linear progression strength program focused on compound lifts. Ideal for building foundational strength.

**Structure:**
- Week 1-12 (progressive):
  - Day 1: Squat, Bench Press, Barbell Row
  - Day 2: Rest
  - Day 3: Squat, Overhead Press, Deadlift
  - Day 4: Rest
  - Day 5: Squat, Bench Press, Barbell Row

### 5. Bro Split (5-day)

**Description:** Classic bodybuilding split with dedicated days for each muscle group. Popular for hypertrophy focus.

**Structure:**
- Week 1-4 (repeating):
  - Day 1: Chest
  - Day 2: Back
  - Day 3: Shoulders
  - Day 4: Arms (Biceps/Triceps)
  - Day 5: Legs

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| New users creating first program from template | 60%+ | Analytics: template vs manual creation |
| Users completing workout from templated program in first 7 days | 40%+ | Analytics: workout completion tracking |
| Average templates saved per active user | Track over time | Analytics: template creation events |
| 7-day retention comparison | Template users > manual users | Cohort analysis |

---

## Out of Scope (v1)

- Community/shared templates (architecture prepared but UI not implemented)
- Template categories or tags (flat list only)
- Template editing (delete and re-save instead)
- Quick start from recent workouts
- Template versioning or sync with original

---

## Overall Acceptance Criteria

- [ ] 5 pre-built programs available and functional
- [ ] Users can save workouts, weeks, and programs as templates (10 each limit)
- [ ] Users can create content from both pre-built and user templates
- [ ] "From Template" option available on all create screens
- [ ] Template preview shows appropriate content summary
- [ ] Templates do not affect created content when deleted
- [ ] Works offline (cached pre-built programs, locally stored user templates)
- [ ] 90%+ test coverage for new functionality

---

## Appendix: Existing Patterns to Reuse

### Week Duplication (Reference)
- Location: `lib/services/firestore_service.dart` lines 472-704
- Pattern: Batched writes with ≤450 operations per batch
- Deep copy with ID regeneration and timestamp refresh

### Smart Copy Naming (Reference)
- Location: `lib/utils/smart_copy_naming.dart`
- Pattern: Auto-suffix with gap filling ("Copy 1", "Copy 2", etc.)

### Exercise Library (Reference)
- Location: `lib/providers/exercise_library_provider.dart`
- Pattern: Bundled JSON + Firestore user data hybrid
