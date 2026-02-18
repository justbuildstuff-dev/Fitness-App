# FitTrack v1.5.0 Release Notes

**Release Date:** 2026-02-18
**Version:** 1.5.0+6
**Platforms:** Android, iOS

## What's New

### Enhanced Progress Tracking & Charts

FitTrack v1.5.0 brings powerful progress visualization tools to help you see exactly how your training is paying off. Track individual exercises over time, visualize your estimated strength, understand your training balance, and stay motivated with streaks and PR celebrations.

### Exercise Progress Charts

See how any exercise has progressed over weeks and months:

- **Select any exercise** you've logged and view a detailed line chart
- **Strength exercises** show max weight per session with estimated 1RM overlay
- **Bodyweight exercises** show max reps per session
- **Cardio exercises** show distance and duration trends
- **Time range selector** -- view 1 month, 3 months, 6 months, or all time

**How to use:** Analytics > Exercise tab > Search for an exercise > View chart

### Estimated 1RM Tracking

Track your theoretical max strength without actually maxing out:

- **Epley formula** calculates your estimated one-rep max from your working sets
- **Dual-line chart** clearly distinguishes "Actual Weight" vs "Est. 1RM"
- Only calculated for sets of 10 reps or fewer (where estimates are reliable)
- Watch your estimated strength trend upward as you get stronger

### Muscle Group Volume Breakdown

Understand how balanced your training really is:

- **Horizontal bar chart** shows total sets per muscle group
- **Six muscle groups** tracked: Chest, Back, Shoulders, Arms, Legs, Core
- **Percentage breakdown** reveals training imbalances at a glance
- Uses exercise library muscle group assignments for accurate tracking

**How to use:** Analytics > Trends tab > Muscle Group Volume section

### Training Trends

Visualize your consistency and volume over time:

- **Weekly volume trend** -- total training volume (weight x reps) per week
- **Weekly frequency** -- number of workouts per week
- **Moving average** smooths out week-to-week variance
- See whether your training commitment is growing, steady, or declining

**How to use:** Analytics > Trends tab > Volume and Frequency charts

### Configurable Workout Streaks

Set your weekly training goal and track your consistency:

- **Set your target** -- 1 to 7 workouts per week (default: 3)
- **Current streak** -- consecutive weeks meeting your target
- **Longest streak** -- your all-time best consistency record
- **Streak indicator** with flame icon for motivation
- Change your target anytime -- streak recalculates automatically

**How to use:** Analytics > Overview tab > Streak section > Tap gear to set target

### PR Celebration Notifications

Get instant recognition when you beat a personal record:

- **Inline banner** appears on the workout screen when you set a new PR
- Shows exercise name, PR type, new value, and improvement amount
- **Auto-dismisses** after 5 seconds or tap to dismiss
- Supports all PR types: Max Weight, Max Reps, Max Volume, 1RM, Duration, Distance
- **"NEW" badge** highlights recent PRs in the Analytics PR list

## Benefits

- **See Your Progress** -- Visual proof that your training is working
- **Train Smarter** -- Identify weak muscle groups and fix imbalances
- **Stay Consistent** -- Streak tracking builds the workout habit
- **Stay Motivated** -- PR notifications celebrate your achievements instantly
- **Make Better Decisions** -- Data-driven insights for your training

## Bug Fixes

- Fixed PR notification not triggering after set creation (#366)
- Fixed exercise chart legend label from 'Weight' to 'Actual Weight' (#367)
- Fixed flaky streak calculation tests related to calendar week boundaries

## Technical Improvements

### Analytics Enhancement (#262)
- New 3-tab analytics layout: Overview, Exercise, Trends
- Exercise progress data aggregation with per-exercise time-series
- 1RM calculation utility (Epley formula) with rep-count validation
- Muscle group volume aggregation from exercise library data
- Configurable streak model with user-set weekly target
- Custom chart painters (LineChartWidget, BarChartWidget) using Flutter CustomPainter
- Searchable exercise picker with exercise type filtering
- PR notification banner with navigator overlay persistence pattern
- All computed chart data cached (5-min TTL, matching existing pattern)

### Code Quality
- 1,446 automated tests passing (805 unit + 579 widget + 48 integration + 14 performance)
- No security vulnerabilities
- Comprehensive error handling across all new components

## Known Issues

None at this time.

## Upgrade Notes

This update is fully backward compatible. Existing programs, workouts, and analytics data are not affected. The new analytics features automatically populate from your existing workout history -- no action needed.

The only new data stored is your streak target preference (defaults to 3 workouts/week). All chart data is computed client-side from existing Firestore collections.

---

**GitHub Issue:** [#262 - Enhanced Progress Tracking & Charts](https://github.com/justbuildstuff-dev/Fitness-App/issues/262)
**Technical Design:** [Enhanced Progress Tracking Technical Design](https://github.com/justbuildstuff-dev/Fitness-App/blob/main/Docs/Technical_Designs/Enhanced_Progress_Tracking_Technical_Design.md)

## Implementation Tasks Completed

- Task #349: AnalyticsService extension methods (per-exercise data, 1RM, muscle group, streak)
- Task #350: Exercise progress and 1RM data models
- Task #351: ProgramProvider analytics extensions
- Task #352: CustomPainter chart widgets (LineChartWidget, BarChartWidget)
- Task #353: 3-tab analytics screen layout (Overview, Exercise, Trends)
- Task #354: Searchable exercise picker and progress chart section
- Task #355: Muscle group volume and training trends components
- Task #356: Configurable streak section and PR notification banner
- Bugfix #366: PR notification wired to CreateSetScreen
- Bugfix #367: Exercise chart legend label fix
