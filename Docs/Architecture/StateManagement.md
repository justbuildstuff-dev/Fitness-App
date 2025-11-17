# State Management Documentation

## Overview

The FitTrack application uses the Provider pattern for state management, implementing a hierarchical provider structure that mirrors the data model hierarchy. The state management layer provides reactive UI updates, loading states, error handling, and clean separation between UI and business logic.

## Architecture Principles

### Provider Pattern
- **Reactive State**: UI automatically updates when state changes
- **Separation of Concerns**: Business logic separated from UI components
- **Dependency Injection**: Services injected via constructor parameters
- **Stream Management**: Proper subscription handling and cleanup

### Hierarchical Provider Structure
```
AuthProvider (Root)
├── User Authentication State
└── ProgramProvider (Child)
    ├── Program Management
    ├── Week Management  
    ├── Workout Management
    ├── Exercise Management
    └── Set Management
```

### State Ownership
- **AuthProvider**: User authentication and profile data
- **ProgramProvider**: All workout data hierarchy
- **Providers communicate via dependency injection**

## Core Provider Classes

### AuthProvider

**Purpose**: Manages user authentication state and profile data

**Key Responsibilities**:
- Firebase Authentication integration
- User profile management
- Password validation
- Error handling for auth operations
- Session management

**State Properties**:
```dart
User? _user;                    // Firebase auth user
UserProfile? _userProfile;      // Custom user profile data
bool _isLoading;               // Loading state for async operations
String? _error;                // Current error message
String? _successMessage;       // Success feedback
```

**Public Interface**:
```dart
// Getters
User? get user;
UserProfile? get userProfile;
bool get isLoading;
String? get error;
String? get successMessage;
bool get isAuthenticated;

// Authentication Methods
Future<bool> signUpWithEmail({String email, String password, String? displayName});
Future<void> signInWithEmail({String email, String password});
Future<void> signOut();
Future<void> resetPassword(String email);

// Profile Management
Future<void> updateProfile({String? displayName, Map<String, dynamic>? settings});

// State Management
void clearError();
void clearSuccessMessage();
```

**Usage Patterns**:
```dart
// In Widget
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (authProvider.error != null) {
      return ErrorMessage(authProvider.error!);
    }
    
    return authProvider.isAuthenticated 
        ? HomeScreen() 
        : LoginScreen();
  },
)

// In Business Logic
final authProvider = context.read<AuthProvider>();
await authProvider.signInWithEmail(
  email: emailController.text,
  password: passwordController.text,
);
```

**Password Policy Enforcement**:
```dart
bool _isValidPassword(String password) {
  if (password.length < 8) return false;
  
  bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
  bool hasDigit = password.contains(RegExp(r'[0-9]'));
  
  return hasLetter && hasDigit;
}
```

**Error Handling**:
- Firebase auth errors mapped to user-friendly messages
- Network errors handled gracefully
- Loading states prevent duplicate operations
- Success messages provide user feedback

### ProgramProvider

**Purpose**: Manages the entire workout data hierarchy and user selections

**Key Responsibilities**:
- CRUD operations for all workout entities
- Selection state management (current program, week, workout, etc.)
- Real-time data synchronization via Firestore streams
- Loading and error state coordination
- Stream subscription lifecycle management

**Hierarchical State Structure**:
```dart
// Programs Level
List<Program> _programs = [];
Program? _selectedProgram;
bool _isLoadingPrograms = false;

// Weeks Level  
List<Week> _weeks = [];
Week? _selectedWeek;
bool _isLoadingWeeks = false;

// Workouts Level
List<Workout> _workouts = [];
Workout? _selectedWorkout; 
bool _isLoadingWorkouts = false;

// Exercises Level
List<Exercise> _exercises = [];
Exercise? _selectedExercise;
bool _isLoadingExercises = false;

// Sets Level
List<ExerciseSet> _sets = [];
bool _isLoadingSets = false;

// Global State
String? _error;
```

**Stream Management**:
```dart
// Subscription tracking for proper cleanup
StreamSubscription<List<Program>>? _programsSubscription;
StreamSubscription<List<Week>>? _weeksSubscription;
StreamSubscription<List<Workout>>? _workoutsSubscription;
StreamSubscription<List<Exercise>>? _exercisesSubscription;
StreamSubscription<List<ExerciseSet>>? _setsSubscription;

@override
void dispose() {
  _programsSubscription?.cancel();
  _weeksSubscription?.cancel();
  _workoutsSubscription?.cancel();
  _exercisesSubscription?.cancel();
  _setsSubscription?.cancel();
  super.dispose();
}
```

