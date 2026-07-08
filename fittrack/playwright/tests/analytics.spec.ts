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
    // dispatchEvent('click') fires a non-trusted click event. For most buttons (FAB,
    // list tiles) this works because Flutter's flt-tappable click listener fires
    // performAction(tap). But bottom NavigationBar destination taps require the event
    // to reach flt-glass-pane (the Flutter gesture arena) via actual pointer input.
    //
    // Fix: use the same pointer-events bypass as tapListTile:
    //   1. Temporarily set pointer-events:none on all flt-semantics so the CDP mouse
    //      click reaches flt-glass-pane instead of being intercepted by the overlay.
    //   2. Use page.mouse.click() (a CDP-generated trusted event) so Flutter's gesture
    //      engine processes it via hit-testing and fires onDestinationSelected(1).
    const analyticsTabEl = page.locator('flt-semantics[flt-tappable]:has-text("Analytics")').first();
    await analyticsTabEl.waitFor({ state: 'visible', timeout: 10_000 });
    const tabBox = await analyticsTabEl.boundingBox();
    const tabText = await analyticsTabEl.textContent().catch(() => '');
    console.log(`[E2E][analytics-tab] text="${tabText?.trim()}" box=${JSON.stringify(tabBox)}`);
    if (tabBox) {
      await page.evaluate(() => {
        document.querySelectorAll('flt-semantics').forEach(e => {
          (e as HTMLElement).style.pointerEvents = 'none';
        });
      });
      await page.mouse.click(
        tabBox.x + tabBox.width * 0.5,
        tabBox.y + tabBox.height * 0.5,
      );
      await page.evaluate(() => {
        document.querySelectorAll('flt-semantics').forEach(e => {
          (e as HTMLElement).style.pointerEvents = '';
        });
      });
      // Brief wait so Flutter's gesture engine can process the tap and trigger
      // NavigationBar.onDestinationSelected before we start polling for screen content.
      await page.waitForTimeout(1000);
    }

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
      .waitFor({ state: 'visible', timeout: 15_000 })
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
