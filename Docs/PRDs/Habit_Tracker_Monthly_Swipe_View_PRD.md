# Product Requirements Document: Habit Tracker Monthly Swipe View

**Feature Name:** Habit Tracker Monthly Swipe View
**Created:** 2024-12-19
**Author:** Business Analyst Agent
**Status:** Requirements Complete
**Priority:** Medium
**Platform:** Android, iOS

---

## Overview

Replace the current habit tracker implementation with a simplified, compact monthly calendar view that uses swipe gestures for navigation. Focus on single-month visibility with larger, more readable cells.

## Problem Statement

The current habit tracker implementation with multiple timeframe options (This Week, This Month, Last 30 Days, This Year) and vertical scrolling through 52 weeks is overly complex for the primary use case of tracking recent activity. Users need a simpler, more focused view that emphasizes the current month with easy navigation.

## Goals

1. **Simplify interface**: Remove complexity of multiple timeframe selectors
2. **Improve readability**: Larger cells showing one month at a time
3. **Enhance navigation**: Intuitive swipe gestures between months
4. **Maintain data tracking**: Continue set-based activity tracking with heatmap visualization

## User Stories

### Primary User Story
**As a user**, I want to view my workout activity in a monthly calendar format, so that I can easily see my progress for the current month and compare with previous months.

### Supporting User Stories

1. **As a user**, I want to swipe left/right between months, so that I can quickly navigate through my workout history
2. **As a user**, I want to see a clear month/year header, so that I know which time period I'm viewing
3. **As a user**, I want larger, more readable cells, so that I can easily see my activity intensity without straining
4. **As a user**, I want to quickly return to today's date, so that I can focus on current activity
5. **As a user**, I want to jump to a specific month, so that I can review activity from any time period
6. **As a user**, I want to tap on a day to see detailed set count, so that I can understand my daily activity

## Requirements

### Functional Requirements

#### FR1: Monthly Calendar View
- Display activity data in a traditional monthly calendar grid
- Show one month at a time (e.g., December 2024)
- 7 columns: Mon, Tue, Wed, Thu, Fri, Sat, Sun (ISO 8601 week start)
- 5-6 rows: Weeks of the month
- Fill grid with adjacent month days (grayed out) for visual continuity
- Larger cells optimized for single-month view

#### FR2: Swipe Navigation
- Swipe left: Move to next month
- Swipe right: Move to previous month
- Smooth swipe animation with PageView or similar
- No limit on past/future navigation (within app data range)

#### FR3: Month Header
- Display month name and year (e.g., "December 2024")
- Centered at top of calendar
- Tappable to open month/year picker

#### FR4: Quick Navigation
- **Today Button**: Button to instantly jump to current month
- **Month Picker**: Tap header to open picker showing month/year selection
  - Allow selection of any month/year
  - Close picker and navigate to selected month

#### FR5: Heatmap Visualization
- Maintain current 5-level intensity coloring:
  - None: 0 sets
  - Low: 1-5 sets
  - Medium: 6-15 sets
  - High: 16-25 sets
  - Very High: 26+ sets
- Use theme-based primary color with opacity variations
- Adjacent month days: Show in grayed-out/dimmed style (no heatmap data)

#### FR6: Day Interaction
- Tap on day cell: Show popup with set count
- Popup content: "X sets completed" (same as current)
- Tap outside popup to dismiss
- No interaction for empty days (0 sets)

#### FR7: Data Aggregation
- **Remove program filter completely**
- Always show aggregated data from all programs
- Set-based tracking: Total completed sets per day (where `checked: true`)

### Non-Functional Requirements

#### NFR1: Performance
- Smooth swipe transitions (60fps)
- Fast month rendering (<100ms)
- Efficient data loading (only load visible month + adjacent months)

#### NFR2: Usability
- Touch targets: Minimum 44x44 points for cells
- Clear visual feedback on swipe
- Intuitive gestures (standard swipe behavior)

#### NFR3: Accessibility
- Screen reader support for day cells
- Semantic labels for navigation controls
- Sufficient color contrast for heatmap colors

### UI/UX Requirements

#### Layout
```
┌─────────────────────────────┐
│      [<] December 2024 [>]  │ ← Header (tappable)
│          [Today ↻]          │ ← Today button
├─────────────────────────────┤
│  Mon Tue Wed Thu Fri Sat Sun│ ← Day labels
├─────────────────────────────┤
│  [•] [•] [•] [•]  1   2   3 │ ← Week 1 (• = prev month)
│   4   5   6   7   8   9  10 │ ← Week 2
│  11  12  13  14  15  16  17 │ ← Week 3
│  18  19  20  21  22  23  24 │ ← Week 4
│  25  26  27  28  29  30  31 │ ← Week 5
│  [•] [•] [•] [•] [•] [•] [•]│ ← Week 6 (• = next month)
├─────────────────────────────┤
│  Less ▢▢▢▢▢ More            │ ← Legend
└─────────────────────────────┘
```

