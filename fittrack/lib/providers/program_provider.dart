import 'dart:async';
import 'package:flutter/material.dart';
import '../models/program.dart';
import '../models/week.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../services/firestore_service.dart';

class ProgramProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final String? _userId;

  ProgramProvider(this._userId);

  // Programs
  List<Program> _programs = [];
  Program? _selectedProgram;
  bool _isLoadingPrograms = false;
  String? _error;

  // Weeks
  List<Week> _weeks = [];
  Week? _selectedWeek;
  bool _isLoadingWeeks = false;

  // Workouts
  List<Workout> _workouts = [];
  Workout? _selectedWorkout;
  bool _isLoadingWorkouts = false;

  // Exercises
  List<Exercise> _exercises = [];
  Exercise? _selectedExercise;
  bool _isLoadingExercises = false;

  // Sets
  List<ExerciseSet> _sets = [];
  bool _isLoadingSets = false;

  // Stream subscriptions for cleanup
  StreamSubscription<List<Program>>? _programsSubscription;
  StreamSubscription<List<Week>>? _weeksSubscription;
  StreamSubscription<List<Workout>>? _workoutsSubscription;
  StreamSubscription<List<Exercise>>? _exercisesSubscription;
  StreamSubscription<List<ExerciseSet>>? _setsSubscription;

  // Getters
  List<Program> get programs => _programs;
  Program? get selectedProgram => _selectedProgram;
  bool get isLoadingPrograms => _isLoadingPrograms;
  String? get error => _error;

  List<Week> get weeks => _weeks;
  Week? get selectedWeek => _selectedWeek;
  bool get isLoadingWeeks => _isLoadingWeeks;

  List<Workout> get workouts => _workouts;
  Workout? get selectedWorkout => _selectedWorkout;
  bool get isLoadingWorkouts => _isLoadingWorkouts;

  List<Exercise> get exercises => _exercises;
  Exercise? get selectedExercise => _selectedExercise;
  bool get isLoadingExercises => _isLoadingExercises;

  List<ExerciseSet> get sets => _sets;
  bool get isLoadingSets => _isLoadingSets;

  /// Get current sets (convenience method)
  List<ExerciseSet> getCurrentSets() => _sets;

  /// General loading state (true if any operation is loading)
  bool get isLoading => _isLoadingPrograms || _isLoadingWeeks || _isLoadingWorkouts || _isLoadingExercises || _isLoadingSets;

  // ========================================
  // PROGRAM OPERATIONS
  // ========================================

  /// Load all programs for the user
  void loadPrograms() {
    if (_userId == null) return;

    _isLoadingPrograms = true;
    _error = null;
    notifyListeners();

    // Cancel previous subscription
    _programsSubscription?.cancel();
    
    _programsSubscription = _firestoreService.getPrograms(_userId!).listen(
      (programs) {
        _programs = programs;
        _isLoadingPrograms = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load programs: $error';
        _isLoadingPrograms = false;
        notifyListeners();
      },
    );
  }

  /// Create a new program
  Future<String?> createProgram({
    required String name,
    String? description,
  }) async {
    if (_userId == null) return null;

    try {
      _error = null;
      notifyListeners();

      final program = Program(
        id: '',
        name: name.trim(),
        description: description?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _userId!,
      );

      final programId = await _firestoreService.createProgram(program);
      return programId;
    } catch (e) {
      _error = 'Failed to create program: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a program
  Future<bool> updateProgram(Program program) async {
    try {
      _error = null;
      notifyListeners();

      final updatedProgram = program.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateProgram(updatedProgram);
      return true;
    } catch (e) {
      _error = 'Failed to update program: $e';
      notifyListeners();
      return false;
    }
  }

  /// Archive a program
  Future<bool> archiveProgram(String programId) async {
    if (_userId == null) return false;

    try {
      _error = null;
      notifyListeners();

      await _firestoreService.archiveProgram(_userId!, programId);
      return true;
    } catch (e) {
      _error = 'Failed to archive program: $e';
      notifyListeners();
      return false;
    }
  }

  /// Select a program and load its weeks
  void selectProgram(Program program) {
    _selectedProgram = program;
    _weeks = [];
    _selectedWeek = null;
    _workouts = [];
    _selectedWorkout = null;
    _exercises = [];
    _selectedExercise = null;
    _sets = [];
    notifyListeners();

    loadWeeks(program.id);
  }

  // ========================================
  // WEEK OPERATIONS
  // ========================================

  /// Load weeks for the selected program
  void loadWeeks(String programId) {
    if (_userId == null) return;

    _isLoadingWeeks = true;
    _error = null;
    notifyListeners();

    // Cancel previous subscription
    _weeksSubscription?.cancel();
    
    _weeksSubscription = _firestoreService.getWeeks(_userId!, programId).listen(
      (weeks) {
        _weeks = weeks;
        _isLoadingWeeks = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load weeks: $error';
        _isLoadingWeeks = false;
        notifyListeners();
      },
    );
  }

  /// Create a new week
  Future<String?> createWeek({
    required String programId,
    required String name,
    String? notes,
  }) async {
    if (_userId == null) return null;

    try {
      _error = null;
      notifyListeners();

      // Calculate next order
      final nextOrder = _weeks.isEmpty 
          ? 1 
          : _weeks.map((w) => w.order).reduce((a, b) => a > b ? a : b) + 1;

      final week = Week(
        id: '',
        name: name.trim(),
        order: nextOrder,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _userId!,
        programId: programId,
      );

      final weekId = await _firestoreService.createWeek(week);
      return weekId;
    } catch (e) {
      _error = 'Failed to create week: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a week
  Future<bool> updateWeek(Week week) async {
    try {
      _error = null;
      notifyListeners();

      final updatedWeek = week.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateWeek(updatedWeek);
      return true;
    } catch (e) {
      _error = 'Failed to update week: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a week
  Future<bool> deleteWeek(String programId, String weekId) async {
    if (_userId == null) return false;

    try {
      _error = null;
      notifyListeners();

      await _firestoreService.deleteWeek(_userId!, programId, weekId);
      return true;
    } catch (e) {
      _error = 'Failed to delete week: $e';
      notifyListeners();
      return false;
    }
  }

  /// Duplicate a week
  Future<Map<String, dynamic>?> duplicateWeek({
    required String programId,
    required String weekId,
  }) async {
    if (_userId == null) return null;

    try {
      _error = null;
      notifyListeners();

      final result = await _firestoreService.duplicateWeek(
        userId: _userId!,
        programId: programId,
        weekId: weekId,
      );

      return result;
    } catch (e) {
      _error = 'Failed to duplicate week: $e';
      notifyListeners();
      return null;
    }
  }

  /// Select a week and load its workouts
  void selectWeek(Week week) {
    _selectedWeek = week;
    _workouts = [];
    _selectedWorkout = null;
    _exercises = [];
    _selectedExercise = null;
    _sets = [];
    notifyListeners();

    loadWorkouts(week.programId, week.id);
  }

  // ========================================
  // WORKOUT OPERATIONS
  // ========================================

  /// Load workouts for the selected week
  void loadWorkouts(String programId, String weekId) {
    if (_userId == null) return;

    _isLoadingWorkouts = true;
    _error = null;
    notifyListeners();

    // Cancel previous subscription
    _workoutsSubscription?.cancel();
    
    _workoutsSubscription = _firestoreService.getWorkouts(_userId!, programId, weekId).listen(
      (workouts) {
        _workouts = workouts;
        _isLoadingWorkouts = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load workouts: $error';
        _isLoadingWorkouts = false;
        notifyListeners();
      },
    );
  }

  /// Create a new workout
  Future<String?> createWorkout({
    required String programId,
    required String weekId,
    required String name,
    int? dayOfWeek,
    String? notes,
  }) async {
    if (_userId == null) return null;

    try {
      _error = null;
      notifyListeners();

      // Calculate next order index
      final nextOrderIndex = _workouts.isEmpty 
          ? 0 
          : _workouts.map((w) => w.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

      final workout = Workout(
        id: '',
        name: name.trim(),
        dayOfWeek: dayOfWeek,
        orderIndex: nextOrderIndex,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _userId!,
        weekId: weekId,
        programId: programId,
      );

      final workoutId = await _firestoreService.createWorkout(workout);
      return workoutId;
    } catch (e) {
      _error = 'Failed to create workout: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a workout
  Future<bool> updateWorkout(Workout workout) async {
    try {
      _error = null;
      notifyListeners();

      final updatedWorkout = workout.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateWorkout(updatedWorkout);
      return true;
    } catch (e) {
      _error = 'Failed to update workout: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(
    String programId,
    String weekId,
    String workoutId,
  ) async {
    if (_userId == null) return false;

    try {
      _error = null;
      notifyListeners();

      await _firestoreService.deleteWorkout(_userId!, programId, weekId, workoutId);
      return true;
    } catch (e) {
      _error = 'Failed to delete workout: $e';
      notifyListeners();
      return false;
    }
  }

  /// Select a workout and load its exercises
  void selectWorkout(Workout workout) {
    _selectedWorkout = workout;
    _exercises = [];
    _selectedExercise = null;
    _sets = [];
    notifyListeners();

    loadExercises(workout.programId, workout.weekId, workout.id);
  }

  // ========================================
  // EXERCISE OPERATIONS
  // ========================================

  /// Load exercises for the selected workout
  void loadExercises(String programId, String weekId, String workoutId) {
    if (_userId == null) return;

    _isLoadingExercises = true;
    _error = null;
    notifyListeners();

    _firestoreService.getExercises(_userId!, programId, weekId, workoutId).listen(
      (exercises) {
        _exercises = exercises;
        _isLoadingExercises = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load exercises: $error';
        _isLoadingExercises = false;
        notifyListeners();
      },
    );
  }

  /// Create a new exercise
  Future<String?> createExercise({
    required String programId,
    required String weekId,
    required String workoutId,
    required String name,
    required ExerciseType exerciseType,
    String? notes,
  }) async {
    if (_userId == null) return null;

    try {
      _error = null;
      notifyListeners();

      // Calculate next order index
      final nextOrderIndex = _exercises.isEmpty 
          ? 0 
          : _exercises.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

      final exercise = Exercise(
        id: '',
        name: name.trim(),
        exerciseType: exerciseType,
        orderIndex: nextOrderIndex,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _userId!,
        workoutId: workoutId,
        weekId: weekId,
        programId: programId,
      );

      final exerciseId = await _firestoreService.createExercise(exercise);
      return exerciseId;
    } catch (e) {
      _error = 'Failed to create exercise: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update an exercise
  Future<bool> updateExercise(Exercise exercise) async {
    try {
      _error = null;
      notifyListeners();

      final updatedExercise = exercise.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateExercise(updatedExercise);
      return true;
    } catch (e) {
      _error = 'Failed to update exercise: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete an exercise
  Future<bool> deleteExercise(
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
  ) async {
    if (_userId == null) return false;

    try {
      _error = null;
      notifyListeners();

      await _firestoreService.deleteExercise(
          _userId!, programId, weekId, workoutId, exerciseId);
      return true;
    } catch (e) {
      _error = 'Failed to delete exercise: $e';
      notifyListeners();
      return false;
    }
  }

  /// Select an exercise and load its sets
  void selectExercise(Exercise exercise) {
    _selectedExercise = exercise;
    _sets = [];
    notifyListeners();

    loadSets(exercise.programId, exercise.weekId, exercise.workoutId, exercise.id);
  }

  // ========================================
  // SET OPERATIONS
  // ========================================

  /// Load sets for the selected exercise
  void loadSets(String programId, String weekId, String workoutId, String exerciseId) {
    if (_userId == null) return;

    _isLoadingSets = true;
    _error = null;
    notifyListeners();

    _firestoreService.getSets(_userId!, programId, weekId, workoutId, exerciseId).listen(
      (sets) {
        _sets = sets;
        _isLoadingSets = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load sets: $error';
        _isLoadingSets = false;
        notifyListeners();
      },
    );
  }

  /// Create a new set
  Future<String?> createSet({
    required String programId,
    required String weekId,
    required String workoutId,
    required String exerciseId,
    int? reps,
    double? weight,
    int? duration,
    double? distance,
    int? restTime,
    String? notes,
  }) async {
    if (_userId == null) return null;

    try {
      _error = null;
      notifyListeners();

      // Calculate next set number
      final nextSetNumber = _sets.isEmpty 
          ? 1 
          : _sets.map((s) => s.setNumber).reduce((a, b) => a > b ? a : b) + 1;

      final set = ExerciseSet(
        id: '',
        setNumber: nextSetNumber,
        reps: reps,
        weight: weight,
        duration: duration,
        distance: distance,
        restTime: restTime,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: _userId!,
        exerciseId: exerciseId,
        workoutId: workoutId,
        weekId: weekId,
        programId: programId,
      );

      final setId = await _firestoreService.createSet(set);
      return setId;
    } catch (e) {
      _error = 'Failed to create set: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a set
  Future<bool> updateSet(ExerciseSet set) async {
    try {
      _error = null;
      notifyListeners();

      final updatedSet = set.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateSet(updatedSet);
      return true;
    } catch (e) {
      _error = 'Failed to update set: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a set
  Future<bool> deleteSet(
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
    String setId,
  ) async {
    if (_userId == null) return false;

    try {
      _error = null;
      notifyListeners();

      await _firestoreService.deleteSet(
          _userId!, programId, weekId, workoutId, exerciseId, setId);
      return true;
    } catch (e) {
      _error = 'Failed to delete set: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selected items
  void clearSelections() {
    _selectedProgram = null;
    _selectedWeek = null;
    _selectedWorkout = null;
    _selectedExercise = null;
    _weeks = [];
    _workouts = [];
    _exercises = [];
    _sets = [];
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _programsSubscription?.cancel();
    _weeksSubscription?.cancel();
    _workoutsSubscription?.cancel();
    _exercisesSubscription?.cancel();
    _setsSubscription?.cancel();
    super.dispose();
  }
}