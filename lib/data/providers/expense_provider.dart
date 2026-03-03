import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../services/budget_service.dart';

/// Centralized state for all expense/income data.
/// This is the **single source of truth** — every screen should read from here.
///
/// Usage:
///   final provider = context.read<ExpenseProvider>();   // one-shot read
///   final provider = context.watch<ExpenseProvider>();  // auto-rebuild
class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final BudgetService _budgetService = BudgetService();

  // ───────── State ─────────
  List<ExpenseModel> _expenses = [];
  BudgetProgress? _budgetProgress;
  bool _isLoading = false;
  String? _error;

  // ───────── Getters ─────────
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  BudgetProgress? get budgetProgress => _budgetProgress;

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

      // Recalculate budget progress
      _budgetProgress = await _budgetService.calculateProgress(
        expenses: all,
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
    notifyListeners();
  }

  /// Force a full reload (same as loadExpenses but semantically clearer).
  Future<void> refresh() => loadExpenses();
}
