import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lb }

class WeightUnitProvider extends ChangeNotifier {
  static const String _key = 'weight_unit';

  final SharedPreferences _prefs;
  WeightUnit _unit = WeightUnit.kg;

  WeightUnitProvider(this._prefs) {
    _load();
  }

  WeightUnit get unit => _unit;

  /// Short label for display: 'kg' or 'lb'
  String get label => _unit == WeightUnit.kg ? 'kg' : 'lb';

  Future<void> setUnit(WeightUnit unit) async {
    if (_unit == unit) return;
    _unit = unit;
    await _prefs.setString(_key, unit.name);
    notifyListeners();
  }

  void _load() {
    final saved = _prefs.getString(_key);
    _unit = saved == 'lb' ? WeightUnit.lb : WeightUnit.kg;
    notifyListeners();
  }
}
