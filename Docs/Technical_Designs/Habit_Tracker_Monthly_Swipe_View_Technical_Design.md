# Technical Design: Habit Tracker Monthly Swipe View

**Feature**: Habit Tracker Monthly Swipe View
**GitHub Issue**: [#209](https://github.com/justbuildstuff-dev/Fitness-App/issues/209)
**PRD**: [Habit Tracker Monthly Swipe View PRD](../Feature_PRDs/Habit_Tracker_Monthly_Swipe_View_PRD.md)
**Created**: 2024-12-20
**Status**: Design Phase
**Priority**: Medium
**Platform**: Android, iOS

---

## Overview

Replace the current habit tracker implementation with a simplified monthly calendar view using swipe gestures for navigation. This complete redesign removes the complexity of multiple timeframe selectors and program filtering, focusing on a single-month view with larger, more readable cells and intuitive navigation.

### Problem Statement

The current implementation (from Issue #48) provides four timeframe options (This Week, This Month, Last 30 Days, This Year) with program filtering. User feedback indicates this is overly complex for the primary use case of viewing recent monthly activity. The year-view requires vertical scrolling through 52 weeks, making it difficult to focus on the current month.

### Solution

Implement a PageView-based monthly calendar that displays one month at a time with swipe gestures to navigate between months. Remove all complexity of timeframe selectors and program filters, always showing aggregated data from all programs.

---

## Architecture Changes

### Component Replacement Strategy

This is a **complete replacement** of the existing habit tracker UI, not an enhancement.

#### Components to Remove

1. **Timeframe Selector** (`activity_heatmap_section.dart:90-111`)
   - `_buildTimeframeSelector()` method
   - `HeatmapTimeframe.values` iteration
   - ChoiceChip widgets for This Week/This Month/Last 30 Days/This Year

2. **Program Filter** (`activity_heatmap_section.dart:113-133`)
   - `_buildProgramFilter()` method
   - DropdownButtonFormField widget
   - Program selection logic

3. **Dynamic Layout System** (`dynamic_heatmap_calendar.dart`)
   - `_buildScrollableGrid()` - year view with 52 weeks
   - `_buildStaticGrid()` - week/month views
   - `_buildMonthLabels()` - month labels on left side
   - All timeframe-specific grid logic

4. **Model Support** (`analytics.dart`)
   - `HeatmapTimeframe` enum
   - `HeatmapLayoutConfig` class
   - `DateRange` utility class

#### New Components to Create

1. **MonthlyCalendarView** widget
   - Replaces `DynamicHeatmapCalendar`
   - Single responsibility: render one month's calendar
   - No timeframe/layout switching logic

2. **MonthlyHeatmapSection** widget
   - Replaces `ActivityHeatmapSection`
   - Contains PageView for swipe navigation
   - Month/year header with picker
   - Today button

3. **MonthPageController** (state management)
   - Manages current displayed month
   - Handles month navigation (swipe, picker, today button)
   - Pre-fetches data for adjacent months

---

## Data Flow

### Current Data Flow (Issue #48)

```
User selects timeframe → ProgramProvider.setHeatmapTimeframe()
  → AnalyticsService.generateSetBasedHeatmapData(range, programId)
  → Firestore query filtered by date range and program
  → Build HeatmapLayoutConfig for selected timeframe
  → Render DynamicHeatmapCalendar with adaptive layout
```

### New Data Flow (Monthly Swipe View)

```
User swipes/taps Today/picks month → MonthPageController updates current month
  → AnalyticsService.getMonthHeatmapData(year, month)
  → Firestore query for month (all programs aggregated)
  → Pre-fetch adjacent months (month-1, month+1)
  → Render MonthlyCalendarView for current month
```

### Data Fetching Strategy

**Month Data Model:**
```dart
class MonthHeatmapData {
  final int year;
  final int month;
  final Map<int, int> dailySetCounts; // day of month (1-31) → set count
  final int totalSets;

  // Cached data for efficiency
  final DateTime fetchedAt;

  const MonthHeatmapData({
    required this.year,
    required this.month,
    required this.dailySetCounts,
    required this.totalSets,
    required this.fetchedAt,
  });
}
```

**Caching Strategy:**
- Cache last 3 months of data (current, prev, next)
- Invalidate cache after 5 minutes
- Pre-fetch on swipe start for smoother transitions

---

## Component Design

### 1. MonthlyCalendarView Widget

**File**: `lib/screens/analytics/components/monthly_calendar_view.dart`

**Responsibility**: Render a single month's calendar grid

**Props:**
```dart
class MonthlyCalendarView extends StatelessWidget {
  final MonthHeatmapData data;
  final DateTime displayMonth; // Year + month being displayed
  final Function(DateTime)? onDayTapped;

  const MonthlyCalendarView({
    super.key,
    required this.data,
    required this.displayMonth,
    this.onDayTapped,
  });
}
```

**Layout Algorithm:**
1. Calculate first day of month (e.g., Dec 1, 2024 = Sunday)
2. Calculate Monday of week containing first day
3. Generate 5-6 week rows (35-42 cells)
4. Fill cells:
   - Before month start: Gray out, show previous month days
   - Current month: Show heatmap intensity
   - After month end: Gray out, show next month days

**Cell Sizing:**
- Responsive width: `(screenWidth - padding) / 7`
- Square cells: `height = width`
- Min: 40×40 points
- Max: 60×60 points

**Example Layout (December 2024):**
```
Mon Tue Wed Thu Fri Sat Sun
25  26  27  28  29  30   1  ← Week 1 (Nov 25-Dec 1)
 2   3   4   5   6   7   8  ← Week 2
 9  10  11  12  13  14  15  ← Week 3
16  17  18  19  20  21  22  ← Week 4
23  24  25  26  27  28  29  ← Week 5
30  31   1   2   3   4   5  ← Week 6 (Dec 30-Jan 5)
```

**Adjacent Month Days:**
- Show in 50% opacity or distinct gray
- No heatmap coloring (always gray)
- Still tappable to navigate to that month (future enhancement)

**Current Day Indicator:**
- Subtle border/outline around today's cell
- Only if `displayMonth` matches current month

---

### 2. MonthlyHeatmapSection Widget

**File**: `lib/screens/analytics/components/monthly_heatmap_section.dart`

**Responsibility**: Container for monthly view with navigation

**State:**
```dart
class _MonthlyHeatmapSectionState extends State<MonthlyHeatmapSection> {
  late PageController _pageController;
  late DateTime _currentMonth;

  // Cache for month data
  final Map<String, MonthHeatmapData> _monthCache = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _pageController = PageController(initialPage: _getInitialPageIndex());
    _preloadAdjacentMonths();
  }
}
```

**Layout Structure:**
```dart
Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.all(16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),           // "Activity Tracker" + total sets
            _buildMonthYearHeader(),  // "December 2024" (tappable)
            _buildTodayButton(),      // "Today" button
            _buildDayLabels(),        // Mon Tue Wed Thu Fri Sat Sun
            _buildPageView(),         // PageView with MonthlyCalendarView
            _buildLegend(),           // Less ▢▢▢▢▢ More
            _buildStreakCards(),      // Current/Longest streak
          ],
        ),
      ),
    ),
  );
}
```

**Month/Year Header:**
```dart
Widget _buildMonthYearHeader() {
  return GestureDetector(
    onTap: _showMonthYearPicker,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_currentMonth),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.calendar_month, size: 20),
      ],
    ),
  );
}
```

**PageView Navigation:**
```dart
Widget _buildPageView() {
  return SizedBox(
    height: 380, // Fixed height for calendar grid
    child: PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final month = _getMonthForPageIndex(index);
        final data = _getDataForMonth(month);

        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return MonthlyCalendarView(
          data: data,
          displayMonth: month,
          onDayTapped: _showDayPopup,
        );
      },
    ),
  );
}
```

**Month/Year Picker:**
```dart
Future<void> _showMonthYearPicker() async {
  final selectedDate = await showDatePicker(
    context: context,
    initialDate: _currentMonth,
    firstDate: DateTime(2020, 1),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    helpText: 'Select Month',
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );

  if (selectedDate != null) {
    _navigateToMonth(DateTime(selectedDate.year, selectedDate.month, 1));
  }
}
```

**Today Button:**
```dart
Widget _buildTodayButton() {
  final now = DateTime.now();
  final isCurrentMonth = _currentMonth.year == now.year &&
                          _currentMonth.month == now.month;

  if (isCurrentMonth) {
    return const SizedBox.shrink(); // Hide if already on current month
  }

  return TextButton.icon(
    icon: const Icon(Icons.today),
    label: const Text('Today'),
    onPressed: () {
      _navigateToMonth(DateTime(now.year, now.month, 1));
    },
  );
}
```

---

### 3. Data Service Updates

**File**: `lib/services/analytics_service.dart`

**New Method:**
```dart
/// Generate heatmap data for a specific month (all programs aggregated)
///
/// This method queries all programs and aggregates set counts by day
/// for the specified month. It replaces the timeframe-based approach
/// with a simpler month-specific query.
///
/// Parameters:
/// - [userId]: User ID for data scoping
/// - [year]: Year (e.g., 2024)
/// - [month]: Month (1-12)
///
/// Returns:
/// MonthHeatmapData with daily set counts for the month
Future<MonthHeatmapData> getMonthHeatmapData({
  required String userId,
  required int year,
  required int month,
}) async {
  // Check cache first
  final cacheKey = '$userId-$year-$month';
  final cachedData = _getFromCache(cacheKey);
  if (cachedData != null) return cachedData;

  // Query Firestore for month data
  final monthStart = DateTime(year, month, 1);
  final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

  // Traverse hierarchy: programs → weeks → workouts → exercises → sets
  final allSets = await _fetchSetsInDateRange(
    userId: userId,
    startDate: monthStart,
    endDate: monthEnd,
  );

  // Group sets by day and count checked sets
  final Map<int, int> dailySetCounts = {};
  int totalSets = 0;

  for (final set in allSets) {
    if (set.checked) {
      final day = set.createdAt.day;
      dailySetCounts[day] = (dailySetCounts[day] ?? 0) + 1;
      totalSets++;
    }
  }

  final data = MonthHeatmapData(
    year: year,
    month: month,
    dailySetCounts: dailySetCounts,
    totalSets: totalSets,
    fetchedAt: DateTime.now(),
  );

  // Cache for 5 minutes
  _addToCache(cacheKey, data);

  return data;
}

/// Pre-fetch data for adjacent months to enable smooth swiping
Future<void> prefetchAdjacentMonths({
  required String userId,
  required int year,
  required int month,
}) async {
  // Fetch previous month
  final prevMonth = month == 1 ? 12 : month - 1;
  final prevYear = month == 1 ? year - 1 : year;

  // Fetch next month
  final nextMonth = month == 12 ? 1 : month + 1;
  final nextYear = month == 12 ? year + 1 : year;

  // Fetch both in parallel
  await Future.wait([
    getMonthHeatmapData(userId: userId, year: prevYear, month: prevMonth),
    getMonthHeatmapData(userId: userId, year: nextYear, month: nextMonth),
  ]);
}
```

**Remove Methods:**
```dart
// REMOVE: No longer needed with monthly-only view
// - generateSetBasedHeatmapData() with timeframe parameter
// - DateRange utility methods
// - HeatmapLayoutConfig factory methods
```

---

### 4. State Management Updates

**File**: `lib/providers/program_provider.dart`

**Remove State:**
```dart
// REMOVE: No longer needed
// - HeatmapTimeframe _selectedHeatmapTimeframe
// - String? _selectedHeatmapProgramId
// - setHeatmapTimeframe()
// - setHeatmapProgramFilter()
// - SharedPreferences persistence for timeframe/program
```

**Simplify Analytics Loading:**
```dart
/// Load analytics data (simplified for monthly view only)
Future<void> loadAnalytics() async {
  if (_userId == null) return;

  setLoadingState(isLoadingAnalytics: true);

  try {
    final now = DateTime.now();

    // Fetch current month data
    _monthHeatmapData = await _analyticsService.getMonthHeatmapData(
      userId: _userId!,
      year: now.year,
      month: now.month,
    );

    // Pre-fetch adjacent months
    await _analyticsService.prefetchAdjacentMonths(
      userId: _userId!,
      year: now.year,
      month: now.month,
    );

    // Load other analytics (key stats, PRs, etc.)
    _currentAnalytics = await _analyticsService.getWorkoutAnalytics(
      userId: _userId!,
      startDate: DateTime(now.year, 1, 1),
      endDate: now,
    );

    setLoadingState(isLoadingAnalytics: false);
  } catch (e) {
    setError(e.toString());
    setLoadingState(isLoadingAnalytics: false);
  }
}
```

---

### 5. Model Updates

**File**: `lib/models/analytics.dart`

**Add MonthHeatmapData:**
```dart
/// Heatmap data for a single month
class MonthHeatmapData {
  final int year;
  final int month;
  final Map<int, int> dailySetCounts; // day (1-31) → set count
  final int totalSets;
  final DateTime fetchedAt;

  const MonthHeatmapData({
    required this.year,
    required this.month,
    required this.dailySetCounts,
    required this.totalSets,
    required this.fetchedAt,
  });

  /// Get set count for a specific day of the month
  int getSetCountForDay(int day) {
    return dailySetCounts[day] ?? 0;
  }

  /// Get heatmap intensity for a specific day
  HeatmapIntensity getIntensityForDay(int day) {
    final count = getSetCountForDay(day);
    return HeatmapIntensity.fromSetCount(count);
  }

  /// Check if cache is still valid (5 minutes)
  bool get isCacheValid {
    final now = DateTime.now();
    return now.difference(fetchedAt).inMinutes < 5;
  }
}
```

**Keep:**
- `HeatmapIntensity` enum (still needed for color levels)
- `HeatmapDay` model (used by MonthlyCalendarView)
- `ActivityHeatmapData.currentStreak` / `longestStreak` (still shown in streak cards)

**Remove:**
- `HeatmapTimeframe` enum
- `HeatmapLayoutConfig` class
- `DateRange` utility class

---

## UI/UX Specifications

### Visual Design

**Month/Year Header:**
- Font: Headline Small, Bold
- Color: OnSurface
- Icon: calendar_month (20px)
- Tap feedback: Ripple effect
- Picker: Material DatePicker in calendar-only mode

**Today Button:**
- Style: TextButton with icon
- Icon: today (18px)
- Hidden when already on current month
- Positioned below month/year header

**Day Labels:**
- Font: Label Small (10px)
- Color: OnSurface with 70% opacity
- Fixed width: Match cell width
- Alignment: Center

**Calendar Cells:**
- Size: Responsive (40-60px square)
- Spacing: 2px between cells
- Border radius: 2px
- Current day: 1px border in primary color

**Adjacent Month Days:**
- Background: Surface color (no heatmap)
- Opacity: 50%
- Font color: OnSurface with 40% opacity
- Still shows day number

**Heatmap Colors:**
- none (0 sets): `surfaceContainerHighest`
- low (1-5 sets): `primary.withOpacity(0.2)`
- medium (6-15 sets): `primary.withOpacity(0.4)`
- high (16-25 sets): `primary.withOpacity(0.7)`
- veryHigh (26+ sets): `primary` (full color)

**Day Popup:**
- Same as current implementation
- Material dialog overlay
- Show: "X sets completed"
- Tap outside to dismiss

**Swipe Animation:**
- PageView with smooth transitions
- Swipe velocity threshold: Default PageView behavior
- No bounce on first/last month (within data range)

---

## Performance Considerations

### Data Fetching

**Lazy Loading:**
- Only fetch current month on initial load
- Pre-fetch adjacent months on `initState()`
- Fetch new month on swipe/navigation

**Caching:**
- Keep last 3 months in memory
- Cache invalidation: 5 minutes
- Clear cache on app resume to ensure fresh data

**Firestore Optimization:**
- Query only one month at a time
- Use existing hierarchical traversal
- Leverage composite indexes

### Rendering

**PageView Optimization:**
- Use `PageView.builder` for infinite scrolling
- Only 3 pages kept in memory (prev, current, next)
- Dispose old pages when out of range

**Widget Rebuilds:**
- MonthlyCalendarView is stateless (pure render)
- Month changes trigger new page build, not full rebuild
- Use `const` constructors where possible

---

## Migration Strategy

### Breaking Changes

1. **Remove timeframe selector**: Users lose ability to switch between Week/Month/Year views
2. **Remove program filter**: Users lose ability to filter by specific program
3. **UI paradigm shift**: From scrolling grid to swipe navigation

### User Impact

**Positive:**
- Simpler, more focused interface
- Larger, more readable cells
- Faster navigation with swipes
- Reduced cognitive load

**Negative:**
- Users who frequently checked year-view lose that option
- Users who filtered by program lose that capability
- Potential confusion if not communicated

### Rollout Plan

1. **Version Bump**: Minor version increment (e.g., 1.3.0 → 1.4.0)
2. **Release Notes**: Clearly explain the change
3. **Monitoring**: Track analytics engagement for 2 weeks
4. **Feedback Collection**: Monitor GitHub issues and app reviews
5. **Iteration**: Consider adding year-view back if strong demand

---

## Testing Strategy

### Unit Tests

**MonthHeatmapData Model:**
- ✅ Correctly maps day → set count
- ✅ Returns 0 for days with no data
- ✅ Calculates correct intensity levels
- ✅ Cache validity logic

**AnalyticsService:**
- ✅ `getMonthHeatmapData()` queries correct date range
- ✅ Aggregates sets from all programs
- ✅ Only counts checked sets
- ✅ Groups by day correctly
- ✅ Caching works (cache hit/miss)
- ✅ Pre-fetch loads adjacent months

### Widget Tests

**MonthlyCalendarView:**
- ✅ Renders 5-6 week rows
- ✅ Shows correct day numbers
- ✅ Highlights current day
- ✅ Adjacent month days are grayed out
- ✅ Heatmap colors match intensity
- ✅ Tapping day shows popup
- ✅ Responsive cell sizing

**MonthlyHeatmapSection:**
- ✅ Month/year header displays correctly
- ✅ Tapping header opens picker
- ✅ Today button appears/disappears correctly
- ✅ Swipe left/right changes month
- ✅ PageView navigation updates header
- ✅ Streak cards show correct data

### Integration Tests

**Full User Flows:**
- ✅ Swipe through 6 months (forward and backward)
- ✅ Tap month header → pick month → verify navigation
- ✅ Tap Today button → verify returns to current month
- ✅ Tap day cell → verify popup shows correct set count
- ✅ Data matches Firestore (verify set counts)
- ✅ Pre-fetching improves swipe performance

### Coverage Targets

- **Unit Tests**: 90%+ (models, service logic)
- **Widget Tests**: 85%+ (UI components, interactions)
- **Integration Tests**: Critical user flows (15+ tests)

---

## Implementation Tasks

### Task Breakdown

**Task 1: Create MonthHeatmapData Model**
- Add `MonthHeatmapData` class to `analytics.dart`
- Add helper methods (`getSetCountForDay`, `getIntensityForDay`)
- Write unit tests (10+ tests)
- **Files**: `lib/models/analytics.dart`, `test/models/analytics_test.dart`

**Task 2: Update AnalyticsService**
- Add `getMonthHeatmapData()` method
- Add `prefetchAdjacentMonths()` method
- Implement month-based caching
- Remove timeframe-based methods
- Write unit tests (15+ tests)
- **Files**: `lib/services/analytics_service.dart`, `test/services/analytics_service_test.dart`

**Task 3: Create MonthlyCalendarView Widget**
- Implement calendar grid layout
- Generate 5-6 week rows with adjacent month days
- Apply heatmap colors with intensity levels
- Add current day indicator
- Add day tap handling
- Write widget tests (20+ tests)
- **Files**: `lib/screens/analytics/components/monthly_calendar_view.dart`, `test/screens/analytics/components/monthly_calendar_view_test.dart`

**Task 4: Create MonthlyHeatmapSection Widget**
- Implement PageView with month navigation
- Add month/year header with picker
- Add Today button
- Add day labels and legend
- Add streak cards
- Write widget tests (25+ tests)
- **Files**: `lib/screens/analytics/components/monthly_heatmap_section.dart`, `test/screens/analytics/components/monthly_heatmap_section_test.dart`

**Task 5: Update ProgramProvider**
- Remove timeframe/program filter state
- Simplify `loadAnalytics()` for monthly view
- Remove SharedPreferences persistence
- Update notifyListeners() calls
- Write unit tests (10+ tests)
- **Files**: `lib/providers/program_provider.dart`, `test/providers/program_provider_test.dart`

**Task 6: Integrate MonthlyHeatmapSection into AnalyticsScreen**
- Replace `ActivityHeatmapSection` with `MonthlyHeatmapSection`
- Update data passing (remove timeframe/program props)
- Update error handling
- Write widget tests (5+ tests)
- **Files**: `lib/screens/analytics/analytics_screen.dart`, `test/screens/analytics/analytics_screen_test.dart`

**Task 7: Remove Legacy Code**
- Delete `activity_heatmap_section.dart`
- Delete `dynamic_heatmap_calendar.dart`
- Remove `HeatmapTimeframe` enum from `analytics.dart`
- Remove `HeatmapLayoutConfig` class from `analytics.dart`
- Remove `DateRange` utility from `analytics.dart`
- Update imports across codebase
- **Files**: Multiple files

**Task 8: Integration Tests**
- Write integration test for swipe navigation
- Write integration test for month picker
- Write integration test for Today button
- Write integration test for data accuracy
- Verify all tests pass on CI
- **Files**: `test/integration/habit_tracker_monthly_view_test.dart`

**Task 9: Documentation**
- Update code comments
- Update architecture documentation
- Update component documentation
- Create migration guide
- **Files**: Multiple documentation files

---

## Acceptance Criteria

All acceptance criteria from the PRD must be met:

### AC1: Monthly Calendar Display
- ✅ Calendar shows one month at a time in traditional grid (7 cols × 5-6 rows)
- ✅ Days start on Monday (ISO 8601)
- ✅ Adjacent month days visible in grayed-out style
- ✅ Month/year header displays correctly (e.g., "December 2024")
- ✅ Day labels (Mon-Sun) visible at top

### AC2: Swipe Navigation
- ✅ Swipe left navigates to next month
- ✅ Swipe right navigates to previous month
- ✅ Swipe animation is smooth and responsive (60fps)
- ✅ Can navigate to any month (past or future within data range)

### AC3: Quick Navigation
- ✅ Today button returns to current month
- ✅ Tapping header opens month/year picker
- ✅ Month picker allows selection of any month
- ✅ Selecting month in picker navigates to that month

### AC4: Heatmap Visualization
- ✅ Cells display correct heatmap intensity colors (5 levels)
- ✅ Current month days show full color intensity
- ✅ Adjacent month days are grayed out/dimmed (no heatmap)
- ✅ Legend shows color scale (Less ▢▢▢▢▢ More)

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
- ✅ Timeframe selector completely removed (This Week, This Month, Last 30 Days, This Year)
- ✅ Program filter dropdown completely removed
- ✅ Year-view scrolling grid removed
- ✅ Month label column removed

---

## Open Questions

None - all requirements gathered and confirmed.

---

## References

- **PRD**: [Habit_Tracker_Monthly_Swipe_View_PRD.md](../Feature_PRDs/Habit_Tracker_Monthly_Swipe_View_PRD.md)
- **GitHub Issue**: [#209](https://github.com/justbuildstuff-dev/Fitness-App/issues/209)
- **Previous Implementation**: [Analytics_Habit_Tracker_Enhancement_Technical_Design.md](./Analytics_Habit_Tracker_Enhancement_Technical_Design.md) (Issue #48)
- **Testing Standards**: [TestingFramework.md](../Testing/TestingFramework.md)
- **Code Quality**: `.claude/skills/flutter_code_quality/`

---

**Next Steps:**
1. SA Agent: Create task issues for each implementation task
2. SA Agent: Hand off to Developer Agent
3. Developer Agent: Implement tasks one by one
4. Testing Agent: Validate all tests pass
5. QA Agent: Manual testing on devices
6. Deployment Agent: Release to production
