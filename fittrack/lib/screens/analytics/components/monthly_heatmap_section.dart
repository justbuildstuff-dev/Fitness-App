import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/analytics.dart';
import '../../../services/analytics_service.dart';
import 'monthly_calendar_view.dart';

/// Monthly habit tracker section with swipe navigation
///
/// Features:
/// - PageView for swipe navigation between months
/// - Month/year header (tappable to open picker)
/// - Today button (hidden if already on current month)
/// - Heatmap legend and streak cards
/// - Data pre-fetching for smooth navigation
class MonthlyHeatmapSection extends StatefulWidget {
  final String userId;
  final AnalyticsService analyticsService;
  final DateTime? initialMonth; // Optional: defaults to current month

  const MonthlyHeatmapSection({
    super.key,
    required this.userId,
    required this.analyticsService,
    this.initialMonth,
  });

  @override
  State<MonthlyHeatmapSection> createState() => _MonthlyHeatmapSectionState();
}

class _MonthlyHeatmapSectionState extends State<MonthlyHeatmapSection> {
  late PageController _pageController;
  late DateTime _currentMonth;
  late DateTime _initialMonth; // Fixed reference month at _virtualCenter

  // Cache for month data (key: "year_month", value: MonthHeatmapData)
  final Map<String, MonthHeatmapData> _monthCache = {};

  // Loading states
  bool _isLoading = true;
  String? _error;

  // Virtual page index offset (to allow infinite scrolling)
  static const int _virtualCenter = 10000;

  /// Safely adds [months] to [date], handling year boundaries correctly
  DateTime _addMonths(DateTime date, int months) {
    // Calculate total months from year 0
    int totalMonths = date.year * 12 + date.month - 1 + months;

    // Extract year and month
    int newYear = totalMonths ~/ 12;
    int newMonth = (totalMonths % 12) + 1;

    return DateTime(newYear, newMonth, 1);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialDate = widget.initialMonth ?? now;
    _initialMonth = DateTime(initialDate.year, initialDate.month, 1);
    _currentMonth = _initialMonth;
    _pageController = PageController(initialPage: _virtualCenter);
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load initial month data and pre-fetch adjacent months
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadMonthData(_currentMonth);
      await _preloadAdjacentMonths();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load data for a specific month
  Future<void> _loadMonthData(DateTime month) async {
    final cacheKey = '${month.year}_${month.month}';

    // Check if already cached
    if (_monthCache.containsKey(cacheKey)) {
      final cached = _monthCache[cacheKey]!;
      if (cached.isCacheValid) {
        return; // Use cached data
      }
    }

    // Fetch from service
    final data = await widget.analyticsService.getMonthHeatmapData(
      userId: widget.userId,
      year: month.year,
      month: month.month,
    );

    setState(() {
      _monthCache[cacheKey] = data;
    });
  }

  /// Pre-fetch adjacent months for smooth navigation
  Future<void> _preloadAdjacentMonths() async {
    final prevMonth = _addMonths(_currentMonth, -1);
    final nextMonth = _addMonths(_currentMonth, 1);

    await Future.wait([
      _loadMonthData(prevMonth),
      _loadMonthData(nextMonth),
    ]);
  }

  /// Get month for a given page index
  DateTime _getMonthForPageIndex(int index) {
    final offset = index - _virtualCenter;
    // Use _initialMonth as fixed reference, not _currentMonth
    // This prevents drift when navigating between months
    return _addMonths(_initialMonth, offset);
  }

  /// Get cached data for a month
  MonthHeatmapData? _getDataForMonth(DateTime month) {
    final cacheKey = '${month.year}_${month.month}';
    return _monthCache[cacheKey];
  }

  /// Handle page change (swipe)
  void _onPageChanged(int index) {
    final newMonth = _getMonthForPageIndex(index);

    setState(() {
      _currentMonth = newMonth;
    });

    // Pre-fetch adjacent months in background
    _preloadAdjacentMonths();
  }

  /// Navigate to a specific month
  void _navigateToMonth(DateTime month) {
    final targetMonth = DateTime(month.year, month.month, 1);

    // Calculate offset from _initialMonth (the month at _virtualCenter)
    final monthOffset = (targetMonth.year - _initialMonth.year) * 12 +
                        (targetMonth.month - _initialMonth.month);
    final targetPage = _virtualCenter + monthOffset;

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Show month/year picker dialog
  Future<void> _showMonthYearPicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Month',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (selectedDate != null) {
      _navigateToMonth(selectedDate);
    }
  }

  /// Show day popup with set count
  void _showDayPopup(DateTime date) {
    final data = _getDataForMonth(_currentMonth);
    if (data == null) return;

    final setCount = data.getSetCountForDay(date.day);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMMM d, yyyy').format(date)),
        content: Text('$setCount sets completed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildMonthYearHeader(context),
              const SizedBox(height: 8),
              _buildTodayButton(context),
              const SizedBox(height: 16),

              // Content or loading/error state
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Error loading data: $_error',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                )
              else ...[
                _buildPageView(context),
                const SizedBox(height: 16),
                _buildLegend(context),
                const SizedBox(height: 16),
                _buildStreakCards(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final currentData = _getDataForMonth(_currentMonth);
    final totalSets = currentData?.totalSets ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Activity Tracker',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$totalSets sets',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthYearHeader(BuildContext context) {
    return GestureDetector(
      onTap: _showMonthYearPicker,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.calendar_month,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayButton(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year &&
                          _currentMonth.month == now.month;

    if (isCurrentMonth) {
      return const SizedBox.shrink(); // Hide if already on current month
    }

    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.today),
        label: const Text('Today'),
        onPressed: () {
          _navigateToMonth(DateTime(now.year, now.month, 1));
        },
      ),
    );
  }

  Widget _buildPageView(BuildContext context) {
    return SizedBox(
      height: 420, // Fixed height for calendar grid (increased to prevent overflow)
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final month = _getMonthForPageIndex(index);
          final data = _getDataForMonth(month);

          if (data == null) {
            // Data not yet loaded, show loading indicator
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

  Widget _buildLegend(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: 8),
        _buildLegendBox(context, Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)),
        _buildLegendBox(context, primaryColor.withOpacity(0.2)),
        _buildLegendBox(context, primaryColor.withOpacity(0.4)),
        _buildLegendBox(context, primaryColor.withOpacity(0.7)),
        _buildLegendBox(context, primaryColor),
        const SizedBox(width: 8),
        Text(
          'More',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildLegendBox(BuildContext context, Color color) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStreakCards(BuildContext context) {
    // For now, we don't have streak data in MonthHeatmapData
    // This will be added when we integrate with ProgramProvider
    // Using placeholder values
    const currentStreak = 0;
    const longestStreak = 0;

    return Row(
      children: [
        Expanded(
          child: _StreakCard(
            title: 'Current Streak',
            value: '$currentStreak days',
            icon: Icons.local_fire_department,
            color: currentStreak > 0
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StreakCard(
            title: 'Longest Streak',
            value: '$longestStreak days',
            icon: Icons.emoji_events,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

/// Streak information card
class _StreakCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StreakCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
