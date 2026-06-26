const AUTH_URL = 'http://localhost:9099';
const FIRESTORE_URL = 'http://localhost:8080';
const PROJECT_ID = 'fitness-app-8505e';

export async function createTestUser(email: string, password: string): Promise<string> {
  // Create user via Auth emulator REST API
  const res = await fetch(
    `${AUTH_URL}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  if (!res.ok) {
    throw new Error(`createTestUser failed: ${await res.text()}`);
  }
  const data = await res.json() as { localId: string };

  // Mark email as verified via OOB endpoint
  const oobRes = await fetch(
    `${AUTH_URL}/emulator/v1/projects/${PROJECT_ID}/accounts`,
    {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ localId: data.localId, emailVerified: true }),
    }
  );
  if (!oobRes.ok) {
    throw new Error(`setEmailVerified failed: ${await oobRes.text()}`);
  }

  return data.localId;
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
    headers: { 'Content-Type': 'application/json' },
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
