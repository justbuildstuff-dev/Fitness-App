# UI Components Documentation

## Overview

The FitTrack UI is built with Flutter using Material Design principles. The component architecture emphasizes reusability, accessibility, and consistent user experience across the hierarchical workout data structure. All components integrate with the Provider pattern for reactive state management.

## Design Principles

### Material Design 3
- **Dynamic Color**: ColorScheme.fromSeed with app-specific branding
- **Typography**: Material 3 text themes for consistency
- **Elevation**: Modern elevation system with surface tinting
- **Accessibility**: WCAG 2.1 AA compliance with proper contrast ratios

### Responsive Design
- **Mobile-First**: Optimized for phone screens with tablet adaptations
- **Touch Targets**: Minimum 44×44pt touch targets for accessibility
- **Layout Flexibility**: Adapts to various screen sizes and orientations
- **Content Hierarchy**: Clear visual hierarchy for complex data structures

### Component Architecture
- **Atomic Design**: Atoms, molecules, organisms pattern
- **Reusable Widgets**: Consistent components across screens
- **State Integration**: Seamless Provider pattern integration
- **Error Boundaries**: Graceful error handling in UI components

## Screen Architecture

### Authentication Screens
**Location**: `lib/screens/auth/`

#### AuthWrapper
**Purpose**: Root-level authentication routing component

```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return LoadingScreen();
        }
        
        return authProvider.isAuthenticated 
            ? const HomeScreen() 
            : const SignInScreen();
      },
    );
  }
}
```

**Responsibilities**:
- Authentication state routing
- Loading state management
- Seamless navigation between auth and app states

#### SignInScreen & SignUpScreen
**Features**:
- Form validation with real-time feedback
- Password visibility toggle
- Loading states during authentication
- Error message display with dismiss actions
- Accessibility support with semantic labels

**Form Validation Pattern**:
```dart
TextFormField(
  controller: _emailController,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!_isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  },
  decoration: InputDecoration(
    labelText: 'Email Address',
    prefixIcon: Icon(Icons.email),
    errorMaxLines: 2,
  ),
)
```

### Main Navigation Screens
**Location**: `lib/screens/home/`

#### HomeScreen
**Purpose**: Central navigation hub and dashboard

**Features**:
- Bottom navigation bar with program, history, settings tabs
- Quick action cards (Recent Workouts, Quick Start)
- Progress overview widgets
- Floating action button for quick program creation

**Navigation Structure**:
```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: 'Programs',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ],
)
```

### Program Management Screens
**Location**: `lib/screens/programs/`

#### ProgramsScreen
**Purpose**: Display and manage user's workout programs

**Features**:
- Program list with search and filtering
- Swipe-to-archive actions
- Pull-to-refresh functionality
- Empty state with onboarding guidance
- Floating action button for program creation

**List Item Design**:
```dart
Card(
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(program.name.substring(0, 1).toUpperCase()),
    ),
    title: Text(program.name),
    subtitle: Text('${program.weekCount} weeks • Created ${formatDate(program.createdAt)}'),
    trailing: IconButton(
      icon: Icon(Icons.more_vert),
      onPressed: () => _showProgramOptions(program),
    ),
    onTap: () => _navigateToProgram(program),
  ),
)
```

#### ProgramDetailScreen
**Purpose**: Display program overview with week management

**Features**:
- Program header with name, description, and metadata
- Week list with reordering capabilities
- Week creation and duplication actions
- Progress tracking visual indicators
- Share and export options

### Week Management Screens
**Location**: `lib/screens/weeks/`

#### WeeksScreen
**Purpose**: Manage weeks within a program

**Features**:
- Week cards with progress indicators
- Drag-and-drop reordering
- Week duplication with visual feedback
- Quick workout access from week cards
- Week notes and scheduling

**Week Card Component**:
```dart
Card(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        title: Text(week.name),
        subtitle: Text('${week.workoutCount} workouts'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleWeekAction(action, week),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(
          value: week.completionPercentage,
          backgroundColor: Colors.grey[300],
        ),
      ),
    ],
  ),
)
```

### Workout Management Screens
**Location**: `lib/screens/workouts/`

