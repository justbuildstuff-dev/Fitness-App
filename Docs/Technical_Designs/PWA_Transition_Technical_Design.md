# PWA Transition — Technical Design

**Status:** Approved
**GitHub Issue:** #478
**PRD:** [Docs/PRDs/PWA_Transition_PRD.md](../PRDs/PWA_Transition_PRD.md)
**Created:** 2026-06-14

---

## 1. Current Architecture Analysis

### State Management
Provider pattern throughout (`provider ^6.1.1`). All providers are `ChangeNotifier` subclasses registered in `main.dart` via `MultiProvider`. Auth-dependent providers use `ChangeNotifierProxyProvider`. This pattern is unchanged by the PWA pivot.

### File Structure
```
fittrack/lib/
  main.dart                    — Firebase init, service init, runApp
  providers/                   — ChangeNotifier state
  services/                    — Singletons with .instance getter + forTest constructors
  screens/                     — Screen widgets, grouped by feature
  models/                      — Data models + Firestore serialisation
  widgets/                     — Shared UI components
  converters/                  — Firestore ↔ model converters
```

### Services Pattern
All services use a `static final instance` singleton. Test constructors (`forTest()`) accept injected dependencies (Firestore, SharedPreferences, etc.). This pattern is maintained in rewrites.

### Existing Web Readiness
`fittrack/web/` exists with PWA manifest, icons, and Flutter bootstrap. The manifest currently has stale values (`name: "fittrack"`, `description: "A new Flutter project."`) that need updating. `FirestoreService.enableOfflinePersistence()` is already called in `main.dart` — offline persistence works for web without changes.

### Packages That Break the Web Build
| Package | Used In | Reason Breaks Web |
|---------|---------|-------------------|
| `in_app_purchase ^3.2.0` | `SubscriptionService`, `SubscriptionProvider` | No web implementation |
| `flutter_local_notifications ^19.4.1` | `NotificationService`, `LifecycleNotificationService` | No web implementation |
| `timezone ^0.10.0` | `LifecycleNotificationService` | Used for `tz.TZDateTime` scheduling |
| `in_app_review ^2.0.9` | `AppReviewService` | No web implementation |
| `path_provider ^2.1.2` | pubspec only — not imported anywhere in lib/ | Unused; safe to drop |
| `share_plus ^11.1.0` | pubspec only — not imported anywhere in lib/ | Unused; safe to drop |
| `csv ^6.0.0` | pubspec only — not imported anywhere in lib/ | Unused; safe to drop |

**Key finding:** `path_provider`, `share_plus`, and `csv` are declared in `pubspec.yaml` but have zero import sites in `lib/`. They can be removed with no code changes.

### `dart:io` Usage in Subscription Files
- `subscription_provider.dart:2` — `import 'dart:io'` for `Platform.isIOS` (in `_handlePurchaseUpdates`, which is being removed)
- `subscription_management_screen.dart:1` — `import 'dart:io'` for `Platform.isIOS ? _iosManageUrl : _androidManageUrl` (replaced with a single Stripe Portal URL)

Both `dart:io` imports are removed as part of the Stripe rewrite.

---

## 2. Architecture Overview

The pivot strategy is **targeted removal + minimal replacement**: remove mobile-only package dependencies, stub notification services, rewrite subscription billing to Stripe, update infra config. The core app architecture (Provider, Firestore, Auth, all 38 screens) is untouched.

### What Changes
1. **Packages** — 7 packages removed from `pubspec.yaml` (4 have code, 3 are unused)
2. **Notification services** — stubbed to no-ops; analytics tracking inside `LifecycleNotificationService` preserved
3. **Subscription service + provider** — rewritten to use Firebase Stripe Extension via Firestore
4. **Paywall and management screens** — updated for Stripe Checkout redirect and Customer Portal
5. **Firebase Hosting config** — second site added for PWA
6. **CI pipeline** — Flutter web build + deploy step added
7. **PWA manifest + index.html** — branding updated to "Overload"

