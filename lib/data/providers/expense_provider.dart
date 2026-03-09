import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../services/budget_service.dart';
import '../models/goal_model.dart';
import '../models/smart_suggestion_model.dart';
import '../services/local_storage_service.dart';
import '../services/smart_suggestion_service.dart';

/// Centralized state for all expense/income data.
/// This is the **single source of truth** — every screen should read from here.
///
/// Usage:
///   final provider = context.read<ExpenseProvider>();   // one-shot read
///   final provider = context.watch<ExpenseProvider>();  // auto-rebuild
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final BudgetService _budgetService = BudgetService();
  final LocalStorageService _localStorageService =
      LocalStorageService(); // Added LocalStorageService

  // ───────── State ─────────
  List<ExpenseModel> _expenses = [];
  BudgetProgress? _budgetProgress;
  FinancialGoal? _goal;
  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  // ───────── Getters ─────────
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  BudgetProgress? get budgetProgress => _budgetProgress;
  FinancialGoal? get goal => _goal;
  List<SmartSuggestion> get suggestions => List.unmodifiable(_suggestions);

  /// Current-month expenses (sorted newest first)
  List<ExpenseModel> get currentMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// All expenses (sorted newest first)
  List<ExpenseModel> get allExpensesSorted {
    return List.of(_expenses)..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome => currentMonthExpenses
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get totalExpense => currentMonthExpenses
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get totalBalance => totalIncome - totalExpense;

  // ───────── Actions ─────────

  /// Initial data load — call once at app start or on pull-to-refresh.
  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final all = await _repository.getExpensesByMonth(now.year, now.month);
      all.sort((a, b) => b.date.compareTo(a.date));

      _expenses = all;

      // Get goal from LocalStorageService
      _goal = _localStorageService.getGoal();

      // Recalculate budget progress
      _budgetProgress = await _budgetService.calculateProgress(expenses: all);

      // Generate smart suggestions
      final budget = _localStorageService.getMonthlyBudget();
      _suggestions = SmartSuggestionService.analyzePatternsAndSuggest(
        expenses: all,
        monthlyBudget: budget,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new expense, persist, and notify all listeners.
  Future<void> addExpense(ExpenseModel expense) async {
    await _repository.addExpense(expense);
    // Reload from storage to get the generated ID and ensure consistency
    await loadExpenses();
  }

  /// Update an existing expense, persist, and notify all listeners.
  Future<void> updateExpense(ExpenseModel expense) async {
    await _repository.updateExpense(expense);
    await loadExpenses();
  }

  /// Delete an expense by ID, persist, and notify all listeners.
  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
    await loadExpenses();
  }

  /// Delete all data and clear state.
  Future<void> deleteAllData() async {
    await _repository.deleteAllData();
    _expenses = [];
    _budgetProgress = null;
    _goal = null;
    _suggestions = [];
    notifyListeners();
  }

  /// Import multiple expenses from an external source (e.g. Excel file).
  Future<void> importExpenses(List<ExpenseModel> expenses) async {
    for (final expense in expenses) {
      await _repository.addExpense(expense);
    }
    await loadExpenses();
  }

  /// Dismiss a smart suggestion by ID
  void dismissSuggestion(String id) {
    _suggestions = _suggestions.where((s) => s.id != id).toList();
    notifyListeners();
  }

  // --- GOAL ACTIONS ---

  Future<void> setGoal(FinancialGoal goal) async {
    _goal = goal;
    await _localStorageService.saveGoal(goal);
    notifyListeners();
  }

  Future<void> addSavingsToGoal(double amount) async {
    if (_goal == null) return;

    final updatedGoal = FinancialGoal(
      title: _goal!.title,
      targetAmount: _goal!.targetAmount,
      savedAmount: _goal!.savedAmount + amount,
      deadline: _goal!.deadline,
    );

    _goal = updatedGoal;
    await _localStorageService.saveGoal(updatedGoal);
    notifyListeners();
  }

  /// Force a full reload (same as loadExpenses but semantically clearer).
  Future<void> refresh() => loadExpenses();
}
