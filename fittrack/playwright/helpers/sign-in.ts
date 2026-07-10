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

  // Set up response listener BEFORE pressing Enter so we don't miss the response.
  // Firebase Auth emulator handles signInWithPassword at /identitytoolkit/v3/relyingparty/...
  // or /v1/accounts:signInWithPassword — match either path pattern.
  const authOkPromise = page.waitForResponse(
    resp => (resp.url().includes('signInWithPassword') || resp.url().includes('accounts:signInWithPassword')) && resp.status() === 200,
    // 90s: the emulator occasionally stalls on the first auth request of a test suite
    // run (cold emulator + cold browser + Firestore data loaded by previous tests). The
    // workout-logging test.setTimeout(120_000) in beforeEach provides the budget for this.
    { timeout: 90_000 }
  );

  // Submit by pressing Enter in the password field.
  // The password TextFormField has onFieldSubmitted: (_) => _signIn(), so Enter
  // fires _signIn() via Flutter's TextInputAction.done handler. This is more
  // reliable in headless CI than clicking the flt-semantics button element.
  await page.keyboard.press('Enter');

  // Wait for Firebase Auth to confirm sign-in (200 from signInWithPassword).
  // This is viewport-agnostic — does NOT depend on any DOM structure or Flutter
  // rendering behaviour, making it reliable across mobile (375px) and desktop (1280px).
  await authOkPromise;
  console.log('[E2E] signInWithPassword → 200 OK; waiting for HomeScreen');

  // Diagnostic: dump [role="button"] flt-semantics so we can see what the DOM looks
  // like after sign-in on both mobile and desktop viewports.
  const buttonDump = await page.evaluate(() =>
    Array.from(document.querySelectorAll('flt-semantics[role="button"]'))
      .slice(0, 12)
      .map(el => {
        const ac = el.getAttribute('aria-current') ?? '';
        const tap = el.hasAttribute('flt-tappable') ? 'tappable' : '';
        return `[${el.id}] aria-current="${ac}" ${tap}`;
      })
      .join(' | ') || '(none)'
  ).catch(() => '(eval failed)');
  console.log(`[E2E][buttons-after-signin] ${buttonDump}`);

  // Brief wait to let Flutter begin the HomeScreen route transition.
  // [aria-current] never reliably appears across viewports so we don't wait long;
  // each individual test waits for its own first element (program title, nav button, etc.).
  await page.locator('[aria-current]')
    .waitFor({ state: 'attached', timeout: 1_000 })
    .catch(() => {});
}