### What Stays Identical
- All 38 screens (rendering, navigation, business logic)
- All providers except `SubscriptionProvider`
- `FirestoreService` (offline persistence already enabled)
- `AuthProvider`, `ProgramProvider`, all other providers
- Firebase Auth, Analytics, Crashlytics (all web-compatible)
- `SubscriptionInfo` model and `SubscriptionProvider` gating logic (`isPro`, `maxPrograms`, `maxCustomExercises`)
- `fittrack/android/` and `beta_build.yml` — preserved entirely

---

## 3. Detailed Design

### Task #481 — Remove Mobile-Only Package Dependencies

**Foundation task — must be completed first as it unblocks the web build.**

#### pubspec.yaml changes
Remove from `dependencies`:
```yaml
# Remove these 4:
flutter_local_notifications: ^19.4.1
timezone: ^0.10.0
in_app_purchase: ^3.2.0
in_app_review: ^2.0.9

# Remove these 3 (unused in code):
path_provider: ^2.1.2
share_plus: ^11.1.0
csv: ^6.0.0
```

Keep all others unchanged. `firebase_messaging ^16.0.1` stays — it is web-compatible and still used for FCM token storage in `LifecycleNotificationService`.

#### lib/services/notification_service.dart — Stub
Replace entire file with a no-op stub. The public API (`initialize`, `scheduleWorkoutReminder`, `scheduleRecurringWorkoutReminder`, `showNotification`, `cancelNotification`, `cancelAllNotifications`, `getPendingNotifications`) is preserved so call sites continue to compile, but all methods are no-ops.

Remove the `Day` and `Time` classes (they were internal to the scheduling API). If any call site references them, remove those call sites.

```dart
// Stub: local notification scheduling deferred to FCM web push PRD
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  Future<void> initialize() async {}
  Future<void> scheduleWorkoutReminder({...}) async {}
  Future<void> scheduleRecurringWorkoutReminder({...}) async {}
  Future<void> showNotification({...}) async {}
  Future<void> cancelNotification(int id) async {}
  Future<void> cancelAllNotifications() async {}
  Future<List<Never>> getPendingNotifications() async => [];
}
```

#### lib/services/lifecycle_notification_service.dart — Partial stub
This service has two roles: notification scheduling (remove) and retention analytics tracking (keep). Analytics tracking uses only `SharedPreferences` and `AppAnalyticsService` — both web-compatible.

Remove:
- `flutter_local_notifications` import
- `timezone` import
- `FlutterLocalNotificationsPlugin _localNotifications` field
- `_initLocalNotifications()`, `_scheduleLocalNotification()`, `_scheduleActivationNotifications()`, `_scheduleRetentionNotifications()`, `_showPRNotification()` methods
- `_day1NotifId`, `_day3NotifId`, `_day10NotifId`, `_day30NotifId`, `_prNotifBaseId` constants
- Notification channel ID constants

Keep:
- `FirebaseMessaging` import and `_messaging` field (FCM token storage, web-compatible)
- SharedPreferences tracking keys and state
- `_initFCM()`, `_onFCMTokenRefresh()`, `_onFCMMessageReceived()`
- Analytics logging: `_logRetentionSessions()`, `AppAnalyticsService` calls
- `recordWorkoutLogged()` analytics logic (milestone events)
- `requestPermissionIfEligible()` — keep but just requests FCM permission, no local notifications

Update `recordWorkoutLogged()` to remove the `_localNotifications.cancel(...)` calls (since local notifications are gone). Keep the analytics milestone logic.

Update `onAppLaunch()` to only call `_scheduleRetentionNotifications()` as a no-op stub (or remove it entirely and just call `_logRetentionSessions()`).

#### lib/services/app_review_service.dart — Stub review call
Remove `in_app_review` import and `InAppReview _inAppReview` field.

In `maybeRequestReview()`: keep eligibility check and analytics logging, but replace the actual `_inAppReview.requestReview()` call with a no-op. The service remains structurally intact for future use.

```dart
// In maybeRequestReview():
try {
  await AppAnalyticsService.instance.logReviewPromptTriggered();
  // in_app_review has no web equivalent — review prompt deferred
  await _prefs.setBool(_reviewRequestedKey, true);
} catch (e) {
  _requestedThisSession = false;
}
```

