# Google Play Console Listing — Overload v1.6.0

> **ARCHIVED (2026-08-02):** Drafted for a native IAP-based Pro subscription that was never actually implemented — the app used Stripe Checkout instead — and monetization has since been parked entirely. Overload is currently free for all users; the "OVERLOAD PRO" section, pricing, and reviewer notes about Google Play Billing below no longer apply. Kept for reference in case paid tiers return. See [#472](https://github.com/justbuildstuff-dev/Fitness-App/issues/472) and [#453](https://github.com/justbuildstuff-dev/Fitness-App/issues/453) for context.

## App Name (50 chars max)
```
Overload: Gym & Strength Tracker
```
*33 characters*

---

## Short Description (80 chars — shown in search results)
```
Structured workout tracker for serious lifters. No ads. No fluff.
```
*65 characters*

---

## Full Description (4000 chars max — Google indexes this for search)

```
Overload is the workout tracker for people who actually program their training.

Build structured programs across multiple weeks and workouts. Track every set — weight, reps, duration, distance. See your strength trends over time. No ads. No data selling. Ever.

STRUCTURED PROGRAMMING
• Organise training the way serious lifters think: Program → Week → Workout → Exercise → Set
• Duplicate entire training weeks with one tap — built for progressive overload cycles
• Pre-built programs: Push/Pull/Legs, Upper/Lower, Full Body, 5x5 Strength, Bro Split
• Save and reuse your own workout templates
• The only free workout tracker built around how serious lifters actually program

PROGRESS ANALYTICS
• Personal records tracked automatically across every exercise
• Activity heatmap — see your actual training consistency at a glance
• Training streaks and key workout statistics always visible
• Exercise progress charts with estimated 1RM trends (Pro)
• Volume trends and full weightlifting analytics history (Pro)

WORKOUT LOGGING
• All exercises and sets on one screen — no tapping in and out
• 5 exercise types: strength, cardio, bodyweight, time-based, custom
• Inline editing — tap to change weight, reps, or duration
• Completion toggles lock in your sets as you go

YOUR DATA, YOUR CONTROL
• No ads. No data selling. No surveillance.
• Full offline support — log gym workouts without a connection
• Your data is yours, regardless of subscription status

FREE TIER INCLUDES
• Up to 3 programs with unlimited workouts, exercises, and sets
• Personal records and activity heatmap
• All 5 exercise types
• Up to 10 custom exercises
• Save up to 3 workout templates
• Full offline support

OVERLOAD PRO
• Unlimited programs
• Full analytics history and exercise progress charts
• Estimated 1RM tracking and volume trends
• Up to 50 custom exercises and unlimited saved templates
• Access to all pre-built program templates
• $6.99/month or $39.99/year — save 52% annually

WHO IT'S FOR
Overload is built for intermediate and advanced lifters who follow structured programs: PPL, Upper/Lower, 5x5, powerlifting blocks, hypertrophy phases. If you use terms like progressive overload, periodisation, or training block — this app was made for you.

If you're looking for a workout generator or AI fitness coach, this isn't it. Overload gives you the structure; you bring the program.

Built for lifters who know that tracking isn't the goal — progressive overload is. Overload is the tool that keeps you honest.

---

Overload is for fitness tracking and personal use only. Always consult a qualified healthcare professional before starting a new exercise programme.
```

**Character count:** ~2,100 — within 4,000 limit.

**Google Play SEO note:** Google indexes the full description text. Key terms included naturally: workout tracker, gym tracker, strength tracker, weightlifting, powerlifting, progressive overload, periodisation, training block, exercise log, workout log, fitness tracker, strength training app, gym workout log.

---

## Feature Graphic
- **Size:** 1024×500px
- **Content guidance:** Dark background (matching app's dark theme). Bold "OVERLOAD" wordmark centred. Below: "Structured Strength Tracker" in smaller text. Optional: a small device mockup showing the analytics heatmap or workout logging screen on the right. Accent colour from the app (electric blue or acid green).
- **Do NOT use:** Google Play badge, Apple device, or competitor branding.

---

## Content Rating
Everyone (see AgeRating_Questionnaire.md)

## Category
Fitness

## Tags (Google Play allows up to 5)
- Workout Tracker
- Gym Log
- Strength Training
- Progressive Overload
- Fitness

---

## Data Safety Section (Google Play Console — complete this manually)

| Data type | Collected? | Purpose | Shared? |
|-----------|-----------|---------|---------|
| Email address | Yes | Account creation / authentication | No |
| User-generated content (workout data) | Yes | App functionality (synced to Firestore) | No |
| App interactions (analytics events) | Yes | Analytics / crash reporting | Firebase (Google) |
| Device identifiers | Yes (Firebase automatic) | Analytics / crash reporting | Firebase (Google) |
| Crash logs | Yes (Crashlytics) | App stability | Firebase (Google) |

**Data is encrypted in transit:** Yes (Firebase/TLS)  
**Users can request data deletion:** Yes (delete account via app)  
**Data collection required for basic app function:** Yes (email for auth)

---

## Short Notes for Play Console Reviewer

The app includes an in-app subscription (Overload Pro) managed via Google Play Billing. The free tier is fully functional without any payment. The paywall is triggered when free-tier limits are reached and can be dismissed. A sandbox test account can be used for review.
