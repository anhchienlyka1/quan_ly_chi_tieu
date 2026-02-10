import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'routes/app_router.dart';

class QuanLyChiTieuApp extends StatelessWidget {
  const QuanLyChiTieuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Chi Tiêu',
      debugShowCheckedModeBanner: false,
      theme: ProTheme.lightTheme,
      darkTheme: ProTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