Update `AppReviewService.forTest` constructor to remove the `InAppReview` parameter (breaking change in test constructor — update test files accordingly).

#### lib/main.dart — Remove notification init
The `NotificationService.instance.initialize()` call can stay (it's now a no-op). No changes needed — the stub handles it silently.

---

### Task #479 — Firebase Hosting Multi-Site Configuration

#### Step 1: Create second Firebase Hosting site
Developer action in Firebase Console:
1. Go to Firebase Console → Hosting → Add another site
2. Site ID: `fittrack-app` (produces URL `fittrack-app.web.app`)
3. Note: Firebase Hosting site IDs are globally unique. `app.fitness-app-8505e.web.app` is not a valid Firebase Hosting URL — the actual URL will be `fittrack-app.web.app` (or the chosen site ID). This is the correct PWA launch URL.

#### fittrack/.firebaserc — Add hosting targets
```json
{
  "projects": {
    "default": "fitness-app-8505e"
  },
  "targets": {
    "fitness-app-8505e": {
      "hosting": {
        "marketing": ["fitness-app-8505e"],
        "app": ["fittrack-app"]
      }
    }
  }
}
```

#### fittrack/firebase.json — Convert to array format
Convert `"hosting"` from a single object to an array with two targets:

```json
{
  "functions": [...],
  "hosting": [
    {
      "target": "marketing",
      "public": "public",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "cleanUrls": true,
      "trailingSlash": false,
      "404": "404.html",
      "headers": [
        {
          "source": "**",
          "headers": [
            { "key": "X-Content-Type-Options", "value": "nosniff" },
            { "key": "X-Frame-Options", "value": "DENY" },
            { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
          ]
        }
      ]
    },
    {
      "target": "app",
      "public": "build/web",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        { "source": "**", "destination": "/index.html" }
      ],
      "headers": [
        {
          "source": "**",
          "headers": [
            { "key": "X-Content-Type-Options", "value": "nosniff" },
            { "key": "X-Frame-Options", "value": "DENY" },
            { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
          ]
        },
        {
          "source": "/flutter_service_worker.js",
          "headers": [
            { "key": "Cache-Control", "value": "no-cache" }
          ]
        }
      ]
    }
  ],
  "firestore": {...},
  "emulators": {...}
}
```

**Note on PWA routing:** Flutter web apps are single-page apps. The `"rewrites": [{"source": "**", "destination": "/index.html"}]` rule ensures deep links and page refreshes serve `index.html` rather than 404. The service worker header prevents the service worker from being cached, ensuring PWA updates deploy immediately.

---

### Task #480 — Replace in_app_purchase with Stripe Subscription Billing

**This is the most complex task (~2 weeks). Depends on #481.**

#### Prerequisites (developer actions before coding)
1. Create Stripe account and activate it
2. Install Firebase Stripe Extension in Firebase Console (Extensions → stripe-firestore-stripe-payments)
3. Configure extension:
   - Stripe API key (secret key from Stripe dashboard)
   - Products collection: `customers`
   - Sync new users: Yes
4. Create three Stripe Products in Stripe Dashboard:
   - Monthly: $6.99/month recurring → note Price ID (`price_monthly_xxx`)
   - Annual: $39.99/year recurring → note Price ID (`price_annual_xxx`)
   - Lifetime: $59.99 one-time → note Price ID (`price_lifetime_xxx`)
5. Enable Stripe Customer Portal in Stripe Dashboard (Settings → Billing → Customer Portal)
6. Store Price IDs in Firebase Remote Config (or as constants, updated before launch)
7. Configure Stripe Checkout success/cancel URLs:
   - Success: `https://fittrack-app.web.app/?checkout=success`
   - Cancel: `https://fittrack-app.web.app/?checkout=cancelled`

#### How Firebase Stripe Extension Works
The extension creates a Firestore-based integration:
- Creates `customers/{userId}` document when a user signs up (synced from Firebase Auth)
- To start a checkout session: write to `customers/{userId}/checkout_sessions`
- Extension creates Stripe Checkout session and writes back the `url`
- App reads the `url` and redirects the browser to it via `url_launcher`
- Stripe handles payment, then redirects back to the app's success URL
- Stripe webhook fires → extension writes subscription status to `customers/{userId}/subscriptions`
- `SubscriptionProvider` listens to this collection and updates app state

#### lib/services/subscription_service.dart — Full rewrite

Remove all `in_app_purchase` code. New implementation:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();

  static const String monthlyPriceId = 'price_monthly_xxx';   // set from config
  static const String annualPriceId = 'price_annual_xxx';     // set from config
  static const String lifetimePriceId = 'price_lifetime_xxx'; // set from config

  final FirebaseFirestore? _injectedFirestore;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  SubscriptionService._() : _injectedFirestore = null;

  @visibleForTesting
  SubscriptionService.forTest(FirebaseFirestore firestore)
      : _injectedFirestore = firestore;

  /// Stream of active Stripe subscriptions for [userId].
  /// Written by the Firebase Stripe Extension webhook.
  Stream<SubscriptionInfo> subscriptionStream(String userId) {
    return _firestore
        .collection('customers')
        .doc(userId)
        .collection('subscriptions')
        .where('status', whereIn: ['active', 'trialing'])
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return SubscriptionInfo.free();
          final data = snapshot.docs.first.data();
          return SubscriptionInfo.fromStripeFirestore(data);
        });
  }

  /// Writes a checkout session document and returns the Stripe Checkout URL.
  /// The Firebase Stripe Extension populates the `url` field asynchronously.
  Future<String> createCheckoutSession({
    required String userId,
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final sessionRef = await _firestore
        .collection('customers')
        .doc(userId)
        .collection('checkout_sessions')
        .add({
      'price': priceId,
      'success_url': successUrl,
      'cancel_url': cancelUrl,
      'mode': priceId == lifetimePriceId ? 'payment' : 'subscription',
      'allow_promotion_codes': true,
    });

    // Wait for extension to populate url (timeout after 10s)
    final snapshot = await sessionRef.snapshots().firstWhere(
      (snap) => snap.data()?['url'] != null || snap.data()?['error'] != null,
    ).timeout(const Duration(seconds: 10));

    final error = snapshot.data()?['error'] as String?;
    if (error != null) throw Exception('Stripe checkout error: $error');

    return snapshot.data()!['url'] as String;
  }

  /// Loads the Stripe Customer Portal URL for subscription management.
  /// The Customer Portal shareable link is configured in the Stripe Dashboard.
  static const String stripePortalUrl =
      'https://billing.stripe.com/p/login/xxx'; // configured post-launch

  /// Fallback: reads subscription status directly from Firestore.
  Future<SubscriptionInfo> loadFromFirestore(String userId) async {
    final snapshot = await _firestore
        .collection('customers')
        .doc(userId)
        .collection('subscriptions')
        .where('status', whereIn: ['active', 'trialing'])
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return SubscriptionInfo.free();
    return SubscriptionInfo.fromStripeFirestore(snapshot.docs.first.data());
  }
}
```

#### lib/models/subscription.dart — Add Stripe factory
Add `SubscriptionInfo.fromStripeFirestore`:

```dart
factory SubscriptionInfo.fromStripeFirestore(Map<String, dynamic> data) {
  final statusStr = data['status'] as String? ?? 'unknown';
  final isActive = statusStr == 'active' || statusStr == 'trialing';
  final priceId = (data['items'] as List?)?.firstOrNull?['price']?['id'] as String?;
  final periodEnd = (data['current_period_end'] as Timestamp?)?.toDate();
  return SubscriptionInfo(
    tier: isActive ? SubscriptionTier.pro : SubscriptionTier.free,
    status: isActive ? SubscriptionStatus.active : SubscriptionStatus.unknown,
    productId: priceId,
    platform: 'web',
    expiresAt: periodEnd,
  );
}
```

Keep `SubscriptionInfo.fromFirestore` for backwards compatibility with any existing Firestore data written by the old IAP integration.

#### lib/providers/subscription_provider.dart — Rewrite

Remove all `in_app_purchase` imports and `PurchaseDetails` handling. Replace with a Firestore stream listener:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionInfo _subscriptionInfo = SubscriptionInfo.free();
  bool _isProOverride = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<SubscriptionInfo>? _subscriptionStream;
  bool _disposed = false;

  // Public getters — unchanged interface used throughout the app
  bool get isPro => _isProOverride || _subscriptionInfo.isPro;
  bool get isFree => !isPro;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SubscriptionInfo get subscriptionInfo => _subscriptionInfo;
  bool get isProOverride => _isProOverride;
  int get maxPrograms => isPro ? 999 : 3;
  int get maxCustomExercises => isPro ? 50 : 5;

  void update(AuthProvider auth) {
    final userId = auth.user?.uid;
    final profile = auth.userProfile;
    if (userId == null) { _reset(); return; }
    _isProOverride = profile?.isProOverride ?? false;
    _initialize(userId);
  }

  Future<void> _initialize(String userId) async {
    // Load cached status immediately
    final cached = await SubscriptionService.instance.loadFromFirestore(userId);
    _subscriptionInfo = cached;
    _safeNotify();

    // Start real-time listener
    _subscriptionStream?.cancel();
    _subscriptionStream = SubscriptionService.instance
        .subscriptionStream(userId)
        .listen((info) {
          _subscriptionInfo = info;
          _safeNotify();
        });
  }

  /// Opens Stripe Checkout for the given price ID.
  /// Returns true if the URL launched successfully.
  Future<bool> startCheckout(String userId, String priceId) async {
    _error = null;
    _isLoading = true;
    _safeNotify();
    try {
      final url = await SubscriptionService.instance.createCheckoutSession(
        userId: userId,
        priceId: priceId,
        successUrl: 'https://fittrack-app.web.app/?checkout=success',
        cancelUrl: 'https://fittrack-app.web.app/?checkout=cancelled',
      );
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      _isLoading = false;
      _safeNotify();
      return launched;
    } catch (e) {
      _error = 'Could not start checkout. Please try again.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<void> openCustomerPortal() async {
    final uri = Uri.parse(SubscriptionService.stripePortalUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void clearError() { _error = null; _safeNotify(); }

  @visibleForTesting
  void setSubscriptionInfoForTest(SubscriptionInfo info) {
    _subscriptionInfo = info; _safeNotify();
  }

  @visibleForTesting
  void setProOverrideForTest({required bool value}) {
    _isProOverride = value; _safeNotify();
  }

  void _reset() {
    _subscriptionInfo = SubscriptionInfo.free();
    _isProOverride = false;
    _isLoading = false;
    _error = null;
    _subscriptionStream?.cancel();
    _subscriptionStream = null;
    _safeNotify();
  }

  void _safeNotify() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() {
    _disposed = true;
    _subscriptionStream?.cancel();
    super.dispose();
  }
}
```

