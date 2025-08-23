/**
 * Cloud Functions for FitTrack
 * 
 * Contains the production-ready duplicateWeek function and other
 * server-side operations for the fitness tracking app.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function: duplicateWeek
 * 
 * Callable function that duplicates a Week (and its nested Workouts -> Exercises -> Sets)
 * for the authenticated user.
 * 
 * Features:
 * - Deep copying of hierarchical data structure
 * - Batched writes with chunking to avoid Firestore limits
 * - Exercise type-specific field copying
 * - Security: Only authenticated users can duplicate their own data
 * - Audit logging for debugging and monitoring
 * 
 * @param data - Object containing programId and weekId
 * @param context - Firebase Functions context with authentication info
 * @returns Promise<{success: boolean, mapping: object}>
 */
export const duplicateWeek = functions.https.onCall(async (data, context) => {
  // -------------------------
  // 1) Authentication check
  // -------------------------
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated."
    );
  }
  const uid = context.auth.uid;

  // -------------------------
  // 2) Validate input
  // -------------------------
  const {programId, weekId} = data || {};
  if (!programId || !weekId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "programId and weekId are required."
    );
  }

  const db = admin.firestore();

  // Helper: batch management with chunking
  const BATCH_LIMIT = 450; // keep safely under 500
  let batch = db.batch();
  let batchCount = 0;
  const pendingCommits: Promise<admin.firestore.WriteResult[]>[] = [];

  async function commitBatchIfNeeded(): Promise<void> {
    if (batchCount === 0) return;
    // commit current batch and prepare a fresh one
    const commitPromise = batch.commit();
    pendingCommits.push(commitPromise);
    batch = db.batch();
    batchCount = 0;
  }

  async function addToBatch(
    ref: admin.firestore.DocumentReference,
    data: admin.firestore.DocumentData
  ): Promise<void> {
    batch.set(ref, data);
    batchCount++;
    if (batchCount >= BATCH_LIMIT) {
      await commitBatchIfNeeded();
    }
  }

  try {
    // -------------------------
    // 3) Load source week and ownership check
    // -------------------------
    const srcWeekRef = db
      .collection("users")
      .doc(uid)
      .collection("programs")
      .doc(programId)
      .collection("weeks")
      .doc(weekId);

    const srcWeekSnap = await srcWeekRef.get();
    if (!srcWeekSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Source week not found.");
    }

    const srcWeekData = srcWeekSnap.data();
    if (!srcWeekData) {
      throw new functions.https.HttpsError("not-found", "Source week data not found.");
    }

    // Verify userId stored in doc matches uid (defense in depth)
    if (srcWeekData.userId && srcWeekData.userId !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You do not own this week."
      );
    }

    // -------------------------
    // 4) Create new Week document
    // -------------------------
    const newWeekRef = db
      .collection("users")
      .doc(uid)
      .collection("programs")
      .doc(programId)
      .collection("weeks")
      .doc();

    const newWeekData = {
      name: srcWeekData.name ? `${srcWeekData.name} (Copy)` : "Week (Copy)",
      order: srcWeekData.order || null,
      notes: srcWeekData.notes || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: uid,
    };

    await addToBatch(newWeekRef, newWeekData);

    // Prepare mapping to return to client for navigation / confirmation
    const mapping = {
      oldWeekId: weekId,
      newWeekId: newWeekRef.id,
      workouts: [] as Array<{
        oldWorkoutId: string;
        newWorkoutId: string;
        exercises: Array<{
          oldExerciseId: string;
          newExerciseId: string;
          sets: Array<{
            oldSetId: string;
            newSetId: string;
          }>;
        }>;
      }>,
    };

    // -------------------------
    // 5) Duplicate workouts -> exercises -> sets
    // -------------------------
    const srcWorkoutsSnap = await srcWeekRef
      .collection("workouts")
      .orderBy("orderIndex", "asc")
      .get();

    for (const workoutDoc of srcWorkoutsSnap.docs) {
      const workoutData = workoutDoc.data();

      // new workout under the new week
      const newWorkoutRef = newWeekRef.collection("workouts").doc();
      const newWorkoutData = {
        name: workoutData.name || null,
        dayOfWeek: workoutData.dayOfWeek || null,
        orderIndex: workoutData.orderIndex || null,
        notes: workoutData.notes || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: uid,
      };

      await addToBatch(newWorkoutRef, newWorkoutData);

      const workoutMap = {
        oldWorkoutId: workoutDoc.id,
        newWorkoutId: newWorkoutRef.id,
        exercises: [] as Array<{
          oldExerciseId: string;
          newExerciseId: string;
          sets: Array<{
            oldSetId: string;
            newSetId: string;
          }>;
        }>,
      };

      // Fetch exercises for this workout
      const srcExercisesSnap = await workoutDoc.ref
        .collection("exercises")
        .orderBy("orderIndex", "asc")
        .get();

      for (const exerciseDoc of srcExercisesSnap.docs) {
        const exerciseData = exerciseDoc.data();

        // create new exercise
        const newExerciseRef = newWorkoutRef.collection("exercises").doc();
        const newExerciseData = {
          name: exerciseData.name || null,
          exerciseType: exerciseData.exerciseType || "custom",
          orderIndex: exerciseData.orderIndex || null,
          notes: exerciseData.notes || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          userId: uid,
        };

        await addToBatch(newExerciseRef, newExerciseData);

        const exerciseMap = {
          oldExerciseId: exerciseDoc.id,
          newExerciseId: newExerciseRef.id,
          sets: [] as Array<{
            oldSetId: string;
            newSetId: string;
          }>,
        };

        // Fetch sets for this exercise and duplicate conditionally
        const srcSetsSnap = await exerciseDoc.ref
          .collection("sets")
          .orderBy("setNumber", "asc")
          .get();

        for (const setDoc of srcSetsSnap.docs) {
          const setData = setDoc.data();

          // Build the new set payload by copying only relevant fields
          const type = exerciseData.exerciseType || "custom";
          const newSetPayload: admin.firestore.DocumentData = {
            setNumber: setData.setNumber,
            exerciseType: type,
            checked: false,
            notes: setData.notes || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            userId: uid,
          };

          // conditional copying based on type
          if (type === "strength") {
            if (setData.reps != null) newSetPayload.reps = setData.reps;
            // Reset weight to null to encourage fresh entry (policy decision)
            newSetPayload.weight = null;
          } else if (type === "cardio" || type === "time-based") {
            if (setData.duration != null) newSetPayload.duration = setData.duration;
            if (setData.distance != null) newSetPayload.distance = setData.distance;
          } else {
            // custom or other -> copy over sensible fields
            if (setData.reps != null) newSetPayload.reps = setData.reps;
            if (setData.duration != null) newSetPayload.duration = setData.duration;
            if (setData.distance != null) newSetPayload.distance = setData.distance;
            if (setData.weight != null) newSetPayload.weight = setData.weight;
          }

          const newSetRef = newExerciseRef.collection("sets").doc();
          await addToBatch(newSetRef, newSetPayload);

          exerciseMap.sets.push({oldSetId: setDoc.id, newSetId: newSetRef.id});
        } // end sets loop

        workoutMap.exercises.push(exerciseMap);
      } // end exercises loop

      mapping.workouts.push(workoutMap);
    } // end workouts loop

    // Commit any outstanding batch writes
    await commitBatchIfNeeded();
    // Wait for all batch commits to finish
    await Promise.all(pendingCommits);

    // Log duplication event for audit / debugging
    try {
      await db
        .collection("users")
        .doc(uid)
        .collection("duplicationLogs")
        .add({
          type: "duplicateWeek",
          sourceWeekId: weekId,
          newWeekId: newWeekRef.id,
          programId: programId,
          userId: uid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (err) {
      // non-fatal if logging fails — just record to Cloud Logging
      console.warn("duplication log failed", err);
    }

    // Return mapping to client
    return {success: true, mapping};
  } catch (err) {
    console.error("duplicateWeek error:", err);

    // Map known firebase functions errors through, otherwise return internal
    if (err instanceof functions.https.HttpsError) throw err;

    throw new functions.https.HttpsError(
      "internal",
      "Duplication failed. See logs for details."
    );
  }
});