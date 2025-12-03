import 'package:flutter/material.dart';
import '../../../models/analytics.dart';
import '../../../models/program.dart';
import 'dynamic_heatmap_calendar.dart';

/// Activity heatmap section with dynamic timeframe selection and program filtering
class ActivityHeatmapSection extends StatefulWidget {
  final ActivityHeatmapData data;
  final HeatmapTimeframe selectedTimeframe;
  final String? selectedProgramId;
  final List<Program> availablePrograms;
  final Function(HeatmapTimeframe) onTimeframeChanged;
  final Function(String?) onProgramFilterChanged;

  const ActivityHeatmapSection({
    super.key,
    required this.data,
    required this.selectedTimeframe,
    required this.selectedProgramId,
    required this.availablePrograms,
    required this.onTimeframeChanged,
    required this.onProgramFilterChanged,
  });

  @override
  State<ActivityHeatmapSection> createState() => _ActivityHeatmapSectionState();
}

class _ActivityHeatmapSectionState extends State<ActivityHeatmapSection> {
  @override
  Widget build(BuildContext context) {
    // Get layout config based on selected timeframe
    final layoutConfig = HeatmapLayoutConfig.forTimeframe(widget.selectedTimeframe);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 16),

              // Timeframe selector
              _buildTimeframeSelector(context),
              const SizedBox(height: 16),

              // Program filter dropdown
              _buildProgramFilter(context),
              const SizedBox(height: 16),

              // Heatmap calendar with dynamic layout
              _buildDynamicHeatmap(context, layoutConfig),

              const SizedBox(height: 16),

              // Streak information
              _buildStreakCards(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          '${widget.data.totalSets} sets completed',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HeatmapTimeframe.values.map((timeframe) {
          final isSelected = timeframe == widget.selectedTimeframe;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(timeframe.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  widget.onTimeframeChanged(timeframe);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgramFilter(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: widget.selectedProgramId,
      decoration: const InputDecoration(
        labelText: 'Filter by Program',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Programs'),
        ),
        ...widget.availablePrograms.map((program) => DropdownMenuItem<String?>(
          value: program.id,
          child: Text(program.name),
        )),
      ],
      onChanged: widget.onProgramFilterChanged,
    );
  }

  Widget _buildDynamicHeatmap(BuildContext context, HeatmapLayoutConfig config) {
    return SizedBox(
      height: config.enableVerticalScroll ? 300 : null,
      child: DynamicHeatmapCalendar(
        data: widget.data,
        config: config,
      ),
    );
  }

  Widget _buildStreakCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StreakCard(
            title: 'Current Streak',
            value: '${widget.data.currentStreak} days',
            icon: Icons.local_fire_department,
            color: widget.data.currentStreak > 0
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StreakCard(
            title: 'Longest Streak',
            value: '${widget.data.longestStreak} days',
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
