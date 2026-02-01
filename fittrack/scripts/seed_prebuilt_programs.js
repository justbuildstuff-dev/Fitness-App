/**
 * Firebase Admin Script: Seed Pre-built Programs
 *
 * This script uploads pre-built workout programs to the Firestore
 * 'prebuiltPrograms' collection for the FitTrack app.
 *
 * Usage:
 *   1. Ensure you have a Firebase service account key
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to the key path
 *   3. Run: node scripts/seed_prebuilt_programs.js
 *
 * Or for Firebase emulator:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 node scripts/seed_prebuilt_programs.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
// Uses GOOGLE_APPLICATION_CREDENTIALS environment variable or emulator
if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log('Using Firestore emulator at:', process.env.FIRESTORE_EMULATOR_HOST);
  admin.initializeApp({
    projectId: 'fittrack-demo'
  });
} else {
  admin.initializeApp();
}

const db = admin.firestore();

// Collection name for pre-built programs
const COLLECTION_NAME = 'prebuiltPrograms';

/**
 * Convert JavaScript Date-like objects to Firestore Timestamps
 */
function convertDatesToTimestamps(obj) {
  const now = admin.firestore.Timestamp.now();

  if (Array.isArray(obj)) {
    return obj.map(item => convertDatesToTimestamps(item));
  }

  if (obj !== null && typeof obj === 'object') {
    const result = {};
    for (const [key, value] of Object.entries(obj)) {
      if (key === 'createdAt' || key === 'updatedAt') {
        result[key] = now;
      } else {
        result[key] = convertDatesToTimestamps(value);
      }
    }
    return result;
  }

  return obj;
}

/**
 * Seed pre-built programs to Firestore
 */
async function seedPrograms() {
  console.log('Loading pre-built programs from JSON...');

  // Load the JSON file
  const jsonPath = path.join(__dirname, '../assets/data/prebuilt_programs.json');
  const jsonContent = fs.readFileSync(jsonPath, 'utf8');
  const data = JSON.parse(jsonContent);

  if (!data.programs || !Array.isArray(data.programs)) {
    throw new Error('Invalid JSON structure: expected { programs: [...] }');
  }

  console.log(`Found ${data.programs.length} programs to seed.`);

  // Clear existing pre-built programs (optional - comment out to preserve existing)
  console.log('Clearing existing pre-built programs...');
  const existingDocs = await db.collection(COLLECTION_NAME).get();
  const deletePromises = existingDocs.docs.map(doc => doc.ref.delete());
  await Promise.all(deletePromises);
  console.log(`Deleted ${existingDocs.size} existing programs.`);

  // Add each program
  console.log('Uploading new programs...');
  const batch = db.batch();

  for (const program of data.programs) {
    // Use the program's id as the document ID
    const docRef = db.collection(COLLECTION_NAME).doc(program.id);

    // Add timestamps
    const programWithTimestamps = {
      ...convertDatesToTimestamps(program),
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    };

    batch.set(docRef, programWithTimestamps);
    console.log(`  - Added: ${program.name} (${program.id})`);
  }

  // Commit the batch
  await batch.commit();
  console.log(`\nSuccessfully seeded ${data.programs.length} pre-built programs!`);

  // Verify the upload
  console.log('\nVerifying upload...');
  const verifyDocs = await db.collection(COLLECTION_NAME).get();
  console.log(`Found ${verifyDocs.size} programs in Firestore.`);

  for (const doc of verifyDocs.docs) {
    const data = doc.data();
    console.log(`  - ${data.name}: ${data.weeks?.length || 0} weeks, ${
      data.weeks?.[0]?.workouts?.length || 0
    } workouts/week`);
  }
}

// Run the seeder
seedPrograms()
  .then(() => {
    console.log('\nSeeding complete!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Error seeding programs:', error);
    process.exit(1);
  });
