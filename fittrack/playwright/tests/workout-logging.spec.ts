import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

// Seeded in global-setup
const PROGRAM_NAME = 'E2E Test Program';
const WEEK_NAME = 'Week 1';
const WORKOUT_NAME = 'E2E Workout';
const EXERCISE_NAME = 'Bench Press';

/**
 * Tap a Flutter flt-semantics list tile by text content.
 *
 * Strategy: wait for the text element to be visible (handles async Firestore loading),
 * then dispatch a click on it. The click event bubbles up to the flt-tappable
 * ListTile container's click listener, triggering the Dart onTap callback.
 *
 * Using getByText instead of locator('flt-semantics[flt-tappable]', { hasText }) because
 * ListTile widgets with trailing IconButtons (edit/delete) may not get flt-tappable on
 * their outer semantics container — Flutter may omit it when interactive children are
 * present. getByText finds the title text flt-semantics directly; dispatchEvent('click')
 * bubbles to whichever ancestor has the click listener.
 *
 * dispatchEvent is used instead of .click() to avoid Playwright's actionability retry
 * loop: after Flutter navigation the semantics tree rebuilds, which invalidates element
 * references and causes .click() to retry indefinitely until the 60-second timeout.
 */
async function tapListTile(page: import('@playwright/test').Page, text: string): Promise<void> {
  const el = page.getByText(text).first();
  await el.waitFor({ state: 'visible', timeout: 15_000 });
  await el.dispatchEvent('click');
}

/**
 * Tap the program card on the Programs screen.
 *
 * Strategy: dispatchEvent('click') directly on the outer flt-semantics role=button node
 * (aria-label = program name). This bypasses coordinate-based DOM hit testing so no
 * overlay element can intercept the event.
 *
 * _ProgramCard now sets Semantics(onTap: onTap, button: true, label: program.name),
 * which registers SemanticsAction.tap on the outer semantics node. Flutter's semantics
 * click handler invokes that action → onTap → Navigator.push.
 *
 * dispatchEvent is used instead of .click() to avoid Playwright's actionability retry
 * loop: after navigation the flt-semantics tree rebuilds, which would cause .click() to
 * re-fire indefinitely until the 60-second test timeout.
 */
async function tapProgramCard(page: import('@playwright/test').Page): Promise<void> {
  const card = page.getByRole('button', { name: PROGRAM_NAME, exact: true });
  await card.waitFor({ state: 'visible', timeout: 15_000 });

  // Small wait for any in-flight Firestore updates to settle before clicking,
  // to avoid clicking during a semantics tree rebuild.
  await page.waitForTimeout(300);

  // Diagnostic: inspect what flt-tappable elements exist and whether the outer
  // Semantics node (aria-label=program.name) has flt-tappable registered.
  const diag = await page.evaluate((name) => {
    const outer = document.querySelector(`flt-semantics[role="button"][aria-label="${name}"]`);
    const tappables = Array.from(document.querySelectorAll('flt-semantics[flt-tappable]'))
      .map(el => ({
        id: el.id,
        role: el.getAttribute('role'),
        label: el.getAttribute('aria-label'),
        text: (el.textContent ?? '').trim().slice(0, 60),
      }));
    return {
      outerFound: !!outer,
      outerTappable: outer?.hasAttribute('flt-tappable') ?? false,
      tappables,
    };
  }, PROGRAM_NAME);
  console.log(`[E2E][card-diag] ${JSON.stringify(diag)}`);

  // Attempt 1: dispatchEvent directly on the outer Semantics node (bypasses
  // coordinate hit-testing so old-route overlays can't intercept).
  await card.dispatchEvent('click');

  // If dispatchEvent doesn't trigger navigation (SemanticsAction.tap not registered
  // on the outer node), fall back to a trusted CDP click via page.mouse at the card
  // center — trusted (isTrusted=true) events go through Flutter's pointer path.
  const navigated = await page.evaluate(() =>
    Array.from(document.querySelectorAll('flt-semantics'))
      .some(el => (el.textContent ?? '').includes('Week'))
  );
  console.log(`[E2E][card-post-click] navigated=${navigated}`);
  if (!navigated) {
    console.log('[E2E][card-fallback] dispatchEvent had no effect; trying CDP mouse click');
    const box = await card.boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    }
  }
}

