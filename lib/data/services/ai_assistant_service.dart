import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/env_config.dart';
import '../models/expense_model.dart';
import '../models/goal_model.dart';
import '../models/smart_suggestion_model.dart';
import 'local_storage_service.dart';

/// Loại hành động AI có thể gợi ý
enum AiAction {
  addExpense,
  setBudget,
  showStats,
  viewExpenses,
  none;

  String get label {
    switch (this) {
      case AiAction.addExpense:
        return 'Thêm chi tiêu';
      case AiAction.setBudget:
        return 'Đặt ngân sách';
      case AiAction.showStats:
        return 'Xem thống kê';
      case AiAction.viewExpenses:
        return 'Xem giao dịch';
      case AiAction.none:
        return '';
    }
  }

  IconData get icon {
    switch (this) {
      case AiAction.addExpense:
        return Icons.add_circle_outline_rounded;
      case AiAction.setBudget:
        return Icons.savings_outlined;
      case AiAction.showStats:
        return Icons.pie_chart_outline_rounded;
      case AiAction.viewExpenses:
        return Icons.receipt_long_outlined;
      case AiAction.none:
        return Icons.circle;
    }
  }

  String get routeName {
    switch (this) {
      case AiAction.addExpense:
        return '/add-expense';
      case AiAction.setBudget:
        return '/budget';
      case AiAction.showStats:
        return '/statistics';
      case AiAction.viewExpenses:
        return '/expenses';
      case AiAction.none:
        return '/';
    }
  }
}

/// Response từ AI — bao gồm text + danh sách action gợi ý
class AiResponse {
  final String text;
  final List<AiAction> actions;

  const AiResponse({required this.text, this.actions = const []});
}

/// Tin nhắn trong cuộc hội thoại AI
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AiAction> actions;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actions = const [],
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<AiAction>? actions,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      actions: actions ?? this.actions,
    );
  }
}

