import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/providers/theme_provider.dart';
import 'package:fittrack/screens/profile/settings_screen.dart';

/// Integration test for theme switching functionality
///
/// This test verifies the complete flow:
/// 1. User opens settings screen
/// 2. User selects a theme
/// 3. UI updates immediately with new theme
/// 4. Theme preference persists across app restarts
void main() {
  group('Theme Switching Integration Test', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('complete theme switch flow - system to light', (tester) async {
      /// Test Purpose: Verify full flow of switching to light theme
      /// This simulates user journey: navigate to settings, change theme, see UI update

      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);

      // Verify initial state is system
      expect(themeProvider.currentThemeMode, equals(ThemeMode.system));

      // Build app
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                themeMode: provider.currentThemeMode,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.light,
                  ),
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ),
                ),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      // Verify settings screen loaded
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);

      // Act - Select light theme
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Assert - Theme mode updated
      expect(themeProvider.currentThemeMode, equals(ThemeMode.light));

      // Assert - Preference persisted
      final savedMode = prefs.getString('theme_mode');
      expect(savedMode, equals('light'));
    });

    testWidgets('complete theme switch flow - system to dark', (tester) async {
      /// Test Purpose: Verify full flow of switching to dark theme

      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                themeMode: provider.currentThemeMode,
                theme: ThemeData(brightness: Brightness.light),
                darkTheme: ThemeData(brightness: Brightness.dark),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      // Act - Select dark theme
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Assert - Theme mode updated
      expect(themeProvider.currentThemeMode, equals(ThemeMode.dark));

      // Assert - Preference persisted
      final savedMode = prefs.getString('theme_mode');
      expect(savedMode, equals('dark'));
    });

    testWidgets('theme switching between all modes works correctly', (tester) async {
      /// Test Purpose: Verify switching between all theme modes

      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                themeMode: provider.currentThemeMode,
                theme: ThemeData(brightness: Brightness.light),
                darkTheme: ThemeData(brightness: Brightness.dark),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      // Act & Assert - Switch to light
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(themeProvider.currentThemeMode, equals(ThemeMode.light));

      // Act & Assert - Switch to dark
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(themeProvider.currentThemeMode, equals(ThemeMode.dark));

      // Act & Assert - Switch to system
      await tester.tap(find.text('System Default'));
      await tester.pumpAndSettle();
      expect(themeProvider.currentThemeMode, equals(ThemeMode.system));
    });

    testWidgets('theme persists across app restart', (tester) async {
      /// Test Purpose: Verify theme preference survives app restart

      // First app session
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      var themeProvider = ThemeProvider(prefs);

      // Set theme to dark
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.currentThemeMode, equals(ThemeMode.dark));

      // Simulate app restart by creating new provider with same prefs
      themeProvider = ThemeProvider(prefs);

      // Assert - Theme should still be dark after "restart"
      expect(themeProvider.currentThemeMode, equals(ThemeMode.dark));
    });

    testWidgets('UI updates immediately when theme changes', (tester) async {
      /// Test Purpose: Verify UI responds immediately to theme changes

      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);
      bool rebuiltWithNewTheme = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              // Track rebuilds
              if (provider.currentThemeMode == ThemeMode.dark) {
                rebuiltWithNewTheme = true;
              }

              return MaterialApp(
                themeMode: provider.currentThemeMode,
                theme: ThemeData(brightness: Brightness.light),
                darkTheme: ThemeData(brightness: Brightness.dark),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      // Verify not yet rebuilt with dark theme
      expect(rebuiltWithNewTheme, isFalse);

      // Act - Change theme
      await tester.tap(find.text('Dark'));
      await tester.pump(); // Single pump to trigger rebuild

      // Assert - UI should have rebuilt immediately
      expect(rebuiltWithNewTheme, isTrue);
    });

    testWidgets('selecting same theme twice does not cause unnecessary updates', (tester) async {
      /// Test Purpose: Verify no unnecessary state updates

      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);
      int rebuildCount = 0;

      await themeProvider.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              rebuildCount++;

              return MaterialApp(
                themeMode: provider.currentThemeMode,
                theme: ThemeData(brightness: Brightness.light),
                darkTheme: ThemeData(brightness: Brightness.dark),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );

      // Initial build
      final initialBuildCount = rebuildCount;

      // Act - Select same theme again
      await tester.tap(find.text('Light'));
      await tester.pump();

      // Assert - Should not rebuild since theme didn't change
      expect(rebuildCount, equals(initialBuildCount));
    });
  });
}
