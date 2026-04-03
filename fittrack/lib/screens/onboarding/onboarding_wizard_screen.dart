import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import '../../providers/program_provider.dart';
import '../../services/onboarding_service.dart';
import '../home/home_screen.dart';
import 'onboarding_completion_screen.dart';

/// 4-step guided wizard for creating a first program during onboarding.
///
/// Steps:
///   0 — Name Your Program
///   1 — Create Your First Week
///   2 — Add Your First Workout
///   3 — Add Your First Exercise
///
/// On any skip at step 0 (nothing saved) → markComplete + HomeScreen.
/// On any skip at step 1+ (program exists) → markComplete + HomeScreen.
/// On Finish (step 3) → markComplete + OnboardingCompletionScreen.
///
/// Can also be launched from Settings to create additional programs.
class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // IDs accumulated as each step completes
  String? _programId;
  String? _programName;
  String? _weekId;
  String? _workoutId;

  // Step 0 — Program
  final _programFormKey = GlobalKey<FormState>();
  final _programNameController = TextEditingController();
  final _programDescController = TextEditingController();

  // Step 1 — Week
  final _weekFormKey = GlobalKey<FormState>();
  final _weekNameController = TextEditingController(text: 'Week 1');
  final _weekNotesController = TextEditingController();

  // Step 2 — Workout
  final _workoutFormKey = GlobalKey<FormState>();
  final _workoutNameController = TextEditingController();
  String? _selectedDayOfWeek;

  // Step 3 — Exercise
  final _exerciseFormKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  ExerciseType _selectedExerciseType = ExerciseType.strength;

  static const _daysOfWeek = [
    'Not scheduled',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _programNameController.dispose();
    _programDescController.dispose();
    _weekNameController.dispose();
    _weekNotesController.dispose();
    _workoutNameController.dispose();
    _exerciseNameController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  Future<void> _onSkip() async {
    await OnboardingService.instance.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _onBack() {
    setState(() => _currentStep--);
  }

  Future<void> _onNext() async {
    switch (_currentStep) {
      case 0:
        await _saveProgram();
      case 1:
        await _saveWeek();
      case 2:
        await _saveWorkout();
      case 3:
        await _saveExerciseAndFinish();
    }
  }

  // ─── Step saves ────────────────────────────────────────────────────────────

  Future<void> _saveProgram() async {
    if (!(_programFormKey.currentState?.validate() ?? false)) return;

    final provider = Provider.of<ProgramProvider>(context, listen: false);
    setState(() => _isLoading = true);

    final programId = await provider.createProgram(
      name: _programNameController.text.trim(),
      description: _programDescController.text.trim().isEmpty
          ? null
          : _programDescController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (programId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create program'),
        ),
      );
      return;
    }

    // Mark onboarding complete as soon as a program exists. If the app is
    // force-closed after this point, AuthWrapper will route to HomeScreen
    // instead of re-showing the carousel (fixes bug #427).
    await OnboardingService.instance.markComplete();
    if (!mounted) return;

    setState(() {
      _programId = programId;
      _programName = _programNameController.text.trim();
      _currentStep = 1;
    });
  }

  Future<void> _saveWeek() async {
    if (!(_weekFormKey.currentState?.validate() ?? false)) return;
    if (_programId == null) return;

    final provider = Provider.of<ProgramProvider>(context, listen: false);
    setState(() => _isLoading = true);

    final weekId = await provider.createWeek(
      programId: _programId!,
      name: _weekNameController.text.trim(),
      notes: _weekNotesController.text.trim().isEmpty
          ? null
          : _weekNotesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (weekId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create week'),
        ),
      );
      return;
    }

    setState(() {
      _weekId = weekId;
      _currentStep = 2;
    });
  }

  Future<void> _saveWorkout() async {
    if (!(_workoutFormKey.currentState?.validate() ?? false)) return;
    if (_programId == null || _weekId == null) return;

    final provider = Provider.of<ProgramProvider>(context, listen: false);
    setState(() => _isLoading = true);

    final day = _selectedDayOfWeek == null || _selectedDayOfWeek == 'Not scheduled'
        ? null
        : _daysOfWeek.indexOf(_selectedDayOfWeek!);

    final workoutId = await provider.createWorkout(
      programId: _programId!,
      weekId: _weekId!,
      name: _workoutNameController.text.trim(),
      dayOfWeek: day,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (workoutId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create workout'),
        ),
      );
      return;
    }

    setState(() {
      _workoutId = workoutId;
      _currentStep = 3;
    });
  }

  Future<void> _saveExerciseAndFinish() async {
    if (!(_exerciseFormKey.currentState?.validate() ?? false)) return;
    if (_programId == null || _weekId == null || _workoutId == null) return;

    final provider = Provider.of<ProgramProvider>(context, listen: false);
    setState(() => _isLoading = true);

    final exerciseId = await provider.createExercise(
      programId: _programId!,
      weekId: _weekId!,
      workoutId: _workoutId!,
      name: _exerciseNameController.text.trim(),
      exerciseType: _selectedExerciseType,
      setCount: 3,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (exerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create exercise'),
        ),
      );
      return;
    }

    await OnboardingService.instance.markComplete();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingCompletionScreen(programName: _programName),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'Name Your Program',
      'Create Your First Week',
      'Add Your First Workout',
      'Add Your First Exercise',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Up Your Program',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Semantics(
              label: 'Step ${_currentStep + 1} of 4',
              child: Text(
                'Step ${_currentStep + 1} of 4',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
          ],
        ),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: _isLoading ? null : _onBack,
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stepTitles[_currentStep],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildCurrentStep(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onNext,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_currentStep == 3 ? 'Finish' : 'Next'),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _onSkip,
              child: Text(
                _currentStep == 0 ? 'Skip for now' : 'Skip this step',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildProgramStep();
      case 1:
        return _buildWeekStep();
      case 2:
        return _buildWorkoutStep();
      case 3:
        return _buildExerciseStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Program ────────────────────────────────────────────────────────

  Widget _buildProgramStep() {
    return Form(
      key: _programFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Give your training program a name. You can always rename it later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _programNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Program Name *',
              hintText: 'e.g. Strength Block 1',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a program name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _programDescController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g. 4-day hypertrophy split',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Week ───────────────────────────────────────────────────────────

  Widget _buildWeekStep() {
    return Form(
      key: _weekFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weeks organise your workouts. Start with Week 1 and add more later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _weekNameController,
            decoration: const InputDecoration(
              labelText: 'Week Name *',
              hintText: 'e.g. Week 1',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a week name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weekNotesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. Focus on form',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Workout ────────────────────────────────────────────────────────

  Widget _buildWorkoutStep() {
    return Form(
      key: _workoutFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A workout is a single training session. Add as many workouts per week as you like.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _workoutNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Workout Name *',
              hintText: 'e.g. Push Day',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a workout name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedDayOfWeek,
            decoration: const InputDecoration(
              labelText: 'Day of Week (optional)',
              border: OutlineInputBorder(),
            ),
            items: _daysOfWeek
                .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                .toList(),
            onChanged: (value) => setState(() => _selectedDayOfWeek = value),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Exercise ───────────────────────────────────────────────────────

  Widget _buildExerciseStep() {
    final exerciseTypes = [
      (ExerciseType.strength, 'Strength', Icons.fitness_center),
      (ExerciseType.bodyweight, 'Bodyweight', Icons.accessibility_new),
      (ExerciseType.cardio, 'Cardio', Icons.directions_run),
      (ExerciseType.timeBased, 'Time-based', Icons.timer),
    ];

    return Form(
      key: _exerciseFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your first exercise. 3 default sets will be created. You can add more after.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _exerciseNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Exercise Name *',
              hintText: 'e.g. Bench Press',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an exercise name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Exercise Type',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exerciseTypes.map((entry) {
              final (type, label, icon) = entry;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 4),
                    Text(label),
                  ],
                ),
                selected: _selectedExerciseType == type,
                onSelected: (_) => setState(() => _selectedExerciseType = type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
