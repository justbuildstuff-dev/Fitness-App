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

    // Navigate to Analytics via bottom navigation tab.
    // getByRole finds node-30 (flt-semantics[role="button"][aria-current="false"]).
    // Use dispatchEvent('click') rather than .click(): Playwright's .click() enters a
    // 60-second retry loop when Flutter rebuilds the flt-semantics tree after navigation
    // (route pushState causes the outer actionability loop to retry indefinitely).
    // dispatchEvent fires the DOM 'click' event directly; Flutter's flt-tappable
    // addEventListener('click') handler fires and triggers the Dart tap callback.
    await page.getByRole('button', { name: 'Analytics' }).dispatchEvent('click');

    // The Analytics screen should load without crash or blank screen
    await expect(page.getByText('Analytics').first()).toBeVisible({ timeout: 15_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/01-analytics-loaded.png` });

    // Wait up to 10s for at least one analytics tab to appear (Overview / Exercise / Trends).
    // These tabs render slightly after the screen header, so isVisible() (which is
    // immediate) would return false if called right after dispatchEvent. Using waitFor
    // gives Flutter time to complete the route transition and render tab widgets.
    await page.getByText('Overview')
      .or(page.getByText('Exercise'))
      .or(page.getByText('Trends'))
      .first()
      .waitFor({ state: 'visible', timeout: 10_000 })
      .catch(() => {});

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
