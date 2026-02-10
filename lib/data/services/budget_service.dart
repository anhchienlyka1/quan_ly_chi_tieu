import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';

/// Service for managing monthly budget data using SharedPreferences.
class BudgetService {
  static const String _budgetKeyPrefix = 'budget_';
  static const String _defaultBudgetKey = 'default_budget';

  /// Save budget for a specific month
  Future<void> saveBudget(BudgetModel budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_budgetKeyPrefix${budget.monthKey}',
      budget.toJson(),
    );
    // Also save as default for future months
    await prefs.setString(_defaultBudgetKey, budget.toJson());
  }

  /// Get budget for a specific month
  /// If no budget is set for that month, returns the default budget
  Future<BudgetModel> getBudget(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    // Try to get budget for this specific month
    final monthBudgetJson = prefs.getString('$_budgetKeyPrefix$monthKey');
    if (monthBudgetJson != null) {
      return BudgetModel.fromJson(monthBudgetJson);
    }

    // Fall back to default budget
    final defaultJson = prefs.getString(_defaultBudgetKey);
    if (defaultJson != null) {
      final defaultBudget = BudgetModel.fromJson(defaultJson);
      // Return with current month key
      return defaultBudget.copyWith(monthKey: monthKey);
    }

    // No budget set at all
    return BudgetModel(totalBudget: 0, monthKey: monthKey);
  }

  /// Get budget for current month
  Future<BudgetModel> getCurrentMonthBudget() async {
    final now = DateTime.now();
    return getBudget(now.year, now.month);
  }

  /// Calculate spending progress for current month
  Future<BudgetProgress> calculateProgress({
    required List<ExpenseModel> expenses,
  }) async {
    final budget = await getCurrentMonthBudget();
    final now = DateTime.now();

    // Filter only this month's expenses (not income)
    final monthExpenses = expenses
        .where((e) =>
            e.type == TransactionType.expense &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .toList();

    // Total spent
    final totalSpent =
        monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    // Per-category spending
    final categorySpending = <ExpenseCategory, double>{};
    for (final expense in monthExpenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Per-category progress
    final categoryProgress = <ExpenseCategory, CategoryBudgetProgress>{};
    for (final entry in budget.categoryBudgets.entries) {
      final spent = categorySpending[entry.key] ?? 0;
      categoryProgress[entry.key] = CategoryBudgetProgress(
        category: entry.key,
        budget: entry.value,
        spent: spent,
      );
    }

    return BudgetProgress(
      budget: budget,
      totalSpent: totalSpent,
      categoryProgress: categoryProgress,
      daysInMonth: DateTime(now.year, now.month + 1, 0).day,
      currentDay: now.day,
    );
  }

  /// Delete budget for a specific month
  Future<void> deleteBudget(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    await prefs.remove('$_budgetKeyPrefix$monthKey');
  }

  /// Clear all budget data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_budgetKeyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    await prefs.remove(_defaultBudgetKey);
  }
}

/// Overall budget progress for the month
class BudgetProgress {
  final BudgetModel budget;
  final double totalSpent;
  final Map<ExpenseCategory, CategoryBudgetProgress> categoryProgress;
  final int daysInMonth;
  final int currentDay;

  const BudgetProgress({
    required this.budget,
    required this.totalSpent,
    required this.categoryProgress,
    required this.daysInMonth,
    required this.currentDay,
  });

  /// Overall percentage spent (0.0 to 1.0+)
  double get percentSpent =>
      budget.totalBudget > 0 ? totalSpent / budget.totalBudget : 0;

  /// Remaining budget amount
  double get remaining => budget.totalBudget - totalSpent;

  /// Whether over budget
  bool get isOverBudget => totalSpent > budget.totalBudget && budget.isSet;

  /// Whether close to budget (>80%)
  bool get isNearBudget =>
      percentSpent >= 0.8 && percentSpent <= 1.0 && budget.isSet;

  /// Daily budget suggestion based on remaining days
  double get dailyBudgetRemaining {
    final remainingDays = daysInMonth - currentDay + 1;
    if (remainingDays <= 0 || remaining <= 0) return 0;
    return remaining / remainingDays;
  }

  /// Percentage of month elapsed
  double get monthProgress => currentDay / daysInMonth;
}

/// Budget progress for a single category
class CategoryBudgetProgress {
  final ExpenseCategory category;
  final double budget;
  final double spent;

  const CategoryBudgetProgress({
    required this.category,
    required this.budget,
    required this.spent,
  });

  double get percentSpent => budget > 0 ? spent / budget : 0;
  double get remaining => budget - spent;
  bool get isOverBudget => spent > budget;
  bool get isNearBudget => percentSpent >= 0.8 && percentSpent <= 1.0;
}
