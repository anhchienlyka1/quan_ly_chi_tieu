import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Who paid for this expense
enum SpenderType {
  husband('Chồng', Icons.person_rounded, AppColors.husband),
  wife('Vợ', Icons.person_rounded, AppColors.wife),
  both('Cả hai', Icons.people_rounded, AppColors.primary);

  final String label;
  final IconData icon;
  final Color color;

  const SpenderType(this.label, this.icon, this.color);
}

/// Payment method
enum PaymentMethod {
  cash('Tiền mặt', Icons.payments_rounded),
  bankTransfer('Chuyển khoản', Icons.account_balance_rounded);

  final String label;
  final IconData icon;

  const PaymentMethod(this.label, this.icon);
}

/// Enum representing expense categories for Vietnamese households
enum ExpenseCategory {
  food('Ăn uống', Icons.restaurant_rounded, AppColors.categoryFood, '🍜'),
  rent('Tiền nhà', Icons.home_rounded, AppColors.categoryRent, '🏠'),
  utilities('Điện nước', Icons.bolt_rounded, AppColors.categoryUtilities, '⚡'),
  transport('Xăng xe', Icons.local_gas_station_rounded, AppColors.categoryTransport, '⛽'),
  children('Con cái', Icons.child_care_rounded, AppColors.categoryChildren, '👶'),
  ceremony('Hiếu hỉ', Icons.card_giftcard_rounded, AppColors.categoryCeremony, '💐'),
  shopping('Mua sắm', Icons.shopping_bag_rounded, AppColors.categoryShopping, '🛒'),
  health('Sức khỏe', Icons.medical_services_rounded, AppColors.categoryHealth, '💊'),
  education('Giáo dục', Icons.school_rounded, AppColors.categoryEducation, '📚'),
  other('Khác', Icons.more_horiz_rounded, AppColors.categoryOther, '📌');

  final String label;
  final IconData icon;
  final Color color;
  final String emoji;

  const ExpenseCategory(this.label, this.icon, this.color, this.emoji);
}

/// Model representing a single expense entry.
class ExpenseModel {
  final String? id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final SpenderType spender;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.spender = SpenderType.husband,
    this.paymentMethod = PaymentMethod.cash,
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
    SpenderType? spender,
    PaymentMethod? paymentMethod,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      spender: spender ?? this.spender,
      paymentMethod: paymentMethod ?? this.paymentMethod,
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
      'spender': spender.name,
      'paymentMethod': paymentMethod.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserialize from a Map
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id']?.toString(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      spender: SpenderType.values.firstWhere(
        (e) => e.name == map['spender'],
        orElse: () => SpenderType.husband,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'ExpenseModel(id: $id, title: $title, amount: $amount, category: ${category.label}, spender: ${spender.label})';
}