#### Cell Sizing
- Responsive cell width: `(screen_width - padding) / 7`
- Cell height: Match width for square cells
- Minimum cell size: 40x40 points
- Maximum cell size: 60x60 points

#### Colors
- Heatmap: Theme primary color with opacity (0.2, 0.4, 0.7, 1.0)
- Adjacent month days: 50% opacity or distinct gray
- Current day: Subtle border/outline
- Selected day (tapped): Highlight effect

### Technical Requirements

#### TR1: Remove Components
- Delete timeframe selector (This Week, This Month, Last 30 Days, This Year)
- Delete program filter dropdown
- Delete vertical scrolling grid implementation
- Delete month label column (left side)

#### TR2: New Components
- `MonthlyCalendarView` widget
- PageView for swipe navigation
- Month/year picker dialog
- Today button

#### TR3: State Management
- Current displayed month (DateTime)
- Navigation history (optional - for back button)
- No persistence needed (always start at current month)

#### TR4: Data Service
- Fetch data for single month at a time
- Pre-fetch adjacent months for smooth swiping
- Cache recent months to reduce queries

## Acceptance Criteria

### AC1: Monthly Calendar Display
- ✅ Calendar shows one month at a time in traditional grid
- ✅ Days start on Monday (ISO 8601)
- ✅ Adjacent month days visible in grayed-out style
- ✅ Month/year header displays correctly
- ✅ Day labels (Mon-Sun) visible at top

### AC2: Swipe Navigation
- ✅ Swipe left navigates to next month
- ✅ Swipe right navigates to previous month
- ✅ Swipe animation is smooth and responsive
- ✅ Can navigate to any month (past or future within data range)

### AC3: Quick Navigation
- ✅ Today button returns to current month
- ✅ Tapping header opens month/year picker
- ✅ Month picker allows selection of any month
- ✅ Selecting month in picker navigates to that month

### AC4: Heatmap Visualization
- ✅ Cells display correct heatmap intensity colors
- ✅ Current month days show full color intensity
- ✅ Adjacent month days are grayed out/dimmed
- ✅ Legend shows color scale

### AC5: Day Interaction
- ✅ Tapping day cell shows popup with set count
- ✅ Popup displays "X sets completed"
- ✅ Tapping outside dismisses popup
- ✅ Empty days (0 sets) don't show popup

### AC6: Data Accuracy
- ✅ All programs' data is aggregated (no filter)
- ✅ Set counts match database (sum of checked sets per day)
- ✅ Heatmap intensity matches set count thresholds
- ✅ Data updates when navigating between months

### AC7: Removed Features
- ✅ Timeframe selector completely removed
- ✅ Program filter dropdown completely removed
- ✅ Year-view scrolling grid removed
- ✅ Month label column removed

## Out of Scope

- Customizable week start day (fixed to Monday)
- Per-program filtering
- Multiple timeframe views
- Workout detail navigation from calendar
- Edit/add workouts from calendar
- Export calendar data
- Share calendar screenshots

## Dependencies

- Existing `AnalyticsService.generateSetBasedHeatmapData()`
- Existing `ActivityHeatmapData` model
- Existing heatmap color generation
- Flutter `PageView` or `flutter_swiper` package
- Date picker widget (`showDatePicker` or custom)

## Success Metrics

- User engagement: Time spent viewing analytics
- Navigation: Average months viewed per session
- Simplicity: Reduced UI complexity (remove 4 timeframe options + 1 filter)
- Performance: Swipe animation maintains 60fps
- User feedback: Positive sentiment on simplified interface

## Migration Notes

### Breaking Changes
- Complete replacement of existing habit tracker UI
- Users familiar with year-view will need to adapt
- No direct equivalent to "This Week" or "Last 30 Days" views

### Rollout Strategy
1. Implement as complete replacement (no feature flag)
2. Include in release notes as "Simplified habit tracker with monthly view"
3. Monitor user feedback for first 2 weeks
4. Consider adding "year view" back if strong user demand

## Open Questions

None - all requirements gathered and confirmed.

---

**Next Steps:**
1. SA Agent: Create technical design
2. SA Agent: Break down into implementation tasks
3. Developer Agent: Implement features
4. Testing Agent: Validate functionality
5. QA Agent: Manual testing and approval
6. Deployment Agent: Release to production
