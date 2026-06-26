import { Page } from '@playwright/test';

/**
 * Signs in via the app's sign-in screen using Firebase Auth emulator credentials.
 * Waits for the "My Programs" screen to confirm successful sign-in.
 *
 * Flutter web (CanvasKit, the default renderer since Flutter 3.24) renders UI on canvas
 * but exposes an accessibility/semantics tree via <flt-semantics> elements. Pressing Tab
 * activates Flutter's accessibility engine, making role-based locators work.
 *
 * Text editing fields: Flutter's text editing host creates real <input> elements in
 * <flt-text-editing-host> when a field is focused. The password field uses type="password".
 */
export async function signIn(page: Page, email: string, password: string): Promise<void> {
  await page.goto('/');

  // Wait for Flutter's CanvasKit <canvas> to be visible — this is the reliable
  // "app has painted" signal. flt-glass-pane and flt-semantics-host exist in the
  // shadow DOM but have CSS that makes them appear "hidden" to Playwright even
  // when the app is rendering correctly.
  await page.locator('canvas').first().waitFor({ state: 'visible', timeout: 45_000 });

  // --force-renderer-accessibility (in playwright.config.ts launchOptions) tells
  // Chromium to expose the accessibility tree, which causes Flutter to populate
  // flt-semantics nodes automatically. Tab additionally focuses the first field.
  await page.keyboard.press('Tab');

  // Wait for at least one flt-semantics node (confirms semantics tree is live)
  await page.waitForSelector('flt-semantics', { timeout: 20_000 });

  // Click the Email field and fill it. Flutter creates a real <input> in the text editing
  // host when focused. We target by ARIA role since Flutter sets aria-label from labelText.
  const emailField = page.getByRole('textbox', { name: /email/i });
  await emailField.waitFor({ timeout: 10_000 });
  await emailField.fill(email);

  // Fill password field — obscureText:true renders the editing input as type="password"
  const passwordInput = page.locator('input[type="password"]');
  await passwordInput.waitFor({ timeout: 10_000 });
  await passwordInput.fill(password);

  // Click the Sign In button (exposed via flt-semantics role="button")
  await page.getByRole('button', { name: /sign in/i }).click();

  // Wait for the home screen — "My Programs" text confirms successful sign-in
  await page.waitForSelector('flt-semantics:has-text("My Programs")', { timeout: 25_000 });
}
