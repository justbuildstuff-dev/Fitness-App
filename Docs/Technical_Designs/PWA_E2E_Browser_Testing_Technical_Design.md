# PWA E2E Browser Testing (Playwright) — Technical Design

**Status:** Ready for Review
**Related PRD:** [Docs/PRDs/PWA_E2E_Browser_Testing_PRD.md](../PRDs/PWA_E2E_Browser_Testing_PRD.md)
**GitHub Issue:** #490
**Created:** 2026-06-26

---

## 1. Current Architecture Analysis

### State Management
The app uses `provider` package with `ChangeNotifier`. Key providers for the tested flows:
- `AuthProvider` — authentication state, email verification
- `ProgramProvider` — programs, weeks, workouts, exercises, sets (ChangeNotifierProxyProvider keyed on userId)
- `SubscriptionProvider` — Pro/free gating via Firebase Stripe Extension listener
- `OnboardingService` — singleton (SharedPreferences-backed) checked in `AuthWrapper`

### Auth & Routing Flow
`AuthWrapper` (`lib/screens/auth/auth_wrapper.dart`) is the root decision tree:
```
isLoading → CircularProgressIndicator
isAuthenticated:
  !isEmailVerified → EmailVerificationScreen
  !OnboardingService.hasCompletedOnboarding → OnboardingCarouselScreen
  → HomeScreen (tabs: Programs / Analytics / Profile)
not authenticated → SignInScreen
```

### Existing Integration Test Infrastructure
`integration_test/firebase_emulator_setup.dart` already contains:
- `FirebaseEmulatorSetup.initializeFirebaseForTesting()` — connects to emulators at localhost:8080 / localhost:9099
- `createTestUser()` — creates user via Firebase Auth, verifies email via OOB code REST endpoint
- `seedTestData()` — writes Program + Week to Firestore emulator
- `clearEmulatorData()` — DELETE to Firestore emulator HTTP API

This design mirrors these patterns in Node.js for Playwright.

### File Organization
```
fittrack/
  lib/
    main.dart             — Firebase init + runApp
    screens/              — UI screens by domain
    providers/            — State (AuthProvider, ProgramProvider, SubscriptionProvider…)
    services/             — Firebase-facing services
  integration_test/       — Flutter driver tests (Android emulator)
  test/                   — Unit + widget tests
  scripts/                — CI shell scripts
  .github/workflows/      — CI pipelines
```

### CI Job Pattern (enhanced-tests job)
The existing `enhanced-tests` job follows this sequence:
1. Checkout + Flutter setup
2. Node.js + Firebase CLI install
3. `flutter pub get` + `build_runner`
4. `firebase emulators:start --only auth,firestore &`
5. Wait for ports 8080 + 9099
6. Run Flutter tests against emulators
7. Stop emulators

The new `playwright-e2e` job follows the same pattern with `flutter build web` and Playwright replacing `flutter test`.

### Subscription / Pro Gating
`SubscriptionProvider` reads `isProOverride` from the user profile document at `users/{userId}`. When this field is `true`, the user is treated as Pro regardless of Stripe subscription status. Analytics and other gated features unlock. Playwright test data setup must write `isProOverride: true` to the Firestore emulator for the test user.

---

## 2. Architecture Overview

### High-Level Approach

Playwright runs **outside** the Flutter/Dart framework — it's a Node.js process driving a real Chromium browser that loads the compiled Flutter web output. This is fundamentally different from existing Flutter integration tests (`flutter drive`), which run inside the Flutter test binding.

The end-to-end flow in CI:

```
[Firebase emulators start]
        ↓
[flutter build web --release --web-renderer html
  --dart-define=USE_EMULATOR=true
  --dart-define=SKIP_ONBOARDING=true]
        ↓
[npx serve -s fittrack/build/web -l 3000 &]   ← SPA server
        ↓
[Playwright globalSetup]
  • Create test user via Auth emulator REST API
  • Verify email via OOB code endpoint
  • Seed Firestore: user profile (isProOverride:true),
    program, week, workout, exercise, sets
        ↓
[npx playwright test]
  • Chromium browser loads http://localhost:3000
  • Flutter web JS runs → connects to emulators (USE_EMULATOR=true)
  • Tests drive UI at 375px mobile + 1280px desktop
  • Screenshots captured throughout
        ↓
[Playwright globalTeardown] — clear emulator data
        ↓
[Upload playwright-screenshots artifact]
        ↓
[report-failures.sh] — PR comment + GitHub issue if failures
```