/// Trigger tài chính — phát hiện tình huống cần chú ý
class FinancialTrigger {
  final String
  type; // 'over_budget', 'near_budget', 'spike', 'fast_pace', 'saving', 'no_data', 'normal'
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
    // Nếu instance tồn tại nhưng chưa configured → reset và thử lại
    if (_instance != null && !_instance!.isConfigured) {
      _instance = null;
    }
    if (_instance == null) {
      _instance = AiAssistantService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Reset singleton — gọi khi user thay đổi API key
  static void resetInstance() {
    _instance = null;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('gemini_api_key');
    final envKey = EnvConfig.geminiApiKey;

    print(
      '🤖 AI Init — userKey: ${userKey != null ? "${userKey.substring(0, 8)}..." : "null"}, envKey: ${envKey.isNotEmpty ? "${envKey.substring(0, 8)}..." : "empty"}',
    );

    // Ưu tiên key từ user (SharedPreferences), fallback sang .env
    final apiKey = (userKey != null && userKey.isNotEmpty) ? userKey : envKey;

    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(model: EnvConfig.geminiModel, apiKey: apiKey);
      print('🤖 AI Model initialized with key: ${apiKey.substring(0, 8)}...');
    } else {
      print('🤖 AI Model NOT initialized — no API key found!');
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
  Future<AiResponse> startNewSession({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
    FinancialGoal? goal,
    List<SmartSuggestion>? suggestions,
  }) async {
    // 1. Phát hiện trigger
    _activeTrigger = detectTopTrigger(
      expenses: expenses,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
    );

    // 2. Build context
    final systemContext = await _buildFinancialContext(
      expenses: expenses,
      totalBalance: totalBalance,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
      goal: goal,
      suggestions: suggestions,
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
      _chatSession = _model!.startChat(
        history: [
          Content.text(systemContext),
          Content.model([TextPart(welcomeMessage)]),
        ],
      );
    }

    // 5. Parse actions from welcome message
    final actions = parseActionsFromText(welcomeMessage);
    return AiResponse(text: welcomeMessage, actions: actions);
  }

  /// Gửi tin nhắn và nhận phản hồi từ AI (dạng stream)
  Stream<String> sendMessageStream(String userMessage) async* {
    if (_chatSession == null) {
      yield '⚠️ Lỗi: Chưa bắt đầu phiên chat.';
      return;
    }

    try {
      final responseStream = _chatSession!.sendMessageStream(
        Content.text(userMessage),
      );
      await for (final chunk in responseStream) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      print('🤖 Lỗi khi streaming tin nhắn: $e');
      yield '\n⚠️ Xin lỗi, có lỗi hiển thị tin nhắn. Vui lòng thử lại sau.';
    }
  }

  /// Gửi tin nhắn và nhận phản hồi từ AI (không stream)
  Future<AiResponse> sendMessage(String userMessage) async {
    if (_chatSession == null) {
      return const AiResponse(
        text: 'Chưa kết nối được AI. Vui lòng kiểm tra API key trong Cài đặt.',
      );
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return const AiResponse(
          text: 'Xin lỗi, mình không hiểu. Bạn có thể hỏi lại được không?',
        );
      }

      final trimmed = text.trim();
      final actions = parseActionsFromText(trimmed);
      return AiResponse(text: trimmed, actions: actions);
    } catch (e) {
      print('🤖 AI chat error: $e');
      return const AiResponse(
        text: 'Đã có lỗi xảy ra. Vui lòng thử lại sau nhé! 🙏',
      );
    }
  }

  /// Phân tích text AI để detect action gợi ý
  List<AiAction> parseActionsFromText(String text) {
    final lower = text.toLowerCase();
    final actions = <AiAction>[];

    if (lower.contains('đặt ngân sách') ||
        lower.contains('thiết lập ngân sách') ||
        lower.contains('ngân sách') && lower.contains('chưa')) {
      actions.add(AiAction.setBudget);
    }
    if (lower.contains('thêm chi tiêu') ||
        lower.contains('ghi chi tiêu') ||
        lower.contains('ghi lại chi')) {
      actions.add(AiAction.addExpense);
    }
    if (lower.contains('xem thống kê') ||
        lower.contains('xem báo cáo') ||
        lower.contains('biểu đồ') ||
        lower.contains('phân tích chi tiết')) {
      actions.add(AiAction.showStats);
    }
    if (lower.contains('xem giao dịch') ||
        lower.contains('lịch sử') ||
        lower.contains('danh sách chi tiêu')) {
      actions.add(AiAction.viewExpenses);
    }

    return actions;
  }

  /// Lưu tóm tắt phiên chat — gọi khi user đóng popup
  Future<void> saveSessionSummary(List<ChatMessage> messages) async {
    if (messages.length < 3 || _model == null) return; // quá ít để tóm tắt

    try {
      // Tạo transcript ngắn cho AI tóm tắt
      final transcript = messages
          .map((m) => '${m.isUser ? "User" : "Fin"}: ${m.text}')
          .join('\n');

      final prompt =
          '''
Hãy tóm tắt cuộc hội thoại tài chính dưới đây trong 3-5 câu tiếng Việt.
Chỉ giữ lại thông tin quan trọng: insight tài chính, lời khuyên đã đưa, quyết định của user.
Không dùng markdown. Plain text ngắn gọn.

CUỘC HỘI THOẠI:
$transcript
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final summary = response.text?.trim();

      if (summary != null && summary.isNotEmpty) {
        final localStorage = await LocalStorageService.getInstance();
        await localStorage.saveConversationSummary(summary);

        await localStorage.saveChatSession(
          messages,
          messages.first.timestamp,
          summary,
        );
        print('🤖 Session summary saved (${summary.length} chars)');
      }
    } catch (e) {
      print('🤖 Failed to save session summary: $e');
    }
  }

  // ─── Weekly Analysis ──────────────────────────────────────────────────────

  /// Tính thống kê tuần hiện tại và tuần trước
  Map<String, dynamic> getWeeklyStats(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final startOfLastWeek = startOfWeekDate.subtract(const Duration(days: 7));

    final thisWeekExpenses = expenses.where(
      (e) =>
          e.type == TransactionType.expense &&
          e.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1))),
    );
    final lastWeekExpenses = expenses.where(
      (e) =>
          e.type == TransactionType.expense &&
          e.date.isAfter(
            startOfLastWeek.subtract(const Duration(seconds: 1)),
          ) &&
          e.date.isBefore(startOfWeekDate),
    );

    final thisWeekTotal = thisWeekExpenses.fold<double>(
      0,
      (s, e) => s + e.amount,
    );
    final lastWeekTotal = lastWeekExpenses.fold<double>(
      0,
      (s, e) => s + e.amount,
    );

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

  FinancialTrigger detectTopTrigger({
    required List<ExpenseModel> expenses,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
  }) {
    final triggers = <FinancialTrigger>[];
    final weekStats = getWeeklyStats(expenses);
    final weeklyBudget = monthlyBudget > 0 ? monthlyBudget / 4 : 0.0;
    final thisWeekTotal = weekStats['thisWeekTotal'] as double;
    final lastWeekTotal = weekStats['lastWeekTotal'] as double;

    if (expenses.isEmpty ||
        expenses.where((e) => e.type == TransactionType.expense).isEmpty) {
      return FinancialTrigger(
        type: 'no_data',
        priority: 3,
        data: {'message': 'Chưa có giao dịch'},
      );
    }

    // 🔴 P0: Vượt ngân sách tuần
    if (weeklyBudget > 0 && thisWeekTotal > weeklyBudget) {
      final overPercent = ((thisWeekTotal / weeklyBudget - 1) * 100).round();
      triggers.add(
        FinancialTrigger(
          type: 'over_budget',
          priority: 0,
          data: {
            'weeklyBudget': weeklyBudget,
            'spent': thisWeekTotal,
            'overPercent': overPercent,
            'topCategory': (weekStats['topWeekCategories'] as List).isNotEmpty
                ? (weekStats['topWeekCategories'] as List).first.key
                : '',
            'topCategoryAmount':
                (weekStats['topWeekCategories'] as List).isNotEmpty
                ? (weekStats['topWeekCategories'] as List).first.value
                : 0.0,
          },
        ),
      );
    }

    // 🟠 P1: Gần vượt ngân sách tuần (>80%, còn >2 ngày)
    if (weeklyBudget > 0 &&
        thisWeekTotal > weeklyBudget * 0.8 &&
        thisWeekTotal <= weeklyBudget &&
        (weekStats['daysRemaining'] as int) > 2) {
      triggers.add(
        FinancialTrigger(
          type: 'near_budget',
          priority: 1,
          data: {
            'weeklyBudget': weeklyBudget,
            'spent': thisWeekTotal,
            'percentUsed': (thisWeekTotal / weeklyBudget * 100).round(),
            'daysRemaining': weekStats['daysRemaining'],
          },
        ),
      );
    }

    // 🟡 P2: Category tăng đột biến so với tuần trước
    final weekCatSpending =
        weekStats['weekCategorySpending'] as Map<String, double>;
    final lastWeekCatSpending =
        weekStats['lastWeekCategorySpending'] as Map<String, double>;
    for (final cat in weekCatSpending.keys) {
      final thisWeek = weekCatSpending[cat] ?? 0;
      final lastWeek = lastWeekCatSpending[cat] ?? 0;
      if (lastWeek > 0 && thisWeek > lastWeek * 1.5 && thisWeek > 100000) {
        triggers.add(
          FinancialTrigger(
            type: 'spike',
            priority: 2,
            data: {
              'spikeCategory': cat,
              'thisWeekAmount': thisWeek,
              'lastWeekAmount': lastWeek,
              'increasePercent': ((thisWeek / lastWeek - 1) * 100).round(),
            },
          ),
        );
        break; // Chỉ lấy 1 spike quan trọng nhất
      }
    }

    // 🔵 P2: Tốc độ chi nhanh (TB/ngày tuần này > tuần trước 30%+)
    final avgThisWeek = weekStats['avgPerDay'] as double;
    final dayOfWeek = weekStats['dayOfWeek'] as int;
    if (lastWeekTotal > 0 && dayOfWeek >= 3) {
      final avgLastWeek = lastWeekTotal / 7;
      if (avgThisWeek > avgLastWeek * 1.3) {
        triggers.add(
          FinancialTrigger(
            type: 'fast_pace',
            priority: 2,
            data: {
              'avgThisWeek': avgThisWeek,
              'avgLastWeek': avgLastWeek,
              'increasePercent': ((avgThisWeek / avgLastWeek - 1) * 100)
                  .round(),
            },
          ),
        );
      }
    }

    // 🟢 P3: Tuần tiết kiệm tốt
    if (weeklyBudget > 0 &&
        thisWeekTotal < weeklyBudget * 0.6 &&
        dayOfWeek >= 4) {
      final saved = weeklyBudget - thisWeekTotal;
      triggers.add(
        FinancialTrigger(
          type: 'saving',
          priority: 3,
          data: {
            'weeklyBudget': weeklyBudget,
            'spent': thisWeekTotal,
            'saved': saved,
            'projectedMonthlySave': saved * 4,
          },
        ),
      );
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
    final weekStats = getWeeklyStats(expenses);
    final greeting = _greetingByTime();

    String triggerContext;
    switch (trigger.type) {
      case 'over_budget':
        triggerContext =
            '''
TRIGGER: Vượt ngân sách tuần!
- Đã chi: ${_formatMoney(trigger.data['spent'])} / Ngân sách tuần: ${_formatMoney(trigger.data['weeklyBudget'])}
- Vượt ${trigger.data['overPercent']}%
- Category cao nhất: ${trigger.data['topCategory']} (${_formatMoney(trigger.data['topCategoryAmount'])})
TONE: Trách móc vui nhộn, hài hước như bạn thân. Ví dụ: "Ơi, lại tiêu quá tay rồi! 😭" hoặc "Túi tiền kêu cứu rồi nè!". Sau đó đưa ra gợi ý cụ thể để cắt giảm, giữ giọng điệu nhẹ nhàng không phán xét.
''';
      case 'near_budget':
        triggerContext =
            '''
TRIGGER: Gần vượt ngân sách tuần
- Đã chi: ${_formatMoney(trigger.data['spent'])} / Ngân sách tuần: ${_formatMoney(trigger.data['weeklyBudget'])} (${trigger.data['percentUsed']}%)
- Còn ${trigger.data['daysRemaining']} ngày
TONE: Quan tâm, gợi ý kiểm soát chi tiêu những ngày còn lại
''';
      case 'spike':
        triggerContext =
            '''
TRIGGER: Category "${trigger.data['spikeCategory']}" tăng đột biến
- Tuần này: ${_formatMoney(trigger.data['thisWeekAmount'])} vs tuần trước: ${_formatMoney(trigger.data['lastWeekAmount'])} (+${trigger.data['increasePercent']}%)
TONE: Tò mò, hỏi nhẹ nhàng, không phán xét
''';
      case 'saving':
        triggerContext =
            '''
TRIGGER: Tuần tiết kiệm tốt!
- Mới chi ${_formatMoney(trigger.data['spent'])} / ${_formatMoney(trigger.data['weeklyBudget'])} ngân sách tuần
- Tiết kiệm được: ${_formatMoney(trigger.data['saved'])}
- Dự kiến tiết kiệm tháng: ${_formatMoney(trigger.data['projectedMonthlySave'])}
TONE: Khen ngợi, động viên, tích cực. Hãy nhắc nhẹ về dự báo chi tiêu cuối tháng nằm trong ngữ cảnh.
''';
      case 'fast_pace':
        triggerContext =
            '''
TRIGGER: Tốc độ chi nhanh hơn tuần trước
- TB/ngày tuần này: ${_formatMoney(trigger.data['avgThisWeek'])} vs tuần trước: ${_formatMoney(trigger.data['avgLastWeek'])} (+${trigger.data['increasePercent']}%)
TONE: Nhắc nhở nhẹ, gợi ý chậm lại
''';
      default:
        triggerContext =
            'TRIGGER: Bình thường — chào hỏi vui vẻ, casual. Dựa vào "DỰ BÁO CUỐI THÁNG" trong ngữ cảnh, hãy nhắc nhẹ người dùng (Ví dụ: "Tháng này dự kiến chi tiêu đang trong tầm kiểm soát" hoặc "Có vẻ hơi lố, cẩn thận nhé").';
    }

    final prompt =
        '''
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
  String _buildStaticWelcome(
    List<ExpenseModel> expenses,
    double monthlyBudget,
  ) {
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

  Future<String> _buildFinancialContext({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
    FinancialGoal? goal,
    List<SmartSuggestion>? suggestions,
  }) async {
    final now = DateTime.now();
    final weekStats = getWeeklyStats(expenses);
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

    final recent = expenses
        .take(10)
        .map((e) {
          final type = e.type == TransactionType.expense ? 'Chi' : 'Thu';
          return '  - $type ${_formatMoney(e.amount)} - ${e.title} (${e.category.label})';
        })
        .join('\n');

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weeklyBudget = monthlyBudget > 0 ? monthlyBudget / 4 : 0;

    // Week category breakdown
    final weekCatBreakdown = (weekStats['topWeekCategories'] as List)
        .take(5)
        .map((e) => '  - ${e.key}: ${_formatMoney(e.value)}')
        .join('\n');

    // Inject conversation memory from previous session
    String conversationMemory = '';
    try {
      final localStorage = await LocalStorageService.getInstance();
      final previousSummary = localStorage.getConversationSummary();
      if (previousSummary != null && previousSummary.isNotEmpty) {
        conversationMemory =
            '''

📝 LỊCH SỬ TÓM TẮT (các phiên trước):
$previousSummary
→ Hãy tham khảo để trả lời liền mạch, tự nhiên. Không cần nhắc lại toàn bộ.
''';
      }

      // Inject feedback tone tuning
      final negRate = localStorage.feedbackNegativeRate;
      if (negRate > 0.3) {
        conversationMemory +=
            '\n⚡ LƯU Ý: User đã đánh giá tiêu cực ${(negRate * 100).round()}% — hãy giải thích chi tiết hơn, rõ ràng hơn, dùng ví dụ cụ thể.\n';
      }
    } catch (e) {
      print('🤖 Failed to load conversation summary: $e');
    }

    String suggestionsContext = '';
    if (suggestions != null && suggestions.isNotEmpty) {
      suggestionsContext =
          '\n💡 GỢI Ý THÔNG MINH VỪA PHÁT HIỆN:\n${suggestions
              .map((s) => '- [${s.type.name}] ${s.title}: ${s.description}')
              .join('\n')}\n→ Hãy linh hoạt đề cập đến những gợi ý này nếu phù hợp.\n';
    }

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
$conversationMemory
📊 THÁNG ${now.month}/${now.year}:
- Tổng chi: ${_formatMoney(totalExpense)} | Thu: ${_formatMoney(totalIncome)}
- Số dư: ${_formatMoney(totalBalance)}
- Ngân sách tháng: ${monthlyBudget > 0 ? _formatMoney(monthlyBudget) : 'Chưa thiết lập'}
- Ngày: ${now.day}/$daysInMonth
$suggestionsContext
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
${_buildGoalContext(goal)}
${buildSpendingForecast(totalExpense, monthlyBudget, now)}
''';
  }

  // ─── Goal & Forecast Context ────────────────────────────────────────────

  /// Build context string for financial goal
  String _buildGoalContext(FinancialGoal? goal) {
    if (goal == null) return '';

    final progressPercent = (goal.progress * 100).toStringAsFixed(0);
    final deadlineStr = goal.deadline != null
        ? '${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}'
        : 'Chưa đặt';

    return '''

🎯 MỤC TIÊU TÀI CHÍNH:
- Tên: ${goal.title}
- Mục tiêu: ${_formatMoney(goal.targetAmount)}
- Đã tiết kiệm: ${_formatMoney(goal.savedAmount)} ($progressPercent%)
- Còn thiếu: ${_formatMoney(goal.remainingAmount)}
- Deadline: $deadlineStr
${goal.isAchieved ? '🎉 ĐÃ ĐẠT MỤC TIÊU!' : ''}
→ Hãy khuyến khích user đạt mục tiêu khi phù hợp.
''';
  }

  /// Build spending forecast for end of month
  String buildSpendingForecast(
    double totalExpense,
    double monthlyBudget,
    DateTime now,
  ) {
    if (now.day < 3) return ''; // Too early to forecast

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;
    final avgPerDay = daysPassed > 0 ? totalExpense / daysPassed : 0.0;
    final projectedTotal = totalExpense + (avgPerDay * daysRemaining);

    final dailyRemaining = monthlyBudget > 0 && daysRemaining > 0
        ? (monthlyBudget - totalExpense) / daysRemaining
        : 0.0;

    String projectedWarning = '';
    if (monthlyBudget > 0) {
      final projPercent = (projectedTotal / monthlyBudget * 100).round();
      if (projPercent > 120) {
        projectedWarning = '⚠️ Dự kiến VƯỢT ngân sách ${projPercent - 100}%!';
      } else if (projPercent > 100) {
        projectedWarning = '🟠 Có nguy cơ vượt ngân sách nhẹ';
      } else {
        projectedWarning = '✅ Đang trong ngân sách';
      }
    }

    return '''

📈 DỰ BÁO CUỐI THÁNG:
- TB chi/ngày: ${_formatMoney(avgPerDay)}
- Dự kiến tổng chi: ${_formatMoney(projectedTotal)}
${monthlyBudget > 0 ? '- Còn lại có thể chi/ngày: ${dailyRemaining > 0 ? _formatMoney(dailyRemaining) : '0đ (đã hết)'}' : ''}
$projectedWarning
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
