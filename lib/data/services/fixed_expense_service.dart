import 'dart:math';
import '../models/fixed_expense_model.dart';
import '../models/expense_model.dart';
import 'local_storage_service.dart';

/// Service providing business logic for fixed monthly expenses.
class FixedExpenseService {
  final LocalStorageService _storage;

  FixedExpenseService(this._storage);

  // ───────── CRUD ─────────

  List<FixedExpenseModel> getAll() => _storage.getFixedExpenses();

  Future<void> add(FixedExpenseModel item) async {
    final list = getAll();
    list.add(item);
    await _storage.saveFixedExpenses(list);
  }

  Future<void> update(FixedExpenseModel updated) async {
    final list = getAll();
    final idx = list.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) list[idx] = updated;
    await _storage.saveFixedExpenses(list);
  }

  Future<void> delete(String id) async {
    final list = getAll()..removeWhere((e) => e.id == id);
    await _storage.saveFixedExpenses(list);
  }

  // ───────── Helpers ─────────

  /// Total of all **active** fixed expenses.
  double getTotalMonthly() {
    return getAll()
        .where((e) => e.isActive)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  /// Returns true if the monthly import dialog should be shown this month.
  bool shouldShowImportDialog(DateTime now) {
    final currentKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final lastKey = _storage.getLastFixedImportMonth();
    return lastKey != currentKey && getAll().any((e) => e.isActive);
  }

  /// Mark current month as imported (dialog won't show again this month).
  Future<void> markImportDone(DateTime now) async {
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await _storage.setLastFixedImportMonth(key);
  }

  /// Convert selected fixed expenses into regular ExpenseModel instances
  /// (one per fixed expense) for the given month.
  List<ExpenseModel> toExpenseModels(
    List<FixedExpenseModel> items,
    DateTime month,
  ) {
    return items.map((item) {
      final day = min(item.dayOfMonth, _daysInMonth(month.year, month.month));
      return ExpenseModel(
        title: item.title,
        amount: item.amount,
        category: item.category,
        date: DateTime(month.year, month.month, day),
        note: item.note ?? 'Chi tiêu cố định',
        type: TransactionType.expense,
      );
    }).toList();
  }

  /// Generates a unique ID for a new fixed expense.
  static String generateId() =>
      'fe_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
