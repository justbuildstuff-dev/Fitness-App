import { corsHeaders, isAllowedRedirectUrl } from './cors';
import { verifyFirebaseIdToken } from './auth';

export interface CheckoutRequest {
  uid: string;
  priceId: string;
  successUrl: string;
  cancelUrl: string;
}

export async function handleCreateCheckoutSession(
  request: Request,
  env: Env,
): Promise<Response> {
  const authHeader = request.headers.get('Authorization') ?? '';
  const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice('Bearer '.length) : '';
  if (!idToken) {
    return jsonResponse({ error: 'Missing Authorization header' }, 401, request);
  }

  let authenticatedUid: string;
  try {
    authenticatedUid = await verifyFirebaseIdToken(idToken, env.FIREBASE_PROJECT_ID);
  } catch (err) {
    console.error('ID token verification failed:', err);
    return jsonResponse({ error: 'Invalid or expired ID token' }, 401, request);
  }

  let body: CheckoutRequest;
  try {
    body = await request.json<CheckoutRequest>();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400, request);
  }

  const { uid, priceId, successUrl, cancelUrl } = body;
  if (!uid || !priceId || !successUrl || !cancelUrl) {
    return jsonResponse(
      { error: 'Missing required fields: uid, priceId, successUrl, cancelUrl' },
      400,
      request,
    );
  }

  // The client-supplied uid must match the authenticated caller — it's only
  // still accepted (rather than dropped) so the request stays self-describing
  // in logs; it is never trusted on its own.
  if (uid !== authenticatedUid) {
    return jsonResponse({ error: 'uid does not match authenticated user' }, 403, request);
  }

  // priceId is restricted to the two published plans — an authenticated
  // caller must not be able to check out an arbitrary Stripe price.
  const allowedPriceIds = [env.STRIPE_PRICE_ID_MONTHLY, env.STRIPE_PRICE_ID_ANNUAL];
  if (!allowedPriceIds.includes(priceId)) {
    return jsonResponse({ error: 'Unknown priceId' }, 400, request);
  }

  // successUrl/cancelUrl are echoed back to Stripe verbatim and Stripe will
  // redirect the browser there after checkout — restrict to our own origins
  // so this can't be used as an open redirect off a legitimate Stripe page.
  if (!isAllowedRedirectUrl(successUrl) || !isAllowedRedirectUrl(cancelUrl)) {
    return jsonResponse({ error: 'successUrl/cancelUrl must be on an allow-listed origin' }, 400, request);
  }

  const params = new URLSearchParams();
  params.append('mode', 'subscription');
  params.append('client_reference_id', uid);
  params.append('line_items[0][price]', priceId);
  params.append('line_items[0][quantity]', '1');
  params.append('success_url', successUrl);
  params.append('cancel_url', cancelUrl);
  // Store Firebase UID in subscription metadata so it's available on all
  // future subscription webhook events (updated, deleted).
  params.append('subscription_data[metadata][uid]', uid);

  const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: params.toString(),
  });

  if (!stripeResponse.ok) {
    const errorBody = await stripeResponse.text();
    console.error('Stripe API error:', stripeResponse.status, errorBody);
    return jsonResponse({ error: 'Failed to create checkout session' }, 502, request);
  }

  const session = await stripeResponse.json<{ url: string }>();
  return jsonResponse({ url: session.url }, 200, request);
}

function jsonResponse(body: unknown, status: number, request: Request): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders(request),
    },
  });
}
