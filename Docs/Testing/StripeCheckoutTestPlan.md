# Stripe Checkout / Cloudflare Worker — Test Plan

**Feature:** Stripe Payment Integration via Cloudflare Worker
**GitHub Issue:** [#515](https://github.com/justbuildstuff-dev/Fitness-App/issues/515)
**Related:** [Stripe_Cloudflare_Worker_Technical_Design.md](../Technical_Designs/Stripe_Cloudflare_Worker_Technical_Design.md)

This covers the payment flow end to end: Worker unit tests, local Stripe CLI testing, a Stripe **test mode** manual pass, and the security regressions to check before this goes live with **real money**. Run test mode passes before every change to `cloudflare-worker/**` or the checkout/webhook/subscription code paths; run the live-mode smoke test once, right after the first production deploy.

---

## 1. Automated tests (run first, catches regressions cheaply)

### 1a. Cloudflare Worker (`cloudflare-worker/`)

Runs automatically in CI on any PR touching `cloudflare-worker/**` (`.github/workflows/cloudflare_worker_tests.yml`). To run locally:

```bash
cd cloudflare-worker
npm install
npm test
npx tsc --noEmit
```

Covers:
- `checkout.test.ts` — missing/malformed/expired ID token (401), uid/token mismatch (403), unknown `priceId` (400), non-allow-listed `successUrl`/`cancelUrl` (400), missing fields (400), happy path params sent to Stripe, Stripe error passthrough (502), CORS origin allow-list.
- `webhook.test.ts` — invalid/missing signature (400), **expired signature timestamp / replay (400)**, each event type writes the correct Firestore fields, idempotent replay, 500 on Firestore write failure (triggers Stripe retry).

> This repo lives on a Google-Drive-synced path, and `npm install` there is known to fail with `EPERM`/`ENOTEMPTY` (same class of issue as the Flutter permission problems noted in `CLAUDE.local.md`). If that happens, rely on the GitHub Actions run on the PR rather than fighting the local install.

### 1b. Flutter (`fittrack/`)

Per `CLAUDE.local.md`, don't run Flutter tests locally on this machine — use the GitHub Actions PR checks (`fittrack_test_suite.yml`).

Relevant suites:
- `test/services/subscription_service_test.dart` — checkout POST body/headers, ID token attached, throws when unauthenticated, throws on non-200.
- `test/widgets/checkout_success_banner_test.dart` — banner show/dismiss logic.
- `test/screens/subscription/paywall_screen_test.dart` — pricing/copy, and the web-only notice vs. plan cards split (`isWeb: true`/`false`).

---

## 2. Local end-to-end test with Stripe CLI (before deploying to Cloudflare)

Requires the [Stripe CLI](https://stripe.com/docs/stripe-cli) and a Stripe account in **test mode**.

```bash
# Terminal 1 — run the Worker locally
cd cloudflare-worker
wrangler dev

# Terminal 2 — forward Stripe webhook events to the local Worker
stripe listen --forward-to localhost:8787/stripe-webhook
# This prints a webhook signing secret (whsec_...) — put it in cloudflare-worker/.dev.vars
# as STRIPE_WEBHOOK_SECRET for this local session (never commit .dev.vars).
```

`.dev.vars` (local only, gitignored) needs test-mode values for all of: `STRIPE_SECRET_KEY` (`sk_test_...`), `STRIPE_WEBHOOK_SECRET` (from `stripe listen`), `FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_PROJECT_ID`, `STRIPE_PRICE_ID_MONTHLY`, `STRIPE_PRICE_ID_ANNUAL` (test-mode price IDs — see checklist below).

Checks:
1. `stripe trigger checkout.session.completed` → Worker log shows a 200 and a Firestore write (point `FIREBASE_PROJECT_ID` at a real or emulated project you can inspect).
2. `stripe trigger customer.subscription.updated` / `customer.subscription.deleted` → same.
3. Manually POST to `/create-checkout-session` with `curl` and **no** `Authorization` header → expect 401.
4. Same request with a garbage Bearer token → expect 401.
5. Same request with a valid ID token but a `uid` that doesn't match the token → expect 403.
6. Same request with a `priceId` that isn't `STRIPE_PRICE_ID_MONTHLY`/`_ANNUAL` → expect 400.
7. Same request with `successUrl`/`cancelUrl` pointing off-origin (e.g. `https://evil.example.com`) → expect 400.
8. Replay the same signed webhook body twice within a minute → single Firestore doc, no duplicate.
9. Replay a captured webhook body+signature with the CLI after modifying the timestamp to >5 minutes old → expect 400 ("Invalid signature").

---

## 3. Manual end-to-end test on a beta build (Stripe test mode)

Do this against a deployed Worker using **test-mode** Stripe keys and a **test** webhook endpoint (separate from the live one) before ever touching live keys.

**Setup:**
- Worker deployed with test-mode secrets (`sk_test_...`, test `whsec_...`, test price IDs)
- Flutter web build pointed at that Worker (`_workerBaseUrl`) — or a build flavor / local override, so this doesn't touch the production Worker

**Steps:**
1. Sign in as a real (non-`isProOverride`) test user on the web build. Confirm the paywall shows the plan cards (web) — and separately, confirm a native iOS/Android build shows the "subscribing is available on the web app" notice instead, not the plan cards.
2. Tap **Annual**. Confirm redirect to Stripe's hosted Checkout, pre-filled with the correct price/currency.
3. Pay with a [Stripe test card](https://stripe.com/docs/testing) (`4242 4242 4242 4242`, any future expiry/CVC).
4. Confirm redirect back to `?checkout=success` and the "Welcome to Overload Pro!" banner appears once.
5. Within 30 seconds, confirm `customers/{uid}/subscriptions` in Firestore has a doc with `status: active`, correct `items[0].price.id`, and `current_period_end`.
6. Confirm `SubscriptionProvider.isPro` flips to `true` and feature gates (program limit, analytics, custom exercises) lift without restarting the app.
7. Refresh the page with `?checkout=success` still in the URL — banner reappears (documented as accepted behavior, not a bug).
8. Start a **second** checkout, click **Cancel** on the Stripe page. Confirm return to `?checkout=cancelled`, no banner, no new Firestore doc.
9. From the Subscription screen, tap **Manage subscription** → confirms Stripe Customer Portal opens. Cancel the subscription there.
10. Confirm `customer.subscription.deleted` fires, Firestore doc updates to `status: canceled`, `isPro` flips to `false`, feature gates re-engage, and existing programs/exercises/sets are untouched.
11. Confirm a user with `isProOverride: true` (dev/beta access) is unaffected by any of the above — override still grants Pro regardless of real subscription state.

---

## 4. Security regression checklist (re-run after any change to `cloudflare-worker/src/**`)

- [ ] `/create-checkout-session` without `Authorization` → 401
- [ ] `/create-checkout-session` with a token for user A but `uid` for user B in the body → 403
- [ ] `/create-checkout-session` with an unpublished `priceId` → 400
- [ ] `/create-checkout-session` with `successUrl`/`cancelUrl` off the allow-listed origins → 400
- [ ] `/create-checkout-session` preflight (`OPTIONS`) from a non-allow-listed `Origin` → no `Access-Control-Allow-Origin` header
- [ ] `/stripe-webhook` with an invalid signature → 400, no Firestore write
- [ ] `/stripe-webhook` with a valid signature but timestamp >5 minutes old → 400, no Firestore write
- [ ] No secret values (`sk_live_...`, `whsec_...`, service account private key) appear anywhere in `cloudflare-worker/**` source, `wrangler.toml`, or git history
- [ ] Native (non-web) build never shows a Stripe Checkout link

---

## 5. Production smoke test (once, after first live deploy)

Use a real card for a small-value real charge (the Monthly plan), or a [Stripe live-mode test clock / free trial coupon if configured], then immediately cancel via the Customer Portal to avoid ongoing billing. Confirm the same checks as section 3, steps 2–10, against the **live** Worker and **live** Stripe webhook. Watch the Cloudflare Worker logs (`wrangler tail`) and the Stripe Dashboard's webhook delivery log during this pass.
