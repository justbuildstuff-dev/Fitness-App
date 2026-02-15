import 'package:flutter/material.dart';

import '../../models/analytics.dart';

/// Time range options for analytics charts
enum TimeRange {
  oneMonth,
  threeMonths,
  sixMonths,
  allTime;

  String get label {
    switch (this) {
      case TimeRange.oneMonth:
        return '1M';
      case TimeRange.threeMonths:
        return '3M';
      case TimeRange.sixMonths:
        return '6M';
      case TimeRange.allTime:
        return 'All';
    }
  }

  DateRange toDateRange() {
    switch (this) {
      case TimeRange.oneMonth:
        return DateRange.lastMonth();
      case TimeRange.threeMonths:
        return DateRange.last3Months();
      case TimeRange.sixMonths:
        return DateRange.last6Months();
      case TimeRange.allTime:
        return DateRange.allTime();
    }
  }
}

/// A Material 3 segmented button control for selecting time ranges.
///
/// Options: 1M, 3M, 6M, All. Default: 3M.
/// Calls [onChanged] with the corresponding [DateRange].
class TimeRangeSelector extends StatelessWidget {
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  const TimeRangeSelector({
    super.key,
    this.selected = TimeRange.threeMonths,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Time range selector, currently ${selected.label}',
      child: SegmentedButton<TimeRange>(
        segments: TimeRange.values.map((range) {
          return ButtonSegment<TimeRange>(
            value: range,
            label: Text(range.label),
          );
        }).toList(),
        selected: {selected},
        onSelectionChanged: (selection) {
          onChanged(selection.first);
        },
        showSelectedIcon: false,
      ),
    );
  }
}
