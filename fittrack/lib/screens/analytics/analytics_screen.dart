import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/navigation_section.dart';
import '../../providers/program_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/error_display.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/pro_gate_widget.dart';
import 'components/overview_tab.dart';
import 'components/exercise_tab.dart';
import 'components/trends_tab.dart';

/// Analytics screen with 3-tab layout: Overview, Exercise, Trends.
class AnalyticsScreen extends StatefulWidget {
  final AnalyticsService? analyticsService;

  const AnalyticsScreen({
    super.key,
    this.analyticsService,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        // Show loading state
        if (provider.isLoadingAnalytics) {
          return Scaffold(
            appBar: _buildAppBar(context, hasTabBar: false),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            ),
            bottomNavigationBar: const GlobalBottomNavBar(
              currentSection: NavigationSection.analytics,
            ),
          );
        }

        // Show error state
        if (provider.error != null) {
          return Scaffold(
            appBar: _buildAppBar(context, hasTabBar: false),
            body: ErrorDisplay(
              message: 'Unable to load analytics data. Please check your connection and try again.',
              technicalError: provider.error,
              onRetry: () {
                final freshProvider = Provider.of<ProgramProvider>(context, listen: false);
                freshProvider.clearError();
                freshProvider.loadAnalytics();
              },
            ),
            bottomNavigationBar: const GlobalBottomNavBar(
              currentSection: NavigationSection.analytics,
            ),
          );
        }

        // Show empty state
        if (provider.monthHeatmapData == null && provider.currentAnalytics == null) {
          return Scaffold(
            appBar: _buildAppBar(context, hasTabBar: false),
            body: Center(
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
            ),
            bottomNavigationBar: const GlobalBottomNavBar(
              currentSection: NavigationSection.analytics,
            ),
          );
        }

        // Show tabbed content
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: _buildAppBar(context, hasTabBar: true),
            body: TabBarView(
              children: [
                OverviewTab(analyticsService: widget.analyticsService),
                const ProGateWidget(
                  paywallHeadline: 'Track every rep\'s progress',
                  child: ExerciseTab(),
                ),
                const ProGateWidget(
                  paywallHeadline: 'See your full training history',
                  child: TrendsTab(),
                ),
              ],
            ),
            bottomNavigationBar: const GlobalBottomNavBar(
              currentSection: NavigationSection.analytics,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, {required bool hasTabBar}) {
    return AppBar(
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
      bottom: hasTabBar
          ? const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.show_chart), text: 'Exercise'),
                Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
              ],
            )
          : null,
    );
  }
}
