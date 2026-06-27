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
 * IMPORTANT — filling Flutter text fields:
 * locator.fill() dispatches `input` events on the flt-semantics element, which Flutter
 * does not translate to text controller changes. The correct sequence is:
 *   1. click() the flt-semantics textbox — Flutter focuses the field and creates a real
 *      <input> in <flt-text-editing-host> to receive keyboard input.
 *   2. page.keyboard.type(text) — keyboard events route to the focused DOM element
 *      (the flt-text-editing-host input), which Flutter DOES read.
 */
export async function signIn(page: Page, email: string, password: string): Promise<void> {
  await page.goto('/');

  // FORCE_SEMANTICS=true at build time ensures flt-semantics nodes are live from first
  // render. Wait for any node to confirm the app has painted and semantics are active.
  await page.waitForSelector('flt-semantics', { timeout: 45_000 });

  // Click email field → Flutter focuses it, creates flt-text-editing-host <input>.
  // Then type via keyboard — goes to the focused flt-text-editing-host input.
  await page.getByRole('textbox', { name: /email/i }).click();
  await page.keyboard.type(email);

  // Tab moves Flutter focus to the password field asynchronously (Dart→JS bridge).
  // Typing immediately after Tab races with Flutter's focus change — partial password
  // characters land in the email field before focus transfers.
  // Wait for the password editing input to appear before typing; that confirms Flutter
  // has finished processing Tab and focused the password field.
  await page.keyboard.press('Tab');
  await page.locator('input[type="password"]').waitFor({ timeout: 10_000 });
  await page.keyboard.type(password);

  // Click Sign In button (flt-semantics with role="button" and aria-label="Sign In")
  await page.getByRole('button', { name: /sign in/i }).click();

  // Flutter puts text in aria-label, not as DOM text content — getByText() never matches
  // flt-semantics elements. Use an attribute selector instead.
  // state:'attached' because flt-semantics elements can be CSS-clipped while still in DOM.
  await page.locator('[aria-label="My Programs"]').waitFor({ state: 'attached', timeout: 25_000 });
}
