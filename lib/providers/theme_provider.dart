import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _useDynamicColors = true;
  ThemeMode _themeMode = ThemeMode.system;
  int _defaultContactTab = 0;
  final SharedPreferences _prefs;
  bool _isInitialized = false;

  ThemeProvider(this._prefs) {
    _loadPreferences();
  }

  bool get useDynamicColors => _useDynamicColors;
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  int get defaultContactTab => _defaultContactTab;

  Future<void> _loadPreferences() async {
    _useDynamicColors = _prefs.getBool('useDynamicColors') ?? true;
    _themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
    _defaultContactTab = _prefs.getInt('defaultContactTab') ?? 0;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setDynamicColors(bool value) async {
    if (_useDynamicColors != value) {
      _useDynamicColors = value;
      await _prefs.setBool('useDynamicColors', value);
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setInt('themeMode', mode.index);
      notifyListeners();
    }
  }

  Future<void> setDefaultContactTab(int index) async {
    if (_defaultContactTab != index) {
      _defaultContactTab = index;
      await _prefs.setInt('defaultContactTab', index);
      notifyListeners();
    }
  }
}