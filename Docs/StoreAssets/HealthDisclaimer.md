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

*The app currently links to Terms of Service at https://overloadapp.com/terms from the paywall footnote. A draft Terms of Service document is needed before launch. It should cover at minimum:*

- Acceptance of terms
- Description of service (workout tracking app; not medical device)
- User responsibilities (provide accurate information; not use for harmful purposes)
- Subscription terms (billing, cancellation, refunds — defer to Apple/Google policies)
- Limitation of liability (app not liable for injuries, data loss)
- Disclaimer of warranties
- Governing law and jurisdiction
- Contact information

*Recommendation: Use a lawyer or a reputable Terms of Service generator (Iubenda, Termly) as a starting point. Host at https://overloadapp.com/terms before submission.*
