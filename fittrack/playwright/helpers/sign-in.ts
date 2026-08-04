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
 * does not translate to text controller changes. The correct sequence (#534:
 * matches the proven pattern in program-creation.spec.ts's fillTextField(),
 * after several other approaches all left an intermittent character-dropping
 * race — see git history on this file for what didn't work and why) is:
 *   1. click({ force: true }) the flt-semantics textbox — a trusted CDP click
 *      that skips Playwright's actionability-check choreography. This focuses
 *      the field and creates a real <input> in <flt-text-editing-host> to
 *      receive keyboard input.
 *   2. page.keyboard.press('Control+A') — clears any pre-filled value.
 *   3. page.keyboard.type(text) — keyboard events route to the focused DOM
 *      element (the flt-text-editing-host input), which Flutter DOES read.
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

  // #534: a plain click() plus various wait strategies (DOM attachment,
  // native focus, Playwright's toBeFocused(), even verify-and-retry with an
  // untested custom locator) all failed to reliably avoid a character-
  // dropping race. program-creation.spec.ts's fillTextField() helper already
  // has a proven-reliable pattern for this exact kind of Flutter TextFormField
  // interaction that this file never adopted: click({ force: true }) — a
  // trusted CDP click that skips Playwright's actionability-check choreography
  // — followed immediately by Control+A (clears any prefill) and type().
  // Mirroring it here instead of inventing a new approach.
  const emailTextbox = page.getByRole('textbox', { name: /email/i });
  await emailTextbox.waitFor({ state: 'visible', timeout: 10_000 });
  await emailTextbox.click({ force: true });
  await page.keyboard.press('Control+A');
  await page.keyboard.type(email);

  const passwordTextbox = page.getByRole('textbox', { name: /password/i });
  await passwordTextbox.waitFor({ state: 'visible', timeout: 10_000 });
  await passwordTextbox.click({ force: true });
  await page.keyboard.press('Control+A');
  await page.keyboard.type(password);

  // DIAGNOSTIC (#534): confirming click({force:true}) actually closes the
  // race before removing this check — everything has looked plausible before
  // in this investigation until CI proved otherwise. Never logs the literal
  // value.
  const actualPasswordValue = await page.locator('input[type="password"]').inputValue().catch(() => null);
  if (actualPasswordValue !== password) {
    console.log(
      `[E2E][credential-check] MISMATCH — expected length ${password.length}, ` +
      `actual length ${actualPasswordValue?.length ?? 'null'}, actual value starts with "${actualPasswordValue?.slice(0, 2) ?? ''}"`
    );
  } else {
    console.log(`[E2E][credential-check] password input matches expected (length ${password.length})`);
  }

  // Set up response listener BEFORE pressing Enter so we don't miss the response.
  // Firebase Auth emulator handles signInWithPassword at /identitytoolkit/v3/relyingparty/...
  // or /v1/accounts:signInWithPassword — match either path pattern.
  // Wait for ANY signInWithPassword response (200 or 400), then check status.
  // Filtering for 200 only would hang for the full 90s whenever the emulator
  // rejects a bad sign-in (see #534 — was a corrupted-password typing race, now
  // fixed above) instead of failing fast. Accepting any status lets us throw
  // immediately on 400 so the test retries within seconds rather than burning
  // the full timeout budget.
  const authOkPromise = page.waitForResponse(
    resp => resp.url().includes('signInWithPassword') || resp.url().includes('accounts:signInWithPassword'),
    { timeout: 90_000 }
  ).then(async resp => {
    if (resp.status() !== 200) {
      let body = '';
      try { body = (await resp.text()).slice(0, 200); } catch { /* consumed */ }
      throw new Error(`signInWithPassword returned ${resp.status()}: ${body}`);
    }
    return resp;
  });

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
