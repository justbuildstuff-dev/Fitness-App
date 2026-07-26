// Cloudflare Worker environment bindings.
// Secrets are set via `wrangler secret put` — never committed.
interface Env {
  FIREBASE_PROJECT_ID: string;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  FIREBASE_SERVICE_ACCOUNT_JSON: string;
  // Not secret — plain [vars] in wrangler.toml. Server-side allow-list for
  // /create-checkout-session so an authenticated caller can't check out an
  // arbitrary Stripe price.
  STRIPE_PRICE_ID_MONTHLY: string;
  STRIPE_PRICE_ID_ANNUAL: string;
}
