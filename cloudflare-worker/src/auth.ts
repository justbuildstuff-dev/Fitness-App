// Verifies Firebase Auth ID tokens sent by the Flutter client, so the Worker
// never has to trust a client-supplied uid.
//
// Firebase ID tokens are RS256-signed JWTs. Google publishes the current
// signing keys in JWK format, which the Workers Web Crypto API can import
// directly (no need to parse X.509 certs by hand).
const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

interface Jwk {
  kid: string;
  n: string;
  e: string;
  kty: string;
  alg: string;
}

interface FirebaseIdTokenPayload {
  iss: string;
  aud: string;
  sub: string;
  exp: number;
  iat: number;
  auth_time?: number;
}

let cachedKeys: { keys: Jwk[]; expiresAt: number } | null = null;

async function getSigningKeys(): Promise<Jwk[]> {
  if (cachedKeys && cachedKeys.expiresAt > Date.now()) {
    return cachedKeys.keys;
  }

  const response = await fetch(JWKS_URL);
  if (!response.ok) {
    throw new Error(`Failed to fetch Firebase signing keys: ${response.status}`);
  }
  const body = await response.json<{ keys: Jwk[] }>();

  // Google rotates these keys infrequently; a short local cache avoids a
  // round trip on every checkout request without risking a long-lived stale key.
  cachedKeys = { keys: body.keys, expiresAt: Date.now() + 60 * 60 * 1000 };
  return body.keys;
}

function base64urlDecode(input: string): Uint8Array {
  const unpadded = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = unpadded + '='.repeat((4 - (unpadded.length % 4)) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

function decodeJson<T>(base64url: string): T {
  return JSON.parse(new TextDecoder().decode(base64urlDecode(base64url))) as T;
}

/**
 * Verifies a Firebase Auth ID token and returns the authenticated uid.
 * Throws if the token is missing, malformed, expired, or fails signature
 * verification against Google's published keys for the given project.
 */
export async function verifyFirebaseIdToken(
  idToken: string,
  projectId: string,
): Promise<string> {
  const parts = idToken.split('.');
  if (parts.length !== 3) {
    throw new Error('Malformed ID token');
  }
  const [encodedHeader, encodedPayload, encodedSignature] = parts;

  const header = decodeJson<{ alg: string; kid: string }>(encodedHeader);
  if (header.alg !== 'RS256') {
    throw new Error(`Unexpected token algorithm: ${header.alg}`);
  }

  const payload = decodeJson<FirebaseIdTokenPayload>(encodedPayload);
  const now = Math.floor(Date.now() / 1000);

  if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
    throw new Error('Invalid token issuer');
  }
  if (payload.aud !== projectId) {
    throw new Error('Invalid token audience');
  }
  if (typeof payload.exp !== 'number' || payload.exp <= now) {
    throw new Error('Token expired');
  }
  if (typeof payload.iat !== 'number' || payload.iat > now + 60) {
    throw new Error('Token issued in the future');
  }
  if (!payload.sub) {
    throw new Error('Token missing subject');
  }

  const keys = await getSigningKeys();
  const jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) {
    throw new Error('No matching signing key for token');
  }

  const publicKey = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );

  const signedData = new TextEncoder().encode(`${encodedHeader}.${encodedPayload}`);
  const signature = base64urlDecode(encodedSignature);

  const isValid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', publicKey, signature, signedData);
  if (!isValid) {
    throw new Error('Invalid token signature');
  }

  return payload.sub;
}
