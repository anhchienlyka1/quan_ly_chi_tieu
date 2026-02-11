import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/expense_model.dart';

class ExpenseLocalDataSource {
  static const String _storageKey = 'expenses_data';

  Future<List<ExpenseModel>> getAllExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => ExpenseModel.fromMap(e)).toList();
    } catch (e) {
      print('Error parsing local expenses: $e');
      return [];
    }
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ExpenseModel> currentExpenses = await getAllExpenses();

    // Generate a unique ID if not present (simple implementation)
    final newExpense = expense.copyWith(
      id: expense.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );

    currentExpenses.add(newExpense);

    await _saveList(prefs, currentExpenses);
    return newExpense;
  }

  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ExpenseModel> currentExpenses = await getAllExpenses();

    final index = currentExpenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      currentExpenses[index] = expense;
      await _saveList(prefs, currentExpenses);
      return expense;
    } else {
      throw Exception('Expense not found');
    }
  }

  Future<void> deleteExpense(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ExpenseModel> currentExpenses = await getAllExpenses();

    currentExpenses.removeWhere((e) => e.id == id);
    await _saveList(prefs, currentExpenses);
  }

  Future<void> _saveList(
    SharedPreferences prefs,
    List<ExpenseModel> expenses,
  ) async {
    final String jsonString = jsonEncode(
      expenses.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
  }
}
