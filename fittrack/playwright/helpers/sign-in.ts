import { Page } from '@playwright/test';

// #534: waits for an element matching `selector` to actually be the
// page's true focused element, not just attached to the DOM. Flutter web's
// focus transfer (whether triggered by Tab or by click()) is asynchronous —
// Playwright's click()/press() only wait for the input event to be
// dispatched, not for whatever async side effect it triggers inside the
// page. Typing before focus has genuinely landed silently drops/misroutes
// keystrokes (confirmed via diagnostic: "playwright-test-123" arriving
// corrupted, e.g. "wright-test-123"), which the emulator then correctly
// rejects as INVALID_PASSWORD. Waiting for attachment alone (round 2) was
// insufficient for the same reason Tab (round 1) was — neither guarantees
// focus, only presence.
//
// Flutter's CanvasKit renderer hosts flt-text-editing-host inside a shadow
// root, so document.activeElement only ever returns the shadow HOST, never
// the <input> inside it (round-3-first-attempt regression: a plain
// `document.querySelector(sel) === document.activeElement` check can never
// be true, so it just times out instead of ever detecting focus). Walk down
// through nested shadowRoot.activeElement to find the real deepest focused
// element before checking it against the selector.
async function waitForInputFocus(page: Page, selector: string, timeoutMs: number): Promise<void> {
  await page.waitForFunction(
    (sel) => {
      let el: Element | null = document.activeElement;
      while (el?.shadowRoot?.activeElement) {
        el = el.shadowRoot.activeElement;
      }
      return el !== null && el.matches(sel);
    },
    selector,
    { timeout: timeoutMs }
  );
}

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
 *   2. Wait for that <input> to actually be document.activeElement (see
 *      waitForInputFocus below) — Flutter's focus transfer is asynchronous, so
 *      neither the click() resolving nor the <input> merely existing in the DOM
 *      guarantees focus has landed yet (#534: two earlier fix attempts assumed
 *      one of those was sufficient; both left an intermittent race that silently
 *      dropped/misrouted keystrokes typed too early).
 *   3. page.keyboard.type(text) — keyboard events route to the focused DOM element
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

  // #534 (round 3): round 1 (Tab) and round 2 (click()) both left the same
  // character-dropping race — neither waiting for DOM attachment nor for the
  // click event to dispatch guarantees Flutter has actually moved DOM focus
  // into the new input yet, since that focus transfer happens asynchronously
  // inside the page regardless of what triggers it. Wait for genuine
  // document.activeElement focus before typing into either field — this is
  // the actual invariant that matters, not attachment or dispatch order.
  await page.getByRole('textbox', { name: /email/i }).click();
  await waitForInputFocus(page, 'flt-text-editing-host input', 10_000);
  await page.keyboard.type(email);

  const passwordInput = page.locator('input[type="password"]');
  await page.getByRole('textbox', { name: /password/i }).click();
  await waitForInputFocus(page, 'input[type="password"]', 10_000);
  await page.keyboard.type(password);

  // DIAGNOSTIC (#534 round 3): verifying the focus-wait actually closes the
  // race this time — rounds 1 and 2 both looked plausible until CI proved
  // otherwise. Never logs the literal value.
  const actualPasswordValue = await passwordInput.inputValue().catch(() => null);
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
