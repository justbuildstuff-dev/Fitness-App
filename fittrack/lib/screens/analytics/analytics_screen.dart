import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/error_display.dart';
import 'components/monthly_heatmap_section.dart';
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

    // No need to manually load analytics - ProgramProvider auto-loads when userId is set
    // Removed manual loadAnalytics() call to prevent race condition
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
            return ErrorDisplay(
              message: 'Unable to load analytics data. Please check your connection and try again.',
              technicalError: provider.error,
              onRetry: () {
                // Get fresh provider reference in case it was recreated
                final freshProvider = Provider.of<ProgramProvider>(context, listen: false);
                freshProvider.clearError();
                freshProvider.loadAnalytics();
              },
            );
          }

          // Check if we have any data to display
          if (provider.monthHeatmapData == null && provider.currentAnalytics == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                  // Monthly Heatmap Section with swipe navigation
                  if (provider.monthHeatmapData != null && provider.userId != null)
                    MonthlyHeatmapSection(
                      userId: provider.userId!,
                      analyticsService: AnalyticsService.instance,
                    ),

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
}