### Web Renderer Decision

**Primary: `--web-renderer html`**
The HTML renderer renders Flutter widgets as real DOM elements. Playwright can use `getByRole()`, `getByText()`, `getByLabel()`, and `getByPlaceholder()` directly. This gives the most reliable, maintainable selectors.

**Fallback: CanvasKit (if HTML renderer removed in Flutter 3.35.1)**
CanvasKit renders to `<canvas>` but generates `<flt-semantics>` accessibility elements in a shadow DOM. Playwright can still interact via `page.getByRole()` and ARIA labels, but semantic labels must be explicit on Flutter widgets. If the developer finds `--web-renderer html` unsupported in Flutter 3.35.1, switch all locators to `page.getByRole()` / `page.getByLabel()` and ensure key widgets have `Semantics` wrappers.

The developer task includes a verification step to confirm which renderer works.

### Emulator Connection from Flutter Web Build

Two `--dart-define` compile-time flags control test build behaviour:

| Flag | Default | Effect |
|------|---------|--------|
| `USE_EMULATOR` | `false` | Connects Auth + Firestore to localhost emulators |
| `SKIP_ONBOARDING` | `false` | `OnboardingService.hasCompletedOnboarding` always returns `true` |

These are `const` values resolved at compile time. Production builds compiled without these flags are unaffected.

**Why `SKIP_ONBOARDING`:** `AuthWrapper` checks `OnboardingService.instance.hasCompletedOnboarding` before routing to `HomeScreen`. Without this flag, the test user would hit the onboarding carousel on first launch, blocking all subsequent screen navigation in tests.

### Firestore Seeding Strategy

Playwright's Node.js `globalSetup` seeds data directly via the Firestore emulator REST API (not through the app UI). This gives deterministic, fast test setup and avoids fragile UI-based setup flows.

Seeded structure per test run:
```
users/{userId}/
  (document)    { isProOverride: true, ... }
  programs/{programId}/
    (document)  { name: 'E2E Test Program', ... }
    weeks/{weekId}/
      (document) { name: 'E2E Test Week', ... }
      workouts/{workoutId}/
        (document) { name: 'E2E Test Workout', ... }
        exercises/{exerciseId}/
          (document) { name: 'Bench Press', exerciseType: 'strength', ... }
          sets/{setId}/
            (document) { reps: 5, weight: 60, checked: false, ... }
```

The analytics test needs at least one exercise with sets to render charts. The seeded data satisfies this.

---

## 3. File Structure

```
fittrack/
├── playwright/                              [NEW directory]
│   ├── package.json                         [NEW] @playwright/test dep
│   ├── playwright.config.ts                 [NEW] Chromium, 2 viewports, JSON+GitHub reporters
│   ├── global-setup.ts                      [NEW] Create user, seed Firestore
│   ├── global-teardown.ts                   [NEW] Clear emulator data
│   ├── helpers/
│   │   └── firebase-emulator.ts             [NEW] REST API calls to emulators
│   └── tests/
│       ├── program-creation.spec.ts         [NEW] Flow: sign-in → create program/week/workout
│       ├── workout-logging.spec.ts          [NEW] Flow: log set, check off, verify persistence
│       ├── analytics.spec.ts               [NEW] Flow: navigate to analytics, verify renders
│       └── offline-smoke.spec.ts           [NEW] PWA: service worker cache serves app offline
├── lib/
│   ├── main.dart                            [MODIFIED] USE_EMULATOR dart-define support
│   └── services/
│       └── onboarding_service.dart          [MODIFIED] SKIP_ONBOARDING dart-define support
└── .github/workflows/
    └── fittrack_test_suite.yml              [MODIFIED] playwright-e2e job + Android E2E skip
```

---

## 4. Detailed Component Design

### 4.1 `main.dart` — Emulator Mode Flag

**Change:** After Firebase initialization and before `runApp()`, check `USE_EMULATOR` dart-define and connect to emulators if set.

