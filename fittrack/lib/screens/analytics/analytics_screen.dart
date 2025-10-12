import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/analytics.dart';
import '../../providers/program_provider.dart';
import 'components/activity_heatmap_section.dart';
import 'components/key_statistics_section.dart';
import 'components/charts_section.dart';

/// Analytics screen providing comprehensive workout insights
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  @override
  void initState() {
    super.initState();
    // Load analytics data when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgramProvider>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProgramProvider>().refreshAnalytics();
            },
            tooltip: 'Refresh Analytics',
          ),
          PopupMenuButton<DateRange>(
            icon: const Icon(Icons.date_range),
            onSelected: _onDateRangeChanged,
            tooltip: 'Select Date Range',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: DateRange.thisWeek(),
                child: const Text('This Week'),
              ),
              PopupMenuItem(
                value: DateRange.thisMonth(),
                child: const Text('This Month'),
              ),
              PopupMenuItem(
                value: DateRange.last30Days(),
                child: const Text('Last 30 Days'),
              ),
              PopupMenuItem(
                value: DateRange.thisYear(),
                child: const Text('This Year'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProgramProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingAnalytics) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadAnalytics(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Check if we have any data to display
          if (provider.heatmapData == null && provider.currentAnalytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Data Available',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking workouts to see your analytics',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Use the Programs tab to start tracking workouts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.refreshAnalytics();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Heatmap Section
                  if (provider.heatmapData != null)
                    ActivityHeatmapSection(data: provider.heatmapData!),
                  
                  // Key Statistics Section  
                  if (provider.keyStatistics != null)
                    KeyStatisticsSection(statistics: provider.keyStatistics!),
                  
                  // Charts Section
                  if (provider.currentAnalytics != null || provider.recentPRs != null)
                    ChartsSection(
                      analytics: provider.currentAnalytics,
                      personalRecords: provider.recentPRs ?? [],
                    ),
                  
                  // Bottom padding
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDateRangeChanged(DateRange newRange) {
    setState(() {
      // Update analytics with new date range
    });
    
    // Reload analytics with new date range
    context.read<ProgramProvider>().loadAnalytics(dateRange: newRange);
  }
}