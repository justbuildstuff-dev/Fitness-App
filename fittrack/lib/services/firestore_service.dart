import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/program.dart';
import '../models/week.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enable offline persistence for Firestore
  static Future<void> enableOfflinePersistence() async {
    try {
      await FirebaseFirestore.instance.enablePersistence();
    } catch (e) {
      // Persistence might already be enabled or not supported
      print('Offline persistence error: $e');
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Program.fromFirestore(doc))
            .toList());
  }

  /// Get a specific program
  Stream<Program?> getProgram(String userId, String programId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? Program.fromFirestore(snapshot) : null);
  }

  /// Create a new program
  Future<String> createProgram(Program program) async {
    final docRef = await _firestore
        .collection('users')
        .doc(program.userId)
        .collection('programs')
        .add(program.toFirestore());
    return docRef.id;
  }

  /// Update a program
  Future<void> updateProgram(Program program) async {
    await _firestore
        .collection('users')
        .doc(program.userId)
        .collection('programs')
        .doc(program.id)
        .update(program.toFirestore());
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
    // TODO: Implement cascade delete via Cloud Function
    // For now, just delete the program document
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .delete();
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Week.fromFirestore(doc, programId))
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
        .map((snapshot) => snapshot.exists ? Week.fromFirestore(snapshot, programId) : null);
  }

  /// Create a new week
  Future<String> createWeek(Week week) async {
    final docRef = await _firestore
        .collection('users')
        .doc(week.userId)
        .collection('programs')
        .doc(week.programId)
        .collection('weeks')
        .add(week.toFirestore());
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
        .update(week.toFirestore());
  }

  /// Delete a week
  Future<void> deleteWeek(String userId, String programId, String weekId) async {
    // TODO: Implement cascade delete via Cloud Function
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('programs')
        .doc(programId)
        .collection('weeks')
        .doc(weekId)
        .delete();
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

      // 2) Create new Week document
      final newWeekRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('programs')
          .doc(programId)
          .collection('weeks')
          .doc();

      final newWeekData = {
        'name': srcWeekData['name'] != null ? '${srcWeekData['name']} (Copy)' : 'Week (Copy)',
        'order': srcWeekData['order'],
        'notes': srcWeekData['notes'],
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

      // 3) Duplicate workouts -> exercises -> sets
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
            final sourceSet = ExerciseSet.fromFirestore(
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
            final newSetPayload = duplicatedSet.toFirestore();
            // Use server timestamp instead of client timestamp for consistency
            newSetPayload['createdAt'] = FieldValue.serverTimestamp();
            newSetPayload['updatedAt'] = FieldValue.serverTimestamp();
            
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromFirestore(doc, weekId, programId))
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
            ? Workout.fromFirestore(snapshot, weekId, programId) 
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
        .add(workout.toFirestore());
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
        .update(workout.toFirestore());
  }

  /// Delete a workout
  Future<void> deleteWorkout(
    String userId,
    String programId,
    String weekId,
    String workoutId,
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
        .delete();
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Exercise.fromFirestore(doc, workoutId, weekId, programId))
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
            ? Exercise.fromFirestore(snapshot, workoutId, weekId, programId) 
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
        .add(exercise.toFirestore());
    return docRef.id;
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
        .update(exercise.toFirestore());
  }

  /// Delete an exercise
  Future<void> deleteExercise(
    String userId,
    String programId,
    String weekId,
    String workoutId,
    String exerciseId,
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
        .delete();
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExerciseSet.fromFirestore(
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
            ? ExerciseSet.fromFirestore(
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
        .add(set.toFirestore());
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
        .update(set.toFirestore());
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
      
      batch.update(docRef, set.toFirestore());
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