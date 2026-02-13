# PRD: Enhanced Progress Tracking & Charts

**GitHub Issue:** [#262](https://github.com/justbuildstuff-dev/Fitness-App/issues/262)
**Priority:** Medium
**Platform:** Both (iOS & Android)
**Status:** Requirements Gathering
**Created:** 2026-02-13
**BA Agent:** In Progress

---

## Overview

Expand the existing Analytics screen with exercise-specific progress charts, estimated 1RM tracking, muscle group volume breakdowns, configurable workout streak tracking, and PR highlight notifications. This builds on the current analytics foundation (heatmap, key statistics, exercise type charts, PR list) to provide deeper per-exercise insights and trend visualizations.

## User Problem

The current analytics provide aggregate statistics (total volume, workout count, exercise type breakdown) but lack exercise-specific progress tracking. Users cannot see how their bench press has progressed over 3 months, what their estimated 1RM trend looks like, or how their training volume is distributed across muscle groups. This makes it difficult for users to:
1. Verify progressive overload is happening
2. Identify weak muscle groups or imbalanced training
3. Stay motivated through visible progress trends
4. Understand training patterns over time

---

## User Stories

### US-1: View Exercise Progress Chart

As a user tracking my workouts,
I want to see a progress chart for any specific exercise,
so that I can visualize my improvement over time.

**Acceptance Criteria:**
- [ ] User can select any exercise they've logged from a searchable exercise list
- [ ] Chart displays data points over time for the selected exercise
- [ ] Strength exercises show: max weight per session, total volume per session
- [ ] Bodyweight exercises show: max reps per session
- [ ] Cardio/time-based exercises show: duration per session, distance per session (if tracked)
- [ ] Custom exercises show relevant tracked metrics
- [ ] Default time range is last 3 months
- [ ] User can switch between: 1 month, 3 months, 6 months, All time
- [ ] Chart uses line graph with data points
- [ ] Empty state shown if exercise has no logged data in the selected range
- [ ] Works on both iOS and Android

### US-2: View Estimated 1RM on Exercise Charts

As a strength trainee,
I want to see my estimated 1RM trend on exercise progress charts,
so that I can track my theoretical max strength over time without actually maxing out.

**Acceptance Criteria:**
- [ ] Estimated 1RM line displayed on strength exercise progress charts
- [ ] 1RM calculated using Epley formula: `weight * (1 + reps / 30)` as primary
- [ ] Brzycki formula available as alternative: `weight * (36 / (37 - reps))`
- [ ] 1RM calculated from the heaviest set per session (highest weight * reps combination)
- [ ] 1RM line shown as a distinct color/style from actual weight line
- [ ] Only shown for strength exercises (not bodyweight, cardio, or time-based)
- [ ] Only calculated when reps <= 10 (estimates become unreliable above 10 reps)
- [ ] Chart legend clearly labels "Actual Weight" vs "Est. 1RM"

### US-3: View Muscle Group Volume Breakdown

As a user planning balanced training,
I want to see how my training volume is distributed across muscle groups,
so that I can identify imbalances and ensure I'm training all muscle groups adequately.

**Acceptance Criteria:**
- [ ] Pie chart or horizontal bar chart showing volume distribution by muscle group
- [ ] Volume calculated as total sets per muscle group (using exercise library primary muscle group data)
- [ ] 6 muscle groups displayed: Chest, Back, Shoulders, Arms, Legs, Core
- [ ] Each muscle group shows: set count and percentage of total
- [ ] Uses exercise library `MuscleGroup` assignments for library exercises
- [ ] Uses user-assigned `MuscleGroup` for custom exercises
- [ ] Exercises without a muscle group assignment are grouped as "Other"
- [ ] Time range matches the analytics period (default: this month)
- [ ] Color-coded segments for easy visual identification

### US-4: View Training Trends Over Time

As a user wanting to understand my training patterns,
I want to see trend charts for key metrics over weeks and months,
so that I can see whether my training volume, frequency, and consistency are improving.

**Acceptance Criteria:**
- [ ] Line chart showing weekly total volume trend (weight * reps across all exercises)
- [ ] Line chart showing weekly workout frequency (number of workouts per week)
- [ ] Default view: last 3 months of weekly data points
- [ ] User can switch between: 1 month, 3 months, 6 months, All time
- [ ] Trend line or moving average to smooth out week-to-week variance
- [ ] Clear axis labels (weeks on x-axis, metric value on y-axis)
- [ ] Tap on data point to see exact value and date range

### US-5: Configurable Workout Streak Tracking

As a user building consistent workout habits,
I want to set my weekly workout target and track my streak,
so that I can see how consistently I'm meeting my training goals.

**Acceptance Criteria:**
- [ ] User can set a weekly workout target (1-7 workouts per week) in Settings or Analytics
- [ ] Default target: 3 workouts per week
- [ ] Streak counter shows consecutive weeks meeting the target
- [ ] Current streak displayed prominently on Analytics screen (e.g., "12-week streak")
- [ ] Longest streak displayed alongside current streak
- [ ] Visual streak indicator (flame icon or similar) with streak count
- [ ] Streak resets when a calendar week has fewer workouts than the target
- [ ] Streak persists across app restarts (stored in Firestore user preferences)
- [ ] A week with 0 workouts always breaks the streak regardless of target

### US-6: PR Highlight Notifications

As a user who just beat a personal record,
I want to be notified immediately when I set a new PR,
so that I can celebrate the achievement and stay motivated.

**Acceptance Criteria:**
- [ ] When a set is saved that beats a previous PR, show a congratulatory notification/badge
- [ ] PR notification appears inline on the workout screen (not a system notification)
- [ ] Shows: exercise name, PR type (Max Weight, Max Reps, etc.), new value, improvement amount
- [ ] Notification is dismissible
- [ ] New PRs are highlighted in the existing PR list on Analytics with a "NEW" badge
- [ ] PR detection uses existing `PersonalRecord` model and `PRType` enum
- [ ] Supports all 6 PR types: oneRepMax, maxWeight, maxReps, maxVolume, maxDuration, maxDistance

---

## Functional Requirements

### Exercise Progress Charts
- **Exercise Selection**: Searchable list of all exercises the user has logged (across all programs)
- **Chart Type**: Line chart with data points connected by lines
- **Data Aggregation**: One data point per workout session containing that exercise
- **Metrics by Exercise Type**:
  - Strength: Max weight (primary), total volume, est. 1RM
  - Bodyweight: Max reps (primary), total reps
  - Cardio: Distance (primary), duration
  - Time-based: Duration (primary)
  - Custom: All available tracked metrics
- **Time Range Selector**: Segmented control with 1M, 3M, 6M, All options
- **No External Charting Library**: Build charts using Flutter's `CustomPainter` (matching existing pattern)

### 1RM Estimation
- **Primary Formula**: Epley: `1RM = weight * (1 + reps / 30)`
- **Alternative Formula**: Brzycki: `1RM = weight * (36 / (37 - reps))`
- **Input Validation**: Only calculate when reps <= 10 and weight > 0
- **Display**: Overlaid as a second line on exercise progress charts
- **Formula Selection**: Default to Epley; no user-facing toggle in v1 (can add later)

### Muscle Group Volume
- **Data Source**: Exercise library's `primaryMuscleGroup` field + custom exercise muscle groups
- **Volume Metric**: Total sets (not weight-based volume) per muscle group
- **Chart Type**: Horizontal bar chart or pie chart
- **Time Period**: Matches current analytics period

### Training Trends
- **Weekly Aggregation**: Sum total volume and count workouts per calendar week
- **Trend Visualization**: Line chart with weekly data points
- **Smoothing**: Optional 4-week moving average line

### Streak Tracking
- **Storage**: `workoutTarget` field in user preferences (Firestore `users/{userId}` document)
- **Calculation**: Count consecutive calendar weeks where workout count >= target
- **Week Boundary**: Monday-Sunday (ISO 8601)
- **Default**: 3 workouts/week if not configured

### PR Notifications
- **Detection**: Leverage existing `AnalyticsService.checkForNewPR()` method
- **Display**: In-app banner/snackbar on workout screen when PR detected
- **Persistence**: New PRs flagged in PR list for 7 days or until viewed

---

## Non-Functional Requirements

- **Performance**: Exercise progress charts must render within 500ms for up to 1 year of data
- **Caching**: All computed chart data cached for 5 minutes (matching existing analytics cache)
- **Offline**: Charts work with cached data; show "Data may be outdated" indicator when offline
- **Accessibility**: All charts must have text alternatives and meet WCAG AA contrast ratios
- **Platform**: Identical functionality on iOS and Android

---

## User Flow

### Exercise Progress Flow
1. User navigates to Analytics screen
2. New "Exercise Progress" section visible below existing charts
3. User taps "View Exercise Progress" or an exercise name
4. Exercise selection screen with search and filter
5. Chart displays with default 3-month range
6. User can change time range via segmented control
7. Strength exercises show weight line + 1RM line

### Streak Setup Flow
1. User opens Analytics screen
2. Streak section shows current/longest streak with default target (3/week)
3. User taps gear icon or "Set Target" to change weekly target
4. Simple picker/stepper for 1-7 workouts per week
5. Streak recalculates immediately with new target

### PR Notification Flow
1. User completes a set on the workout screen
2. System checks if the set is a new PR via existing `checkForNewPR()` method
3. If PR detected, inline banner appears: "New PR! Bench Press - Max Weight: 100kg (+5kg)"
4. Banner auto-dismisses after 5 seconds or user taps to dismiss
5. PR appears in Analytics PR list with "NEW" badge

---

## Edge Cases

1. **No exercise data**: Show empty state with message "Complete some workouts to see progress charts"
2. **Exercise tracked in only one session**: Show single data point, no connecting line
3. **Exercise name changes**: Use exercise ID (not name) for data continuity
4. **Deleted exercises**: Historical data still available in charts via exerciseId
5. **1RM with high reps (>10)**: Skip 1RM calculation, show "Not applicable for high-rep sets"
6. **Muscle group not assigned**: Group under "Other" category
7. **Custom exercises without muscle group**: Exclude from muscle group chart or show in "Other"
8. **Streak across year boundary**: Streak continues across calendar year changes
9. **User changes streak target**: Recalculate streak from scratch with new target
10. **Week with partial data**: A week is only counted once it's complete (past Sunday) or is the current week
11. **Multiple PRs in one session**: Show all PR notifications sequentially
12. **Very long exercise history (1000+ sessions)**: Paginate or downsample data points for performance

---

## Technical Considerations

### Existing Infrastructure to Leverage
- `AnalyticsService` singleton with caching (5-min TTL)
- `PersonalRecord` model with 6 PR types and Firestore serialization
- `WorkoutAnalytics` model with volume, duration, exercise type breakdown
- `ActivityHeatmapData` with streak calculation (current + longest)
- `DateRange` utility class with common presets
- `MuscleGroup` enum (6 groups: Chest, Back, Shoulders, Arms, Legs, Core)
- `ExerciseType` enum (strength, bodyweight, cardio, time-based, custom)
- `ProgramProvider` with `loadAnalytics()` and `refreshAnalytics()` methods
- Exercise library with 128 exercises including `primaryMuscleGroup` assignments

### New Components Needed
- Exercise progress data model (per-exercise time-series data)
- 1RM calculation utility
- Muscle group volume aggregation
- Configurable streak model (user-set target)
- PR notification widget
- Custom chart painters for line charts and bar charts
- Exercise selection/filter screen for chart viewing

### Data Access Pattern
- All data computed client-side from existing Firestore collections
- No new Firestore collections required (compute from existing sets/exercises/workouts)
- May need new `users/{userId}` fields for streak target preference
- Cache computed chart data in memory (5-min TTL, matching existing pattern)

### UI Integration
- Enhance existing Analytics screen with new sections/tabs
- Keep existing: Monthly Heatmap, Key Statistics, Charts (exercise type breakdown + PRs)
- Add new sections: Exercise Progress, Muscle Group Volume, Training Trends, Streak Tracker
- Consider tab-based navigation if screen becomes too long (Overview / Exercise / Trends)

---

## Success Metrics

- **Adoption**: 60%+ of active users view exercise progress charts within first month
- **Engagement**: Average 2+ exercise charts viewed per analytics visit
- **Streak**: 40%+ of users set a custom streak target within first 2 weeks
- **Retention**: 10% improvement in weekly active user retention
- **PR Engagement**: Users who receive PR notifications return to workout screen 20% more often

---

## Out of Scope (v1)

- Predictive analytics / PR predictions (future enhancement)
- Social sharing of achievements
- Coach/trainer dashboard
- Export charts as images
- Comparison with other users
- Bodyweight tracking / body measurements
- Formula selection UI for 1RM (defaults to Epley)
- Achievement badges/system beyond PR notifications (future enhancement)

---

## Dependencies

- Exercise Library feature (v1.3.0) - provides `MuscleGroup` assignments for library exercises
- Existing PR detection in `AnalyticsService` - provides `checkForNewPR()` method
- Existing analytics infrastructure - provides caching, date ranges, data models

---

## Implementation Notes

This feature builds entirely on existing infrastructure. No new Firestore collections are required - all data is computed client-side from existing sets, exercises, and workouts. The only Firestore change is adding a `workoutTarget` preference field to the user document for configurable streaks.

The existing `AnalyticsService` should be extended with new methods for:
1. Per-exercise time-series data aggregation
2. 1RM calculation from set data
3. Muscle group volume aggregation
4. Configurable streak calculation

Charts should use Flutter's `CustomPainter` to match the existing charting approach (no external library dependency).
