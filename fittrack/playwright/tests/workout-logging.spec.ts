import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

// Seeded in global-setup
const PROGRAM_NAME = 'E2E Test Program';
const WEEK_NAME = 'Week 1';
const WORKOUT_NAME = 'E2E Workout';
const EXERCISE_NAME = 'Bench Press';

/**
 * Returns the first locator that becomes visible within `timeout` ms.
 *
 * Flutter's ListTile uses MergeSemantics internally:
 * - Without trailing container children (IconButtons): title text appears as
 *   flt-semantics text content → getByText() works.
 * - With trailing containers (edit/delete buttons): MergeSemantics absorbs the
 *   title into the node's aria-label; text content shows only trailing button text
 *   → getByText() fails, flt-tappable[aria-label*=] succeeds.
 * Both locators race; whichever resolves first wins.
 */
function firstVisible(
  locators: import('@playwright/test').Locator[],
  timeout: number,
): Promise<import('@playwright/test').Locator> {
  return new Promise<import('@playwright/test').Locator>((resolve, reject) => {
    let settled = false;
    let pending = locators.length;
    for (const loc of locators) {
      loc.waitFor({ state: 'visible', timeout }).then(
        () => { if (!settled) { settled = true; resolve(loc); } },
        () => { if (--pending === 0 && !settled) reject(); },
      );
    }
  });
}

/**
 * Tap a Flutter flt-semantics list tile by text content.
 *
 * Flutter's _WorkoutCard / _ProgramCard / _WeekCard use a Stack overlay so that
 * ListTile has no trailing buttons. Without trailing container children, ListTile's
 * MergeSemantics produces a single flt-tappable node whose DOM text content IS the
 * tile title (not absorbed into aria-label). However the Stack itself also becomes
 * a non-tappable flt-semantics element whose textContent includes the title — and
 * page.getByText().first() in DOM order hits that non-tappable Stack container before
 * the tappable ListTile node.
 *
 * Selection: flt-semantics[flt-tappable]:has-text() finds the correct tappable node.
 * Fallback: flt-tappable[aria-label*=] catches merged-semantics nodes where the title
 * is in aria-label rather than text content.
 *
 * Click mechanism: with --force-renderer-accessibility, tappable flt-semantics elements
 * have pointer-events:all and intercept all pointer events. Flutter's glass-pane gesture
 * handler skips gesture processing when event.target is a flt-semantics element (it
 * relies on performAction from the semantics click listener instead). However,
 * performAction does not reliably trigger ListTile.onTap navigation in this build.
 *
 * Fix: temporarily set pointer-events:none on all flt-semantics before the click so
 * the event target becomes flt-glass-pane rather than flt-semantics. Flutter's gesture
 * engine then processes the event via normal hit-testing and fires ListTile.onTap.
 * We click at 25% from the left edge to stay clear of right-side trailing buttons.
 */
async function tapListTile(page: import('@playwright/test').Page, text: string): Promise<void> {
  const el = await firstVisible(
    [
      // Primary: tappable flt-semantics whose DOM text content contains the tile title.
      // [flt-tappable] excludes non-tappable Stack/group containers that also match :has-text.
      page.locator(`flt-semantics[flt-tappable]:has-text("${text}")`).first(),
      // Fallback: title is in aria-label (merged-semantics case).
      page.locator(`flt-semantics[flt-tappable][aria-label*="${text}"]`).first(),
    ],
    15_000,
  ).catch(() => { throw new Error(`Tile "${text}" not found within 15s`); });

  // Log which element was resolved (visible in gh run view --log for debugging).
  const elInfo = await el.evaluate((e: Element) => ({
    text: (e.textContent ?? '').trim().slice(0, 50),
    role: e.getAttribute('role'),
    tappable: e.hasAttribute('flt-tappable'),
    box: (() => { const r = (e as HTMLElement).getBoundingClientRect(); return {x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height)}; })(),
  }));
  console.log(`[E2E][tap] "${text}" → ${JSON.stringify(elInfo)}`);

  const box = await el.boundingBox();
  if (box) {
    const cx = box.x + box.width * 0.25;
    const cy = box.y + box.height * 0.5;

    // Bypass the flt-semantics pointer-events intercept so the click reaches the
    // Flutter canvas / glass-pane directly and is processed by the gesture engine.
    await page.evaluate(() => {
      document.querySelectorAll('flt-semantics').forEach(e => {
        (e as HTMLElement).style.pointerEvents = 'none';
      });
    });
    await page.mouse.click(cx, cy);
    await page.evaluate(() => {
      document.querySelectorAll('flt-semantics').forEach(e => {
        (e as HTMLElement).style.pointerEvents = '';
      });
    });
  } else {
    // Fallback: dispatchEvent if the element has no layout box (should not happen).
    await el.dispatchEvent('click');
  }
}

