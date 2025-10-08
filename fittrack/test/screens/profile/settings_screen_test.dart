import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/profile/settings_screen.dart';
import 'package:fittrack/providers/theme_provider.dart';

import 'settings_screen_test.mocks.dart';

@GenerateMocks([ThemeProvider])
void main() {
  group('SettingsScreen', () {
    late MockThemeProvider mockThemeProvider;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      mockThemeProvider = MockThemeProvider();

      // Default mock responses
      when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);
      when(mockThemeProvider.setThemeMode(any)).thenAnswer((_) async {});
    });

    Widget createTestApp() {
      return MaterialApp(
        home: ChangeNotifierProvider<ThemeProvider>.value(
          value: mockThemeProvider,
          child: const SettingsScreen(),
        ),
      );
    }

    group('UI Rendering', () {
      testWidgets('renders settings screen with all theme options', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Always use light theme'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('Always use dark theme'), findsOneWidget);
        expect(find.text('System Default'), findsOneWidget);
        expect(find.text('Use system theme setting'), findsOneWidget);
      });

      testWidgets('shows light mode selected when current theme is light', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.light);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Light option should be selected
        final lightRadio = tester.widget<RadioListTile<ThemeMode>>(
          find.byWidgetPredicate((widget) =>
            widget is RadioListTile<ThemeMode> && widget.value == ThemeMode.light),
        );
        expect(lightRadio.groupValue, equals(ThemeMode.light));
      });

      testWidgets('shows dark mode selected when current theme is dark', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.dark);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Dark option should be selected
        final darkRadio = tester.widget<RadioListTile<ThemeMode>>(
          find.byWidgetPredicate((widget) =>
            widget is RadioListTile<ThemeMode> && widget.value == ThemeMode.dark),
        );
        expect(darkRadio.groupValue, equals(ThemeMode.dark));
      });

      testWidgets('shows system mode selected when current theme is system', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - System option should be selected
        final systemRadio = tester.widget<RadioListTile<ThemeMode>>(
          find.byWidgetPredicate((widget) =>
            widget is RadioListTile<ThemeMode> && widget.value == ThemeMode.system),
        );
        expect(systemRadio.groupValue, equals(ThemeMode.system));
      });
    });

    group('Theme Selection', () {
      testWidgets('selecting light theme calls setThemeMode with ThemeMode.light', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.text('Light'));
        await tester.pump();

        // Assert
        verify(mockThemeProvider.setThemeMode(ThemeMode.light)).called(1);
      });

      testWidgets('selecting dark theme calls setThemeMode with ThemeMode.dark', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.text('Dark'));
        await tester.pump();

        // Assert
        verify(mockThemeProvider.setThemeMode(ThemeMode.dark)).called(1);
      });

      testWidgets('selecting system theme calls setThemeMode with ThemeMode.system', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.light);

        // Act
        await tester.pumpWidget(createTestApp());
        await tester.tap(find.text('System Default'));
        await tester.pump();

        // Assert
        verify(mockThemeProvider.setThemeMode(ThemeMode.system)).called(1);
      });
    });

    group('Navigation', () {
      testWidgets('has back button in app bar', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert
        expect(find.byType(BackButton), findsOneWidget);
      });

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
                        builder: (_) => ChangeNotifierProvider<ThemeProvider>.value(
                          value: mockThemeProvider,
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
  });
}
