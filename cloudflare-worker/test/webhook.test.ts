import { describe, it, expect, vi, beforeEach } from 'vitest';
import { handleStripeWebhook } from '../src/webhook';

// Mock writeSubscription to avoid real Firestore calls.
vi.mock('../src/firestore', () => ({
  writeSubscription: vi.fn().mockResolvedValue(undefined),
}));

import { writeSubscription } from '../src/firestore';

const mockEnv: Env = {
  FIREBASE_PROJECT_ID: 'test-project',
  STRIPE_SECRET_KEY: 'sk_test_mock',
  STRIPE_WEBHOOK_SECRET: 'whsec_test_secret',
  FIREBASE_SERVICE_ACCOUNT_JSON: '{}',
};

// Builds a valid Stripe-Signature header using HMAC-SHA256.
async function buildSignatureHeader(body: string, secret: string, timestamp = Math.floor(Date.now() / 1000)): Promise<string> {
  const signingPayload = `${timestamp}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sigBytes = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signingPayload));
  const sig = Array.from(new Uint8Array(sigBytes))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `t=${timestamp},v1=${sig}`;
}

function makeWebhookRequest(body: string, signatureHeader: string): Request {
  return new Request('https://worker.test/stripe-webhook', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Stripe-Signature': signatureHeader,
    },
    body,
  });
}

const mockSub = {
  id: 'sub_123',
  status: 'active',
  current_period_end: 1800000000,
  metadata: { uid: 'user123' },
  items: { data: [{ price: { id: 'price_annual' } }] },
};

describe('handleStripeWebhook', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns 400 for invalid signature', async () => {
    const body = JSON.stringify({ type: 'checkout.session.completed', data: { object: {} } });
    const req = makeWebhookRequest(body, 't=12345,v1=invalidsig');
    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(400);
  });

  it('returns 400 for missing signature header', async () => {
    const body = '{}';
    const req = new Request('https://worker.test/stripe-webhook', {
      method: 'POST',
      body,
    });
    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(400);
  });

  it('handles customer.subscription.updated and writes to Firestore', async () => {
    const event = {
      type: 'customer.subscription.updated',
      data: { object: mockSub },
    };
    const body = JSON.stringify(event);
    const sig = await buildSignatureHeader(body, mockEnv.STRIPE_WEBHOOK_SECRET);
    const req = makeWebhookRequest(body, sig);

    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(200);
    expect(writeSubscription).toHaveBeenCalledWith(
      mockEnv,
      'user123',
      'sub_123',
      'active',
      'price_annual',
      1800000000,
    );
  });

  it('handles customer.subscription.deleted and writes canceled status', async () => {
    const deletedSub = { ...mockSub, status: 'canceled' };
    const event = { type: 'customer.subscription.deleted', data: { object: deletedSub } };
    const body = JSON.stringify(event);
    const sig = await buildSignatureHeader(body, mockEnv.STRIPE_WEBHOOK_SECRET);
    const req = makeWebhookRequest(body, sig);

    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(200);
    expect(writeSubscription).toHaveBeenCalledWith(
      mockEnv,
      'user123',
      'sub_123',
      'canceled',
      'price_annual',
      1800000000,
    );
  });

  it('handles checkout.session.completed by fetching subscription from Stripe', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(
      JSON.stringify(mockSub),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )));

    const event = {
      type: 'checkout.session.completed',
      data: {
        object: {
          client_reference_id: 'user123',
          subscription: 'sub_123',
        },
      },
    };
    const body = JSON.stringify(event);
    const sig = await buildSignatureHeader(body, mockEnv.STRIPE_WEBHOOK_SECRET);
    const req = makeWebhookRequest(body, sig);

    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(200);
    expect(writeSubscription).toHaveBeenCalledWith(
      mockEnv,
      'user123',
      'sub_123',
      'active',
      'price_annual',
      1800000000,
    );
    vi.unstubAllGlobals();
  });

  it('returns 500 when writeSubscription throws (triggers Stripe retry)', async () => {
    vi.mocked(writeSubscription).mockRejectedValueOnce(new Error('Firestore error'));

    const event = {
      type: 'customer.subscription.updated',
      data: { object: mockSub },
    };
    const body = JSON.stringify(event);
    const sig = await buildSignatureHeader(body, mockEnv.STRIPE_WEBHOOK_SECRET);
    const req = makeWebhookRequest(body, sig);

    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(500);
  });

  it('returns 200 for unhandled event types (no retry needed)', async () => {
    const event = { type: 'payment_intent.created', data: { object: {} } };
    const body = JSON.stringify(event);
    const sig = await buildSignatureHeader(body, mockEnv.STRIPE_WEBHOOK_SECRET);
    const req = makeWebhookRequest(body, sig);

    const res = await handleStripeWebhook(req, mockEnv);
    expect(res.status).toBe(200);
    expect(writeSubscription).not.toHaveBeenCalled();
  });

  it('idempotent: processing the same event twice calls writeSubscription twice with same args', async () => {
    const event = {
      type: 'customer.subscription.updated',
      data: { object: mockSub },
    };
    const body = JSON.stringify(event);
    const sig = await buildSignatureHeader(body, mockEnv.STRIPE_WEBHOOK_SECRET);

    const res1 = await handleStripeWebhook(makeWebhookRequest(body, sig), mockEnv);
    const res2 = await handleStripeWebhook(makeWebhookRequest(body, sig), mockEnv);

    expect(res1.status).toBe(200);
    expect(res2.status).toBe(200);
    expect(writeSubscription).toHaveBeenCalledTimes(2);
    expect(vi.mocked(writeSubscription).mock.calls[0]).toEqual(
      vi.mocked(writeSubscription).mock.calls[1],
    );
  });
});
