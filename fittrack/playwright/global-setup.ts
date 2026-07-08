import { createTestUser, seedFirestoreDoc, clearEmulatorData } from './helpers/firebase-emulator';

const TEST_EMAIL = 'playwright-e2e@test.com';
const TEST_PASSWORD = 'playwright-test-123';

export default async function globalSetup(): Promise<void> {
  // Start with a clean slate
  await clearEmulatorData();

  // Create test user and verify email
  const uid = await createTestUser(TEST_EMAIL, TEST_PASSWORD);

  // Expose credentials to tests via env vars
  process.env.E2E_TEST_EMAIL = TEST_EMAIL;
  process.env.E2E_TEST_PASSWORD = TEST_PASSWORD;
  process.env.E2E_TEST_UID = uid;

  // Seed user profile with isProOverride to unlock Analytics Pro gate
  await seedFirestoreDoc(`users/${uid}`, {
    userId: uid,
    email: TEST_EMAIL,
    displayName: 'Playwright Test User',
    isProOverride: true,
    createdAt: new Date(),
  });

  // Seed a full workout hierarchy for logging and analytics tests
  const programId = 'e2e-program-001';
  const weekId = 'e2e-week-001';
  const workoutId = 'e2e-workout-001';
  const exerciseId = 'e2e-exercise-001';
  const setId = 'e2e-set-001';

  await seedFirestoreDoc(`users/${uid}/programs/${programId}`, {
    userId: uid,
    id: programId,
    name: 'E2E Test Program',
    createdAt: new Date(),
    weekCount: 1,
    isArchived: false,  // Required: getPrograms() queries .where('isArchived', isEqualTo: false)
  });

  await seedFirestoreDoc(`users/${uid}/programs/${programId}/weeks/${weekId}`, {
    userId: uid,
    id: weekId,
    programId,
    name: 'Week 1',
    order: 1,        // Required: getWeeks() queries .orderBy('order')
    weekNumber: 1,
    createdAt: new Date(),
    workoutCount: 1,
  });

  await seedFirestoreDoc(
    `users/${uid}/programs/${programId}/weeks/${weekId}/workouts/${workoutId}`,
    {
      userId: uid,
      id: workoutId,
      weekId,
      programId,
      name: 'E2E Workout',
      orderIndex: 0,   // Required: getWorkouts() queries .orderBy('orderIndex')
      createdAt: new Date(),
      updatedAt: new Date(),  // Required: WorkoutConverter.fromFirestore casts as Timestamp (non-nullable)
      exerciseCount: 1,
    }
  );

  await seedFirestoreDoc(
    `users/${uid}/programs/${programId}/weeks/${weekId}/workouts/${workoutId}/exercises/${exerciseId}`,
    {
      userId: uid,
      id: exerciseId,
      workoutId,
      weekId,
      programId,
      name: 'Bench Press',
      exerciseType: 'strength',
      order: 0,
      createdAt: new Date(),
      updatedAt: new Date(),  // Required: ExerciseConverter.fromFirestore casts as Timestamp (non-nullable)
    }
  );

  await seedFirestoreDoc(
    `users/${uid}/programs/${programId}/weeks/${weekId}/workouts/${workoutId}/exercises/${exerciseId}/sets/${setId}`,
    {
      userId: uid,
      id: setId,
      exerciseId,
      workoutId,
      weekId,
      programId,
      setNumber: 1,
      reps: 5,
      weight: 60,
      checked: false,
      createdAt: new Date(),
      updatedAt: new Date(),  // Required: ExerciseSetConverter.fromFirestore casts as Timestamp (non-nullable)
    }
  );

  console.log(`[global-setup] Test user created: ${TEST_EMAIL} (uid: ${uid})`);
  console.log('[global-setup] Seeded workout hierarchy for E2E tests');
}
