import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Color scheme options for the app
enum ColorSchemeType {
  classicBlue,
  energeticOrange,
  electricPurple,
  crimsonPower,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';

  final SharedPreferences _prefs;
  ThemeMode _currentThemeMode = ThemeMode.system;
  ColorSchemeType _currentColorScheme = ColorSchemeType.classicBlue;

  ThemeProvider(this._prefs) {
    _loadThemeMode();
    _loadColorScheme();
  }

  ThemeMode get currentThemeMode => _currentThemeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_currentThemeMode == mode) return;

    _currentThemeMode = mode;
    await _prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  void _loadThemeMode() {
    final String? savedMode = _prefs.getString(_themeModeKey);

    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          _currentThemeMode = ThemeMode.light;
          break;
        case 'dark':
          _currentThemeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _currentThemeMode = ThemeMode.system;
          break;
      }
    } else {
      _currentThemeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  void loadThemeMode() {
    _loadThemeMode();
  }

  // Color scheme management

  ColorSchemeType get currentColorScheme => _currentColorScheme;

  Future<void> setColorScheme(ColorSchemeType scheme) async {
    if (_currentColorScheme == scheme) return;

    _currentColorScheme = scheme;
    await _prefs.setString(_colorSchemeKey, scheme.name);
    notifyListeners();
  }

  void _loadColorScheme() {
    final String? savedScheme = _prefs.getString(_colorSchemeKey);

    if (savedScheme != null) {
      _currentColorScheme = ColorSchemeType.values.firstWhere(
        (s) => s.name == savedScheme,
        orElse: () => ColorSchemeType.classicBlue,
      );
    } else {
      _currentColorScheme = ColorSchemeType.classicBlue;
    }
  }

  /// Returns the seed color for the current color scheme
  Color get seedColor {
    switch (_currentColorScheme) {
      case ColorSchemeType.classicBlue:
        return const Color(0xFF2196F3);
      case ColorSchemeType.energeticOrange:
        return const Color(0xFFFF6B35);
      case ColorSchemeType.electricPurple:
        return const Color(0xFF7C3AED);
      case ColorSchemeType.crimsonPower:
        return const Color(0xFFDC143C);
    }
  }
}
