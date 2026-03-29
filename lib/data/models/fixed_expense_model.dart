import 'package:flutter/material.dart';
import 'expense_model.dart';

/// Model representing a fixed monthly expense (e.g. rent, electricity, internet).
class FixedExpenseModel {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;

  /// Day of the month this expense is typically due (1–31).
  final int dayOfMonth;

  /// Whether this expense is currently active (included in totals & import).
  final bool isActive;

  final String? note;
  final DateTime createdAt;

  FixedExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.dayOfMonth = 1,
    this.isActive = true,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  FixedExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    int? dayOfMonth,
    bool? isActive,
    String? note,
  }) {
    return FixedExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'dayOfMonth': dayOfMonth,
      'isActive': isActive,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FixedExpenseModel.fromMap(Map<String, dynamic> map) {
    return FixedExpenseModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.bills,
      ),
      dayOfMonth: (map['dayOfMonth'] as num?)?.toInt() ?? 1,
      isActive: map['isActive'] as bool? ?? true,
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Returns the icon associated with the category.
  IconData get icon => category.icon;

  /// Returns the color associated with the category.
  Color get color => category.color;

  @override
  String toString() =>
      'FixedExpenseModel(id: $id, title: $title, amount: $amount, active: $isActive)';
}
