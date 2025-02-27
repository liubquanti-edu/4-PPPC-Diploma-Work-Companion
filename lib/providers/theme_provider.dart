import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _useDynamicColors = true;
  ThemeMode _themeMode = ThemeMode.system;
  int _defaultContactTab = 0;
  String? _stopId;
  final SharedPreferences _prefs;
  bool _isInitialized = false;
  List<String> _stopIds = [];

  ThemeProvider(this._prefs) {
    _loadPreferences();
  }

  bool get useDynamicColors => _useDynamicColors;
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  int get defaultContactTab => _defaultContactTab;
  String? get stopId => _stopId;
  List<String> get stopIds => _stopIds;

  Future<void> _loadPreferences() async {
    _useDynamicColors = _prefs.getBool('useDynamicColors') ?? true;
    _themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
    _defaultContactTab = _prefs.getInt('defaultContactTab') ?? 0;
    _stopId = _prefs.getString('stopId');
    _stopIds = _prefs.getStringList('stopIds') ?? [];
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

  Future<void> setStopId(String? id) async {
    if (_stopId != id) {
      _stopId = id;
      if (id != null) {
        await _prefs.setString('stopId', id);
      } else {
        await _prefs.remove('stopId');
      }
      notifyListeners();
    }
  }

  Future<void> addStopId(String id) async {
    if (!_stopIds.contains(id)) {
      _stopIds.add(id);
      await _prefs.setStringList('stopIds', _stopIds);
      notifyListeners();
    }
  }

  Future<void> removeStopId(String id) async {
    if (_stopIds.remove(id)) {
      await _prefs.setStringList('stopIds', _stopIds);
      notifyListeners();
    }
  }
}