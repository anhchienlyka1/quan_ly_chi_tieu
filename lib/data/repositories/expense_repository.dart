import '../models/expense_model.dart';
import '../datasources/local/expense_local_datasource.dart';

/// Repository for managing expense data.
/// Now connects to the Local Data Source (SharedPreferences).
class ExpenseRepository {
  final ExpenseLocalDataSource _localDataSource = ExpenseLocalDataSource();

  // In-memory cache or sync mechanism could be added here later.

  /// Get all expenses from Local Storage
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      return await _localDataSource.getAllExpenses();
    } catch (e) {
      print('Error fetching expenses locally: $e');
      return [];
    }
  }

  /// Add a new expense locally
  Future<void> addExpense(ExpenseModel expense) async {
    await _localDataSource.addExpense(expense);
  }

  /// Update an expense locally
  Future<void> updateExpense(ExpenseModel expense) async {
    await _localDataSource.updateExpense(expense);
  }

  /// Delete an expense locally
  Future<void> deleteExpense(String id) async {
    await _localDataSource.deleteExpense(id);
  }

  // --- Filtering Logic (Client-side for now, or Server-side query params) ---

  /// Get expenses filtered by date range (local filtering after fetch)
  Future<List<ExpenseModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllExpenses();
    return all
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  /// Get expenses for a specific month
  Future<List<ExpenseModel>> getExpensesByMonth(int year, int month) async {
    final all = await getAllExpenses();
    return all
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  /// Get total expense amount for a specific month
  Future<double> getMonthlyTotal(int year, int month) async {
    final monthly = await getExpensesByMonth(year, month);
    return monthly.fold<double>(0.0, (sum, e) => sum + e.amount);
  }
}
