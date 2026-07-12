# Technical Design: Stripe Payment Integration via Cloudflare Worker

**Feature:** Stripe Payment Integration via Cloudflare Worker
**GitHub Issue:** [#515](https://github.com/justbuildstuff-dev/Fitness-App/issues/515)
**PRD:** [Docs/PRDs/Stripe_Cloudflare_Worker_PRD.md](../PRDs/Stripe_Cloudflare_Worker_PRD.md)
**Author:** SA Agent
**Date:** 2026-07-10
**Status:** Design Approved

---

## Current Architecture Analysis

**State Management:** Provider pattern (`ChangeNotifier` + `ChangeNotifierProxyProvider`). `SubscriptionProvider` is a `ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>` registered in `main.dart`. Services are singletons (`SubscriptionService.instance`).

**File Structure Discovered:**
- `lib/services/` — singleton services (e.g. `SubscriptionService`, `FirestoreService`)
- `lib/providers/` — ChangeNotifier providers
- `lib/screens/subscription/` — `paywall_screen.dart`, `subscription_management_screen.dart`
- `lib/widgets/` — reusable widgets (e.g. `returning_user_banner.dart` — banner pattern reference)

**Similar Feature (Banner Pattern):** `lib/widgets/returning_user_banner.dart` — `StatefulWidget` with `_dismissed` bool, static service check, `SizedBox.shrink()` when inactive, `Card` with `primaryContainer` colour. `CheckoutSuccessBanner` follows this exactly.

**URL Param Detection:** No routing library (direct `Navigator.push` only). `Uri.base.queryParameters` is available from `dart:core` on Flutter web — no `dart:html` import needed. Read in widget's `initState` or as a static pre-computed flag.

**HTTP package:** `http: ^1.1.0` is currently in `dev_dependencies` only. It must be moved to `dependencies` for the refactored `SubscriptionService` to use it in production.

**Firestore Customers Rules:** `customers/{userId}/checkout_sessions` currently allows client read/write (used by the Firebase Extension to receive the checkout URL). This subcollection is unused in the new flow — the Worker creates sessions directly via the Stripe API. The rule will be updated to remove write access and add a legacy comment.

**Testing Approach:** Unit tests use `mockito` (`.mocks.dart` generated files). Widget tests use `flutter_test`. The `SubscriptionService` should expose the Worker base URL as a configurable constant (or injectable for tests).

---

## Architecture Overview

The Firebase Stripe Extension is replaced entirely by a Cloudflare Worker. The Worker handles two concerns:

1. **Checkout session creation** — the Flutter app POSTs to the Worker with the user's UID and price ID; the Worker calls the Stripe API and returns the hosted Checkout URL directly. No Firestore writes involved in this path.

2. **Webhook fulfilment** — Stripe fires webhook events to the Worker; the Worker verifies the `Stripe-Signature` header, then writes subscription documents directly to Firestore via the Firebase Admin REST API using a service account JWT. Security rules are bypassed (as with any Admin SDK call).

The existing `SubscriptionProvider` real-time listener on `customers/{uid}/subscriptions` is unchanged — it picks up documents written by the Worker automatically.

```
┌─────────────────────────┐
│   Flutter Web (PWA)      │
│                          │
│  PaywallScreen           │
│    → SubscriptionService │
│       .createCheckout()  │──── POST /create-checkout-session ──▶ Cloudflare Worker
│                          │◀─── { url: "https://checkout.stripe..." } ──────────────┘
│    url_launcher opens    │
│    Stripe Checkout page  │
└─────────────────────────┘
                                   Stripe fires webhook
                                       │
                          POST /stripe-webhook ──▶ Cloudflare Worker
                                                        │ verify Stripe-Signature
                                                        │ build Firestore Admin JWT
                                                        ▼
                                              Firestore REST API
                                          customers/{uid}/subscriptions/{subId}
                                                        │
                                   SubscriptionProvider listener fires
                                          │
                              Flutter app isPro = true
```

---

## Component Design

### New: Cloudflare Worker (`cloudflare-worker/`)

A standalone TypeScript project using Wrangler. Lives outside `fittrack/` at the repo root.

```
cloudflare-worker/
├── src/
│   ├── index.ts          # Entry: routes requests to handlers
│   ├── checkout.ts       # POST /create-checkout-session handler
│   ├── webhook.ts        # POST /stripe-webhook handler
│   └── firestore.ts      # Firestore Admin REST API helper (JWT + PATCH)
├── wrangler.toml
├── package.json
└── tsconfig.json
```

**Environment variables (Cloudflare secrets — never committed):**
| Secret | Description |
|--------|-------------|
| `STRIPE_SECRET_KEY` | Stripe secret key (`sk_live_...`) |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret (`whsec_...`) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Full service account JSON as a string |

**`src/checkout.ts`** — `POST /create-checkout-session`

Input (JSON body):
```json
{ "uid": "firebase-auth-uid", "priceId": "price_xxx", "successUrl": "...", "cancelUrl": "..." }
```

Steps:
1. Validate required fields present
2. Call Stripe API: `POST https://api.stripe.com/v1/checkout/sessions` with `mode: subscription`, `client_reference_id: uid`, `line_items: [{ price: priceId, quantity: 1 }]`, `success_url`, `cancel_url`
3. Return `{ url: session.url }`

CORS headers: `Access-Control-Allow-Origin: *` (Stripe Checkout opens in a separate tab; the POST itself comes from the Flutter app's origin)

**`src/webhook.ts`** — `POST /stripe-webhook`

Steps:
1. Read raw request body (required for Stripe signature verification)
2. Verify `Stripe-Signature` header using `STRIPE_WEBHOOK_SECRET` — return 400 on failure
3. Route by `event.type`:
   - `checkout.session.completed`: extract `client_reference_id` (uid), look up subscription ID via Stripe API, write subscription doc
   - `customer.subscription.updated`: update subscription doc
   - `customer.subscription.deleted`: write `status: 'canceled'` to subscription doc
4. Return HTTP 200 immediately (Stripe retries on non-200)

Idempotency: the Stripe subscription ID is used as the Firestore document ID. Firestore PATCH (merge) is naturally idempotent — replaying the same event produces the same document state.

**`src/firestore.ts`** — Firestore Admin REST API helper

The Worker calls Firestore's REST endpoint using a service account JWT — this bypasses Firestore security rules (same behaviour as the Admin SDK).

JWT flow:
1. Parse `FIREBASE_SERVICE_ACCOUNT_JSON` → extract `private_key` (PEM), `client_email`
2. Build JWT payload: `{ iss: client_email, sub: client_email, aud: 'https://oauth2.googleapis.com/token', scope: 'https://www.googleapis.com/auth/datastore', iat, exp: iat+3600 }`
3. Sign with `crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, headerPayload)` (Workers have full `crypto.subtle` support)
4. Exchange JWT for access token: `POST https://oauth2.googleapis.com/token`
5. PATCH to `https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/customers/{uid}/subscriptions/{subscriptionId}`

**Subscription document shape** (what the Worker writes, in Firestore REST API format):
```json
{
  "fields": {
    "status":              { "stringValue": "active" },
    "items":               { "arrayValue": { "values": [
                               { "mapValue": { "fields": {
                                   "price": { "mapValue": { "fields": {
                                     "id": { "stringValue": "price_xxx" }
                                   }}}
                               }}}
                             ]}},
    "current_period_end":  { "timestampValue": "2027-07-10T00:00:00Z" }
  }
}
```

When the Flutter `cloud_firestore` SDK reads this document, the typed values are automatically deserialised to Dart types (`String`, `List`, `Timestamp`), matching what `SubscriptionInfo.fromStripeFirestore()` already expects. No Flutter-side changes are needed for subscription reading.

---

### Modified: `lib/services/subscription_service.dart`

Replace the `createCheckoutSession()` Firestore write/poll with a direct HTTP POST to the Worker.

**Key changes:**
- Add `static const String _workerBaseUrl = 'https://[worker-name].[account].workers.dev'` (set during deployment)
- Remove `lifetimePriceId` constant
- Replace `createCheckoutSession()` body: write to `customers/{userId}/checkout_sessions` + poll → `http.post(_workerBaseUrl/create-checkout-session, body: json)` → parse `url` from response
- Keep all other methods unchanged (`subscriptionStream`, `loadFromFirestore`, `openCustomerPortal`)

**Error handling:** If the Worker returns non-200, throw `Exception('Checkout failed: $statusCode')`. `SubscriptionProvider.startCheckout()` already catches and surfaces this as `_error`.

---

### Modified: `pubspec.yaml`

Move `http` from `dev_dependencies` to `dependencies`:
```yaml
dependencies:
  # ...existing...
  http: ^1.1.0   # moved from dev_dependencies
```

---

### Modified: `lib/screens/subscription/paywall_screen.dart`

- Remove the `_PlanCard` for 'Lifetime' (`\$59.99`, one-time)
- Remove `'14-day free trial'` from `detail` fields on Monthly and Annual cards
- Update Annual `price` from `'\$39.99/year'` to `'\$49.99/year'`
- Update Annual `savings` from `'Save 52% vs monthly'` to `'Save 40% vs monthly'`
- Update Annual `detail` from `'Billed annually · 14-day free trial'` to `'Billed annually'`
- Update Monthly `detail` from `'14-day free trial'` to `''` (or remove the field)
- Remove the `onTap` for the Lifetime card and its `startCheckout` call with `lifetimePriceId`

---

### Modified: `lib/screens/profile/profile_screen.dart`

Line 98: Update subtitle from `'Unlock Overload Pro'` / subtext `'\$39.99/year.'` to `'\$49.99/year.'`

---

### New: `lib/widgets/checkout_success_banner.dart`

Follows the `ReturningUserBanner` pattern exactly (`lib/widgets/returning_user_banner.dart`).

```
CheckoutSuccessBanner (StatefulWidget)
  └── _CheckoutSuccessBannerState
        bool _dismissed = false
        build():
          if (_dismissed || !_shouldShow) → SizedBox.shrink()
          else → Card(primaryContainer) with:
            - "Welcome to Overload Pro!" title + workspace_premium icon
            - "Your subscription is now active." body
            - X dismiss button
```

`_shouldShow` is a static bool computed once at app startup in `main.dart`:
```dart
// In main() before runApp(), web only:
final bool _checkoutSuccess = kIsWeb
    ? Uri.base.queryParameters['checkout'] == 'success'
    : false;
```

This is passed into `OverloadApp` and stored on a simple `CheckoutSuccessService` static (mirrors `ReturningUserService.shouldShowPrompt` pattern):
```dart
class CheckoutSuccessService {
  static bool pendingWelcome = false;
  static void dismiss() => pendingWelcome = false;
}
```

Set `CheckoutSuccessService.pendingWelcome = _checkoutSuccess` in `main()` before `runApp()`.

On dismiss, the banner calls `CheckoutSuccessService.dismiss()` + `setState(() => _dismissed = true)`. This is in-memory only — refreshing the page after the first view re-shows the banner if the URL still contains `?checkout=success`. To prevent this, after showing the banner, also call:
```dart
// Cleans URL without a page reload (web only)
if (kIsWeb) {
  // Use dart:html (deprecated) or package:web
  // Or: rely on the in-memory flag being cleared on dismiss
}
```

**Decision:** Do NOT clean the URL programmatically to avoid `dart:html` / `package:web` dependency. The in-memory `pendingWelcome = false` on dismiss is sufficient — once dismissed, it won't re-appear in the same session. A hard refresh re-shows it, which is acceptable (the user paid, seeing "Welcome to Pro" twice is benign).

---

### Modified: `lib/screens/programs/programs_screen.dart`

Add `CheckoutSuccessBanner()` as the first item in the programs list, above `ReturningUserBanner()` (the existing banner).

---

### Modified: `fittrack/firestore.rules`

Update the `checkout_sessions` subcollection comment and remove client write access (no longer used):

```
match /customers/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if false; // Cloudflare Worker writes via service account (Admin REST API)

  // Legacy: was used by Firebase Stripe Extension for checkout session polling.
  // Not used in current Cloudflare Worker flow — retained for historical compatibility.
  match /checkout_sessions/{sessionId} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false; // no longer written by client
  }

  match /subscriptions/{subscriptionId} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false; // Cloudflare Worker writes via service account
  }

  match /payments/{paymentId} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false;
  }
}
```

---

## Implementation Tasks

| # | Task | Files | Effort |
|---|------|-------|--------|
| 516 | Cloudflare Worker: project setup + /create-checkout-session endpoint | `cloudflare-worker/**` (new) | 1.5 days |
| 517 | Cloudflare Worker: /stripe-webhook handler + Firestore write | `cloudflare-worker/src/webhook.ts`, `firestore.ts` | 2 days |
| 518 | Flutter: move http dependency + refactor SubscriptionService | `pubspec.yaml`, `lib/services/subscription_service.dart` | 0.5 days |
| 519 | Flutter: update PaywallScreen + ProfileScreen pricing UI | `lib/screens/subscription/paywall_screen.dart`, `lib/screens/profile/profile_screen.dart` | 0.5 days |
| 520 | Flutter: CheckoutSuccessBanner + ProgramsScreen integration | `lib/widgets/checkout_success_banner.dart` (new), `lib/main.dart`, `lib/screens/programs/programs_screen.dart` | 1 day |
| 521 | Firestore rules: update customers collection comments + remove legacy write access | `fittrack/firestore.rules` | 0.5 days |

**Total estimated effort:** ~6 days

**Dependency order:**
- Task 516 first (Worker foundation — checkout endpoint needed to get Worker URL for Task 518)
- Task 517 after 516 (same Worker project)
- Tasks 518, 519, 520, 521 can be done in parallel after 516 is deployed

---

## Testing Strategy

### Cloudflare Worker (Tasks 516–517)
- Unit tests using Vitest (Wrangler's test harness) or manual testing via `wrangler dev`
- Test `POST /create-checkout-session` with valid/missing fields
- Test `POST /stripe-webhook` with valid and invalid Stripe signatures
- Test idempotency: processing the same webhook event twice produces the same Firestore document
- Use Stripe CLI (`stripe listen --forward-to localhost:8787`) for local webhook testing

### Flutter (Tasks 518–520)
- **Unit:** `SubscriptionService` — mock `http.Client`, assert correct Worker URL + JSON body, assert URL returned correctly
- **Unit:** `CheckoutSuccessService` — assert `pendingWelcome` set correctly based on URL param
- **Widget:** `CheckoutSuccessBanner` — `pendingWelcome = true` → banner visible; dismiss → `SizedBox.shrink()`; `pendingWelcome = false` → `SizedBox.shrink()`
- **Widget:** `PaywallScreen` — assert no Lifetime card, no "free trial" text, correct prices
- Follow existing test patterns: `mockito` for service mocks, `WidgetTester` for widget tests

### Firestore Rules (Task 521)
- Verify `customers/{userId}/checkout_sessions` write blocked for clients
- Verify `customers/{userId}/subscriptions` read allowed for owner

---

## Deployment Notes

1. **Manual setup required before implementation can be tested end-to-end:**
   - Create Stripe products: Monthly ($6.99) and Annual ($49.99) — note the Price IDs
   - Create Cloudflare Worker (`wrangler deploy`) and note the Worker URL
   - Register Stripe webhook endpoint pointing to `https://[worker].workers.dev/stripe-webhook`
   - Store secrets via `wrangler secret put`
   - Configure Stripe Customer Portal return URL in Stripe Dashboard
   - Update `_workerBaseUrl` and `monthlyPriceId`/`annualPriceId` constants in `SubscriptionService`

2. **Firebase Hosting:** `firebase deploy --only hosting` — `fittrack/public/index.html` already updated; redeploy as part of this release.

3. **No Firebase Blaze plan required.** The Firebase Spark plan is sufficient.

---

## Security Notes

- Stripe webhook signature verification is mandatory — without it, any HTTP client could forge a `checkout.session.completed` event and grant Pro access to arbitrary users
- Service account JSON must never be committed — store in Cloudflare Worker secrets only
- The service account should be scoped to Firestore only (`roles/datastore.user`) — not a project owner
- The Worker's `POST /create-checkout-session` endpoint does not require auth (Stripe Checkout handles payment auth). CORS is restricted to the app's production domain in the Worker config (not `*`)

---

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Worker cold-start latency on first request | Low | Workers typically < 5ms cold start; acceptable |
| Stripe webhook delivery delay | Low | Stripe retries for 3 days; real-time listener shows Pro once doc is written |
| JWT expiry mid-webhook | Low | Tokens are generated per-request with 1hr expiry; not reused |
| `client_reference_id` missing on session | Low | Worker validates field presence before writing to Firestore; Stripe returns it on all checkout events |
| Checkout success URL reloads banner on refresh | Accepted | In-memory flag cleared on dismiss; re-show on refresh is benign (user paid, Welcome to Pro is harmless) |
