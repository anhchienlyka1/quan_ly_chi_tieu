import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

class QuanLyChiTieuApp extends StatelessWidget {
  const QuanLyChiTieuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chi Tiêu Gia Đình',
      debugShowCheckedModeBanner: false,
      theme: ProTheme.lightTheme,
      darkTheme: ProTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: RouteNames.intro,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
