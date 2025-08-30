# Workout Tracker — Final Technical Specification

## Table of Contents
1. [Introduction & Purpose](#1-introduction--purpose)  
2. [High-Level Architecture](#2-high-level-architecture)  
3. [Primary Personas & Goals](#3-primary-personas--goals)  
4. [Data Model (Hierarchy & Collections)](#4-data-model-hierarchy--collections)  
5. [Program Management](#5-program-management)  
6. [Week Management](#6-week-management)  
7. [Workout Management](#7-workout-management)  
8. [Exercise Management](#8-exercise-management)  
9. [Set Management](#9-set-management)  
10. [Duplication — Design + Implementation](#10-duplication--design--implementation)  
    - 10.1 [Duplication Principles](#101-duplication-principles)  
    - 10.2 [Callable Cloud Function — `duplicateWeek`](#102-callable-cloud-function---duplicateweek)  
    - 10.3 [Duplication Error Handling, Idempotency & Audit](#103-duplication-error-handling-idempotency--audit)  
    - 10.4 [Security & Triggering Duplication](#104-security--triggering-duplication)  
11. [Data Synchronization & Offline Mode](#11-data-synchronization--offline-mode)  
12. [Authentication & Authorization](#12-authentication--authorization)  
13. [Accessibility & UI Behavior](#13-accessibility--ui-behavior)  
14. [Analytics & Export](#14-analytics--export)  
15. [Notifications (Local Reminders)](#15-notifications-local-reminders)  
16. [Error Handling & Observability](#16-error-handling--observability)  
17. [Testing, Staging & CI/CD](#17-testing-staging--cicd)  
18. [Performance, Indexing & Scalability](#18-performance-indexing--scalability)  

Appendix A: [Firestore security rules (full)](#appendix-a-firestore-security-rules)  
Appendix B: [`firestore.indexes.json` ready-to-deploy](#appendix-b-firestoreindexesjson-ready-to-deploy)  

---

## 1 — Introduction & Purpose

**FitTrack (working name)** is a mobile-first workout tracking app that enables authenticated users to create structured multi-week programs and log workouts at set granularity. Primary features include:

- Program → Week → Workout → Exercise → Set hierarchy.
- Deep duplication (user self-duplication of weeks/programs/workouts).
- Offline-first support via Firestore caches.
- Local reminders and client-side analytics.
- Security-first approach: per-user data scoping and validation in Firestore rules.

This document is a complete handoff spec for developers or AI-driven code generation tools (Claude Code / Cursor). It contains functional requirements, data schema, security rules, index recommendations, and a production-ready Cloud Function to implement duplication reliably.

---

## 2 — High-Level Architecture

**Client:** Flutter (iOS + Android) — or alternative cross-platform stack.  
**Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions).  
**Notifications:** OS-native local notifications via Flutter plugin.  
**Analytics:** Client-side aggregation (no server analytics in v1).  
**Sync:** Firestore offline persistence and snapshot listeners, with queued writes.

Conceptually:

```
[Mobile App (Flutter)]
  ├─ Firebase Auth (signin)
  ├─ Firestore (hierarchical data under users/{userId})
  ├─ Firebase Storage (optional media)
  ├─ Local Notifications (reminders)
  └─ Client Analytics Engine (charts)
[Firebase Cloud]
  ├─ Cloud Functions (duplication, maintenance, cascade deletes)
  └─ Firestore/Storage
```

---

## 3 — Primary Personas & Goals

- **Casual Gym-goer (Sam):** Quick logging with minimal friction. Duplicates weeks occasionally to repeat routines.
- **Serious Trainee (Alex):** Needs accurate tracking of sets, reps, and progression. Uses duplication for progression tests.
- **Coach (future):** Would like to create and share programs with clients (out of scope v1).

Success criteria:
- Users can create a program and log workouts quickly.
- Duplication of a typical week (< 50 sets) completes reliably under 10 seconds.
- Data integrity and privacy are maintained.

---

## 4 — Data Model (Hierarchy & Collections)

Canonical structure (hierarchical under each user):

```
users/{userId}/
  programs/{programId}/
    weeks/{weekId}/
      workouts/{workoutId}/
        exercises/{exerciseId}/
          sets/{setId}
```

Every document will include a `userId` field (string) duplicating `request.auth.uid` to simplify queries and indexing.

### Collections & Document Fields (detailed)

**users/{userId} (document)**
- `displayName`: string  
- `email`: string  
- `createdAt`: timestamp  
- `lastLogin`: timestamp  
- `settings`: map (e.g., unitPreference, theme)  

**users/{userId}/programs/{programId} (document)**
- `name`: string (required, <=100 chars)  
- `description`: string (optional, <=500)  
- `createdAt`, `updatedAt`: timestamp  
- `userId`: string (redundant ownership field)  

**users/{userId}/programs/{programId}/weeks/{weekId}**  
- `name`: string (default "Week {order}")  
- `order`: integer (1-based)  
- `notes`: string (optional)  
- `createdAt`, `updatedAt`  
- `userId`: string  

**users/{userId}/programs/{programId}/weeks/{weekId}/workouts/{workoutId}**  
- `name`: string  
- `dayOfWeek`: integer (1–7 optional)  
- `orderIndex`: integer  
- `notes`: string  
- `createdAt`, `updatedAt`  
- `userId`: string  

**users/{userId}/programs/{programId}/weeks/{weekId}/workouts/{workoutId}/exercises/{exerciseId}**  
- `name`: string  
- `exerciseType`: string enum (`strength`, `cardio`, `bodyweight`, `custom`)  
- `orderIndex`: integer  
- `notes`: string  
- `createdAt`, `updatedAt`  
- `userId`: string  

**users/{userId}/programs/{programId}/weeks/{weekId}/workouts/{workoutId}/exercises/{exerciseId}/sets/{setId}**  
- `setNumber`: integer  
- `reps`: integer (nullable)  
- `weight`: number (nullable)  
- `duration`: integer (seconds, nullable)  
- `distance`: number (meters, nullable)  
- `restTime`: integer (seconds, nullable)  
- `checked`: boolean (completed)  
- `notes`: string  
- `createdAt`, `updatedAt`  
- `userId`: string  

**Notes on denormalization:** storing `userId` and parent IDs in child documents helps fast filtering and simplifies security rules and indexing. This is intentional.

---

## 5 — Program Management

**Features**
- Create/Edit/Delete Programs.
- View program details (list of weeks).
- Archive programs (`isArchived` boolean) for soft-delete (optional).
- Duplicate program via duplication service.

**Behavioral rules**
- `name` required, trimmed, max length enforced client- and server-side.
- On delete: cascade delete weeks & child docs via Cloud Function (not client-only).

**Edge cases**
- Prevent duplicate program names for same user (enforce client-side and optionally server-side check).

---

## 6 — Week Management

**Features**
- Create/Edit/Delete Weeks inside a program.
- Order maintained via `order` field.
- Duplicate Week (deep copy of workouts/exercises/sets).
- Reorder weeks with adjustments applied to sibling `order` values.

**Behavioral rules**
- `order` must be unique within a program (reindexing performed when needed).
- Deleting a week cascades to delete its workouts/exercises/sets through Cloud Function.

---

## 7 — Workout Management

**Features**
- Create/Edit/Delete workouts in a week.
- Workouts include `name`, `dayOfWeek`, `notes`, `orderIndex`.
- Reorder workouts; drag-and-drop in UI persists order.

**Behavioral rules**
- `dayOfWeek` values validated (1–7) if used.
- Deleting a workout triggers cascade delete for exercises/sets.

---

## 8 — Exercise Management

**Features**
- Create/Edit/Delete exercise instances in a workout.
- Exercises link to a master definition in a future “exercise library” (optional) but contain all needed metadata locally.
- `exerciseType` drives UI: which set fields are shown and validated.

**Exercise Types & Corresponding set fields**
- `strength` → `reps` (required), `weight` (optional), `restTime`  
- `cardio` or `time-based` → `duration` (required), `distance` (optional)  
- `bodyweight` → `reps` (required)  
- `custom` → flexible; app shows user-configured fields

**Behavioral rules**
- Type change warning: changing an exercise's type may remove non-applicable set fields.

---

## 9 — Set Management

**Features**
- CRUD sets under an exercise.
- Fields: `setNumber`, `reps`, `weight`, `duration`, `distance`, `restTime`, `checked`, `notes`.
- Order is preserved; reordering updates `setNumber`/`order`.

**Validation**
- At least one metric required per set (`reps` OR `duration` OR `distance`).
- Numeric fields must be non-negative.
- Timestamps auto-set by server.

---

## 10 — Duplication — Design & Implementation

Duplication is centralized and must be consistent across UI and API. Users may duplicate a Week (common), Workout, or Exercise. For reliability and data integrity, duplication will be implemented server-side as a **callable Cloud Function**.

### 10.1 Duplication Principles

- **Per-user self-duplication only**: A user can only duplicate their own data.
- **Deep copy**: Duplicating a Week will duplicate Workouts → Exercises → Sets.
- **Selective Set copying**: Sets should copy only relevant fields based on `exerciseType`. Example:
  - For `strength` → copy `setNumber`, `reps`, `weight`, `exerciseType`, reset `checked` to false.
  - For `cardio` → copy `duration`, optional `distance`; reset other irrelevant fields.
- **Timestamps**: New copies get new `createdAt` and `updatedAt`.
- **IDs**: New documents get new Firestore-generated IDs.
- **Atomicity**: Use batched writes (<= 500 writes/batch). If >500 writes required, commit batches in sequence.
- **Idempotency**: Client-side double-tap prevention is sufficient; server does not guarantee idempotency by default.
- **Audit**: Log duplication events for debugging & monitoring.

### 10.2 Client-Side Duplication Implementation

**Note**: The duplication functionality has been implemented client-side using batched Firestore writes instead of Cloud Functions for better performance and reduced complexity. The implementation is available in `FirestoreService.duplicateWeek()` method.

**Key Features of Client-Side Implementation:**
- Batched writes with proper chunking (450 ops/batch limit)
- Exercise type-specific field copying for sets
- Proper error handling and rollback
- Returns mapping of old IDs to new IDs for UI updates
- Maintains all security through Firestore rules

### 10.3 Duplication Error Handling, Idempotency & Audit

**Error Handling**
- If credential/ownership failure: return `permission-denied`.
- If source not found: return `not-found`.
- On batched commit failure: log, optionally retry, return `partial: true` with created IDs.

**Idempotency**
- Client-side double-tap prevention is sufficient per decision. No server-side requestId tracking implemented in v1.

**Audit**
- Cloud Logging entries for duplication events (`userId`, `sourceWeekId`, `newWeekId`, timestamp).

**Security**
- Client-side implementation leverages Firestore security rules for ownership validation
- All operations validated through existing security rules with `request.auth.uid == userId` checks
- Admin role: implement via custom claim `admin: true` for support access; admins can be allowed expanded read-only operations via rules.

---

## 11 — Data Synchronization & Offline Mode

**Requirements**
- Firestore offline persistence enabled on clients.
- Local queued writes accepted while offline; Firestore SDK will sync when online.
- Conflict resolution: default **Last Write Wins** using `updatedAt`. For certain fields (arrays, order indices) consider custom merge strategies.
- Include `lastModified` and `modifiedByDeviceId` in records to help merge resolution.

**Implementation Notes**
- Use Firestore snapshot listeners sparingly to avoid unnecessary reads.
- For reordering operations, use batched updates to ensure consistent order.

---

## 12 — Authentication & Authorization

**Auth**
- Firebase Authentication (email/password), optional Google/Apple sign-in later.
- Password policy: minimum 8 characters with at least one letter and one number (client-enforced).

**Authorization**
- Per-user document scoping under `users/{userId}`.
- Firestore rules verify `request.auth.uid == userId`.
- **Admin role** added via custom claims (`request.auth.token.admin == true`). Admins are intended for support (read-only) and maintenance tasks, not regular app users.

---

## 13 — Accessibility & UI Behavior

- WCAG 2.1 AA compliance where applicable.
- Dynamic scaling of UI elements based on display size (phones and tablets).
- Support large fonts, voice-over/talkback, and minimum touch target 44×44pt.
- Ensure color contrast and accessible labels on all actionable items.

---

## 14 — Analytics & Export

**Client-side analytics**
- Track workout count, exercise frequency, and weekly volume.
- Calculate personal records (PRs) like highest `weight × reps`.

**Export**
- Export selected Program/Week/Workout to JSON or CSV including nested data.
- Include metadata (timestamps, ids) to enable re-import if necessary.
- Export endpoints can be implemented as callable Cloud Functions or built client-side.

---

## 15 — Notifications (Local Reminders)

- Local notifications scheduled on-device (no server push in v1).
- Users configure reminder times and repeat schedules in settings.
- Use OS-native scheduling to ensure reminders fire reliably.

---

## 16 — Error Handling & Observability

**User-facing**
- Friendly messages for validation/network errors.
- Retry options with preserved user input.

**Developer-facing**
- Crashlytics for uncaught exceptions.
- Cloud Logging for Cloud Functions and duplication events.
- Structured logs for failure diagnosis.

---

## 17 — Testing, Staging & CI/CD

**Testing**
- Unit tests for business logic (duplication, validation).
- Integration tests with Firebase Emulator (Auth + Firestore).
- E2E tests for core flows (create program, duplicate week, sync offline data).

**Environments**
- Dev (local emulator), Staging (internal testers), Prod.

**CI/CD**
- Automated test suite on PR.
- Deploy Cloud Functions via CI (Firebase CLI) to staging/prod with proper service accounts.
- Release to beta testers via Firebase App Distribution.

---

## 18 — Performance, Indexing & Scalability

**Performance**
- Use pagination and lazy loading for lists (programs, history).
- Limit Firestore listeners to views in use.

**Scalability**
- Keep queries indexed by `userId` and sorting fields like `createdAt` or `orderIndex`.
- Use batched writes and chunking for duplication and bulk operations.

**Index Recommendations**
- Composite indexes where queries filter by `userId` and sort by `createdAt` or `orderIndex`.
- `collectionGroup` indexes for queries across nested subcollections (e.g., all `workouts` for a user across programs).

---

# Appendix A — Firestore Security Rules (full template)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() { return request.auth != null; }
    function isOwner(userId) { return isSignedIn() && request.auth.uid == userId; }
    function isAdmin() { return isSignedIn() && request.auth.token.admin == true; }

    // Validate data helpers
    function isString(v) { return v is string; }
    function isNumber(v) { return v is int || v is float; }
    function isTimestamp(v) { return v is timestamp; }

    // -----------------------------------------------------
    // Top-level user node: each user's data lives under users/{userId}
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isSignedIn() && request.auth.uid == userId;
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin(); // admin-only deletes

      // Programs subcollection
      match /programs/{programId} {
        allow read: if isOwner(userId) || isAdmin();
        allow create: if isOwner(userId);
        allow update, delete: if isOwner(userId) || isAdmin();

        function validProgram(data) {
          return (!data.name || isString(data.name) && data.name.size() <= 100)
            && (!data.description || isString(data.description) && data.description.size() <= 500)
            && (!data.createdAt || isTimestamp(data.createdAt))
            && (!data.userId || request.auth.uid == data.userId);
        }
        allow write: if (isOwner(userId) || isAdmin()) && validProgram(request.resource.data);

        // Weeks subcollection
        match /weeks/{weekId} {
          allow read: if isOwner(userId) || isAdmin();
          allow create: if isOwner(userId);
          allow update, delete: if isOwner(userId) || isAdmin();

          function validWeek(data) {
            return (!data.name || isString(data.name))
              && (!data.order || isNumber(data.order))
              && (!data.createdAt || isTimestamp(data.createdAt))
              && (!data.userId || request.auth.uid == data.userId);
          }
          allow write: if (isOwner(userId) || isAdmin()) && validWeek(request.resource.data);

          // Workouts
          match /workouts/{workoutId} {
            allow read: if isOwner(userId) || isAdmin();
            allow create: if isOwner(userId);
            allow update, delete: if isOwner(userId) || isAdmin();

            function validWorkout(data) {
              return (!data.name || isString(data.name))
                && (!data.orderIndex || isNumber(data.orderIndex))
                && (!data.dayOfWeek || (isNumber(data.dayOfWeek) && data.dayOfWeek >= 1 && data.dayOfWeek <= 7))
                && (!data.userId || request.auth.uid == data.userId);
            }
            allow write: if (isOwner(userId) || isAdmin()) && validWorkout(request.resource.data);

            // Exercises
            match /exercises/{exerciseId} {
              allow read: if isOwner(userId) || isAdmin();
              allow create: if isOwner(userId);
              allow update, delete: if isOwner(userId) || isAdmin();

              function validExercise(data) {
                return (!data.name || isString(data.name))
                  && (!data.exerciseType || isString(data.exerciseType))
                  && (!data.orderIndex || isNumber(data.orderIndex))
                  && (!data.userId || request.auth.uid == data.userId);
              }
              allow write: if (isOwner(userId) || isAdmin()) && validExercise(request.resource.data);

              // Sets
              match /sets/{setId} {
                allow read: if isOwner(userId) || isAdmin();
                allow create: if isOwner(userId);
                allow update, delete: if isOwner(userId) || isAdmin();

                function validSet(data) {
                  // At least one metric present
                  let hasMetric = (data.reps != null) || (data.duration != null) || (data.distance != null);
                  return (!data.setNumber || isNumber(data.setNumber))
                    && hasMetric
                    && (!data.weight || isNumber(data.weight) && data.weight >= 0)
                    && (!data.reps || isNumber(data.reps) && data.reps >= 0)
                    && (!data.duration || isNumber(data.duration) && data.duration >= 0)
                    && (!data.distance || isNumber(data.distance) && data.distance >= 0)
                    && (!data.userId || request.auth.uid == data.userId);
                }
                allow write: if (isOwner(userId) || isAdmin()) && validSet(request.resource.data);
              } // end sets
            } // end exercises
          } // end workouts
        } // end weeks
      } // end programs
    } // end users
  }
}
```

---

---

# Appendix B — firestore.indexes.json (ready to deploy)

```json
{
  "indexes": [
    {
      "collectionGroup": "programs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "weeks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "workouts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "orderIndex", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "exercises",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "exerciseType", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "sets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "setNumber", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```


