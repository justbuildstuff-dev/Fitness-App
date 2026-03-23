# Onboarding Flow

## Overview

New users currently land on an empty Programs screen immediately after sign-up with no context or guidance. The Onboarding Flow introduces FitTrack's core value proposition and walks first-time users through the app's structured hierarchy (Programs → Weeks → Workouts → Exercises → Sets), then guides them through creating their first program via a step-by-step wizard. The goal is to reduce early drop-off by ensuring users experience meaningful value before they encounter an empty state.

**Status:** Ready for Design
**Priority:** Medium
**Platform:** iOS + Android
**Feature Type:** New Feature
**GitHub Issue:** [#411](https://github.com/justbuildstuff-dev/Fitness-App/issues/411)

---

## User Problem

First-time users who sign up for FitTrack arrive at an empty Programs screen with no explanation of what to do, why the hierarchy exists, or what the app can do for them. The structured Program → Week → Workout → Exercise → Sets model is FitTrack's core differentiator, but it is not self-evident to a new user. Without guidance, users either abandon immediately or create programs incorrectly and miss the analytics value that comes from consistent, structured tracking.

---

## Existing Implementation Context

- **Authentication screens** are complete: `SignInScreen`, `SignUpScreen`, `AuthWrapper`
- **AuthWrapper** currently routes directly to `HomeScreen` (Programs tab) after sign-up — no onboarding hook exists
- **Settings screen** exists at `lib/screens/settings/settings_screen.dart` as a placeholder — needs a wizard re-launch trigger
- **CreateProgramScreen, CreateWeekScreen, CreateWorkoutScreen, CreateExerciseScreen** all exist and are fully functional — the wizard will reuse these or replicate their logic in a guided context
- **SharedPreferences** (or equivalent) needed to track onboarding completion state
- No existing onboarding PRD or implementation

---

## User Stories

### US-1: Value Proposition Carousel

As a first-time FitTrack user who has just created an account,
I want to see a brief visual overview of what FitTrack offers,
so that I understand the app's structure and the benefits of using it before I start.

**Acceptance Criteria:**
- [ ] A carousel of 4 screens is shown immediately after first sign-up, before the Programs screen
- [ ] Screen 1 explains the program hierarchy (Programs → Weeks → Workouts → Exercises → Sets) with a simple visual
- [ ] Screen 2 highlights detailed set tracking (all exercise types, rest time, notes)
- [ ] Screen 3 previews the analytics value (heatmap, streaks, personal records)
- [ ] Screen 4 summarises the free tier with a primary CTA ("Set Up My First Program") and a secondary skip link ("Skip to App")
- [ ] A "Skip" option is available on every screen (not just the last)
- [ ] Skipping at any point takes the user directly to the Program Setup Wizard (not the app)
- [ ] The carousel is only shown once — never again after first completion or skip
- [ ] The carousel does not appear for existing users who log in

### US-2: Program Setup Wizard

As a first-time FitTrack user,
I want to be guided step-by-step through creating my first program,
so that I have something real to work with on my first session and understand how the hierarchy works.

**Acceptance Criteria:**
- [ ] Wizard consists of 4 sequential steps: (1) Name program, (2) Create first week, (3) Create first workout, (4) Add first exercise
- [ ] Each step is clearly numbered and shows overall progress (e.g., "Step 2 of 4")
- [ ] Each step has a "Skip" option that advances to the next step without creating that entity
- [ ] If the user skips Step 1 (program name), the entire wizard is abandoned and the user goes to the Programs screen (nothing to save without a program)
- [ ] If the user skips any step after Step 1, progress made so far is saved (partial program persists)
- [ ] On wizard completion, the user is taken to the Programs list (showing their newly created program)
- [ ] On any mid-wizard skip (Steps 2–4), the user is taken to the Programs list with partial progress preserved
- [ ] Input validation follows the same rules as the existing Create screens

### US-3: Wizard Completion & Subtle Pro Awareness

As a user who has just completed the setup wizard,
I want to see a completion confirmation and be lightly made aware that a Pro tier exists,
so that I feel rewarded for completing setup and know there is more available without feeling pressured.

**Acceptance Criteria:**
- [ ] A completion screen is shown after Step 4 is finished (or the last non-skipped step)
- [ ] The completion screen confirms what was created ("Your program '[Name]' is ready!")
- [ ] A single, low-emphasis text link ("Explore FitTrack Pro →") is shown below the primary CTA
- [ ] Tapping the Pro link navigates to a Pro information screen (or placeholder for future paywall)
- [ ] The Pro link is visually subordinate to the primary CTA — it must not look like a button or use accent colour
- [ ] No Pro mention appears anywhere in the value prop carousel or wizard steps

### US-4: Onboarding Skip Flows

As a first-time user who already understands the app or prefers to explore independently,
I want to skip onboarding entirely or exit at any point,
so that I am never forced through a process I don't need.

**Acceptance Criteria:**
- [ ] Skipping the value prop carousel goes directly to the wizard (not the app)
- [ ] Skipping the wizard at Step 1 (before naming a program) goes to the Programs screen with nothing saved
- [ ] Skipping the wizard at Steps 2–4 saves partial progress and goes to the Programs screen
- [ ] All skip actions are confirmed immediately (no "Are you sure?" dialogs)
- [ ] Onboarding state is marked as complete on any skip so it never re-shows automatically

### US-5: Re-launch Wizard from Settings

As an existing FitTrack user who wants to create a new program with guided assistance,
I want to be able to re-launch the setup wizard from the Settings screen,
so that I can get structured help even after initial onboarding is complete.

**Acceptance Criteria:**
- [ ] A "Set Up a New Program" (or "Relaunch Setup Wizard") option is visible in the Settings screen
- [ ] Launching from Settings starts the wizard only (not the value prop carousel)
- [ ] The wizard launched from Settings behaves identically to the first-launch wizard
- [ ] The Settings wizard skip/completion always routes back to the Programs list

### US-6: Onboarding State Persistence

As a user who closes the app mid-onboarding,
I want the app to remember where I was,
so that I'm not forced to restart onboarding from the beginning on relaunch.

**Acceptance Criteria:**
- [ ] Onboarding state is persisted locally (e.g., SharedPreferences): `not_started`, `carousel_seen`, `wizard_started`, `complete`
- [ ] If the app is closed mid-carousel, it resumes the carousel at the first screen on relaunch (carousel is short; resuming mid-carousel is not required)
- [ ] If the app is closed mid-wizard with a program already created (Step 1 complete), the wizard is skipped on relaunch and the user goes to Programs (program already exists)
- [ ] Once state is `complete` or skipped, onboarding never auto-shows again

---

## Functional Requirements

- **FR-1:** Onboarding triggers automatically for new users after first sign-up, detected via a local persistence flag
- **FR-2:** The value prop carousel contains exactly 4 screens with skip available on all screens
- **FR-3:** The wizard contains exactly 4 steps (Program → Week → Workout → Exercise) with skip on each
- **FR-4:** Partial wizard progress (program created, week/workout/exercise not created) is persisted to Firestore
- **FR-5:** Onboarding is marked complete in local storage on any exit (skip or finish)
- **FR-6:** The Settings screen exposes a re-launch trigger for the wizard only
- **FR-7:** The completion screen includes one subtle Pro text link and a primary "Go to My Program" CTA
- **FR-8:** No Pro mention appears in carousel or wizard step screens
- **FR-9:** The value prop carousel must not be shown to returning/existing users on subsequent logins
- **FR-10:** Wizard input validation must match existing Create screen validation rules

---

## Non-Functional Requirements

- **NFR-1: Performance** — Carousel transitions must animate at 60fps. Wizard steps must load instantly (no network calls between steps except Firestore writes on confirmation)
- **NFR-2: Accessibility** — All onboarding screens must meet WCAG AA: minimum 4.5:1 contrast, semantic labels on all interactive elements, minimum 48×48dp touch targets, screen reader compatible
- **NFR-3: Offline Behaviour** — If the user is offline during the wizard, show an appropriate error when attempting to save to Firestore. Do not silently fail. The carousel can be shown offline (no network dependency)
- **NFR-4: Platform Consistency** — Material Design 3 on Android, consistent with existing app design on iOS. No platform-specific onboarding UI divergence
- **NFR-5: Data Integrity** — Any Firestore writes during the wizard must use the same validation and data model as the existing Create screens
- **NFR-6: First Impression** — Onboarding must feel fast and lightweight. Total carousel read time target: under 60 seconds. Wizard minimum path (name program only): under 30 seconds

---

## User Flow

### First Launch (Full)
1. User completes sign-up → `AuthWrapper` detects `onboarding_state = not_started`
2. Value prop Carousel Screen 1 shown ("How FitTrack works")
3. User taps Next → Screen 2 ("Track every rep")
4. User taps Next → Screen 3 ("See your progress")
5. User taps Next → Screen 4 ("Start free" + CTA)
6. User taps "Set Up My First Program" → Wizard Step 1
7. User enters program name → taps Next → Firestore write (program created)
8. Wizard Step 2: User enters week name → taps Next → Firestore write
9. Wizard Step 3: User enters workout name/day → taps Next → Firestore write
10. Wizard Step 4: User selects exercise type + name → taps "Finish" → Firestore write
11. Completion screen shown ("Your program is ready!") with subtle Pro link
12. User taps "Go to My Program" → Programs list (showing new program)
13. `onboarding_state = complete` persisted locally

### First Launch (Skip Carousel)
1. User completes sign-up → Carousel Screen 1 shown
2. User taps "Skip" → Wizard Step 1 shown directly
3. Flow continues as wizard path above

### First Launch (Skip Wizard at Step 1)
1. Wizard Step 1 shown → User taps "Skip"
2. Nothing saved. `onboarding_state = complete`
3. User routed to Programs list (empty)

### First Launch (Skip Wizard at Step 3)
1. Wizard Steps 1–2 completed (program + week saved)
2. User taps "Skip" at Step 3
3. Program and week saved. `onboarding_state = complete`
4. User routed to Programs list

### Re-launch from Settings
1. User navigates to Settings → taps "Set Up a New Program"
2. Wizard Step 1 shown (no carousel)
3. Flow identical to first-launch wizard

---

## Edge Cases & Error Handling

- **Offline during wizard write:** Show snackbar error "Could not save — check your connection." Do not advance the step. Allow retry.
- **App closed mid-carousel:** Resume from Screen 1 on relaunch (carousel is < 60s, no mid-carousel resume needed)
- **App closed after Step 1 (program saved):** On relaunch, skip onboarding. Program exists in Programs list.
- **User creates duplicate program name:** Follow existing `CreateProgramScreen` validation (names don't need to be unique in data model, so this is not an error)
- **Very long program name:** Truncate in completion screen display, consistent with existing screen behaviour
- **Existing user logs in on a new device:** `onboarding_state` is stored locally — will show onboarding again on the new device. Acceptable behaviour for v1.

---

## Technical Considerations

- **Onboarding state:** Use `SharedPreferences` (or `flutter_secure_storage` if needed) to persist `onboarding_state` locally. Key: `fittrack_onboarding_state`. Values: `not_started`, `complete`.
- **AuthWrapper integration:** `AuthWrapper` must check `onboarding_state` after authentication and route to `OnboardingCarousel` or `HomeScreen` accordingly
- **Wizard Firestore writes:** Reuse existing `ProgramProvider` methods (`createProgram`, `createWeek`, `createWorkout`, `createExerciseWithSets`). The wizard is a guided UI layer over existing business logic.
- **Settings screen:** Currently a placeholder — needs a list tile added to trigger wizard re-launch
- **No Notion MCP available:** PRD stored in `Docs/PRDs/` per project convention
- **Dependencies:** No new packages expected. `shared_preferences` may already be in `pubspec.yaml`; confirm during SA phase.

---

## Success Metrics

- **Activation rate:** % of new sign-ups who create at least one program within 7 days (target: increase from baseline)
- **Wizard completion rate:** % of users who complete all 4 wizard steps (target: >40%)
- **Skip rate at carousel:** % of users who skip the carousel (informational — not a failure metric)
- **Day-7 retention:** % of users who return on day 7 (onboarding should improve this vs baseline)

---

## Overall Acceptance Criteria

- [ ] Value prop carousel shown exactly once to new users after sign-up, never to returning users
- [ ] Carousel has 4 screens, skip available on all, skipping goes to wizard
- [ ] Wizard has 4 steps (Program → Week → Workout → Exercise), skip on all steps
- [ ] Skipping Step 1 saves nothing and routes to Programs list
- [ ] Skipping Steps 2–4 saves partial progress and routes to Programs list
- [ ] Completion screen shows subtle Pro text link (no button, no accent colour)
- [ ] No Pro mention in carousel or wizard steps
- [ ] Settings screen has wizard re-launch option
- [ ] Onboarding state persisted locally; never auto-shows after first completion/skip
- [ ] All screens WCAG AA compliant
- [ ] Offline error handling for wizard Firestore writes
- [ ] iOS and Android both supported
