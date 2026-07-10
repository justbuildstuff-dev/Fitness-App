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
  let body: CheckoutRequest;
  try {
    body = await request.json<CheckoutRequest>();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const { uid, priceId, successUrl, cancelUrl } = body;
  if (!uid || !priceId || !successUrl || !cancelUrl) {
    return jsonResponse(
      { error: 'Missing required fields: uid, priceId, successUrl, cancelUrl' },
      400,
    );
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
    return jsonResponse({ error: 'Failed to create checkout session' }, 502);
  }

  const session = await stripeResponse.json<{ url: string }>();
  return jsonResponse({ url: session.url }, 200);
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