#### WorkoutDetailScreen
**Purpose**: Workout execution interface showing exercises and sets

**Features**:
- Exercise list for selected workout
- Exercise type color coding and visual indicators
- Navigation to exercise detail screens
- Exercise creation functionality
- Integration with workout execution flow
- Real-time updates from ProgramProvider

**Exercise Display Pattern**:
```dart
Card(
  child: ListTile(
    leading: CircleAvatar(
      backgroundColor: _getExerciseTypeColor(exercise.exerciseType),
      child: Icon(_getExerciseTypeIcon(exercise.exerciseType)),
    ),
    title: Text(exercise.name),
    subtitle: Text('${exercise.exerciseType.displayName} • ${setCount} sets'),
    trailing: Icon(Icons.chevron_right),
    onTap: () => _navigateToExerciseDetail(exercise),
  ),
)
```

### Exercise Management Screens
**Location**: `lib/screens/exercises/`

#### CreateExerciseScreen
**Purpose**: Create new exercises with type-specific configuration

**Features**:
- Exercise type dropdown with all available types
- Dynamic field requirement display based on selected type
- Form validation with real-time feedback
- Context breadcrumb (Program → Week → Workout)
- Helper text and user guidance tips

**Exercise Type Selection Pattern**:
```dart
DropdownButtonFormField<ExerciseType>(
  decoration: InputDecoration(
    labelText: 'Exercise Type *',
    border: OutlineInputBorder(),
  ),
  value: _selectedExerciseType,
  items: ExerciseType.values.map((type) {
    return DropdownMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(_getTypeIcon(type), color: _getTypeColor(type)),
          SizedBox(width: 8),
          Text(type.displayName),
        ],
      ),
    );
  }).toList(),
  onChanged: (value) => setState(() => _selectedExerciseType = value),
)
```

#### ExerciseDetailScreen  
**Purpose**: Manage individual exercises and their sets

**Features**:
- Exercise information display with type-specific styling
- Set list management with completion tracking
- Set creation and editing navigation
- Exercise type color coding
- Set completion toggle functionality

**Set List Display Pattern**:
```dart
ListView.builder(
  itemCount: sets.length,
  itemBuilder: (context, index) {
    final set = sets[index];
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: set.checked,
          onChanged: (value) => _toggleSetCompletion(set),
        ),
        title: Text('Set ${index + 1}'),
        subtitle: Text(set.displayString),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (action) => _handleSetAction(action, set),
        ),
      ),
    );
  },
)
```

### Set Management Screens
**Location**: `lib/screens/sets/`

#### CreateSetScreen
**Purpose**: Create and edit sets with exercise type-specific fields

**Features**:
- Dynamic form generation based on exercise type
- Exercise type-specific input validation
- Unit conversion (minutes/seconds, km/meters)
- Loading states and error handling
- Context information display

**Exercise Type-Specific Input Pattern**:
```dart
List<Widget> _buildFieldsForExerciseType() {
  final fields = <Widget>[];
  
  // Dynamic field generation based on exercise type requirements
  if (_requiredFields.contains('reps') || _optionalFields.contains('reps')) {
    fields.add(_buildRepsField());
  }
  
  if (_requiredFields.contains('weight') || _optionalFields.contains('weight')) {
    fields.add(_buildWeightField());
  }
  
  if (_requiredFields.contains('duration') || _optionalFields.contains('duration')) {
    fields.add(_buildDurationField()); // Minutes + Seconds inputs
  }
  
  return fields;
}

Widget _buildDurationField() {
  return Row(
    children: [
      Expanded(
        child: TextFormField(
          controller: _durationMinutesController,
          decoration: InputDecoration(
            labelText: 'Minutes${_requiredFields.contains('duration') ? ' *' : ''}',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.schedule),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
      SizedBox(width: 16),
      Expanded(
        child: TextFormField(
          controller: _durationSecondsController,
          decoration: InputDecoration(
            labelText: 'Seconds',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final seconds = int.tryParse(value);
              if (seconds == null || seconds < 0 || seconds >= 60) {
                return 'Must be 0-59';
              }
            }
            return null;
          },
        ),
      ),
    ],
  );
}
```

