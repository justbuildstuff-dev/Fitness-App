import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/library_exercise.dart';
import '../models/custom_exercise.dart';
import '../models/muscle_group.dart';
import '../models/exercise.dart';

/// Maximum number of custom exercises allowed per user
const int maxCustomExercises = 20;

/// Maximum length for custom exercise names
const int maxCustomExerciseNameLength = 50;

/// Provider for managing the exercise library and custom exercises.
///
/// This provider manages two data sources:
/// 1. Library exercises - bundled JSON asset file (read-only, offline-first)
/// 2. Custom exercises - Firestore collection per user (CRUD operations)
class ExerciseLibraryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final String? _userId;

  List<LibraryExercise> _libraryExercises = [];
  List<CustomExercise> _customExercises = [];
  bool _isLoading = false;
  bool _isLibraryLoaded = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _customExercisesSubscription;

  ExerciseLibraryProvider(this._userId)
      : _firestore = FirebaseFirestore.instance {
    _initialize();
  }

  /// Constructor for testing with dependency injection
  ExerciseLibraryProvider.withFirestore(this._userId, this._firestore) {
    _initialize();
  }

  void _initialize() {
    if (_userId != null) {
      loadLibrary();
      _subscribeToCustomExercises();
    }
  }

  // ========================================
  // GETTERS
  // ========================================

  List<LibraryExercise> get libraryExercises => List.unmodifiable(_libraryExercises);
  List<CustomExercise> get customExercises => List.unmodifiable(_customExercises);
  bool get isLoading => _isLoading;
  bool get isLibraryLoaded => _isLibraryLoaded;
  String? get error => _error;
  int get customExerciseCount => _customExercises.length;
  bool get canCreateCustomExercise => _customExercises.length < maxCustomExercises;

  // ========================================
  // LIBRARY LOADING
  // ========================================

  /// Load the exercise library from the bundled JSON asset file.
  /// This should be called once at app start.
  Future<void> loadLibrary() async {
    if (_isLibraryLoaded) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final jsonString = await rootBundle.loadString('assets/data/exercise_library.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final exercisesList = jsonData['exercises'] as List<dynamic>;

      _libraryExercises = exercisesList
          .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLibraryLoaded = true;
      _error = null;
      debugPrint('[ExerciseLibraryProvider] Loaded ${_libraryExercises.length} library exercises');
    } catch (e) {
      _error = 'Failed to load exercise library: $e';
      debugPrint('[ExerciseLibraryProvider] Error loading library: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // CUSTOM EXERCISES - FIRESTORE
  // ========================================

  /// Subscribe to custom exercises from Firestore for the current user.
  void _subscribeToCustomExercises() {
    if (_userId == null) return;

    _customExercisesSubscription?.cancel();

    _customExercisesSubscription = _firestore
        .collection('users')
        .doc(_userId)
        .collection('customExercises')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            _customExercises = snapshot.docs
                .map((doc) => CustomExercise.fromFirestore(doc))
                .toList();
            debugPrint('[ExerciseLibraryProvider] Loaded ${_customExercises.length} custom exercises');
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load custom exercises: $e';
            debugPrint('[ExerciseLibraryProvider] Error loading custom exercises: $e');
            notifyListeners();
          },
        );
  }

  /// Create a new custom exercise.
  /// Returns the new exercise ID on success, or null on failure.
  Future<String?> createCustomExercise({
    required String name,
    required ExerciseType exerciseType,
    required List<MuscleGroup> primaryMuscles,
    List<MuscleGroup> secondaryMuscles = const [],
  }) async {
    if (_userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return null;
    }

    // Validate custom exercise limit
    if (!canCreateCustomExercise) {
      _error = 'Maximum custom exercises reached ($maxCustomExercises)';
      notifyListeners();
      return null;
    }

    // Validate name
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _error = 'Exercise name cannot be empty';
      notifyListeners();
      return null;
    }

    if (trimmedName.length > maxCustomExerciseNameLength) {
      _error = 'Exercise name must be $maxCustomExerciseNameLength characters or less';
      notifyListeners();
      return null;
    }

    // Check name uniqueness among custom exercises
    if (!isNameAvailable(trimmedName)) {
      _error = 'An exercise with this name already exists';
      notifyListeners();
      return null;
    }

    // Validate primary muscles
    if (primaryMuscles.isEmpty) {
      _error = 'At least one primary muscle group is required';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('customExercises')
          .doc();

      final exercise = CustomExercise(
        id: docRef.id,
        name: trimmedName,
        exerciseType: exerciseType,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        userId: _userId!,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(exercise.toFirestore());

      debugPrint('[ExerciseLibraryProvider] Created custom exercise: ${exercise.name}');
      return docRef.id;
    } catch (e) {
      _error = 'Failed to create custom exercise: $e';
      debugPrint('[ExerciseLibraryProvider] Error creating custom exercise: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing custom exercise.
  /// Returns true on success, false on failure.
  Future<bool> updateCustomExercise(CustomExercise exercise) async {
    if (_userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    // Validate name
    final trimmedName = exercise.name.trim();
    if (trimmedName.isEmpty) {
      _error = 'Exercise name cannot be empty';
      notifyListeners();
      return false;
    }

    if (trimmedName.length > maxCustomExerciseNameLength) {
      _error = 'Exercise name must be $maxCustomExerciseNameLength characters or less';
      notifyListeners();
      return false;
    }

    // Check name uniqueness (excluding current exercise)
    if (!isNameAvailable(trimmedName, excludeId: exercise.id)) {
      _error = 'An exercise with this name already exists';
      notifyListeners();
      return false;
    }

    // Validate primary muscles
    if (exercise.primaryMuscles.isEmpty) {
      _error = 'At least one primary muscle group is required';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedExercise = exercise.copyWith(
        name: trimmedName,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('customExercises')
          .doc(exercise.id)
          .update(updatedExercise.toFirestore());

      debugPrint('[ExerciseLibraryProvider] Updated custom exercise: ${exercise.name}');
      return true;
    } catch (e) {
      _error = 'Failed to update custom exercise: $e';
      debugPrint('[ExerciseLibraryProvider] Error updating custom exercise: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a custom exercise.
  /// Returns true on success, false on failure.
  Future<bool> deleteCustomExercise(String exerciseId) async {
    if (_userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('customExercises')
          .doc(exerciseId)
          .delete();

      debugPrint('[ExerciseLibraryProvider] Deleted custom exercise: $exerciseId');
      return true;
    } catch (e) {
      _error = 'Failed to delete custom exercise: $e';
      debugPrint('[ExerciseLibraryProvider] Error deleting custom exercise: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // SEARCH AND FILTERING
  // ========================================

  /// Search exercises across both library and custom exercises.
  /// Returns a combined list with custom exercises appearing first.
  List<dynamic> searchExercises({
    String query = '',
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) {
    final results = <dynamic>[];

    // Add matching custom exercises first
    for (final exercise in _customExercises) {
      if (exercise.matchesSearch(query) &&
          exercise.matchesMuscleGroup(muscleGroup) &&
          exercise.matchesExerciseType(exerciseType)) {
        results.add(exercise);
      }
    }

    // Add matching library exercises
    for (final exercise in _libraryExercises) {
      if (exercise.matchesSearch(query) &&
          exercise.matchesMuscleGroup(muscleGroup) &&
          exercise.matchesExerciseType(exerciseType)) {
        results.add(exercise);
      }
    }

    return results;
  }

  /// Get exercises filtered by muscle group.
  List<dynamic> getExercisesByMuscleGroup(MuscleGroup muscleGroup) {
    return searchExercises(muscleGroup: muscleGroup);
  }

  /// Get exercises filtered by exercise type.
  List<dynamic> getExercisesByType(ExerciseType exerciseType) {
    return searchExercises(exerciseType: exerciseType);
  }

  // ========================================
  // VALIDATION HELPERS
  // ========================================

  /// Check if a custom exercise name is available.
  /// Optionally exclude a specific exercise ID (for edit mode).
  bool isNameAvailable(String name, {String? excludeId}) {
    final lowerName = name.toLowerCase().trim();

    for (final exercise in _customExercises) {
      if (excludeId != null && exercise.id == excludeId) continue;
      if (exercise.name.toLowerCase().trim() == lowerName) {
        return false;
      }
    }

    return true;
  }

  /// Get a custom exercise by ID.
  CustomExercise? getCustomExerciseById(String id) {
    try {
      return _customExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get a library exercise by ID.
  LibraryExercise? getLibraryExerciseById(String id) {
    try {
      return _libraryExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ========================================
  // CLEANUP
  // ========================================

  /// Cancel all subscriptions and clear state.
  void cancelSubscriptions() {
    _customExercisesSubscription?.cancel();
    _customExercisesSubscription = null;
    _customExercises = [];
    _error = null;
    debugPrint('[ExerciseLibraryProvider] Subscriptions canceled');
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
