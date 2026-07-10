import { clearEmulatorData } from './helpers/firebase-emulator';

export default async function globalTeardown(): Promise<void> {
  await clearEmulatorData();
  console.log('[global-teardown] Emulator data cleared');
}
