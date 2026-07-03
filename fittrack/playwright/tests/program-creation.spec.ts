import { test, expect } from '@playwright/test';
import { signIn } from '../helpers/sign-in';

const EMAIL = process.env.E2E_TEST_EMAIL ?? 'playwright-e2e@test.com';
const PASSWORD = process.env.E2E_TEST_PASSWORD ?? 'playwright-test-123';

const PROGRAM_NAME = 'E2E Created Program';
const WEEK_NAME = 'E2E Week 1';
const WORKOUT_NAME = 'E2E Push Day';

/**
 * Tap a Flutter flt-semantics list tile by text content.
 *
 * Strategy: wait for the text element to be visible (handles async Firestore loading),
 * then dispatch a click on it. The click event bubbles up to the flt-tappable
 * ListTile container's click listener, triggering the Dart onTap callback.
 *
 * Using getByText instead of locator('flt-semantics[flt-tappable]', { hasText }) because
 * ListTile widgets with trailing IconButtons (edit/delete) may not get flt-tappable on
 * their outer semantics container — Flutter may omit it when interactive children are
 * present. getByText finds the title text flt-semantics directly; dispatchEvent('click')
 * bubbles to whichever ancestor has the click listener.
 *
 * dispatchEvent is used instead of .click() to avoid Playwright's actionability retry
 * loop: after Flutter navigation the semantics tree rebuilds, which invalidates element
 * references and causes .click() to retry indefinitely until the 60-second timeout.
 */
async function tapListTile(page: import('@playwright/test').Page, text: string): Promise<void> {
  const el = page.getByText(text).first();
  await el.waitFor({ state: 'visible', timeout: 15_000 });
  await el.dispatchEvent('click');
}

/**
 * Fill a Flutter web text field identified by its accessible label.
 *
 * Uses element.focus() (via JS evaluate) rather than locator.click() (CDP pointer events)
 * to focus the flt-semantics[role="textbox"] element.
 *
 * On pushed routes (slide-in animation), CDP pointer events route to incorrect coordinates
 * in Flutter's gesture system — the pointer lands outside the widget's layout bounds while
 * the animation is in-flight, so the text field is never focused and flt-text-editing-host
 * <input> is never created. Waiting for the animation to settle and retrying clicks did not
 * resolve this (confirmed across multiple CI runs).
 *
 * element.focus() bypasses Flutter's gesture system entirely. It fires a DOM focus event
 * on the flt-semantics element, which Flutter's web engine handles via its accessibility
 * event listener: focus → SemanticsAction.didGainAccessibilityFocus → FocusNode.requestFocus()
 * → TextInputConnection.attach() → flt-text-editing-host <input> created. This works
 * regardless of route animation state.
 *
 * Control+A before typing clears any pre-filled value (e.g. "Week N" in CreateWeekScreen)
 * so the field contains only the typed text.
 */
async function fillTextField(
  page: import('@playwright/test').Page,
  label: string | RegExp,
  text: string,
): Promise<void> {
  const textbox = page.getByRole('textbox', { name: label });
  await textbox.waitFor({ state: 'visible', timeout: 10_000 });

  // Focus via JS rather than CDP pointer events — works on pushed routes where
  // animation-offset coordinates cause locator.click() to miss Flutter's gesture hit-test.
  await textbox.evaluate((el: Element) => (el as HTMLElement).focus());
  const input = page.locator('flt-text-editing-host input');
  await input.waitFor({ state: 'attached', timeout: 8_000 });

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

    // Verify program appears in the list
    await expect(page.getByText(PROGRAM_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/03-program-created.png` });

    // --- NAVIGATE INTO PROGRAM ---
    await tapListTile(page, PROGRAM_NAME);
    // Wait for program detail screen
    await expect(page.getByText(PROGRAM_NAME)).toBeVisible({ timeout: 10_000 });

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

    // Verify week appears
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/05-week-created.png` });

    // --- NAVIGATE INTO WEEK ---
    await tapListTile(page, WEEK_NAME);
    await expect(page.getByText(WEEK_NAME)).toBeVisible({ timeout: 10_000 });

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

    // Verify workout appears
    await expect(page.getByText(WORKOUT_NAME)).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: `test-results/${testInfo.title}/07-workout-created.png` });
  });
});