```dart
// At top of file (compile-time constant)
const bool _kUseEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

// Inside main(), after Firebase.initializeApp() succeeds, before runApp():
if (_kUseEmulator) {
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    debugPrint('[Emulator] Connected to local Firebase emulators');
  } catch (e) {
    debugPrint('[Emulator] Warning: $e');
  }
}
```

**Pattern reference:** Mirrors `FirebaseEmulatorSetup._configureEmulators()` in `integration_test/firebase_emulator_setup.dart:104`.

### 4.2 `onboarding_service.dart` — Skip Onboarding Flag

**Change:** Add compile-time constant; `hasCompletedOnboarding` checks it first.

```dart
const bool _kSkipOnboarding = bool.fromEnvironment('SKIP_ONBOARDING', defaultValue: false);

// In OnboardingService class:
bool get hasCompletedOnboarding =>
    _kSkipOnboarding || (_prefs.getBool(_onboardingKey) ?? false);
```

No other changes to `OnboardingService`. Production builds are unaffected (`_kSkipOnboarding` is `false`).

### 4.3 `playwright/playwright.config.ts`

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: 1,                  // one retry to reduce flakiness noise
  workers: 1,                  // sequential — single emulator instance
  reporter: [
    ['json', { outputFile: 'playwright-report/results.json' }],
    ['github'],                // annotations in CI
    ['html', { open: 'never' }],
  ],
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'on',          // capture on every test (pass + fail)
    video: 'off',
  },
  projects: [
    {
      name: 'mobile-375px',
      use: { viewport: { width: 375, height: 812 } },
    },
    {
      name: 'desktop-1280px',
      use: { viewport: { width: 1280, height: 800 } },
    },
  ],
  globalSetup: './global-setup.ts',
  globalTeardown: './global-teardown.ts',
  outputDir: 'playwright-screenshots',
});
```

### 4.4 `playwright/helpers/firebase-emulator.ts`

Node.js helper using `fetch` (Node 18+, no extra dep needed) to call emulator REST APIs. Mirrors the logic in `integration_test/firebase_emulator_setup.dart`.

Key functions:
```typescript
// Auth emulator REST API base
const AUTH_URL = 'http://localhost:9099';
const FIRESTORE_URL = 'http://localhost:8080';
const PROJECT_ID = 'fitness-app-8505e';

export async function createTestUser(email: string, password: string): Promise<string>
// Returns uid. Creates account, then verifies email via OOB codes endpoint.
// Pattern: same as FirebaseEmulatorSetup.createTestUser() + _setEmailVerifiedInEmulator()

export async function signInTestUser(email: string, password: string): Promise<string>
// Returns idToken for API calls that need auth (not used in Playwright — UI sign-in is used instead)

export async function seedFirestoreDoc(path: string, data: object): Promise<void>
// POST to Firestore REST API — writes a document at the given path

export async function clearEmulatorData(): Promise<void>
// DELETE http://localhost:8080/emulator/v1/projects/.../databases/(default)/documents
// Pattern: same as FirebaseEmulatorSetup._clearFirestoreData()
```

### 4.5 `playwright/global-setup.ts`

```typescript
import { createTestUser, seedFirestoreDoc } from './helpers/firebase-emulator';

const TEST_EMAIL = 'playwright-e2e@test.com';
const TEST_PASSWORD = 'playwright-test-123';

export default async function globalSetup() {
  const uid = await createTestUser(TEST_EMAIL, TEST_PASSWORD);
  
  // Seed user profile with isProOverride so Analytics screen is unlocked
  await seedFirestoreDoc(`users/${uid}`, {
    userId: uid,
    email: TEST_EMAIL,
    isProOverride: true,
    createdAt: new Date().toISOString(),
  });

  // Seed program/week/workout/exercise/sets hierarchy
  // Uses direct Firestore REST API with known IDs for determinism
  const programId = 'e2e-program-001';
  const weekId = 'e2e-week-001';
  const workoutId = 'e2e-workout-001';
  const exerciseId = 'e2e-exercise-001';
  const setId = 'e2e-set-001';

  await seedFirestoreDoc(`users/${uid}/programs/${programId}`, {
    name: 'E2E Test Program', userId: uid, isArchived: false,
    createdAt: new Date().toISOString(), updatedAt: new Date().toISOString(),
  });
  // ... seed week, workout, exercise, set at known IDs

  // Store credentials for tests to read
  process.env.E2E_TEST_EMAIL = TEST_EMAIL;
  process.env.E2E_TEST_PASSWORD = TEST_PASSWORD;
  process.env.E2E_TEST_UID = uid;
}
```

### 4.6 Test Files

All tests share a `signIn()` helper (defined once in a shared fixture) that:
1. Navigates to `http://localhost:3000`
2. Waits for `SignInScreen` to render (detects 'Overload' heading or Email field)
3. Fills email + password
4. Clicks 'SIGN IN'
5. Waits for 'My Programs' heading (HomeScreen)

