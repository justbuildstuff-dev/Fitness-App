import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/exercises/custom_exercise_form_screen.dart';
import 'package:fittrack/providers/exercise_library_provider.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';

// Mock provider for testing
class MockExerciseLibraryProvider extends ChangeNotifier
    implements ExerciseLibraryProvider {
  int _customExerciseCount = 0;
  bool _canCreateCustomExercise = true;
  String? _error;
  bool _isLoading = false;
  final Set<String> _existingNames = {};

  void setCustomExerciseCount(int count) {
    _customExerciseCount = count;
    _canCreateCustomExercise = count < maxCustomExercises;
    notifyListeners();
  }

  void addExistingName(String name) {
    _existingNames.add(name.toLowerCase());
  }

  @override
  List<LibraryExercise> get libraryExercises => [];

  @override
  List<CustomExercise> get customExercises => [];

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLibraryLoaded => true;

  @override
  String? get error => _error;

  @override
  int get customExerciseCount => _customExerciseCount;

  @override
  bool get canCreateCustomExercise => _canCreateCustomExercise;

  @override
  Future<void> loadLibrary() async {}

  @override
  List<dynamic> searchExercises({
    String query = '',
    MuscleGroup? muscleGroup,
    ExerciseType? exerciseType,
  }) {
    return [];
  }

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
  }) async {
    if (!_canCreateCustomExercise) {
      _error = 'Maximum custom exercises reached';
      return null;
    }
    return 'mock_id_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<bool> updateCustomExercise(CustomExercise exercise) async {
    return true;
  }

  @override
  Future<bool> deleteCustomExercise(String exerciseId) async {
    return true;
  }

  @override
  bool isNameAvailable(String name, {String? excludeId}) {
    return !_existingNames.contains(name.toLowerCase());
  }

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

  Widget createTestWidget({CustomExercise? exercise}) {
    return MaterialApp(
      home: ChangeNotifierProvider<ExerciseLibraryProvider>.value(
        value: mockProvider,
        child: CustomExerciseFormScreen(
          exercise: exercise,
        ),
      ),
    );
  }

  group('CustomExerciseFormScreen - Create Mode', () {
    testWidgets('should display create title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Create Custom Exercise'), findsOneWidget);
    });

    testWidgets('should display CREATE button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CREATE'), findsOneWidget);
    });

    testWidgets('should display name input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Exercise Name *'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should display exercise type chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Exercise Type *'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);
    });

    testWidgets('should display muscle group sections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Primary Muscles * (select at least one)'), findsOneWidget);
      expect(find.text('Secondary Muscles (optional)'), findsOneWidget);
    });

    testWidgets('should display all muscle groups', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      for (final muscle in MuscleGroup.values) {
        // Each muscle appears twice (primary and secondary sections)
        expect(find.text(muscle.displayName), findsNWidgets(2));
      }
    });

    testWidgets('should display custom exercise count', (tester) async {
      mockProvider.setCustomExerciseCount(5);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('5/$maxCustomExercises custom exercises'), findsOneWidget);
    });

    testWidgets('should display limit warning when at max', (tester) async {
      mockProvider.setCustomExerciseCount(maxCustomExercises);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('maximum of $maxCustomExercises custom exercises'),
        findsOneWidget,
      );
    });

    testWidgets('should not show delete button in create mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Delete Exercise'), findsNothing);
    });

    testWidgets('should show error for empty name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select a primary muscle (required for form validation to proceed)
      await tester.tap(find.text('Chest').first);
      await tester.pumpAndSettle();

      // Try to create without entering name
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an exercise name'), findsOneWidget);
    });

    testWidgets('should show error for duplicate name', (tester) async {
      mockProvider.addExistingName('Existing Exercise');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter duplicate name
      await tester.enterText(find.byType(TextFormField), 'Existing Exercise');
      await tester.pumpAndSettle();

      // Select a primary muscle
      await tester.tap(find.text('Chest').first);
      await tester.pumpAndSettle();

      // Try to create
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      expect(find.text('An exercise with this name already exists'), findsOneWidget);
    });

    testWidgets('should allow selecting exercise type', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Strength should be selected by default
      final strengthChip = find.ancestor(
        of: find.text('Strength'),
        matching: find.byType(ChoiceChip),
      );
      expect(tester.widget<ChoiceChip>(strengthChip).selected, true);

      // Select Bodyweight
      await tester.tap(find.text('Bodyweight'));
      await tester.pumpAndSettle();

      // Verify Bodyweight is now selected
      final bodyweightChip = find.ancestor(
        of: find.text('Bodyweight'),
        matching: find.byType(ChoiceChip),
      );
      expect(tester.widget<ChoiceChip>(bodyweightChip).selected, true);
    });

    testWidgets('should allow selecting primary muscles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Select Chest as primary
      await tester.tap(find.text('Chest').first);
      await tester.pumpAndSettle();

      // Find the chip in primary section and verify it's selected
      final primaryChips = find.ancestor(
        of: find.text('Chest'),
        matching: find.byType(FilterChip),
      );
      expect(primaryChips, findsNWidgets(2)); // One in each section

      // Error message should disappear
      expect(
        find.text('Select at least one primary muscle group'),
        findsNothing,
      );
    });
  });

  group('CustomExerciseFormScreen - Edit Mode', () {
    late CustomExercise testExercise;

    setUp(() {
      final now = DateTime.now();
      testExercise = CustomExercise(
        id: 'test_exercise_1',
        name: 'Test Exercise',
        exerciseType: ExerciseType.bodyweight,
        primaryMuscles: [MuscleGroup.chest, MuscleGroup.arms],
        secondaryMuscles: [MuscleGroup.shoulders],
        userId: 'user_123',
        createdAt: now,
        updatedAt: now,
      );
    });

    testWidgets('should display edit title', (tester) async {
      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      expect(find.text('Edit Custom Exercise'), findsOneWidget);
    });

    testWidgets('should display SAVE button', (tester) async {
      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      expect(find.text('SAVE'), findsOneWidget);
    });

    testWidgets('should pre-populate name field', (tester) async {
      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      expect(find.text('Test Exercise'), findsOneWidget);
    });

    testWidgets('should pre-select exercise type', (tester) async {
      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      final bodyweightChip = find.ancestor(
        of: find.text('Bodyweight'),
        matching: find.byType(ChoiceChip),
      );
      expect(tester.widget<ChoiceChip>(bodyweightChip).selected, true);
    });

    testWidgets('should show delete button in edit mode', (tester) async {
      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      expect(find.text('Delete Exercise'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog on delete', (tester) async {
      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      // Scroll to and tap delete button
      await tester.scrollUntilVisible(
        find.text('Delete Exercise'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete Exercise'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Delete Exercise'), findsNWidgets(2)); // Title + button
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
      expect(find.textContaining('"Test Exercise"'), findsOneWidget);
    });

    testWidgets('should not show exercise count in edit mode', (tester) async {
      mockProvider.setCustomExerciseCount(5);

      await tester.pumpWidget(createTestWidget(exercise: testExercise));
      await tester.pumpAndSettle();

      expect(
        find.text('5/$maxCustomExercises custom exercises'),
        findsNothing,
      );
    });
  });

  group('CustomExerciseFormScreen - Tips Section', () {
    testWidgets('should display tips section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to tips section
      await tester.scrollUntilVisible(
        find.text('Tips'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Tips'), findsOneWidget);
      expect(
        find.textContaining('Custom exercises can be used in any workout'),
        findsOneWidget,
      );
    });
  });
}
