const AUTH_URL = 'http://localhost:9099';
const FIRESTORE_URL = 'http://localhost:8080';
const PROJECT_ID = 'fitness-app-8505e';

export async function createTestUser(email: string, password: string): Promise<string> {
  // Step 1: Create user
  const signUpRes = await fetch(
    `${AUTH_URL}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  if (!signUpRes.ok) {
    throw new Error(`createTestUser failed: ${await signUpRes.text()}`);
  }
  const { localId, idToken } = await signUpRes.json() as { localId: string; idToken: string };

  // Step 2: Trigger email verification — this stores an OOB code in the emulator.
  // The emulator does NOT send a real email; the code is retrievable via the
  // emulator's /oobCodes endpoint (same pattern as the Android integration tests
  // in integration_test/firebase_emulator_setup.dart:_setEmailVerifiedInEmulator).
  const sendOobRes = await fetch(
    `${AUTH_URL}/identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requestType: 'VERIFY_EMAIL', idToken }),
    }
  );
  if (!sendOobRes.ok) {
    throw new Error(`sendOobCode failed: ${await sendOobRes.text()}`);
  }

  // Step 3: Retrieve the OOB code from the emulator management endpoint.
  // The response is { oobCodes: [{ email, requestType, oobCode, ... }] }.
  const oobListRes = await fetch(`${AUTH_URL}/emulator/v1/projects/${PROJECT_ID}/oobCodes`);
  if (!oobListRes.ok) {
    throw new Error(`getOobCodes failed: ${await oobListRes.text()}`);
  }
  const oobListData = await oobListRes.json() as {
    oobCodes: Array<{ email: string; requestType: string; oobCode: string }>;
  };
  const entry = [...oobListData.oobCodes]
    .reverse()
    .find(c => c.email === email && c.requestType === 'VERIFY_EMAIL');
  if (!entry) {
    throw new Error(`No VERIFY_EMAIL OOB code found for ${email}`);
  }

  // Step 4: Apply the OOB code (simulates the user clicking the verification link)
  const confirmRes = await fetch(
    `${AUTH_URL}/identitytoolkit.googleapis.com/v1/accounts:update?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ oobCode: entry.oobCode }),
    }
  );
  if (!confirmRes.ok) {
    throw new Error(`confirmEmailVerification failed: ${await confirmRes.text()}`);
  }

  return localId;
}

export async function seedFirestoreDoc(
  path: string,
  fields: Record<string, unknown>
): Promise<void> {
  // Convert plain JS values to Firestore REST value format
  const firestoreFields = toFirestoreFields(fields);
  const segments = path.split('/');
  const docId = segments[segments.length - 1];
  const collectionPath = segments.slice(0, -1).join('/');

  const url = `${FIRESTORE_URL}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collectionPath}/${docId}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      // 'owner' is the Firebase emulator admin bypass token — skips security rules
      // (same role the Admin SDK occupies in production).
      'Authorization': 'Bearer owner',
    },
    body: JSON.stringify({ fields: firestoreFields }),
  });
  if (!res.ok) {
    throw new Error(`seedFirestoreDoc(${path}) failed: ${await res.text()}`);
  }
}

export async function clearEmulatorData(): Promise<void> {
  const url = `${FIRESTORE_URL}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
  await fetch(url, { method: 'DELETE' });
  // Auth emulator clear
  const authClearUrl = `${AUTH_URL}/emulator/v1/projects/${PROJECT_ID}/accounts`;
  await fetch(authClearUrl, { method: 'DELETE' });
}

// Converts a plain JS object to Firestore REST API field format
function toFirestoreFields(obj: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    result[key] = toFirestoreValue(value);
  }
  return result;
}

function toFirestoreValue(value: unknown): unknown {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object' && value !== null) {
    return {
      mapValue: {
        fields: toFirestoreFields(value as Record<string, unknown>),
      },
    };
  }
  return { stringValue: String(value) };
}
