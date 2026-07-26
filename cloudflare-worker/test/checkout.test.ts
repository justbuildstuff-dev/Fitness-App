import { describe, it, expect, vi, beforeEach, beforeAll } from 'vitest';
import { handleCreateCheckoutSession } from '../src/checkout';
import {
  TEST_PROJECT_ID,
  buildIdToken,
  buildJwks,
  generateTestKeyPair,
  stubFetchWithJwks,
} from './helpers/firebaseToken';

const ALLOWED_ORIGIN = 'https://overload-workouts.web.app';

const mockEnv: Env = {
  FIREBASE_PROJECT_ID: TEST_PROJECT_ID,
  STRIPE_SECRET_KEY: 'sk_test_mock',
  STRIPE_WEBHOOK_SECRET: 'whsec_test_mock',
  FIREBASE_SERVICE_ACCOUNT_JSON: '{}',
  STRIPE_PRICE_ID_MONTHLY: 'price_monthly',
  STRIPE_PRICE_ID_ANNUAL: 'price_annual',
};

let keyPair: CryptoKeyPair;
let jwks: { keys: unknown[] };
let validIdToken: string;

function makeRequest(
  body: unknown,
  options: { authToken?: string; origin?: string } = {},
): Request {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (options.authToken) {
    headers.Authorization = `Bearer ${options.authToken}`;
  }
  if (options.origin) {
    headers.Origin = options.origin;
  }
  return new Request('https://worker.test/create-checkout-session', {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
}

// A valid, fully-formed checkout body — tests override individual fields.
function validBody(overrides: Partial<Record<string, string>> = {}) {
  return {
    uid: 'user123',
    priceId: 'price_monthly',
    successUrl: `${ALLOWED_ORIGIN}/?checkout=success`,
    cancelUrl: `${ALLOWED_ORIGIN}/?checkout=cancelled`,
    ...overrides,
  };
}

const okStripeResponse = () =>
  new Response(JSON.stringify({ url: 'https://checkout.stripe.com/test123' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });

describe('handleCreateCheckoutSession', () => {
  beforeAll(async () => {
    keyPair = await generateTestKeyPair();
    jwks = await buildJwks(keyPair.publicKey);
    validIdToken = await buildIdToken(keyPair.privateKey, { sub: 'user123' });
  });

  beforeEach(() => {
    vi.restoreAllMocks();
    stubFetchWithJwks(jwks, okStripeResponse);
  });

  it('returns 401 when Authorization header is missing', async () => {
    const req = makeRequest(validBody());
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(401);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Missing Authorization');
  });

  it('returns 401 when the ID token is malformed', async () => {
    const req = makeRequest(validBody(), { authToken: 'not-a-valid-jwt' });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(401);
  });

  it('returns 401 when the ID token is expired', async () => {
    const expiredToken = await buildIdToken(keyPair.privateKey, {
      sub: 'user123',
      iat: Math.floor(Date.now() / 1000) - 7200,
      exp: Math.floor(Date.now() / 1000) - 3600,
    });
    const req = makeRequest(validBody(), { authToken: expiredToken });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(401);
  });

  it('returns 403 when body uid does not match the authenticated uid', async () => {
    const req = makeRequest(validBody({ uid: 'someone-else' }), { authToken: validIdToken });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(403);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('does not match');
  });

  it('returns 400 for invalid JSON', async () => {
    const req = new Request('https://worker.test/create-checkout-session', {
      method: 'POST',
      headers: { Authorization: `Bearer ${validIdToken}` },
      body: 'not-json',
    });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Invalid JSON');
  });

  it('returns 400 when required fields are missing', async () => {
    const req = makeRequest({ uid: 'user123' }, { authToken: validIdToken });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Missing required fields');
  });

  it('returns 400 for a priceId that is not one of the published plans', async () => {
    const req = makeRequest(validBody({ priceId: 'price_some_other_product' }), {
      authToken: validIdToken,
    });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Unknown priceId');
  });

  it('returns 400 when successUrl is not on an allow-listed origin', async () => {
    const req = makeRequest(
      validBody({ successUrl: 'https://evil.example.com/?checkout=success' }),
      { authToken: validIdToken },
    );
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('allow-listed origin');
  });

  it('returns 400 when cancelUrl is not on an allow-listed origin', async () => {
    const req = makeRequest(
      validBody({ cancelUrl: 'https://evil.example.com/?checkout=cancelled' }),
      { authToken: validIdToken },
    );
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('allow-listed origin');
  });

  it('calls Stripe API with correct params and returns url', async () => {
    const req = makeRequest(validBody(), { authToken: validIdToken });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(200);

    const json = await res.json<{ url: string }>();
    expect(json.url).toBe('https://checkout.stripe.com/test123');

    // Verify Stripe was called with correct params
    const fetchCall = vi.mocked(fetch).mock.calls.find(
      ([url]) => url.toString() === 'https://api.stripe.com/v1/checkout/sessions',
    );
    const [stripeUrl, stripeInit] = fetchCall as [string, RequestInit];
    expect(stripeUrl).toBe('https://api.stripe.com/v1/checkout/sessions');
    expect(stripeInit.headers).toMatchObject({
      Authorization: `Bearer sk_test_mock`,
    });

    const body = new URLSearchParams(stripeInit.body as string);
    expect(body.get('mode')).toBe('subscription');
    expect(body.get('client_reference_id')).toBe('user123');
    expect(body.get('line_items[0][price]')).toBe('price_monthly');
    expect(body.get('subscription_data[metadata][uid]')).toBe('user123');
  });

  it('accepts the annual priceId as well as monthly', async () => {
    const req = makeRequest(validBody({ priceId: 'price_annual' }), {
      authToken: validIdToken,
    });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(200);
  });

  it('returns 502 when Stripe API returns an error', async () => {
    stubFetchWithJwks(
      jwks,
      () =>
        new Response(JSON.stringify({ error: { message: 'Invalid API key' } }), { status: 401 }),
    );

    const req = makeRequest(validBody(), { authToken: validIdToken });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(502);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Failed to create checkout session');
  });

  it('echoes back an allow-listed Origin on the CORS header', async () => {
    const req = makeRequest(validBody({ priceId: 'price_annual' }), {
      authToken: validIdToken,
      origin: ALLOWED_ORIGIN,
    });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe(ALLOWED_ORIGIN);
  });

  it('omits the CORS header for a non-allow-listed Origin', async () => {
    const req = makeRequest(validBody({ priceId: 'price_annual' }), {
      authToken: validIdToken,
      origin: 'https://evil.example.com',
    });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
  });
});
