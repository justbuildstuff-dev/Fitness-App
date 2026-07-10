# Release Notes — v1.6.1

**Release Date:** 2026-07-10
**Type:** Developer Infrastructure

---

## What's New

### Automated End-to-End Browser Testing

We've added a Playwright-based E2E test suite that automatically verifies the app's critical user flows work correctly in a real browser on every code change.

**What this means for you:**
- Higher confidence that program creation, workout logging, and analytics work correctly after every update
- Faster detection of regressions before they reach production
- Automated screenshots captured on every CI run for human inspection

**Flows covered:**
- Creating a program, week, and workout from scratch
- Navigating to a workout and logging a set (including persistence to the database)
- Analytics screen loading without errors

Tests run at both mobile (375px) and desktop (1280px) viewport sizes.

---

## Under the Hood

- Playwright E2E test suite (`fittrack/playwright/`) with Chromium runner
- Tests run against Firebase Auth and Firestore emulators — no production data involved
- Non-blocking CI integration: E2E failures warn via PR comments and GitHub issues but never block a merge
- Failure reports automatically create one GitHub issue per PR listing all failing tests
- Screenshots artifact uploaded on every CI run (90-day retention)

---

## Bug Fixes

- Fixed Firebase Auth emulator endpoint used during sign-in to correctly target the emulator (`localhost:9099`) rather than the production Auth service
- Fixed E2E test sign-in helper to fail fast on auth errors (rather than waiting the full 90s timeout)
- Fixed analytics tab navigation in E2E tests: hides the Firebase emulator warning banner before clicking so it no longer intercepts pointer events

---

*This is a developer infrastructure release. No user-facing features or UI changes.*
