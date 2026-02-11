import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing local key-value storage using SharedPreferences.
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyMonthlyBudget = 'monthly_budget';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyAutoExpenseEnabled = 'auto_expense_enabled';
  static const String _keyAutoExpenseHistory = 'auto_expense_history';

  // Theme Mode
  Future<void> setThemeMode(String mode) async {
    await _preferences?.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _preferences?.getString(_keyThemeMode) ?? 'system';
  }

  // Monthly Budget
  Future<void> setMonthlyBudget(double budget) async {
    await _preferences?.setDouble(_keyMonthlyBudget, budget);
  }

  double getMonthlyBudget() {
    return _preferences?.getDouble(_keyMonthlyBudget) ?? 0.0;
  }

  // First Launch
  Future<void> setFirstLaunch(bool value) async {
    await _preferences?.setBool(_keyFirstLaunch, value);
  }

  bool isFirstLaunch() {
    return _preferences?.getBool(_keyFirstLaunch) ?? true;
  }

  // Auto Expense
  Future<void> setAutoExpenseEnabled(bool value) async {
    await _preferences?.setBool(_keyAutoExpenseEnabled, value);
  }

  bool isAutoExpenseEnabled() {
    return _preferences?.getBool(_keyAutoExpenseEnabled) ?? false;
  }

  Future<void> setAutoExpenseHistory(String jsonHistory) async {
    await _preferences?.setString(_keyAutoExpenseHistory, jsonHistory);
  }

  String getAutoExpenseHistory() {
    return _preferences?.getString(_keyAutoExpenseHistory) ?? '[]';
  }

  // Total Balance
  Future<void> setTotalBalance(double balance) async {
    await _preferences?.setDouble('total_balance', balance);
  }

  double getTotalBalance() {
    return _preferences?.getDouble('total_balance') ?? 0.0;
  }
}
