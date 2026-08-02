# App Store Review Guidelines Compliance — Overload v1.6.0

Complete all items before submitting to either store. Tick each box as confirmed.

---

## Apple App Store Review Guidelines

Reference: https://developer.apple.com/app-store/review/guidelines/

### 1. Safety (Guidelines 1.1–1.5)
- [ ] App does not encourage or facilitate dangerous activities
- [ ] Health disclaimer included in app store description and in-app onboarding (see HealthDisclaimer.md)
- [ ] No user-generated content is shared between users — all workout data is private to the account holder
- [ ] No user-generated content moderation issues (not applicable — single-user app)

### 2. Performance (Guidelines 2.1–2.5)
- [ ] App is complete — no placeholder screens, "coming soon" UI, or non-functional buttons
- [ ] App does not crash on launch (test on physical device, not just simulator)
- [ ] App does not crash on low-memory conditions (test on older device)
- [ ] All advertised features in the description are implemented and working
- [ ] App works offline — workout logging works without a network connection (offline support is advertised)
- [ ] Binary does not include unused code or assets that inflate size significantly

### 3. Business (Guidelines 3.1–3.2)
- [ ] Subscription pricing clearly stated in the app description and on the paywall screen
- [ ] Subscription terms (billing period, amount, auto-renewal) disclosed on the paywall before purchase
- [ ] Cancellation instructions accessible to users (Settings app → Subscriptions)
- [ ] No misleading subscription traps or dark patterns (can dismiss paywall, free tier remains functional)
- [ ] In-app purchase products set up correctly in App Store Connect with correct pricing tiers
- [x] Privacy policy URL is live at https://fitness-app-8505e.web.app/privacy ✓

**Subscription disclosure on paywall must include:**
> "$6.99/month or $39.99/year. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your device subscription settings."

### 4. Design (Guidelines 4.1–4.8)
- [ ] App follows iOS Human Interface Guidelines (Material 3 / Flutter maps closely — verify no severe HIG violations)
- [ ] Does not replicate the App Store, iTunes Store, or iOS system app UI
- [ ] App icon does not include the App Store badge or use Apple product images
- [ ] App icon looks correct at all sizes (verify at 60×60 and 1024×1024)
- [ ] Supports Dynamic Type / text scaling (review at largest accessibility text size)
- [ ] Supports both light and dark mode (app has explicit theme switcher)

### 5. Legal (Guidelines 5.1–5.5)
- [x] Privacy policy is live at https://fitness-app-8505e.web.app/privacy ✓
- [x] Privacy policy accurately describes all data collected (email, workout data, analytics events) ✓
- [ ] App name "Overload" does not infringe any registered trademark in the fitness/software category — **verify with a trademark search before submission**
- [ ] No copyrighted content used without licence (exercise names are generic; pre-built program names are generic fitness terms)
- [ ] App Store Privacy Nutrition Label completed accurately in App Store Connect

### 6. Health & Fitness (Guideline 1.4)
- [ ] App does not claim to diagnose, treat, cure, or prevent any medical condition
- [ ] Health disclaimer present in app store description (bottom of description)
- [ ] Health disclaimer shown during onboarding (or accessible in app — see HealthDisclaimer.md)
- [ ] App does not access Apple HealthKit without explicit user permission (note: HealthKit not integrated in v1.6.0 — confirm this is still correct)
- [ ] Exercise recommendations in pre-built programs are general fitness guidance, not medical advice

### 7. In-App Review Prompt (Guideline 1.1.7)
- [ ] `SKStoreReviewController.requestReview()` is called at most 3 times per 365-day period (Apple enforces this)
- [ ] Review prompt is NOT shown within the first launch, on first-run, or immediately after a negative event
- [ ] Review prompt is shown after a positive moment (5th completed workout + 7+ days since first use — ✓ correctly implemented)
- [ ] Review prompt is NOT used to gate features or rewards

---

## Google Play Store Policy

Reference: https://play.google.com/about/developer-content-policy/

### Core App Quality
- [ ] App is stable — no ANRs (Application Not Responding) on test devices
- [ ] No crashes on supported Android versions
- [ ] Target SDK meets current minimum (API 35 for 2025+ submissions — verify in build.gradle)
- [ ] App tested on Android 10, 12, and 14 (or latest three major versions)

### Privacy & Data Safety
- [ ] Data Safety form completed accurately in Play Console (see AgeRating_Questionnaire.md for data inventory)
- [x] Privacy policy URL is live at https://fitness-app-8505e.web.app/privacy ✓
- [ ] All data types collected are declared — email, fitness data, usage events, crash logs, FCM tokens
- [ ] App requests only necessary permissions (expected: POST_NOTIFICATIONS for push notifications)

### Permissions
- [ ] `POST_NOTIFICATIONS` — requested after first workout completion (correctly implemented — not on first launch)
- [ ] No `READ_EXTERNAL_STORAGE` or `WRITE_EXTERNAL_STORAGE` unless data export is implemented
- [ ] Internet permission used only for Firebase sync (standard, no review concern)
- [ ] All permissions have runtime explanation shown to user before requesting

### Subscriptions & Billing
- [ ] Google Play Billing Library integrated correctly (verify version — Google requires minimum billing library version)
- [ ] Subscription products set up in Play Console with correct pricing
- [ ] Pricing clearly displayed before purchase
- [ ] Auto-renewal disclosed on the paywall

### Content Policy
- [ ] App description does not keyword-stuff (title/description are readable and natural — ✓)
- [ ] Screenshots accurately represent the app (no features shown that don't exist — verify before upload)
- [ ] App is not misleadingly described (no claims that can't be substantiated)
- [ ] No content that violates Play's Restricted Content policy

### App Signing
- [ ] App is signed with an upload key (not the same as the signing key for Play App Signing)
- [ ] Play App Signing enrolled (Google manages the distribution signing key — recommended)
- [ ] Keystore file backed up securely (NOT in the repository)

---

## Pre-Submission Final Checks

### Both Stores
- [ ] App version number in pubspec.yaml matches submitted binary (1.6.0+7)
- [ ] Release build tested on physical devices (not just emulator)
- [ ] Subscription flow end-to-end tested with sandbox accounts
- [ ] Paywall can be dismissed; free features work after dismissing paywall
- [ ] Push notification permission prompt tested — only fires after first workout
- [ ] In-app review prompt fires correctly (may require a test build with the count threshold lowered)
- [ ] Privacy policy URL is live and correct before submitting to either store
- [ ] All placeholder text removed from store listings (no "[Founder name]" or "[To be added]")

### Apple Only
- [ ] App Store Connect app record created
- [ ] Bundle ID `com.fittrack.app` registered in Apple Developer portal
- [ ] Provisioning profiles and certificates valid
- [ ] TestFlight build submitted and tested before App Store submission
- [ ] Age Rating questionnaire completed in App Store Connect
- [ ] Privacy Nutrition Label completed

### Google Only
- [ ] Play Console app created with package `com.fittrack.app`
- [ ] Content Rating questionnaire completed (IARC)
- [ ] Data Safety form completed
- [ ] Internal/Closed testing track tested before production release
- [ ] Feature Graphic uploaded (1024×500px)
- [ ] App icon uploaded (512×512px PNG)
