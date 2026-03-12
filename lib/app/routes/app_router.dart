import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/expenses/screens/expense_list_screen.dart';
import '../../features/expenses/screens/add_expense_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/scan_receipt/screens/scan_receipt_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/settings/screens/auto_expense_screen.dart';
import '../../features/settings/screens/export_data_screen.dart';
import '../../features/home/screens/ai_chat_history_screen.dart';
import '../../features/gold/screens/gold_dashboard_screen.dart';
import '../../features/gold/screens/add_gold_screen.dart';
import '../../features/gold/screens/gold_detail_screen.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/gold_asset_model.dart';

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
  static const String scanReceipt = RouteNames.scanReceipt;
  static const String budget = RouteNames.budget;
  static const String autoExpense = RouteNames.autoExpense;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _buildRoute(const HomeScreen(), settings);

      case RouteNames.expenseList:
        return _buildRoute(const ExpenseListScreen(), settings);

      case RouteNames.addExpense:
        final args = settings.arguments;
        final expense = args is ExpenseModel ? args : null;
        final initialType = args is TransactionType ? args : null;
        return _buildRoute(
          AddExpenseScreen(expense: expense, initialType: initialType),
          settings,
        );

      case RouteNames.statistics:
        return _buildRoute(const StatisticsScreen(), settings);

      case RouteNames.settings:
        return _buildRoute(const SettingsScreen(), settings);

      case RouteNames.scanReceipt:
        return _buildRoute(const ScanReceiptScreen(), settings);

      case RouteNames.budget:
        return _buildRoute(const BudgetScreen(), settings);

      case RouteNames.aiHistory:
        return _buildRoute(const AiChatHistoryScreen(), settings);

      case RouteNames.autoExpense:
        return _buildRoute(const AutoExpenseScreen(), settings);

      case RouteNames.exportData:
        return _buildRoute(const ExportDataScreen(), settings);

      // ── Gold Feature Routes ─────────────────────────────────
      case RouteNames.goldDashboard:
        return _buildRoute(const GoldDashboardScreen(), settings);

      case RouteNames.goldAdd:
        final arg = settings.arguments;
        final existingAsset = arg is GoldAssetModel ? arg : null;
        return _buildRoute(
          AddGoldScreen(existingAsset: existingAsset),
          settings,
        );

      case RouteNames.goldDetail:
        final asset = settings.arguments as GoldAssetModel;
        return _buildRoute(GoldDetailScreen(asset: asset), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('Không tìm thấy trang: ${settings.name}')),
          ),
          settings,
        );
    }
  }

  /// Helper to create consistent page transitions
  static Route<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (context) => page, settings: settings);
  }
}