#### `program-creation.spec.ts`
```
signIn()
→ tap FAB (or '+' button) on Programs screen
→ enter program name 'Playwright Program'
→ tap CREATE → verify 'Playwright Program' appears in list → screenshot
→ tap into program → tap 'Add Week' → enter 'Week 1' → save → screenshot
→ tap into week → tap 'Add Workout' → enter 'Push Day' → save → screenshot
```
Runs at both viewports.

#### `workout-logging.spec.ts`
```
signIn()
→ navigate: Programs → 'E2E Test Program' → 'E2E Test Week' → 'E2E Test Workout'
→ verify 'Bench Press' exercise visible → screenshot
→ expand exercise card → locate set row → enter reps '8', weight '60'
→ tap checkbox to mark set complete → screenshot
→ navigate back and re-enter workout → verify set is still checked → screenshot
```
Relies on seeded exercise + set data from globalSetup.

#### `analytics.spec.ts`
```
signIn()
→ tap Analytics tab (bottom nav)
→ wait for analytics data to load (no CircularProgressIndicator)
→ verify at least one stat element visible (not empty/error state) → screenshot
```
Relies on `isProOverride: true` seeded in user profile.

#### `offline-smoke.spec.ts`
```
navigate to http://localhost:3000
→ wait for Flutter app to load and service worker to register
→ page.context().setOffline(true)
→ page.reload()
→ wait for app shell (heading or nav element visible) → screenshot
→ verify no 'No internet' Chrome error page (look for absence of 'ERR_INTERNET_DISCONNECTED')
→ page.context().setOffline(false)
```
Note: offline test only runs at desktop viewport (service worker behaviour is viewport-independent).

### 4.7 `playwright/scripts/report-failures.sh`

```bash
#!/bin/bash
# Reads playwright-report/results.json and escalates failures.
# Posts PR comment always; creates/updates GitHub issue on failure.

RESULTS="playwright/playwright-report/results.json"
PR_NUMBER="${GITHUB_REF##*/}"   # extracted from GITHUB_REF or GITHUB_EVENT_PATH
RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
ARTIFACT_URL="$RUN_URL#artifacts"

# Parse failure count and names from JSON report using jq
FAILURES=$(jq '[.suites[].specs[] | select(.tests[].results[].status == "failed")] | length' "$RESULTS" 2>/dev/null || echo 0)
FAILED_TESTS=$(jq -r '[.suites[].specs[] | select(.tests[].results[].status == "failed") | .title] | join("\n- ")' "$RESULTS" 2>/dev/null || echo "")

if [ "$FAILURES" -eq 0 ]; then
  gh pr comment "$PR_NUMBER" --body "✅ **Playwright E2E:** All tests passed. [View screenshots]($ARTIFACT_URL)"
  exit 0
fi

# Build failure body
ISSUE_BODY="## Playwright E2E Failures — PR #${PR_NUMBER} Run [#${GITHUB_RUN_NUMBER}]($RUN_URL)

**${FAILURES} test(s) failed:**

- ${FAILED_TESTS}

**Screenshots:** [Download from Actions artifacts]($ARTIFACT_URL)

*This issue was auto-created by the \`playwright-e2e\` CI job. Resolve failures and re-run.*"

# Create or update issue (one per open issue for this PR)
EXISTING=$(gh issue list --label "playwright-failure" --state open --search "PR #${PR_NUMBER}" --json number -q '.[0].number' 2>/dev/null)

if [ -n "$EXISTING" ]; then
  gh issue comment "$EXISTING" --body "$ISSUE_BODY"
  ISSUE_URL=$(gh issue view "$EXISTING" --json url -q '.url')
else
  # Ensure label exists
  gh label create "playwright-failure" --color "d93f0b" --description "Playwright E2E test failure" 2>/dev/null || true
  ISSUE_URL=$(gh issue create \
    --title "[Playwright E2E] Failures on PR #${PR_NUMBER}" \
    --body "$ISSUE_BODY" \
    --label "playwright-failure,priority/high,area/ui" \
    --json url -q '.url')
fi

gh pr comment "$PR_NUMBER" --body "⚠️ **Playwright E2E:** ${FAILURES} test(s) failed. [GitHub Issue]($ISSUE_URL) | [Screenshots]($ARTIFACT_URL)"
exit 0   # Always exit 0 — failures are non-blocking
```