## Exercise & Set Components

### Exercise Type Visual Elements

#### Exercise Type Colors and Icons
```dart
Color _getExerciseTypeColor(ExerciseType type) {
  switch (type) {
    case ExerciseType.strength:
      return Colors.blue;
    case ExerciseType.cardio:
      return Colors.red;
    case ExerciseType.timeBased:
      return Colors.orange;
    case ExerciseType.bodyweight:
      return Colors.green;
    case ExerciseType.custom:
      return Colors.purple;
  }
}

IconData _getExerciseTypeIcon(ExerciseType type) {
  switch (type) {
    case ExerciseType.strength:
      return Icons.fitness_center;
    case ExerciseType.cardio:
      return Icons.directions_run;
    case ExerciseType.timeBased:
      return Icons.timer;
    case ExerciseType.bodyweight:
      return Icons.accessibility;
    case ExerciseType.custom:
      return Icons.tune;
  }
}
```

#### Exercise Type Information Display
```dart
Widget _buildExerciseTypeInfo() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getExerciseTypeIcon(_selectedExerciseType),
              color: _getExerciseTypeColor(_selectedExerciseType),
            ),
            SizedBox(width: 8),
            Text(
              '${_selectedExerciseType.displayName} Exercise',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(_getExerciseTypeDescription()),
        SizedBox(height: 8),
        ..._buildFieldRequirements(),
      ],
    ),
  );
}
```

### Set Display Components

#### Set Completion Tracking
```dart
class SetCompletionCard extends StatelessWidget {
  final ExerciseSet set;
  final int setNumber;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: set.checked ? 1 : 2,
      color: set.checked 
        ? Theme.of(context).colorScheme.surfaceVariant 
        : null,
      child: ListTile(
        leading: Checkbox(
          value: set.checked,
          onChanged: (_) => onToggle?.call(),
        ),
        title: Text(
          'Set $setNumber',
          style: TextStyle(
            decoration: set.checked 
              ? TextDecoration.lineThrough 
              : null,
          ),
        ),
        subtitle: Text(
          set.displayString,
          style: TextStyle(
            color: set.checked 
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
          ),
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
```

## Reusable UI Components

### Loading and Error States
**Location**: `lib/widgets/common/`

#### LoadingIndicator
```dart
class LoadingIndicator extends StatelessWidget {
  final String? message;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
```

