import 'dart:convert';
import '../models/bank_notification_model.dart';
import '../models/expense_model.dart';

/// Service phân tích notification ngân hàng Việt Nam.
/// Nhận diện package name, parse số tiền, loại giao dịch, nội dung.
class BankNotificationParser {
  /// Mapping package name → tên ngân hàng
  static const Map<String, String> bankPackages = {
    // --- Major Banks ---
    
    'com.vnpay.vpbankonline': 'VPBank',
    'com.vn.vib.mobileapp': 'VIB',
    'com.tpb.mb.gprsandroid': 'TPBank',
    'com.vnpay.bidv': 'BIDV',
    'vn.com.techcombank.bb.app':'Techcombank',
    'com.VCB':'Vietcombank',
    'com.vietinbank.ipay':'Vietinbank',
    'com.mservice.momotransfer':'Momo',
    'vn.com.vng.zalopay':'Zalo Pay'
  };

  /// Kiểm tra notification có phải từ app ngân hàng không
  static bool isBankNotification(String packageName) {
    print('chienn: $packageName');
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
    // Pattern kiểm tra số có PS: hoặc GD: (biến động số dư) trước
    // TPBank: PS:-6.666VND
    final fluctuationsPattern = RegExp(r'(?:PS|GD|Giao dich|Biến động)[:\s]*([+-]?[\d.,]+)\s*(?:VND|VNĐ|d|đ)', caseSensitive: false);
    
    var match = fluctuationsPattern.firstMatch(text);
    if (match != null) {
      return _parseNumberString(match.group(1));
    }

    // Pattern 1: Số tiền với dấu +/- và VND/VNĐ/d/đ
    // VD: "+500,000 VND", "-1.200.000d"
    final signedAmountPattern = RegExp(r'[+-]\s*([\d.,]+)\s*(?:VND|VNĐ|d|đ)', caseSensitive: false);
    match = signedAmountPattern.firstMatch(text);
    if (match != null) {
       return _parseNumberString(match.group(1));
    }

     // Số tiền: xxx VND
    final explicitAmountPattern = RegExp(r'(?:so tien|số tiền|s(?:ố|o) ti(?:ề|e)n|amount)[:\s]*([\d.,]+)\s*(?:VND|VNĐ|d|đ)?', caseSensitive: false);
    match = explicitAmountPattern.firstMatch(text);
    if (match != null) {
       return _parseNumberString(match.group(1));
    }

    return null;
  }

  static double? _parseNumberString(String? raw) {
    if (raw == null) return null;
    String clean = raw.replaceAll(RegExp(r'[^\d.,-]'), ''); // Keep digits, dot, comma, minus
    
    // Xử lý separator: 
    // Nếu có cả dấu . và , -> dấu nào xuất hiện sau cùng là decimal separator (VN: 100.000,00 hoặc 100,000.00)
    // Tuy nhiên, ngân hàng VN thường dùng . làm hàng nghìn (TPBank: 6.666) -> format tiếng việt
    
    // Trường hợp đơn giản: chỉ có dấu chấm (TPBank: 6.666) hoặc chỉ dấu phẩy (6,666)
    // Nếu format là xxx.xxx -> remove dot. Nếu xxx.xxx.xxx -> remove dot.
    // Nếu số lượng group sau dấu chấm là 3 (6.666) -> khả năng cao là hàng nghìn.
    // Logic an toàn: 
    // - Remove toàn bộ dấu chấm (.) và dấu phẩy (,) 
    // - TRỪ KHI dấu đó là decimal separator. 
    // Với VND, thường không có xu lẻ, nên các số nguyên lớn thường là separator hàng nghìn.
    
    // Cách xử lý "mỳ ăn liền" cho case TPBank "6.666":
    // Remove toàn bộ dấu chấm và phẩy, coi như số nguyên VND.
    clean = clean.replaceAll('.', '').replaceAll(',', '');
    
    return double.tryParse(clean)?.abs();
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
      // Sử dụng \b để tránh match nhầm 'VND' chứa 'ND'
      // Thêm 'So GD', 'Số GD' vào terminator
      RegExp(r'(?:^|\b)(?:ND|Noi dung|nội dung|N(?:ộ|o)i dung)[:\s]+(.+?)(?:\s+(?:So du|SD|Số dư|So GD|Số GD)|$)', caseSensitive: false, dotAll: true),
      // Noi dung CK: xxx
      RegExp(r'(?:^|\b)(?:noi dung ck|nội dung ck|NDCK)[:\s]+(.+?)(?:\s+(?:So du|SD|Số dư|So GD|Số GD)|$)', caseSensitive: false, dotAll: true),
      // Ly do: xxx
      RegExp(r'(?:^|\b)(?:Ly do|lý do|L(?:ý|y) do)[:\s]+(.+?)(?:\s+(?:So du|SD|Số dư|So GD|Số GD)|$)', caseSensitive: false, dotAll: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final content = match.group(1)?.trim() ?? '';
        // Loại bỏ các ký tự thừa ở cuối nếu có (ví dụ dấu chấm, dấu phẩy cuối câu nếu terminator không bắt hết)
        // Nhưng giữ lại dấu chấm giữa câu.
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
