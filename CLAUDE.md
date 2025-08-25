# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

**FitTrack** is a mobile-first workout tracking app built on Firebase with the following architecture:

- **Client**: Flutter (iOS + Android) 
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **Data Structure**: Hierarchical Firestore collections under `users/{userId}/programs/{programId}/weeks/{weekId}/workouts/{workoutId}/exercises/{exerciseId}/sets/{setId}`

## Key Files & Components

### Code Samples
- `Code Samples/duplicateWeek.js` - Production-ready Cloud Function for week duplication with batched writes
- `Code Samples/Firestore.rules` - Complete security rules with per-user data scoping and admin support
- `Code Samples/firestore.indexes.json` - Firestore composite indexes for efficient queries

### Documentation
- `Docs/Workout_Tracker_Final_Spec.md` - Complete technical specification with data models, security rules, and implementation details
- `Docs/original_README.md` - Collaboration guidelines for working with Claude Code
- `Docs/*` - Includes all documentation for the project and should be reviewed when getting context for the current task. Documents exist for each component of the application and there is also and architectural overview. You should ask for the necessary document to be added for context when implementing changes. The Architectural Overview should be requested when adding new functionality or cross-component updates to make sure the updates align with the vision for the application.

## Data Model

The app uses a strict hierarchical structure:
```
users/{userId}/
  programs/{programId}/
    weeks/{weekId}/
      workouts/{workoutId}/
        exercises/{exerciseId}/
          sets/{setId}
```

Every document includes a `userId` field for security and efficient querying.

## Security & Authorization

- **Authentication**: Firebase Auth with per-user data scoping
- **Authorization**: Firestore rules enforce `request.auth.uid == userId` 
- **Admin Role**: Custom claims with `admin: true` for support operations
- **Validation**: Server-side validation for all document fields and types

## Key Implementation Patterns

### Exercise Types & Set Fields
- `strength` → `reps` (required), `weight` (optional), `restTime`
- `cardio`/`time-based` → `duration` (required), `distance` (optional)  
- `bodyweight` → `reps` (required)
- `custom` → flexible user-configured fields

### Duplication Strategy
- Server-side Cloud Functions with batched writes (≤450 ops/batch)
- Selective field copying based on `exerciseType`
- Deep copying: Week → Workouts → Exercises → Sets
- Reset `checked` to false, optionally reset `weight` to null for fresh tracking

### Development Workflow
1. **Plan & Outline**: State intentions and list sub-tasks before coding
2. **Ask for Confirmation**: Propose plans before implementation
3. **Test-Driven Development**: Write tests before code implementation
4. **Iterative Progress**: Work section by section through the specification
5. **Clear Communication**: Share reasoning and ask for clarification when needed

## Firebase Configuration

Deploy the provided security rules and indexes:
- `firebase deploy --only firestore:rules`
- `firebase deploy --only firestore:indexes` 
- `firebase deploy --only functions` (for duplicateWeek function)

## Testing Requirements

- Unit tests for duplication logic and validation
- Integration tests with Firebase Emulator (Auth + Firestore)
- E2E tests for core flows (create program, duplicate week, offline sync)

## Commands
- When asked to deploy the application for testing, a check should be done to see if the emulators are already running before redeploying. If the emulators are already running and accessible then a hot redeploy of the application should be performed. 