### 4.8 `fittrack_test_suite.yml` Changes

#### New `playwright-e2e` job

```yaml
playwright-e2e:
  name: Playwright E2E (PWA Browser Tests)
  runs-on: ubuntu-latest
  timeout-minutes: 15
  if: github.event_name == 'pull_request' || github.event_name == 'workflow_dispatch'
  # NOT in the `needs` list of all-tests-passed → non-blocking

  steps:
    - uses: actions/checkout@v4

    - uses: subosito/flutter-action@v2
      with:
        flutter-version: 3.35.1
        cache: true

    - uses: actions/setup-node@v4
      with:
        node-version: '18'

    - name: Install Firebase CLI
      run: npm install -g firebase-tools

    - name: Flutter pub get
      run: cd fittrack && flutter pub get

    - name: Start Firebase emulators
      run: |
        cd fittrack
        firebase emulators:start --only auth,firestore --project fitness-app-8505e &
        echo $! > emulator.pid

    - name: Wait for emulators
      run: |
        timeout 60 bash -c 'until curl -s http://localhost:8080 > /dev/null; do sleep 2; done'
        timeout 60 bash -c 'until curl -s http://localhost:9099 > /dev/null; do sleep 2; done'

    - name: Build Flutter web (emulator mode)
      run: |
        cd fittrack
        flutter build web --release \
          --web-renderer html \
          --dart-define=USE_EMULATOR=true \
          --dart-define=SKIP_ONBOARDING=true

    - name: Install Playwright and dependencies
      run: |
        cd fittrack/playwright
        npm ci
        npx playwright install chromium --with-deps

    - name: Start local SPA server
      run: |
        npx serve -s fittrack/build/web -l 3000 &
        sleep 3
        curl -f http://localhost:3000 || (echo "Server not ready" && exit 1)

    - name: Run Playwright tests
      id: playwright
      continue-on-error: true   # non-blocking
      run: |
        cd fittrack/playwright
        npx playwright test

    - name: Upload screenshots artifact
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: playwright-screenshots
        path: fittrack/playwright/playwright-screenshots/
        retention-days: 90

    - name: Report results (PR comment + GitHub issue on failure)
      if: always() && github.event_name == 'pull_request'
      env:
        GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      run: bash fittrack/playwright/scripts/report-failures.sh

    - name: Stop emulators
      if: always()
      run: |
        cd fittrack
        [ -f emulator.pid ] && kill $(cat emulator.pid) || true
        pkill -f "firebase" || true
```

#### Android E2E path filter

Add a `check-changes` job before `integration-tests` and add `workflow_dispatch` input to the `on:` section:

```yaml
on:
  workflow_dispatch:
    inputs:
      run_android_e2e:
        description: 'Force-run Android E2E tests regardless of changed files'
        type: boolean
        default: false
  # ... existing push/pull_request triggers unchanged ...

jobs:
  # New job: detect whether Android-relevant files changed
  check-changes:
    name: Detect Changed File Paths
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request' || github.event_name == 'workflow_dispatch'
    outputs:
      android_changed: ${{ steps.filter.outputs.android }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            android:
              - 'fittrack/android/**'
              - 'fittrack/integration_test/**'

  # Modified: integration-tests now depends on check-changes
  integration-tests:
    needs: [check-changes]
    # Run when: android files changed OR manually forced via workflow_dispatch input
    if: |
      (github.event_name == 'pull_request' || github.event_name == 'workflow_dispatch') &&
      (needs.check-changes.outputs.android_changed == 'true' ||
       github.event.inputs.run_android_e2e == 'true')
    # ... rest of job unchanged ...
```

The `all-tests-passed` job already treats `integration-tests` as non-blocking (it checks for `cancelled` vs `failed` differently). A skipped job returns `'skipped'` from `needs.integration-tests.result`, which the current logic does not block on. No change required there.

