import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../providers/program_provider.dart';
import '../screens/programs/program_detail_screen.dart';
import '../services/returning_user_service.dart';

/// Shown at the top of the programs list when a user returns after 30+ days
/// of inactivity. Offers "Start Fresh Week" (creates the next week in their
/// last active program) or "Pick Up Here" (navigates to the program).
///
/// Invisible (SizedBox.shrink) when conditions are not met.
class ReturningUserBanner extends StatefulWidget {
  const ReturningUserBanner({super.key});

  @override
  State<ReturningUserBanner> createState() => _ReturningUserBannerState();
}

class _ReturningUserBannerState extends State<ReturningUserBanner> {
  bool _dismissed = false;
  bool _isCreatingWeek = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !ReturningUserService.shouldShowPrompt) {
      return const SizedBox.shrink();
    }

    final provider = Provider.of<ProgramProvider>(context, listen: false);
    final programId = ReturningUserService.lastActiveProgramId;
    final Program? program = programId == null
        ? null
        : provider.programs.cast<Program?>().firstWhere(
              (p) => p?.id == programId,
              orElse: () => null,
            );

    if (program == null) {
      // Program was deleted — silently dismiss so the banner doesn't reappear.
      ReturningUserService.dismiss();
      return const SizedBox.shrink();
    }

    final days = ReturningUserService.daysSinceLastWorkout;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand_outlined,
                    color: colorScheme.onPrimaryContainer, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Dismiss',
                  onPressed: _dismiss,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'You last trained $days days ago. "${program.name}" is ready when you are.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _isCreatingWeek
                        ? null
                        : () => _startFreshWeek(provider, program),
                    child: _isCreatingWeek
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Start Fresh Week'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      side: BorderSide(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.4)),
                    ),
                    onPressed: () => _pickUpHere(program),
                    child: const Text('Pick Up Here'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _dismiss() {
    ReturningUserService.dismiss();
    setState(() => _dismissed = true);
  }

  void _pickUpHere(Program program) {
    _dismiss();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program)),
    );
  }

  Future<void> _startFreshWeek(
    ProgramProvider provider,
    Program program,
  ) async {
    setState(() => _isCreatingWeek = true);

    final weekId =
        await provider.createWeekForProgram(programId: program.id);

    if (!mounted) return;
    setState(() => _isCreatingWeek = false);

    if (weekId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not create week. Please try again.')),
      );
      return;
    }

    _dismiss();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program)),
    );
  }
}
