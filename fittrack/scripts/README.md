# Firebase Admin Scripts

This directory contains Node.js scripts for Firebase administration tasks.

## Prerequisites

1. Node.js installed
2. Firebase Admin SDK: `npm install firebase-admin`

## Scripts

### seed_prebuilt_programs.js

Seeds the pre-built workout programs to Firestore.

**For Firebase Emulator:**
```bash
cd fittrack/scripts
npm install firebase-admin
FIRESTORE_EMULATOR_HOST=localhost:8080 node seed_prebuilt_programs.js
```

**For Production:**
```bash
cd fittrack/scripts
npm install firebase-admin
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
node seed_prebuilt_programs.js
```

## Pre-built Programs

The script uploads 5 pre-built training programs:

1. **Push Pull Legs** - 6-day split for intermediate/advanced lifters
2. **Upper Lower Split** - 4-day balanced development program
3. **Full Body 3-Day** - Beginner-friendly full body program
4. **5x5 Strength** - Linear progression strength program
5. **Bro Split** - Classic 5-day bodybuilding split

Programs are stored in the `prebuiltPrograms` collection and are read-only for app users.