---

## 5. Dependencies

| Dependency | Why | Where |
|------------|-----|-------|
| `@playwright/test` | Test runner and browser driver | `fittrack/playwright/package.json` |
| Chromium (via playwright) | Browser for test execution | Installed by `playwright install chromium` |
| `serve` (npx, no install) | SPA-mode static file server | CI step via `npx serve` |
| `dorny/paths-filter@v3` | Detect changed paths for Android skip | `.github/workflows/fittrack_test_suite.yml` |
| `jq` | Parse Playwright JSON report in escalation script | Pre-installed on `ubuntu-latest` |
| `firebase-tools` (already in CI) | Firebase emulators | Already installed in CI |

No new Flutter/Dart dependencies. No new pubspec changes.

---

## 6. Security Considerations

- `USE_EMULATOR` and `SKIP_ONBOARDING` are compile-time `const bool` values. They are `false` in all production builds. The test build artifact (`build/web`) is never deployed to Firebase Hosting — it is only served locally inside CI for the duration of the Playwright job.
- No production Firebase credentials are used. Auth and Firestore emulators run locally with no network access to production.
- The `GH_TOKEN` (GitHub Actions default token) is used in `report-failures.sh` with scoped `issues: write` and `pull-requests: write` permissions already declared in the workflow.
- Test credentials (`playwright-e2e@test.com` / `playwright-test-123`) are hardcoded in `global-setup.ts`. This is safe — they only exist in the emulator's ephemeral data and are cleared in `globalTeardown`.

---

## 7. Performance Considerations

CI job budget: 15 minutes. Breakdown estimate:
- Emulator start + wait: ~30s
- `flutter build web --release`: ~4-5 min
- `playwright install chromium --with-deps`: ~2 min
- `npm ci` (cached): ~30s
- Playwright tests (4 specs × 2 viewports = 8 test runs): ~3 min
- Artifact upload: ~30s
- **Total: ~10-11 min** — within 15-minute budget

`workers: 1` in Playwright config avoids race conditions on the single emulator instance.

`retries: 1` catches transient timing flakes without masking real failures.

---

## 8. Testing Strategy for This Feature

The Playwright infrastructure itself is tested by running CI. No unit tests for test helpers are required. Acceptance is: all 4 test specs pass on 2 viewports (8 pass results) consistently across 5 consecutive PR runs.

---

## 9. Rollback Plan

If the `playwright-e2e` job causes CI resource issues (time overrun, memory):
1. Remove the job from `fittrack_test_suite.yml` — no other jobs depend on it (non-blocking)
2. The `build/web` output directory is `gitignore`-d and not committed

If `--web-renderer html` is unsupported in Flutter 3.35.1:
1. Remove `--web-renderer html` from the build command
2. Switch all Playwright locators to `page.getByRole()` / `page.getByLabel()` 
3. Add `Semantics` wrappers to key widgets if labels are missing

---

## 10. Implementation Tasks

See GitHub task issues #491–#499 (linked below).

Task dependency order:
```
Task #491 (dart-define flags)  ──┐
Task #492 (Playwright infra)   ──┤──→ Tasks #493–#496 (test specs)
                                 │
Tasks #493–#496 (test specs)  ──→ Task #497 (CI job)
Task #497 (CI job) ────────────→ Task #498 (failure escalation)
Task #499 (Android skip) [independent]
```

| # | Task | Effort |
|---|------|--------|
| #491 | Add USE_EMULATOR + SKIP_ONBOARDING dart-define flags to Flutter app | 0.5d |
| #492 | Set up Playwright infrastructure (config, helpers, global setup/teardown) | 1d |
| #493 | Implement program/week/workout creation Playwright test | 0.5d |
| #494 | Implement workout set logging Playwright test | 0.5d |
| #495 | Implement analytics screen Playwright test | 0.5d |
| #496 | Implement offline PWA smoke test | 0.5d |
| #497 | Add playwright-e2e CI job to fittrack_test_suite.yml | 1d |
| #498 | Implement failure escalation script (PR comment + GitHub issue) | 0.5d |
| #499 | Add Android E2E path filter and workflow_dispatch input | 0.5d |

**Total estimated effort: ~6 days**
