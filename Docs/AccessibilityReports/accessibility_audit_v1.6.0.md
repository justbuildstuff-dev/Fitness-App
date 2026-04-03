# Accessibility Audit Report — FitTrack v1.6.0
**Date:** 2026-03-19
**Scope:** Full codebase audit (38 screens, 18 widgets)
**Standard:** WCAG 2.1 AA + Apple HIG + Material Design
**Auditor:** Accessibility Audit Agent

## Results Summary

**Overall: PASSED (with non-blocking issues)**

| Check | Status | Notes |
|-------|--------|-------|
| Semantic Labels | ⚠️ | Most interactive elements labelled; 5 specific gaps identified (Medium) |
| Color Contrast | ⚠️ | Theme uses Material ColorScheme correctly; two hardcoded colour uses noted |
| Touch Targets | ⚠️ | SetRow action buttons explicitly constrained to 32×32dp (below 48dp min) |
| Dynamic Text | ✅ | No textScaleFactor overrides found anywhere in the codebase |
| Screen Reader Order | ✅ | Logical flow in all audited screens; modals/dialogs use AlertDialog |
| Motion/Animation | ⚠️ | PRNotificationBanner AnimationController ignores disableAnimations |
| Error Accessibility | ✅ | Errors rendered as visible text; form validators return strings |
| Image Descriptions | ✅ | No Image widgets found; all visuals use Icon widgets (announced by SR) |

---

## Blocking Issues

**None.** No screen reader flow is entirely blocked and no critical user flow is inaccessible without sight.

---

## Non-Blocking Issues

### Medium Severity

**M1 — SetRow action buttons below 48dp touch target minimum**
Files: `fittrack/lib/widgets/set_row.dart` lines 185–233

The checkbox, notes button, and delete button in SetRow are each constrained to `SizedBox(width: 32, height: 32)` with `padding: EdgeInsets.zero`. This puts all three primary set-interaction controls below the Material/HIG 48dp minimum. These appear on every set in every workout — this is a high-frequency interaction surface.

Affected widgets:
- Completion `Checkbox` — `SizedBox(width: 32, height: 32)` with `Transform.scale(scale: 0.9)` (effective ~29dp)
- Notes `IconButton` — `SizedBox(width: 32, height: 32)`, `padding: EdgeInsets.zero`
- Delete `IconButton` — `SizedBox(width: 32, height: 32)`, `padding: EdgeInsets.zero`

Fix: Use `GestureDetector` or `InkWell` with a larger hit area, or `Material` with `InkWell` padding, to expand the tap area without changing visual size.

**M2 — FABs missing tooltip on several screens**
Files:
- `fittrack/lib/screens/programs/programs_screen.dart` line 109
- `fittrack/lib/screens/programs/program_detail_screen.dart` line 262
- `fittrack/lib/screens/weeks/weeks_screen.dart` line 279
- `fittrack/lib/screens/profile/my_exercises_screen.dart` line 116

All four FABs use `Icon(Icons.add)` with no `tooltip` parameter. Screen readers will announce "Button" with no contextual label.

Fix: Add `tooltip: 'Create program'` / `'Add week'` / `'Add exercise'` etc. to each FAB.

**M3 — Password visibility toggle missing tooltip in auth screens**
Files:
- `fittrack/lib/screens/auth/sign_in_screen.dart` line 94
- `fittrack/lib/screens/auth/sign_up_screen.dart` lines 118, 151

Three `IconButton` instances using `Icons.visibility` / `Icons.visibility_off` have no `tooltip`.

Fix: Add `tooltip: 'Show password'` / `'Hide password'`.

**M4 — Month/year picker header uses GestureDetector without Semantics**
File: `fittrack/lib/screens/analytics/components/monthly_heatmap_section.dart` line 285

`_buildMonthYearHeader` wraps a `Row` in a bare `GestureDetector` with no `Semantics` wrapper. Screen readers cannot discover that tapping the month header opens the date picker.

Fix:
```dart
Semantics(
  label: 'Select month and year, currently ${_formattedMonth}',
  button: true,
  child: GestureDetector(...)
)
```

