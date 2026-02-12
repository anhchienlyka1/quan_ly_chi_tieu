import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense_model.dart';

/// Model representing the extracted receipt data from AI.
class ReceiptData {
  final String title;
  final double amount;
  final String category;
  final String date;
  final String? note;
  final List<ReceiptItem> items;
  final String? storeName;
  final double confidence;

  ReceiptData({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.items = const [],
    this.storeName,
    this.confidence = 0.0,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      title: json['title'] as String? ?? 'Hóa đơn',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'other',
      date: json['date'] as String? ?? DateTime.now().toIso8601String(),
      note: json['note'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItem.fromJson(item))
              .toList() ??
          [],
      storeName: json['store_name'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to ExpenseModel for saving
  ExpenseModel toExpenseModel() {
    return ExpenseModel(
      title: storeName != null ? '$storeName - $title' : title,
      amount: amount,
      category: _mapCategory(category),
      date: _parseDate(date),
      note: _buildNote(),
    );
  }

  ExpenseCategory _mapCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
      case 'ăn uống':
      case 'đồ ăn':
      case 'nhà hàng':
      case 'quán ăn':
      case 'cafe':
      case 'cà phê':
        return ExpenseCategory.food;
      case 'transport':
      case 'di chuyển':
      case 'xăng':
      case 'đổ xăng':
      case 'grab':
      case 'taxi':
        return ExpenseCategory.transport;
      case 'shopping':
      case 'mua sắm':
      case 'siêu thị':
      case 'tạp hóa':
        return ExpenseCategory.shopping;
      case 'entertainment':
      case 'giải trí':
      case 'phim':
      case 'karaoke':
        return ExpenseCategory.entertainment;
      case 'health':
      case 'sức khỏe':
      case 'thuốc':
      case 'bệnh viện':
      case 'khám bệnh':
        return ExpenseCategory.health;
      case 'education':
      case 'giáo dục':
      case 'học phí':
      case 'sách':
        return ExpenseCategory.education;
      case 'bills':
      case 'hóa đơn':
      case 'điện':
      case 'nước':
      case 'internet':
        return ExpenseCategory.bills;
      default:
        return ExpenseCategory.other;
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _buildNote() {
    final parts = <String>[];
    if (storeName != null) parts.add('Cửa hàng: $storeName');
    if (items.isNotEmpty) {
      parts.add('Chi tiết:');
      for (final item in items) {
        parts.add('  • ${item.name}: ${item.amount.toStringAsFixed(0)}₫');
      }
    }
    if (note != null && note!.isNotEmpty) parts.add(note!);
    return parts.join('\n');
  }
}

class ReceiptItem {
  final String name;
  final double amount;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Service for scanning receipts using Gemini AI Vision.
class ReceiptScannerService {
  static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY';
  
  GenerativeModel? _model;

  ReceiptScannerService({String? apiKey}) {
    final key = apiKey ?? _defaultApiKey;
    if (key != _defaultApiKey && key.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: key,
      );
    }
  }

  bool get isConfigured => _model != null;

  /// Scan a receipt image and extract expense data.
  /// [imageBytes] - raw bytes of the receipt image
  /// [mimeType] - MIME type (e.g. 'image/jpeg', 'image/png')
  /// [qrContent] - Optional QR code content detected locally
  Future<ReceiptData> scanReceipt(
    Uint8List imageBytes,
    String mimeType, {
    String? qrContent,
  }) async {
    if (_model == null) {
      throw Exception(
        'Gemini API key chưa được cấu hình. '
        'Vui lòng vào Cài đặt để thêm API key.',
      );
    }

    final prompt = TextPart('''
Bạn là một trợ lý chuyên phân tích hóa đơn/biên lai mua hàng.
${qrContent != null ? 'Tôi đã quét được mã QR trên ảnh với nội dung: "$qrContent". Hãy sử dụng thông tin này nếu hữu ích.' : ''}
Hãy phân tích ảnh hóa đơn này và trả về dữ liệu JSON với cấu trúc chính xác như sau:

{
  "title": "tóm tắt ngắn gọn nội dung hóa đơn (ví dụ: Mua sắm tại BigC)",
  "amount": 150000,
  "category": "một trong các giá trị: food, transport, shopping, entertainment, health, education, bills, other",
  "date": "YYYY-MM-DDTHH:mm:ss.000 (ngày trên hóa đơn, nếu không có dùng ngày hôm nay ${DateTime.now().toIso8601String()})",
  "store_name": "tên cửa hàng/nhà hàng nếu có",
  "note": "ghi chú thêm nếu có",
  "items": [
    {"name": "tên món hàng", "amount": 50000, "quantity": 1}
  ],
  "confidence": 0.95
}

Lưu ý quan trọng:
- amount là TỔNG TIỀN phải trả (đã gồm VAT/giảm giá nếu có), đơn vị VNĐ, KHÔNG có dấu chấm hay phẩy
- Nếu không đọc được rõ thông tin nào, hãy ước lượng hợp lý
- Category phải là MỘT trong các giá trị: food, transport, shopping, entertainment, health, education, bills, other
- confidence là mức độ tự tin từ 0.0 đến 1.0
- CHỈ trả về JSON, KHÔNG kèm thêm text hay giải thích
- Nếu có mã QR chứa thông tin hóa đơn (như PDV, ký hiệu, số hóa đơn), hãy ưu tiên sử dụng thông tin đó để trích xuất chính xác hơn

Chỉ trả về JSON object, không markdown, không code block.
''');

    final imagePart = DataPart(mimeType, imageBytes);

    try {
      final response = await _model!.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Không thể đọc được hóa đơn. Hãy thử lại.');
      }

      // Parse JSON from response (may have markdown wrapping)
      String jsonStr = text.trim();
      
      // Remove markdown code block if present
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
        jsonStr = jsonStr.trim();
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ReceiptData.fromJson(json);
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Không thể phân tích dữ liệu hóa đơn via AI. Vui lòng thử lại hoặc nhập thủ công.');
      } else if (e.toString().contains('403') || e.toString().contains('401')) {
        throw Exception('Lỗi xác thực API Key. Vui lòng kiểm tra lại cấu hình.');
      } else if (e.toString().contains('503') || e.toString().contains('500')) {
        throw Exception('Dịch vụ AI đang bận. Vui lòng thử lại sau.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw Exception('Không có kết nối mạng. Vui lòng kiểm tra internet.');
      }
      rethrow;
    }
  }
}
