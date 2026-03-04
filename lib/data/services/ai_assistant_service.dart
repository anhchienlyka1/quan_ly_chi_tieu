import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/env_config.dart';
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

/// Trigger tài chính — phát hiện tình huống cần chú ý
class FinancialTrigger {
  final String type; // 'over_budget', 'near_budget', 'spike', 'fast_pace', 'saving', 'no_data', 'normal'
  final int priority; // 0 = khẩn cấp, 4 = bình thường
  final Map<String, dynamic> data; // Dữ liệu chi tiết của trigger

  const FinancialTrigger({
    required this.type,
    required this.priority,
    required this.data,
  });

  bool get isUrgent => priority <= 1;
}

/// Service trợ lý AI thông minh — chat trao đổi về tài chính.
/// Phân tích data theo tuần, phát hiện trigger, sinh welcome message chủ động.
class AiAssistantService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  static AiAssistantService? _instance;
  FinancialTrigger? _activeTrigger;

  AiAssistantService._();

  static Future<AiAssistantService> getInstance() async {
    if (_instance == null) {
      _instance = AiAssistantService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('gemini_api_key');

    if (userKey != null && userKey.isNotEmpty) {
      _model = GenerativeModel(
        model: EnvConfig.geminiModel,
        apiKey: userKey,
      );
    }
  }

  bool get isConfigured => _model != null;

  /// Trigger hiện tại — dùng để hiển thị notification dot
  FinancialTrigger? get activeTrigger => _activeTrigger;

  /// Có cảnh báo khẩn cấp không (P0/P1)?
  bool get hasUrgentAlert => _activeTrigger?.isUrgent ?? false;

  /// Câu hỏi gợi ý — thay đổi theo trigger
  List<String> get suggestedQuestions {
    if (_activeTrigger == null) return defaultQuestions;

    switch (_activeTrigger!.type) {
      case 'over_budget':
        return [
          '⚠️ Làm sao để giảm chi tiêu tuần này?',
          '📊 Phân tích chi tiết tuần này giúp tôi',
          '💡 Gợi ý cách tiết kiệm cho tuần sau',
          '🍳 Mục nào tôi có thể cắt giảm?',
        ];
      case 'near_budget':
        return [
          '🎯 Tôi nên chi tiêu bao nhiêu mỗi ngày?',
          '📊 Mục nào chiếm nhiều nhất tuần này?',
          '💡 Cho tôi lời khuyên tiết kiệm',
          '📈 So sánh tuần này với tuần trước',
        ];
      case 'spike':
        final cat = _activeTrigger!.data['spikeCategory'] ?? '';
        return [
          '📊 Tại sao mục $cat tăng tuần này?',
          '🎯 Làm sao kiểm soát chi tiêu $cat?',
          '💡 Gợi ý thay thế tiết kiệm hơn',
          '📈 Xu hướng chi tiêu tuần này',
        ];
      case 'saving':
        return [
          '🎉 Tôi đã tiết kiệm được bao nhiêu?',
          '🎯 Đặt mục tiêu tiết kiệm cho tôi',
          '📊 Chi tiết chi tuần này',
          '💡 Làm sao duy trì thói quen này?',
        ];
      default:
        return defaultQuestions;
    }
  }

  static final List<String> defaultQuestions = [
    '💰 Tình hình chi tiêu tuần này thế nào?',
    '📊 Tôi chi nhiều nhất vào mục nào?',
    '🎯 Làm sao để tiết kiệm hơn?',
    '⚠️ Tôi có đang vượt ngân sách không?',
    '📈 So sánh tuần này với tuần trước',
    '💡 Cho tôi lời khuyên tài chính',
  ];

  // ─── Session Management ──────────────────────────────────────────────────

  /// Bắt đầu phiên chat mới — phân tích trigger và tạo proactive welcome
  Future<String> startNewSession({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
  }) async {
    // 1. Phát hiện trigger
    _activeTrigger = _detectTopTrigger(
      expenses: expenses,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
    );

    // 2. Build context
    final systemContext = _buildFinancialContext(
      expenses: expenses,
      totalBalance: totalBalance,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
    );

    // 3. Build proactive welcome
    String welcomeMessage;
    if (_model != null && expenses.isNotEmpty) {
      try {
        welcomeMessage = await _generateProactiveWelcome(
          expenses: expenses,
          monthlyBudget: monthlyBudget,
        );
      } catch (e) {
        print('🤖 Proactive welcome failed: $e');
        welcomeMessage = _buildStaticWelcome(expenses, monthlyBudget);
      }
    } else {
      welcomeMessage = _buildStaticWelcome(expenses, monthlyBudget);
    }

    // 4. Start chat session
    if (_model != null) {
      _chatSession = _model!.startChat(history: [
        Content.text(systemContext),
        Content.model([TextPart(welcomeMessage)]),
      ]);
    }

    return welcomeMessage;
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

  // ─── Weekly Analysis ──────────────────────────────────────────────────────

  /// Tính thống kê tuần hiện tại và tuần trước
  Map<String, dynamic> _getWeeklyStats(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final startOfLastWeek = startOfWeekDate.subtract(const Duration(days: 7));

    final thisWeekExpenses = expenses.where((e) =>
        e.type == TransactionType.expense &&
        e.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1))));
    final lastWeekExpenses = expenses.where((e) =>
        e.type == TransactionType.expense &&
        e.date.isAfter(startOfLastWeek.subtract(const Duration(seconds: 1))) &&
        e.date.isBefore(startOfWeekDate));

    final thisWeekTotal = thisWeekExpenses.fold<double>(0, (s, e) => s + e.amount);
    final lastWeekTotal = lastWeekExpenses.fold<double>(0, (s, e) => s + e.amount);

    // Category breakdown tuần này
    final weekCategorySpending = <String, double>{};
    for (final e in thisWeekExpenses) {
      weekCategorySpending[e.category.label] =
          (weekCategorySpending[e.category.label] ?? 0) + e.amount;
    }
    final topWeekCategories = weekCategorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Category breakdown tuần trước
    final lastWeekCategorySpending = <String, double>{};
    for (final e in lastWeekExpenses) {
      lastWeekCategorySpending[e.category.label] =
          (lastWeekCategorySpending[e.category.label] ?? 0) + e.amount;
    }

    final dayOfWeek = now.weekday; // 1=Mon, 7=Sun
    final daysRemaining = 7 - dayOfWeek;

    return {
      'thisWeekTotal': thisWeekTotal,
      'lastWeekTotal': lastWeekTotal,
      'weekCategorySpending': weekCategorySpending,
      'lastWeekCategorySpending': lastWeekCategorySpending,
      'topWeekCategories': topWeekCategories,
      'dayOfWeek': dayOfWeek,
      'daysRemaining': daysRemaining,
      'thisWeekCount': thisWeekExpenses.length,
      'avgPerDay': dayOfWeek > 0 ? thisWeekTotal / dayOfWeek : 0.0,
    };
  }

  // ─── Trigger Detection ────────────────────────────────────────────────────

  FinancialTrigger _detectTopTrigger({
    required List<ExpenseModel> expenses,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
  }) {
    final triggers = <FinancialTrigger>[];
    final weekStats = _getWeeklyStats(expenses);
    final weeklyBudget = monthlyBudget > 0 ? monthlyBudget / 4 : 0.0;
    final thisWeekTotal = weekStats['thisWeekTotal'] as double;
    final lastWeekTotal = weekStats['lastWeekTotal'] as double;

    if (expenses.isEmpty || expenses.where((e) => e.type == TransactionType.expense).isEmpty) {
      return FinancialTrigger(
        type: 'no_data',
        priority: 3,
        data: {'message': 'Chưa có giao dịch'},
      );
    }

    // 🔴 P0: Vượt ngân sách tuần
    if (weeklyBudget > 0 && thisWeekTotal > weeklyBudget) {
      final overPercent = ((thisWeekTotal / weeklyBudget - 1) * 100).round();
      triggers.add(FinancialTrigger(
        type: 'over_budget',
        priority: 0,
        data: {
          'weeklyBudget': weeklyBudget,
          'spent': thisWeekTotal,
          'overPercent': overPercent,
          'topCategory': (weekStats['topWeekCategories'] as List).isNotEmpty
              ? (weekStats['topWeekCategories'] as List).first.key
              : '',
          'topCategoryAmount': (weekStats['topWeekCategories'] as List).isNotEmpty
              ? (weekStats['topWeekCategories'] as List).first.value
              : 0.0,
        },
      ));
    }

    // 🟠 P1: Gần vượt ngân sách tuần (>80%, còn >2 ngày)
    if (weeklyBudget > 0 &&
        thisWeekTotal > weeklyBudget * 0.8 &&
        thisWeekTotal <= weeklyBudget &&
        (weekStats['daysRemaining'] as int) > 2) {
      triggers.add(FinancialTrigger(
        type: 'near_budget',
        priority: 1,
        data: {
          'weeklyBudget': weeklyBudget,
          'spent': thisWeekTotal,
          'percentUsed': (thisWeekTotal / weeklyBudget * 100).round(),
          'daysRemaining': weekStats['daysRemaining'],
        },
      ));
    }

    // 🟡 P2: Category tăng đột biến so với tuần trước
    final weekCatSpending = weekStats['weekCategorySpending'] as Map<String, double>;
    final lastWeekCatSpending = weekStats['lastWeekCategorySpending'] as Map<String, double>;
    for (final cat in weekCatSpending.keys) {
      final thisWeek = weekCatSpending[cat] ?? 0;
      final lastWeek = lastWeekCatSpending[cat] ?? 0;
      if (lastWeek > 0 && thisWeek > lastWeek * 1.5 && thisWeek > 100000) {
        triggers.add(FinancialTrigger(
          type: 'spike',
          priority: 2,
          data: {
            'spikeCategory': cat,
            'thisWeekAmount': thisWeek,
            'lastWeekAmount': lastWeek,
            'increasePercent': ((thisWeek / lastWeek - 1) * 100).round(),
          },
        ));
        break; // Chỉ lấy 1 spike quan trọng nhất
      }
    }

    // 🔵 P2: Tốc độ chi nhanh (TB/ngày tuần này > tuần trước 30%+)
    final avgThisWeek = weekStats['avgPerDay'] as double;
    final dayOfWeek = weekStats['dayOfWeek'] as int;
    if (lastWeekTotal > 0 && dayOfWeek >= 3) {
      final avgLastWeek = lastWeekTotal / 7;
      if (avgThisWeek > avgLastWeek * 1.3) {
        triggers.add(FinancialTrigger(
          type: 'fast_pace',
          priority: 2,
          data: {
            'avgThisWeek': avgThisWeek,
            'avgLastWeek': avgLastWeek,
            'increasePercent': ((avgThisWeek / avgLastWeek - 1) * 100).round(),
          },
        ));
      }
    }

    // 🟢 P3: Tuần tiết kiệm tốt
    if (weeklyBudget > 0 &&
        thisWeekTotal < weeklyBudget * 0.6 &&
        dayOfWeek >= 4) {
      final saved = weeklyBudget - thisWeekTotal;
      triggers.add(FinancialTrigger(
        type: 'saving',
        priority: 3,
        data: {
          'weeklyBudget': weeklyBudget,
          'spent': thisWeekTotal,
          'saved': saved,
          'projectedMonthlySave': saved * 4,
        },
      ));
    }

    // Sort by priority — lấy P cao nhất
    triggers.sort((a, b) => a.priority.compareTo(b.priority));

    return triggers.isNotEmpty
        ? triggers.first
        : const FinancialTrigger(type: 'normal', priority: 4, data: {});
  }

  // ─── Proactive Welcome Message ────────────────────────────────────────────

  Future<String> _generateProactiveWelcome({
    required List<ExpenseModel> expenses,
    required double monthlyBudget,
  }) async {
    final trigger = _activeTrigger!;
    final weekStats = _getWeeklyStats(expenses);
    final greeting = _greetingByTime();

    String triggerContext;
    switch (trigger.type) {
      case 'over_budget':
        triggerContext = '''
TRIGGER: Vượt ngân sách tuần!
- Đã chi: ${_formatMoney(trigger.data['spent'])} / Ngân sách tuần: ${_formatMoney(trigger.data['weeklyBudget'])}
- Vượt ${trigger.data['overPercent']}%
- Category cao nhất: ${trigger.data['topCategory']} (${_formatMoney(trigger.data['topCategoryAmount'])})
TONE: Trách móc vui nhộn, hài hước như bạn thân. Ví dụ: "Ơi, lại tiêu quá tay rồi! 😭" hoặc "Túi tiền kêu cứu rồi nè!". Sau đó đưa ra gợi ý cụ thể để cắt giảm, giữ giọng điệu nhẹ nhàng không phán xét.
''';
      case 'near_budget':
        triggerContext = '''
TRIGGER: Gần vượt ngân sách tuần
- Đã chi: ${_formatMoney(trigger.data['spent'])} / Ngân sách tuần: ${_formatMoney(trigger.data['weeklyBudget'])} (${trigger.data['percentUsed']}%)
- Còn ${trigger.data['daysRemaining']} ngày
TONE: Quan tâm, gợi ý kiểm soát chi tiêu những ngày còn lại
''';
      case 'spike':
        triggerContext = '''
TRIGGER: Category "${trigger.data['spikeCategory']}" tăng đột biến
- Tuần này: ${_formatMoney(trigger.data['thisWeekAmount'])} vs tuần trước: ${_formatMoney(trigger.data['lastWeekAmount'])} (+${trigger.data['increasePercent']}%)
TONE: Tò mò, hỏi nhẹ nhàng, không phán xét
''';
      case 'saving':
        triggerContext = '''
TRIGGER: Tuần tiết kiệm tốt!
- Mới chi ${_formatMoney(trigger.data['spent'])} / ${_formatMoney(trigger.data['weeklyBudget'])} ngân sách tuần
- Tiết kiệm được: ${_formatMoney(trigger.data['saved'])}
- Dự kiến tiết kiệm tháng: ${_formatMoney(trigger.data['projectedMonthlySave'])}
TONE: Khen ngợi, động viên, tích cực
''';
      case 'fast_pace':
        triggerContext = '''
TRIGGER: Tốc độ chi nhanh hơn tuần trước
- TB/ngày tuần này: ${_formatMoney(trigger.data['avgThisWeek'])} vs tuần trước: ${_formatMoney(trigger.data['avgLastWeek'])} (+${trigger.data['increasePercent']}%)
TONE: Nhắc nhở nhẹ, gợi ý chậm lại
''';
      default:
        triggerContext = 'TRIGGER: Bình thường — chào hỏi vui vẻ, casual';
    }

    final prompt = '''
Bạn là Fin — trợ lý tài chính AI. Hãy tạo tin nhắn chào hỏi chủ động dựa trên trigger.

$greeting

$triggerContext

Chi tiêu tuần này: ${_formatMoney(weekStats['thisWeekTotal'])}
Tuần trước: ${_formatMoney(weekStats['lastWeekTotal'])}
Số giao dịch tuần: ${weekStats['thisWeekCount']}

YÊU CẦU:
- Bắt đầu bằng lời chào phù hợp thời gian trong ngày
- Tự giới thiệu ngắn: "Mình là Fin"
- Đi thẳng vào insight chính dựa trên trigger
- Đưa con số cụ thể (tiền VND dạng k, tr)
- 3-4 câu, tối đa 80 từ
- Kết bằng câu hỏi mở hoặc gợi ý
- Emoji vừa phải, tự nhiên
- Tiếng Việt thân thiện như bạn bè
- Plain text, không markdown
''';

    final response = await _model!.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) throw Exception('Empty response');
    return text.trim();
  }

  /// Fallback welcome message khi AI không khả dụng
  String _buildStaticWelcome(List<ExpenseModel> expenses, double monthlyBudget) {
    final greeting = _greetingByTime();
    final trigger = _activeTrigger;

    if (trigger == null || expenses.isEmpty) {
      return '$greeting Mình là Fin — trợ lý tài chính AI của bạn! 🤖\n\n'
          'Hãy bắt đầu ghi chi tiêu để mình giúp bạn phân tích nhé! 😊';
    }

    switch (trigger.type) {
      case 'over_budget':
        return '$greeting Mình là Fin! 🤖\n\n'
            'Ơi bạn ơi, tuần này chi ${_formatMoney(trigger.data['spent'])} rồi — '
            'vượt ngân sách tuần ${_formatMoney(trigger.data['weeklyBudget'])} mất rồi nè! 😭 '
            'Mục "${trigger.data['topCategory']}" là "thủ phạm" chính đó. '
            'Túi tiền đang kêu cứu kìa! 😅';
      case 'near_budget':
        return '$greeting Mình là Fin! 🤖\n\n'
            '📊 Bạn đã dùng ${trigger.data['percentUsed']}% ngân sách tuần, '
            'còn ${trigger.data['daysRemaining']} ngày. Cố gắng kiểm soát nhé! 💪';
      case 'saving':
        return '$greeting Mình là Fin! 🤖\n\n'
            '🎉 Tuyệt vời! Tuần này bạn chỉ chi ${_formatMoney(trigger.data['spent'])} / '
            '${_formatMoney(trigger.data['weeklyBudget'])} ngân sách. '
            'Tiết kiệm được ${_formatMoney(trigger.data['saved'])}! Tiếp tục nhé! 💪';
      default:
        return '$greeting Mình là Fin — trợ lý tài chính AI! 🤖\n\n'
            'Mình đã phân tích chi tiêu tuần này rồi. Bạn muốn hỏi gì nào? 😊';
    }
  }

  // ─── Financial Context ────────────────────────────────────────────────────

  String _buildFinancialContext({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
  }) {
    final now = DateTime.now();
    final weekStats = _getWeeklyStats(expenses);
    final totalExpense = expenses
        .where((e) => e.type == TransactionType.expense)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = expenses
        .where((e) => e.type == TransactionType.income)
        .fold<double>(0, (sum, e) => sum + e.amount);

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

    String catBudgetStr = '';
    if (categoryBudgets != null && categoryBudgets.isNotEmpty) {
      catBudgetStr = '\nNgân sách theo danh mục:\n';
      for (final entry in categoryBudgets.entries) {
        final spent = categorySpending[entry.key.label] ?? 0;
        catBudgetStr +=
            '  - ${entry.key.label}: đã chi ${_formatMoney(spent)} / ${_formatMoney(entry.value)}\n';
      }
    }

    final recent = expenses.take(10).map((e) {
      final type = e.type == TransactionType.expense ? 'Chi' : 'Thu';
      return '  - $type ${_formatMoney(e.amount)} - ${e.title} (${e.category.label})';
    }).join('\n');

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weeklyBudget = monthlyBudget > 0 ? monthlyBudget / 4 : 0;

    // Week category breakdown
    final weekCatBreakdown = (weekStats['topWeekCategories'] as List)
        .take(5)
        .map((e) => '  - ${e.key}: ${_formatMoney(e.value)}')
        .join('\n');

    return '''
Bạn là trợ lý tài chính AI thông minh, tên là "Fin" 🤖, cho ứng dụng quản lý chi tiêu Việt Nam.

QUY TẮC:
- Trả lời bằng tiếng Việt, thân thiện, có emoji
- Dùng dữ liệu bên dưới để trả lời chính xác
- Ngắn gọn (tối đa 150 từ)
- Đưa con số cụ thể, không nói chung chung
- Phân tích theo TUẦN là ưu tiên chính
- Nếu hỏi ngoài tài chính → nhẹ nhàng đưa về chủ đề
- Đơn vị VND: đ, k, tr

📊 THÁNG ${now.month}/${now.year}:
- Tổng chi: ${_formatMoney(totalExpense)} | Thu: ${_formatMoney(totalIncome)}
- Số dư: ${_formatMoney(totalBalance)}
- Ngân sách tháng: ${monthlyBudget > 0 ? _formatMoney(monthlyBudget) : 'Chưa thiết lập'}
- Ngày: ${now.day}/$daysInMonth

📅 TUẦN NÀY (ưu tiên phân tích theo tuần):
- Chi tuần: ${_formatMoney(weekStats['thisWeekTotal'])}
- Tuần trước: ${_formatMoney(weekStats['lastWeekTotal'])}
- Ngân sách tuần: ${weeklyBudget > 0 ? _formatMoney(weeklyBudget) : 'N/A'}
- TB/ngày: ${_formatMoney(weekStats['avgPerDay'])}
- GD tuần: ${weekStats['thisWeekCount']}
- Chi theo mục tuần:
$weekCatBreakdown

Chi tiêu tháng theo danh mục:
$catBreakdown
$catBudgetStr
10 giao dịch gần nhất:
$recent
''';
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng! ☀️';
    if (hour < 18) return 'Chào buổi chiều! 🌤️';
    return 'Chào buổi tối! 🌙';
  }

  String _formatMoney(dynamic amount) {
    final val = (amount is int) ? amount.toDouble() : (amount as double);
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}tr';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return '${val.toStringAsFixed(0)}đ';
  }
}
