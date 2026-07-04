import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

const PROGRAM_NAME = 'E2E Created Program';
const WEEK_NAME = 'E2E Week 1';
const WORKOUT_NAME = 'E2E Push Day';

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
 * Tap a Flutter flt-semantics list tile by text content or aria-label.
 *
 * Tries text content first (simple tiles without trailing buttons), then falls back
 * to flt-tappable[aria-label*=] for tiles whose title is merged into aria-label by
 * MergeSemantics (triggered when trailing IconButtons are present as container nodes).
 *
 * Uses page.mouse.click() at the element's bounding-box centre rather than
 * dispatchEvent('click'). dispatchEvent creates a synthetic (isTrusted=false) event
 * that MergeSemantics flt-tappable nodes ignore; page.mouse.click() sends a CDP
 * Input.dispatchMouseEvent which arrives as a real (isTrusted=true) pointer event and
 * hits Flutter's canvas hit-test path, triggering the InkWell/GestureDetector onTap.
 * Coordinate-based mouse clicks also avoid Playwright's locator retry loop (which
 * re-fires .click() indefinitely after Flutter rebuilds the semantics tree on navigation).
 */
async function tapListTile(page: import('@playwright/test').Page, text: string): Promise<void> {
  const el = await firstVisible(
    [
      page.getByText(text).first(),
      page.locator(`flt-semantics[flt-tappable][aria-label*="${text}"]`).first(),
    ],
    15_000,
  ).catch(() => { throw new Error(`Tile "${text}" not found by text or aria-label within 15s`); });

  const box = await el.boundingBox();
  if (!box) throw new Error(`Tile "${text}" has no bounding box`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
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

/**
 * Fill a Flutter web text field identified by its accessible label.
 *
 * Creation screens set autofocus: !kIsWeb so the FocusNode starts unfocused on web.
 * A trusted CDP click (isTrusted=true, force:true) focuses the flt-semantics textbox,
 * then keyboard events route directly to the focused element. Control+A clears any
 * pre-filled value (e.g. "Week N") before typing.
 */
async function fillTextField(
  page: import('@playwright/test').Page,
  label: string | RegExp,
  text: string,
): Promise<void> {
  const textbox = page.getByRole('textbox', { name: label });
  await textbox.waitFor({ state: 'visible', timeout: 10_000 });
  await textbox.click({ force: true });
  await page.keyboard.press('Control+A');
  await page.keyboard.type(text);
}

test.describe('Program / Week / Workout Creation', () => {
  test.beforeEach(async ({ page }) => {
    await signIn(page, EMAIL, PASSWORD);
  });

  test('creates a program, week, and workout end-to-end', async ({ page }, testInfo) => {
    // --- SIGN-IN COMPLETE ---
    await page.screenshot({ path: `test-results/${testInfo.title}/01-signed-in.png` });

    // --- CREATE PROGRAM ---
    // Click the FAB (+) to open the create options bottom sheet.
    // All Flutter flt-semantics[role="button"] clicks use dispatchEvent('click')
    // rather than .click(): Playwright's .click() has an outer retry loop that
    // re-fires when the flt-semantics tree rebuilds after Flutter navigation. Each
    // click triggers a route change (pushState), which invalidates the element
    // reference, causing Playwright to re-find and re-click indefinitely until the
    // 60-second test timeout fires. dispatchEvent fires the DOM 'click' event once
    // without retry; Flutter's flt-tappable addEventListener('click') handler fires
    // and triggers the Dart tap callback exactly once.
    await page.getByRole('button', { name: 'Add' }).dispatchEvent('click');

    // Bottom sheet: choose "Start Fresh".
    // Bottom sheet items may render as role="listitem" — use tapListTile() which
    // selects by [flt-tappable] hasText rather than getByRole('button').
    await expect(page.getByText('Start Fresh')).toBeVisible({ timeout: 10_000 });
    await tapListTile(page, 'Start Fresh');

    // CreateProgramScreen: fill program name and submit.
    // fillTextField() clicks the textbox, waits for the flt-text-editing-host <input>
    // to confirm focus, then types. Without the input wait, keyboard.type() may
    // fire before Flutter has finished processing the focus event, dropping characters.
    await expect(page.getByText('Create New Program')).toBeVisible({ timeout: 10_000 });
    await fillTextField(page, /program name/i, PROGRAM_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/02-program-name-filled.png` });
    await page.getByRole('button', { name: 'CREATE', exact: true }).dispatchEvent('click');

    // Verify program appears in the list (tile title is in aria-label via MergeSemantics)
    await assertTileVisible(page, PROGRAM_NAME, 15_000);
    await page.screenshot({ path: `test-results/${testInfo.title}/03-program-created.png` });

    // --- NAVIGATE INTO PROGRAM ---
    await tapListTile(page, PROGRAM_NAME);
    // Wait for program detail screen (AppBar or tile shows program name)
    await assertTileVisible(page, PROGRAM_NAME, 10_000);

    // --- CREATE WEEK ---
    // Empty state shows "Create Week" button; if FAB is shown instead, fall back to FAB.
    const createWeekButton = page.getByRole('button', { name: 'Create Week' });
    const hasEmptyState = await createWeekButton.isVisible().catch(() => false);
    if (hasEmptyState) {
      await createWeekButton.dispatchEvent('click');
    } else {
      await page.getByRole('button', { name: 'Add' }).dispatchEvent('click');
    }

    // CreateWeekScreen: fill week name and submit
    await expect(page.getByText('Create New Week')).toBeVisible({ timeout: 10_000 });
    await fillTextField(page, /week name/i, WEEK_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/04-week-name-filled.png` });
    await page.getByRole('button', { name: 'CREATE', exact: true }).dispatchEvent('click');

    // Verify week appears in the list
    await assertTileVisible(page, WEEK_NAME, 15_000);
    await page.screenshot({ path: `test-results/${testInfo.title}/05-week-created.png` });

    // --- NAVIGATE INTO WEEK ---
    await tapListTile(page, WEEK_NAME);
    await assertTileVisible(page, WEEK_NAME, 10_000);

    // --- CREATE WORKOUT ---
    const createWorkoutButton = page.getByRole('button', { name: 'Create Workout' });
    const hasWorkoutEmptyState = await createWorkoutButton.isVisible().catch(() => false);
    if (hasWorkoutEmptyState) {
      await createWorkoutButton.dispatchEvent('click');
    } else {
      await page.getByRole('button', { name: 'Add' }).dispatchEvent('click');
    }

    // CreateWorkoutScreen: fill workout name and submit
    await expect(page.getByText('Create Workout').first()).toBeVisible({ timeout: 10_000 });
    await fillTextField(page, /workout name/i, WORKOUT_NAME);
    await page.screenshot({ path: `test-results/${testInfo.title}/06-workout-name-filled.png` });
    await page.getByRole('button', { name: 'CREATE', exact: true }).dispatchEvent('click');

    // Verify workout appears in the list
    await assertTileVisible(page, WORKOUT_NAME, 15_000);
    await page.screenshot({ path: `test-results/${testInfo.title}/07-workout-created.png` });
  });
});
