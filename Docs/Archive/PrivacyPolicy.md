# Overload — Privacy Policy

> **ARCHIVED (2026-08-02):** Drafted while a native IAP-based Pro subscription was planned. That subscription was never actually implemented — the app used Stripe Checkout instead — and monetization has since been parked entirely; Overload is currently free for all users. The "Google Play Billing / App Store IAP" data-processor entry below no longer applies. This draft was never legally reviewed or published as the live privacy policy. Kept for reference in case paid tiers return. See [#472](https://github.com/justbuildstuff-dev/Fitness-App/issues/472) and [#453](https://github.com/justbuildstuff-dev/Fitness-App/issues/453) for context.

**Effective Date:** [To be set before submission]  
**Last Updated:** May 2026

> **Status:** Live at https://fitness-app-8505e.web.app/privacy — this URL satisfies both App Store and Play Store requirements. When a custom domain is connected, update to https://overloadapp.com/privacy and update the in-app paywall links accordingly.
> 
> **Note:** This document reflects the policy content. The authoritative hosted version is the live HTML page linked above.

---

## 1. Overview

Overload ("the App", "we", "us") is committed to protecting your privacy. This policy explains what personal data we collect, how we use it, how we store it, and your rights as a user.

We do not sell your data. We do not use your data for advertising. Your fitness data is personal, and we treat it that way.

---

## 2. Who We Are

The App is operated by justbuildstuff.dev. Contact: justbuildstuff.dev@gmail.com.

---

## 3. Data We Collect

### 3.1 Account Data
- **Email address** — required to create an account and authenticate
- **Display name** — optional, provided by you during sign-up

### 3.2 Health & Fitness Data
- Workout programs, weeks, workouts, exercises, and set data you create and log
- Personal records and performance analytics derived from your logged data
- Training history (dates, volume, frequency)

This data is personal health information and is treated with appropriate care. It is stored securely in your private account and is not visible to other users.

### 3.3 Usage Data (collected automatically by Firebase)
- App interactions and feature usage events (e.g., "workout started", "program created")
- Device type (iOS/Android) and operating system version
- App version
- Crash reports and error logs (via Firebase Crashlytics)
- Session information (when the app was opened, approximate session duration)

### 3.4 Notification Data
- If you grant notification permission, we send local device notifications for workout reminders and re-engagement prompts. We do not send marketing emails without your explicit consent.
- Firebase Cloud Messaging (FCM) tokens are stored locally on your device to enable push notifications. These tokens are not used for targeting or advertising.

---

## 4. How We Use Your Data

| Purpose | Data used | Basis |
|---------|-----------|-------|
| Provide the app's workout tracking functionality | Account data, fitness data | Contract (to provide the service) |
| Sync your data across devices | Account data, fitness data | Contract |
| Compute analytics and progress charts | Fitness data | Contract |
| Detect and fix app crashes | Crash logs, device data | Legitimate interest |
| Understand how the app is used (aggregate analytics) | Usage events (anonymised) | Legitimate interest |
| Send workout reminders and re-engagement notifications | Local device notifications | Consent (you grant notification permission) |
| Comply with legal obligations | Account data | Legal obligation |

We do **not**:
- Sell your data to third parties
- Use your data for advertising or ad targeting
- Share your fitness data with any third party other than our infrastructure providers (listed below)
- Use your data to train AI or machine learning models

---

## 5. Third-Party Services

The App uses the following third-party infrastructure providers. All are bound by their own privacy policies and, where applicable, data processing agreements.

| Service | Provider | Purpose | Privacy Policy |
|---------|----------|---------|----------------|
| Firebase Authentication | Google LLC | Account creation and sign-in | https://firebase.google.com/support/privacy |
| Cloud Firestore | Google LLC | Storing your workout data | https://firebase.google.com/support/privacy |
| Firebase Analytics | Google LLC | Aggregate usage analytics | https://firebase.google.com/support/privacy |
| Firebase Crashlytics | Google LLC | Crash reporting and stability | https://firebase.google.com/support/privacy |
| Firebase Cloud Messaging | Google LLC | Push notifications | https://firebase.google.com/support/privacy |
| Google Play Billing / App Store IAP | Google / Apple | Subscription management | Google/Apple privacy policies |

Google LLC processes data in accordance with the EU-US Data Privacy Framework and applicable data protection law.

---

## 6. Data Storage and Security

- Your data is stored in Google Cloud / Firebase infrastructure, which provides industry-standard encryption at rest and in transit (TLS 1.2+).
- We implement appropriate technical and organisational measures to protect your data against unauthorised access, alteration, or disclosure.
- Access to your data in our systems is restricted to the minimum necessary for operation and support.

---

## 7. Data Retention

- Your workout data is retained for as long as your account is active.
- If you delete your account, all personal data (account data, workout data) is permanently deleted from our systems within 30 days.
- Aggregate, anonymised analytics data (e.g., total number of workouts logged in a month) may be retained indefinitely as it cannot be linked to an individual.
- Crash logs are retained for a maximum of 90 days.

---

## 8. Your Rights

Depending on your jurisdiction, you may have the following rights:

| Right | How to exercise |
|-------|----------------|
| Access your data | All your data is visible within the app |
| Correct your data | Edit your profile or workout data directly in the app |
| Delete your data | Delete your account via Settings → Profile → Delete Account |
| Data portability | [Data export feature — note if not yet implemented: "Contact us at [email] to request a data export"] |
| Withdraw consent (notifications) | Revoke notification permission in your device settings |
| Object to processing | Contact us at [contact email] |

**For EU/EEA users (GDPR):** You have the right to lodge a complaint with your local data protection authority.

**For California users (CCPA):** You have the right to know what personal information we collect, to delete it, and to opt out of sale. We do not sell personal information.

---

## 9. Children's Privacy

Overload is not directed at children under 13 (or 16 in some jurisdictions). We do not knowingly collect personal data from children under 13. If you believe a child under 13 has provided us with personal data, please contact us and we will delete it promptly.

---

## 10. Health Data Notice

Overload is a fitness tracking tool for personal use. It is not a medical device and does not provide medical advice, diagnosis, or treatment. The fitness data you log in the app is for your personal tracking purposes only.

If the App integrates with Apple Health or Google Fit in a future version, that data will be subject to Apple's and Google's health data privacy policies respectively.

---

## 11. Changes to This Policy

We will update this policy when our data practices change materially. We will notify you of significant changes via an in-app notice or email. The "Last Updated" date at the top of this document reflects the most recent revision. Continued use of the App after changes constitutes acceptance of the updated policy.

---

## 12. Contact Us

If you have questions, requests, or complaints about your data or this policy:

**Email:** justbuildstuff.dev@gmail.com

We aim to respond to all data-related requests within 30 days.

---

*This document was drafted as a starting point. It should be reviewed by a qualified lawyer before publication, particularly for GDPR (EU), CCPA (California), and PIPEDA (Canada) compliance.*
