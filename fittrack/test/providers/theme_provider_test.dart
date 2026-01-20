import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/providers/theme_provider.dart';

import 'theme_provider_test.mocks.dart';

/// Unit tests for ThemeProvider
///
/// These tests verify that the ThemeProvider correctly:
/// - Initializes with default ThemeMode.system
/// - Persists theme mode to SharedPreferences
/// - Loads saved theme mode from SharedPreferences
/// - Notifies listeners on theme changes
/// - Manages color scheme selection and persistence
/// - Returns correct seed color for each color scheme
///
/// Tests use mocked SharedPreferences to ensure isolation
@GenerateMocks([SharedPreferences])
void main() {
  group('ThemeProvider Tests', () {
    late MockSharedPreferences mockPrefs;
    late ThemeProvider themeProvider;

    setUp(() {
      // Set up clean test environment for each test
      mockPrefs = MockSharedPreferences();
      // Mock color_scheme key - required because constructor calls _loadColorScheme()
      when(mockPrefs.getString('color_scheme')).thenReturn(null);
    });

    group('Initialization', () {
      test('initializes with ThemeMode.system when no saved preference', () {
        /// Test Purpose: Verify default theme mode when no preference is saved
        /// This is the first-time user experience

        // Mock no saved preference
        when(mockPrefs.getString('theme_mode')).thenReturn(null);

        // Create provider
        themeProvider = ThemeProvider(mockPrefs);

        // Verify default state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.system),
          reason: 'Should default to ThemeMode.system when no preference saved');
      });

      test('initializes with saved light mode preference', () {
        /// Test Purpose: Verify loading of saved light mode preference

        // Mock saved light mode
        when(mockPrefs.getString('theme_mode')).thenReturn('light');

        // Create provider
        themeProvider = ThemeProvider(mockPrefs);

        // Verify loaded state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.light),
          reason: 'Should load saved light mode preference');
      });

      test('initializes with saved dark mode preference', () {
        /// Test Purpose: Verify loading of saved dark mode preference

        // Mock saved dark mode
        when(mockPrefs.getString('theme_mode')).thenReturn('dark');

        // Create provider
        themeProvider = ThemeProvider(mockPrefs);

        // Verify loaded state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.dark),
          reason: 'Should load saved dark mode preference');
      });

      test('initializes with saved system mode preference', () {
        /// Test Purpose: Verify loading of saved system mode preference

        // Mock saved system mode
        when(mockPrefs.getString('theme_mode')).thenReturn('system');

        // Create provider
        themeProvider = ThemeProvider(mockPrefs);

        // Verify loaded state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.system),
          reason: 'Should load saved system mode preference');
      });

      test('defaults to system mode for invalid saved value', () {
        /// Test Purpose: Verify fallback to system mode for invalid values

        // Mock invalid saved value
        when(mockPrefs.getString('theme_mode')).thenReturn('invalid');

        // Create provider
        themeProvider = ThemeProvider(mockPrefs);

        // Verify default state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.system),
          reason: 'Should default to system mode for invalid saved values');
      });
    });

    group('setThemeMode', () {
      setUp(() {
        // Mock no saved preference for clean state
        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        themeProvider = ThemeProvider(mockPrefs);
      });

      test('sets theme mode to light and persists', () async {
        /// Test Purpose: Verify setting light mode updates state and persists

        // Execute
        await themeProvider.setThemeMode(ThemeMode.light);

        // Verify state updated
        expect(themeProvider.currentThemeMode, equals(ThemeMode.light),
          reason: 'Should update current theme mode to light');

        // Verify persistence
        verify(mockPrefs.setString('theme_mode', 'light')).called(1);
      });

      test('sets theme mode to dark and persists', () async {
        /// Test Purpose: Verify setting dark mode updates state and persists

        // Execute
        await themeProvider.setThemeMode(ThemeMode.dark);

        // Verify state updated
        expect(themeProvider.currentThemeMode, equals(ThemeMode.dark),
          reason: 'Should update current theme mode to dark');

        // Verify persistence
        verify(mockPrefs.setString('theme_mode', 'dark')).called(1);
      });

      test('sets theme mode to system and persists', () async {
        /// Test Purpose: Verify setting system mode updates state and persists

        // First set to a different mode so we can test changing to system
        await themeProvider.setThemeMode(ThemeMode.dark);

        // Reset mock call count to isolate this test
        clearInteractions(mockPrefs);

        // Execute - change from dark to system
        await themeProvider.setThemeMode(ThemeMode.system);

        // Verify state updated
        expect(themeProvider.currentThemeMode, equals(ThemeMode.system),
          reason: 'Should update current theme mode to system');

        // Verify persistence
        verify(mockPrefs.setString('theme_mode', 'system')).called(1);
      });

      test('does not persist if theme mode is already set', () async {
        /// Test Purpose: Verify no unnecessary persistence calls

        // Set initial mode
        await themeProvider.setThemeMode(ThemeMode.light);

        // Reset mock call count
        clearInteractions(mockPrefs);

        // Try to set same mode again
        await themeProvider.setThemeMode(ThemeMode.light);

        // Verify no persistence call
        verifyNever(mockPrefs.setString(any, any));
      });

      test('notifies listeners when theme mode changes', () async {
        /// Test Purpose: Verify listeners are notified on theme change

        bool listenerCalled = false;
        themeProvider.addListener(() {
          listenerCalled = true;
        });

        // Execute
        await themeProvider.setThemeMode(ThemeMode.dark);

        // Verify listener was called
        expect(listenerCalled, isTrue,
          reason: 'Should notify listeners when theme mode changes');
      });

      test('does not notify listeners when setting same theme mode', () async {
        /// Test Purpose: Verify listeners not notified unnecessarily

        // Set initial mode
        await themeProvider.setThemeMode(ThemeMode.light);

        int listenerCallCount = 0;
        themeProvider.addListener(() {
          listenerCallCount++;
        });

        // Try to set same mode again
        await themeProvider.setThemeMode(ThemeMode.light);

        // Verify listener was not called
        expect(listenerCallCount, equals(0),
          reason: 'Should not notify listeners when theme mode unchanged');
      });
    });

    group('loadThemeMode', () {
      test('loads and applies saved theme mode', () {
        /// Test Purpose: Verify explicit load of theme mode

        // Mock saved dark mode
        when(mockPrefs.getString('theme_mode')).thenReturn('dark');

        themeProvider = ThemeProvider(mockPrefs);

        // Execute explicit load
        themeProvider.loadThemeMode();

        // Verify loaded state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.dark),
          reason: 'Should load and apply saved theme mode');
      });

      test('notifies listeners after loading theme mode', () {
        /// Test Purpose: Verify listeners notified after load

        when(mockPrefs.getString('theme_mode')).thenReturn('light');

        themeProvider = ThemeProvider(mockPrefs);

        bool listenerCalled = false;
        themeProvider.addListener(() {
          listenerCalled = true;
        });

        // Execute
        themeProvider.loadThemeMode();

        // Verify listener was called
        expect(listenerCalled, isTrue,
          reason: 'Should notify listeners after loading theme mode');
      });
    });

    group('Color Scheme Initialization', () {
      test('initializes with classicBlue when no saved preference', () {
        /// Test Purpose: Verify default color scheme when no preference saved

        // Mock no saved preferences
        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn(null);

        themeProvider = ThemeProvider(mockPrefs);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.classicBlue),
          reason: 'Should default to classicBlue when no preference saved');
      });

      test('initializes with saved energeticOrange preference', () {
        /// Test Purpose: Verify loading of saved energeticOrange preference

        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn('energeticOrange');

        themeProvider = ThemeProvider(mockPrefs);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.energeticOrange),
          reason: 'Should load saved energeticOrange preference');
      });

      test('initializes with saved electricPurple preference', () {
        /// Test Purpose: Verify loading of saved electricPurple preference

        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn('electricPurple');

        themeProvider = ThemeProvider(mockPrefs);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.electricPurple),
          reason: 'Should load saved electricPurple preference');
      });

      test('initializes with saved crimsonPower preference', () {
        /// Test Purpose: Verify loading of saved crimsonPower preference

        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn('crimsonPower');

        themeProvider = ThemeProvider(mockPrefs);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.crimsonPower),
          reason: 'Should load saved crimsonPower preference');
      });

      test('defaults to classicBlue for invalid saved value', () {
        /// Test Purpose: Verify fallback to classicBlue for invalid values

        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn('invalidScheme');

        themeProvider = ThemeProvider(mockPrefs);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.classicBlue),
          reason: 'Should default to classicBlue for invalid saved values');
      });
    });

    group('setColorScheme', () {
      setUp(() {
        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        themeProvider = ThemeProvider(mockPrefs);
      });

      test('sets color scheme to energeticOrange and persists', () async {
        /// Test Purpose: Verify setting energeticOrange updates state and persists

        await themeProvider.setColorScheme(ColorSchemeType.energeticOrange);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.energeticOrange),
          reason: 'Should update current color scheme to energeticOrange');

        verify(mockPrefs.setString('color_scheme', 'energeticOrange')).called(1);
      });

      test('sets color scheme to electricPurple and persists', () async {
        /// Test Purpose: Verify setting electricPurple updates state and persists

        await themeProvider.setColorScheme(ColorSchemeType.electricPurple);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.electricPurple),
          reason: 'Should update current color scheme to electricPurple');

        verify(mockPrefs.setString('color_scheme', 'electricPurple')).called(1);
      });

      test('sets color scheme to crimsonPower and persists', () async {
        /// Test Purpose: Verify setting crimsonPower updates state and persists

        await themeProvider.setColorScheme(ColorSchemeType.crimsonPower);

        expect(themeProvider.currentColorScheme, equals(ColorSchemeType.crimsonPower),
          reason: 'Should update current color scheme to crimsonPower');

        verify(mockPrefs.setString('color_scheme', 'crimsonPower')).called(1);
      });

      test('does not persist if color scheme is already set', () async {
        /// Test Purpose: Verify no unnecessary persistence calls

        // Color scheme starts as classicBlue by default
        clearInteractions(mockPrefs);

        await themeProvider.setColorScheme(ColorSchemeType.classicBlue);

        verifyNever(mockPrefs.setString(any, any));
      });

      test('notifies listeners when color scheme changes', () async {
        /// Test Purpose: Verify listeners are notified on color scheme change

        bool listenerCalled = false;
        themeProvider.addListener(() {
          listenerCalled = true;
        });

        await themeProvider.setColorScheme(ColorSchemeType.electricPurple);

        expect(listenerCalled, isTrue,
          reason: 'Should notify listeners when color scheme changes');
      });

      test('does not notify listeners when setting same color scheme', () async {
        /// Test Purpose: Verify listeners not notified unnecessarily

        int listenerCallCount = 0;
        themeProvider.addListener(() {
          listenerCallCount++;
        });

        // Try to set same scheme (classicBlue is default)
        await themeProvider.setColorScheme(ColorSchemeType.classicBlue);

        expect(listenerCallCount, equals(0),
          reason: 'Should not notify listeners when color scheme unchanged');
      });
    });

    group('seedColor', () {
      setUp(() {
        when(mockPrefs.getString('theme_mode')).thenReturn(null);
        when(mockPrefs.getString('color_scheme')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        themeProvider = ThemeProvider(mockPrefs);
      });

      test('returns correct color for classicBlue', () {
        /// Test Purpose: Verify seedColor returns correct hex for classicBlue

        expect(themeProvider.seedColor, equals(const Color(0xFF2196F3)),
          reason: 'classicBlue should return #2196F3');
      });

      test('returns correct color for energeticOrange', () async {
        /// Test Purpose: Verify seedColor returns correct hex for energeticOrange

        await themeProvider.setColorScheme(ColorSchemeType.energeticOrange);

        expect(themeProvider.seedColor, equals(const Color(0xFFFF6B35)),
          reason: 'energeticOrange should return #FF6B35');
      });

      test('returns correct color for electricPurple', () async {
        /// Test Purpose: Verify seedColor returns correct hex for electricPurple

        await themeProvider.setColorScheme(ColorSchemeType.electricPurple);

        expect(themeProvider.seedColor, equals(const Color(0xFF7C3AED)),
          reason: 'electricPurple should return #7C3AED');
      });

      test('returns correct color for crimsonPower', () async {
        /// Test Purpose: Verify seedColor returns correct hex for crimsonPower

        await themeProvider.setColorScheme(ColorSchemeType.crimsonPower);

        expect(themeProvider.seedColor, equals(const Color(0xFFDC143C)),
          reason: 'crimsonPower should return #DC143C');
      });
    });
  });
}
