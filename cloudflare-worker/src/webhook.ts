import { writeSubscription } from './firestore';

interface StripeSubscription {
  id: string;
  status: string;
  current_period_end: number;
  metadata: { uid?: string };
  items: { data: Array<{ price: { id: string } }> };
}

interface StripeCheckoutSession {
  client_reference_id: string;
  subscription: string;
}

interface StripeEvent {
  type: string;
  data: { object: StripeSubscription | StripeCheckoutSession };
}

// Verifies a Stripe webhook signature using HMAC-SHA256.
// Returns true if valid, false if the signature doesn't match or is malformed.
async function verifyStripeSignature(
  body: string,
  signatureHeader: string,
  secret: string,
): Promise<boolean> {
  const parts = Object.fromEntries(
    signatureHeader.split(',').map((p) => p.split('=')),
  ) as Record<string, string>;

  const timestamp = parts['t'];
  const expectedSig = parts['v1'];
  if (!timestamp || !expectedSig) return false;

  const signingPayload = `${timestamp}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signatureBytes = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(signingPayload),
  );

  const computedSig = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  // Constant-time comparison to prevent timing attacks.
  if (computedSig.length !== expectedSig.length) return false;
  let mismatch = 0;
  for (let i = 0; i < computedSig.length; i++) {
    mismatch |= computedSig.charCodeAt(i) ^ expectedSig.charCodeAt(i);
  }
  return mismatch === 0;
}

async function fetchStripeSubscription(
  subscriptionId: string,
  secretKey: string,
): Promise<StripeSubscription> {
  const response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
    headers: { Authorization: `Bearer ${secretKey}` },
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch subscription ${subscriptionId}: ${response.status}`);
  }
  return response.json<StripeSubscription>();
}

export async function handleStripeWebhook(request: Request, env: Env): Promise<Response> {
  const body = await request.text();
  const signatureHeader = request.headers.get('Stripe-Signature') ?? '';

  const isValid = await verifyStripeSignature(body, signatureHeader, env.STRIPE_WEBHOOK_SECRET);
  if (!isValid) {
    return new Response('Invalid signature', { status: 400 });
  }

  let event: StripeEvent;
  try {
    event = JSON.parse(body) as StripeEvent;
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as StripeCheckoutSession;
        const uid = session.client_reference_id;
        if (!uid) {
          console.error('checkout.session.completed missing client_reference_id');
          break;
        }
        const sub = await fetchStripeSubscription(session.subscription, env.STRIPE_SECRET_KEY);
        const priceId = sub.items.data[0]?.price.id ?? '';
        await writeSubscription(env, uid, sub.id, sub.status, priceId, sub.current_period_end);
        break;
      }

      case 'customer.subscription.updated': {
        const sub = event.data.object as StripeSubscription;
        const uid = sub.metadata?.uid;
        if (!uid) {
          console.error('customer.subscription.updated missing metadata.uid');
          break;
        }
        const priceId = sub.items.data[0]?.price.id ?? '';
        await writeSubscription(env, uid, sub.id, sub.status, priceId, sub.current_period_end);
        break;
      }

      case 'customer.subscription.deleted': {
        const sub = event.data.object as StripeSubscription;
        const uid = sub.metadata?.uid;
        if (!uid) {
          console.error('customer.subscription.deleted missing metadata.uid');
          break;
        }
        const priceId = sub.items.data[0]?.price.id ?? '';
        await writeSubscription(env, uid, sub.id, 'canceled', priceId, sub.current_period_end);
        break;
      }

      default:
        // Unhandled event types are silently ignored; Stripe doesn't need a retry.
        break;
    }
  } catch (err) {
    console.error('Webhook handler error:', err);
    // Return 500 so Stripe retries the event.
    return new Response('Internal error', { status: 500 });
  }

  return new Response('OK', { status: 200 });
}
