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
    //
    // The Firebase emulator warning banner (<p class="firebase-emulator-warning">) is
    // fixed at the bottom of the page and physically overlaps the BottomNavigationBar.
    // It intercepts all pointer events at those coordinates, which is why every previous
    // approach failed:
    //   - dispatchEvent('click'): untrusted event, Flutter ignores for InkResponse callbacks.
    //   - Playwright locator.click(): explicitly blocked ("firebase-emulator-warning intercepts
    //     pointer events") on mobile; fires on desktop but click lands on flt-semantics
    //     → performAction(tap), which does NOT trigger InkResponse.onTap navigation.
    //   - pointer-events bypass + page.mouse.click(): set flt-semantics to pointer-events:none
    //     so click goes to flt-glass-pane, BUT the emulator banner (a real HTML element, not
    //     flt-semantics) was never bypassed, so it still absorbed the click.
    //
    // Fix: hide the emulator banner FIRST, then apply the pointer-events bypass so the
    // CDP mouse click reaches flt-glass-pane. Flutter's gesture engine hit-tests the widget
    // tree at those coordinates and fires InkResponse.onTap → BottomNavigationBar.onTap(1)
    // → Navigator.pushAndRemoveUntil(HomeScreen(initialIndex: 1)).
    const analyticsTabEl = page.locator('flt-semantics[flt-tappable][role="button"]:has-text("Analytics")').first();
    await analyticsTabEl.waitFor({ state: 'visible', timeout: 10_000 });
    const tabBox = await analyticsTabEl.boundingBox();
    const tabText = await analyticsTabEl.textContent().catch(() => '');
    console.log(`[E2E][analytics-tab] text="${tabText?.trim()?.replace(/\n/g, '\\n')}" box=${JSON.stringify(tabBox)}`);

    if (tabBox) {
      const cx = tabBox.x + tabBox.width * 0.5;
      const cy = tabBox.y + tabBox.height * 0.5;

      // 1. Hide the emulator banner so it cannot intercept the click.
      // 2. Bypass flt-semantics so the event target is flt-glass-pane (Flutter's gesture arena).
      await page.evaluate(() => {
        document.querySelectorAll<HTMLElement>('.firebase-emulator-warning').forEach(e => { e.style.display = 'none'; });
        document.querySelectorAll<HTMLElement>('flt-semantics').forEach(e => { e.style.pointerEvents = 'none'; });
      });
      await page.mouse.click(cx, cy);
      await page.evaluate(() => {
        document.querySelectorAll<HTMLElement>('.firebase-emulator-warning').forEach(e => { e.style.display = ''; });
        document.querySelectorAll<HTMLElement>('flt-semantics').forEach(e => { e.style.pointerEvents = ''; });
      });
    } else {
      // Fallback when element has no layout box (should not happen).
      await analyticsTabEl.dispatchEvent('click');
    }
    await page.waitForTimeout(1000); // allow Flutter's gesture engine and navigation to complete

    // Diagnostic: dump top-level semantics nodes to reveal what screen is now showing.
    const postNavDump = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('flt-semantics'))
        .map(e => ({
          text: (e.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 50),
          tappable: e.hasAttribute('flt-tappable'),
          role: e.getAttribute('role'),
        }))
        .filter(n => n.text)
        .slice(0, 20);
    });
    console.log(`[E2E][post-nav-dump] ${JSON.stringify(postNavDump)}`);

    await page.screenshot({ path: `test-results/${testInfo.title}/01-analytics-tab-clicked.png` });

    // Wait for Analytics screen body content (analytics-specific text that does NOT appear
    // on the Programs screen). The nav button "Analytics Tab 2 of 3" contains "Analytics"
    // so we cannot use that as a navigation signal — we must wait for screen body content.
    //   - "No Data Available" → empty state (expected when no completed workouts exist)
    //   - "Loading analytics..." → loading state
    //   - "Overview" / "Exercise" / "Trends" → tabbed content (when analytics data exists)
    await page.getByText('No Data Available')
      .or(page.getByText('Loading analytics'))
      .or(page.getByText('Start tracking workouts'))
      .or(page.getByText('Overview'))
      .or(page.getByText('Exercise'))
      .or(page.getByText('Trends'))
      .first()
      .waitFor({ state: 'visible', timeout: 20_000 })
      .catch(() => {});

    await page.screenshot({ path: `test-results/${testInfo.title}/02-analytics-loaded.png` });

    const hasOverviewTab = await page.getByText('Overview').isVisible().catch(() => false);
    const hasExerciseTab = await page.getByText('Exercise').isVisible().catch(() => false);
    const hasTrendsTab = await page.getByText('Trends').isVisible().catch(() => false);
    const hasEmptyState = await page.getByText('No Data Available').isVisible().catch(() => false);
    const hasLoadingState = await page.getByText('Loading analytics').isVisible().catch(() => false);
    const hasEmptyHint = await page.getByText('Start tracking workouts').isVisible().catch(() => false);

    console.log(`[E2E][analytics-state] overview=${hasOverviewTab} exercise=${hasExerciseTab} trends=${hasTrendsTab} empty=${hasEmptyState} loading=${hasLoadingState} hint=${hasEmptyHint}`);

    expect(hasOverviewTab || hasExerciseTab || hasTrendsTab || hasEmptyState || hasLoadingState || hasEmptyHint).toBeTruthy();

    // Verify no error dialog is shown
    const errorDialog = page.getByText(/something went wrong/i);
    await expect(errorDialog).not.toBeVisible();

    // Verify screen is not blank
    const bodyText = await page.locator('body').innerText();
    expect(bodyText.length).toBeGreaterThan(20);
  });
});
