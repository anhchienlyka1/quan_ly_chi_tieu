import '../models/expense_model.dart';
import '../datasources/remote/expense_remote_datasource.dart';

/// Repository for managing expense data.
/// Now connects to the Remote Data Source (Local Server API).
class ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource = ExpenseRemoteDataSource();

  // In-memory cache or sync mechanism could be added here later.

  /// Get all expenses from API
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      return await _remoteDataSource.getAllExpenses();
    } catch (e) {
      // Handle network errors gracefully (e.g., return empty list or cached data)
      // For now, rethrow or return empty list
      print('Error fetching expenses: $e');
      return [];
    }
  }

  /// Add a new expense via API
  Future<void> addExpense(ExpenseModel expense) async {
    await _remoteDataSource.addExpense(expense);
  }

  /// Update an expense via API
  Future<void> updateExpense(ExpenseModel expense) async {
    await _remoteDataSource.updateExpense(expense);
  }

  /// Delete an expense via API
  Future<void> deleteExpense(String id) async {
    await _remoteDataSource.deleteExpense(id);
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
