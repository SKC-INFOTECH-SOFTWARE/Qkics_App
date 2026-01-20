import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSizeFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get fontSizeFactor => _fontSizeFactor;

  ThemeProvider() {
    _loadSettings();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  void setFontSizeFactor(double factor) {
    _fontSizeFactor = factor;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Font Size
    final savedFontSize = prefs.getDouble('font_size_factor');
    if (savedFontSize != null) {
      _fontSizeFactor = savedFontSize;
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
    await prefs.setDouble('font_size_factor', _fontSizeFactor);
  }

  // Helper for toggle if still needed, but preferred to use setThemeMode
  void toggleTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
