# PRD: Transition to Progressive Web Application

**Status:** Ready for Design
**Priority:** High
**Platform:** Both (web — Android Chrome + iOS Safari + desktop)
**Feature Type:** New Feature
**GitHub Issue:** #478
**Created:** 2026-06-14

---

## 1. Problem Statement

Google Play requires a developer account physical address that is publicly visible on the store listing. For a solo founder without a registered business address this is a dealbreaker — the address cannot be hidden and is permanently attached to every published app.

The app (Overload, package `com.fittrack.app`) is ~6–8 weeks from Play Store submission. Rather than register a business address to satisfy Google's requirement, we pivot the distribution channel: instead of a native Android app, we publish as a Progressive Web Application hosted on Firebase Hosting.

This pivot also:
- **Eliminates the 30% Google Play billing cut** — replaced by Stripe at ~3% per transaction
- **Enables instant deployments** — no store review cycle; push code and users get it immediately
- **Broadens reach** — works on Android Chrome, iOS Safari (16.4+), and desktop browsers without separate builds

The Android codebase and packaging are preserved in case the distribution decision changes later (e.g., after registering a business, or switching to iOS App Store which handles address differently).

---

## 2. Users

**Primary:** New users arriving via direct link, Reddit/social sharing, or the marketing site (`overload.fitness`) who install the PWA to their home screen on Android or iOS.

**Existing:** Current beta testers who currently access via Firebase App Distribution APK — they will migrate to the PWA URL.

---

## 3. Existing Implementation Notes

Relevant to the SA when designing:

- **Flutter web already configured:** `fittrack/web/` exists with PWA manifest, icons, and Flutter bootstrap template. `flutter build web` is expected to work without major code changes — the framework, Firestore, Auth, Analytics, and Storage all have first-class web support.
- **Mobile-only packages in `pubspec.yaml`** that will break a web build: `in_app_purchase`, `flutter_local_notifications`, `in_app_review`, `path_provider`. These must be removed or conditionally excluded before the web build works.
- **`SubscriptionService`** (`lib/services/subscription_service.dart`) currently wraps `in_app_purchase`. It will be fully rewritten to use the Firebase Stripe Extension.
- **`PaywallScreen`** (`lib/screens/subscription/paywall_screen.dart`) will be updated to trigger a Stripe Checkout redirect rather than opening a native IAP sheet.
- **Firebase Hosting currently serves one site:** `fitness-app-8505e.web.app` → marketing site at `fittrack/public/`. The PWA needs a second Firebase Hosting site.
- **PWA URL (confirmed):** `app.fitness-app-8505e.web.app` — no custom domain configuration required for launch.
- **Subscription pricing (unchanged):** $6.99/month, $39.99/year, $59.99 lifetime. These become Stripe Price IDs instead of App Store product IDs.
- **Notifications deferred:** `flutter_local_notifications` and FCM web push are OUT OF SCOPE for this launch. Notification service calls will be stubbed/removed so the web build compiles. A follow-up PRD will cover web push notifications.
- **Android packaging preserved:** `fittrack/android/` and `beta_build.yml` are NOT touched by this feature.

---

## 4. User Stories

### Story 1: Access the App via Browser

**As a** new user who clicked a link to Overload,
**I want to** open the app in my mobile browser and be prompted to install it to my home screen,
**so that** I can use it like a native app without going through an app store.

**Acceptance Criteria:**
1. Navigating to `https://app.fitness-app-8505e.web.app` loads the Overload Flutter app in a browser.
2. On Android Chrome, the browser displays an "Add to Home Screen" / "Install App" prompt after a brief interaction.
3. On iOS Safari 16.4+, the user can manually add to home screen via the share sheet.
4. After installation, the app launches in standalone mode (no browser chrome, full screen).
5. The app icon and name ("Overload") display correctly on the home screen.

---

### Story 2: Subscribe via Stripe Checkout

**As a** free-tier user who has hit a feature gate (e.g. attempting to create a 4th program),
**I want to** subscribe to Overload Pro by completing a payment flow,
**so that** I can unlock unlimited programs and advanced analytics.

**Acceptance Criteria:**
1. Tapping a Pro gate trigger (paywall screen) presents the existing plan options: Monthly ($6.99), Annual ($39.99), Lifetime ($59.99).
2. Tapping a plan opens Stripe Checkout in the browser (redirect, not an in-app sheet).
3. After successful payment, Stripe returns the user to the app with their subscription active.
4. The user's subscription status updates in the app without requiring a manual refresh (Firestore listener picks up the change written by the Firebase Stripe Extension webhook).
5. If the user closes Stripe Checkout without completing payment, they return to the paywall screen and their status remains unchanged.
6. Subscription cancellation is handled via the Stripe Customer Portal (linked from Settings → Subscription Management screen).

---

### Story 3: Use the App Offline

**As a** user in the gym with poor mobile signal,
**I want to** view and log my workouts even without an internet connection,
**so that** I don't lose a session due to connectivity issues.

**Acceptance Criteria:**
1. Programs, weeks, workouts, exercises, and sets that were previously loaded are accessible when offline.
2. Set logging (check/uncheck, create set) works offline and syncs to Firestore when connectivity is restored.
3. A visible indicator informs the user they are in offline mode (consistent with current offline behavior).
4. No crash or error dialog appears when opening the app without network access.