**CRUD Operation Pattern**:
```dart
/// Create a new program
Future<String?> createProgram({
  required String name,
  String? description,
}) async {
  if (_userId == null) return null;

  try {
    _error = null;
    notifyListeners();

    final program = Program(
      id: '',
      name: name.trim(),
      description: description?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: _userId!,
    );

    final programId = await _firestoreService.createProgram(program);
    return programId;
  } catch (e) {
    _error = 'Failed to create program: $e';
    notifyListeners();
    return null;
  }
}
```

**Selection State Management**:
```dart
/// Select a program and load its weeks
void selectProgram(Program program) {
  _selectedProgram = program;
  _weeks = [];
  _selectedWeek = null;
  _workouts = [];
  _selectedWorkout = null;
  _exercises = [];
  _selectedExercise = null;
  _sets = [];
  _error = null;
  notifyListeners();
  
  // Load child data
  loadWeeks(program.id!);
}
```

**Real-time Data Loading**:
```dart
/// Load weeks for the selected program
void loadWeeks(String programId) {
  if (_userId == null) return;

  _isLoadingWeeks = true;
  _error = null;
  notifyListeners();

  // Cancel previous subscription
  _weeksSubscription?.cancel();
  
  _weeksSubscription = _firestoreService.getWeeks(_userId!, programId).listen(
    (weeks) {
      _weeks = weeks;
      _isLoadingWeeks = false;
      _error = null;
      notifyListeners();
    },
    onError: (error) {
      _error = 'Failed to load weeks: $error';
      _isLoadingWeeks = false;
      notifyListeners();
    },
  );
}
```

**Duplication Integration**:
```dart
/// Duplicate a week
Future<Map<String, dynamic>?> duplicateWeek({
  required String programId,
  required String weekId,
}) async {
  if (_userId == null) return null;

  try {
    _error = null;
    notifyListeners();

    final result = await _firestoreService.duplicateWeek(
      userId: _userId!,
      programId: programId,
      weekId: weekId,
    );

    return result;
  } catch (e) {
    _error = 'Failed to duplicate week: $e';
    notifyListeners();
    return null;
  }
}
```

**Cascade Delete Count Integration**:
```dart
/// Get cascade delete counts for confirmation dialogs
///
/// Resolves context (programId, weekId, workoutId) based on provider state
/// and calls FirestoreService to calculate affected entity counts.
///
/// Returns CascadeDeleteCounts with zero values if context is missing
/// or if the count operation fails.
Future<CascadeDeleteCounts> getCascadeDeleteCounts({
  String? weekId,
  String? workoutId,
  String? exerciseId,
}) async {
  if (_userId == null) return const CascadeDeleteCounts();

  String? programId;
  String? resolvedWeekId = weekId;
  String? resolvedWorkoutId = workoutId;

  // Determine programId and resolve IDs based on context
  if (exerciseId != null) {
    // Deleting exercise - need program, week, workout, exercise IDs
    if (_selectedProgram == null || _selectedWeek == null || _selectedWorkout == null) {
      return const CascadeDeleteCounts();
    }
    programId = _selectedProgram!.id;
    resolvedWeekId = _selectedWeek!.id;
    resolvedWorkoutId = _selectedWorkout!.id;
  } else if (workoutId != null) {
    // Deleting workout - need program, week, workout IDs
    if (_selectedProgram == null || _selectedWeek == null) {
      return const CascadeDeleteCounts();
    }
    programId = _selectedProgram!.id;
    resolvedWeekId = _selectedWeek!.id;
  } else if (weekId != null) {
    // Deleting week - need program, week IDs
    if (_selectedProgram == null) {
      return const CascadeDeleteCounts();
    }
    programId = _selectedProgram!.id;
  } else {
    return const CascadeDeleteCounts();
  }

  return await _firestoreService.getCascadeDeleteCounts(
    userId: _userId!,
    programId: programId!,
    weekId: resolvedWeekId,
    workoutId: resolvedWorkoutId,
    exerciseId: exerciseId,
  );
}
```

**Implementation Notes:**
- Added in Task #56 as part of Delete Functionality Fix (Issue #49)
- Provides convenient provider-level access to cascade counts for UI screens
- Automatically resolves context from provider state (_selectedProgram, _selectedWeek, _selectedWorkout)
- Returns zero counts gracefully if required context is missing
- Used by all delete confirmation dialogs to show affected entity counts

## Provider Setup and Configuration

### Application Root Configuration
```dart
// main.dart
MultiProvider(
  providers: [
    // Auth Provider (root level)
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    
    // Program Provider depends on AuthProvider
    ChangeNotifierProxyProvider<AuthProvider, ProgramProvider>(
      create: (_) => ProgramProvider(null),
      update: (_, authProvider, previousProgramProvider) =>
          ProgramProvider(authProvider.user?.uid),
    ),
  ],
  child: MaterialApp(
    home: AuthWrapper(),
  ),
)
```