/** Assert that a named tile is visible by text content or aria-label. */
async function assertTileVisible(
  page: import('@playwright/test').Page,
  text: string,
  timeout = 10_000,
): Promise<void> {
  await firstVisible(
    [
      page.getByText(text).first(),
      page.locator(`flt-semantics[aria-label*="${text}"]`).first(),
    ],
    timeout,
  ).catch(() => { throw new Error(`"${text}" not visible by text or aria-label within ${timeout}ms`); });
}


test.describe('Workout Set Logging', () => {
  test.beforeEach(async ({ page }) => {
    // Extend timeout for the full test (beforeEach + test body): sign-in alone can take
    // up to 60s in the emulator on a cold browser. The default 60s total budget leaves
    // no room for the Firestore PATCH + sign-in + navigation + set-logging steps.
    test.setTimeout(120_000);

    // Reset the set's checked field to false before each attempt so tests are isolated
    // regardless of run order: mobile runs first, clicks the checkbox, and persists
    // checked:true; without this reset the desktop run (and any mobile retry) would see
    // checked:true and fail the not.toBeChecked() assertion.
    const uid = process.env.E2E_TEST_UID ?? '';
    const setUrl = `http://localhost:8080/v1/projects/fitness-app-8505e/databases/(default)/documents/users/${uid}/programs/e2e-program-001/weeks/e2e-week-001/workouts/e2e-workout-001/exercises/e2e-exercise-001/sets/e2e-set-001?updateMask.fieldPaths=checked&updateMask.fieldPaths=updatedAt`;
    await fetch(setUrl, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer owner' },
      body: JSON.stringify({ fields: { checked: { booleanValue: false }, updatedAt: { timestampValue: new Date().toISOString() } } }),
    }).catch(() => {}); // non-fatal: if emulator isn't ready, the seeded value is already false

    await signIn(page, EMAIL, PASSWORD);
  });

  test('navigates to seeded workout and checks off a set', async ({ page }, testInfo) => {

    // Diagnostic: read seeded program document directly from the Firestore emulator REST API
    // (bypassing Flutter and security rules) to confirm the data is present and correct.
    // If this returns null/error, the seeding in global-setup failed or used the wrong path.
    const uid = process.env.E2E_TEST_UID ?? '';
    const docUrl = `http://localhost:8080/v1/projects/fitness-app-8505e/databases/(default)/documents/users/${uid}/programs/e2e-program-001`;
    const directDoc = await fetch(docUrl, { headers: { 'Authorization': 'Bearer owner' } })
      .then(r => r.ok ? r.json() : r.text())
      .catch((e: Error) => ({ error: e.message }));
    const fields = (directDoc as { fields?: Record<string, unknown> })?.fields;
    console.log(`[E2E][direct-read] uid=${uid} name=${JSON.stringify(fields?.name)} isArchived=${JSON.stringify(fields?.isArchived)} createdAt=${JSON.stringify(fields?.createdAt)}`);

    // Wait for HomeScreen before attempting any navigation.
    // auth_provider calls user.reload() after sign-in to refresh emailVerified; it has a
    // 10s timeout, so HomeScreen navigation can begin up to ~11s after signIn() returns.
    await expect(page.getByText('My Programs').first()).toBeVisible({ timeout: 20_000 });

    // DOM diagnostic: dump flt-semantics nodes to confirm program card aria-label structure.
    // MergeSemantics (used by ListTile with trailing IconButtons) merges the title into
    // aria-label rather than text content; this log confirms which selector to use.
    const domDump = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics'));
      return {
        count: els.length,
        nodes: els.map(e => ({
          text: (e.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 80),
          label: e.getAttribute('aria-label'),
          role: e.getAttribute('role'),
          tappable: e.hasAttribute('flt-tappable'),
        })).filter(n => n.text || n.label),
      };
    });
    console.log(`[E2E][dom-dump] count=${domDump.count} nodes=${JSON.stringify(domDump.nodes.slice(0, 25))}`);

    // --- NAVIGATE TO WORKOUT ---
    await tapListTile(page, PROGRAM_NAME);

    // Diagnostic: confirm navigation by checking current flt-semantics node texts.
    // If still on programs screen, "E2E Test Program" tile is still present.
    // If navigated to program detail, the tile is gone and week tiles appear instead.
    await page.waitForTimeout(1500);
    const postTapDump = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics[flt-tappable]'));
      return els.map(e => (e.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 35));
    });
    console.log(`[E2E][post-tap-tappables] ${JSON.stringify(postTapDump)}`);

    await assertTileVisible(page, WEEK_NAME, 10_000);

    // Navigate into Week 1
    await tapListTile(page, WEEK_NAME);

    // Diagnostic: confirm navigation to WeeksScreen succeeded.
    // If still on ProgramDetailScreen, week tile is present; if navigated, workout tiles appear.
    await page.waitForTimeout(1500);
    const postWeekTapDump = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics[flt-tappable]'));
      return els.map(e => (e.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 35));
    });
    console.log(`[E2E][post-week-tap-tappables] ${JSON.stringify(postWeekTapDump)}`);

    await assertTileVisible(page, WORKOUT_NAME, 10_000);

    // Navigate into E2E Workout
    await tapListTile(page, WORKOUT_NAME);

    // Diagnostic: confirm navigation to ConsolidatedWorkoutScreen.
    // If exercises fail to load (orderIndex field missing, updatedAt cast error, etc.),
    // this dump reveals whether we're on an error state or loading state.
    await page.waitForTimeout(2000);
    const postWorkoutTapDump = await page.evaluate(() => {
      const els = Array.from(document.querySelectorAll('flt-semantics'));
      return els.map(e => ({
        text: (e.textContent ?? '').trim().replace(/\s+/g, ' ').slice(0, 60),
        label: e.getAttribute('aria-label')?.slice(0, 60) ?? null,
        tappable: e.hasAttribute('flt-tappable'),
        role: e.getAttribute('role'),
      })).filter(n => n.text || n.label).slice(0, 30);
    });
    console.log(`[E2E][post-workout-tap-dump] ${JSON.stringify(postWorkoutTapDump)}`);

    await assertTileVisible(page, EXERCISE_NAME, 10_000);

    await page.screenshot({ path: `test-results/${testInfo.title}/01-workout-open.png` });

    // --- VERIFY EXERCISE IS VISIBLE ---
    await assertTileVisible(page, EXERCISE_NAME, 5_000);

    // --- LOG THE SET ---
    // The seeded set (reps:5, weight:60) is pre-populated in the set row.
    // Verify the reps text field is visible.
    // Flutter renders InputDecoration.labelText ('Reps *') as aria-label on the textbox
    // semantics node — NOT as a separate DOM text node — so getByText('Reps *') finds nothing.
    await expect(page.getByRole('textbox', { name: /reps/i }).first()).toBeVisible({ timeout: 5_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/02-exercise-visible.png` });

    // Diagnostic: read the set document directly from the Firestore emulator to verify
    // the 'checked' field value as stored — bypasses Flutter and security rules.
    // If checked=true here, the seed wrote the wrong value or global-setup failed.
    // If checked=false here but the DOM shows aria-checked="true", it's a converter/Flutter bug.
    const setDocUrl = `http://localhost:8080/v1/projects/fitness-app-8505e/databases/(default)/documents/users/${uid}/programs/e2e-program-001/weeks/e2e-week-001/workouts/e2e-workout-001/exercises/e2e-exercise-001/sets/e2e-set-001`;
    const setDoc = await fetch(setDocUrl, { headers: { 'Authorization': 'Bearer owner' } })
      .then(r => r.ok ? r.json() : r.text())
      .catch((e: Error) => ({ error: (e as Error).message }));
    const setFields = (setDoc as { fields?: Record<string, unknown> })?.fields as Record<string, unknown> | undefined;
    console.log(`[E2E][set-direct-read] checked=${JSON.stringify(setFields?.checked)} reps=${JSON.stringify(setFields?.reps)} updatedAt=${JSON.stringify(setFields?.updatedAt)}`);

    // Diagnostic: dump ALL role="checkbox" elements in the DOM (unfiltered) to identify
    // exactly which element getByRole('checkbox').first() resolves to and what its state is.
    const allCheckboxes = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('[role="checkbox"]')).map(el => ({
        id: el.id,
        checked: el.getAttribute('aria-checked'),
        tappable: el.hasAttribute('flt-tappable'),
        text: (el.textContent ?? '').trim().slice(0, 40),
        label: el.getAttribute('aria-label'),
        rect: (() => {
          const r = (el as HTMLElement).getBoundingClientRect();
          return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
        })(),
      }));
    });
    console.log(`[E2E][all-checkboxes] count=${allCheckboxes.length} ${JSON.stringify(allCheckboxes)}`);

    // Check off the set using the Checkbox widget (Flutter renders as role="checkbox").
    // Use dispatchEvent('click') for the same reason as button clicks: the flt-semantics
    // node may be rebuilt after the toggle (set becomes read-only), which would cause
    // Playwright's .click() outer retry loop to re-fire indefinitely.
    const checkbox = page.getByRole('checkbox').first();
    await expect(checkbox).toBeVisible({ timeout: 5_000 });
    await expect(checkbox).not.toBeChecked();
    await checkbox.dispatchEvent('click');

    // After checking, the set becomes read-only and the checkbox should be checked
    await expect(checkbox).toBeChecked({ timeout: 5_000 });

    await page.screenshot({ path: `test-results/${testInfo.title}/03-set-checked.png` });

    // --- VERIFY PERSISTENCE ---
    // Read the set document directly from Firestore to confirm checked:true was persisted.
    // page.reload() is unreliable here: Firebase Auth state is not guaranteed to survive a
    // full page reload in the emulator environment (the app may land on the sign-in screen
    // rather than the Programs screen, causing the navigation-back assertions to timeout).
    // A direct Firestore read is a stronger persistence signal: if the value is in Firestore
    // it will survive any app restart or reload.
    await page.waitForTimeout(1500); // allow the Firestore write to propagate
    const persistDoc = await fetch(setDocUrl, { headers: { 'Authorization': 'Bearer owner' } })
      .then(r => r.ok ? r.json() : r.text())
      .catch((e: Error) => ({ error: (e as Error).message }));
    const persistFields = (persistDoc as { fields?: Record<string, unknown> })?.fields as Record<string, unknown> | undefined;
    const persistChecked = (persistFields?.checked as { booleanValue?: boolean })?.booleanValue;
    console.log(`[E2E][persist-check] checked=${persistChecked}`);
    expect(persistChecked).toBe(true);

    await page.screenshot({ path: `test-results/${testInfo.title}/04-persisted-verified.png` });
  });
});
