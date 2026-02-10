import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/templates/templates.dart';
import '../services/firestore_service.dart';
import '../utils/smart_copy_naming.dart';

/// Maximum templates per type per user
const int maxWorkoutTemplates = 10;
const int maxWeekTemplates = 10;
const int maxProgramTemplates = 10;

/// Provider for managing workout templates and pre-built programs.
///
/// This provider manages multiple data sources:
/// 1. Pre-built programs - fetched from Firestore with caching
/// 2. User templates - real-time sync with Firestore streams
class TemplateProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String? _userId;

  // Pre-built programs (cached from Firestore)
  List<ProgramTemplate> _prebuiltPrograms = [];
  bool _isPrebuiltLoaded = false;
  bool _isLoadingPrebuilt = false;

  // User templates (real-time sync)
  List<WorkoutTemplate> _workoutTemplates = [];
  List<WeekTemplate> _weekTemplates = [];
  List<ProgramTemplate> _programTemplates = [];

  // Stream subscriptions
  StreamSubscription<List<WorkoutTemplate>>? _workoutTemplatesSubscription;
  StreamSubscription<List<WeekTemplate>>? _weekTemplatesSubscription;
  StreamSubscription<List<ProgramTemplate>>? _programTemplatesSubscription;

  // Loading states
  bool _isLoading = false;

  // Error state
  String? _error;

  // Disposed state to prevent notifyListeners after dispose
  bool _disposed = false;

  TemplateProvider(this._userId)
      : _firestoreService = FirestoreService.instance {
    _initialize();
  }

  /// Constructor for testing with dependency injection
  TemplateProvider.withFirestore(this._userId, this._firestoreService) {
    _initialize();
  }

  void _initialize() {
    if (_userId != null && _userId!.isNotEmpty) {
      loadPrebuiltPrograms();
      _subscribeToUserTemplates();
    }
  }

  // ========================================
  // GETTERS
  // ========================================

  List<ProgramTemplate> get prebuiltPrograms =>
      List.unmodifiable(_prebuiltPrograms);
  List<WorkoutTemplate> get workoutTemplates =>
      List.unmodifiable(_workoutTemplates);
  List<WeekTemplate> get weekTemplates => List.unmodifiable(_weekTemplates);
  List<ProgramTemplate> get programTemplates =>
      List.unmodifiable(_programTemplates);

  bool get isPrebuiltLoaded => _isPrebuiltLoaded;
  bool get isLoadingPrebuilt => _isLoadingPrebuilt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Template counts
  int get workoutTemplateCount => _workoutTemplates.length;
  int get weekTemplateCount => _weekTemplates.length;
  int get programTemplateCount => _programTemplates.length;

  // Limit checks
  bool get canSaveWorkoutTemplate =>
      _workoutTemplates.length < maxWorkoutTemplates;
  bool get canSaveWeekTemplate => _weekTemplates.length < maxWeekTemplates;
  bool get canSaveProgramTemplate =>
      _programTemplates.length < maxProgramTemplates;

  // ========================================
  // PRE-BUILT PROGRAMS
  // ========================================

  /// Load pre-built programs from Firestore with caching
  Future<void> loadPrebuiltPrograms() async {
    if (_isPrebuiltLoaded || _isLoadingPrebuilt) return;

    _isLoadingPrebuilt = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _prebuiltPrograms = await _firestoreService.getPrebuiltPrograms();
      _isPrebuiltLoaded = true;
      debugPrint(
          '[TemplateProvider] Loaded ${_prebuiltPrograms.length} prebuilt programs');
    } catch (e) {
      _error = 'Failed to load prebuilt programs: $e';
      debugPrint('[TemplateProvider] Error loading prebuilt programs: $e');
    } finally {
      _isLoadingPrebuilt = false;
      _safeNotifyListeners();
    }
  }

  // ========================================
  // USER TEMPLATES - STREAM SUBSCRIPTIONS
  // ========================================

  /// Subscribe to all user template streams
  void _subscribeToUserTemplates() {
    if (_userId == null || _userId!.isEmpty) return;

    _subscribeToWorkoutTemplates();
    _subscribeToWeekTemplates();
    _subscribeToUserProgramTemplates();
  }

  void _subscribeToWorkoutTemplates() {
    _workoutTemplatesSubscription?.cancel();

    _workoutTemplatesSubscription =
        _firestoreService.getUserWorkoutTemplates(_userId!).listen(
      (templates) {
        _workoutTemplates = templates;
        debugPrint(
            '[TemplateProvider] Loaded ${_workoutTemplates.length} workout templates');
        _safeNotifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load workout templates: $e';
        debugPrint('[TemplateProvider] Error loading workout templates: $e');
        _safeNotifyListeners();
      },
    );
  }

  void _subscribeToWeekTemplates() {
    _weekTemplatesSubscription?.cancel();

    _weekTemplatesSubscription =
        _firestoreService.getUserWeekTemplates(_userId!).listen(
      (templates) {
        _weekTemplates = templates;
        debugPrint(
            '[TemplateProvider] Loaded ${_weekTemplates.length} week templates');
        _safeNotifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load week templates: $e';
        debugPrint('[TemplateProvider] Error loading week templates: $e');
        _safeNotifyListeners();
      },
    );
  }

  void _subscribeToUserProgramTemplates() {
    _programTemplatesSubscription?.cancel();

    _programTemplatesSubscription =
        _firestoreService.getUserProgramTemplates(_userId!).listen(
      (templates) {
        _programTemplates = templates;
        debugPrint(
            '[TemplateProvider] Loaded ${_programTemplates.length} program templates');
        _safeNotifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load program templates: $e';
        debugPrint('[TemplateProvider] Error loading program templates: $e');
        _safeNotifyListeners();
      },
    );
  }

  // ========================================
  // SAVE TEMPLATES
  // ========================================

  /// Save a workout as a template.
  /// Returns the template ID on success, or null on failure.
  Future<String?> saveWorkoutAsTemplate({
    required String name,
    String? description,
    required List<TemplateExercise> exercises,
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return null;
    }

    if (!canSaveWorkoutTemplate) {
      _error =
          'Maximum workout templates reached ($maxWorkoutTemplates). Delete a template to save a new one.';
      _safeNotifyListeners();
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _error = 'Template name cannot be empty';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final template = WorkoutTemplate(
        id: '',
        name: trimmedName,
        description: description?.trim(),
        exercises: exercises,
        createdAt: DateTime.now(),
        userId: _userId!,
        isPrebuilt: false,
      );

      final templateId = await _firestoreService.saveWorkoutTemplate(template);
      debugPrint('[TemplateProvider] Saved workout template: $trimmedName');
      return templateId;
    } catch (e) {
      _error = 'Failed to save workout template: $e';
      debugPrint('[TemplateProvider] Error saving workout template: $e');
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Save a week as a template.
  /// Returns the template ID on success, or null on failure.
  Future<String?> saveWeekAsTemplate({
    required String name,
    String? description,
    required List<TemplateWorkout> workouts,
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return null;
    }

    if (!canSaveWeekTemplate) {
      _error =
          'Maximum week templates reached ($maxWeekTemplates). Delete a template to save a new one.';
      _safeNotifyListeners();
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _error = 'Template name cannot be empty';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final template = WeekTemplate(
        id: '',
        name: trimmedName,
        description: description?.trim(),
        workouts: workouts,
        createdAt: DateTime.now(),
        userId: _userId!,
        isPrebuilt: false,
      );

      final templateId = await _firestoreService.saveWeekTemplate(template);
      debugPrint('[TemplateProvider] Saved week template: $trimmedName');
      return templateId;
    } catch (e) {
      _error = 'Failed to save week template: $e';
      debugPrint('[TemplateProvider] Error saving week template: $e');
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Save a program as a template.
  /// Returns the template ID on success, or null on failure.
  Future<String?> saveProgramAsTemplate({
    required String name,
    String? description,
    required List<TemplateWeek> weeks,
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return null;
    }

    if (!canSaveProgramTemplate) {
      _error =
          'Maximum program templates reached ($maxProgramTemplates). Delete a template to save a new one.';
      _safeNotifyListeners();
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _error = 'Template name cannot be empty';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final template = ProgramTemplate(
        id: '',
        name: trimmedName,
        description: description?.trim(),
        weeks: weeks,
        createdAt: DateTime.now(),
        userId: _userId!,
        isPrebuilt: false,
      );

      final templateId = await _firestoreService.saveProgramTemplate(template);
      debugPrint('[TemplateProvider] Saved program template: $trimmedName');
      return templateId;
    } catch (e) {
      _error = 'Failed to save program template: $e';
      debugPrint('[TemplateProvider] Error saving program template: $e');
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ========================================
  // APPLY TEMPLATES
  // ========================================

  /// Apply a workout template to create a new workout.
  /// Returns the created workout ID on success, or null on failure.
  Future<String?> applyWorkoutTemplate({
    required WorkoutTemplate template,
    required String weekId,
    required String programId,
    String? customName,
    int? orderIndex,
    List<String> existingWorkoutNames = const [],
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Generate a unique name using SmartCopyNaming if no custom name
      final workoutName = customName?.trim().isNotEmpty == true
          ? customName!.trim()
          : SmartCopyNaming.generateCopyName(
              template.name, existingWorkoutNames);

      final workoutId = await _firestoreService.createWorkoutFromTemplate(
        template: template,
        workoutName: workoutName,
        weekId: weekId,
        programId: programId,
        userId: _userId!,
        orderIndex: orderIndex,
      );

      debugPrint('[TemplateProvider] Applied workout template: $workoutName');
      return workoutId;
    } catch (e) {
      _error = 'Failed to apply workout template: $e';
      debugPrint('[TemplateProvider] Error applying workout template: $e');
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Apply a week template to create a new week.
  /// Returns the created week ID on success, or null on failure.
  Future<String?> applyWeekTemplate({
    required WeekTemplate template,
    required String programId,
    required int order,
    String? customName,
    List<String> existingWeekNames = const [],
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Generate a unique name using SmartCopyNaming if no custom name
      final weekName = customName?.trim().isNotEmpty == true
          ? customName!.trim()
          : SmartCopyNaming.generateCopyName(template.name, existingWeekNames);

      final weekId = await _firestoreService.createWeekFromTemplate(
        template: template,
        weekName: weekName,
        order: order,
        programId: programId,
        userId: _userId!,
      );

      debugPrint('[TemplateProvider] Applied week template: $weekName');
      return weekId;
    } catch (e) {
      _error = 'Failed to apply week template: $e';
      debugPrint('[TemplateProvider] Error applying week template: $e');
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Apply a program template to create a new program.
  /// Returns the created program ID on success, or null on failure.
  Future<String?> applyProgramTemplate({
    required ProgramTemplate template,
    String? customName,
    List<String> existingProgramNames = const [],
  }) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Generate a unique name using SmartCopyNaming if no custom name
      final programName = customName?.trim().isNotEmpty == true
          ? customName!.trim()
          : SmartCopyNaming.generateCopyName(
              template.name, existingProgramNames);

      final programId = await _firestoreService.createProgramFromTemplate(
        template: template,
        programName: programName,
        userId: _userId!,
      );

      return programId;
    } catch (e) {
      _error = 'Failed to apply program template: $e';
      debugPrint('[TemplateProvider] Error applying program template: $e');
      return null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ========================================
  // DELETE TEMPLATES
  // ========================================

  /// Delete a workout template.
  /// Returns true on success, false on failure.
  Future<bool> deleteWorkoutTemplate(String templateId) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _firestoreService.deleteWorkoutTemplate(_userId!, templateId);
      debugPrint('[TemplateProvider] Deleted workout template: $templateId');
      return true;
    } catch (e) {
      _error = 'Failed to delete workout template: $e';
      debugPrint('[TemplateProvider] Error deleting workout template: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Delete a week template.
  /// Returns true on success, false on failure.
  Future<bool> deleteWeekTemplate(String templateId) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _firestoreService.deleteWeekTemplate(_userId!, templateId);
      debugPrint('[TemplateProvider] Deleted week template: $templateId');
      return true;
    } catch (e) {
      _error = 'Failed to delete week template: $e';
      debugPrint('[TemplateProvider] Error deleting week template: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Delete a program template.
  /// Returns true on success, false on failure.
  Future<bool> deleteProgramTemplate(String templateId) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _firestoreService.deleteProgramTemplate(_userId!, templateId);
      debugPrint('[TemplateProvider] Deleted program template: $templateId');
      return true;
    } catch (e) {
      _error = 'Failed to delete program template: $e';
      debugPrint('[TemplateProvider] Error deleting program template: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ========================================
  // RENAME TEMPLATES
  // ========================================

  /// Rename a workout template.
  /// Returns true on success, false on failure.
  Future<bool> renameWorkoutTemplate(String templateId, String newName) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return false;
    }

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      _error = 'Template name cannot be empty';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _firestoreService.renameWorkoutTemplate(
          _userId!, templateId, trimmedName);
      debugPrint(
          '[TemplateProvider] Renamed workout template to: $trimmedName');
      return true;
    } catch (e) {
      _error = 'Failed to rename workout template: $e';
      debugPrint('[TemplateProvider] Error renaming workout template: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Rename a week template.
  /// Returns true on success, false on failure.
  Future<bool> renameWeekTemplate(String templateId, String newName) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return false;
    }

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      _error = 'Template name cannot be empty';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _firestoreService.renameWeekTemplate(
          _userId!, templateId, trimmedName);
      debugPrint('[TemplateProvider] Renamed week template to: $trimmedName');
      return true;
    } catch (e) {
      _error = 'Failed to rename week template: $e';
      debugPrint('[TemplateProvider] Error renaming week template: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Rename a program template.
  /// Returns true on success, false on failure.
  Future<bool> renameProgramTemplate(String templateId, String newName) async {
    if (_userId == null || _userId!.isEmpty) {
      _error = 'User not authenticated';
      _safeNotifyListeners();
      return false;
    }

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      _error = 'Template name cannot be empty';
      _safeNotifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _firestoreService.renameProgramTemplate(
          _userId!, templateId, trimmedName);
      debugPrint(
          '[TemplateProvider] Renamed program template to: $trimmedName');
      return true;
    } catch (e) {
      _error = 'Failed to rename program template: $e';
      debugPrint('[TemplateProvider] Error renaming program template: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Get a workout template by ID.
  WorkoutTemplate? getWorkoutTemplateById(String id) {
    try {
      return _workoutTemplates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a week template by ID.
  WeekTemplate? getWeekTemplateById(String id) {
    try {
      return _weekTemplates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a program template by ID.
  ProgramTemplate? getProgramTemplateById(String id) {
    try {
      return _programTemplates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a prebuilt program by ID.
  ProgramTemplate? getPrebuiltProgramById(String id) {
    try {
      return _prebuiltPrograms.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear the error state.
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  // ========================================
  // CLEANUP
  // ========================================

  /// Cancel all subscriptions and clear state.
  void cancelSubscriptions() {
    _workoutTemplatesSubscription?.cancel();
    _weekTemplatesSubscription?.cancel();
    _programTemplatesSubscription?.cancel();

    _workoutTemplatesSubscription = null;
    _weekTemplatesSubscription = null;
    _programTemplatesSubscription = null;

    _workoutTemplates = [];
    _weekTemplates = [];
    _programTemplates = [];
    _error = null;

    debugPrint('[TemplateProvider] Subscriptions canceled');
  }

  @override
  void dispose() {
    if (_disposed) return; // Guard against double-disposal
    _disposed = true;
    cancelSubscriptions();
    super.dispose();
  }

  /// Safely notify listeners only if not disposed.
  /// This prevents errors when async operations complete after dispose.
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
