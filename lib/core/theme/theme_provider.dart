import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  
  ThemeMode _themeMode = ThemeMode.light;
  late SharedPreferences _prefs;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _initialized;

  // Initialize SharedPreferences and load saved theme
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemeMode();
    _initialized = true;
    notifyListeners();
  }

  // Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    final themeModeString = _prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.light,
      );
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  // Set and save theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }

  // Get current brightness
  Brightness getCurrentBrightness(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    } else if (_themeMode == ThemeMode.dark) {
      return Brightness.dark;
    } else {
      return Brightness.light;
    }
  }
}