#### ErrorMessage
```dart
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### EmptyState
```dart
class EmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 96, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (description != null) ...[
              SizedBox(height: 8),
              Text(description!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

### Data Display Components

#### ProgramCard
```dart
class ProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      program.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(action),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              if (program.description != null) ...[
                SizedBox(height: 8),
                Text(program.description!),
              ],
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16),
                  SizedBox(width: 4),
                  Text('${program.weekCount} weeks'),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 4),
                  Text('Created ${_formatDate(program.createdAt)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### WeekProgressCard
```dart
class WeekProgressCard extends StatelessWidget {
  final Week week;
  final double completionPercentage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(week.name, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: completionPercentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text('${(completionPercentage * 100).round()}% complete'),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Form Components

#### CustomTextField
```dart
class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(),
        errorMaxLines: 2,
      ),
    );
  }
}
```

#### NumberInputField
```dart
class NumberInputField extends StatelessWidget {
  final String labelText;
  final double? value;
  final ValueChanged<double?> onChanged;
  final double? min;
  final double? max;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toStringAsFixed(decimalPlaces),
      keyboardType: TextInputType.numberWithOptions(decimal: decimalPlaces > 0),
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        suffixText: _getSuffixText(),
      ),
      validator: (value) => _validateNumber(value),
      onChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null && _isValidRange(parsed)) {
          onChanged(parsed);
        }
      },
    );
  }
}
```

## State Integration Patterns

### Consumer Pattern Usage
```dart
class ProgramsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, programProvider, child) {
        if (programProvider.isLoadingPrograms) {
          return LoadingIndicator(message: 'Loading programs...');
        }

        if (programProvider.error != null) {
          return ErrorMessage(
            message: programProvider.error!,
            onRetry: () {
              programProvider.clearError();
              programProvider.loadPrograms();
            },
          );
        }

        if (programProvider.programs.isEmpty) {
          return EmptyState(
            title: 'No Programs Yet',
            description: 'Create your first workout program to get started',
            icon: Icons.fitness_center,
            action: ElevatedButton(
              onPressed: () => _navigateToCreateProgram(),
              child: Text('Create Program'),
            ),
          );
        }

        return ListView.builder(
          itemCount: programProvider.programs.length,
          itemBuilder: (context, index) {
            final program = programProvider.programs[index];
            return ProgramCard(
              program: program,
              onTap: () => programProvider.selectProgram(program),
              onEdit: () => _editProgram(program),
              onDelete: () => _deleteProgram(program),
            );
          },
        );
      },
    );
  }
}
```

### Selector Pattern for Performance
```dart
class WorkoutTimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<WorkoutProvider, Duration>(
      selector: (context, provider) => provider.currentRestTime,
      builder: (context, restTime, child) {
        return Text(
          '${restTime.inMinutes}:${(restTime.inSeconds % 60).toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.displayMedium,
        );
      },
    );
  }
}
```

## Navigation Patterns

### Named Routes
```dart
// main.dart
MaterialApp(
  routes: {
    '/': (context) => AuthWrapper(),
    '/programs': (context) => ProgramsScreen(),
    '/program': (context) => ProgramDetailScreen(),
    '/workout': (context) => WorkoutScreen(),
    '/settings': (context) => SettingsScreen(),
  },
)
```

### Programmatic Navigation
```dart
// Navigate with arguments
Navigator.pushNamed(
  context,
  '/program',
  arguments: ProgramArgs(program: selectedProgram),
);

// Navigate and replace
Navigator.pushReplacementNamed(context, '/home');

// Pop with result
Navigator.pop(context, CreatedProgram(program));
```

## Accessibility Implementation

### Semantic Labels
```dart
Semantics(
  label: 'Program: ${program.name}',
  child: ProgramCard(program: program),
)
```

### Focus Management
```dart
class CreateProgramScreen extends StatefulWidget {
  @override
  _CreateProgramScreenState createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus name field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }
}
```

### Color and Contrast
```dart
// Theme definition with accessible colors
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF2196F3),
    brightness: Brightness.light,
  ).copyWith(
    // Ensure sufficient contrast ratios
    primary: Color(0xFF1976D2),      // 4.5:1 contrast on white
    error: Color(0xFFD32F2F),        // 4.5:1 contrast on white
  ),
)
```

## Testing Strategies

### Widget Testing
```dart
group('ProgramCard Widget', () {
  testWidgets('displays program information correctly', (tester) async {
    final program = Program(
      id: '1',
      name: 'Test Program',
      description: 'Test Description',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'user1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCard(program: program),
      ),
    );

    expect(find.text('Test Program'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });

  testWidgets('handles tap events correctly', (tester) async {
    bool tapped = false;
    final program = Program(/* test data */);

    await tester.pumpWidget(
      MaterialApp(
        home: ProgramCard(
          program: program,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(ProgramCard));
    expect(tapped, isTrue);
  });
});
```

### Golden Tests for Visual Regression
```dart
testWidgets('ProgramCard golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProgramCard(program: testProgram),
      ),
    ),
  );

  await expectLater(
    find.byType(ProgramCard),
    matchesGoldenFile('program_card.png'),
  );
});
```

## Performance Optimization

### ListView Optimization
```dart
ListView.builder(
  itemCount: programs.length,
  itemBuilder: (context, index) {
    return ProgramCard(
      key: ValueKey(programs[index].id), // Stable keys for performance
      program: programs[index],
    );
  },
)
```

### Image Optimization
```dart
FadeInImage.memoryNetwork(
  placeholder: kTransparentImage,
  image: program.imageUrl,
  fit: BoxFit.cover,
  fadeInDuration: Duration(milliseconds: 300),
)
```

### Memory Management
```dart
class _WorkoutScreenState extends State<WorkoutScreen> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

This UI component architecture provides a scalable, accessible, and maintainable foundation for the FitTrack application with consistent design patterns and excellent user experience across all workout management features.