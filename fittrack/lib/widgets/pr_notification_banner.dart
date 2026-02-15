import 'dart:async';

import 'package:flutter/material.dart';

import '../models/analytics.dart';

/// An animated banner that slides in from the top to announce a new PR.
///
/// Auto-dismisses after 5 seconds. Tappable to dismiss immediately.
/// Uses `Semantics.liveRegion` for screen reader announcement.
class PRNotificationBanner extends StatefulWidget {
  final PersonalRecord pr;
  final VoidCallback? onDismissed;

  const PRNotificationBanner({
    super.key,
    required this.pr,
    this.onDismissed,
  });

  @override
  State<PRNotificationBanner> createState() => _PRNotificationBannerState();

  /// Shows the PR banner as an overlay on the given context.
  ///
  /// Returns the [OverlayEntry] so callers can remove it if needed.
  static OverlayEntry show(BuildContext context, PersonalRecord pr) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: PRNotificationBanner(
            pr: pr,
            onDismissed: () => entry.remove(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }
}

class _PRNotificationBannerState extends State<PRNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pr = widget.pr;

    final valueStr = _formatValue(pr.value, pr.prType);
    final improvementStr = pr.previousValue != null
        ? ' (+${_formatValue(pr.improvement, pr.prType)})'
        : '';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Semantics(
          liveRegion: true,
          label:
              'New personal record: ${pr.exerciseName}, ${pr.prType.displayName}: $valueStr$improvementStr',
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New PR!',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${pr.exerciseName} - ${pr.prType.displayName}: $valueStr$improvementStr',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.close,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatValue(double value, PRType prType) {
    switch (prType) {
      case PRType.oneRepMax:
      case PRType.maxWeight:
        return '${value.toStringAsFixed(1)}kg';
      case PRType.maxReps:
        return '${value.toInt()} reps';
      case PRType.maxVolume:
        return '${value.toStringAsFixed(0)}kg';
      case PRType.maxDuration:
        final minutes = (value / 60).floor();
        final seconds = (value % 60).toInt();
        return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
      case PRType.maxDistance:
        if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(2)}km';
        }
        return '${value.toStringAsFixed(0)}m';
    }
  }
}
