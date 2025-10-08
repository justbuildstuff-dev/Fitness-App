import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _currentThemeMode = ThemeMode.system;

  ThemeProvider(this._prefs) {
    _loadThemeMode();
  }

  ThemeMode get currentThemeMode => _currentThemeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_currentThemeMode == mode) return;

    _currentThemeMode = mode;
    await _prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
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

  Future<void> loadThemeMode() async {
    await _loadThemeMode();
  }
}
