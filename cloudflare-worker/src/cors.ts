// Only the app's production web origins may call this Worker from a browser,
// and Stripe Checkout is only ever allowed to redirect back to one of these.
// The mobile app (iOS/Android) is not subject to CORS since requests don't
// originate from a browser context.
export const ALLOWED_ORIGINS = [
  'https://overload-workouts.web.app',
  'https://fitness-app-8505e.web.app',
  'https://fitness-app-8505e.firebaseapp.com',
];

const ALLOWED_ORIGINS_SET = new Set(ALLOWED_ORIGINS);

// Returns CORS headers for the given request, restricted to an allow-listed
// origin. If the request's Origin isn't allow-listed, no
// Access-Control-Allow-Origin header is returned and the browser will block
// the response from being read by the calling page.
export function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get('Origin');
  const headers: Record<string, string> = {
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    Vary: 'Origin',
  };
  if (origin && ALLOWED_ORIGINS_SET.has(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
  }
  return headers;
}

// Guards against an authenticated caller pointing Stripe Checkout's
// success/cancel redirect at an arbitrary URL (open-redirect-via-Stripe /
// phishing risk) by requiring it to start with one of our own origins.
export function isAllowedRedirectUrl(url: string): boolean {
  return ALLOWED_ORIGINS.some((origin) => url === origin || url.startsWith(`${origin}/`));
}
