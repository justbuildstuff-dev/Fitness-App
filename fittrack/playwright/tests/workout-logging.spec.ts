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
 * Returns the first locator that becomes visible within `timeout` ms.
 *
 * Flutter's ListTile uses MergeSemantics internally:
 * - Without trailing container children (IconButtons): title text appears as
 *   flt-semantics text content → getByText() works.
 * - With trailing containers (edit/delete buttons): MergeSemantics absorbs the
 *   title into the node's aria-label; text content shows only trailing button text
 *   → getByText() fails, flt-tappable[aria-label*=] succeeds.
 * Both locators race; whichever resolves first wins.
 */
function firstVisible(
  locators: import('@playwright/test').Locator[],
  timeout: number,
): Promise<import('@playwright/test').Locator> {
  return new Promise<import('@playwright/test').Locator>((resolve, reject) => {
    let settled = false;
    let pending = locators.length;
    for (const loc of locators) {
      loc.waitFor({ state: 'visible', timeout }).then(
        () => { if (!settled) { settled = true; resolve(loc); } },
        () => { if (--pending === 0 && !settled) reject(); },
      );
    }
  });
}

/**
 * Tap a Flutter flt-semantics list tile by text content or aria-label.
 *
 * Tries text content first (simple tiles without trailing buttons), then falls back
 * to flt-tappable[aria-label*=] for tiles whose title is merged into aria-label by
 * MergeSemantics (triggered when trailing IconButtons are present as container nodes).
 *
 * dispatchEvent avoids Playwright's actionability retry loop: after Flutter navigation
 * the semantics tree rebuilds, invalidating element references and causing .click()
 * to retry indefinitely until the 60-second timeout.
 */
async function tapListTile(page: import('@playwright/test').Page, text: string): Promise<void> {
  const el = await firstVisible(
    [
      page.getByText(text).first(),
      page.locator(`flt-semantics[flt-tappable][aria-label*="${text}"]`).first(),
    ],
    15_000,
  ).catch(() => { throw new Error(`Tile "${text}" not found by text or aria-label within 15s`); });

  await el.dispatchEvent('click');
}

/** Assert that a named tile is visible by text content or aria-label. */
async function assertTileVisible(
  page: import('@playwright/test').Page,
  text: string,
  timeout = 10_000,
): Promise<void> {
  await firstVisible(
    [
      page.getByText(text).first(),
      page.locator(`flt-semantics[aria-label*="${text}"]`).first(),
    ],
    timeout,
  ).catch(() => { throw new Error(`"${text}" not visible by text or aria-label within ${timeout}ms`); });
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
    await expect(page.getByText('My Programs').first()).toBeVisible({ timeout: 20_000 });

    // DOM diagnostic: dump flt-semantics nodes to confirm program card aria-label structure.
    // MergeSemantics (used by ListTile with trailing IconButtons) merges the title into
    // aria-label rather than text content; this log confirms which selector to use.
    const domDump = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics'));
      return {
        count: els.length,
        nodes: els.map(e => ({
          text: (e.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 80),
          label: e.getAttribute('aria-label'),
          role: e.getAttribute('role'),
          tappable: e.hasAttribute('flt-tappable'),
        })).filter(n => n.text || n.label),
      };
    });
    console.log(`[E2E][dom-dump] count=${domDump.count} nodes=${JSON.stringify(domDump.nodes.slice(0, 25))}`);

    // --- NAVIGATE TO WORKOUT ---
    await tapListTile(page, PROGRAM_NAME);
    await assertTileVisible(page, WEEK_NAME, 10_000);

    // Navigate into Week 1
    await tapListTile(page, WEEK_NAME);
    await assertTileVisible(page, WORKOUT_NAME, 10_000);

    // Navigate into E2E Workout
    await tapListTile(page, WORKOUT_NAME);
    await assertTileVisible(page, EXERCISE_NAME, 10_000);

    await page.screenshot({ path: `test-results/${testInfo.title}/01-workout-open.png` });

    // --- VERIFY EXERCISE IS VISIBLE ---
    await assertTileVisible(page, EXERCISE_NAME, 5_000);

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
    await tapListTile(page, PROGRAM_NAME);
    await tapListTile(page, WEEK_NAME);
    await tapListTile(page, WORKOUT_NAME);
    await assertTileVisible(page, EXERCISE_NAME, 10_000);

    // The checkbox should still be checked after reload
    const reloadedCheckbox = page.getByRole('checkbox').first();
    await expect(reloadedCheckbox).toBeChecked({ timeout: 10_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/04-persisted-after-reload.png` });
  });
});
