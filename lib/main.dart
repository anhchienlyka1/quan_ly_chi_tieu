import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/constants/env_config.dart';
import 'data/providers/expense_provider.dart';
import 'data/providers/gold_provider.dart';
import 'theme/theme_provider.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_check_task.dart';
import 'package:workmanager/workmanager.dart';

/// Global ThemeProvider instance accessible throughout the app.
/// Initialized before runApp to ensure theme is ready.
final ThemeProvider themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await EnvConfig.load();

  // Initialize theme from stored preferences
  await themeProvider.init();

  // Initialize notifications & background tasks
  final notificationService = NotificationService();
  await notificationService.initialize();

  Workmanager().initialize(callbackDispatcher);
  notificationService.scheduleDailyCheck();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider()..loadExpenses(),
        ),
        ChangeNotifierProvider(create: (_) => GoldProvider()),
      ],
      child: const QuanLyChiTieuApp(),
    ),
  );
}