**Important:** `startCheckout` requires the userId. The PaywallScreen gets this from `AuthProvider` via Provider. The `SubscriptionProvider.update()` receives `AuthProvider` but doesn't store the userId — the paywall screen must read userId from the auth provider directly when calling `startCheckout`.

#### lib/screens/subscription/paywall_screen.dart — Update for Stripe redirect

Remove `sub.purchaseAnnual()` / `sub.purchaseMonthly()` calls. Replace with `sub.startCheckout(userId, priceId)`.

Changes:
- Add `context.read<AuthProvider>().user?.uid` to get userId
- Remove "Restore purchases" button (no web equivalent for Stripe)
- Update plan cards to show all three plans (Monthly, Annual, Lifetime)
- Use hardcoded prices in the display (Stripe price IDs don't carry display prices)
- Update `sub.annualProduct?.price` and `sub.monthlyProduct?.price` to hardcoded strings

The `_PlanCard` widget stays identical. The `onTap` callbacks change:
```dart
onTap: () {
  Navigator.of(context).pop();
  final userId = context.read<AuthProvider>().user?.uid;
  if (userId != null) {
    context.read<SubscriptionProvider>()
        .startCheckout(userId, SubscriptionService.annualPriceId);
  }
}
```

#### lib/screens/subscription/subscription_management_screen.dart — Stripe Portal

Remove `dart:io` import and `Platform.isIOS` check. Replace `_openManageSubscription()` to use Stripe Customer Portal:

```dart
Future<void> _openManageSubscription(BuildContext context) async {
  await context.read<SubscriptionProvider>().openCustomerPortal();
}
```

Remove the iOS/Android URL constants. The "Restore purchases" button is removed (no Stripe equivalent).

#### Firestore Security Rules Update
The Firebase Stripe Extension requires read access to `customers/{uid}/subscriptions` for the authenticated user. Add to `firestore.rules`:

```
match /customers/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if false; // Extension writes via admin SDK

  match /checkout_sessions/{sessionId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }

  match /subscriptions/{subscriptionId} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false; // Extension writes via admin SDK
  }
}
```

---

### Task #483 — Update CI Pipeline for Flutter Web Builds

**Depends on #479 (needs the app hosting site to exist) and #481 (needs web build to compile).**

#### .github/workflows/deploy_website.yml — Full rewrite

Add Flutter setup and web build. Deploy both targets:

```yaml
name: Deploy Website

on:
  push:
    branches:
      - main
    paths:
      - 'fittrack/public/**'
      - 'fittrack/lib/**'
      - 'fittrack/web/**'
      - 'fittrack/pubspec.yaml'
      - 'fittrack/firebase.json'
  workflow_dispatch:

jobs:
  deploy-marketing:
    name: Deploy Marketing Site
    runs-on: ubuntu-latest
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
    steps:
      - uses: actions/checkout@v4
      - name: Deploy marketing site to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: fitness-app-8505e
          target: marketing
          channelId: live
          entryPoint: ./fittrack

  deploy-pwa:
    name: Build and Deploy PWA
    runs-on: ubuntu-latest
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.35.1
          cache: true

      - name: Install dependencies
        run: |
          cd fittrack
          flutter pub get

      - name: Build Flutter web
        run: |
          cd fittrack
          flutter build web --release

      - name: Deploy PWA to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          projectId: fitness-app-8505e
          target: app
          channelId: live
          entryPoint: ./fittrack
```

**Note:** Splitting into two jobs allows the marketing site to deploy even if the Flutter build fails, and vice versa.

The `paths` trigger now includes `fittrack/lib/**`, `fittrack/web/**`, and `fittrack/pubspec.yaml` so code changes trigger a redeploy.

---

### Task #482 — PWA Install Prompt and Offline Service Worker Validation

**Final task — run after all others are complete.**

#### fittrack/web/manifest.json — Update branding

```json
{
  "name": "Overload",
  "short_name": "Overload",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#000000",
  "description": "Structured strength tracking. Built for progressive overload.",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

#### fittrack/web/index.html — Update branding

Update:
- `<meta name="apple-mobile-web-app-title" content="Overload">`
- `<meta name="description" content="Structured strength tracking. Built for progressive overload.">`
- `<title>Overload</title>`

#### Firestore offline persistence
Already configured in `main.dart` via `FirestoreService.enableOfflinePersistence()`. No changes needed. Verify it works in web by testing offline scenario in Chrome DevTools.

#### Validation checklist for developer
- [ ] Run `flutter build web` locally — zero errors
- [ ] Deploy to `fittrack-app.web.app` via CI
- [ ] Open URL in Android Chrome → install prompt appears after interaction
- [ ] Open URL in iOS Safari 16.4+ → add to home screen via share sheet works
- [ ] App icon shows "Overload" on home screen
- [ ] Standalone mode (no browser chrome) confirmed
- [ ] Enable airplane mode → previously loaded programs visible and editable
- [ ] Log a set offline → set visible in Firestore after re-enabling network
- [ ] Run Lighthouse PWA audit → passes installability checks

---

## 4. Task Sequencing and Dependencies

```
#481 (Remove mobile-only packages)    ──┬──► #480 (Stripe billing)
                                        │
#479 (Firebase Hosting multi-site)  ────┤
                                        │
                                        ├──► #483 (CI pipeline)
                                        │
                                        └──► #482 (PWA validation) ← all others
```

**Recommended order:**
1. **#481** — Foundation. Enables `flutter build web`. ~2 days.
2. **#479** — Infra. Can be done in parallel with #481 (touches different files). ~0.5 days.
3. **#480** — Stripe billing. Depends on #481 (IAP must be gone). ~2 weeks.
4. **#483** — CI. Depends on #479 + #481. ~0.5 days.
5. **#482** — Validation. Depends on all others. ~1–2 days.

---

## 5. Testing Strategy

Following the existing testing patterns (mockito, `fake_cloud_firestore`, integration test helpers).

### Task #481 Tests
- Unit tests for stubbed `NotificationService` — all methods return without error
- Unit tests for `LifecycleNotificationService` analytics tracking still fires (mock SharedPreferences, mock AppAnalyticsService)
- Unit tests for `AppReviewService.maybeRequestReview()` no-op path
- No web build test here — verified in #483 CI step

### Task #480 Tests
- Unit tests for `SubscriptionService` (`forTest` constructor with `fake_cloud_firestore`):
  - `subscriptionStream` returns `SubscriptionInfo.free()` when no subscriptions
  - `subscriptionStream` returns `SubscriptionInfo` with `isPro: true` when active subscription exists
  - `createCheckoutSession` writes correct document to Firestore
  - `loadFromFirestore` returns correct status
- Unit tests for `SubscriptionProvider`:
  - `isPro` gate works correctly for all status values
  - `startCheckout` sets `isLoading` then clears it
  - `openCustomerPortal` calls `url_launcher` with the portal URL
- Widget tests for `PaywallScreen`:
  - Renders three plan cards (Monthly, Annual, Lifetime)
  - Tapping a plan calls `startCheckout`
  - Loading state shows `CircularProgressIndicator`
- **Integration test** (`test/services/subscription_service_integration_test.dart`) — required per `CLAUDE.md`

### Task #482 Tests
- Manual validation only (no automated tests for Lighthouse or manual install flow)
- Offline test: use Chrome DevTools to verify Firestore cache serves data

---

## 6. Security Considerations

- **Stripe secret key** — stored in Firebase Extension config (environment variable in Google Cloud), never in the Flutter app or repository
- **Stripe publishable key** — not needed; using Stripe Checkout redirect, not embedded SDK
- **Firestore rules** — `customers/{uid}/subscriptions` readable only by the authenticated user; writable only by the Extension (admin SDK)
- **Checkout session** — written by the Flutter client but the Extension validates it server-side before creating the Stripe session; no price manipulation possible
- **dart:io removal** — eliminates `Platform.isIOS` checks that could behave unexpectedly on web

---

## 7. Files Summary

### New files
None — all changes are modifications to existing files.

### Modified files (by task)

**#481:**
- `fittrack/pubspec.yaml` — remove 7 packages
- `fittrack/lib/services/notification_service.dart` — stub rewrite
- `fittrack/lib/services/lifecycle_notification_service.dart` — partial stub (keep analytics)
- `fittrack/lib/services/app_review_service.dart` — remove InAppReview, no-op review call

**#479:**
- `fittrack/firebase.json` — convert hosting to array, add app target
- `fittrack/.firebaserc` — add hosting targets

**#480:**
- `fittrack/lib/services/subscription_service.dart` — full rewrite (Stripe)
- `fittrack/lib/providers/subscription_provider.dart` — rewrite (Firestore stream)
- `fittrack/lib/models/subscription.dart` — add `fromStripeFirestore` factory
- `fittrack/lib/screens/subscription/paywall_screen.dart` — Stripe Checkout redirect
- `fittrack/lib/screens/subscription/subscription_management_screen.dart` — Stripe Portal
- `fittrack/firestore.rules` — add `customers` collection rules

**#483:**
- `.github/workflows/deploy_website.yml` — add Flutter build + multi-target deploy

**#482:**
- `fittrack/web/manifest.json` — update to "Overload" branding
- `fittrack/web/index.html` — update title and meta tags

---

## 8. Implementation Notes

*(To be updated by Developer Agent as implementation progresses)*
