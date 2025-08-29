# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

**FitTrack** is a mobile-first workout tracking app built on Firebase with the following architecture:

- **Client**: Flutter (iOS + Android) 
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Data Structure**: Hierarchical Firestore collections under `users/{userId}/programs/{programId}/weeks/{weekId}/workouts/{workoutId}/exercises/{exerciseId}/sets/{setId}`

## Key Files & Components

### Configuration Files
- `fittrack/firestore.rules` - Complete security rules with per-user data scoping and admin support
- `fittrack/firestore.indexes.json` - Firestore composite indexes for efficient queries

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
- Client-side implementation with batched writes (≤450 ops/batch)
- Selective field copying based on `exerciseType`
- Deep copying: Week → Workouts → Exercises → Sets
- Reset `checked` to false, optionally reset `weight` to null for fresh tracking

### Development Workflow
- This plan should be followed (in order) whenever a new feature, feature update, or bug fix is requested.
- CurrentScreens.md should be reviewed at the start of each session to see what is still in the pipeline to be completed.

1. **Review Documentation**: 
  - Check the document titles in the @Docs folder.
  - Request access to document titles that sound relevant.
  - State why the document would help with development.
2. **Plan & Outline**: 
  - State intentions and list sub-tasks before coding.
3. **Ask for Confirmation**:
  - Propose plans before implementation.
4. **Test-Driven Development**:
  - Review existing tests to help with understanding functionality flows.
  - write new tests aligned defined by the expected outcomes of the new functionality.
  - Update existing tests if necessary.
5. **Iterative Progress**: 
  - Work section by section through the specification.
6. **Clear Communication**:
  - Share reasoning and ask for clarification when needed.
7. **Update Documentation**:
  - Existing documentation files within the @Docs folder should be updated to align with any changes that were made.
  - If the updates do not fit entirely within an already existing document:
    - Create a new document in @Docs for the new functionality
    - Follow the exact same formatting, tone, and level of detail as other, already existing documents.
    - CurrentScreens.md should be updated to reflect the completion of a task within the document.
    - Any new tasks for the next session should be added to CurrentScreens.md or a similar document for tracking status should be created.

## Firebase Configuration

Deploy the provided security rules and indexes:
- `firebase deploy --only firestore:rules`
- `firebase deploy --only firestore:indexes`

## Testing Requirements

- Unit tests for duplication logic and validation
- Integration tests with Firebase Emulator (Auth + Firestore)
- E2E tests for core flows (create program, duplicate week, offline sync)

## Commands
- When asked to deploy the application for testing, a check should be done to see if the emulators are already running before redeploying. If the emulators are already running and accessible then a hot redeploy of the application should be performed. 