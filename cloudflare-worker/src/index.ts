import { handleCreateCheckoutSession } from './checkout';
import { handleStripeWebhook } from './webhook';
import { corsHeaders } from './cors';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(request),
      });
    }

    if (request.method === 'POST' && url.pathname === '/create-checkout-session') {
      return handleCreateCheckoutSession(request, env);
    }

    if (request.method === 'POST' && url.pathname === '/stripe-webhook') {
      return handleStripeWebhook(request, env);
    }

    return new Response('Not Found', { status: 404 });
  },
} satisfies ExportedHandler<Env>;
