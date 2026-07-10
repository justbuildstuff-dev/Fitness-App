import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 60_000,
  retries: 1,
  workers: 1,
  reporter: [
    ['list'],
    ['json', { outputFile: 'playwright-report/results.json' }],
    ['github'],
    ['html', { outputFolder: 'playwright-report/html', open: 'never' }],
  ],
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'on',
    trace: 'on-first-retry',
    video: 'on-first-retry',
    // Force Chromium to expose its accessibility tree to all web content.
    // Without this, headless Chromium disables accessibility APIs, so Flutter
    // never activates its flt-semantics overlay even after a Tab keypress.
    launchOptions: {
      args: [
        '--force-renderer-accessibility',
        // Allow HTTP on localhost without mixed-content / certificate errors
        '--allow-insecure-localhost',
        // Disable Private Network Access preflight check — in some Chrome builds
        // localhost→localhost requests trigger a PNA preflight that the Firebase
        // Auth emulator doesn't respond to, causing signInWithPassword to hang.
        '--disable-features=PrivateNetworkAccessSendPreflights',
      ],
    },
  },
  globalSetup: './global-setup.ts',
  globalTeardown: './global-teardown.ts',
  projects: [
    {
      name: 'mobile-375px',
      use: {
        ...devices['Pixel 5'],
        viewport: { width: 375, height: 812 },
      },
    },
    {
      name: 'desktop-1280px',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 800 },
      },
    },
  ],
});
