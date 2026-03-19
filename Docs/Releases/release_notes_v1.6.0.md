# Release Notes — FitTrack v1.6.0

**Release Date:** 2026-03-19
**Version:** 1.6.0 (Build 7)
**Platforms:** Android + iOS
**GitHub Issue:** #261

---

## What's New

### Superset Training Support

FitTrack now supports superset training — the technique where you perform two or more exercises back-to-back before resting. Whether you follow a PPL split, a hypertrophy program, or just want to make your workouts more efficient, you can now build and track supersets directly in the app.

---

## How It Works

### Adding a Superset

Tap the **+** button on any workout screen. You'll now see two options:

- **Add Exercise** — works exactly as before
- **Add Superset** — opens the exercise picker in multi-select mode

In multi-select mode, tap any exercises you want to group together (minimum 2). Choose how many sets you want for each exercise, then tap **Add**.

### Visual Grouping

Superset exercises appear together in a distinct card with a coloured header. Each exercise is labelled by its position in the group:

- **A1**, **A2** for the first superset
- **B1**, **B2** for the second superset
- And so on through A, B, C…

Standalone exercises look exactly as they always have.

### Reordering

- Drag the handle on the group card header to reorder the entire group relative to other exercises
- Drag individual exercise handles within the group card to swap which exercise is A1 and which is A2

### Deleting a Superset

Tap the three-dot menu on the group card header and choose **Delete Superset**. You'll be asked to confirm before the group and all its exercises and sets are removed.

### Logging Sets

Nothing changes about how you log sets. Each exercise in a superset group shows its sets inline, and you add, edit, and check off sets exactly as you do for standalone exercises.

---

## Technical Details

- Superset groups are identified by a shared ID stored on each exercise — no new collections or data structures required
- Week duplication preserves superset group structure
- Saving a workout as a template preserves superset group membership
- All existing workouts display identically — this feature only activates when you explicitly create a superset

---

## Bug Fixes & Improvements

None in this release — superset support is the sole focus of v1.6.0.

---

## Known Limitations (v1)

- You cannot add or remove individual exercises from an existing superset group — delete the group and re-create it
- Rest timers are not group-aware (no automatic rest after completing all exercises in a superset)
- Alternating set logging (log A1 set → A2 set → rest → repeat) is not guided by the UI
