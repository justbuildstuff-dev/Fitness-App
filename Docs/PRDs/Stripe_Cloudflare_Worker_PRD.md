# PRD: Stripe Payment Integration via Cloudflare Worker

**Status:** Requirements Complete
**Priority:** High
**Platform:** Web (PWA)
**GitHub Issue:** [#515](https://github.com/justbuildstuff-dev/Fitness-App/issues/515)
**Author:** BA Agent
**Date:** 2026-07-10

---

## Problem Statement

Overload Pro's paywall is built but non-functional. The existing checkout flow depends on the Firebase Stripe Extension, which requires the Firebase Blaze (pay-as-you-go) plan. Upgrading introduces unbounded GCP billing risk.

This feature replaces the Firebase Extension dependency with a Cloudflare Worker — a permanently-free serverless function that handles Stripe Checkout session creation and webhook fulfilment, writing subscription status directly to Firestore via the Admin REST API.

---

## Goals

- Make Pro subscriptions purchasable on the web PWA
- Eliminate the Firebase Blaze plan requirement
- Keep the Flutter app changes minimal (primarily a service layer swap)
- Update pricing to reflect market positioning

---

## Out of Scope

- iOS App Store IAP and Android Play Billing (future feature)
- Lifetime plan (future feature)
- Free trials (deferred — can be reintroduced as a growth lever later)
- Info site / marketing page pricing update (separate task — note for SA to flag as a dependency)
- Stripe Customer Portal configuration (manual one-time setup, not a code task)

---

## Pricing

| Plan | Price | Saving vs monthly | Notes |
|------|-------|-------------------|-------|
| Monthly | $6.99/month | — | No change |
| Annual | $49.99/year | ~40% | Updated from $39.99 |

Free trial copy ("14-day free trial") must be removed from the paywall UI.

---

## Architecture Overview

```
User taps plan in PaywallScreen
  → SubscriptionService calls Cloudflare Worker POST /create-checkout-session
  → Worker creates Stripe Checkout Session via Stripe API
  → Worker returns { url }
  → App opens url via url_launcher (LaunchMode.externalApplication)
  → User completes payment on Stripe hosted page
  → Stripe fires webhook → Worker POST /stripe-webhook
      → verifies Stripe-Signature header
      → handles checkout.session.completed → writes subscription doc to Firestore
      → handles customer.subscription.updated → updates subscription doc
      → handles customer.subscription.deleted → marks subscription cancelled
  → SubscriptionProvider real-time listener picks up Firestore change
  → User lands back on app with ?checkout=success in URL
  → App detects param → shows "Welcome to Pro" banner
```

---

## User Stories

### US-1: Purchase a subscription

**As a free user**, I want to tap a plan on the paywall and be taken directly to a Stripe payment page, so that I can subscribe to Overload Pro without leaving the app ecosystem.

**Acceptance Criteria:**
- Tapping Monthly or Annual on the paywall opens the Stripe hosted Checkout page in the browser
- The Checkout page is pre-populated with the correct plan price and currency
- Tapping "Cancel" on the Stripe page returns the user to the app (cancel URL)
- The checkout flow works on both mobile and desktop web browsers
- No Firebase Extension or Blaze plan is required for checkout to function

### US-2: Pro access activates after payment

**As a user who has just paid**, I want my Pro features to unlock automatically, so that I do not have to sign out and back in or manually refresh.

**Acceptance Criteria:**
- Within 30 seconds of payment completing, `SubscriptionProvider.isPro` returns `true` for the user
- The real-time Firestore listener (`customers/{uid}/subscriptions`) fires when the Worker writes the subscription document
- Feature gates (program limit, analytics, custom exercises) lift without any user action
- If the Firestore write is delayed, the UI does not show an error — it waits silently for the listener to fire

### US-3: Welcome confirmation on return

**As a user returning to the app after payment**, I want to see a clear confirmation that my subscription is active, so that I know the purchase worked and I don't pay twice.

**Acceptance Criteria:**
- When the app loads with `?checkout=success` in the URL, a "Welcome to Pro" banner or dialog is displayed
- The banner is shown once per successful checkout (not on every subsequent app load)
- The banner is dismissible
- The banner is not shown when `?checkout=cancelled` is in the URL

### US-4: Manage or cancel subscription

**As an active Pro subscriber**, I want to tap a button in the app to manage my subscription, so that I can change my plan or cancel without contacting support.

**Acceptance Criteria:**
- The "Manage subscription" button in the Subscription screen opens the Stripe Customer Portal in the browser
- The button is only shown to users with an active subscription (not `isProOverride` admin users)
- The Stripe Customer Portal URL is configurable without a code change (stored as a constant, not hardcoded in logic)
- After cancelling in the Portal and returning, the subscription status updates automatically via the real-time listener

### US-5: Subscription expiry revokes Pro access

**As the system**, I want Pro access to be revoked automatically when a subscription is cancelled or expires, so that users who cancel do not continue to access paid features.

**Acceptance Criteria:**
- When Stripe fires `customer.subscription.deleted`, the Worker updates the Firestore subscription document with `status: 'canceled'`
- `SubscriptionProvider.isPro` returns `false` once the Firestore update is received by the real-time listener
- Feature gates re-engage immediately — the user is downgraded to free tier limits
- Existing data (programs, exercises, sets) is not deleted on downgrade

### US-6: Webhook security

**As the system**, I want all Stripe webhook calls to be cryptographically verified, so that malicious actors cannot fake payment events to grant themselves Pro access.

**Acceptance Criteria:**
- The Cloudflare Worker verifies the `Stripe-Signature` header on every webhook request using the webhook signing secret
- Requests with an invalid or missing signature return HTTP 400 and are not processed
- The webhook signing secret is stored as a Cloudflare Worker secret (environment variable), never in source code
- The Firebase service account key used to write to Firestore is also stored as a Cloudflare Worker secret

---

## Non-Functional Requirements

- **Latency:** Checkout session URL returned within 3 seconds under normal conditions
- **Webhook reliability:** Worker returns HTTP 200 within 5 seconds (Stripe retries on non-200)
- **Idempotency:** Processing the same webhook event twice must not create duplicate subscription documents
- **No Blaze plan:** The solution must function entirely on the Firebase Spark (free) plan — no Cloud Functions, no Firebase Extensions
- **Security:** No secrets committed to the repository; all credentials stored as Cloudflare Worker secrets

---

## Existing Code to Modify

| File | Change |
|------|--------|
| `lib/services/subscription_service.dart` | Replace `createCheckoutSession()` (currently writes to Firestore and polls) with HTTP POST to Cloudflare Worker endpoint; remove `lifetimePriceId` |
| `lib/screens/subscription/paywall_screen.dart` | Remove Lifetime plan card; remove trial copy ("14-day free trial"); update annual price to $49.99 |
| `fittrack/firestore.rules` | Review `customers/{userId}/checkout_sessions` rules — the Worker does not use this subcollection; keep or clean up |

## New Code

| Artifact | Description |
|----------|-------------|
| `cloudflare-worker/src/index.ts` | Worker with two routes: `POST /create-checkout-session` and `POST /stripe-webhook` |
| `cloudflare-worker/package.json` | Wrangler + Stripe SDK dependencies |
| `cloudflare-worker/wrangler.toml` | Worker name, routes, compatibility date |
| `lib/main.dart` or router | Detect `?checkout=success` on startup and trigger welcome banner |

---

## Dependencies

- Stripe account with two products created (Monthly $6.99, Annual $49.99) and price IDs recorded
- Stripe webhook endpoint registered pointing to the deployed Cloudflare Worker URL
- Firebase service account key (JSON) generated and stored as Cloudflare Worker secret
- Stripe Customer Portal configured in the Stripe Dashboard with the correct return URL
- **`fittrack/public/index.html`** — the PWA landing/info page pricing has already been updated by the developer. The Deployment Agent should redeploy Firebase Hosting as part of this feature's release (`firebase deploy --only hosting`).
