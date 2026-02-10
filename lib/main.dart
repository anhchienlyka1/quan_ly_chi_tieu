import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'theme/theme_provider.dart';

/// Global ThemeProvider instance accessible throughout the app.
/// Initialized before runApp to ensure theme is ready.
final ThemeProvider themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme from stored preferences
  await themeProvider.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const QuanLyChiTieuApp());
}
