import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'routes/app_router.dart';

class QuanLyChiTieuApp extends StatefulWidget {
  const QuanLyChiTieuApp({super.key});

  @override
  State<QuanLyChiTieuApp> createState() => _QuanLyChiTieuAppState();
}

class _QuanLyChiTieuAppState extends State<QuanLyChiTieuApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
    // Update system UI overlay style based on theme
    _updateSystemUI();
  }

  void _updateSystemUI() {
    final isDark = themeProvider.isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark 
            ? const Color(0xFF121218)
            : const Color(0xFFF8F9FE),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Chi Tiêu',
      debugShowCheckedModeBanner: false,
      theme: ProTheme.lightTheme,
      darkTheme: ProTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
