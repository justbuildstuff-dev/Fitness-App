# Exercise and Set Management System

## Overview

The Exercise and Set Management system provides complete workout tracking functionality for FitTrack users. This system handles the creation, management, and tracking of exercises and their associated sets, with full support for different exercise types and their specific requirements.

## Architecture

### Component Hierarchy
```
WorkoutDetailScreen
    └── Exercise List
        └── ExerciseDetailScreen
            ├── Set List Management
            └── CreateSetScreen
                └── Exercise Type-Specific Input Fields
```

### Data Flow
```
User Action → Screen → ProgramProvider → FirestoreService → Firestore
                  ↓
            Real-time Updates → UI Rebuild
```

## Exercise Types and Validation

### ExerciseType Enum
```dart
enum ExerciseType {
  strength,    // Traditional weight lifting
  cardio,      // Cardiovascular activities
  timeBased,   // Time-based exercises
  bodyweight,  // Bodyweight movements
  custom       // User-defined flexible tracking
}
```

### Exercise Type Specifications

#### Strength Exercises
- **Required Fields**: `reps`
- **Optional Fields**: `weight`, `restTime`
- **Example**: Bench Press, Squats, Deadlifts
- **Validation**: Reps must be > 0, weight must be ≥ 0

#### Cardio Exercises  
- **Required Fields**: `duration`
- **Optional Fields**: `distance`
- **Example**: Running, Cycling, Swimming
- **Validation**: Duration must be > 0, distance must be ≥ 0
- **Unit Conversion**: km → meters, minutes/seconds → total seconds

#### Time-Based Exercises
- **Required Fields**: `duration`
- **Optional Fields**: `distance`
- **Example**: Planks, Wall sits
- **Validation**: Same as cardio exercises

#### Bodyweight Exercises
- **Required Fields**: `reps`
- **Optional Fields**: `restTime`
- **Example**: Push-ups, Pull-ups, Burpees
- **Validation**: Same as strength exercises (no weight tracking)

#### Custom Exercises
- **Required Fields**: At least one metric must be provided
- **Optional Fields**: Any combination of `reps`, `weight`, `duration`, `distance`, `restTime`
- **Example**: Complex movements, hybrid exercises
- **Validation**: Flexible - at least one field must have a value

## Screen Implementation Details

### CreateExerciseScreen

**Location**: `lib/screens/exercises/create_exercise_screen.dart`

**Features**:
- Exercise type dropdown with all available types
- Dynamic information display based on selected type
- Form validation with real-time feedback
- Context information (Program → Week → Workout breadcrumb)
- Helper text and tips for users

**Key Components**:
```dart
class CreateExerciseScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;
  
  // Exercise type selection
  DropdownButtonFormField<ExerciseType> _buildExerciseTypeDropdown()
  
  // Dynamic info based on selected type
  Widget _buildExerciseTypeInfo()
  
  // Form validation
  String? _validateExerciseName(String? value)
}
```

**Validation Rules**:
- Exercise name: Required, max 200 characters
- Exercise type: Required, must be valid enum value
- Notes: Optional, max 1000 characters

### ExerciseDetailScreen

**Location**: `lib/screens/exercises/exercise_detail_screen.dart`

**Features**:
- Exercise information display with type-specific styling
- Set list management with completion tracking  
- Navigation to set creation
- Exercise editing capabilities
- Set completion toggle functionality

**Key Components**:
```dart
class ExerciseDetailScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;
  final Exercise exercise;
  
  // Set list with completion tracking
  Widget _buildSetsList()
  
  // Exercise type-specific set display
  Widget _buildSetItem(ExerciseSet set)
  
  // Set completion toggle
  void _toggleSetCompletion(ExerciseSet set)
}
```

### CreateSetScreen

**Location**: `lib/screens/sets/create_set_screen.dart`

**Features**:
- Exercise type-specific input fields
- Dynamic form generation based on exercise requirements
- Unit conversion (duration, distance)
- Comprehensive validation
- Loading states and error handling

**Key Components**:
```dart
class CreateSetScreen extends StatefulWidget {
  final Program program;
  final Week week;
  final Workout workout;
  final Exercise exercise;
  
  // Dynamic field generation
  List<Widget> _buildFieldsForExerciseType()
  
  // Input field builders
  Widget _buildRepsField()
  Widget _buildWeightField()
  Widget _buildDurationField()
  Widget _buildDistanceField()
  Widget _buildRestTimeField()
}
```

## Input Field Specifications

### Reps Field
- **Input Type**: Integer only (`FilteringTextInputFormatter.digitsOnly`)
- **Validation**: Required for strength/bodyweight, must be > 0
- **UI**: Number input with increment/decrement buttons

### Weight Field  
- **Input Type**: Decimal numbers (`TextInputType.numberWithOptions(decimal: true)`)
- **Validation**: Must be ≥ 0 if provided
- **Unit**: Kilograms (kg)
- **UI**: Decimal input with kg suffix

