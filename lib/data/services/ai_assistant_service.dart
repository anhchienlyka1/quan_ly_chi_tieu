import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';

/// Tin nhắn trong cuộc hội thoại AI
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Service trợ lý AI thông minh — chat trao đổi về tài chính.
/// Gửi context dữ liệu chi tiêu kèm mỗi câu hỏi để AI trả lời chính xác.
class AiAssistantService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  static AiAssistantService? _instance;

  AiAssistantService._();

  static Future<AiAssistantService> getInstance() async {
    if (_instance == null) {
      _instance = AiAssistantService._();
      await _instance!._init();
    }
    return _instance!;
  }

  static const String _apiKey = 'AIzaSyDkw6n8Id3r6SHZEsE-fnE8UrUCrwvQ8Gk';

  Future<void> _init() async {
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

  bool get isConfigured => _model != null;

  /// Câu hỏi gợi ý cho người dùng
  static List<String> get suggestedQuestions => [
        '💰 Tình hình chi tiêu tháng này thế nào?',
        '📊 Tôi chi nhiều nhất vào mục nào?',
        '🎯 Làm sao để tiết kiệm hơn?',
        '⚠️ Tôi có đang vượt ngân sách không?',
        '📈 So sánh thu chi tháng này giúp tôi',
        '💡 Cho tôi lời khuyên tài chính',
      ];

  /// Bắt đầu phiên chat mới với context tài chính
  void startNewSession({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
  }) {
    if (_model == null) return;

    final systemContext = _buildFinancialContext(
      expenses: expenses,
      totalBalance: totalBalance,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
    );

    _chatSession = _model!.startChat(history: [
      Content.text(systemContext),
      Content.model([TextPart(_getWelcomeMessage())]),
    ]);
  }

  /// Gửi tin nhắn và nhận phản hồi từ AI
  Future<String> sendMessage(String userMessage) async {
    if (_chatSession == null) {
      return 'Chưa kết nối được AI. Vui lòng kiểm tra API key trong Cài đặt.';
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'Xin lỗi, mình không hiểu. Bạn có thể hỏi lại được không?';
      }

      return text.trim();
    } catch (e) {
      print('🤖 AI chat error: $e');
      return 'Đã có lỗi xảy ra. Vui lòng thử lại sau nhé! 🙏';
    }
  }

  /// Xây dựng context tài chính từ dữ liệu thực
  String _buildFinancialContext({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
  }) {
    final now = DateTime.now();
    final totalExpense = expenses
        .where((e) => e.type == TransactionType.expense)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = expenses
        .where((e) => e.type == TransactionType.income)
        .fold<double>(0, (sum, e) => sum + e.amount);

    // Category breakdown
    final categorySpending = <String, double>{};
    for (final e in expenses.where((e) => e.type == TransactionType.expense)) {
      categorySpending[e.category.label] =
          (categorySpending[e.category.label] ?? 0) + e.amount;
    }
    final topCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catBreakdown = topCategories
        .map((e) => '  - ${e.key}: ${_formatMoney(e.value)}')
        .join('\n');

    // Category budgets
    String catBudgetStr = '';
    if (categoryBudgets != null && categoryBudgets.isNotEmpty) {
      catBudgetStr = '\nNgân sách theo danh mục:\n';
      for (final entry in categoryBudgets.entries) {
        final spent = categorySpending[entry.key.label] ?? 0;
        catBudgetStr +=
            '  - ${entry.key.label}: đã chi ${_formatMoney(spent)} / ${_formatMoney(entry.value)}\n';
      }
    }

    // Recent transactions (last 10)
    final recent = expenses.take(10).map((e) {
      final type = e.type == TransactionType.expense ? 'Chi' : 'Thu';
      return '  - $type ${_formatMoney(e.amount)} - ${e.title} (${e.category.label})';
    }).join('\n');

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final avgPerDay = daysPassed > 0 ? totalExpense / daysPassed : 0.0;

    return '''
Bạn là trợ lý tài chính AI thông minh, tên là "Fin" 🤖, cho ứng dụng quản lý chi tiêu Việt Nam.

QUY TẮC:
- Trả lời bằng tiếng Việt, thân thiện, có emoji
- Dùng dữ liệu tài chính bên dưới để trả lời chính xác
- Ngắn gọn (tối đa 150 từ mỗi câu trả lời)
- Đưa ra con số cụ thể, không nói chung chung
- Nếu người dùng hỏi ngoài phạm vi tài chính → nhẹ nhàng đưa về chủ đề
- Sử dụng đơn vị tiền tệ VND (đ, k, tr)

📊 DỮ LIỆU TÀI CHÍNH THÁNG ${now.month}/${now.year}:
- Tổng chi tiêu: ${_formatMoney(totalExpense)}
- Tổng thu nhập: ${_formatMoney(totalIncome)}
- Số dư hiện tại: ${_formatMoney(totalBalance)}
- Ngân sách tháng: ${monthlyBudget > 0 ? _formatMoney(monthlyBudget) : 'Chưa thiết lập'}
- Ngày đã qua: $daysPassed/$daysInMonth (còn ${daysInMonth - daysPassed} ngày)
- Chi tiêu trung bình/ngày: ${_formatMoney(avgPerDay)}
- Số giao dịch: ${expenses.length}

Chi tiêu theo danh mục:
$catBreakdown
$catBudgetStr
10 giao dịch gần nhất:
$recent
''';
  }

  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng! ☀️';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều! 🌤️';
    } else {
      greeting = 'Chào buổi tối! 🌙';
    }

    return '$greeting Mình là Fin — trợ lý tài chính AI của bạn! 🤖\n\n'
        'Mình đã nắm được tình hình chi tiêu tháng này của bạn rồi. '
        'Bạn muốn hỏi gì nào? 😊';
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '${amount.toStringAsFixed(0)}đ';
  }
}
