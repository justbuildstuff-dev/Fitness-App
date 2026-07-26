import { vi } from 'vitest';

// Test-only helper for minting fake Firebase ID tokens and a matching JWKS
// response, so tests can exercise verifyFirebaseIdToken without hitting
// Google's real endpoints.
export const TEST_PROJECT_ID = 'test-project';
export const TEST_KID = 'test-kid-1';

function base64url(data: ArrayBuffer | Uint8Array): string {
  return Buffer.from(data).toString('base64url');
}

export async function generateTestKeyPair(): Promise<CryptoKeyPair> {
  return crypto.subtle.generateKey(
    {
      name: 'RSASSA-PKCS1-v1_5',
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: 'SHA-256',
    },
    true,
    ['sign', 'verify'],
  ) as Promise<CryptoKeyPair>;
}

export async function buildJwks(publicKey: CryptoKey): Promise<{ keys: unknown[] }> {
  const jwk = await crypto.subtle.exportKey('jwk', publicKey);
  return { keys: [{ ...jwk, kid: TEST_KID, alg: 'RS256' }] };
}

export async function buildIdToken(
  privateKey: CryptoKey,
  overrides: Record<string, unknown> = {},
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', kid: TEST_KID, typ: 'JWT' };
  const payload = {
    iss: `https://securetoken.google.com/${TEST_PROJECT_ID}`,
    aud: TEST_PROJECT_ID,
    sub: 'user123',
    iat: now,
    exp: now + 3600,
    auth_time: now,
    ...overrides,
  };

  const encodedHeader = base64url(Buffer.from(JSON.stringify(header)));
  const encodedPayload = base64url(Buffer.from(JSON.stringify(payload)));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64url(signature)}`;
}

// Wraps a Stripe-call fetch mock so JWKS lookups are transparently served
// from the given key pair, without the test needing to know the JWKS URL.
// Returns a vi.fn() spy (via vi.stubGlobal) so callers can assert on calls.
export function stubFetchWithJwks(
  jwks: { keys: unknown[] },
  stripeHandler: (url: string, init?: RequestInit) => Response | Promise<Response>,
): void {
  vi.stubGlobal(
    'fetch',
    vi.fn(async (url: string, init?: RequestInit) => {
      if (url.toString().includes('service_accounts/v1/jwk')) {
        return new Response(JSON.stringify(jwks), {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        });
      }
      return stripeHandler(url, init);
    }),
  );
}
