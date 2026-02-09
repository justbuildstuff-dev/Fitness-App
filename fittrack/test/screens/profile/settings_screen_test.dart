import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/screens/profile/settings_screen.dart';
import 'package:fittrack/providers/theme_provider.dart';
import 'package:fittrack/providers/exercise_library_provider.dart';
import 'package:fittrack/providers/template_provider.dart';
import 'package:fittrack/models/library_exercise.dart';
import 'package:fittrack/models/custom_exercise.dart';
import 'package:fittrack/models/muscle_group.dart';
import 'package:fittrack/models/exercise.dart';
import 'package:fittrack/models/templates/templates.dart';

import 'settings_screen_test.mocks.dart';

/// Mock ExerciseLibraryProvider for settings screen tests
class MockExerciseLibraryProvider extends ChangeNotifier
    implements ExerciseLibraryProvider {
  @override
  List<LibraryExercise> get libraryExercises => [];

  @override
  List<CustomExercise> get customExercises => [];

  @override
  bool get isLoading => false;

  @override
  bool get isLibraryLoaded => true;

  @override
  String? get error => null;

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

/// Mock TemplateProvider for settings screen tests
class MockTemplateProvider extends ChangeNotifier implements TemplateProvider {
  @override
  List<WorkoutTemplate> get workoutTemplates => [];

  @override
  List<WeekTemplate> get weekTemplates => [];

  @override
  List<ProgramTemplate> get programTemplates => [];

  @override
  List<ProgramTemplate> get prebuiltPrograms => [];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingPrebuilt => false;

  @override
  bool get isPrebuiltLoaded => true;

  @override
  String? get error => null;

  @override
  int get workoutTemplateCount => 0;

  @override
  int get weekTemplateCount => 0;

  @override
  int get programTemplateCount => 0;

  @override
  bool get canSaveWorkoutTemplate => true;

  @override
  bool get canSaveWeekTemplate => true;

  @override
  bool get canSaveProgramTemplate => true;

  @override
  void initialize(String userId) {}

  @override
  void clearError() {}

  @override
  void cancelSubscriptions() {}

  @override
  Future<void> loadPrebuiltPrograms() async {}

  @override
  Future<String?> saveWorkoutTemplate(WorkoutTemplate template) async => 'mock_id';

  @override
  Future<String?> saveWeekTemplate(WeekTemplate template) async => 'mock_id';

  @override
  Future<String?> saveProgramTemplate(ProgramTemplate template) async => 'mock_id';

  @override
  Future<String?> saveWorkoutAsTemplate({
    required String name,
    String? description,
    required List<TemplateExercise> exercises,
  }) async => 'mock_id';

  @override
  Future<String?> saveWeekAsTemplate({
    required String name,
    String? description,
    required List<TemplateWorkout> workouts,
  }) async => 'mock_id';

  @override
  Future<String?> saveProgramAsTemplate({
    required String name,
    String? description,
    required List<TemplateWeek> weeks,
  }) async => 'mock_id';

  @override
  Future<String?> applyWorkoutTemplate({
    required WorkoutTemplate template,
    required String weekId,
    required String programId,
    String? customName,
    int? orderIndex,
    List<String> existingWorkoutNames = const [],
  }) async => 'mock_id';

  @override
  Future<String?> applyWeekTemplate({
    required WeekTemplate template,
    required String programId,
    required int order,
    String? customName,
    List<String> existingWeekNames = const [],
  }) async => 'mock_id';

  @override
  Future<String?> applyProgramTemplate({
    required ProgramTemplate template,
    String? customName,
    List<String> existingProgramNames = const [],
  }) async => 'mock_id';

  @override
  Future<bool> deleteWorkoutTemplate(String templateId) async => true;

  @override
  Future<bool> deleteWeekTemplate(String templateId) async => true;

  @override
  Future<bool> deleteProgramTemplate(String templateId) async => true;

  @override
  Future<bool> renameWorkoutTemplate(String templateId, String newName) async => true;

  @override
  Future<bool> renameWeekTemplate(String templateId, String newName) async => true;

  @override
  Future<bool> renameProgramTemplate(String templateId, String newName) async => true;

  @override
  WorkoutTemplate? getWorkoutTemplateById(String id) => null;

  @override
  WeekTemplate? getWeekTemplateById(String id) => null;

  @override
  ProgramTemplate? getProgramTemplateById(String id) => null;

  @override
  ProgramTemplate? getPrebuiltProgramById(String id) => null;

  @override
  void dispose() {}
}

@GenerateMocks([ThemeProvider])
void main() {
  group('SettingsScreen', () {
    late MockThemeProvider mockThemeProvider;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      mockThemeProvider = MockThemeProvider();

      // Default mock responses for theme mode
      when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);
      when(mockThemeProvider.setThemeMode(any)).thenAnswer((_) async {});

      // Default mock responses for color scheme
      when(mockThemeProvider.currentColorScheme).thenReturn(ColorSchemeType.classicBlue);
      when(mockThemeProvider.setColorScheme(any)).thenAnswer((_) async {});
    });

    Widget createTestApp() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(
              value: mockThemeProvider,
            ),
            ChangeNotifierProvider<ExerciseLibraryProvider>.value(
              value: MockExerciseLibraryProvider(),
            ),
            ChangeNotifierProvider<TemplateProvider>.value(
              value: MockTemplateProvider(),
            ),
          ],
          child: const SettingsScreen(),
        ),
      );
    }

    group('UI Rendering', () {
      testWidgets('renders settings screen with compact theme selector', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Theme'), findsOneWidget);

        // Check for theme icon buttons
        expect(find.byIcon(Icons.brightness_auto), findsOneWidget); // System
        expect(find.byIcon(Icons.wb_sunny), findsOneWidget); // Light
        expect(find.byIcon(Icons.nights_stay), findsOneWidget); // Dark
      });

      testWidgets('shows system theme button as selected when current theme is system', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - System button should have selected styling
        final systemButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'System theme',
        );

        expect(systemButton, findsOneWidget);

        final semantics = tester.widget<Semantics>(systemButton);
        expect(semantics.properties.selected, isTrue);
        expect(semantics.properties.label, equals('System theme'));
      });

      testWidgets('shows light theme button as selected when current theme is light', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.light);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Light button should have selected styling
        final lightButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Light theme',
        );

        expect(lightButton, findsOneWidget);

        final semantics = tester.widget<Semantics>(lightButton);
        expect(semantics.properties.selected, isTrue);
        expect(semantics.properties.label, equals('Light theme'));
      });

      testWidgets('shows dark theme button as selected when current theme is dark', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.dark);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Dark button should have selected styling
        final darkButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Dark theme',
        );

        expect(darkButton, findsOneWidget);

        final semantics = tester.widget<Semantics>(darkButton);
        expect(semantics.properties.selected, isTrue);
        expect(semantics.properties.label, equals('Dark theme'));
      });

      testWidgets('theme icon buttons meet minimum size requirements', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Each button should be at least 48x48 dp
        final systemButton = find.ancestor(
          of: find.byIcon(Icons.brightness_auto),
          matching: find.byType(Container),
        ).first;

        final container = tester.widget<Container>(systemButton);
        final decoration = container.decoration as BoxDecoration;

        expect(container.constraints?.minWidth, greaterThanOrEqualTo(48.0));
        expect(container.constraints?.minHeight, greaterThanOrEqualTo(48.0));
      });
    });

    group('Theme Selection', () {
      testWidgets('tapping system button calls setThemeMode with ThemeMode.system', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.light);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.byIcon(Icons.brightness_auto));
        await tester.pump();

        // Assert
        verify(mockThemeProvider.setThemeMode(ThemeMode.system)).called(1);
      });

      testWidgets('tapping light button calls setThemeMode with ThemeMode.light', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.byIcon(Icons.wb_sunny));
        await tester.pump();

        // Assert
        verify(mockThemeProvider.setThemeMode(ThemeMode.light)).called(1);
      });

      testWidgets('tapping dark button calls setThemeMode with ThemeMode.dark', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.byIcon(Icons.nights_stay));
        await tester.pump();

        // Assert
        verify(mockThemeProvider.setThemeMode(ThemeMode.dark)).called(1);
      });

      testWidgets('theme changes immediately when button is tapped', (tester) async {
        // Arrange - Use real ThemeProvider with mock SharedPreferences
        // This ensures proper ChangeNotifier behavior and widget rebuilds
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final realThemeProvider = ThemeProvider(prefs);

        // Set up setThemeMode to update mock state and trigger rebuild
        when(mockThemeProvider.setThemeMode(ThemeMode.dark)).thenAnswer((_) async {
          when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.dark);
          // Mock doesn't actually extend ChangeNotifier, but the real provider does
          // The widget will rebuild after setThemeMode completes
        });

        // Act - Initial render
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ThemeProvider>.value(
                  value: realThemeProvider,
                ),
                ChangeNotifierProvider<ExerciseLibraryProvider>.value(
                  value: MockExerciseLibraryProvider(),
                ),
                ChangeNotifierProvider<TemplateProvider>.value(
                  value: MockTemplateProvider(),
                ),
              ],
              child: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle(); // Wait for initial load

        // Verify initial state (System theme selected by default)
        var systemButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'System theme',
        );
        expect(tester.widget<Semantics>(systemButton).properties.selected, isTrue);

        // Tap dark mode button - this calls setThemeMode which triggers notifyListeners
        await tester.tap(find.byIcon(Icons.nights_stay));
        await tester.pump(); // Trigger state update
        await tester.pump(); // Allow Consumer to rebuild
        await tester.pumpAndSettle(); // Wait for any animations

        // Assert - Dark button should now be selected
        final darkButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Dark theme',
        );
        expect(tester.widget<Semantics>(darkButton).properties.selected, isTrue);
      });
    });

    group('Accessibility', () {
      testWidgets('theme buttons have proper semantic labels', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Check all semantic labels
        final systemButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'System theme',
        );
        expect(tester.widget<Semantics>(systemButton).properties.label, equals('System theme'));

        final lightButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Light theme',
        );
        expect(tester.widget<Semantics>(lightButton).properties.label, equals('Light theme'));

        final darkButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Dark theme',
        );
        expect(tester.widget<Semantics>(darkButton).properties.label, equals('Dark theme'));
      });

      testWidgets('theme buttons announce selected state to screen readers', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.dark);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Dark button should announce selected state
        final darkButton = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Dark theme',
        );

        final semantics = tester.widget<Semantics>(darkButton);
        expect(semantics.properties.selected, isTrue);
        expect(semantics.properties.button, isTrue);
      });
    });

    group('Navigation', () {
      testWidgets('back button pops route', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider<ThemeProvider>.value(
                              value: mockThemeProvider,
                            ),
                            ChangeNotifierProvider<ExerciseLibraryProvider>.value(
                              value: MockExerciseLibraryProvider(),
                            ),
                            ChangeNotifierProvider<TemplateProvider>.value(
                              value: MockTemplateProvider(),
                            ),
                          ],
                          child: const SettingsScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        );

        // Navigate to settings
        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Verify settings screen is shown
        expect(find.text('Settings'), findsOneWidget);

        // Act - tap back button
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Assert - should be back to previous screen
        expect(find.text('Settings'), findsNothing);
        expect(find.text('Open Settings'), findsOneWidget);
      });
    });

    group('Color Scheme UI Rendering', () {
      testWidgets('renders color scheme dropdown with label', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.text('Color Scheme'), findsOneWidget);
        expect(find.byType(DropdownButton<ColorSchemeType>), findsOneWidget);
      });

      testWidgets('shows all 4 color scheme options in dropdown', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Tap to open dropdown
        await tester.tap(find.byType(DropdownButton<ColorSchemeType>));
        await tester.pumpAndSettle();

        // Assert - All 4 options should be visible
        expect(find.text('Classic Blue'), findsWidgets);
        expect(find.text('Energetic Orange'), findsOneWidget);
        expect(find.text('Electric Purple'), findsOneWidget);
        expect(find.text('Crimson Power'), findsOneWidget);
      });

      testWidgets('displays current color scheme as selected', (tester) async {
        // Arrange
        when(mockThemeProvider.currentColorScheme).thenReturn(ColorSchemeType.electricPurple);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Dropdown should show Electric Purple as selected
        final dropdown = find.byType(DropdownButton<ColorSchemeType>);
        expect(dropdown, findsOneWidget);

        // The selected value text should be visible
        expect(find.text('Electric Purple'), findsOneWidget);
      });

      testWidgets('each dropdown item has color preview circle', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Tap to open dropdown
        await tester.tap(find.byType(DropdownButton<ColorSchemeType>));
        await tester.pumpAndSettle();

        // Assert - Find color preview circles (16x16 containers with BoxShape.circle)
        final colorCircles = find.byWidgetPredicate((widget) {
          if (widget is Container) {
            final decoration = widget.decoration;
            if (decoration is BoxDecoration) {
              return decoration.shape == BoxShape.circle &&
                     widget.constraints?.maxWidth == 16 &&
                     widget.constraints?.maxHeight == 16;
            }
          }
          return false;
        });

        // Should have at least 4 color circles (one for each option)
        expect(colorCircles, findsAtLeast(4));
      });
    });

    group('Color Scheme Selection', () {
      testWidgets('selecting energeticOrange calls setColorScheme', (tester) async {
        // Arrange
        when(mockThemeProvider.currentColorScheme).thenReturn(ColorSchemeType.classicBlue);

        // Act
        await tester.pumpWidget(createTestApp());

        // Open dropdown
        await tester.tap(find.byType(DropdownButton<ColorSchemeType>));
        await tester.pumpAndSettle();

        // Select Energetic Orange
        await tester.tap(find.text('Energetic Orange').last);
        await tester.pumpAndSettle();

        // Assert
        verify(mockThemeProvider.setColorScheme(ColorSchemeType.energeticOrange)).called(1);
      });

      testWidgets('selecting electricPurple calls setColorScheme', (tester) async {
        // Arrange
        when(mockThemeProvider.currentColorScheme).thenReturn(ColorSchemeType.classicBlue);

        // Act
        await tester.pumpWidget(createTestApp());

        // Open dropdown
        await tester.tap(find.byType(DropdownButton<ColorSchemeType>));
        await tester.pumpAndSettle();

        // Select Electric Purple
        await tester.tap(find.text('Electric Purple').last);
        await tester.pumpAndSettle();

        // Assert
        verify(mockThemeProvider.setColorScheme(ColorSchemeType.electricPurple)).called(1);
      });

      testWidgets('selecting crimsonPower calls setColorScheme', (tester) async {
        // Arrange
        when(mockThemeProvider.currentColorScheme).thenReturn(ColorSchemeType.classicBlue);

        // Act
        await tester.pumpWidget(createTestApp());

        // Open dropdown
        await tester.tap(find.byType(DropdownButton<ColorSchemeType>));
        await tester.pumpAndSettle();

        // Select Crimson Power
        await tester.tap(find.text('Crimson Power').last);
        await tester.pumpAndSettle();

        // Assert
        verify(mockThemeProvider.setColorScheme(ColorSchemeType.crimsonPower)).called(1);
      });

      testWidgets('color scheme changes immediately when selected', (tester) async {
        // Arrange - Use real ThemeProvider with mock SharedPreferences
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final realThemeProvider = ThemeProvider(prefs);

        // Act - Initial render
        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ThemeProvider>.value(
                  value: realThemeProvider,
                ),
                ChangeNotifierProvider<ExerciseLibraryProvider>.value(
                  value: MockExerciseLibraryProvider(),
                ),
                ChangeNotifierProvider<TemplateProvider>.value(
                  value: MockTemplateProvider(),
                ),
              ],
              child: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial state (Classic Blue by default)
        expect(find.text('Classic Blue'), findsOneWidget);

        // Open dropdown and select Electric Purple
        await tester.tap(find.byType(DropdownButton<ColorSchemeType>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Electric Purple').last);
        await tester.pumpAndSettle();

        // Assert - Dropdown should now show Electric Purple
        expect(find.text('Electric Purple'), findsOneWidget);
        expect(realThemeProvider.currentColorScheme, equals(ColorSchemeType.electricPurple));
      });
    });

    group('Color Scheme Accessibility', () {
      testWidgets('color scheme dropdown has semantic label', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Find semantics wrapper for color scheme selector
        final colorSchemeSemantics = find.byWidgetPredicate(
          (widget) => widget is Semantics &&
                     widget.properties.label == 'Color scheme selector',
        );

        expect(colorSchemeSemantics, findsOneWidget);
      });
    });
  });
}
