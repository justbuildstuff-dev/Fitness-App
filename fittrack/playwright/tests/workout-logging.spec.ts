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
 * Flutter ListTile widgets with onTap render as flt-semantics[flt-tappable] but
 * may have role="listitem" (not role="button") — so getByRole('button', { name })
 * never resolves and times out. Selecting by [flt-tappable] + hasText is role-agnostic
 * and finds the tappable container regardless of its ARIA role.
 *
 * dispatchEvent('click') is used instead of .click() to avoid Playwright's outer
 * actionability retry loop: after Flutter navigation the semantic tree rebuilds,
 * which invalidates the element reference and causes .click() to re-find and
 * re-click indefinitely until the 60-second test timeout fires.
 */
async function tapListTile(page: import('@playwright/test').Page, text: string): Promise<void> {
  await page.locator('flt-semantics[flt-tappable]', { hasText: text })
    .first()
    .dispatchEvent('click');
}

test.describe('Workout Set Logging', () => {
  test.beforeEach(async ({ page }) => {
    await signIn(page, EMAIL, PASSWORD);
  });

  test('navigates to seeded workout and checks off a set', async ({ page }, testInfo) => {
    // --- NAVIGATE TO WORKOUT ---
    // Programs screen shows the seeded E2E Test Program.
    await tapListTile(page, PROGRAM_NAME);
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
    await tapListTile(page, PROGRAM_NAME);
    await tapListTile(page, WEEK_NAME);
    await tapListTile(page, WORKOUT_NAME);
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible({ timeout: 10_000 });

    // The checkbox should still be checked after reload
    const reloadedCheckbox = page.getByRole('checkbox').first();
    await expect(reloadedCheckbox).toBeChecked({ timeout: 10_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/04-persisted-after-reload.png` });
  });
});
