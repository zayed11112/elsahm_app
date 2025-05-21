import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // --- Constants ---
  static const String _themePrefKey = 'themeMode';

  // --- State ---
  ThemeMode _themeMode = ThemeMode.light; // Default theme is light mode

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // --- Initialization ---
  ThemeProvider() {
    _loadPreferences(); // Cargar solo theme
  }

  // --- Preference Management ---
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final savedTheme = prefs.getString(_themePrefKey);
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light; // Default is light mode
    }

    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save Theme
    String themeString;
    switch (_themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await prefs.setString(_themePrefKey, themeString);
  }

  // --- Theme Methods ---
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    _savePreferences();
    notifyListeners();
  }

  // Add a smoother transition with a slight delay for animations
  Future<void> toggleThemeWithAnimation() async {
    toggleTheme(); // First toggle immediately for the UI to respond
    await _savePreferences(); // Save preferences in background
  }

  void setTheme(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _savePreferences();
      notifyListeners();
    }
  }
}
