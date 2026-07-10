# PRD: PWA E2E Browser Testing (Playwright)

**Status:** Requirements Complete
**Priority:** High
**Platform:** Web (PWA)
**Feature Type:** Enhancement
**GitHub Issue:** #490
**Created:** 2026-06-26

---

## 1. Problem Statement

Since transitioning to a PWA, the CI pipeline has no test job that loads the app in a real browser and exercises rendered screens. Unit, widget, and Firebase integration tests validate business logic and component behaviour in isolation, but none of them ever serve the compiled Flutter web output and drive it through a browser. The Android E2E job renders screens, but against the Android platform — not the web — and it is known to be flaky (#29).

The result is a blind spot: a regression that breaks a real user flow in the browser (blank screen, broken navigation, failed Firestore write) would not be caught by CI before reaching production.

This feature adds a Playwright-based E2E test job to the CI pipeline. It builds the Flutter web output, serves it locally, and drives a headless Chromium browser through the three highest-value user flows. Failures are non-blocking but escalate automatically via a single GitHub issue and a PR comment so regressions are tracked without creating noise.

---

## 2. Users

**Primary:** Developer — benefits from catching browser-level regressions before merge.

**Secondary:** QA Agent — benefits from a rendered-screen signal alongside unit/widget test results when assessing PR readiness.

---

## 3. Existing Implementation Notes

Relevant to the SA when designing:

- **CI pipeline:** `.github/workflows/fittrack_test_suite.yml` — existing jobs: `unit-tests`, `widget-tests`, `integration-tests` (Android, known flaky), `enhanced-tests` (Firebase emulators), `performance-tests`, `security-checks`, `all-tests-passed`.
- **Android E2E job (`integration-tests`):** Currently non-blocking due to known flakiness (issue #29). Runs unconditionally. The Android codebase is preserved but PWA is the primary distribution channel — the Android job should gain a skip mechanism so it does not run on PWA-only changes.
- **PWA deploy workflow:** `.github/workflows/deploy_website.yml` — builds `flutter build web --release` and deploys to Firebase Hosting target `app`. This confirms the web build is already working in CI.
- **Firebase emulators in CI:** Auth (port 9099) and Firestore (port 8080) emulators are already started in the `enhanced-tests` job using `firebase emulators:start --only auth,firestore --project fitness-app-8505e`. Playwright tests can reuse this exact setup.
- **GitHub Actions artifacts:** Already used for test output. Screenshots will follow the same pattern — uploaded via `actions/upload-artifact` and accessible from the Actions run page for 90 days.
- **Firestore security rules:** `fittrack/firestore.rules` — emulator applies real rules so test users must have correct `userId` scoping.
- **App URL in web build:** The Flutter app targets `https://app.fitness-app-8505e.web.app` in production. In CI the local dev server will serve on `http://localhost:PORT` — Playwright's `baseURL` will be set accordingly.

---

## 4. User Stories

### Story 1: Create a Program, Week, and Workout

**As a** developer reviewing a PR,
**I want** Playwright to sign in with a test user, create a program, add a week, and add a workout to that week,
**so that** I can be confident the core program-building flow renders and functions correctly in the browser.

**Acceptance Criteria:**
1. Playwright signs in via the app's sign-in screen using a Firebase Auth emulator test account.
2. The test creates a new program and verifies the program card appears in the program list.
3. The test adds a week to the program and verifies it appears.
4. The test adds a workout to the week and verifies it appears.
5. Each creation step is backed by a real Firestore emulator write (verified by subsequent reads, not by mocking).
6. Screenshots are captured at: sign-in complete, program created, week created, workout created.
7. The test passes at both 375px (mobile) and 1280px (desktop) viewport widths.

---

### Story 2: Log a Workout Set

**As a** developer reviewing a PR,
**I want** Playwright to open a workout, add an exercise, log a set by checking it off, and verify the set is persisted,
**so that** I can be confident the core workout-logging flow — the app's primary daily-use action — works correctly in the browser.

**Acceptance Criteria:**
1. Continuing from Story 1's state (or with seeded data), the test navigates into a workout.
2. The test adds an exercise to the workout.
3. The test logs a set (enters reps/weight and checks off the set).
4. The checked state is visible on screen and persists in Firestore (verified by re-reading the set document).
5. Screenshots are captured at: exercise added, set logged, set checked off.
6. The test passes at both 375px and 1280px viewport widths.

---

### Story 3: View Analytics / Progress Screen

**As a** developer reviewing a PR,
**I want** Playwright to navigate to the analytics or progress screen with logged data in place,
**so that** I can be confident the analytics screens render correctly with real data and do not crash or show empty-state errors when data exists.

**Acceptance Criteria:**
1. With workout data logged (from Story 2 or seeded), the test navigates to the Analytics/Progress screen.
2. The screen renders without a crash, error dialog, or blank screen.
3. At least one data visualisation or stat card is visible on screen.
4. Screenshots are captured at the analytics screen at both 375px and 1280px viewport widths.

---

### Story 4: Failure Escalation Without Noise

**As a** developer,
**I want** Playwright test failures to create a single GitHub issue listing all failing tests (not one issue per test), and post a summary comment on the PR,
**so that** regressions are tracked and actionable without flooding the issue tracker.

**Acceptance Criteria:**
1. If all Playwright tests pass, no GitHub issue is created and the PR comment states "Playwright E2E: all tests passed ✓".
2. If one or more tests fail, exactly one GitHub issue is created (or an existing open Playwright-failure issue for the same PR is updated) listing all failing test names, the viewport at which each failed, and a link to the uploaded screenshot artifact.
3. The PR comment links to the GitHub issue and to the Actions run artifact page.
4. The `playwright-failure` and `priority/high` labels are applied to the failure issue automatically.
5. Playwright failures do NOT cause the `all-tests-passed` status check to fail — they are informational.

---

### Story 5: Screenshot Artifacts

**As a** developer or QA reviewer,
**I want** screenshots captured at key points in every Playwright run uploaded as GitHub Actions artifacts,
**so that** I can visually inspect what was rendered, at which viewport, regardless of whether the test passed or failed.

**Acceptance Criteria:**
1. Screenshots are captured at all checkpoints defined in Stories 1–3 on every run (pass or fail).
2. On test failure, an additional screenshot is taken at the point of failure.
3. Screenshots are organised by test name and viewport (e.g. `create-program/mobile-375px.png`).
4. All screenshots are uploaded as a single artifact named `playwright-screenshots` on the Actions run.
5. Artifact retention is 90 days (GitHub Actions default).

---

### Story 6: PWA Offline Smoke Test

**As a** developer,
**I want** a smoke test that verifies the app shell loads from the service worker cache when the network is offline,
**so that** I can catch service worker regressions that would break the offline-capable PWA experience.

**Acceptance Criteria:**
1. After an initial page load (warming the service worker cache), Playwright simulates network offline mode.
2. The app is refreshed while offline.
3. The app shell (at minimum: the navigation and a screen title) is visible — the browser does not show a "no internet" error page.
4. A screenshot is captured of the offline state.
5. Network is restored and the test verifies the app reconnects normally.

---

### Story 7: Android E2E Skip Mechanism

**As a** developer working on PWA-only changes,
**I want** to skip the Android E2E job without disabling the entire test suite,
**so that** I don't wait 80 minutes for an Android emulator job that is irrelevant to my change.

**Acceptance Criteria:**
1. The `integration-tests` (Android E2E) job gains a path filter: it runs automatically only when files under `fittrack/android/` or `fittrack/integration_test/` are changed.
2. A `workflow_dispatch` input (`run_android_e2e: true/false`, default `false`) allows manually forcing the Android job on or off regardless of path filter.
3. The `all-tests-passed` gate treats a skipped Android E2E job as passing (consistent with current non-blocking behaviour).
4. The change is documented in a comment in the workflow file.

---

## 5. Functional Requirements

- FR-1: New CI job `playwright-e2e` in `fittrack_test_suite.yml` that builds Flutter web, serves it locally, and runs Playwright tests against it
- FR-2: Firebase Auth + Firestore emulators started in the same job (reusing existing emulator setup pattern)
- FR-3: Tests cover three flows: program/week/workout creation, workout set logging, analytics screen rendering
- FR-4: Tests run at two viewport widths: 375px (mobile) and 1280px (desktop)
- FR-5: Offline/service worker smoke test included
- FR-6: Screenshots captured at defined checkpoints and on failure, uploaded as `playwright-screenshots` artifact
- FR-7: Failure escalation: one GitHub issue per failing run (not per test); PR comment posted in all cases
- FR-8: Playwright job is non-blocking — does not gate `all-tests-passed`
- FR-9: Android E2E job (`integration-tests`) gains path-based skip + `workflow_dispatch` override input
- FR-10: Playwright and its dependencies (`@playwright/test`, Chromium) installed in CI via npm

---

## 6. Non-Functional Requirements

- NFR-1: **CI Speed** — Playwright job must complete within 15 minutes. Flutter web build and emulator startup are the longest steps; test execution should be fast (headless Chromium).
- NFR-2: **Reliability** — Playwright tests must use explicit waits (not `sleep`) and target stable selectors (semantic labels, test IDs) to minimise flakiness.
- NFR-3: **Isolation** — Each test run starts with a fresh Firebase emulator state (no data from previous runs bleeds through).
- NFR-4: **Security** — No production Firebase credentials used in tests; Auth and Firestore emulators only.
- NFR-5: **Maintainability** — Tests follow a page-object or helper pattern so selectors are defined once, not scattered across test files.

---

## 7. Out of Scope

- **Visual regression diffing** — screenshots are artifacts for human inspection only; pixel-diff comparison against a baseline is deferred.
- **Percy / Chromatic** — third-party visual regression services are not in scope.
- **iOS Safari / Firefox testing** — Playwright will run Chromium only in CI; cross-browser testing is deferred.
- **Performance / Lighthouse CI** — deferred to a separate feature.
- **PWA install prompt testing** — browser/OS-specific behaviour; unreliable in headless CI.
- **Production Firebase** — all CI tests use emulators only.

---

## 8. User Flow (CI Perspective)

**Happy path (all tests pass):**
1. PR opened → `fittrack_test_suite.yml` triggered
2. `playwright-e2e` job: Flutter web builds → emulators start → Playwright runs all tests at 375px and 1280px → all pass
3. Screenshots uploaded as `playwright-screenshots` artifact
4. PR comment posted: "Playwright E2E: all tests passed ✓ — [View screenshots]"
5. `all-tests-passed` check is unaffected (Playwright is non-blocking)

**Failure path:**
1. One or more tests fail
2. Failure screenshot captured at point of failure
3. All screenshots uploaded as artifact
4. GitHub issue created: "Playwright E2E failures — PR #XX run #YY" listing each failing test, viewport, and screenshot link
5. PR comment posted: "Playwright E2E: 2 tests failed ⚠️ — [GitHub Issue #ZZ] [View screenshots]"
6. `all-tests-passed` check unaffected

---

## 9. Success Metrics

- Playwright job completes in under 15 minutes on `ubuntu-latest`
- All three user flow tests pass consistently across 10 consecutive PR runs (flakiness rate < 5%)
- Screenshots are accessible from every CI run
- Android E2E job is skipped on PRs that only touch `fittrack/lib/` or `fittrack/web/` (no `android/` changes)
- Zero false-positive GitHub issues created when all tests pass

---

## 10. Overall Acceptance Criteria

- [ ] `playwright-e2e` job runs on every PR to `main`, `feature/**`, and `bug/**` branches
- [ ] Program creation flow passes at 375px and 1280px
- [ ] Workout set logging flow passes at 375px and 1280px
- [ ] Analytics screen renders without error at 375px and 1280px
- [ ] Offline smoke test passes (app shell visible with network disabled)
- [ ] Screenshots artifact present on every run
- [ ] Failure escalation creates one GitHub issue with all defects listed
- [ ] PR comment posted on every run (pass or fail)
- [ ] Playwright failures do not block `all-tests-passed`
- [ ] Android E2E skipped when no `android/` or `integration_test/` files changed
- [ ] CI job completes within 15 minutes
