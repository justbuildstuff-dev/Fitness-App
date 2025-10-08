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

        // Execute
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
      test('loads and applies saved theme mode', () async {
        /// Test Purpose: Verify explicit load of theme mode

        // Mock saved dark mode
        when(mockPrefs.getString('theme_mode')).thenReturn('dark');

        themeProvider = ThemeProvider(mockPrefs);

        // Execute explicit load
        await themeProvider.loadThemeMode();

        // Verify loaded state
        expect(themeProvider.currentThemeMode, equals(ThemeMode.dark),
          reason: 'Should load and apply saved theme mode');
      });

      test('notifies listeners after loading theme mode', () async {
        /// Test Purpose: Verify listeners notified after load

        when(mockPrefs.getString('theme_mode')).thenReturn('light');

        themeProvider = ThemeProvider(mockPrefs);

        bool listenerCalled = false;
        themeProvider.addListener(() {
          listenerCalled = true;
        });

        // Execute
        await themeProvider.loadThemeMode();

        // Verify listener was called
        expect(listenerCalled, isTrue,
          reason: 'Should notify listeners after loading theme mode');
      });
    });
  });
}