### Provider Dependencies
- **ProgramProvider** receives `userId` from **AuthProvider**
- When user signs out, ProgramProvider is recreated with `null` userId
- All data is cleared when user changes
- Automatic cleanup of stream subscriptions

## State Management Patterns

### Loading States
```dart
// Individual loading states for different data levels
bool get isLoadingPrograms => _isLoadingPrograms;
bool get isLoadingWeeks => _isLoadingWeeks;
bool get isLoadingWorkouts => _isLoadingWorkouts;

// Usage in UI
if (programProvider.isLoadingWeeks) {
  return CircularProgressIndicator();
}
```

### Error Handling
```dart
// Global error state shared across all operations
String? get error => _error;

// Error setting pattern
void _setError(String errorMessage) {
  _error = errorMessage;
  notifyListeners();
}

// Error clearing
void clearError() {
  _error = null;
  notifyListeners();
}
```

### Selection State Cascading
When a parent is selected, all child selections are cleared:
```dart
void selectProgram(Program program) {
  _selectedProgram = program;
  
  // Clear all child selections
  _selectedWeek = null;
  _selectedWorkout = null;
  _selectedExercise = null;
  
  // Clear all child data
  _weeks = [];
  _workouts = [];
  _exercises = [];
  _sets = [];
  
  notifyListeners();
  
  // Load fresh child data
  if (program.id != null) {
    loadWeeks(program.id!);
  }
}
```

### Stream Subscription Management
```dart
// Pattern for loading with stream subscription
void loadData(String parentId) {
  _isLoading = true;
  notifyListeners();

  // Cancel existing subscription to prevent memory leaks
  _subscription?.cancel();
  
  _subscription = _service.getData(parentId).listen(
    (data) {
      _data = data;
      _isLoading = false;
      _error = null;
      notifyListeners();
    },
    onError: (error) {
      _error = 'Failed to load data: $error';
      _isLoading = false;
      notifyListeners();
    },
  );
}

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

## UI Integration Patterns

### Consumer Pattern
```dart
Consumer<ProgramProvider>(
  builder: (context, programProvider, child) {
    // Handle loading state
    if (programProvider.isLoadingPrograms) {
      return LoadingIndicator();
    }
    
    // Handle error state
    if (programProvider.error != null) {
      return ErrorMessage(
        message: programProvider.error!,
        onRetry: () => programProvider.clearError(),
      );
    }
    
    // Render data
    return ListView.builder(
      itemCount: programProvider.programs.length,
      itemBuilder: (context, index) {
        final program = programProvider.programs[index];
        return ProgramTile(
          program: program,
          onTap: () => programProvider.selectProgram(program),
          isSelected: programProvider.selectedProgram?.id == program.id,
        );
      },
    );
  },
)
```

### Selector Pattern (Performance Optimization)
```dart
// Only rebuild when specific property changes
Selector<ProgramProvider, List<Week>>(
  selector: (context, provider) => provider.weeks,
  builder: (context, weeks, child) {
    return WeeksList(weeks: weeks);
  },
)
```

### Read Pattern (No Rebuilding)
```dart
// For actions that don't need rebuilding
void _onCreateWeek() async {
  final provider = context.read<ProgramProvider>();
  final weekId = await provider.createWeek(
    programId: provider.selectedProgram!.id!,
    name: 'New Week',
    order: provider.weeks.length + 1,
  );
  
  if (weekId != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Week created successfully!')),
    );
  }
}
```

## Error Handling Strategies

### Provider-Level Error Handling
```dart
// Centralized error state
String? _error;

// Error setting with automatic UI updates
void _handleError(String operation, dynamic error) {
  _error = 'Failed to $operation: ${error.toString()}';
  _isLoading = false;
  notifyListeners();
}

// Usage in operations
try {
  await _performOperation();
} catch (e) {
  _handleError('create program', e);
}
```

### UI-Level Error Display
```dart
// Error handling in UI
if (provider.error != null) {
  return Column(
    children: [
      ErrorBanner(
        message: provider.error!,
        onDismiss: () => provider.clearError(),
      ),
      // Continue with normal UI...
    ],
  );
}
```

### Operation-Specific Error Handling
```dart
Future<void> _duplicateWeek() async {
  final result = await context.read<ProgramProvider>().duplicateWeek(
    programId: selectedProgram.id!,
    weekId: selectedWeek.id!,
  );
  
  if (result == null) {
    // Error is already set in provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to duplicate week'),
        backgroundColor: Colors.red,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Week duplicated successfully!')),
    );
  }
}
```

## Performance Optimizations

### Selective Rebuilding
```dart
// Use Selector to prevent unnecessary rebuilds
Selector<ProgramProvider, bool>(
  selector: (context, provider) => provider.isLoadingPrograms,
  builder: (context, isLoading, child) {
    return isLoading ? CircularProgressIndicator() : child!;
  },
  child: ProgramsList(),
)
```

### Stream Subscription Optimization
```dart
// Cancel subscriptions when not needed
void _pauseDataLoading() {
  _weeksSubscription?.pause();
}

