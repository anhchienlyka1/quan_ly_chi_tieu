import 'dart:convert';
import '../models/expense_model.dart';

/// Model representing a monthly budget with overall and per-category limits.
class BudgetModel {
  /// Overall monthly budget limit
  final double totalBudget;

  /// Optional per-category budget limits
  final Map<ExpenseCategory, double> categoryBudgets;

  /// The month/year this budget applies to (stored as "yyyy-MM")
  final String monthKey;

  const BudgetModel({
    required this.totalBudget,
    this.categoryBudgets = const {},
    required this.monthKey,
  });

  /// Create from current month
  factory BudgetModel.forCurrentMonth({
    required double totalBudget,
    Map<ExpenseCategory, double> categoryBudgets = const {},
  }) {
    final now = DateTime.now();
    return BudgetModel(
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      monthKey: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );
  }

  BudgetModel copyWith({
    double? totalBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
    String? monthKey,
  }) {
    return BudgetModel(
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      monthKey: monthKey ?? this.monthKey,
    );
  }

  /// Serialize to JSON string for storage
  Map<String, dynamic> toMap() {
    return {
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'monthKey': monthKey,
    };
  }

  String toJson() => jsonEncode(toMap());

  /// Deserialize from JSON string
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    final catBudgets = <ExpenseCategory, double>{};
    if (map['categoryBudgets'] != null) {
      (map['categoryBudgets'] as Map<String, dynamic>).forEach((key, value) {
        for (final cat in ExpenseCategory.values) {
          if (cat.name == key) {
            catBudgets[cat] = (value as num).toDouble();
            break;
          }
        }
      });
    }

    return BudgetModel(
      totalBudget: (map['totalBudget'] as num?)?.toDouble() ?? 0,
      categoryBudgets: catBudgets,
      monthKey: map['monthKey'] as String? ?? '',
    );
  }

  factory BudgetModel.fromJson(String json) =>
      BudgetModel.fromMap(jsonDecode(json) as Map<String, dynamic>);

  /// Check if budget is set (non-zero)
  bool get isSet => totalBudget > 0;

  /// Get budget for a specific category, returns null if not set
  double? getBudgetForCategory(ExpenseCategory category) =>
      categoryBudgets[category];

  /// Get expense categories that have budgets only (not income)
  static List<ExpenseCategory> get expenseCategories =>
      ExpenseCategory.values.where((c) => !c.isIncome).toList();

  @override
  String toString() =>
      'BudgetModel(total: $totalBudget, categories: ${categoryBudgets.length}, month: $monthKey)';
}
