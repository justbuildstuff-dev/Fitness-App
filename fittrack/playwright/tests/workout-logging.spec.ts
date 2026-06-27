import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

// Seeded in global-setup
const PROGRAM_NAME = 'E2E Test Program';
const WEEK_NAME = 'Week 1';
const WORKOUT_NAME = 'E2E Workout';
const EXERCISE_NAME = 'Bench Press';

test.describe('Workout Set Logging', () => {
  test.beforeEach(async ({ page }) => {
    await signIn(page, EMAIL, PASSWORD);
  });

  test('navigates to seeded workout and checks off a set', async ({ page }, testInfo) => {
    // --- NAVIGATE TO WORKOUT ---
    // Programs screen shows the seeded E2E Test Program.
    // Use getByRole('button') to find the tappable list-tile element via the
    // accessibility tree. getByText().click() fails because Flutter text nodes
    // inside list tiles have pointer-events:none — only the parent button is clickable.
    await page.getByRole('button', { name: PROGRAM_NAME }).click();
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 10_000 });

    // Navigate into Week 1
    await page.getByRole('button', { name: WEEK_NAME }).click();
    await expect(page.getByText(WORKOUT_NAME)).toBeVisible({ timeout: 10_000 });

    // Navigate into E2E Workout
    await page.getByRole('button', { name: WORKOUT_NAME }).click();
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible({ timeout: 10_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/01-workout-open.png` });

    // --- VERIFY EXERCISE IS VISIBLE ---
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible();

    // --- LOG THE SET ---
    // The seeded set (reps:5, weight:60) is pre-populated in the set row.
    // Verify reps and weight fields are visible
    await expect(page.getByText('Reps *').first()).toBeVisible({ timeout: 5_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/02-exercise-visible.png` });

    // Check off the set using the Checkbox widget (Flutter renders as role="checkbox")
    const checkbox = page.getByRole('checkbox').first();
    await expect(checkbox).toBeVisible({ timeout: 5_000 });
    await expect(checkbox).not.toBeChecked();
    await checkbox.click();

    // After checking, the set becomes read-only and the checkbox should be checked
    await expect(checkbox).toBeChecked({ timeout: 5_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/03-set-checked.png` });

    // --- VERIFY PERSISTENCE ---
    // Reload the page and navigate back to verify the checked state persisted.
    // After reload, wait for the Programs screen to appear, then navigate using
    // getByRole('button') so we click the tappable list-tile (not the text node).
    await page.reload();
    await page.waitForSelector('flt-semantics', { timeout: 20_000 });
    await expect(page.getByText('My Programs')).toBeVisible({ timeout: 20_000 });
    await page.getByRole('button', { name: PROGRAM_NAME }).click();
    await page.getByRole('button', { name: WEEK_NAME }).click();
    await page.getByRole('button', { name: WORKOUT_NAME }).click();
    await expect(page.getByText(EXERCISE_NAME)).toBeVisible({ timeout: 10_000 });

    // The checkbox should still be checked after reload
    const reloadedCheckbox = page.getByRole('checkbox').first();
    await expect(reloadedCheckbox).toBeChecked({ timeout: 10_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/04-persisted-after-reload.png` });
  });
});