void _resumeDataLoading() {
  _weeksSubscription?.resume();
}

// Or cancel completely when navigating away
void _stopDataLoading() {
  _weeksSubscription?.cancel();
  _weeksSubscription = null;
}
```

### Memory Management
```dart
// Clear large data sets when not needed
void clearWorkoutData() {
  _workouts = [];
  _exercises = [];
  _sets = [];
  notifyListeners();
}

// Dispose pattern
@override
void dispose() {
  // Cancel all subscriptions
  _programsSubscription?.cancel();
  _weeksSubscription?.cancel();
  // ... other subscriptions
  super.dispose();
}
```

## Testing Strategies

### Provider Testing
```dart
group('ProgramProvider', () {
  late ProgramProvider provider;
  late MockFirestoreService mockService;

  setUp(() {
    mockService = MockFirestoreService();
    provider = ProgramProvider('test_user_id');
    provider._firestoreService = mockService;
  });

  test('loads programs on initialization', () async {
    // Arrange
    final testPrograms = [Program(/* test data */)];
    when(mockService.getPrograms(any)).thenAnswer(
      (_) => Stream.value(testPrograms),
    );

    // Act
    provider.loadPrograms();
    await untilCalled(mockService.getPrograms(any));

    // Assert
    expect(provider.programs, equals(testPrograms));
    expect(provider.isLoadingPrograms, isFalse);
  });

  test('handles errors gracefully', () async {
    // Arrange
    when(mockService.getPrograms(any)).thenAnswer(
      (_) => Stream.error('Network error'),
    );

    // Act
    provider.loadPrograms();
    await untilCalled(mockService.getPrograms(any));

    // Assert
    expect(provider.error, contains('Failed to load programs'));
    expect(provider.isLoadingPrograms, isFalse);
  });
});
```

### Widget Testing with Providers
```dart
testWidgets('displays programs correctly', (tester) async {
  final mockProvider = MockProgramProvider();
  when(mockProvider.programs).thenReturn([
    Program(id: '1', name: 'Test Program', /* other fields */),
  ]);

  await tester.pumpWidget(
    ChangeNotifierProvider<ProgramProvider>.value(
      value: mockProvider,
      child: MaterialApp(home: ProgramsScreen()),
    ),
  );

  expect(find.text('Test Program'), findsOneWidget);
});
```

## Best Practices

### Provider Design
1. **Single Responsibility**: Each provider manages related state
2. **Immutable State**: Use copyWith patterns for updates
3. **Stream Management**: Always cancel subscriptions in dispose()
4. **Error Boundaries**: Handle errors at appropriate levels
5. **Loading States**: Provide feedback for async operations

### State Updates
```dart
// Good: Atomic state updates
void updateProgram(Program updatedProgram) {
  final index = _programs.indexWhere((p) => p.id == updatedProgram.id);
  if (index != -1) {
    _programs[index] = updatedProgram;
    if (_selectedProgram?.id == updatedProgram.id) {
      _selectedProgram = updatedProgram;
    }
    notifyListeners();
  }
}

// Avoid: Partial updates that leave inconsistent state
```

### Memory Management
```dart
// Clear data when user signs out
void clearAllData() {
  _programs.clear();
  _weeks.clear();
  _workouts.clear();
  _exercises.clear();
  _sets.clear();
  
  _selectedProgram = null;
  _selectedWeek = null;
  _selectedWorkout = null;
  _selectedExercise = null;
  
  // Cancel all subscriptions
  _programsSubscription?.cancel();
  _weeksSubscription?.cancel();
  // ... other subscriptions
  
  notifyListeners();
}
```

### Error Recovery
```dart
// Provide retry mechanisms
void retryLoadPrograms() {
  _error = null;
  loadPrograms();
}

// Graceful degradation
List<Program> get availablePrograms {
  return _programs.isNotEmpty 
      ? _programs 
      : _getCachedPrograms(); // Fallback to cached data
}
```

This state management architecture provides a robust foundation for the FitTrack application, ensuring reactive UI updates, proper resource management, and excellent user experience through comprehensive loading and error states.