**M5 — Calendar day cells use GestureDetector without Semantics**
File: `fittrack/lib/screens/analytics/components/monthly_calendar_view.dart` line 105

`_buildDayCell` wraps each calendar cell in a `GestureDetector`. Cells with workout data are tappable but carry no semantic label describing the date, set count, or interactive affordance.

Fix:
```dart
Semantics(
  label: '$day ${setCount > 0 ? "$setCount sets logged" : ""}',
  button: setCount > 0,
  child: GestureDetector(...)
)
```

**M6 — _QuickRestButton InkWell touch target below minimum**
File: `fittrack/lib/widgets/set_notes_modal.dart` lines 230–257

Quick rest time chip buttons use `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)` with ~12sp text. Rendered height is approximately 24–28dp — below 48dp spec.

Fix: Increase vertical padding to `EdgeInsets.symmetric(horizontal: 12, vertical: 14)` or use `minimumSize: Size(48, 48)` on the button style.

---

### Low Severity

**L1 — PRNotificationBanner AnimationController ignores reduce-motion preference**
File: `fittrack/lib/widgets/pr_notification_banner.dart` lines 58–71

The slide-in/fade animation controller does not check `MediaQuery.of(context).disableAnimations`.

Fix:
```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
final duration = reduceMotion ? Duration.zero : Duration(milliseconds: 300);
```

**L2 — ExerciseCard InkWell header missing explicit Semantics label**
File: `fittrack/lib/widgets/exercise_card.dart` line 51

The `InkWell` wrapping the exercise card header toggles expand/collapse but has no `Semantics` wrapper. Collapse/expand state is not communicated to screen readers.

**L3 — CircularProgressIndicator instances missing semanticsLabel**
Representative files:
- `fittrack/lib/screens/workouts/consolidated_workout_screen.dart` line 130
- `fittrack/lib/screens/programs/programs_screen.dart` line 32
- `fittrack/lib/screens/auth/sign_in_screen.dart` line 178

Fix: Add `semanticsLabel: 'Loading...'` or contextual equivalent.

**L4 — Superset badge icon not excluded from semantics**
File: `fittrack/lib/widgets/superset_group_card.dart` line 126

`Icon(Icons.link, size: 14)` inside the superset badge is decorative. Screen readers may announce "link" before the "Superset · A" label.

Fix: Wrap in `ExcludeSemantics(child: Icon(...))`.

**L5 — ExerciseCard exercise-type icon not excluded from semantics**
File: `fittrack/lib/widgets/exercise_card.dart` line 72

`Icon(_getExerciseTypeIcon(...))` is decorative alongside the exercise name. Screen readers may announce the icon name (e.g., "fitness center") followed by the exercise name.

Fix: Wrap in `ExcludeSemantics(child: Icon(...))`.

---

## Positives Noted

- **PR Notification Banner**: Correctly uses `Semantics(liveRegion: true)` with a rich label — exemplary implementation.
- **Chart widgets**: Both `LineChartWidget` and `BarChartWidget` wrap custom-painted charts in `Semantics` with descriptive labels. `TimeRangeSelector` also wraps its `SegmentedButton` in `Semantics`.
- **Settings screen theme buttons**: `_ThemeIconButton` correctly uses `Semantics(label: ..., selected: ..., button: true)` — correct toggle semantics.
- **IconButton tooltips**: The vast majority of `IconButton` instances have `tooltip` set — this is well-maintained.
- **Form validation**: All auth forms use `TextFormField` with `validator` callbacks returning visible text. Error state is accessible.
- **No textScaleFactor suppression**: No overrides of system text scaling found anywhere in the codebase.
- **No Image widgets**: The app relies entirely on `Icon` widgets and `CustomPaint` — no complex image accessibility management needed.
- **BottomNavigationBar**: Uses `BottomNavigationBarItem` with `label` on all three items.

---

## Scope Note

All 38 screen files under `fittrack/lib/screens/` and all 18 widget files under `fittrack/lib/widgets/` were audited, plus `fittrack/lib/providers/theme_provider.dart`. The audit covered the complete feature set including the recently added superset/circuit training support (SupersetGroupCard, ConsolidatedWorkoutScreen with FAB menu, ExercisePickerScreen multi-select mode).
