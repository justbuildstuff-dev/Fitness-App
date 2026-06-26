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
    // Flutter FABs with Icons.add expose aria-label="Add" via the icon's semantic label.
    await page.getByRole('button', { name: /add/i }).last().click();

    // Bottom sheet: choose "Start Fresh"
    await expect(page.getByText('Start Fresh')).toBeVisible({ timeout: 10_000 });
    await page.getByText('Start Fresh').click();

    // CreateProgramScreen: fill program name and submit
    await expect(page.getByText('Create New Program')).toBeVisible({ timeout: 10_000 });
    await page.getByPlaceholder('e.g., Full Body Strength').fill(PROGRAM_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/02-program-name-filled.png` });
    await page.getByText('CREATE', { exact: true }).click();

    // Verify program appears in the list
    await expect(page.getByText(PROGRAM_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/03-program-created.png` });

    // --- NAVIGATE INTO PROGRAM ---
    await page.getByText(PROGRAM_NAME).click();
    // Wait for program detail screen
    await expect(page.getByText(PROGRAM_NAME)).toBeVisible({ timeout: 10_000 });

    // --- CREATE WEEK ---
    // Empty state shows "Create Week" button; if FAB is shown instead, fall back to FAB.
    const createWeekButton = page.getByText('Create Week', { exact: true });
    const hasEmptyState = await createWeekButton.isVisible().catch(() => false);
    if (hasEmptyState) {
      await createWeekButton.click();
    } else {
      await page.getByRole('button', { name: /add/i }).last().click();
    }

    // CreateWeekScreen: fill week name and submit
    await expect(page.getByText('Create New Week')).toBeVisible({ timeout: 10_000 });
    await page.getByPlaceholder('e.g., Week 1, Foundation Week').fill(WEEK_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/04-week-name-filled.png` });
    await page.getByText('CREATE', { exact: true }).click();

    // Verify week appears
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/05-week-created.png` });

    // --- NAVIGATE INTO WEEK ---
    await page.getByText(WEEK_NAME).click();
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 10_000 });

    // --- CREATE WORKOUT ---
    const createWorkoutButton = page.getByText('Create Workout', { exact: true });
    const hasWorkoutEmptyState = await createWorkoutButton.isVisible().catch(() => false);
    if (hasWorkoutEmptyState) {
      await createWorkoutButton.click();
    } else {
      await page.getByRole('button', { name: /add/i }).last().click();
    }

    // CreateWorkoutScreen: fill workout name and submit
    await expect(page.getByText('Create Workout').first()).toBeVisible({ timeout: 10_000 });
    await page.getByPlaceholder('e.g., Push Day, Upper Body, Cardio').fill(WORKOUT_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/06-workout-name-filled.png` });
    await page.getByText('CREATE', { exact: true }).click();

    // Verify workout appears
    await expect(page.getByText(WORKOUT_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/07-workout-created.png` });
  });
});