### Duration Fields
- **Input Type**: Minutes (integer) + Seconds (integer, 0-59 range)
- **Validation**: At least one must be > 0 for required duration
- **Conversion**: Combined to total seconds for storage
- **UI**: Two separate fields with minute/second labels

### Distance Field
- **Input Type**: Decimal numbers  
- **Validation**: Must be ≥ 0 if provided
- **Unit**: Kilometers (converted to meters for storage)
- **UI**: Decimal input with km suffix

### Rest Time Field
- **Input Type**: Integer (seconds)
- **Validation**: Must be ≥ 0 if provided
- **Unit**: Seconds
- **UI**: Number input with seconds suffix

## Data Conversion Logic

### Duration Conversion
```dart
// User Input: 5 minutes, 30 seconds
// Storage: 330 seconds (5 * 60 + 30)
int? duration;
final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
final seconds = int.tryParse(_durationSecondsController.text) ?? 0;
if (minutes > 0 || seconds > 0) {
  duration = minutes * 60 + seconds;
}
```

### Distance Conversion
```dart
// User Input: 5.5 km
// Storage: 5500 meters
final distanceKm = double.tryParse(_distanceController.text);
final distance = distanceKm != null ? distanceKm * 1000 : null;
```

## Set Display Formatting

### Display String Generation
The `ExerciseSet` model includes a `displayString` getter that formats sets appropriately for each exercise type:

```dart
String get displayString {
  switch (exerciseType) {
    case ExerciseType.strength:
      return '${reps ?? 0} reps${weight != null ? ' @ ${_formatWeight(weight!)}' : ''}';
    case ExerciseType.cardio:
      return '${_formatDuration(duration ?? 0)}${distance != null ? ', ${_formatDistance(distance!)}' : ''}';
    // ... other types
  }
}
```

**Examples**:
- Strength: "12 reps @ 100.5 kg"
- Cardio: "30:00, 5.5 km"
- Bodyweight: "15 reps"

## Integration with ProgramProvider

### Required Provider Methods
The exercise and set management system relies on these ProgramProvider methods:

```dart
// Exercise CRUD
Future<String?> createExercise({...})
Future<void> updateExercise({...})
Future<void> deleteExercise({...})

// Set CRUD
Future<String?> createSet({...})
Future<void> updateSet({...})
Future<void> deleteSet({...})

// Data getters
List<Exercise> getCurrentExercises()
List<ExerciseSet> getCurrentSets()
bool get isLoading
```

### State Management Flow
1. User action triggers screen method
2. Screen calls appropriate ProgramProvider method
3. Provider calls FirestoreService
4. Firestore operation completes
5. Real-time listeners update provider state
6. UI rebuilds automatically via Consumer widgets

## Testing Coverage

### Model Tests (`test/models/exercise_set_test.dart`)
**Coverage**: 24/24 tests passing
- Constructor validation
- Exercise type-specific validation
- Duplication logic
- Display string formatting
- Firestore serialization/deserialization

### Screen Tests (`test/screens/create_exercise_screen_test.dart`)
**Coverage**: 33/33 tests passing
- Form validation
- Exercise type selection
- Dynamic UI updates
- Loading states
- Error handling
- Success flows

### Screen Tests (`test/screens/create_set_screen_test.dart`)  
**Coverage**: 18/18 tests passing
- Exercise type-specific field display
- Input validation
- Unit conversion
- Form submission
- Error states
- Loading indicators

## Error Handling

### Validation Errors
- **Form Validation**: Real-time validation with user-friendly messages
- **Network Errors**: Graceful handling with retry options
- **Data Conflicts**: Automatic conflict resolution via Firestore

### User Feedback
- **Loading States**: Visual feedback during async operations
- **Success Messages**: Confirmation of successful actions
- **Error Messages**: Clear error descriptions with suggested actions

## Performance Considerations

### Efficient Queries
- Hierarchical queries following security model
- Minimal data transfer with selective field updates
- Real-time listeners properly managed and disposed

### Memory Management
- TextEditingController disposal in dispose() methods
- Stream subscriptions cancelled appropriately
- Provider state cleaned up when screens unmount

### UI Performance
- Selective rebuilding with Consumer widgets
- Efficient list rendering with proper keys
- Input formatters to prevent invalid input

## Future Enhancement Opportunities

### Planned Features
1. **Set Templates**: Save and reuse common set configurations
2. **Exercise Library**: Predefined exercises with instructions
3. **Progress Tracking**: Historical data and progress charts
4. **Exercise Notes**: Detailed form cues and technique notes
5. **Timer Integration**: Rest timers between sets

### Architecture Extensions
1. **Exercise Categories**: Grouping exercises by muscle groups
2. **Superset Support**: Linking exercises in supersets
3. **Drop Sets**: Progressive weight reduction within exercises
4. **Advanced Metrics**: RPE, tempo, range of motion tracking

This comprehensive exercise and set management system provides a solid foundation for complete workout tracking with room for future enhancements while maintaining excellent user experience and data integrity.