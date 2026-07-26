# Stripe + Cloudflare Worker — Step-by-Step Setup Guide

**Feature:** Stripe Payment Integration via Cloudflare Worker
**GitHub Issue:** [#515](https://github.com/justbuildstuff-dev/Fitness-App/issues/515)
**Related:** [Stripe_Cloudflare_Worker_Technical_Design.md](Stripe_Cloudflare_Worker_Technical_Design.md) · [StripeCheckoutTestPlan.md](../Testing/StripeCheckoutTestPlan.md)

This is a manual, one-time setup — nothing here can be automated by an agent (it requires your Stripe/Cloudflare/Google accounts and dashboard access). Do it once in **Test mode** to validate the flow end-to-end for free, then repeat the Stripe-specific steps in **Live mode** when ready to accept real payments.

**Recommended order:** Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8, in that order — several steps depend on values produced by an earlier one (called out in each phase).

---

## Phase 0 — Prerequisites

- A Cloudflare account (free tier is fine) — [dash.cloudflare.com](https://dash.cloudflare.com)
- A Stripe account, with Test mode available immediately and Live mode activated (Stripe requires business details before Live mode works) — [dashboard.stripe.com](https://dashboard.stripe.com)
- Node.js installed locally
- Access to the `fitness-app-8505e` Firebase/Google Cloud project as an Owner or IAM Admin

**Install the CLIs globally** (not into `cloudflare-worker/node_modules`) — this sidesteps the Google-Drive-sync `npm install` failures noted in `CLAUDE.local.md`, since global packages install outside this synced folder:

```powershell
npm install -g wrangler
npm install -g stripe   # optional — only needed for the local Stripe CLI test pass in Phase 8 / StripeCheckoutTestPlan.md §2
```

Verify:
```powershell
wrangler --version
```

---

## Phase 1 — Deploy the Worker (bare, to get its URL)

Stripe's webhook registration (Phase 3) needs the Worker's URL to exist, so this goes first even though the Worker won't function until secrets are added in Phase 6.

```powershell
cd "cloudflare-worker"
wrangler login
```
This opens a browser tab — authorize Wrangler against your Cloudflare account, then return to the terminal.

```powershell
wrangler deploy
```

The output ends with a line like:
```
Published fittrack-stripe-worker (x.xx sec)
  https://fittrack-stripe-worker.<your-account-subdomain>.workers.dev
```

**Copy that URL** — call it `<WORKER_URL>` for the rest of this guide. You'll use it in Phases 3, 6, and 7.

> If `wrangler deploy` fails on dependency install, run `npm install -g wrangler` (Phase 0) rather than relying on the local `node_modules` inside this Google-Drive-synced folder.

---

## Phase 2 — Create the Stripe Prices

No dependency on Cloudflare — can be done in parallel with Phase 1 if you prefer.

In the Stripe Dashboard, use the **Test mode / Live mode** toggle (top-right) to pick which mode you're setting up. Do this whole guide in Test mode first.

1. Go to **Product catalog** → **+ Add product**.
2. **Product 1 — Monthly:**
   - Name: `Overload Pro — Monthly`
   - Pricing model: Standard pricing, Recurring
   - Price: `$6.99`, Billing period: Monthly
   - Save.
3. **Product 2 — Annual:**
   - Name: `Overload Pro — Annual`
   - Pricing model: Standard pricing, Recurring
   - Price: `$49.99`, Billing period: Yearly
   - Save.
4. For each product, click into it and copy the **Price ID** (starts with `price_...`, shown under the pricing table — not the Product ID, which starts with `prod_`).

Record:
- `<PRICE_ID_MONTHLY>` = `price_...`
- `<PRICE_ID_ANNUAL>` = `price_...`

---

## Phase 3 — Register the Stripe webhook endpoint

Needs `<WORKER_URL>` from Phase 1.

1. Stripe Dashboard → **Developers** → **Webhooks** → **+ Add endpoint**.
2. Endpoint URL: `<WORKER_URL>/stripe-webhook` (e.g. `https://fittrack-stripe-worker.you.workers.dev/stripe-webhook`)
3. **Select events to listen to** → add exactly these three:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
4. Save. On the endpoint's detail page, click **Reveal** under **Signing secret**.

Record:
- `<WEBHOOK_SECRET>` = `whsec_...`

---

## Phase 4 — Get your Stripe secret key

1. Stripe Dashboard → **Developers** → **API keys**.
2. Copy the **Secret key** (click "Reveal" if hidden). In Test mode this starts with `sk_test_...`; in Live mode, `sk_live_...`.

Record:
- `<STRIPE_SECRET_KEY>` = `sk_test_...` or `sk_live_...`

**Never** paste this into a file that gets committed — it only ever goes into a Cloudflare secret (Phase 6).

---

## Phase 5 — Create a scoped Firebase service account

The Worker needs to write to Firestore without going through security rules (same as any Admin SDK use). **Don't reuse the default `firebase-adminsdk` service account** — it typically has a broad `Editor` role on the whole project. Create a new, narrowly-scoped one instead, per the Technical Design's security notes.

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → select project `fitness-app-8505e`.
2. **IAM & Admin** → **Service Accounts** → **+ Create Service Account**.
3. Name: `stripe-worker` (or similar). Create.
4. **Grant this service account access to the project** → role: **Cloud Datastore User** (`roles/datastore.user`). Do **not** grant Editor/Owner. Continue → Done.
5. Back in the Service Accounts list, click the new account → **Keys** tab → **Add Key** → **Create new key** → **JSON**. This downloads a `.json` file.

That file's full contents (as a single string) is what goes into the `FIREBASE_SERVICE_ACCOUNT_JSON` secret in Phase 6. Keep the downloaded file out of the repo — delete it from your Downloads folder once it's in the Cloudflare secret, or store it in a password manager if you want a backup.

---

## Phase 6 — Set the Cloudflare Worker secrets

From `cloudflare-worker/`, each command prompts for a value (paste it and press Enter — it won't echo back):

```powershell
wrangler secret put STRIPE_SECRET_KEY
# paste <STRIPE_SECRET_KEY> from Phase 4

wrangler secret put STRIPE_WEBHOOK_SECRET
# paste <WEBHOOK_SECRET> from Phase 3

wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON
# paste the ENTIRE contents of the JSON file from Phase 5, as one line
```

For the JSON secret, the easiest way to get it onto your clipboard as a single line in PowerShell:
```powershell
Get-Content "path\to\your-service-account-key.json" -Raw | Set-Clipboard
```
then paste into the `wrangler secret put` prompt.

Secrets take effect immediately on the already-deployed Worker — no redeploy needed for this step.

---

## Phase 7 — Set the price ID vars and redeploy

Unlike secrets, values in `wrangler.toml`'s `[vars]` are baked in at deploy time, so a redeploy is required after editing.

1. Open `cloudflare-worker/wrangler.toml`.
2. Replace the placeholders:
   ```toml
   STRIPE_PRICE_ID_MONTHLY = "price_..."   # <PRICE_ID_MONTHLY> from Phase 2
   STRIPE_PRICE_ID_ANNUAL = "price_..."    # <PRICE_ID_ANNUAL> from Phase 2
   ```
3. Redeploy:
   ```powershell
   wrangler deploy
   ```

The Worker now rejects any `priceId` other than these two — this is the server-side allow-list added during the pre-merge security review.

---

## Phase 8 — Update the Flutter app to match

Edit `fittrack/lib/services/subscription_service.dart`:

```dart
static const String monthlyPriceId = 'price_...';   // same <PRICE_ID_MONTHLY> as Phase 7
static const String annualPriceId = 'price_...';    // same <PRICE_ID_ANNUAL> as Phase 7
static const String _workerBaseUrl = 'https://fittrack-stripe-worker.you.workers.dev'; // <WORKER_URL> from Phase 1, no trailing slash
```

**These three values must exactly match what's in `wrangler.toml` / what Stripe generated** — a mismatched price ID gets rejected by the Worker's new allow-list (400 "Unknown priceId"); a wrong Worker URL means the app can't reach the Worker at all.

Commit this change through the normal PR flow (not a direct push to `main`).

---

## Phase 9 — Configure the Stripe Customer Portal

Independent of the above — do whenever.

1. Stripe Dashboard → **Settings** → **Billing** → **Customer portal**.
2. Fill in business info (name, support email/URL) — required before the portal can go live.
3. Under **Functionality**, enable at minimum: cancel subscriptions, update payment method.
4. Set the **Default return URL** to your web app, e.g. `https://overload-workouts.web.app`.
5. Save.

`SubscriptionService.stripePortalUrl` in the Flutter app is a plain constant pointing at your portal's shareable link (Settings → Billing → Customer portal → the link at the top) — update it there too if it's still a placeholder.

---

## Phase 10 — Validate before going live

Don't skip this — follow [StripeCheckoutTestPlan.md](../Testing/StripeCheckoutTestPlan.md) sections 2 and 3 (local Stripe CLI pass, then full manual E2E pass) using this guide's **Test mode** values. Only once that passes cleanly should you repeat Phases 2–7 with **Live mode** Stripe values (new live Price IDs, live webhook endpoint + secret, live secret key — Test and Live are entirely separate object graphs in Stripe, nothing carries over automatically).

---

## Quick reference — what depends on what

| Step | Needs |
|---|---|
| Phase 1 (deploy bare Worker) | Nothing |
| Phase 2 (create Prices) | Nothing |
| Phase 3 (register webhook) | `<WORKER_URL>` from Phase 1 |
| Phase 4 (get secret key) | Nothing |
| Phase 5 (service account) | Nothing |
| Phase 6 (set Cloudflare secrets) | Phases 3, 4, 5 |
| Phase 7 (set price vars, redeploy) | Phase 2 |
| Phase 8 (update Flutter constants) | Phases 1, 2 |
| Phase 9 (Customer Portal) | Nothing |
| Phase 10 (validate) | Everything above |
