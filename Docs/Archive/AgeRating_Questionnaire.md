# Age Rating Questionnaire — Overload

> **ARCHIVED (2026-08-02):** Drafted for a native IAP-based Pro subscription that was never actually implemented — the app used Stripe Checkout instead — and monetization has since been parked entirely. Overload is currently free for all users with no digital purchases. Kept for reference in case paid tiers return; needs a rewrite (the "digital purchases: Yes" answer below no longer applies) before any store submission. See [#472](https://github.com/justbuildstuff-dev/Fitness-App/issues/472) and [#453](https://github.com/justbuildstuff-dev/Fitness-App/issues/453) for context.

## Apple App Store (App Store Connect)

Complete the Age Rating section in App Store Connect under your app's General Information. Answer as follows:

| Question | Answer | Reasoning |
|---------|--------|-----------|
| Made for Kids | **No** | Adult fitness app |
| Alcohol, Tobacco, or Drug Use or References | **None** | No such content |
| Contests | **None** | No gambling or prize contests |
| Gambling and Contests | **None** | No gambling |
| Horror/Fear Themes | **None** | No such content |
| Mature/Suggestive Themes | **None** | No such content |
| Medical/Treatment Information | **None** | General fitness tracking only, no medical advice |
| Profanity or Crude Humor | **None** | No such content |
| Sexual Content or Nudity | **None** | No such content |
| Violence | **None** | No such content |
| Unrestricted Web Access | **No** | Legal links (Terms/Privacy) open in browser but are not a general browser; no arbitrary web browsing |

**Expected Rating: 4+**

---

## Google Play Store (Content Rating — IARC Questionnaire)

In the Google Play Console, navigate to App Content → Content Rating → Start Questionnaire. Select **Utility** as the app category (closest match; alternatively select **Health & Fitness** if available). Answer as follows:

| Category | Question | Answer |
|---------|---------|--------|
| Violence | Does your app contain violent or graphic content? | **No** |
| Sexual content | Does your app contain sexual content? | **No** |
| Profanity | Does your app contain profanity or crude humour? | **No** |
| Controlled substances | Does your app depict or reference drugs, alcohol, or tobacco? | **No** |
| User-generated content | Does your app allow users to generate and share content? | **No** — users create workout data for their own use only; it is not shared with or visible to other users |
| Social features | Does your app include social or communication features? | **No** |
| Location sharing | Does your app share or display user location? | **No** |
| Digital purchases | Does your app include digital purchases? | **Yes** — in-app subscription (Overload Pro) |

**Expected Rating: Everyone (E)**

---

## Health & Fitness App Notes

- Overload does **not** provide medical advice, diagnosis, or treatment
- Overload does **not** track biometric health data (heart rate, blood pressure, etc.)
- Overload is a workout log — it records what the user manually inputs
- A health disclaimer is included in the app store descriptions and should be shown during onboarding (see HealthDisclaimer.md)
- If Apple HealthKit integration is added in a future version, re-evaluate whether the "Medical/Treatment Information" answer changes

---

## Privacy Nutrition Label (Apple — App Privacy)

In App Store Connect, complete the Privacy Nutrition Label under your app's Privacy section:

**Data Used to Track You:** No (we do not use data for cross-app tracking or advertising)

**Data Linked to You:**
- Contact Info → Email Address (used for account creation)
- Usage Data → App interactions, crash data (linked via Firebase UID)

**Data Not Linked to You:**
- Diagnostics → Crash data (only if processed without user identifier — note: Firebase Crashlytics links to Firebase UID, so this is "linked to you")

**Practical guidance:** Declare conservatively. Apple reviewers check these declarations and discrepancies cause rejection. When in doubt, declare the data as "linked to you."
