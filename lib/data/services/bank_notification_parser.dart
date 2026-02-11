import 'dart:convert';
import '../models/bank_notification_model.dart';
import '../models/expense_model.dart';

/// Service phân tích notification ngân hàng Việt Nam.
/// Nhận diện package name, parse số tiền, loại giao dịch, nội dung.
class BankNotificationParser {
  /// Mapping package name → tên ngân hàng
  static const Map<String, String> bankPackages = {
    'com.VCB': 'Vietcombank',
    'com.vietinbank.ipay': 'VietinBank',
    'com.bidiots.bidv.online': 'BIDV',
    'vn.com.techcombank.bb.app': 'Techcombank',
    'com.mbmobile': 'MB Bank',
    'com.vnpay.tpbankvn': 'TPBank',
    'com.acb.acbmobilebanking': 'ACB',
    'com.sacombank.ewallet': 'Sacombank',
    'com.VPB.VPBankNeo': 'VPBank',
    'com.shb.ebanking.mobile': 'SHB',
    'vn.momo.platform': 'Momo',
    'com.zing.zalo.zalopay': 'ZaloPay',
    'vn.vnpay.vnpayewallet': 'VNPay',
    // Thêm các ngân hàng khác khi cần
  };

  /// Kiểm tra notification có phải từ app ngân hàng không
  static bool isBankNotification(String packageName) {
    return bankPackages.containsKey(packageName);
  }

  /// Lấy tên ngân hàng từ package name
  static String getBankName(String packageName) {
    return bankPackages[packageName] ?? 'Ngân hàng';
  }

  /// Parse notification content thành BankNotificationModel
  /// Returns null nếu không parse được
  static BankNotificationModel? parseNotification({
    required String packageName,
    required String title,
    required String content,
  }) {
    if (!isBankNotification(packageName)) return null;

    final bankName = getBankName(packageName);
    final fullText = '$title $content';

    // Parse số tiền
    final amount = _parseAmount(fullText);
    if (amount == null || amount <= 0) return null;

    // Xác định nhận tiền hay chuyển đi
    final isIncoming = _isIncomingTransaction(fullText);

    // Parse nội dung chuyển khoản
    final transferContent = _parseTransferContent(fullText);

    // Parse số dư
    final balance = _parseBalance(fullText);

    return BankNotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_${packageName.hashCode}',
      bankName: bankName,
      packageName: packageName,
      amount: amount,
      isIncoming: isIncoming,
      rawContent: transferContent.isNotEmpty ? transferContent : content,
      timestamp: DateTime.now(),
      balance: balance,
    );
  }

  /// Parse số tiền từ text notification
  /// Hỗ trợ formats: +500,000 VND, -1.200.000d, 500000 VND, etc.
  static double? _parseAmount(String text) {
    // Pattern 1: Số tiền với dấu +/- và VND/VNĐ/d/đ
    // VD: "+500,000 VND", "-1.200.000d", "GD: -50,000 VND"
    final patterns = [
      // Biến động số dư: +/- số tiền
      RegExp(r'[+-]\s*([\d.,]+)\s*(?:VND|VNĐ|d|đ)', caseSensitive: false),
      // Số tiền: xxx VND
      RegExp(r'(?:so tien|số tiền|s(?:ố|o) ti(?:ề|e)n|amount)[:\s]*([\d.,]+)\s*(?:VND|VNĐ|d|đ)?', caseSensitive: false),
      // GD: xxx VND
      RegExp(r'(?:GD|giao dich)[:\s]*[+-]?\s*([\d.,]+)\s*(?:VND|VNĐ|d|đ)?', caseSensitive: false),
      // Pattern phổ biến: xxx,xxx VND hoặc xxx.xxx VND
      RegExp(r'([\d]{1,3}(?:[.,]\d{3})+)\s*(?:VND|VNĐ|d|đ)', caseSensitive: false),
      // Fallback: số lớn hơn 1000 (khả năng cao là tiền)
      RegExp(r'(\d{4,})\s*(?:VND|VNĐ|d|đ)?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1) ?? '';
        // Loại bỏ dấu phân cách hàng nghìn
        amountStr = amountStr.replaceAll(RegExp(r'[.,]'), '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) return amount;
      }
    }

    return null;
  }

  /// Xác định giao dịch nhận tiền hay chuyển đi
  static bool _isIncomingTransaction(String text) {
    final lowerText = text.toLowerCase();

    // Keywords nhận tiền
    final incomingKeywords = [
      'nhan duoc', 'nhận được', 'nhan', 'nhận',
      'chuyen den', 'chuyển đến', 'chuyen toi',
      'credited', 'credit',
      'tien vao', 'tiền vào',
      r'\+\d', // Số dương
    ];

    // Keywords chuyển đi
    final outgoingKeywords = [
      'chuyen di', 'chuyển đi', 'chuyen tien',
      'thanh toan', 'thanh toán',
      'tru', 'trừ',
      'ghi no', 'ghi nợ',
      'debited', 'debit',
      'tien ra', 'tiền ra',
      'chi tieu', 'chi tiêu',
      r'-\d', // Số âm
    ];

    // Kiểm tra outgoing trước (phổ biến hơn)
    for (final keyword in outgoingKeywords) {
      if (RegExp(keyword, caseSensitive: false).hasMatch(lowerText)) {
        return false;
      }
    }

    for (final keyword in incomingKeywords) {
      if (RegExp(keyword, caseSensitive: false).hasMatch(lowerText)) {
        return true;
      }
    }

    // Default: chuyển đi (chi tiêu)
    return false;
  }

  /// Parse nội dung chuyển khoản từ notification
  static String _parseTransferContent(String text) {
    final patterns = [
      // ND: xxx hoặc Noi dung: xxx
      RegExp(r'(?:ND|Noi dung|nội dung|N(?:ộ|o)i dung)[:\s]+(.+?)(?:\.|So du|SD|$)', caseSensitive: false),
      // Noi dung CK: xxx
      RegExp(r'(?:noi dung ck|nội dung ck|NDCK)[:\s]+(.+?)(?:\.|So du|SD|$)', caseSensitive: false),
      // Ly do: xxx
      RegExp(r'(?:Ly do|lý do|L(?:ý|y) do)[:\s]+(.+?)(?:\.|So du|SD|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        if (content.isNotEmpty) return content;
      }
    }

    return '';
  }

  /// Parse số dư từ notification
  static double? _parseBalance(String text) {
    final patterns = [
      RegExp(r'(?:So du|SD|Số dư|S(?:ố|o) d(?:ư|u))[:\s]*([\d.,]+)\s*(?:VND|VNĐ|d|đ)?', caseSensitive: false),
      RegExp(r'(?:balance|bal)[:\s]*([\d.,]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String balanceStr = match.group(1) ?? '';
        balanceStr = balanceStr.replaceAll(RegExp(r'[.,]'), '');
        return double.tryParse(balanceStr);
      }
    }

    return null;
  }
}
