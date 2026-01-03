import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/program.dart';
import '../models/week.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/cascade_delete_counts.dart';
import '../converters/program_converter.dart';
import '../converters/week_converter.dart';
import '../converters/workout_converter.dart';
import '../converters/exercise_converter.dart';
import '../converters/exercise_set_converter.dart';
import '../utils/smart_copy_naming.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;
  
  final FirebaseFirestore _firestore;
  
  FirestoreService._internal() : _firestore = FirebaseFirestore.instance;
  
  // Constructor for testing with dependency injection
  FirestoreService.withFirestore(this._firestore);

  /// Enable offline persistence for Firestore
  static Future<void> enableOfflinePersistence() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    } catch (e) {
      // Persistence might already be enabled or not supported
      debugPrint('Offline persistence error: $e');
    }
  }

  // ========================================
  // USER PROFILE OPERATIONS
  // ========================================

  /// Get user profile
  Stream<Map<String, dynamic>?> getUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  /// Create user profile
  Future<void> createUserProfile({
    required String userId,
    String? displayName,
    String? email,
    Map<String, dynamic>? settings,
  }) async {
    final profileData = {
      'displayName': displayName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'settings': settings ?? {},
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .set(profileData);
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? email,
    Map<String, dynamic>? settings,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) updateData['displayName'] = displayName;
    if (email != null) updateData['email'] = email;
    if (settings != null) updateData['settings'] = settings;

    await _firestore
        .collection('users')
        .doc(userId)
        .update(updateData);
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // ========================================
  // PROGRAM OPERATIONS
  // ========================================

  /// Get all programs for a user
  Stream<List<Program>> getPrograms(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          // Convert all documents to Program objects and filter archived programs
          // Client-side filtering is critical because:
          // 1. Pending writes may include documents before server applies the query filter
          // 2. Archive updates may not be reflected in the query immediately
          final programs = snapshot.docs
              .map((doc) => ProgramConverter.fromFirestore(doc))
              .where((program) => !program.isArchived)
              .toList();

          return programs;
        });
  }

  /// Get a specific program
  Stream<Program?> getProgram(String userId, String programId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? ProgramConverter.fromFirestore(snapshot) : null);
  }

  /// Create a new program
  Future<String> createProgram(Program program) async {
    final docRef = await _firestore
        .collection('users')
        .doc(program.userId)
        .collection('programs')
        .add(ProgramConverter.toFirestore(program));
    return docRef.id;
  }

  /// Update a program
  Future<void> updateProgram(Program program) async {
    await _firestore
        .collection('users')
        .doc(program.userId)
        .collection('programs')
        .doc(program.id)
        .update(ProgramConverter.toFirestore(program));
  }

  /// Update program with specific fields
  Future<void> updateProgramFields({
    required String userId,
    required String programId,
    String? name,
    String? description,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (description != null) {
      updateData['description'] = description.isEmpty ? null : description;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .update(updateData);
  }

  /// Archive a program (soft delete)
  Future<void> archiveProgram(String userId, String programId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .update({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a program permanently (with cascade delete)
  Future<void> deleteProgram(String userId, String programId) async {
    try {
      // Use soft delete (archive) instead of hard delete per specification
      await archiveProgram(userId, programId);
    } catch (e) {
      throw Exception('Failed to delete program: $e');
    }
  }

  /// Delete a program permanently with full cascade (dangerous - use with care)
  Future<void> deleteProgramCascade(String userId, String programId) async {
    try {
      const batchLimit = 450;
      final List<Future<void>> pendingCommits = [];
      
      // Helper to manage batch operations
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      Future<void> commitBatchIfNeeded() async {
        if (batchCount == 0) return;
        final commitFuture = batch.commit();
        pendingCommits.add(commitFuture);
        batch = _firestore.batch();
        batchCount = 0;
      }

      Future<void> addDeleteToBatch(DocumentReference ref) async {
        batch.delete(ref);
        batchCount++;
        if (batchCount >= batchLimit) {
          await commitBatchIfNeeded();
        }
      }

      // Get all weeks for this program
      final weeksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .get();

      // For each week, delete all workouts, exercises, and sets
      for (final weekDoc in weeksSnapshot.docs) {
        final workoutsSnapshot = await weekDoc.reference
            .collection('workouts')
            .get();

        for (final workoutDoc in workoutsSnapshot.docs) {
          final exercisesSnapshot = await workoutDoc.reference
              .collection('exercises')
              .get();

          for (final exerciseDoc in exercisesSnapshot.docs) {
            // Delete all sets for this exercise
            final setsSnapshot = await exerciseDoc.reference
                .collection('sets')
                .get();

            for (final setDoc in setsSnapshot.docs) {
              await addDeleteToBatch(setDoc.reference);
            }

            // Delete the exercise
            await addDeleteToBatch(exerciseDoc.reference);
          }

          // Delete the workout
          await addDeleteToBatch(workoutDoc.reference);
        }

        // Delete the week
        await addDeleteToBatch(weekDoc.reference);
      }

      // Delete the program itself
      await addDeleteToBatch(_firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId));

      // Commit any remaining operations
      await commitBatchIfNeeded();
      await Future.wait(pendingCommits);
    } catch (e) {
      throw Exception('Failed to delete program cascade: $e');
    }
  }

  // ========================================
  // WEEK OPERATIONS
  // ========================================

  /// Get all weeks for a program
  Stream<List<Week>> getWeeks(String userId, String programId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .orderBy('order')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => WeekConverter.fromFirestore(doc, programId: programId))
            .toList());
  }

  /// Get a specific week
  Stream<Week?> getWeek(String userId, String programId, String weekId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? WeekConverter.fromFirestore(snapshot, programId: programId) : null);
  }

  /// Create a new week
  Future<String> createWeek(Week week) async {
    final docRef = await _firestore
        .collection('users')
        .doc(week.userId)
        .collection('programs')
        .doc(week.programId)
        .collection('weeks')
        .add(WeekConverter.toFirestore(week));
    return docRef.id;
  }

  /// Update a week
  Future<void> updateWeek(Week week) async {
    await _firestore
        .collection('users')
        .doc(week.userId)
        .collection('programs')
        .doc(week.programId)
        .collection('weeks')
        .doc(week.id)
        .update(WeekConverter.toFirestore(week));
  }

  /// Update week with specific fields
  Future<void> updateWeekFields({
    required String userId,
    required String programId,
    required String weekId,
    String? name,
    String? notes,
    int? order,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (notes != null) {
      updateData['notes'] = notes.isEmpty ? null : notes;
    }
    if (order != null) updateData['order'] = order;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .update(updateData);
  }

  /// Delete a week with cascade delete
  Future<void> deleteWeek(String userId, String programId, String weekId) async {
    try {
      await _deleteWeekCascade(userId, programId, weekId);
    } catch (e) {
      throw Exception('Failed to delete week: $e');
    }
  }

  /// Delete a week with full cascade delete
  Future<void> _deleteWeekCascade(String userId, String programId, String weekId) async {
    try {
      const batchLimit = 450;
      final List<Future<void>> pendingCommits = [];
      
      // Helper to manage batch operations
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      Future<void> commitBatchIfNeeded() async {
        if (batchCount == 0) return;
        final commitFuture = batch.commit();
        pendingCommits.add(commitFuture);
        batch = _firestore.batch();
        batchCount = 0;
      }

      Future<void> addDeleteToBatch(DocumentReference ref) async {
        batch.delete(ref);
        batchCount++;
        if (batchCount >= batchLimit) {
          await commitBatchIfNeeded();
        }
      }

      // Get all workouts for this week
      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .get();

      for (final workoutDoc in workoutsSnapshot.docs) {
        final exercisesSnapshot = await workoutDoc.reference
            .collection('exercises')
            .get();

        for (final exerciseDoc in exercisesSnapshot.docs) {
          // Delete all sets for this exercise
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();

          for (final setDoc in setsSnapshot.docs) {
            await addDeleteToBatch(setDoc.reference);
          }

          // Delete the exercise
          await addDeleteToBatch(exerciseDoc.reference);
        }

        // Delete the workout
        await addDeleteToBatch(workoutDoc.reference);
      }

      // Delete the week itself
      await addDeleteToBatch(_firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId));

      // Commit any remaining operations
      await commitBatchIfNeeded();
      await Future.wait(pendingCommits);
    } catch (e) {
      throw Exception('Failed to delete week cascade: $e');
    }
  }

  /// Helper function to safely handle Timestamp fields that may be null
  ///
  /// Returns null if the timestamp is null, otherwise returns the timestamp.
  /// This prevents errors when copying documents with null Timestamp fields.
  Timestamp? _safeTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    // If it's a FieldValue.serverTimestamp(), we can't access it here
    return null;
  }

  /// Duplicate a week using client-side batched writes
  Future<Map<String, dynamic>> duplicateWeek({
    required String userId,
    required String programId,
    required String weekId,
  }) async {
    try {
      // Helper: batch management with chunking
      const batchLimit = 450; // keep safely under 500
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      final List<Future<void>> pendingCommits = [];

      Future<void> commitBatchIfNeeded() async {
        if (batchCount == 0) return;
        // commit current batch and prepare a fresh one
        final commitFuture = batch.commit();
        pendingCommits.add(commitFuture);
        batch = _firestore.batch();
        batchCount = 0;
      }

      Future<void> addToBatch(DocumentReference ref, Map<String, dynamic> data) async {
        batch.set(ref, data);
        batchCount++;
        if (batchCount >= batchLimit) {
          await commitBatchIfNeeded();
        }
      }

      // 1) Load source week and ownership check
      final srcWeekRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId);

      final srcWeekSnap = await srcWeekRef.get();
      if (!srcWeekSnap.exists) {
        throw Exception('Source week not found');
      }

      final srcWeekData = srcWeekSnap.data();
      if (srcWeekData == null) {
        throw Exception('Source week data not found');
      }

      // Verify userId stored in doc matches uid (defense in depth)
      if (srcWeekData['userId'] != null && srcWeekData['userId'] != userId) {
        throw Exception('You do not own this week');
      }

      // 2) Query all existing week names for smart copy naming
      final existingWeeksSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .get();

      final existingWeekNames = existingWeeksSnap.docs
          .map((doc) => doc.data()['name'] as String?)
          .where((name) => name != null)
          .cast<String>()
          .toList();

      // Generate smart copy name
      final sourceName = srcWeekData['name'] as String? ?? 'Week';
      final smartCopyName = SmartCopyNaming.generateCopyName(sourceName, existingWeekNames);

      // 3) Create new Week document
      final newWeekRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc();

      final newWeekData = {
        'name': smartCopyName,
        'order': srcWeekData['order'],
        'notes': srcWeekData['notes'],
        // Always set fresh timestamps for duplicated week
        // Don't copy completedAt - duplicated week should start fresh
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': userId,
        'programId': programId,
      };

      await addToBatch(newWeekRef, newWeekData);

      // Prepare mapping to return to client for navigation / confirmation
      final mapping = {
        'oldWeekId': weekId,
        'newWeekId': newWeekRef.id,
        'workouts': <Map<String, dynamic>>[],
      };

      // 4) Duplicate workouts -> exercises -> sets
      final srcWorkoutsSnap = await srcWeekRef
          .collection('workouts')
          .orderBy('orderIndex')
          .get();

      for (final workoutDoc in srcWorkoutsSnap.docs) {
        final workoutData = workoutDoc.data();

        // new workout under the new week
        final newWorkoutRef = newWeekRef.collection('workouts').doc();
        final newWorkoutData = {
          'name': workoutData['name'],
          'dayOfWeek': workoutData['dayOfWeek'],
          'orderIndex': workoutData['orderIndex'],
          'notes': workoutData['notes'],
          // Fresh timestamps for duplicated workout
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': userId,
          'programId': programId,
          'weekId': newWeekRef.id,
        };

        await addToBatch(newWorkoutRef, newWorkoutData);

        final workoutMap = {
          'oldWorkoutId': workoutDoc.id,
          'newWorkoutId': newWorkoutRef.id,
          'exercises': <Map<String, dynamic>>[],
        };

        // Fetch exercises for this workout
        final srcExercisesSnap = await workoutDoc.reference
            .collection('exercises')
            .orderBy('orderIndex')
            .get();

        for (final exerciseDoc in srcExercisesSnap.docs) {
          final exerciseData = exerciseDoc.data();

          // create new exercise
          final newExerciseRef = newWorkoutRef.collection('exercises').doc();
          final newExerciseData = {
            'name': exerciseData['name'],
            'exerciseType': exerciseData['exerciseType'] ?? 'custom',
            'orderIndex': exerciseData['orderIndex'],
            'notes': exerciseData['notes'],
            // Fresh timestamps for duplicated exercise
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'userId': userId,
            'programId': programId,
            'weekId': newWeekRef.id,
            'workoutId': newWorkoutRef.id,
          };

          await addToBatch(newExerciseRef, newExerciseData);

          final exerciseMap = {
            'oldExerciseId': exerciseDoc.id,
            'newExerciseId': newExerciseRef.id,
            'sets': <Map<String, dynamic>>[],
          };

          // Fetch sets for this exercise and duplicate conditionally
          final srcSetsSnap = await exerciseDoc.reference
              .collection('sets')
              .orderBy('setNumber')
              .get();

          for (final setDoc in srcSetsSnap.docs) {
            // Create ExerciseSet object from source data to use its built-in duplication logic
            final sourceSet = ExerciseSetConverter.fromFirestore(
              setDoc,
              exerciseDoc.id,
              workoutDoc.id,
              srcWeekSnap.id,
              programId,
            );

            // Get exercise type and convert to enum
            final typeString = exerciseData['exerciseType'] ?? 'custom';
            final exerciseType = ExerciseType.fromString(typeString);

            // Use model's built-in duplication method - handles all business logic properly
            final newSetRef = newExerciseRef.collection('sets').doc();
            final duplicatedSet = sourceSet.createDuplicateCopy(
              newId: newSetRef.id,
              newExerciseId: newExerciseRef.id,
              newWorkoutId: newWorkoutRef.id,
              newWeekId: newWeekRef.id,
              newProgramId: programId,
              exerciseType: exerciseType,
            );

            // Convert to Firestore format and add to batch
            final newSetPayload = ExerciseSetConverter.toFirestore(duplicatedSet);
            // Always use server timestamps for duplicated sets (fresh timestamps)
            // Don't copy completedAt - duplicated sets should start unchecked
            newSetPayload['createdAt'] = FieldValue.serverTimestamp();
            newSetPayload['updatedAt'] = FieldValue.serverTimestamp();
            // Ensure completedAt is not copied from source (sets should start fresh)
            newSetPayload.remove('completedAt');
            
            await addToBatch(newSetRef, newSetPayload);

            (exerciseMap['sets'] as List<Map<String, dynamic>>).add({
              'oldSetId': setDoc.id,
              'newSetId': newSetRef.id,
            });
          } // end sets loop

          (workoutMap['exercises'] as List<Map<String, dynamic>>).add(exerciseMap);
        } // end exercises loop

        (mapping['workouts'] as List<Map<String, dynamic>>).add(workoutMap);
      } // end workouts loop

      // Commit any outstanding batch writes
      await commitBatchIfNeeded();
      // Wait for all batch commits to finish
      await Future.wait(pendingCommits);

      // Return mapping to client
      return {'success': true, 'mapping': mapping};
    } catch (e) {
      throw Exception('Failed to duplicate week: $e');
    }
  }

  // ========================================
  // WORKOUT OPERATIONS
  // ========================================

  /// Get all workouts for a week
  Stream<List<Workout>> getWorkouts(String userId, String programId, String weekId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .orderBy('orderIndex')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutConverter.fromFirestore(doc, weekId, programId))
            .toList());
  }

  /// Get a specific workout
  Stream<Workout?> getWorkout(
    String userId,
    String programId,
    String weekId,
    String workoutId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? WorkoutConverter.fromFirestore(snapshot, weekId, programId) 
            : null);
  }

  /// Create a new workout
  Future<String> createWorkout(Workout workout) async {
    final docRef = await _firestore
        .collection('users')
        .doc(workout.userId)
        .collection('programs')
        .doc(workout.programId)
        .collection('weeks')
        .doc(workout.weekId)
        .collection('workouts')
        .add(WorkoutConverter.toFirestore(workout));
    return docRef.id;
  }

  /// Update a workout
  Future<void> updateWorkout(Workout workout) async {
    await _firestore
        .collection('users')
        .doc(workout.userId)
        .collection('programs')
        .doc(workout.programId)
        .collection('weeks')
        .doc(workout.weekId)
        .collection('workouts')
        .doc(workout.id)
        .update(WorkoutConverter.toFirestore(workout));
  }

  /// Update workout with specific fields
  Future<void> updateWorkoutFields({
    required String userId,
    required String programId,
    required String weekId,
    required String workoutId,
    String? name,
    int? dayOfWeek,
    String? notes,
    int? orderIndex,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (dayOfWeek != null) updateData['dayOfWeek'] = dayOfWeek;
    if (notes != null) {
      updateData['notes'] = notes.isEmpty ? null : notes;
    }
    if (orderIndex != null) updateData['orderIndex'] = orderIndex;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .update(updateData);
  }

  /// Delete a workout with cascade delete
  Future<void> deleteWorkout(
    String userId,
    String programId,
    String weekId,
    String workoutId,
  ) async {
    try {
      await _deleteWorkoutCascade(userId, programId, weekId, workoutId);
    } catch (e) {
      throw Exception('Failed to delete workout: $e');
    }
  }

  /// Delete a workout with full cascade delete
  Future<void> _deleteWorkoutCascade(
    String userId, 
    String programId, 
    String weekId, 
    String workoutId,
  ) async {
    try {
      const batchLimit = 450;
      final List<Future<void>> pendingCommits = [];
      
      // Helper to manage batch operations
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      Future<void> commitBatchIfNeeded() async {
        if (batchCount == 0) return;
        final commitFuture = batch.commit();
        pendingCommits.add(commitFuture);
        batch = _firestore.batch();
        batchCount = 0;
      }

      Future<void> addDeleteToBatch(DocumentReference ref) async {
        batch.delete(ref);
        batchCount++;
        if (batchCount >= batchLimit) {
          await commitBatchIfNeeded();
        }
      }

      // Get all exercises for this workout
      final exercisesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .get();

      for (final exerciseDoc in exercisesSnapshot.docs) {
        // Delete all sets for this exercise
        final setsSnapshot = await exerciseDoc.reference
            .collection('sets')
            .get();

        for (final setDoc in setsSnapshot.docs) {
          await addDeleteToBatch(setDoc.reference);
        }

        // Delete the exercise
        await addDeleteToBatch(exerciseDoc.reference);
      }

      // Delete the workout itself
      await addDeleteToBatch(_firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId));

      // Commit any remaining operations
      await commitBatchIfNeeded();
      await Future.wait(pendingCommits);
    } catch (e) {
      throw Exception('Failed to delete workout cascade: $e');
    }
  }

  // ========================================
  // EXERCISE OPERATIONS
  // ========================================

  /// Get all exercises for a workout
  Stream<List<Exercise>> getExercises(
    String userId,
    String programId,
    String weekId,
    String workoutId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .orderBy('orderIndex')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => ExerciseConverter.fromFirestore(doc, workoutId, weekId, programId))
            .toList());
  }

  /// Get a specific exercise
  Stream<Exercise?> getExercise(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? ExerciseConverter.fromFirestore(snapshot, workoutId, weekId, programId) 
            : null);
  }

  /// Create a new exercise
  Future<String> createExercise(Exercise exercise) async {
    final docRef = await _firestore
        .collection('users')
        .doc(exercise.userId)
        .collection('programs')
        .doc(exercise.programId)
        .collection('weeks')
        .doc(exercise.weekId)
        .collection('workouts')
        .doc(exercise.workoutId)
        .collection('exercises')
        .add(ExerciseConverter.toFirestore(exercise));
    return docRef.id;
  }

  /// Create an exercise with a specified number of sets in a batched write
  Future<String> createExerciseWithSets(Exercise exercise, int setCount) async {
    final batch = _firestore.batch();

    // Create exercise document reference
    final exerciseRef = _firestore
        .collection('users')
        .doc(exercise.userId)
        .collection('programs')
        .doc(exercise.programId)
        .collection('weeks')
        .doc(exercise.weekId)
        .collection('workouts')
        .doc(exercise.workoutId)
        .collection('exercises')
        .doc();

    // Add exercise to batch with the generated ID
    final exerciseWithId = Exercise(
      id: exerciseRef.id,
      name: exercise.name,
      exerciseType: exercise.exerciseType,
      orderIndex: exercise.orderIndex,
      notes: exercise.notes,
      createdAt: exercise.createdAt,
      updatedAt: exercise.updatedAt,
      userId: exercise.userId,
      workoutId: exercise.workoutId,
      weekId: exercise.weekId,
      programId: exercise.programId,
    );
    batch.set(exerciseRef, ExerciseConverter.toFirestore(exerciseWithId));

    // Create N sets with default values
    for (int i = 0; i < setCount; i++) {
      final setRef = exerciseRef.collection('sets').doc();

      final set = ExerciseSet(
        id: setRef.id,
        setNumber: i + 1,
        checked: false,
        // Default values based on exercise type
        weight: null,
        reps: null,
        duration: null,
        distance: null,
        notes: null,
        restTime: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: exercise.userId,
        exerciseId: exerciseRef.id,
        workoutId: exercise.workoutId,
        weekId: exercise.weekId,
        programId: exercise.programId,
      );

      batch.set(setRef, ExerciseSetConverter.toFirestore(set));
    }

    // Commit the batched write
    await batch.commit();
    return exerciseRef.id;
  }

  /// Update an exercise
  Future<void> updateExercise(Exercise exercise) async {
    await _firestore
        .collection('users')
        .doc(exercise.userId)
        .collection('programs')
        .doc(exercise.programId)
        .collection('weeks')
        .doc(exercise.weekId)
        .collection('workouts')
        .doc(exercise.workoutId)
        .collection('exercises')
        .doc(exercise.id)
        .update(ExerciseConverter.toFirestore(exercise));
  }

  /// Update exercise with specific fields
  Future<void> updateExerciseFields({
    required String userId,
    required String programId,
    required String weekId,
    required String workoutId,
    required String exerciseId,
    String? name,
    ExerciseType? exerciseType,
    String? notes,
    int? orderIndex,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (exerciseType != null) updateData['exerciseType'] = exerciseType.toMap();
    if (notes != null) {
      updateData['notes'] = notes.isEmpty ? null : notes;
    }
    if (orderIndex != null) updateData['orderIndex'] = orderIndex;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .update(updateData);
  }

  /// Delete an exercise with cascade delete
  Future<void> deleteExercise(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
  ) async {
    try {
      await _deleteExerciseCascade(userId, programId, weekId, workoutId, exerciseId);
    } catch (e) {
      throw Exception('Failed to delete exercise: $e');
    }
  }

  /// Delete an exercise with full cascade delete
  Future<void> _deleteExerciseCascade(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
  ) async {
    try {
      const batchLimit = 450;
      final List<Future<void>> pendingCommits = [];
      
      // Helper to manage batch operations
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      Future<void> commitBatchIfNeeded() async {
        if (batchCount == 0) return;
        final commitFuture = batch.commit();
        pendingCommits.add(commitFuture);
        batch = _firestore.batch();
        batchCount = 0;
      }

      Future<void> addDeleteToBatch(DocumentReference ref) async {
        batch.delete(ref);
        batchCount++;
        if (batchCount >= batchLimit) {
          await commitBatchIfNeeded();
        }
      }

      // Get all sets for this exercise
      final setsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('sets')
          .get();

      for (final setDoc in setsSnapshot.docs) {
        await addDeleteToBatch(setDoc.reference);
      }

      // Delete the exercise itself
      await addDeleteToBatch(_firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .doc(exerciseId));

      // Commit any remaining operations
      await commitBatchIfNeeded();
      await Future.wait(pendingCommits);
    } catch (e) {
      throw Exception('Failed to delete exercise cascade: $e');
    }
  }

  // ========================================
  // CASCADE DELETE COUNT OPERATIONS
  // ========================================

  /// Count workouts in a week
  ///
  /// Used to display cascade delete information in confirmation dialogs.
  /// Returns the count of workouts that would be deleted when deleting a week.
  Future<int> countWorkoutsInWeek(
    String userId,
    String programId,
    String weekId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Count exercises in a workout
  ///
  /// Used to display cascade delete information in confirmation dialogs.
  /// Returns the count of exercises that would be deleted when deleting a workout.
  Future<int> countExercisesInWorkout(
    String userId,
    String programId,
    String weekId,
    String workoutId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Count sets in an exercise
  ///
  /// Used to display cascade delete information in confirmation dialogs.
  /// Returns the count of sets that would be deleted when deleting an exercise.
  Future<int> countSetsInExercise(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get counts of all child entities that will be deleted in a cascade operation
  ///
  /// This method calculates the total number of workouts, exercises, and sets
  /// that will be deleted based on the provided IDs:
  /// - If only [weekId] is provided: counts all workouts, exercises, and sets in the week
  /// - If [workoutId] is also provided: counts all exercises and sets in the workout
  /// - If [exerciseId] is also provided: counts all sets in the exercise
  ///
  /// Returns [CascadeDeleteCounts] with counts for each entity type.
  /// On error, returns zero counts (graceful degradation).
  Future<CascadeDeleteCounts> getCascadeDeleteCounts({
    required String userId,
    required String programId,
    String? weekId,
    String? workoutId,
    String? exerciseId,
  }) async {
    try {
      // Deleting a week
      if (weekId != null && workoutId == null && exerciseId == null) {
        int totalExercises = 0;
        int totalSets = 0;

        // Get all workouts in week
        final workoutsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('programs')
            .doc(programId)
            .collection('weeks')
            .doc(weekId)
            .collection('workouts')
            .get();

        final workoutCount = workoutsSnapshot.docs.length;

        // For each workout, count exercises and sets
        for (final workoutDoc in workoutsSnapshot.docs) {
          final exercisesSnapshot = await workoutDoc.reference
              .collection('exercises')
              .get();

          totalExercises += exercisesSnapshot.docs.length;

          for (final exerciseDoc in exercisesSnapshot.docs) {
            final setsSnapshot = await exerciseDoc.reference
                .collection('sets')
                .count()
                .get();
            totalSets += (setsSnapshot.count ?? 0);
          }
        }

        return CascadeDeleteCounts(
          workouts: workoutCount,
          exercises: totalExercises,
          sets: totalSets,
        );
      }

      // Deleting a workout
      if (weekId != null && workoutId != null && exerciseId == null) {
        int totalExercises = 0;
        int totalSets = 0;

        final exercisesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('programs')
            .doc(programId)
            .collection('weeks')
            .doc(weekId)
            .collection('workouts')
            .doc(workoutId)
            .collection('exercises')
            .get();

        totalExercises = exercisesSnapshot.docs.length;

        for (final exerciseDoc in exercisesSnapshot.docs) {
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .count()
              .get();
          totalSets += (setsSnapshot.count ?? 0);
        }

        return CascadeDeleteCounts(
          exercises: totalExercises,
          sets: totalSets,
        );
      }

      // Deleting an exercise
      if (weekId != null && workoutId != null && exerciseId != null) {
        final setsCount = await countSetsInExercise(
          userId,
          programId,
          weekId,
          workoutId,
          exerciseId,
        );

        return CascadeDeleteCounts(sets: setsCount);
      }

      // Invalid parameters
      return const CascadeDeleteCounts();
    } catch (e) {
      debugPrint('Error getting cascade delete counts: $e');
      return const CascadeDeleteCounts();
    }
  }

  // ========================================
  // SET OPERATIONS
  // ========================================

  /// Get all sets for an exercise
  Stream<List<ExerciseSet>> getSets(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .orderBy('setNumber')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => ExerciseSetConverter.fromFirestore(
                doc, exerciseId, workoutId, weekId, programId))
            .toList());
  }

  /// Get a specific set
  Stream<ExerciseSet?> getSet(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
    String setId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .doc(setId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? ExerciseSetConverter.fromFirestore(
                snapshot, exerciseId, workoutId, weekId, programId) 
            : null);
  }

  /// Create a new set
  Future<String> createSet(ExerciseSet set) async {
    final docRef = await _firestore
        .collection('users')
        .doc(set.userId)
        .collection('programs')
        .doc(set.programId)
        .collection('weeks')
        .doc(set.weekId)
        .collection('workouts')
        .doc(set.workoutId)
        .collection('exercises')
        .doc(set.exerciseId)
        .collection('sets')
        .add(ExerciseSetConverter.toFirestore(set));
    return docRef.id;
  }

  /// Update a set
  Future<void> updateSet(ExerciseSet set) async {
    await _firestore
        .collection('users')
        .doc(set.userId)
        .collection('programs')
        .doc(set.programId)
        .collection('weeks')
        .doc(set.weekId)
        .collection('workouts')
        .doc(set.workoutId)
        .collection('exercises')
        .doc(set.exerciseId)
        .collection('sets')
        .doc(set.id)
        .update(ExerciseSetConverter.toFirestore(set));
  }

  /// Delete a set
  Future<void> deleteSet(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
    String setId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .collection('workouts')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .doc(setId)
        .delete();
  }

  // ========================================
  // BATCH OPERATIONS
  // ========================================

  /// Update multiple sets in a batch
  Future<void> batchUpdateSets(List<ExerciseSet> sets) async {
    final batch = _firestore.batch();
    
    for (final set in sets) {
      final docRef = _firestore
          .collection('users')
          .doc(set.userId)
          .collection('programs')
          .doc(set.programId)
          .collection('weeks')
          .doc(set.weekId)
          .collection('workouts')
          .doc(set.workoutId)
          .collection('exercises')
          .doc(set.exerciseId)
          .collection('sets')
          .doc(set.id);
      
      batch.update(docRef, ExerciseSetConverter.toFirestore(set));
    }
    
    await batch.commit();
  }

  /// Reorder weeks within a program
  Future<void> reorderWeeks({
    required String userId,
    required String programId,
    required List<String> weekIds,
  }) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < weekIds.length; i++) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekIds[i]);
          
      batch.update(docRef, {
        'order': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  /// Reorder workouts within a week
  Future<void> reorderWorkouts({
    required String userId,
    required String programId,
    required String weekId,
    required List<String> workoutIds,
  }) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < workoutIds.length; i++) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutIds[i]);
          
      batch.update(docRef, {
        'orderIndex': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  /// Reorder exercises within a workout
  Future<void> reorderExercises({
    required String userId,
    required String programId,
    required String weekId,
    required String workoutId,
    required List<String> exerciseIds,
  }) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < exerciseIds.length; i++) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .doc(exerciseIds[i]);
          
      batch.update(docRef, {
        'orderIndex': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  /// Reorder sets within an exercise
  Future<void> reorderSets({
    required String userId,
    required String programId,
    required String weekId,
    required String workoutId,
    required String exerciseId,
    required List<String> setIds,
  }) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < setIds.length; i++) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc(weekId)
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .doc(exerciseId)
          .collection('sets')
          .doc(setIds[i]);
          
      batch.update(docRef, {
        'setNumber': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }
}