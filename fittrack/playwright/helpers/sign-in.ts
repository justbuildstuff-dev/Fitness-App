import { Page } from '@playwright/test';

/**
 * Signs in via the app's sign-in screen using Firebase Auth emulator credentials.
 * Waits for the "My Programs" screen to confirm successful sign-in.
 *
 * Flutter web (CanvasKit) renders UI on canvas and exposes an accessibility tree via
 * <flt-semantics> elements. The web build is compiled with FORCE_SEMANTICS=true
 * (SemanticsBinding.instance.ensureSemantics() at startup), so flt-semantics nodes
 * are populated immediately — no Tab press or Chromium flag required.
 *
 * Text editing fields: Flutter's text editing host creates real <input> elements in
 * <flt-text-editing-host> when a field is focused. The password field uses type="password".
 */
export async function signIn(page: Page, email: string, password: string): Promise<void> {
  await page.goto('/');

  // The web build is compiled with --dart-define=FORCE_SEMANTICS=true, which calls
  // SemanticsBinding.instance.ensureSemantics() at startup. This means flt-semantics
  // nodes are populated as soon as Flutter first renders — no Tab press required.
  // Wait for at least one node to confirm the app has rendered and semantics are live.
  await page.waitForSelector('flt-semantics', { timeout: 45_000 });

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

  // Wait for the home screen — "My Programs" text in the semantics tree confirms sign-in
  await page.getByText('My Programs').waitFor({ timeout: 25_000 });
}
