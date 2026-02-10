import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Enum representing expense categories
enum ExpenseCategory {
  food('Ăn uống', Icons.restaurant_rounded, AppColors.categoryFood),
  transport('Di chuyển', Icons.directions_car_rounded, AppColors.categoryTransport),
  shopping('Mua sắm', Icons.shopping_bag_rounded, AppColors.categoryShopping),
  entertainment('Giải trí', Icons.movie_rounded, AppColors.categoryEntertainment),
  health('Sức khỏe', Icons.medical_services_rounded, AppColors.categoryHealth),
  education('Giáo dục', Icons.school_rounded, AppColors.categoryEducation),
  bills('Hóa đơn', Icons.receipt_long_rounded, AppColors.categoryBills),
  other('Khác', Icons.more_horiz_rounded, AppColors.categoryOther);

  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.label, this.icon, this.color);
}

/// Model representing a single expense entry.
class ExpenseModel {
  final String? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy with optional field overrides
  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  /// Serialize to a Map (for local storage or API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserialize from a Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() => 'ExpenseModel(id: $id, title: $title, amount: $amount, category: ${category.label})';
}
