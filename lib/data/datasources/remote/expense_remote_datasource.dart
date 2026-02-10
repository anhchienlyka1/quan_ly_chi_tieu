import 'package:dio/dio.dart';
import '../../core/network/http_client.dart';
import '../../core/constants/api_config.dart';
import '../models/expense_model.dart';
import '../../core/constants/api_constants.dart'; // import for endpoints constant

class ExpenseRemoteDataSource {
  final HttpClient _client = HttpClient();

  // GET: /expenses
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final response = await _client.get(ApiConfig.expenses);
      final List<dynamic> data = response.data;
      return data.map((json) => ExpenseModel.fromMap(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load expenses: ${e.message}');
    }
  }

  // POST: /expenses
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      final response = await _client.post(
        ApiConfig.expenses,
        data: expense.toMap(),
      );
      return ExpenseModel.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to add expense: ${e.message}');
    }
  }

  // PUT: /expenses/{id}
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      final response = await _client.put(
        '${ApiConfig.expenses}/${expense.id}',
        data: expense.toMap(),
      );
      return ExpenseModel.fromMap(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update expense: ${e.message}');
    }
  }

  // DELETE: /expenses/{id}
  Future<void> deleteExpense(String id) async {
    try {
      await _client.delete('${ApiConfig.expenses}/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete expense: ${e.message}');
    }
  }
}
