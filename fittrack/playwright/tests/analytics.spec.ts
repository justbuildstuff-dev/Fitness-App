import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

test.describe('Analytics Screen', () => {
  test.beforeEach(async ({ page }) => {
    await signIn(page, EMAIL, PASSWORD);
  });

  test('analytics screen renders without error', async ({ page }, testInfo) => {
    // The test user has isProOverride:true seeded in global-setup,
    // so the Analytics Pro gate is open.

    // Navigate to Analytics via bottom navigation tab
    await page.getByText('Analytics', { exact: true }).click();

    // The Analytics screen should load without crash or blank screen
    await expect(page.getByText('Analytics').first()).toBeVisible({ timeout: 15_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/01-analytics-loaded.png` });

    // Verify at least one tab is visible (Overview, Exercise, or Trends)
    const hasOverviewTab = await page.getByText('Overview').isVisible().catch(() => false);
    const hasExerciseTab = await page.getByText('Exercise').isVisible().catch(() => false);
    const hasTrendsTab = await page.getByText('Trends').isVisible().catch(() => false);

    expect(hasOverviewTab || hasExerciseTab || hasTrendsTab).toBeTruthy();

    await page.screenshot({ path: `test-results/${testInfo.title}/02-analytics-tabs-visible.png` });

    // Verify no error dialog is shown (error dialogs typically contain "Error" or "Something went wrong")
    const errorDialog = page.getByText(/something went wrong/i);
    await expect(errorDialog).not.toBeVisible();

    // Verify screen is not blank: some content should be present beyond just the nav
    // The page should have rendered more than just the navigation bar
    const bodyText = await page.locator('body').innerText();
    expect(bodyText.length).toBeGreaterThan(20);
  });
});
