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
 * _ProgramCard in programs_screen.dart uses:
 *   Semantics(label: program.name, button: true,
 *     child: GestureDetector(onTap: onTap, child: Card(...)))
 *
 * This produces two flt-semantics nodes:
 *   - Outer: role="button", aria-label="<program name>". Flutter auto-adds flt-tappable
 *     to role=button nodes for keyboard activation support, but this node has NO registered
 *     SemanticsAction.tap (button:true is a role flag, not an action) → clicking it is a
 *     no-op. Its aria-label contains the program name.
 *   - Inner GestureDetector: flt-tappable WITH SemanticsAction.tap → onTap → Navigator.push.
 *     Its aria-label is the merged text of its children (trailing IconButtons: "Edit program
 *     Delete program"), NOT the program name — so it cannot be found by label substring match.
 *
 * Strategy: find the outer button node by exact aria-label, then click the first flt-tappable
 * descendant inside it. That first descendant is the GestureDetector node (outermost in DOM
 * order inside the card) which carries the actual navigation tap action.
 */
async function tapProgramCard(page: import('@playwright/test').Page): Promise<void> {
  const card = page.getByRole('button', { name: PROGRAM_NAME, exact: true });
  await card.waitFor({ state: 'visible', timeout: 15_000 });

  const result = await page.evaluate((name: string) => {
    // Find the outer Semantics node by exact aria-label match
    const outerButton = Array.from(document.querySelectorAll('flt-semantics[role="button"]'))
      .find(n => n.getAttribute('aria-label') === name);
    if (!outerButton) return { ok: false, reason: `no role=button with aria-label="${name}"` };

    // The inner GestureDetector is the first flt-tappable descendant and has the tap action.
    const inner = outerButton.querySelector('flt-semantics[flt-tappable]');
    if (!inner) return { ok: false, reason: 'no flt-tappable descendant inside outer button' };

    inner.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
    return { ok: true, innerLabel: inner.getAttribute('aria-label') ?? '(null)' };
  }, PROGRAM_NAME);

  if (!result.ok) {
    const dump = await page.evaluate(() =>
      Array.from(document.querySelectorAll('flt-semantics'))
        .map(n => `[role=${n.getAttribute('role')} label=${n.getAttribute('aria-label')} tap=${n.hasAttribute('flt-tappable')}]`)
        .join(' | ')
    ).catch(() => '(eval failed)');
    throw new Error(`tapProgramCard failed: ${(result as { reason: string }).reason}. DOM: ${dump}`);
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
