import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/program_provider.dart';
import '../../../services/analytics_service.dart';
import 'monthly_heatmap_section.dart';
import 'key_statistics_section.dart';
import 'charts_section.dart';

/// Overview tab displaying existing analytics content:
/// monthly heatmap, key statistics, and exercise/PR charts.
class OverviewTab extends StatefulWidget {
  final AnalyticsService? analyticsService;

  const OverviewTab({super.key, this.analyticsService});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () => provider.refreshAnalytics(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Heatmap Section with swipe navigation
                if (provider.monthHeatmapData != null &&
                    provider.userId != null)
                  MonthlyHeatmapSection(
                    userId: provider.userId!,
                    analyticsService:
                        widget.analyticsService ?? AnalyticsService.instance,
                  ),

                // Key Statistics Section
                if (provider.keyStatistics != null)
                  KeyStatisticsSection(statistics: provider.keyStatistics!),

                // Charts Section
                if (provider.currentAnalytics != null ||
                    provider.recentPRs != null)
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
    );
  }
}
