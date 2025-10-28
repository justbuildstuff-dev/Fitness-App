# Technical Design: Login Data Loading Fix

**Issue:** #47 - Programs not loading on initial login to app
**Status:** Design Phase
**Created:** 2025-10-26
**Last Updated:** 2025-10-26

## Table of Contents
1. [Overview](#overview)
2. [Problem Analysis](#problem-analysis)
3. [Root Cause](#root-cause)
4. [Proposed Solution](#proposed-solution)
5. [Architecture](#architecture)
6. [Implementation Details](#implementation-details)
7. [Testing Strategy](#testing-strategy)
8. [Rollout Plan](#rollout-plan)
9. [Success Metrics](#success-metrics)

---

## Overview

### Problem Statement
When users log into the FitTrack app, both the Programs screen and Analytics screen show the "Something went wrong" error page. The refresh button on Analytics page resolves both errors, but the retry button on either page does not work. This requires users to manually refresh on every app launch.

### Impact
- **Severity:** HIGH - Affects 100% of users on every app launch
- **User Experience:** Critical first impression issue - users see errors immediately after login
- **Workaround:** Manual refresh on Analytics page (not intuitive)
- **Platforms:** Android (confirmed), likely iOS as well

### Goal
Ensure Programs and Analytics data load successfully immediately after login without manual intervention or error states.

---

## Problem Analysis

### Current Behavior Flow

```
User Login
    ↓
AuthProvider._authStateChanges() fires
    ↓
AuthProvider sets _user = user
    ↓
AuthProvider calls notifyListeners()
    ↓
ChangeNotifierProxyProvider triggered
    ↓
Creates NEW ProgramProvider(authProvider.user?.uid)
    ↓                           ↓
HomeScreen.initState()    Provider update cycle
calls loadPrograms()      (async, timing unknown)
    ↓
ProgramProvider.loadPrograms() called
    ↓
Checks if (_userId == null)
    ↓
**RACE CONDITION**
    ↓
If provider not updated yet:
  - _userId is null
  - Silent return (no error set)
  - UI shows loading indefinitely
```

### Why This Happens

**1. Provider Creation Timing:**
- `ChangeNotifierProxyProvider` initially creates `ProgramProvider(null)` at app startup
- When user logs in, AuthProvider notifies listeners
- Provider rebuilds with new userId, but this is asynchronous
- `HomeScreen.initState()` may execute before the new provider is available

**2. Silent Failure:**
```dart
void loadPrograms() {
  if (_userId == null) return;  // Silent failure - no error state set
  // ... rest of loading logic
}
```
- If `_userId` is null, function exits without setting `_error`
- UI never knows the load failed, stays in loading state forever

**3. Why Refresh Works But Retry Doesn't:**
- **Retry button:** Calls `clearError()` + `loadPrograms()` on potentially stale provider reference
- **Refresh button:** By the time user manually clicks it, provider has correct userId
- Time delay allows `ChangeNotifierProxyProvider` to complete its update cycle

**4. Why Both Screens Affected:**
- Both ProgramsScreen and AnalyticsScreen call load methods in their `initState()`
- Both methods have `if (_userId == null) return;` guards
- Both screens reference the same ProgramProvider instance
- When refresh is called on Analytics, it fixes the provider for both screens

---

## Root Cause

### Race Condition Summary

**Primary Issue:** HomeScreen initialization races with ProgramProvider userId update

**Contributing Factors:**
1. `ChangeNotifierProxyProvider.update()` is asynchronous
2. `HomeScreen.initState()` + `addPostFrameCallback()` doesn't wait for provider update
3. Silent failure in `loadPrograms()` and `loadAnalytics()` when userId is null
4. No retry mechanism or auto-reload when userId becomes available

**Evidence from PRD:**
- BA Agent identified the exact race condition in [Notion PRD](https://www.notion.so/Fix-Programs-Not-Loading-on-Initial-Login-298879be57898113bef1d319e34a0abf)
- Root cause confirmed through code analysis

---

## Proposed Solution

### Solution Strategy

We'll implement a **multi-layered fix** that addresses the race condition at multiple points:

1. **Auto-load in ProgramProvider:** Automatically load data when userId becomes available
2. **Explicit error handling:** Set error state instead of silent failures
3. **Improved initialization flow:** Ensure screens don't call load methods prematurely
4. **Better retry logic:** Fix retry button to work correctly

### Architecture Decision

**Selected Approach:** Provider-side auto-loading with listener pattern

**Why This Approach:**
- ✅ Centralized logic in ProgramProvider (single source of truth)
- ✅ Screens don't need to worry about timing
- ✅ Works for all login scenarios (fresh login, logout→login, persisted auth)
- ✅ Minimal changes to existing screen code
- ✅ No breaking changes to public APIs

**Alternatives Considered:**

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Provider auto-load** | Centralized, automatic, handles all cases | Adds internal complexity | ✅ **SELECTED** |
| **Screen-side delays** | Simple, minimal changes | Brittle, depends on timing guesses | ❌ Rejected |
| **Remove ChangeNotifierProxyProvider** | No race condition | Major refactor, breaking changes | ❌ Too risky |
| **Builder pattern** | Fine-grained control | More complex screen code | ❌ Not needed |

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         main.dart                            │
│                                                              │
│  MultiProvider                                              │
│    ├─ AuthProvider                                          │
│    │    └─ Listens to FirebaseAuth.authStateChanges()     │
│    │    └─ Calls notifyListeners() on auth state change   │
│    │                                                        │
│    └─ ChangeNotifierProxyProvider<AuthProvider, ProgramProvider>
│         ├─ create: ProgramProvider(null)                   │
│         └─ update: ProgramProvider(authProvider.user?.uid) │
│              │                                              │
│              └─ NEW: Auto-loads data when userId set       │
└──────────────────────────────────────────────────────────────┘
                           │
                           ├──────────────────┐
                           │                  │
        ┌──────────────────▼────┐   ┌────────▼────────────┐
        │   ProgramsScreen       │   │  AnalyticsScreen    │
        │                        │   │                     │
        │  ✓ No initState call   │   │ ✓ No initState call │
        │  ✓ Provider auto-loads │   │ ✓ Provider auto-loads│
        └────────────────────────┘   └─────────────────────┘
```

### Data Flow

**Before Fix (Race Condition):**
```
Login → AuthProvider update → ChangeNotifierProxyProvider update
                                          │
                    ┌─────────────────────┴─────────────────────┐
                    │ RACE CONDITION                            │
                    ▼                                           ▼
        HomeScreen.initState()                    ProgramProvider(userId)
                    │                                   created
        loadPrograms() called                              │
                    │                                      │
        _userId == null? ─YES→ Silent return          Still being created
                    │
            Stuck in loading state
```

**After Fix (Auto-load):**
```
Login → AuthProvider update → ChangeNotifierProxyProvider update
                                          │
                                          ▼
                             ProgramProvider constructor
                                    _userId = userId
                                          │
                                          ▼
                             Is _userId != null && != _previousUserId?
                                          │
                                        YES
                                          │
                                          ▼
                             Auto-load programs + analytics
                                          │
                                          ▼
                            notifyListeners() → Screens update
                                          │
                                          ▼
                                   Data displayed
```

---

## Implementation Details

### 1. ProgramProvider Constructor Enhancement

**File:** `fittrack/lib/providers/program_provider.dart`

**Changes:**

```dart
class ProgramProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AnalyticsService _analyticsService;
  final String? _userId;
  String? _previousUserId; // NEW: Track previous userId to detect changes

  ProgramProvider(this._userId)
    : _firestoreService = FirestoreService.instance,
      _analyticsService = AnalyticsService.instance {
    // NEW: Auto-load data when userId is set and has changed
    _autoLoadDataIfNeeded();
  }

  // Constructor for testing with dependency injection
  ProgramProvider.withServices(
    this._userId,
    this._firestoreService,
    this._analyticsService
  ) {
    // NEW: Auto-load data for testing constructor too
    _autoLoadDataIfNeeded();
  }

  /// NEW: Auto-load programs and analytics when userId becomes available
  void _autoLoadDataIfNeeded() {
    // Only load if we have a userId and it's different from previous
    if (_userId != null && _userId != _previousUserId) {
      _previousUserId = _userId;

      // Schedule load for next frame to avoid calling notifyListeners during build
      Future.microtask(() {
        loadPrograms();
        loadAnalytics();
      });
    }
  }
}
```

**Why Future.microtask?**
- Ensures we don't call `notifyListeners()` during the provider's constructor/update
- Schedules the work for the next event loop cycle
- Avoids "setState called during build" errors

### 2. Improve Error Handling in Load Methods

**File:** `fittrack/lib/providers/program_provider.dart`

**Current Silent Failure:**
```dart
void loadPrograms() {
  if (_userId == null) return; // Silent - no error set
  // ...
}

Future<void> loadAnalytics({DateRange? dateRange}) async {
  if (_userId == null) return; // Silent - no error set
  // ...
}
```

**Enhanced with Explicit Error:**
```dart
void loadPrograms() {
  if (_userId == null) {
    _error = 'User not authenticated. Please log in to view your programs.';
    _isLoadingPrograms = false;
    notifyListeners();
    debugPrint('[ProgramProvider] loadPrograms called with null userId');
    return;
  }

  _isLoadingPrograms = true;
  _error = null;
  notifyListeners();

  // ... rest of existing logic
}

Future<void> loadAnalytics({DateRange? dateRange}) async {
  if (_userId == null) {
    _error = 'User not authenticated. Please log in to view analytics.';
    _isLoadingAnalytics = false;
    notifyListeners();
    debugPrint('[ProgramProvider] loadAnalytics called with null userId');
    return;
  }

  try {
    _isLoadingAnalytics = true;
    _error = null;
    notifyListeners();

    // ... rest of existing logic
  } catch (e) {
    _error = 'Failed to load analytics: $e';
    _isLoadingAnalytics = false;
    debugPrint('[ProgramProvider] loadAnalytics error: $e');
    notifyListeners();
  }
}
```

**Benefits:**
- Clear error messages for debugging
- UI can show appropriate error states instead of infinite loading
- Console logs help diagnose timing issues

### 3. Remove Manual Load Calls from Screens

**File:** `fittrack/lib/screens/home/home_screen.dart`

**Current Code (Lines 20-34):**
```dart
@override
void initState() {
  super.initState();
  _screens = [
    const ProgramsScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  // Load programs when home screen initializes
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    programProvider.loadPrograms(); // ← REMOVE THIS
  });
}
```

**New Code:**
```dart
@override
void initState() {
  super.initState();
  _screens = [
    const ProgramsScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  // No need to manually load - ProgramProvider auto-loads when userId is set
  // Removed: programProvider.loadPrograms() call
}
```

**File:** `fittrack/lib/screens/analytics/analytics_screen.dart`

**Current Code (Lines 20-27):**
```dart
@override
void initState() {
  super.initState();
  // Load analytics data when screen is first displayed
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ProgramProvider>().loadAnalytics(); // ← REMOVE THIS
  });
}
```

**New Code:**
```dart
@override
void initState() {
  super.initState();

  // No need to manually load - ProgramProvider auto-loads when userId is set
  // Removed: loadAnalytics() call
}
```

**Why Remove These Calls:**
- ProgramProvider now auto-loads data when initialized with valid userId
- Prevents race condition where screens call load before provider is ready
- Screens only need to handle retry/refresh actions, not initial load

### 4. Add Debug Logging for Timing Analysis

**File:** `fittrack/lib/main.dart`

Add logging to track provider lifecycle:

```dart
ChangeNotifierProxyProvider<app_auth.AuthProvider, ProgramProvider>(
  create: (_) {
    debugPrint('[Provider] Creating initial ProgramProvider with null userId');
    return ProgramProvider(null);
  },
  update: (_, authProvider, previousProgramProvider) {
    final userId = authProvider.user?.uid;
    debugPrint('[Provider] Updating ProgramProvider with userId: ${userId ?? 'null'}');
    return ProgramProvider(userId);
  },
),
```

**File:** `fittrack/lib/providers/auth_provider.dart`

Add logging to auth state changes (line 28):

```dart
_authStateSubscription = _auth.authStateChanges().listen((User? user) {
  debugPrint('[AuthProvider] Auth state changed - userId: ${user?.uid ?? 'null'}');
  _user = user;
  if (user != null) {
    _loadUserProfile();
  } else {
    _userProfile = null;
  }
  notifyListeners();
});
```

**Benefits:**
- Helps diagnose any remaining timing issues in production
- Can be disabled in release builds via kDebugMode check
- Provides clear audit trail of initialization sequence

### 5. Improve Retry Logic

**Current Issue:** Retry button may still reference stale provider

**Fix:** Ensure retry always gets fresh provider reference

**File:** `fittrack/lib/screens/programs/programs_screen.dart` (Line 33-36)

**Current:**
```dart
onRetry: () {
  programProvider.clearError();
  programProvider.loadPrograms();
},
```

**Enhanced:**
```dart
onRetry: () {
  // Get fresh provider reference in case it was recreated
  final provider = Provider.of<ProgramProvider>(context, listen: false);
  provider.clearError();
  provider.loadPrograms();
},
```

**File:** `fittrack/lib/screens/analytics/analytics_screen.dart` (Line 87)

**Current:**
```dart
onRetry: () => provider.loadAnalytics(),
```

**Enhanced:**
```dart
onRetry: () {
  // Get fresh provider reference in case it was recreated
  final freshProvider = Provider.of<ProgramProvider>(context, listen: false);
  freshProvider.clearError();
  freshProvider.loadAnalytics();
},
```

---

## Testing Strategy

### Unit Tests

**File:** `fittrack/test/providers/program_provider_test.dart`

**New Test Cases:**

```dart
group('Auto-load on initialization', () {
  test('should auto-load programs and analytics when userId is set', () async {
    final mockFirestore = MockFirestoreService();
    final mockAnalytics = MockAnalyticsService();

    // Setup mocks
    when(mockFirestore.getPrograms(any))
        .thenAnswer((_) => Stream.value([]));

    // Create provider with userId
    final provider = ProgramProvider.withServices(
      'test-user-id',
      mockFirestore,
      mockAnalytics,
    );

    // Wait for microtask to complete
    await Future.delayed(Duration.zero);

    // Verify auto-load was called
    verify(mockFirestore.getPrograms('test-user-id')).called(1);
    verify(mockAnalytics.generateWorkoutAnalytics(any, any)).called(1);
  });

  test('should not auto-load when userId is null', () async {
    final mockFirestore = MockFirestoreService();
    final mockAnalytics = MockAnalyticsService();

    // Create provider without userId
    final provider = ProgramProvider.withServices(
      null,
      mockFirestore,
      mockAnalytics,
    );

    await Future.delayed(Duration.zero);

    // Verify no load calls were made
    verifyNever(mockFirestore.getPrograms(any));
    verifyNever(mockAnalytics.generateWorkoutAnalytics(any, any));
  });

  test('should not reload when userId has not changed', () async {
    final mockFirestore = MockFirestoreService();
    final mockAnalytics = MockAnalyticsService();

    when(mockFirestore.getPrograms(any))
        .thenAnswer((_) => Stream.value([]));

    // Create provider with userId
    final provider = ProgramProvider.withServices(
      'test-user-id',
      mockFirestore,
      mockAnalytics,
    );

    await Future.delayed(Duration.zero);
    clearInteractions(mockFirestore);

    // Call auto-load again with same userId
    provider._autoLoadDataIfNeeded(); // Test internal method
    await Future.delayed(Duration.zero);

    // Should not reload
    verifyNever(mockFirestore.getPrograms(any));
  });
});

group('Error handling for null userId', () {
  test('loadPrograms should set error when userId is null', () async {
    final provider = ProgramProvider.withServices(
      null,
      MockFirestoreService(),
      MockAnalyticsService(),
    );

    provider.loadPrograms();

    expect(provider.error, contains('not authenticated'));
    expect(provider.isLoadingPrograms, false);
  });

  test('loadAnalytics should set error when userId is null', () async {
    final provider = ProgramProvider.withServices(
      null,
      MockFirestoreService(),
      MockAnalyticsService(),
    );

    await provider.loadAnalytics();

    expect(provider.error, contains('not authenticated'));
    expect(provider.isLoadingAnalytics, false);
  });
});
```

### Integration Tests

**File:** `fittrack/integration_test/login_data_loading_test.dart`

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Data Loading', () {
    testWidgets('programs and analytics load immediately after login', (tester) async {
      // Start app
      await tester.pumpWidget(const FitTrackApp());
      await tester.pumpAndSettle();

      // Navigate to login
      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Login'));

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Verify we're on home screen
      expect(find.text('My Programs'), findsOneWidget);

      // Should NOT show error state
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Unable to load'), findsNothing);

      // Should show either programs or empty state (not loading or error)
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Should not be stuck in loading state',
      );

      // Navigate to Analytics tab
      await tester.tap(find.byIcon(Icons.analytics));
      await tester.pumpAndSettle();

      // Analytics should also be loaded (not in error state)
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Unable to load analytics'), findsNothing);
    });

    testWidgets('logout and login again should work correctly', (tester) async {
      // ... test logout → login flow
    });

    testWidgets('app restart with persisted auth should load data', (tester) async {
      // ... test app restart flow
    });
  });
}
```

### Manual Testing

#### Test Plan: Fresh Login Flow

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Install fresh app | Shows login screen | ☐ |
| 2 | Enter valid credentials and login | No errors appear | ☐ |
| 3 | Check Programs screen | Shows programs or "No Programs Yet" (not error) | ☐ |
| 4 | Check Analytics screen | Shows analytics or "No Data" (not error) | ☐ |
| 5 | Verify loading indicators | Should show briefly then disappear | ☐ |
| 6 | Check console logs | Should see auto-load messages in correct order | ☐ |

#### Test Plan: Logout/Login Flow

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | From logged-in state, logout | Returns to login screen | ☐ |
| 2 | Login again with same credentials | No errors appear | ☐ |
| 3 | Check Programs screen | Data loads immediately | ☐ |
| 4 | Check Analytics screen | Data loads immediately | ☐ |

#### Test Plan: App Restart with Persisted Auth

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Login to app | Success | ☐ |
| 2 | Kill app completely | App closed | ☐ |
| 3 | Reopen app | Auto-logs in (persisted auth) | ☐ |
| 4 | Check Programs screen | Data loads immediately without errors | ☐ |
| 5 | Check Analytics screen | Data loads immediately without errors | ☐ |

#### Test Plan: Retry Button

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | Simulate network error during load | Error state appears | ☐ |
| 2 | Click "Retry" button | Data reloads successfully | ☐ |
| 3 | Verify retry works on Programs screen | ✓ Retry works | ☐ |
| 4 | Verify retry works on Analytics screen | ✓ Retry works | ☐ |

#### Test Plan: Refresh Button

| Step | Action | Expected Result | Status |
|------|--------|----------------|--------|
| 1 | From successfully loaded state, click refresh | Data reloads | ☐ |
| 2 | Pull-to-refresh on Programs screen | Data reloads | ☐ |
| 3 | Refresh button on Analytics screen | Data reloads | ☐ |

### Performance Testing

**Metrics to Monitor:**

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Time to load programs after login | < 2 seconds | Firebase Performance Monitoring |
| Time to load analytics after login | < 3 seconds | Firebase Performance Monitoring |
| Unnecessary provider recreations | 0 (only on auth change) | Debug logs |
| Duplicate load calls | 0 (auto-load should prevent) | Debug logs + Firestore metrics |

---

## Rollout Plan

### Phase 1: Foundation (Week 1, Days 1-2)

**Tasks:**
- Implement `_autoLoadDataIfNeeded()` method in ProgramProvider
- Add `_previousUserId` tracking
- Add debug logging to provider lifecycle
- Write unit tests for auto-load logic

**Validation:**
- Unit tests pass
- Debug logs show correct initialization sequence

### Phase 2: Error Handling (Week 1, Days 3-4)

**Tasks:**
- Update `loadPrograms()` to set explicit error when userId is null
- Update `loadAnalytics()` to set explicit error when userId is null
- Add debug logging to load methods
- Write unit tests for error handling

**Validation:**
- Unit tests pass
- Error messages are clear and actionable

### Phase 3: Screen Updates (Week 1, Day 5)

**Tasks:**
- Remove manual `loadPrograms()` call from HomeScreen
- Remove manual `loadAnalytics()` call from AnalyticsScreen
- Update retry button logic to get fresh provider reference
- Test screens still work correctly

**Validation:**
- Screens build without errors
- No console warnings about calling methods during build

### Phase 4: Integration Testing (Week 2, Days 1-3)

**Tasks:**
- Write integration tests for login flow
- Test fresh login, logout→login, app restart scenarios
- Test on physical Android device (Samsung S21 or similar)
- Test on iOS if available

**Validation:**
- All integration tests pass
- Manual testing confirms no errors on login
- Both retry and refresh buttons work correctly

### Phase 5: Production Deployment (Week 2, Days 4-5)

**Tasks:**
- Deploy to beta testers via Firebase App Distribution
- Monitor Firebase Crashlytics for any new errors
- Monitor user feedback and console logs
- Fix any issues discovered in beta

**Validation:**
- No increase in crash rate
- No reports of login errors from beta testers
- Analytics show successful data loads on login

---

## Success Metrics

### Primary Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **Login Success Rate** | ~0% (shows error) | 100% (no errors) | Firebase Analytics custom event |
| **Time to First Data Load** | N/A (manual refresh) | < 3 seconds | Performance monitoring |
| **Manual Refresh Rate** | ~100% (required) | < 5% (occasional) | Analytics event tracking |

### Secondary Metrics

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| **Retry Button Usage** | Low (doesn't work) | Low (works but rare) | Analytics event |
| **Error Screen Views** | High (every login) | < 1% (network errors only) | Screen view analytics |
| **App Uninstalls After First Login** | Unknown | Reduce by 50% | Firebase Analytics |

### Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Provider Recreation Count** | 1 per auth change | Debug logs in dev builds |
| **Duplicate Load Calls** | 0 | Firestore query count metrics |
| **Console Errors on Login** | 0 | Firebase Crashlytics |

---

## Risk Analysis

### High Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Auto-load fires too early** | Data load fails | Medium | Add defensive null checks, extensive testing |
| **Breaking existing flows** | Other screens fail | Low | Comprehensive integration tests |

### Medium Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Performance regression** | Slower load times | Low | Monitor with Firebase Performance |
| **Infinite reload loops** | App hangs | Low | Track _previousUserId to prevent |

### Low Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Debug logs in production** | Minor performance hit | Medium | Use kDebugMode guards |
| **Different behavior on iOS** | iOS-specific issues | Low | Test on both platforms |

---

## Alternative Solutions Considered

### Alternative 1: Add Delays in Screens

**Approach:** Keep manual load calls but add delays

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  Future.delayed(Duration(milliseconds: 500), () {
    Provider.of<ProgramProvider>(context, listen: false).loadPrograms();
  });
});
```

**Pros:**
- Minimal code changes
- Simple to understand

**Cons:**
- ❌ Brittle - depends on timing guesses
- ❌ Arbitrary delay hurts performance
- ❌ May still fail on slow devices
- ❌ Doesn't address root cause

**Decision:** ❌ Rejected - Not reliable

### Alternative 2: Remove ChangeNotifierProxyProvider

**Approach:** Manually listen to AuthProvider and update ProgramProvider

```dart
// In main.dart
ChangeNotifierProvider(
  create: (_) => ProgramProvider(null),
),

// In ProgramProvider
void listenToAuth(AuthProvider authProvider) {
  authProvider.addListener(() {
    if (authProvider.user?.uid != _userId) {
      _userId = authProvider.user?.uid;
      loadPrograms();
    }
  });
}
```

**Pros:**
- Full control over timing
- No race condition

**Cons:**
- ❌ Major refactor required
- ❌ Need to manually manage listener disposal
- ❌ Breaking change to existing architecture
- ❌ More complex code

**Decision:** ❌ Rejected - Too risky, not needed

### Alternative 3: Use FutureBuilder in Screens

**Approach:** Wrap screens in FutureBuilder that waits for userId

```dart
FutureBuilder<String?>(
  future: Provider.of<AuthProvider>(context).waitForUserId(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ProgramsScreen(); // userId is ready
  },
)
```

**Pros:**
- Explicit wait for userId
- Screens know when data is ready

**Cons:**
- ❌ More complex screen code
- ❌ Need to create waitForUserId() method
- ❌ Doesn't prevent manual load calls racing
- ❌ Not idiomatic Flutter/Provider pattern

**Decision:** ❌ Rejected - Overly complex for the problem

---

## Appendix

### Code References

**Key Files:**
- `fittrack/lib/main.dart:70-74` - ChangeNotifierProxyProvider setup
- `fittrack/lib/providers/auth_provider.dart:26-36` - Auth state listener
- `fittrack/lib/providers/program_provider.dart:17-19` - Constructor
- `fittrack/lib/providers/program_provider.dart:109-132` - loadPrograms()
- `fittrack/lib/providers/program_provider.dart:957-1034` - loadAnalytics()
- `fittrack/lib/screens/home/home_screen.dart:20-34` - HomeScreen.initState()
- `fittrack/lib/screens/analytics/analytics_screen.dart:20-27` - AnalyticsScreen.initState()

### Related Documentation

- [Architecture Overview](../Architecture/ArchitectureOverview.md)
- [State Management](../Architecture/StateManagement.md)
- [Authentication Component](../Components/Authentication.md)
- [Testing Framework](../Testing/TestingFramework.md)

### External References

- [Flutter ChangeNotifierProxyProvider](https://pub.dev/documentation/provider/latest/provider/ChangeNotifierProxyProvider-class.html)
- [Firebase Auth State Persistence](https://firebase.google.com/docs/auth/web/auth-state-persistence)
- [Provider Package Best Practices](https://pub.dev/packages/provider#usage)

---

**Document Version:** 1.0
**Last Review:** 2025-10-26
**Next Review:** After implementation complete
