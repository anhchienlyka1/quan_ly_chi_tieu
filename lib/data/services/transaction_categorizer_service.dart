import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense_model.dart';

/// Service dùng Gemini AI để phân tích nội dung chuyển khoản ngân hàng.
/// - Input: nội dung chuyển khoản (chữ không dấu)
/// - Output: ExpenseCategory + tiêu đề có dấu tiếng Việt
class TransactionCategorizerService {
  GenerativeModel? _model;

  TransactionCategorizerService._();
  static TransactionCategorizerService? _instance;

  static Future<TransactionCategorizerService> getInstance() async {
    if (_instance == null) {
      _instance = TransactionCategorizerService._();
      await _instance!._init();
    }
    return _instance!;
  }

  // Hardcoded API key for auto-expense feature
  static const String _apiKey = 'AIzaSyDkw6n8Id3r6SHZEsE-fnE8UrUCrwvQ8Gk';
  
  Future<void> _init() async {
    // Use hardcoded API key
    if (_apiKey.isNotEmpty && _apiKey != 'AIzaSyBt7W8xqVOGHhF_example_REPLACE_WITH_YOUR_KEY') {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
      );
    }
  }

  /// Reinitialize with new API key
  Future<void> reinitialize() async {
    _model = null;
    await _init();
  }

  bool get isConfigured => _model != null;

  /// Phân tích nội dung chuyển khoản bằng AI
  /// [rawContent] - nội dung gốc (thường là chữ không dấu)
  /// [isIncoming] - nhận tiền (true) hay chuyển đi (false)
  /// Returns: {category: String, title: String}
  Future<Map<String, String>> categorize(
    String rawContent, {
    bool isIncoming = false,
  }) async {
    // Thử AI trước, fallback sang keyword matching nếu thất bại
    if (_model != null && rawContent.isNotEmpty) {
      try {
        return await _categorizeWithAI(rawContent, isIncoming);
      } catch (e) {
        print('🤖 AI categorization failed, falling back to keywords: $e');
      }
    }

    // Fallback: keyword matching
    return _categorizeWithKeywords(rawContent, isIncoming);
  }

  /// Phân tích bằng Gemini AI
  Future<Map<String, String>> _categorizeWithAI(
    String rawContent,
    bool isIncoming,
  ) async {
    final transactionType = isIncoming ? 'NHẬN TIỀN' : 'CHUYỂN TIỀN ĐI';
    final categories = isIncoming
        ? 'salary, bonus, investment, gift, other'
        : 'food, transport, shopping, entertainment, health, education, bills, other';

    final prompt = '''
Bạn là trợ lý phân tích giao dịch ngân hàng Việt Nam.

Loại giao dịch: $transactionType
Nội dung chuyển khoản: "$rawContent"

Lưu ý: Nội dung thường là CHỮ KHÔNG DẤU tiếng Việt (VD: "THANH TOAN TIEN DIEN THANG 1" = "Thanh toán tiền điện tháng 1").

Hãy phân tích và trả về JSON (CHỈ JSON, KHÔNG kèm text khác):
{
  "category": "một trong: $categories",
  "title": "tiêu đề ngắn gọn CÓ DẤU tiếng Việt mô tả giao dịch"
}

Quy tắc phân loại:
- food: ăn uống, nhà hàng, quán ăn, cafe, grab food, shopee food, baemin
- transport: di chuyển, xăng, grab, taxi, parking, gửi xe
- shopping: mua sắm, shopee, lazada, tiki, siêu thị, tạp hóa
- entertainment: giải trí, phim, game, karaoke, du lịch
- health: sức khỏe, thuốc, bệnh viện, khám bệnh, phòng khám
- education: giáo dục, học phí, sách, khóa học, trường
- bills: hóa đơn, điện, nước, internet, wifi, thuê nhà, tiền nhà
- salary: lương tháng
- bonus: thưởng, hoa hồng
- investment: đầu tư, chứng khoán, crypto
- gift: quà tặng, mừng, biếu
- other: không xác định rõ

CHỈ trả về JSON object, không markdown, không code block.
''';

    final response = await _model!.generateContent([
      Content.text(prompt),
    ]);

    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Empty AI response');
    }

    // Parse JSON from response
    String jsonStr = text.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceAll(RegExp(r'^```\w*\n?'), '');
      jsonStr = jsonStr.replaceAll(RegExp(r'\n?```$'), '');
      jsonStr = jsonStr.trim();
    }

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return {
      'category': json['category'] as String? ?? 'other',
      'title': json['title'] as String? ?? rawContent,
    };
  }

  /// Fallback: phân tích bằng keyword matching
  Map<String, String> _categorizeWithKeywords(
    String rawContent,
    bool isIncoming,
  ) {
    final lower = rawContent.toLowerCase();

    if (isIncoming) {
      // Thu nhập
      if (_matchAny(lower, ['luong', 'salary', 'luong thang'])) {
        return {'category': 'salary', 'title': 'Lương tháng'};
      }
      if (_matchAny(lower, ['thuong', 'bonus', 'hoa hong'])) {
        return {'category': 'bonus', 'title': 'Tiền thưởng'};
      }
      if (_matchAny(lower, ['dau tu', 'chung khoan', 'lai suat'])) {
        return {'category': 'investment', 'title': 'Thu nhập đầu tư'};
      }
      if (_matchAny(lower, ['tang', 'mung', 'bieu', 'qua'])) {
        return {'category': 'gift', 'title': 'Quà tặng'};
      }
      return {'category': 'other', 'title': 'Nhận tiền'};
    }

    // Chi tiêu
    if (_matchAny(lower, [
      'an uong', 'com', 'bun', 'pho', 'tra sua',
      'cafe', 'ca phe', 'nha hang', 'quan an',
      'grabfood', 'shopeefood', 'baemin', 'food',
      'banh', 'do an', 'an sang', 'an trua', 'an toi',
    ])) {
      return {'category': 'food', 'title': 'Ăn uống'};
    }

    if (_matchAny(lower, [
      'xang', 'grab', 'taxi', 'di chuyen',
      'gui xe', 'parking', 'xe bus', 've xe',
    ])) {
      return {'category': 'transport', 'title': 'Di chuyển'};
    }

    if (_matchAny(lower, [
      'shopee', 'lazada', 'tiki', 'mua sam',
      'sieu thi', 'tap hoa', 'mua', 'dat hang',
    ])) {
      return {'category': 'shopping', 'title': 'Mua sắm'};
    }

    if (_matchAny(lower, [
      'phim', 'game', 'karaoke', 'giai tri',
      'du lich', 'resort', 'khach san',
    ])) {
      return {'category': 'entertainment', 'title': 'Giải trí'};
    }

    if (_matchAny(lower, [
      'thuoc', 'benh vien', 'kham benh',
      'suc khoe', 'phong kham', 'bac si',
    ])) {
      return {'category': 'health', 'title': 'Sức khỏe'};
    }

    if (_matchAny(lower, [
      'hoc phi', 'sach', 'truong', 'giao duc',
      'khoa hoc', 'hoc', 'dao tao',
    ])) {
      return {'category': 'education', 'title': 'Giáo dục'};
    }

    if (_matchAny(lower, [
      'dien', 'nuoc', 'internet', 'wifi',
      'thue nha', 'tien nha', 'hoa don',
      'truyen hinh', 'dien thoai', 'cuoc',
    ])) {
      return {'category': 'bills', 'title': 'Hóa đơn & tiện ích'};
    }

    if (_matchAny(lower, ['thanh toan'])) {
      return {'category': 'bills', 'title': 'Thanh toán'};
    }

    return {'category': 'other', 'title': 'Giao dịch khác'};
  }

  bool _matchAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  /// Map category string to ExpenseCategory enum
  static ExpenseCategory mapCategory(String categoryStr, bool isIncoming) {
    switch (categoryStr.toLowerCase()) {
      case 'food':
        return ExpenseCategory.food;
      case 'transport':
        return ExpenseCategory.transport;
      case 'shopping':
        return ExpenseCategory.shopping;
      case 'entertainment':
        return ExpenseCategory.entertainment;
      case 'health':
        return ExpenseCategory.health;
      case 'education':
        return ExpenseCategory.education;
      case 'bills':
        return ExpenseCategory.bills;
      case 'salary':
        return ExpenseCategory.salary;
      case 'bonus':
        return ExpenseCategory.bonus;
      case 'investment':
        return ExpenseCategory.investment;
      case 'gift':
        return ExpenseCategory.gift;
      default:
        return ExpenseCategory.other;
    }
  }
}
