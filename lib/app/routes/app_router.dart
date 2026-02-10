import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/expenses/screens/expense_list_screen.dart';
import '../../features/expenses/screens/add_expense_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Centralized route management using onGenerateRoute.
/// All navigation logic should be handled here.
class AppRouter {
  AppRouter._();

  // Re-export route names for convenience
  static const String home = RouteNames.home;
  static const String addExpense = RouteNames.addExpense;
  static const String expenseList = RouteNames.expenseList;
  static const String statistics = RouteNames.statistics;
  static const String settings = RouteNames.settings;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _buildRoute(const HomeScreen(), settings);

      case RouteNames.expenseList:
        return _buildRoute(const ExpenseListScreen(), settings);

      case RouteNames.addExpense:
        return _buildRoute(const AddExpenseScreen(), settings);

      case RouteNames.statistics:
        return _buildRoute(const StatisticsScreen(), settings);

      case RouteNames.settings:
        return _buildRoute(const SettingsScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Không tìm thấy trang: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  /// Helper to create consistent page transitions
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
