import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Enum representing expense categories
enum TransactionType {
  expense,
  income;

  String get label => this == TransactionType.expense ? 'Chi tiêu' : 'Thu nhập';
}

/// Enum representing expense/income categories
enum ExpenseCategory {
  // Expenses
  food('Ăn uống', Icons.restaurant_rounded, AppColors.categoryFood),
  transport('Di chuyển', Icons.directions_car_rounded, AppColors.categoryTransport),
  shopping('Mua sắm', Icons.shopping_bag_rounded, AppColors.categoryShopping),
  entertainment('Giải trí', Icons.movie_rounded, AppColors.categoryEntertainment),
  health('Sức khỏe', Icons.medical_services_rounded, AppColors.categoryHealth),
  education('Giáo dục', Icons.school_rounded, AppColors.categoryEducation),
  bills('Hóa đơn', Icons.receipt_long_rounded, AppColors.categoryBills),
  
  // Income
  salary('Lương', Icons.attach_money_rounded, Colors.green),
  bonus('Thưởng', Icons.star_rounded, Colors.orange),
  investment('Đầu tư', Icons.trending_up_rounded, Colors.blue),
  gift('Quà tặng', Icons.card_giftcard_rounded, Colors.purple),
  
  // Other
  other('Khác', Icons.more_horiz_rounded, AppColors.categoryOther);

  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.label, this.icon, this.color);
  
  bool get isIncome => 
      this == salary || 
      this == bonus || 
      this == investment || 
      this == gift;
}

/// Model representing a single transaction (expense or income).
class ExpenseModel {
  final String? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final TransactionType type;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    DateTime? createdAt,
    TransactionType? type,
  }) : type = type ?? TransactionType.expense,
       createdAt = createdAt ?? DateTime.now();

  /// Create a copy with optional field overrides
  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    TransactionType? type,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
      type: type ?? this.type,
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
      'type': type.name,
    };
  }

  /// Deserialize from a Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    TransactionType? parsedType;
    if (map['type'] != null) {
      final typeStr = map['type'].toString();
      for (final t in TransactionType.values) {
        if (t.name == typeStr) {
          parsedType = t;
          break;
        }
      }
    }

    return ExpenseModel(
      id: map['id']?.toString(),
      title: (map['title'] ?? '') as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      type: parsedType,
    );
  }

  @override
  String toString() => 'ExpenseModel(id: $id, title: $title, amount: $amount, category: ${category.label}, type: ${type.name})';
}
