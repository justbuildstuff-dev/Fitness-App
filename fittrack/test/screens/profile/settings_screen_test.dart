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
        final systemButton = find.ancestor(
          of: find.byIcon(Icons.brightness_auto),
          matching: find.byType(Semantics),
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
        final lightButton = find.ancestor(
          of: find.byIcon(Icons.wb_sunny),
          matching: find.byType(Semantics),
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
        final darkButton = find.ancestor(
          of: find.byIcon(Icons.nights_stay),
          matching: find.byType(Semantics),
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
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.system);

        // Act - Initial render
        await tester.pumpWidget(createTestApp());

        // Verify initial state
        var systemButton = find.ancestor(
          of: find.byIcon(Icons.brightness_auto),
          matching: find.byType(Semantics),
        );
        expect(tester.widget<Semantics>(systemButton).properties.selected, isTrue);

        // Change to dark mode
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.dark);
        await tester.tap(find.byIcon(Icons.nights_stay));
        await tester.pump();

        // Assert - Dark button should now be selected
        final darkButton = find.ancestor(
          of: find.byIcon(Icons.nights_stay),
          matching: find.byType(Semantics),
        );
        expect(tester.widget<Semantics>(darkButton).properties.selected, isTrue);
      });
    });

    group('Accessibility', () {
      testWidgets('theme buttons have proper semantic labels', (tester) async {
        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Check all semantic labels
        final systemButton = find.ancestor(
          of: find.byIcon(Icons.brightness_auto),
          matching: find.byType(Semantics),
        );
        expect(tester.widget<Semantics>(systemButton).properties.label, equals('System theme'));

        final lightButton = find.ancestor(
          of: find.byIcon(Icons.wb_sunny),
          matching: find.byType(Semantics),
        );
        expect(tester.widget<Semantics>(lightButton).properties.label, equals('Light theme'));

        final darkButton = find.ancestor(
          of: find.byIcon(Icons.nights_stay),
          matching: find.byType(Semantics),
        );
        expect(tester.widget<Semantics>(darkButton).properties.label, equals('Dark theme'));
      });

      testWidgets('theme buttons announce selected state to screen readers', (tester) async {
        // Arrange
        when(mockThemeProvider.currentThemeMode).thenReturn(ThemeMode.dark);

        // Act
        await tester.pumpWidget(createTestApp());

        // Assert - Dark button should announce selected state
        final darkButton = find.ancestor(
          of: find.byIcon(Icons.nights_stay),
          matching: find.byType(Semantics),
        );

        final semantics = tester.widget<Semantics>(darkButton);
        expect(semantics.properties.selected, isTrue);
        expect(semantics.properties.button, isTrue);
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
