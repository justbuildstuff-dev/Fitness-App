import { describe, it, expect, vi, beforeEach } from 'vitest';
import { handleCreateCheckoutSession } from '../src/checkout';

const mockEnv: Env = {
  FIREBASE_PROJECT_ID: 'test-project',
  STRIPE_SECRET_KEY: 'sk_test_mock',
  STRIPE_WEBHOOK_SECRET: 'whsec_test_mock',
  FIREBASE_SERVICE_ACCOUNT_JSON: '{}',
};

function makeRequest(body: unknown): Request {
  return new Request('https://worker.test/create-checkout-session', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('handleCreateCheckoutSession', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('returns 400 for invalid JSON', async () => {
    const req = new Request('https://worker.test/create-checkout-session', {
      method: 'POST',
      body: 'not-json',
    });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Invalid JSON');
  });

  it('returns 400 when required fields are missing', async () => {
    const req = makeRequest({ uid: 'user123' });
    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(400);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Missing required fields');
  });

  it('calls Stripe API with correct params and returns url', async () => {
    const mockSession = { url: 'https://checkout.stripe.com/test123' };
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(
      JSON.stringify(mockSession),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )));

    const req = makeRequest({
      uid: 'user123',
      priceId: 'price_monthly',
      successUrl: 'https://app.test/?checkout=success',
      cancelUrl: 'https://app.test/?checkout=cancelled',
    });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(200);

    const json = await res.json<{ url: string }>();
    expect(json.url).toBe('https://checkout.stripe.com/test123');

    // Verify Stripe was called with correct params
    const fetchCall = vi.mocked(fetch).mock.calls[0];
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

  it('returns 502 when Stripe API returns an error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(
      JSON.stringify({ error: { message: 'Invalid API key' } }),
      { status: 401 },
    )));

    const req = makeRequest({
      uid: 'user123',
      priceId: 'price_monthly',
      successUrl: 'https://app.test/?checkout=success',
      cancelUrl: 'https://app.test/?checkout=cancelled',
    });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.status).toBe(502);
    const json = await res.json<{ error: string }>();
    expect(json.error).toContain('Failed to create checkout session');
  });

  it('sets CORS header on response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(
      JSON.stringify({ url: 'https://checkout.stripe.com/test' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )));

    const req = makeRequest({
      uid: 'u1',
      priceId: 'price_annual',
      successUrl: 'https://app.test/?checkout=success',
      cancelUrl: 'https://app.test/?checkout=cancelled',
    });

    const res = await handleCreateCheckoutSession(req, mockEnv);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
  });
});
