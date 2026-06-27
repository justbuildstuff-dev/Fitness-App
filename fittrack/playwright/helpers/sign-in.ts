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
 *
 * Form submission:
 * Clicking the flt-semantics Sign In button can hang in headless CI (pointer events
 * on the accessibility overlay may not reliably reach Flutter's gesture handler).
 * Instead, press Enter in the password field — this fires onFieldSubmitted which
 * calls _signIn() directly via Flutter's TextInputAction.done handler.
 *
 * Auth state listener:
 * After sign-in, AuthProvider.authStateChanges calls user.reload() to get the latest
 * emailVerified status. In headless CI, user.reload()'s getAccountInfo request can
 * stall. auth_provider.dart wraps it with a 10-second timeout so a stalled reload
 * cannot block navigation — the sign-in JWT already contains emailVerified.
 */
export async function signIn(page: Page, email: string, password: string): Promise<void> {
  await page.goto('/');

  // FORCE_SEMANTICS=true at build time ensures flt-semantics nodes are live from first
  // render. Wait for any node to confirm the app has painted and semantics are active.
  await page.waitForSelector('flt-semantics', { timeout: 45_000 });

  // Log all Firebase emulator requests/responses (Auth :9099 and Firestore :8080)
  // so CI output shows exactly what the browser sends and whether any requests hang.
  page.on('request', req => {
    const url = req.url();
    if (url.includes('localhost:9099')) {
      const path = url.split('?')[0].replace(/^.*localhost:9099/, '');
      console.log(`[E2E][auth-req] ${req.method()} ${path}`);
    } else if (url.includes('localhost:8080')) {
      const path = url.split('?')[0].replace(/^.*localhost:8080/, '');
      console.log(`[E2E][firestore-req] ${req.method()} ${path}`);
    }
  });
  page.on('response', async resp => {
    const url = resp.url();
    if (url.includes('localhost:9099')) {
      const path = url.split('?')[0].replace(/^.*localhost:9099/, '');
      const status = resp.status();
      let body = '';
      try {
        const text = await resp.text();
        body = text.length > 200 ? text.substring(0, 200) + '…' : text;
      } catch { /* response body already consumed */ }
      console.log(`[E2E][auth-res] ${status} ${path} — ${body}`);
    } else if (url.includes('localhost:8080')) {
      const path = url.split('?')[0].replace(/^.*localhost:8080/, '');
      const status = resp.status();
      console.log(`[E2E][firestore-res] ${status} ${path}`);
    }
  });

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

  // Submit by pressing Enter in the password field.
  // The password TextFormField has onFieldSubmitted: (_) => _signIn(), so Enter
  // fires _signIn() via Flutter's TextInputAction.done handler. This is more
  // reliable in headless CI than clicking the flt-semantics button element.
  await page.keyboard.press('Enter');

  // Wait 4s for Flutter to navigate to HomeScreen, then dump every [aria-label] element
  // so CI output shows the exact DOM structure. This diagnostic is kept permanently so
  // we can see what labels are available on HomeScreen in any future failure.
  await page.waitForTimeout(4_000);
  const ariaSnapshot = await page.evaluate(() =>
    Array.from(document.querySelectorAll('[aria-label]'))
      .map(el => `${el.tagName.toLowerCase()}[role=${el.getAttribute('role')}]="${el.getAttribute('aria-label')}"`)
      .join(' | ')
  );
  console.log(`[E2E][aria-snapshot] ${ariaSnapshot || '(none found)'}`);

  // Confirm we are on HomeScreen. Three selectors are tried simultaneously with a CSS
  // comma-OR; the first to appear wins:
  //   1. [aria-label="My Programs"]   — AppBar title (Flutter Semantics(header:true) label)
  //   2. [aria-label="Analytics"]     — BottomNavBar "Analytics" tab (confirmed by analytics test)
  //   3. [aria-label="Programs"]      — BottomNavBar "Programs" tab
  // Firestore Listen/channel requests appearing in prior CI runs confirmed the app DOES
  // reach HomeScreen; the original failure was a selector mismatch, not a navigation issue.
  await page.locator('[aria-label="My Programs"], [aria-label="Analytics"], [aria-label="Programs"]')
    .first()
    .waitFor({ state: 'attached', timeout: 26_000 });
}
