// Cloudflare Worker environment bindings.
// Secrets are set via `wrangler secret put` — never committed.
interface Env {
  FIREBASE_PROJECT_ID: string;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  FIREBASE_SERVICE_ACCOUNT_JSON: string;
}
