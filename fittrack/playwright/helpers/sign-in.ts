import { Page } from '@playwright/test';

/**
 * Signs in via the app's sign-in screen using Firebase Auth emulator credentials.
 * Waits for the "My Programs" screen to confirm successful sign-in.
 *
 * Flutter web HTML renderer renders TextFormField as real <input> elements once
 * the field is focused. The email field is the first input; password uses type="password".
 */
export async function signIn(page: Page, email: string, password: string): Promise<void> {
  await page.goto('/');

  // Wait for sign-in form to render
  await page.waitForSelector('text=Sign In', { timeout: 20_000 });

  // Fill email — first text input on the sign-in screen
  const emailInput = page.locator('input').first();
  await emailInput.waitFor({ timeout: 10_000 });
  await emailInput.fill(email);

  // Fill password — obscureText:true renders as type="password"
  const passwordInput = page.locator('input[type="password"]');
  await passwordInput.waitFor({ timeout: 10_000 });
  await passwordInput.fill(password);

  // Click the Sign In button
  await page.getByText('Sign In', { exact: true }).click();

  // Wait for the home screen to confirm sign-in succeeded
  await page.waitForSelector('text=My Programs', { timeout: 20_000 });
}
