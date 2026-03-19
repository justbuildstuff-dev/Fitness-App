import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/exercises/exercise_picker_screen.dart';
import 'package:fittrack/providers/exercise_library_provider.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';

// Mock provider for testing
class MockExerciseLibraryProvider extends ChangeNotifier
    implements ExerciseLibraryProvider {
  List<LibraryExercise> _libraryExercises = [];
  bool _isLoading = false;
  bool _isLibraryLoaded = true;
  String? _error;

  void setLibraryExercises(List<LibraryExercise> exercises) {
    _libraryExercises = exercises;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  List<LibraryExercise> get libraryExercises => _libraryExercises;

  @override
  List<CustomExercise> get customExercises => [];

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLibraryLoaded => _isLibraryLoaded;

  @override
  String? get error => _error;

  @override
  int get customExerciseCount => 0;

  @override
  bool get canCreateCustomExercise => true;

  @override
  Future<void> loadLibrary() async {}

  @override
  List<dynamic> searchExercises({
    String query = '',
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) {
    return _libraryExercises.where((exercise) {
      final matchesQuery = query.isEmpty ||
          exercise.name.toLowerCase().contains(query.toLowerCase());
      final matchesMuscle = muscleGroup == null ||
          exercise.primaryMuscles.contains(muscleGroup) ||
          exercise.secondaryMuscles.contains(muscleGroup);
      final matchesType =
          exerciseType == null || exercise.exerciseType == exerciseType;
      return matchesQuery && matchesMuscle && matchesType;
    }).toList();
  }

  @override
  List<dynamic> getExercisesByMuscleGroup(MuscleGroup muscleGroup) {
    return searchExercises(muscleGroup: muscleGroup);
  }

  @override
  List<dynamic> getExercisesByType(ExerciseType exerciseType) {
    return searchExercises(exerciseType: exerciseType);
  }

  @override
  Future<String?> createCustomExercise({
    required String name,
    required ExerciseType exerciseType,
    required List<MuscleGroup> primaryMuscles,
    List<MuscleGroup> secondaryMuscles = const [],
  }) async {
    return 'mock_id';
  }

  @override
  Future<bool> updateCustomExercise(dynamic exercise) async => true;

  @override
  Future<bool> deleteCustomExercise(String exerciseId) async => true;

  @override
  bool isNameAvailable(String name, {String? excludeId}) => true;

  @override
  CustomExercise? getCustomExerciseById(String id) => null;

  @override
  LibraryExercise? getLibraryExerciseById(String id) => null;

  @override
  void cancelSubscriptions() {}
}

void main() {
  late MockExerciseLibraryProvider mockProvider;

  setUp(() {
    mockProvider = MockExerciseLibraryProvider();
  });

  Widget createTestWidget({bool showCreateCustomButton = true}) {
    return MaterialApp(
      home: ChangeNotifierProvider<ExerciseLibraryProvider>.value(
        value: mockProvider,
        child: ExercisePickerScreen(
          showCreateCustomButton: showCreateCustomButton,
        ),
      ),
    );
  }

  group('ExercisePickerScreen', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Exercise Library'), findsOneWidget);
    });

    testWidgets('should display search bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search exercises...'), findsOneWidget);
    });

    testWidgets('should display filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Muscle Group'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (tester) async {
      mockProvider.setLoading(true);
      mockProvider._isLibraryLoaded = false;

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no exercises', (tester) async {
      mockProvider.setLibraryExercises([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No exercises available'), findsOneWidget);
    });

    testWidgets('should display exercises in list', (tester) async {
      mockProvider.setLibraryExercises([
        const LibraryExercise(
          id: 'lib_bench_press',
          name: 'Barbell Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.shoulders],
        ),
        const LibraryExercise(
          id: 'lib_pull_up',
          name: 'Pull-up',
          exerciseType: ExerciseType.bodyweight,
          primaryMuscles: [MuscleGroup.back],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Pull-up'), findsOneWidget);
      expect(find.text('2 exercises'), findsOneWidget);
    });

    testWidgets('should filter exercises by search query', (tester) async {
      mockProvider.setLibraryExercises([
        const LibraryExercise(
          id: 'lib_bench_press',
          name: 'Barbell Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        ),
        const LibraryExercise(
          id: 'lib_pull_up',
          name: 'Pull-up',
          exerciseType: ExerciseType.bodyweight,
          primaryMuscles: [MuscleGroup.back],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Bench');
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Pull-up'), findsNothing);
      expect(find.text('1 exercise'), findsOneWidget);
    });

    testWidgets('should show clear button when search has text', (tester) async {
      mockProvider.setLibraryExercises([
        const LibraryExercise(
          id: 'lib_bench_press',
          name: 'Barbell Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Bench');
      await tester.pumpAndSettle();

      // Now clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should display FAB when showCreateCustomButton is true',
        (tester) async {
      await tester.pumpWidget(createTestWidget(showCreateCustomButton: true));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Create Custom'), findsOneWidget);
    });

    testWidgets('should hide FAB when showCreateCustomButton is false',
        (tester) async {
      await tester.pumpWidget(createTestWidget(showCreateCustomButton: false));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('should show results count', (tester) async {
      mockProvider.setLibraryExercises([
        const LibraryExercise(
          id: 'lib_1',
          name: 'Exercise 1',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        ),
        const LibraryExercise(
          id: 'lib_2',
          name: 'Exercise 2',
          exerciseType: ExerciseType.bodyweight,
          primaryMuscles: [MuscleGroup.back],
        ),
        const LibraryExercise(
          id: 'lib_3',
          name: 'Exercise 3',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.legs],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('3 exercises'), findsOneWidget);
    });

    testWidgets('should show no exercises found when filters match nothing',
        (tester) async {
      mockProvider.setLibraryExercises([
        const LibraryExercise(
          id: 'lib_bench_press',
          name: 'Barbell Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Search for something that doesn't exist
      await tester.enterText(find.byType(TextField), 'NonexistentExercise');
      await tester.pumpAndSettle();

      expect(find.text('No exercises found'), findsOneWidget);
      expect(find.text('Try adjusting your search or filters'), findsOneWidget);
    });

    testWidgets('should display error state when error occurs', (tester) async {
      mockProvider._isLibraryLoaded = false;
      mockProvider.setError('Network error');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load exercise library'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should open bottom sheet when tapping exercise',
        (tester) async {
      mockProvider.setLibraryExercises([
        const LibraryExercise(
          id: 'lib_bench_press',
          name: 'Barbell Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
          secondaryMuscles: [MuscleGroup.shoulders],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on exercise
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with exercise details
      // The button now shows "Add 1 Set to Workout" with set count selector
      expect(find.text('Add 1 Set to Workout'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      // Check for set count selector
      expect(find.text('Number of Sets'), findsOneWidget);
    });
  });

  group('ExercisePickerScreen — multi-select mode', () {
    late List<LibraryExercise> twoExercises;

    setUp(() {
      twoExercises = const [
        LibraryExercise(
          id: 'lib_bench',
          name: 'Bench Press',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest],
        ),
        LibraryExercise(
          id: 'lib_squat',
          name: 'Squat',
          exerciseType: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.legs],
        ),
      ];
    });

    Widget createMultiSelectWidget({int initialSetCount = 3}) {
      return MaterialApp(
        home: ChangeNotifierProvider<ExerciseLibraryProvider>.value(
          value: mockProvider,
          child: ExercisePickerScreen(
            isMultiSelect: true,
            initialSetCount: initialSetCount,
          ),
        ),
      );
    }

    testWidgets('shows "Select Exercises" as title in multi-select mode',
        (tester) async {
      /// Test Purpose: Verify AppBar title changes in multi-select mode
      mockProvider.setLibraryExercises([]);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Exercises'), findsOneWidget);
    });

    testWidgets('shows checkboxes instead of avatars in multi-select mode',
        (tester) async {
      /// Test Purpose: Verify list tiles show checkboxes in multi-select mode
      mockProvider.setLibraryExercises(twoExercises);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(2));
    });

    testWidgets('shows bottom bar in multi-select mode', (tester) async {
      /// Test Purpose: Verify the multi-select bottom bar is rendered
      mockProvider.setLibraryExercises(twoExercises);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      expect(find.text('sets each'), findsOneWidget);
    });

    testWidgets('Add button is disabled with fewer than 2 exercises selected',
        (tester) async {
      /// Test Purpose: Verify Add button disabled until 2+ exercises selected
      mockProvider.setLibraryExercises(twoExercises);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      // Initially 0 selected — button shows "Add 0 exercises"
      final addButton = find.widgetWithText(ElevatedButton, 'Add 0 exercises');
      expect(addButton, findsOneWidget);

      // The button should be disabled (no onPressed)
      final button = tester.widget<ElevatedButton>(addButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting 1 exercise keeps Add button disabled', (tester) async {
      /// Test Purpose: Verify 1 selection is insufficient to enable Add
      mockProvider.setLibraryExercises(twoExercises);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      // Select first exercise
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(ElevatedButton, 'Add 1 exercise');
      expect(addButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(addButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('selecting 2 exercises enables Add button', (tester) async {
      /// Test Purpose: Verify 2+ selections enable the Add button
      mockProvider.setLibraryExercises(twoExercises);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      // Select both exercises
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Squat'));
      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(ElevatedButton, 'Add 2 exercises');
      expect(addButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(addButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('does not open bottom sheet when tapping in multi-select mode',
        (tester) async {
      /// Test Purpose: Verify tap toggles selection instead of opening detail sheet
      mockProvider.setLibraryExercises(twoExercises);
      await tester.pumpWidget(createMultiSelectWidget());
      await tester.pumpAndSettle();

      // Tap an exercise — should toggle checkbox, not open bottom sheet
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // No bottom sheet content (like "Number of Sets" from single-select sheet)
      expect(find.text('Number of Sets'), findsNothing);
      // Checkbox should be checked
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.any((c) => c.value == true), isTrue);
    });
  });
}
