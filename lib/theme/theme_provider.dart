import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeProvider manages the app's theme mode (light/dark/system).
/// It persists the user's choice in SharedPreferences and notifies listeners
/// when the theme changes, so the entire widget tree rebuilds.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Whether dark mode is currently active (accounting for system preference)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Initialize theme from stored preferences.
  /// Must be called before runApp or as early as possible.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_themeKey);
    switch (storedMode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Set the theme mode and persist.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_themeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_themeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_themeKey, 'system');
        break;
    }
  }

  /// Convenience toggle between light and dark mode.
  /// If currently system mode, detect current brightness and toggle to opposite.
  Future<void> toggleDarkMode() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
