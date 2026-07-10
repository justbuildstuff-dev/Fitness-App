interface ServiceAccount {
  client_email: string;
  private_key: string;
}

interface FirestoreField {
  stringValue?: string;
  timestampValue?: string;
  arrayValue?: { values: FirestoreField[] };
  mapValue?: { fields: Record<string, FirestoreField> };
}

interface FirestoreDocument {
  fields: Record<string, FirestoreField>;
}

// Builds a Firestore REST API subscription document from primitive values.
function buildSubscriptionDocument(
  status: string,
  priceId: string,
  currentPeriodEnd: number,
): FirestoreDocument {
  const endDate = new Date(currentPeriodEnd * 1000).toISOString();
  return {
    fields: {
      status: { stringValue: status },
      items: {
        arrayValue: {
          values: [
            {
              mapValue: {
                fields: {
                  price: {
                    mapValue: {
                      fields: {
                        id: { stringValue: priceId },
                      },
                    },
                  },
                },
              },
            },
          ],
        },
      },
      current_period_end: { timestampValue: endDate },
    },
  };
}

// Converts a PEM private key string to a CryptoKey for RSASSA-PKCS1-v1_5 signing.
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContent = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const der = Uint8Array.from(atob(pemContent), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function base64url(data: ArrayBuffer | Uint8Array): string {
  const bytes = data instanceof ArrayBuffer ? new Uint8Array(data) : data;
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// Builds a signed JWT and exchanges it for a Google OAuth2 access token.
async function getAccessToken(env: Env): Promise<string> {
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON) as ServiceAccount;

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    scope: 'https://www.googleapis.com/auth/datastore',
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64url(new TextEncoder().encode(JSON.stringify(header)));
  const encodedPayload = base64url(new TextEncoder().encode(JSON.stringify(payload)));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const privateKey = await importPrivateKey(sa.private_key);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput),
  );

  const jwt = `${signingInput}.${base64url(signature)}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  });

  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${tokenResponse.status}`);
  }

  const tokenData = await tokenResponse.json<{ access_token: string }>();
  return tokenData.access_token;
}

// Writes or updates a subscription document in Firestore via the Admin REST API.
// Uses updateMask to avoid overwriting fields not owned by this worker.
export async function writeSubscription(
  env: Env,
  uid: string,
  subscriptionId: string,
  status: string,
  priceId: string,
  currentPeriodEnd: number,
): Promise<void> {
  const accessToken = await getAccessToken(env);
  const projectId = env.FIREBASE_PROJECT_ID;

  const docPath = `customers/${uid}/subscriptions/${subscriptionId}`;
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${docPath}` +
    '?updateMask.fieldPaths=status&updateMask.fieldPaths=items&updateMask.fieldPaths=current_period_end';

  const body = buildSubscriptionDocument(status, priceId, currentPeriodEnd);

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Firestore PATCH failed (${response.status}): ${errorText}`);
  }
}
