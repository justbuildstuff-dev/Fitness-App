import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/profile/my_exercises_screen.dart';
import 'package:fittrack/providers/exercise_library_provider.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';

// Mock provider for testing
class MockExerciseLibraryProvider extends ChangeNotifier
    implements ExerciseLibraryProvider {
  List<CustomExercise> _customExercises = [];
  bool _isLoading = false;
  String? _error;

  void setCustomExercises(List<CustomExercise> exercises) {
    _customExercises = exercises;
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
  List<LibraryExercise> get libraryExercises => [];

  @override
  List<CustomExercise> get customExercises => _customExercises;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLibraryLoaded => true;

  @override
  String? get error => _error;

  @override
  int get customExerciseCount => _customExercises.length;

  @override
  bool get canCreateCustomExercise =>
      _customExercises.length < maxCustomExercises;

  @override
  Future<void> loadLibrary() async {}

  @override
  List<dynamic> searchExercises({
    String query = '',
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) =>
      [];

  @override
  List<dynamic> getExercisesByMuscleGroup(MuscleGroup muscleGroup) => [];

  @override
  List<dynamic> getExercisesByType(ExerciseType exerciseType) => [];

  @override
  Future<String?> createCustomExercise({
    required String name,
    required ExerciseType exerciseType,
    required List<MuscleGroup> primaryMuscles,
    List<MuscleGroup> secondaryMuscles = const [],
  }) async =>
      'mock_id';

  @override
  Future<bool> updateCustomExercise(CustomExercise exercise) async => true;

  @override
  Future<bool> deleteCustomExercise(String exerciseId) async {
    _customExercises.removeWhere((e) => e.id == exerciseId);
    notifyListeners();
    return true;
  }

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

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<ExerciseLibraryProvider>.value(
        value: mockProvider,
        child: const MyExercisesScreen(),
      ),
    );
  }

  CustomExercise createTestExercise({
    String id = 'test_1',
    String name = 'Test Exercise',
    ExerciseType type = ExerciseType.strength,
    List<MuscleGroup> primaryMuscles = const [MuscleGroup.chest],
  }) {
    final now = DateTime.now();
    return CustomExercise(
      id: id,
      name: name,
      exerciseType: type,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: [],
      userId: 'user_123',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('MyExercisesScreen', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('My Exercises'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading', (tester) async {
      mockProvider.setLoading(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no exercises', (tester) async {
      mockProvider.setCustomExercises([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Custom Exercises Yet'), findsOneWidget);
      expect(
        find.text('Create your own exercises to use in workouts'),
        findsOneWidget,
      );
      expect(find.text('Create Exercise'), findsOneWidget);
    });

    testWidgets('should display exercise list when exercises exist',
        (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Exercise One'),
        createTestExercise(id: '2', name: 'Exercise Two'),
        createTestExercise(id: '3', name: 'Exercise Three'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Exercise One'), findsOneWidget);
      expect(find.text('Exercise Two'), findsOneWidget);
      expect(find.text('Exercise Three'), findsOneWidget);
    });

    testWidgets('should display exercise count', (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Exercise One'),
        createTestExercise(id: '2', name: 'Exercise Two'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('2/$maxCustomExercises exercises'), findsOneWidget);
    });

    testWidgets('should display FAB when can create more', (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Exercise One'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should hide FAB when at max limit', (tester) async {
      // Create 20 exercises (max limit)
      final exercises = List.generate(
        maxCustomExercises,
        (i) => createTestExercise(id: 'id_$i', name: 'Exercise $i'),
      );
      mockProvider.setCustomExercises(exercises);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('should display error state when error occurs', (tester) async {
      mockProvider.setCustomExercises([]);
      mockProvider.setError('Network error');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load exercises'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('should show edit and delete icons on exercise card',
        (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Test Exercise'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Test Exercise'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Delete Exercise'), findsOneWidget);
      expect(find.textContaining('"Test Exercise"'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('should cancel delete when cancel pressed', (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Test Exercise'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Exercise should still exist
      expect(find.text('Test Exercise'), findsOneWidget);
    });

    testWidgets('should delete exercise when confirmed', (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Test Exercise'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap delete in dialog
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      // Exercise should be removed, empty state should show
      expect(find.text('No Custom Exercises Yet'), findsOneWidget);
    });

    testWidgets('should display exercise type and muscles', (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(
          id: '1',
          name: 'Bench Press',
          type: ExerciseType.strength,
          primaryMuscles: [MuscleGroup.chest, MuscleGroup.shoulders],
        ),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.textContaining('Strength'), findsOneWidget);
      expect(find.textContaining('Chest'), findsOneWidget);
    });

    testWidgets('should show Add button in header when exercises exist',
        (tester) async {
      mockProvider.setCustomExercises([
        createTestExercise(id: '1', name: 'Test Exercise'),
      ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('should hide Add button when at max limit', (tester) async {
      // Create 20 exercises (max limit)
      final exercises = List.generate(
        maxCustomExercises,
        (i) => createTestExercise(id: 'id_$i', name: 'Exercise $i'),
      );
      mockProvider.setCustomExercises(exercises);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add button should not appear
      expect(find.text('Add'), findsNothing);
    });
  });
}
