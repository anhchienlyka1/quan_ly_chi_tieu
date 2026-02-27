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
    // Try to get API key from SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('gemini_api_key');

    String keyToUse = '';
    if (userKey != null && userKey.isNotEmpty) {
      keyToUse = userKey;
    } else if (_apiKey.isNotEmpty &&
        _apiKey != 'AIzaSyBt7W8xqVOGHhF_example_REPLACE_WITH_YOUR_KEY') {
      keyToUse = _apiKey;
    }

    if (keyToUse.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: keyToUse,
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
Bạn là chuyên gia ngôn ngữ học và phân tích tài chính người Việt Nam.
Nhiệm vụ của bạn là khôi phục dấu tiếng Việt chính xác cho nội dung giao dịch và phân loại nó.

Thông tin giao dịch:
- Loại giao dịch: $transactionType
- Nội dung gốc (thường không dấu): "$rawContent"

Yêu cầu chi tiết:
1. KHÔI PHỤC DẤU TIẾNG VIỆT: Hãy phân tích kỹ ngữ cảnh và tên riêng để thêm dấu chính xác.
   - Ví dụ: "PHAM VAN CHIEN chuyen tien an sang" -> "Phạm Văn Chiến chuyển tiền ăn sáng"
   - Ví dụ: "tien nha thang 1" -> "Tiền nhà tháng 1"
2. PHÂN LOẠI (Category): Chọn 1 category phù hợp nhất từ danh sách bên dưới.
3. TIÊU ĐỀ (Title): Là nội dung đã được khôi phục dấu tiếng Việt, viết hoa chữ cái đầu và tên riêng.

Danh sách Category:
- food: ăn uống, ăn sáng, cafe, nhà hàng...
- transport: di chuyển, grab, xăng, xe...
- shopping: mua sắm, siêu thị...
- entertainment: giải trí, phim...
- health: thuốc, khám bệnh...
- education: học phí, sách...
- bills: điện, nước, net, tiền nhà...
- salary: lương...
- bonus: thưởng...
- investment: đầu tư...
- gift: biếu tặng...
- other: khác (sử dụng khi không xác định được loại giao dịch hoặc không thuộc các loại trên)

Hãy trả về kết quả dưới dạng JSON hợp lệ (không markdown):
{
  "category": "category_code",
  "title": "Nội dung đã khôi phục dấu"
}
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
    final title = json['title'] as String? ?? rawContent;
    final category = json['category'] as String? ?? 'other';
    
    print('🤖 AI response json: $jsonStr'); // Print full JSON for debugging
    print('🤖 AI translated content: "$title"'); // Print the specific translated content

    return {
      'category': category,
      'title': title,
    };
  }

  /// Fallback: phân tích bằng keyword matching
  Map<String, String> _categorizeWithKeywords(
    String rawContent,
    bool isIncoming,
  ) {
    final lower = rawContent.toLowerCase();
    String title = rawContent; 
    
    // Helper to format title if needed (simple capitalization)
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    if (isIncoming) {
      // Thu nhập
      if (_matchAny(lower, ['luong', 'salary', 'luong thang'])) {
        return {'category': 'salary', 'title': title};
      }
      if (_matchAny(lower, ['thuong', 'bonus', 'hoa hong'])) {
        return {'category': 'bonus', 'title': title};
      }
      if (_matchAny(lower, ['dau tu', 'chung khoan', 'lai suat'])) {
        return {'category': 'investment', 'title': title};
      }
      if (_matchAny(lower, ['tang', 'mung', 'bieu', 'qua'])) {
        return {'category': 'gift', 'title': title};
      }
      return {'category': 'other', 'title': title};
    }

    // Chi tiêu
    if (_matchAny(lower, [
      'an uong', 'com', 'bun', 'pho', 'tra sua',
      'cafe', 'ca phe', 'nha hang', 'quan an',
      'grabfood', 'shopeefood', 'baemin', 'food',
      'banh', 'do an', 'an sang', 'an trua', 'an toi',
    ])) {
      return {'category': 'food', 'title': title};
    }

    if (_matchAny(lower, [
      'xang', 'grab', 'taxi', 'di chuyen',
      'gui xe', 'parking', 'xe bus', 've xe',
    ])) {
      return {'category': 'transport', 'title': title};
    }

    if (_matchAny(lower, [
      'shopee', 'lazada', 'tiki', 'mua sam',
      'sieu thi', 'tap hoa', 'mua', 'dat hang',
    ])) {
      return {'category': 'shopping', 'title': title};
    }

    if (_matchAny(lower, [
      'phim', 'game', 'karaoke', 'giai tri',
      'du lich', 'resort', 'khach san',
    ])) {
      return {'category': 'entertainment', 'title': title};
    }

    if (_matchAny(lower, [
      'thuoc', 'benh vien', 'kham benh',
      'suc khoe', 'phong kham', 'bac si',
    ])) {
      return {'category': 'health', 'title': title};
    }

    if (_matchAny(lower, [
      'hoc phi', 'sach', 'truong', 'giao duc',
      'khoa hoc', 'hoc', 'dao tao',
    ])) {
      return {'category': 'education', 'title': title};
    }

    if (_matchAny(lower, [
      'dien', 'nuoc', 'internet', 'wifi',
      'thue nha', 'tien nha', 'hoa don',
      'truyen hinh', 'dien thoai', 'cuoc',
    ])) {
      return {'category': 'bills', 'title': title};
    }

    if (_matchAny(lower, ['thanh toan'])) {
      return {'category': 'bills', 'title': title};
    }

    if (_matchAny(lower, ['chuyen tien', 'ck', 'chuyen khoan'])) {
      return {'category': 'other', 'title': title};
    }

    return {'category': 'other', 'title': title};
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
