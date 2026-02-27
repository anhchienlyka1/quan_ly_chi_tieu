import 'expense_model.dart';

/// Model đại diện cho một giao dịch ngân hàng được parse từ notification.
class BankNotificationModel {
  final String id;
  final String bankName;
  final String packageName;
  final double amount;
  final bool isIncoming; // true = nhận tiền, false = chuyển đi
  final String rawContent; // Nội dung gốc từ notification
  final String parsedTitle; // Tiêu đề sau khi AI phân tích
  final ExpenseCategory category; // Danh mục do AI xác định
  final DateTime timestamp; // Thời gian giao dịch
  final bool isAutoRecorded; // Đã tự động ghi vào chi tiêu chưa
  final double? balance; // Số dư còn lại (nếu parse được)
  final String? linkedTransactionId; // ID giao dịch đối ứng (nếu là chuyển nội bộ)

  BankNotificationModel({
    required this.id,
    required this.bankName,
    required this.packageName,
    required this.amount,
    required this.isIncoming,
    required this.rawContent,
    this.parsedTitle = '',
    this.category = ExpenseCategory.other,
    required this.timestamp,
    this.isAutoRecorded = false,
    this.balance,
    this.linkedTransactionId,
  });

  bool get isInternalTransfer => linkedTransactionId != null;

  BankNotificationModel copyWith({
    String? id,
    String? bankName,
    String? packageName,
    double? amount,
    bool? isIncoming,
    String? rawContent,
    String? parsedTitle,
    ExpenseCategory? category,
    DateTime? timestamp,
    bool? isAutoRecorded,
    double? balance,
    String? linkedTransactionId,
  }) {
    return BankNotificationModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      packageName: packageName ?? this.packageName,
      amount: amount ?? this.amount,
      isIncoming: isIncoming ?? this.isIncoming,
      rawContent: rawContent ?? this.rawContent,
      parsedTitle: parsedTitle ?? this.parsedTitle,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isAutoRecorded: isAutoRecorded ?? this.isAutoRecorded,
      balance: balance ?? this.balance,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
    );
  }

  /// Serialize to JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'packageName': packageName,
      'amount': amount,
      'isIncoming': isIncoming,
      'rawContent': rawContent,
      'parsedTitle': parsedTitle,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'isAutoRecorded': isAutoRecorded,
      'balance': balance,
      'linkedTransactionId': linkedTransactionId,
    };
  }

  /// Deserialize from JSON map
  factory BankNotificationModel.fromMap(Map<String, dynamic> map) {
    return BankNotificationModel(
      id: map['id'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      isIncoming: map['isIncoming'] as bool? ?? false,
      rawContent: map['rawContent'] as String? ?? '',
      parsedTitle: map['parsedTitle'] as String? ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      isAutoRecorded: map['isAutoRecorded'] as bool? ?? false,
      balance: (map['balance'] as num?)?.toDouble(),
      linkedTransactionId: map['linkedTransactionId'] as String?,
    );
  }

  /// Convert to ExpenseModel for saving to the main expense list
  ExpenseModel toExpenseModel() {
    return ExpenseModel(
      title: parsedTitle.isNotEmpty ? parsedTitle : rawContent,
      amount: amount,
      category: category,
      date: timestamp,
      note: 'Tự động ghi từ $bankName\nNội dung: $rawContent${linkedTransactionId != null ? '\n(Giao dịch liên kết)' : ''}',
      type: isIncoming ? TransactionType.income : TransactionType.expense,
    );
  }

  @override
  String toString() =>
      'BankNotification(bank: $bankName, amount: $amount, incoming: $isIncoming, title: $parsedTitle, linked: $linkedTransactionId)';
}
