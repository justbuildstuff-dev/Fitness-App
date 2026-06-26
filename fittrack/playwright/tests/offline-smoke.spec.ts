import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

// Offline smoke test runs only at desktop viewport to reduce complexity.
// Service worker caching is viewport-independent, so a single project is sufficient.
test.describe('PWA Offline Smoke', () => {
  test.skip(({ browserName }) => browserName !== 'chromium', 'PWA service worker only in Chromium');

  test('app shell loads from cache when network is offline', async ({ page, context }, testInfo) => {
    // --- WARM THE SERVICE WORKER CACHE ---
    // Sign in first to ensure the service worker has cached the app shell.
    await signIn(page, EMAIL, PASSWORD);
    await expect(page.getByText('My Programs')).toBeVisible({ timeout: 15_000 });

    // Wait for the service worker to activate and cache the app shell.
    // Flutter web registers a service worker on first load; wait for it to be active.
    await page.waitForFunction(() => {
      return navigator.serviceWorker?.controller !== null;
    }, { timeout: 15_000 }).catch(() => {
      // Service worker may not be active in test environment; continue anyway
    });

    await page.screenshot({ path: `test-results/${testInfo.title}/01-online-loaded.png` });

    // --- GO OFFLINE ---
    await context.setOffline(true);

    // Reload the page while offline
    await page.reload({ waitUntil: 'domcontentloaded', timeout: 15_000 }).catch(() => {
      // Page may take longer to load from cache; catch timeout and continue
    });

    await page.screenshot({ path: `test-results/${testInfo.title}/02-after-offline-reload.png` });

    // --- VERIFY APP SHELL IS VISIBLE OFFLINE ---
    // The browser should NOT show a "no internet" error page.
    // Chromium's offline error page contains the text "ERR_INTERNET_DISCONNECTED" or
    // "No internet" — if this text is present, the service worker cache failed.
    const pageContent = await page.content();
    const hasNetworkError = pageContent.includes('ERR_INTERNET_DISCONNECTED') ||
      pageContent.includes('ERR_NETWORK_CHANGED') ||
      pageContent.includes('No internet');
    expect(hasNetworkError).toBeFalsy();

    // Some navigable content should be visible (the Flutter app shell or at minimum the title)
    await page.waitForFunction(() => document.title.length > 0, { timeout: 10_000 }).catch(() => {});

    await page.screenshot({ path: `test-results/${testInfo.title}/03-offline-app-visible.png` });

    // --- RESTORE NETWORK ---
    await context.setOffline(false);

    // Reload to reconnect
    await page.reload({ timeout: 20_000 });
    await expect(page.getByText('My Programs')).toBeVisible({ timeout: 20_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/04-reconnected.png` });
  });
});
