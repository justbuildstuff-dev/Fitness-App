# Screenshot Specifications — Overload v1.6.0

> **ARCHIVED (2026-08-02):** Drafted for a native IAP-based Pro subscription that was never actually implemented — the app used Stripe Checkout instead — and monetization has since been parked entirely. Overload is currently free for all users; the "Pro" badge note and the dedicated paywall/pricing screenshot below no longer apply (no screenshots have been captured against this spec yet). Kept for reference in case paid tiers return. See [#472](https://github.com/justbuildstuff-dev/Fitness-App/issues/472) and [#453](https://github.com/justbuildstuff-dev/Fitness-App/issues/453) for context.

Screenshots are the highest-impact ASO element after ratings and reviews. Plan to create 6 screenshots minimum per device size. Prioritise the shots below in order.

---

## Apple App Store Requirements

### Required Device Sizes

| Device | Dimensions | Notes |
|--------|-----------|-------|
| **6.9" iPhone (iPhone 16 Pro Max)** | 1320×2868px | **Required — primary. Shown in search results.** |
| 6.5" iPhone (iPhone 14 Pro Max) | 1242×2688px | Required for older device compatibility |
| 12.9" iPad Pro (if iPad supported) | 2048×2732px | Required only if you list iPad compatibility |

> **Tip:** Create at the 6.9" size first. Use simulator (iPhone 16 Pro Max) or a real device. Scale down for 6.5" — most content is identical.

### Screenshot Rules
- Maximum 10 screenshots per device size
- First screenshot is shown in search results — make it count
- Portrait orientation recommended (matches how users hold phones)
- You MAY add text overlays and device frames (recommended — looks more polished)
- You may NOT use Apple device imagery (iPhone marketing renders) from Apple's website
- Use your own device frames or a tool like [Previewed](https://previewed.app) or [Rottenwood](https://rottenwood.app)

---

## Suggested Screenshot Scenes (Priority Order)

| # | Screen | Headline (text overlay) | Sub-caption | Notes |
|---|--------|------------------------|-------------|-------|
| 1 | **Consolidated Workout Screen** — sets being logged, some checked off | **Log every set, in one place** | Weight, reps, duration — whatever your training needs | Show a realistic PPL workout (Bench Press, OHP, Incline DB — not "Exercise 1") |
| 2 | **Programs list** — showing 2-3 programs with "Start Fresh Week" or week cards | **Structured like real programming** | Programs, blocks, workouts — organised the way you think | Shows the hierarchy that differentiates Overload |
| 3 | **Analytics screen** — heatmap + personal records | **See whether your training's actually working** | Consistency heatmap, PRs, strength trends | Use real-looking data — 4 months of consistent training, 2-3 PRs shown |
| 4 | **Pre-built programs screen** — showing the 5 programs | **Start with an expert-built program** | Push/Pull/Legs, 5x5 Strength, Upper/Lower, and more | Pro feature — add a small "Pro" badge if shown behind paywall |
| 5 | **Analytics — exercise detail / 1RM trend** | **Your PR history, finally visible** | Progress charts and estimated 1RM over time | Pro feature — show the chart with realistic progress |
| 6 | **Dark mode + colour scheme** — Settings or a workout screen in dark mode | **Train your way** | Dark mode, 5 colour schemes built in | Differentiator for users who care about polish |

**Optional additional shots (7-10):**
- Week view showing workouts across Monday–Friday
- Paywall screen (clean, shows pricing clearly — $6.99/mo or $39.99/yr)
- Exercise creation screen (shows custom exercise flow)
- Empty programs screen (onboarding value prop)

---

## Google Play Store Requirements

### Required Assets

| Asset | Dimensions | Notes |
|-------|-----------|-------|
| **Phone screenshots** | 1080×1920px (16:9) minimum | Min 2, max 8. Also accepted: 1080×2340px (19.5:9) |
| **Feature Graphic** | 1024×500px | **Required** — shown at top of Play Store listing page |
| **App icon** | 512×512px | PNG, no transparency (alpha) |

### Feature Graphic Guidance
The feature graphic appears at the top of your Play Store listing. It should:
- Use a dark background (consistent with app's brand)
- Display the "OVERLOAD" wordmark prominently
- Include the tagline "Structured Strength Tracker" in smaller text
- Optionally show 1-2 device mockup screenshots on the right
- Use the app's accent colour (electric blue `#2196F3` or acid green `#39FF14`)
- NOT include the Google Play badge or any store badges

---

## Design Principles

**Do:**
- Use dark theme screenshots — matches the brand and looks better on both stores
- Show realistic, believable workout data (real exercise names, plausible weights/reps)
- Add a clean text overlay at the top or bottom — white text on semi-transparent dark bar
- Use a consistent font (match the app's sans-serif or use Inter/Plus Jakarta Sans)
- Show a PPL or Upper/Lower program — target users will recognise it immediately

**Don't:**
- Use "Exercise 1, Set 1" placeholder data — it looks unfinished
- Cram too much text into overlays — one headline + one sub-caption per screenshot
- Use device bezels for screenshot 1 (they reduce visible content area in search results)
- Show features that aren't in the app (e.g., don't show superset labels if not launched)

---

## Tools for Creating Screenshots

| Tool | Use | Cost |
|------|-----|------|
| iOS Simulator / Android Emulator | Raw screenshots | Free |
| [Previewed.app](https://previewed.app) | Device frames + text overlays | Free tier available |
| [Rottenwood](https://rottenwood.app) | Device frame mockups | Free |
| Canva Pro | Text overlays, brand design | ~$15/mo |
| Figma | Full mockup design (more control) | Free tier available |

**Recommended workflow:** Take raw screenshots in simulator → import into Previewed or Canva → add device frame + text overlay → export at required dimensions.

---

## Screenshot Checklist

- [ ] 6.9" screenshots created (at least 3, ideally 6)
- [ ] 6.5" screenshots created (can be same content, rescaled)
- [ ] Real workout data used (not placeholder text)
- [ ] Text overlays added with clear value proposition
- [ ] Screenshot 1 is the strongest — workout logging in action
- [ ] Dark theme used throughout
- [ ] Feature Graphic created (1024×500px for Play Store)
- [ ] App icon exported as 512×512px PNG for Play Store