test.describe('Workout Set Logging', () => {
  test.beforeEach(async ({ page }) => {
    await signIn(page, EMAIL, PASSWORD);
  });

  test('navigates to seeded workout and checks off a set', async ({ page }, testInfo) => {
    // Extend timeout: sign-in (~3s) + HomeScreen navigation (~12s, auth_provider.user.reload()
    // has a 10s built-in timeout) + Firestore data load + navigation + set logging +
    // page.reload() persist check = ~90s worst case.
    test.setTimeout(120_000);

    // Diagnostic: read seeded program document directly from the Firestore emulator REST API
    // (bypassing Flutter and security rules) to confirm the data is present and correct.
    // If this returns null/error, the seeding in global-setup failed or used the wrong path.
    const uid = process.env.E2E_TEST_UID ?? '';
    const docUrl = `http://localhost:8080/v1/projects/fitness-app-8505e/databases/(default)/documents/users/${uid}/programs/e2e-program-001`;
    const directDoc = await fetch(docUrl, { headers: { 'Authorization': 'Bearer owner' } })
      .then(r => r.ok ? r.json() : r.text())
      .catch((e: Error) => ({ error: e.message }));
    const fields = (directDoc as { fields?: Record<string, unknown> })?.fields;
    console.log(`[E2E][direct-read] uid=${uid} name=${JSON.stringify(fields?.name)} isArchived=${JSON.stringify(fields?.isArchived)} createdAt=${JSON.stringify(fields?.createdAt)}`);

    // Wait for HomeScreen before attempting any navigation.
    // auth_provider calls user.reload() after sign-in to refresh emailVerified; it has a
    // 10s timeout, so HomeScreen navigation can begin up to ~11s after signIn() returns.
    // An explicit wait here separates "app navigated home" (covered below) from
    // "Firestore data loaded" (covered by tapListTile's own 15s wait), making both
    // reliable without inflating a single timeout to cover both concerns.
    await expect(page.getByText('My Programs').first()).toBeVisible({ timeout: 20_000 });

    // Dump flt-semantics text content to CI log so we can diagnose what the HomeScreen
    // is actually rendering (empty list, loading state, or the seeded program).
    const domDump = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics'));
      const texts = els.map(e => e.textContent?.trim()).filter(Boolean);
      const withProgram = texts.filter(t => /E2E|program/i.test(t));
      return { count: els.length, withProgram, first30: texts.slice(0, 30) };
    }).catch(() => ({ count: 0, withProgram: [] as string[], first30: [] as string[] }));
    console.log(`[E2E][dom-dump-home] count=${domDump.count} withProgram=${JSON.stringify(domDump.withProgram)} first30=${JSON.stringify(domDump.first30)}`);

    // --- NAVIGATE TO WORKOUT ---
    // Programs screen shows the seeded E2E Test Program.
    // Program name is canvas-only (not in flt-semantics); use tapProgramCard.
    await tapProgramCard(page);
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 10_000 });

    // Navigate into Week 1
    await tapListTile(page, WEEK_NAME);
    await expect(page.getByText(WORKOUT_NAME)).toBeVisible({ timeout: 10_000 });

    // Navigate into E2E Workout
    await tapListTile(page, WORKOUT_NAME);
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible({ timeout: 10_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/01-workout-open.png` });

    // --- VERIFY EXERCISE IS VISIBLE ---
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible();

    // --- LOG THE SET ---
    // The seeded set (reps:5, weight:60) is pre-populated in the set row.
    // Verify reps and weight fields are visible
    await expect(page.getByText('Reps *').first()).toBeVisible({ timeout: 5_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/02-exercise-visible.png` });

    // Check off the set using the Checkbox widget (Flutter renders as role="checkbox").
    // Use dispatchEvent('click') for the same reason as button clicks: the flt-semantics
    // node may be rebuilt after the toggle (set becomes read-only), which would cause
    // Playwright's .click() outer retry loop to re-fire indefinitely.
    const checkbox = page.getByRole('checkbox').first();
    await expect(checkbox).toBeVisible({ timeout: 5_000 });
    await expect(checkbox).not.toBeChecked();
    await checkbox.dispatchEvent('click');

    // After checking, the set becomes read-only and the checkbox should be checked
    await expect(checkbox).toBeChecked({ timeout: 5_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/03-set-checked.png` });

    // --- VERIFY PERSISTENCE ---
    // Reload the page and navigate back to verify the checked state persisted.
    await page.reload();
    await page.waitForSelector('flt-semantics', { timeout: 20_000 });
    await expect(page.getByText('My Programs')).toBeVisible({ timeout: 20_000 });
    await tapProgramCard(page);
    await tapListTile(page, WEEK_NAME);
    await tapListTile(page, WORKOUT_NAME);
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible({ timeout: 10_000 });

    // The checkbox should still be checked after reload
    const reloadedCheckbox = page.getByRole('checkbox').first();
    await expect(reloadedCheckbox).toBeChecked({ timeout: 10_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/04-persisted-after-reload.png` });
  });
});
