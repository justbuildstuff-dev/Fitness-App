import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

const PROGRAM_NAME = 'E2E Created Program';
const WEEK_NAME = 'E2E Week 1';
const WORKOUT_NAME = 'E2E Push Day';

test.describe('Program / Week / Workout Creation', () => {
  test.beforeEach(async ({ page }) => {
    await signIn(page, EMAIL, PASSWORD);
  });

  test('creates a program, week, and workout end-to-end', async ({ page }, testInfo) => {
    // --- SIGN-IN COMPLETE ---
    await page.screenshot({ path: `test-results/${testInfo.title}/01-signed-in.png` });

    // --- CREATE PROGRAM ---
    // Click the FAB (+) to open the create options bottom sheet.
    // Flutter FABs: FloatingActionButton(tooltip: 'Add') gives accessible name "Add"
    // via the ARIA tree. getByRole uses the accessibility tree (not DOM attributes)
    // so it finds the button even though aria-label is not set as an HTML attribute.
    await page.getByRole('button', { name: 'Add' }).click();

    // Bottom sheet: choose "Start Fresh"
    // getByText().click() fails because Flutter text nodes have pointer-events:none.
    // getByRole('button') finds the tappable parent element via the accessibility tree.
    await expect(page.getByText('Start Fresh')).toBeVisible({ timeout: 10_000 });
    await page.getByRole('button', { name: 'Start Fresh' }).click();

    // CreateProgramScreen: fill program name and submit.
    // Flutter web text fields: click the flt-semantics[role="textbox"] to focus it
    // (Flutter creates the flt-text-editing-host <input> on focus), then type via
    // keyboard. Do NOT use getByPlaceholder() — Flutter sets hint text as a child
    // widget, not as the HTML placeholder attribute.
    await expect(page.getByText('Create New Program')).toBeVisible({ timeout: 10_000 });
    await page.getByRole('textbox').first().click();
    await page.keyboard.type(PROGRAM_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/02-program-name-filled.png` });
    await page.getByRole('button', { name: 'CREATE', exact: true }).click();

    // Verify program appears in the list
    await expect(page.getByText(PROGRAM_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/03-program-created.png` });

    // --- NAVIGATE INTO PROGRAM ---
    await page.getByRole('button', { name: PROGRAM_NAME }).click();
    // Wait for program detail screen
    await expect(page.getByText(PROGRAM_NAME)).toBeVisible({ timeout: 10_000 });

    // --- CREATE WEEK ---
    // Empty state shows "Create Week" button; if FAB is shown instead, fall back to FAB.
    const createWeekButton = page.getByRole('button', { name: 'Create Week' });
    const hasEmptyState = await createWeekButton.isVisible().catch(() => false);
    if (hasEmptyState) {
      await createWeekButton.click();
    } else {
      await page.getByRole('button', { name: 'Add' }).click();
    }

    // CreateWeekScreen: fill week name and submit
    await expect(page.getByText('Create New Week')).toBeVisible({ timeout: 10_000 });
    await page.getByRole('textbox').first().click();
    await page.keyboard.type(WEEK_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/04-week-name-filled.png` });
    await page.getByRole('button', { name: 'CREATE', exact: true }).click();

    // Verify week appears
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/05-week-created.png` });

    // --- NAVIGATE INTO WEEK ---
    await page.getByRole('button', { name: WEEK_NAME }).click();
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 10_000 });

    // --- CREATE WORKOUT ---
    const createWorkoutButton = page.getByRole('button', { name: 'Create Workout' });
    const hasWorkoutEmptyState = await createWorkoutButton.isVisible().catch(() => false);
    if (hasWorkoutEmptyState) {
      await createWorkoutButton.click();
    } else {
      await page.getByRole('button', { name: 'Add' }).click();
    }

    // CreateWorkoutScreen: fill workout name and submit
    await expect(page.getByText('Create Workout').first()).toBeVisible({ timeout: 10_000 });
    await page.getByRole('textbox').first().click();
    await page.keyboard.type(WORKOUT_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/06-workout-name-filled.png` });
    await page.getByRole('button', { name: 'CREATE', exact: true }).click();

    // Verify workout appears
    await expect(page.getByText(WORKOUT_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/07-workout-created.png` });
  });
});
