# Health & Fitness Disclaimer — Overload

---

## 1. App Store / Play Store Listing Disclaimer

*Add verbatim to the bottom of the app description on both stores.*

```
Overload is for fitness tracking and personal use only. Always consult a
qualified healthcare professional before starting a new exercise programme.
Overload does not provide medical advice, diagnosis, or treatment.
```

---

## 2. In-App Onboarding Disclaimer

*Show on first launch, during or at the end of the onboarding wizard. Must require a positive user action (button tap) to dismiss — not auto-dismissed.*

**Screen title:** Before You Begin

**Body text:**
```
Overload helps you track your workouts and measure your progress over time. 
It is not a medical device and does not provide medical advice.

• Consult your doctor before starting a new exercise programme if you have 
  any health concerns.
• Stop exercising immediately and seek medical attention if you experience 
  pain, dizziness, or shortness of breath.
• Listen to your body and train within your limits.

Progressive overload works best when applied consistently and safely.
```

**Button:** "Got it — let's train"

*This screen should appear once per install (not on every launch). Store the "seen disclaimer" flag in SharedPreferences.*

---

## 3. Why This Matters

**Apple App Store Review Guidelines §1.4:** Apple requires fitness apps to include a health disclaimer where there is any potential for physical harm. Workout guidance — even general programming — can constitute this risk. A visible disclaimer protects both users and the app from rejection or removal.

**Google Play policy:** Similar requirement. Google's Health & Fitness content policy expects apps providing exercise guidance to disclaim medical advice.

**Legal protection:** The disclaimer limits liability if a user suffers an injury while following programming created in the app. It is not a substitute for a full terms of service (see PrivacyPolicy.md for the privacy-side terms; consider adding a separate Terms of Service covering user conduct, liability limitation, and disclaimer of warranties).

---

## 4. Terms of Service — Note

*The Terms of Service is live at https://fitness-app-8505e.web.app/terms and is linked from the paywall footnote in-app. It covers acceptance of terms, service description, subscriptions and billing, user conduct, intellectual property, health disclaimer, liability limitation, and governing law (Queensland, Australia).*

*When a custom domain (overloadapp.com) is connected, update the in-app links and this document to reflect the new URL.*
