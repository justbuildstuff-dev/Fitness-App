# Onboarding Flow — Technical Design

**Feature:** Onboarding Flow
**GitHub Issue:** [#411](https://github.com/justbuildstuff-dev/Fitness-App/issues/411)
**PRD:** [Docs/PRDs/Onboarding_Flow_PRD.md](../PRDs/Onboarding_Flow_PRD.md)
**Status:** Design Approved
**Author:** SA Agent

---

## Current Architecture Analysis

**State Management:** Provider pattern throughout. `ChangeNotifierProvider` and `ChangeNotifierProxyProvider` in `main.dart`. App-level preferences received via constructor (e.g., `ThemeProvider(prefs)`), not via `Provider.of` inside widgets.

**SharedPreferences pattern:** `main.dart` calls `await SharedPreferences.getInstance()` then passes the `prefs` instance to `FitTrackApp`, which provides it to providers. Reads are synchronous (prefs is pre-loaded). See `ThemeProvider` — static key constants, constructor reads, setters write+notify.

**AuthWrapper pattern:** `lib/screens/auth/auth_wrapper.dart` — `StatelessWidget` with `Consumer<AuthProvider>`. Routing is entirely synchronous based on provider state. Currently routes: loading → `CircularProgressIndicator`, unauthenticated → `SignInScreen`, unverified → `EmailVerificationScreen`, authenticated+verified → `HomeScreen`.

**Create screen pattern:** All Create screens (`CreateProgramScreen`, `CreateWeekScreen`, `CreateWorkoutScreen`, `CreateExerciseScreen`) follow the same structure: `StatefulWidget`, `GlobalKey<FormState>`, `TextEditingController`(s), `bool _isLoading`, async `_saveX()` method via `Provider.of<ProgramProvider>(context, listen: false)`, `SnackBar` feedback, `Navigator.of(context).pop()` on success.

**Navigation pattern for stack-clearing:** `GlobalBottomNavBar` uses `Navigator.of(context).pushAndRemoveUntil(route, (r) => false)` when switching sections. Onboarding → HomeScreen uses the same approach.

**Settings screen:** Fully implemented (NOT a placeholder). Uses `ListView` with `Consumer2<ThemeProvider, WeightUnitProvider>`, section headings, and `Card`-wrapped `ListTile` items with `CircleAvatar` leading icons and `Icons.chevron_right` trailing. Pattern to follow for new "Get Started" section.

**Testing pattern:** `@GenerateMocks([...])`, `MockSharedPreferences` (for provider unit tests), `MultiProvider` wrapper in `createTestWidget()`, `pump()` not `pumpAndSettle()` for synchronous routing tests.

**Similar features examined:**
- `AuthWrapper` routing — closest analogue to onboarding routing check
- `ThemeProvider` — SharedPreferences pattern
- `CreateProgramScreen` — wizard form step pattern
- `GlobalBottomNavBar` — stack-clearing navigation

---

## Architecture Overview

### Approach

The Onboarding Flow is implemented as a **pure UI layer over existing business logic**, with a lightweight singleton service for state persistence. No new providers are needed.

**Why not a new Provider for onboarding state?**
The onboarding flag is write-once, read-synchronously at app launch. It does not need reactive updates — once onboarding is marked complete, the user navigates directly to `HomeScreen` via `Navigator.pushAndRemoveUntil`. Adding a `ChangeNotifier` provider for a single boolean would add unnecessary complexity.

**Why a singleton service?**
`NotificationService` (already in the codebase) sets the pattern: a singleton initialized once in `main.dart`, accessible anywhere via `.instance`. `OnboardingService` follows this exact pattern. The `SharedPreferences` instance is passed in during initialization (consistent with how `ThemeProvider` receives it).

**Navigation strategy:**
- `AuthWrapper` routes new users to `OnboardingCarouselScreen` (synchronous check against `OnboardingService.instance.hasCompletedOnboarding`)
- Onboarding screens handle their own forward navigation
- On any exit path (complete or skip), screens call `OnboardingService.instance.markComplete()` then `Navigator.pushAndRemoveUntil(HomeScreen)` to fully clear the stack
- `AuthWrapper` does not need to rebuild — it only routes new users; after onboarding, the stack is cleared and `HomeScreen` is pushed directly

### Routing Decision Tree

```
AuthWrapper
├── isLoading → CircularProgressIndicator
├── !isAuthenticated → SignInScreen
├── !isEmailVerified → EmailVerificationScreen
└── isAuthenticated + isEmailVerified
    ├── !hasCompletedOnboarding → OnboardingCarouselScreen
    └── hasCompletedOnboarding → HomeScreen

OnboardingCarouselScreen (4 pages PageView)
├── Skip (any page, pages 1-3) → OnboardingWizardScreen
├── Page 4: "Set Up My First Program" → OnboardingWizardScreen
└── Page 4: "Skip to App" → markComplete() + pushAndRemoveUntil(HomeScreen)

OnboardingWizardScreen (4 steps, internal state)
├── Step 1 "Skip" (no program created) → markComplete() + pushAndRemoveUntil(HomeScreen)
├── Step 2/3/4 "Skip" (program exists) → markComplete() + pushAndRemoveUntil(HomeScreen)
└── Step 4 "Finish" → markComplete() + push(OnboardingCompletionScreen)

OnboardingCompletionScreen
├── "Go to My Programs" → pushAndRemoveUntil(HomeScreen)
└── "Explore FitTrack Pro →" (text link) → push(ProInfoScreen placeholder)

Settings → "Set Up a New Program" → push(OnboardingWizardScreen)
```

---

## Component Design

### New Files

#### `lib/services/onboarding_service.dart`

Singleton service managing onboarding state via SharedPreferences.

```dart
class OnboardingService {
  static const String _onboardingKey = 'fittrack_onboarding_complete';

  static OnboardingService? _instance;
  static OnboardingService get instance => _instance!;

  final SharedPreferences _prefs;

  OnboardingService._internal(this._prefs);

  static void initialize(SharedPreferences prefs) {
    _instance = OnboardingService._internal(prefs);
  }

  bool get hasCompletedOnboarding => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> markComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  /// For testing only — resets onboarding state
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingKey);
  }
}
```

**Initialized in `main.dart`** after `SharedPreferences.getInstance()`:
```dart
final prefs = await SharedPreferences.getInstance();
OnboardingService.initialize(prefs);  // ADD THIS
runApp(FitTrackApp(prefs: prefs));
```

#### `lib/screens/onboarding/onboarding_carousel_screen.dart`

Value prop carousel — 4 pages using `PageView`. `StatefulWidget` with `PageController` and current page index for dot indicator.

```
Structure:
├── Scaffold
│   ├── AppBar (transparent, skip TextButton top-right → wizard)
│   └── body: Column
│       ├── Expanded: PageView (4 pages)
│       │   ├── _CarouselPage(icon, title, description, illustration)
│       │   ├── _CarouselPage(...)
│       │   ├── _CarouselPage(...)
│       │   └── _CarouselPage(...) [last page only]
│       ├── Row: dot indicators (4 dots)
│       └── Padding: action buttons
│           ├── ElevatedButton "Next" / "Set Up My First Program" (last page)
│           └── TextButton "Skip to App" (last page only, replaces Next)
```

**4 carousel pages:**

| Page | Icon | Title | Key Message |
|------|------|-------|-------------|
| 1 | `Icons.account_tree_outlined` | "Structured Training" | "Organise your training into Programs → Weeks → Workouts → Exercises. No more guessing what to do next." |
| 2 | `Icons.checklist_rtl` | "Track Every Set" | "Log reps, weight, duration, distance and rest time for every exercise type — strength, cardio, bodyweight and more." |
| 3 | `Icons.insights` | "See Your Progress" | "Your activity heatmap, personal records, and workout stats help you understand if your training is actually working." |
| 4 | `Icons.rocket_launch_outlined` | "Start for Free" | "Up to 3 programs, unlimited weeks and workouts, full set tracking, and basic analytics — no payment required." |

**Skip behaviour:**
- `AppBar` skip button (all pages) → `_navigateToWizard()`
- "Set Up My First Program" button (page 4) → `_navigateToWizard()`
- "Skip to App" text button (page 4 only) → `OnboardingService.instance.markComplete()` → `pushAndRemoveUntil(HomeScreen)`

```dart
void _navigateToWizard() {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
  );
}
```

No need to `markComplete()` when going to wizard — wizard handles its own completion marking.

#### `lib/screens/onboarding/onboarding_wizard_screen.dart`

4-step program creation wizard. `StatefulWidget` with internal step counter and created entity IDs.

**State:**
```dart
int _currentStep = 0;           // 0-3 (Program, Week, Workout, Exercise)
bool _isLoading = false;
String? _programId;             // set after Step 0 completes
String? _programName;           // for display in later steps
String? _weekId;                // set after Step 1 completes
String? _workoutId;             // set after Step 2 completes
// Form controllers per step (disposed on exit)
```

**Step structure:**
Each step is a private widget method returning the step's content `Widget`. The outer scaffold has:
- `AppBar`: title "Set Up Your Program" + step counter (e.g., "Step 1 of 4")
- Leading back button only on step > 0 (goes back one step, no save)
- `body`: current step content (forms, tips)
- `bottomNavigationBar`: "Next" / "Finish" `ElevatedButton` + "Skip" `TextButton`

**Steps:**

| Step | Title | Fields | Provider Call | Required |
|------|-------|--------|---------------|----------|
| 0 | "Name Your Program" | Name (required, ≤100 chars), Description (optional) | `programProvider.createProgram()` | Yes — skip exits wizard |
| 1 | "Create Your First Week" | Name (auto: "Week 1"), Notes (optional) | `programProvider.createWeek()` | No |
| 2 | "Add Your First Workout" | Name (required), Day of week (optional dropdown) | `programProvider.createWorkout()` | No |
| 3 | "Add Your First Exercise" | Name (required), Exercise type (chip selector) | `programProvider.createExerciseWithSets(setCount: 3)` | No |

**Skip logic:**
```dart
void _onSkip() async {
  if (_currentStep == 0) {
    // Nothing saved yet — exit wizard entirely
    await OnboardingService.instance.markComplete();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  } else {
    // Program exists — save partial progress, exit
    await OnboardingService.instance.markComplete();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }
}
```

**Step 3 (Exercise) "Finish" → completion screen:**
```dart
void _onFinish() async {
  // save exercise...
  await OnboardingService.instance.markComplete();
  if (mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingCompletionScreen(programName: _programName),
      ),
    );
  }
}
```

**Offline error handling:**
If a Firestore write fails (caught exception), show `SnackBar` with error message. Do NOT advance the step. Allow retry via "Next" button.

**Day of week selector (Step 2):** Simple `DropdownButtonFormField<String>` with values Mon-Sun + "Not scheduled". Follows existing `CreateWorkoutScreen` pattern.

**Exercise type selector (Step 3):** `ChoiceChip` row with 4 types: Strength (default), Bodyweight, Cardio, Time-based. No "Custom" in wizard (simpler UX). Creates 3 default sets.

#### `lib/screens/onboarding/onboarding_completion_screen.dart`

Completion screen shown after Step 3 "Finish".

```
Structure:
├── Scaffold (no AppBar — full-screen celebration)
│   └── body: SafeArea → Column (centered)
│       ├── Icon: Icons.check_circle_outline (large, primary colour)
│       ├── Text: "You're all set!"
│       ├── Text: "Your program '[name]' is ready. Start logging your first workout."
│       ├── SizedBox(height: 48)
│       ├── ElevatedButton: "Go to My Programs" → pushAndRemoveUntil(HomeScreen)
│       └── SizedBox(height: 16)
│       └── TextButton (bodySmall, muted colour): "Explore FitTrack Pro →" → push(ProInfoPlaceholderScreen)
```

**Pro link styling:** Uses `Theme.of(context).textTheme.bodySmall` with `colorScheme.onSurface.withValues(alpha: 0.5)`. No button background, no accent color. Must look like a footnote, not a CTA.

#### `lib/screens/onboarding/pro_info_placeholder_screen.dart`

Simple placeholder screen for the Pro link destination. One screen with AppBar "FitTrack Pro" and a centered message: "Coming soon — FitTrack Pro will unlock unlimited programs, full analytics history, and more." This screen will be replaced when the monetization feature is implemented.

---

### Modified Files

#### `lib/services/onboarding_service.dart` (NEW → also modifies `main.dart`)

`main.dart` changes:
1. Import `onboarding_service.dart`
2. After `final prefs = await SharedPreferences.getInstance();`, add:
   ```dart
   OnboardingService.initialize(prefs);
   ```

#### `lib/screens/auth/auth_wrapper.dart`

One change to the `isAuthenticated + isEmailVerified` branch:

```dart
// Before:
if (authProvider.isAuthenticated) {
  if (!authProvider.isEmailVerified) {
    return const EmailVerificationScreen();
  }
  return const HomeScreen();
}

// After:
if (authProvider.isAuthenticated) {
  if (!authProvider.isEmailVerified) {
    return const EmailVerificationScreen();
  }
  if (!OnboardingService.instance.hasCompletedOnboarding) {
    return const OnboardingCarouselScreen();
  }
  return const HomeScreen();
}
```

Import additions: `onboarding_service.dart`, `onboarding_carousel_screen.dart`.

**Impact on existing tests:** Existing `AuthWrapper` tests that test the `HomeScreen` routing path will need to stub `OnboardingService` as complete. This is handled by calling `OnboardingService.initialize(mockPrefs)` in `setUp()` with a mock prefs that returns `true` for the onboarding key.

#### `lib/screens/profile/settings_screen.dart`

Add a new "Get Started" section above the Appearance section (or as the last section — discuss with user; placing first gives it prominence for users who find settings early):

```dart
// New "Get Started" section
Padding(
  padding: const EdgeInsets.all(16.0),
  child: Text('Get Started', style: ...titleMedium, primary, bold),
),
Divider(...),
const SizedBox(height: 8),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.play_arrow_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: const Text('Set Up a New Program'),
      subtitle: const Text('Follow the guided wizard to create a new training program'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
        );
      },
    ),
  ),
),
const SizedBox(height: 24),
```

**Placement:** As the **last section** (after Templates). This avoids disrupting existing Appearance/Units visual flow for returning users who know the settings layout.

---

## Data Flow

### Wizard Firestore IDs

The wizard accumulates entity IDs as steps complete:

```
Step 0: createProgram(name, description) → _programId
Step 1: createWeek(programId: _programId!, name, notes) → _weekId
Step 2: createWorkout(programId: _programId!, weekId: _weekId!, name, dayOfWeek) → _workoutId
Step 3: createExerciseWithSets(programId, weekId, workoutId, name, type, setCount: 3) → done
```

All calls go through existing `ProgramProvider` methods — no new Firestore logic required.

### OnboardingService State

```
Key: 'fittrack_onboarding_complete'
Values: absent/false = onboarding not complete, true = complete

Written by:
- OnboardingWizardScreen._onSkip() (any step)
- OnboardingWizardScreen._onFinish() (step 3)
- OnboardingCarouselScreen "Skip to App" (page 4)

Read by:
- AuthWrapper.build() (synchronous, pre-loaded)
- Settings wizard re-launch does NOT check this flag (always accessible)
```

---

## File Structure

```
lib/
├── services/
│   └── onboarding_service.dart          [NEW]
├── screens/
│   ├── auth/
│   │   └── auth_wrapper.dart            [MODIFIED — add onboarding routing]
│   ├── onboarding/                      [NEW directory]
│   │   ├── onboarding_carousel_screen.dart
│   │   ├── onboarding_wizard_screen.dart
│   │   ├── onboarding_completion_screen.dart
│   │   └── pro_info_placeholder_screen.dart
│   └── profile/
│       └── settings_screen.dart         [MODIFIED — add Get Started section]
└── main.dart                            [MODIFIED — OnboardingService.initialize(prefs)]

test/
├── services/
│   └── onboarding_service_test.dart     [NEW]
├── screens/
│   └── onboarding/
│       ├── onboarding_carousel_screen_test.dart  [NEW]
│       └── onboarding_wizard_screen_test.dart    [NEW]
└── screens/
    └── auth/
        └── auth_wrapper_test.dart       [MODIFIED — add onboarding routing cases]
```

---

## Implementation Tasks

6 tasks, ordered by dependency (leaf nodes first):

| # | Task | Depends on | Effort |
|---|------|------------|--------|
| 1 | OnboardingService + main.dart init | — | 0.5d |
| 2 | AuthWrapper onboarding routing + test updates | #1 | 0.5d |
| 3 | OnboardingCompletionScreen + ProInfoPlaceholderScreen | #1 | 0.5d |
| 4 | OnboardingWizardScreen (4 steps) | #1, #3 | 2d |
| 5 | OnboardingCarouselScreen | #1, #4 | 1d |
| 6 | Settings screen "Get Started" section | #1, #4 | 0.5d |

**Total estimated effort: ~5 developer days**

---

## Testing Strategy

Following existing test patterns:

### Unit Tests (`test/services/onboarding_service_test.dart`)
- Uses `MockSharedPreferences` (following `theme_provider_test.dart` pattern)
- Tests: `hasCompletedOnboarding` returns false when key absent, true when set; `markComplete()` writes correct key/value; `resetOnboarding()` removes key
- Uses `@GenerateMocks([SharedPreferences])`

### Widget Tests (`test/screens/onboarding/`)

**`onboarding_carousel_screen_test.dart`:**
- Renders all 4 pages (swipe or `PageController.jumpToPage`)
- Skip button present on all pages
- "Set Up My First Program" visible on page 4
- "Skip to App" visible on page 4 only
- Skip navigation leads to wizard (mocked navigation)
- "Skip to App" calls `markComplete()` and navigates to HomeScreen

**`onboarding_wizard_screen_test.dart`:**
- Step 0: validation fires on empty name, skip without name exits wizard
- Step 0: valid name → "Next" calls `createProgram` and advances step
- Step 1+: "Skip" calls `markComplete()` and navigates to HomeScreen
- Step 3: "Finish" navigates to completion screen
- Offline error: failed Firestore write shows SnackBar, stays on step

**`auth_wrapper_test.dart` (existing, updated):**
- New test: authenticated + verified + onboarding incomplete → shows `OnboardingCarouselScreen`
- New test: authenticated + verified + onboarding complete → shows `HomeScreen` (existing test updated to set up `OnboardingService` with complete state)

### No Integration Tests Required
The wizard Firestore writes go through `ProgramProvider` which is already integration-tested. No new service-level Firestore logic is introduced.

---

## Technical Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `OnboardingService.instance` accessed before `initialize()` | Low | Null assertion `_instance!` will throw immediately in tests if missed; easy to catch |
| AuthWrapper test breakage (HomeScreen path now requires onboarding complete) | Medium | Update existing tests in Task 2 — `setUp()` must initialize `OnboardingService` with complete state |
| Wizard step skipping with unsaved IDs (e.g., skip step 1, step 2 tries to use `_weekId`) | Low | Each step checks if prerequisite ID exists before allowing "Next"; skip always exits wizard |
| Existing users on new devices see onboarding again (SharedPreferences are local) | Low | Accepted — documented in PRD as acceptable v1 behaviour |
| ProgramProvider not ready when wizard tries to write (userId not set) | Low | Wizard can only be reached when `authProvider.isAuthenticated` is true, which means `ProgramProvider` has been initialized with userId |

---

## Non-Functional Requirements Checklist

- **Performance:** Carousel uses `PageView` with lazy loading. No Firestore calls during carousel. Wizard writes are on-demand per step.
- **Accessibility:** All interactive elements have semantic labels. Minimum 48×48dp touch targets (matching existing settings card tiles). Dot indicators include `Semantics(label: 'Page X of 4')`. Progress counter in AppBar: `Semantics(label: 'Step X of 4')`.
- **Offline:** Carousel works fully offline. Wizard shows `SnackBar` on Firestore failure, does not advance step. Error handling follows existing pattern (`programProvider.error ?? 'Failed to create program'`).
- **Material Design 3:** All screens use `Theme.of(context).colorScheme` and `textTheme` — no hardcoded colours. Matches existing app visual language.