---

### Story 4: App Compiles and Runs Without Mobile-Only Packages

**As a** developer deploying the Flutter web build,
**I want** the codebase to compile without errors when targeting the web platform,
**so that** CI can build and deploy the PWA automatically.

**Acceptance Criteria:**
1. `flutter build web` completes without errors.
2. `in_app_purchase`, `flutter_local_notifications`, `in_app_review`, and `path_provider` are removed from `pubspec.yaml`.
3. All call sites that referenced notification APIs are removed or stubbed so the code compiles (no functionality replaced — notifications are out of scope).
4. CSV export uses `dart:html` to trigger a browser file download instead of `path_provider`.
5. Share functionality falls back to copy-to-clipboard with a "Copied!" confirmation.
6. `in_app_review` prompts are removed entirely (no replacement for web).

---

### Story 5: CI Automatically Deploys the PWA on Push to Main

**As a** developer,
**I want** the CI pipeline to build and deploy the Flutter web app to Firebase Hosting automatically when changes merge to `main`,
**so that** PWA deployments are hands-free and consistent.

**Acceptance Criteria:**
1. Pushing to `main` triggers `deploy_website.yml`, which builds the Flutter web app (`flutter build web --release`) and deploys it to the `app.fitness-app-8505e.web.app` Firebase Hosting site.
2. The existing marketing site (`fitness-app-8505e.web.app`) deploys to its existing target without changes.
3. `beta_build.yml` (Android APK build) is untouched and continues to function.
4. Build failures surface as a failed GitHub Actions check.

---

## 5. Functional Requirements

- FR-1: Firebase Hosting second site configured at `app.fitness-app-8505e.web.app`
- FR-2: Flutter web build deploys to second site via CI
- FR-3: `in_app_purchase` replaced with Firebase Stripe Extension + Stripe Checkout redirect
- FR-4: Subscription status written to Firestore by Stripe webhook; `SubscriptionProvider` reads it unchanged
- FR-5: Stripe Customer Portal linked from Settings → Subscription Management for cancellation/management
- FR-6: Mobile-only packages removed from `pubspec.yaml`; all call sites compile cleanly
- FR-7: CSV export functional via `dart:html` browser download
- FR-8: PWA manifest and service worker validated; app installable on Android Chrome and iOS Safari
- FR-9: Firestore offline persistence confirmed functional in PWA context

---

## 6. Non-Functional Requirements

- NFR-1: **Performance** — Flutter web initial load under 5 seconds on 4G mobile connection
- NFR-2: **Offline** — Core workout logging functions without network access (Firestore offline persistence)
- NFR-3: **Security** — Stripe keys never committed to the repository; loaded via Firebase environment config
- NFR-4: **Compatibility** — Tested on Android Chrome 120+, iOS Safari 16.4+, Chrome desktop
- NFR-5: **Payments PCI compliance** — Stripe Checkout (hosted) handles all card data; app never handles raw card numbers

---

## 7. Out of Scope (Deferred)

- **FCM web push notifications** — `NotificationService` and `LifecycleNotificationService` for web are a separate post-launch PRD. For this launch, notification calls are stubbed/removed.
- **Custom domain** (`app.overload.fitness`) — deferred; launch uses `app.fitness-app-8505e.web.app`
- **iOS App Store submission** — separate decision; Apple handles developer address differently
- **Android Play Store submission** — the original dealbreaker; kept deferred

---

## 8. User Flow

**New user — first open:**
1. User opens `https://app.fitness-app-8505e.web.app` (from link or marketing site CTA)
2. Flutter app loads; onboarding flow runs
3. Android: browser shows install prompt → user adds to home screen
4. iOS: user manually adds via share sheet

**Subscription:**
1. User hits Pro gate (e.g. 4th program)
2. Paywall screen shows plan options
3. User taps "Start Pro Monthly" → redirected to Stripe Checkout
4. Completes payment → returned to app URL with success param
5. Stripe webhook fires → Firebase Stripe Extension writes `status: active` to Firestore
6. Firestore listener in `SubscriptionProvider` updates → Pro features unlock

**Offline workout logging:**
1. User opens app without internet
2. Firestore offline cache serves data
3. User logs sets normally
4. On reconnection, Firestore syncs pending writes

---

## 9. Success Metrics

- Flutter web build compiles with zero errors
- PWA installable on Android Chrome and iOS Safari (passes Lighthouse PWA audit)
- Stripe test subscription round-trip works end-to-end (checkout → webhook → Firestore → app unlock)
- Offline mode: can log a set while airplane mode active; set visible in Firestore after reconnect
- CI deploys PWA to Firebase Hosting on push to `main` without manual intervention

---

## 10. Overall Acceptance Criteria

- [ ] `https://app.fitness-app-8505e.web.app` loads the Overload app
- [ ] All 38 screens render without runtime errors on web
- [ ] Stripe Checkout completes a test subscription and unlocks Pro features
- [ ] App is installable to home screen (Android + iOS)
- [ ] CI pipeline deploys automatically on push to `main`
- [ ] Marketing site deployment is unaffected
- [ ] Android build pipeline (`beta_build.yml`) is unaffected
