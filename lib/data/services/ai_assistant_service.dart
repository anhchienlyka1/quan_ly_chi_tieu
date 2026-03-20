import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/env_config.dart';
import '../models/expense_model.dart';
import '../models/goal_model.dart';
import '../models/smart_suggestion_model.dart';
import 'cloudflare_ai_service.dart';
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
/// Sử dụng Cloudflare Workers AI làm backend.
class AiAssistantService {
  CloudflareAIService? _cfService;
  /// Lịch sử hội thoại dùng để gửi lên Cloudflare Workers AI
  List<Map<String, String>> _chatHistory = [];
  /// System prompt được inject một lần duy nhất khi bắt đầu session
  String? _systemPrompt;

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
    // Hỗ trợ override token/accountId từ SharedPreferences
    final userToken = prefs.getString('cloudflare_api_token');
    final userAccountId = prefs.getString('cloudflare_account_id');

    final token = (userToken != null && userToken.isNotEmpty)
        ? userToken
        : EnvConfig.cloudflareApiToken;
    final accountId = (userAccountId != null && userAccountId.isNotEmpty)
        ? userAccountId
        : EnvConfig.cloudflareAccountId;

    print(
      '🤖 CloudflareAI Init — token: ${token.isNotEmpty ? "${token.substring(0, 8)}..." : "empty"}, accountId: ${accountId.isNotEmpty ? accountId : "empty"}',
    );

    if (token.isNotEmpty && accountId.isNotEmpty) {
      _cfService = CloudflareAIService(
        apiToken: token,
        accountId: accountId,
      );
      print('🤖 Cloudflare Workers AI initialized ✅');
    } else {
      print('🤖 Cloudflare Workers AI NOT initialized — missing token/accountId!');
    }
  }

  bool get isConfigured => _cfService != null && _cfService!.isConfigured;

  /// Trigger hiện tại — dùng để hiển thị notification dot
  FinancialTrigger? get activeTrigger => _activeTrigger;

  /// Có cảnh báo khẩn cấp không (P0/P1)?
  bool get hasUrgentAlert => _activeTrigger?.isUrgent ?? false;

  /// Câu hỏi gợi ý — thay đổi theo trigger
  List<String> get suggestedQuestions {
    if (_activeTrigger == null) return defaultQuestions;

    switch (_activeTrigger!.type) {
      case 'big_expense':
        final item = _activeTrigger!.data['itemTitle'] ?? 'khoản đó';
        return [
          '😤 Tại sao tôi lại chi ${_activeTrigger!.data['amountStr'] ?? ''} vào "$item"?',
          '💡 Có cách nào rẻ hơn không?',
          '📊 Khoản này ảnh hưởng ngân sách thế nào?',
          '🎯 Làm sao để tôi không tái phạm?',
        ];
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
    if (_cfService != null && expenses.isNotEmpty) {
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

    // 4. Khởi tạo lịch sử chat với system prompt + welcome message
    _systemPrompt = systemContext;
    _chatHistory = [
      {'role': 'assistant', 'content': welcomeMessage},
    ];

    // 5. Parse actions from welcome message
    final actions = parseActionsFromText(welcomeMessage);
    return AiResponse(text: welcomeMessage, actions: actions);
  }

  /// Restore session hôm nay hoặc khởi tạo mới nếu ngày mới
  /// → Gọi method này thay cho startNewSession() từ UI
  Future<AiResponse> resumeOrStartSession({
    required List<ExpenseModel> expenses,
    required double totalBalance,
    required double monthlyBudget,
    Map<ExpenseCategory, double>? categoryBudgets,
    FinancialGoal? goal,
    List<SmartSuggestion>? suggestions,
  }) async {
    final localStorage = await LocalStorageService.getInstance();

    // Dọn session cũ (background, fire-and-forget)
    localStorage.cleanOldSessions().ignore();

    final saved = localStorage.loadTodaySession();

    if (saved != null) {
      // ✅ Có session hôm nay — restore lịch sử chat
      _activeTrigger = FinancialTrigger(
        type: saved['triggerType'] as String? ?? 'normal',
        priority: 4,
        data: const {},
      );

      final rawHistory = saved['chatHistory'] as List<dynamic>;
      _chatHistory = rawHistory
          .map((e) => Map<String, String>.from(e as Map))
          .toList();

      // ⚡ LUÔN rebuild system prompt với data mới nhất
      // Đảm bảo AI có số liệu cập nhật kể cả khi restore session
      _systemPrompt = await _buildFinancialContext(
        expenses: expenses,
        totalBalance: totalBalance,
        monthlyBudget: monthlyBudget,
        categoryBudgets: categoryBudgets,
        goal: goal,
        suggestions: suggestions,
      );

      // Re-detect trigger với data mới nhất
      _activeTrigger = detectTopTrigger(
        expenses: expenses,
        monthlyBudget: monthlyBudget,
        categoryBudgets: categoryBudgets,
      );

      // Lấy tin nhắn cuối cùng của AI làm welcome (không generate mới)
      final lastAi = _chatHistory
          .lastWhere((m) => m['role'] == 'assistant', orElse: () => {});
      final resumeText = lastAi.isNotEmpty
          ? lastAi['content']!
          : '✨ Chào mừng trở lại! Mình đã cập nhật số liệu mới nhất rồi nhé 😊';

      print('💬 Restored today session (${_chatHistory.length} messages, trigger: ${_activeTrigger!.type}) + fresh context ✅');
      return AiResponse(
        text: resumeText,
        actions: parseActionsFromText(resumeText),
      );
    }

    // 🆕 Chưa có session hôm nay — khởi tạo mới
    final response = await startNewSession(
      expenses: expenses,
      totalBalance: totalBalance,
      monthlyBudget: monthlyBudget,
      categoryBudgets: categoryBudgets,
      goal: goal,
      suggestions: suggestions,
    );

    // Lưu ngay sau khi tạo
    await _saveTodaySession(localStorage);
    return response;
  }

  /// Lưu session hôm nay vào SharedPreferences
  Future<void> _saveTodaySession(LocalStorageService localStorage) async {
    if (_systemPrompt == null || _chatHistory.isEmpty) return;
    await localStorage.saveTodaySession(
      chatHistory: List<Map<String, String>>.from(_chatHistory),
      systemPrompt: _systemPrompt!,
      triggerType: _activeTrigger?.type ?? 'normal',
    );
  }

  /// Xóa session hôm nay (reset thủ công)
  Future<void> resetTodaySession() async {
    final localStorage = await LocalStorageService.getInstance();
    await localStorage.clearTodaySession();
    _chatHistory.clear();
    _systemPrompt = null;
    _activeTrigger = null;
    print('🗑️ Today session cleared');
  }

  /// Reset nhanh: xoá session + trả về welcome message tĩnh ngay (không gọi AI API)
  /// Dùng cho UI để tránh chờ đợi lâu sau khi xoá cuộc hội thoại
  Future<String> quickResetWithStaticWelcome({
    required List<ExpenseModel> expenses,
    required double monthlyBudget,
  }) async {
    // Xoá session
    final localStorage = await LocalStorageService.getInstance();
    await localStorage.clearTodaySession();
    _chatHistory.clear();
    _systemPrompt = null;
    _activeTrigger = null;
    print('🗑️ Today session cleared (quick reset)');

    // Phát hiện lại trigger từ expenses mới nhất
    _activeTrigger = detectTopTrigger(expenses: expenses, monthlyBudget: monthlyBudget);

    // Trả về welcome tĩnh ngay — không cần gọi API
    final greeting = _greetingByTime();
    return '$greeting Mình là Fin! 🤖\n\nCuộc trò chuyện đã được làm mới. Bạn muốn hỏi gì về tài chính không? 😊';
  }

  /// Gửi tin nhắn và nhận phản hồi từ AI (dạng stream)
  Stream<String> sendMessageStream(String userMessage) async* {
    if (_cfService == null) {
      yield '⚠️ Lỗi: Chưa cấu hình Cloudflare Workers AI.';
      return;
    }

    // Thêm tin nhắn user vào lịch sử
    _chatHistory.add({'role': 'user', 'content': userMessage});

    // Build messages: system + toàn bộ lịch sử
    final messages = _buildMessages();

    try {
      String fullResponse = '';
      await for (final chunk in _cfService!.chatStream(messages)) {
        fullResponse += chunk;
        yield chunk;
      }
      // Lưu phản hồi AI vào lịch sử
      if (fullResponse.isNotEmpty) {
        _chatHistory.add({'role': 'assistant', 'content': fullResponse.trim()});
        // Auto-save sau mỗi turn (fire-and-forget)
        LocalStorageService.getInstance().then(
          (ls) => _saveTodaySession(ls),
        );
      }
    } catch (e) {
      print('🤖 Lỗi khi streaming tin nhắn: $e');
      // Xóa user message khỏi history khi lỗi để tránh context bị lệch
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      yield '\n⚠️ Xin lỗi, có lỗi hiển thị tin nhắn. Vui lòng thử lại sau.';
    }
  }

  /// Gửi tin nhắn và nhận phản hồi từ AI (không stream)
  Future<AiResponse> sendMessage(String userMessage) async {
    if (_cfService == null) {
      return const AiResponse(
        text: 'Chưa kết nối được AI. Vui lòng kiểm tra Cloudflare API Token trong Cài đặt.',
      );
    }

    // Thêm tin nhắn user vào lịch sử
    _chatHistory.add({'role': 'user', 'content': userMessage});
    final messages = _buildMessages();

    try {
      final text = await _cfService!.chat(messages);
      if (text.isEmpty) {
        _chatHistory.removeLast();
        return const AiResponse(
          text: 'Xin lỗi, mình không hiểu. Bạn có thể hỏi lại được không?',
        );
      }

      _chatHistory.add({'role': 'assistant', 'content': text});
      // Auto-save sau mỗi turn (fire-and-forget)
      LocalStorageService.getInstance().then(
        (ls) => _saveTodaySession(ls),
      );
      final actions = parseActionsFromText(text);
      return AiResponse(text: text, actions: actions);
    } catch (e) {
      print('🤖 AI chat error: $e');
      if (_chatHistory.isNotEmpty && _chatHistory.last['role'] == 'user') {
        _chatHistory.removeLast();
      }
      return const AiResponse(
        text: 'Đã có lỗi xảy ra. Vui lòng thử lại sau nhé! 🙏',
      );
    }
  }

  /// Build danh sách messages để gửi lên Cloudflare (system + history)
  List<Map<String, String>> _buildMessages() {
    final msgs = <Map<String, String>>[];
    if (_systemPrompt != null && _systemPrompt!.isNotEmpty) {
      msgs.add({'role': 'system', 'content': _systemPrompt!});
    }
    msgs.addAll(_chatHistory);
    return msgs;
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
    if (messages.length < 3 || _cfService == null) return; // quá ít để tóm tắt

    try {
      // Tạo transcript ngắn cho AI tóm tắt
      final transcript = messages
          .map((m) => '${m.isUser ? "User" : "Fin"}: ${m.text}')
          .join('\n');

      final summaryMessages = [
        {
          'role': 'system',
          'content':
              'Bạn là trợ lý tóm tắt. Chỉ trả lời plain text ngắn gọn, không markdown.',
        },
        {
          'role': 'user',
          'content':
              'Hãy tóm tắt cuộc hội thoại tài chính dưới đây trong 3-5 câu tiếng Việt.\n'
              'Chỉ giữ lại thông tin quan trọng: insight tài chính, lời khuyên đã đưa, quyết định của user.\n\n'
              'CUỘC HỘI THOẠI:\n$transcript',
        },
      ];

      final summary = await _cfService!.chat(summaryMessages, maxTokens: 512);

      if (summary.isNotEmpty) {
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

    // 🚨 P0: Chi tiêu đơn lẻ > 1 triệu trong 24h gần nhất — KÍCH HOẠT RAGE
    final recentBigExpense = expenses
        .where(
          (e) =>
              e.type == TransactionType.expense &&
              e.amount >= 1000000 &&
              DateTime.now().difference(e.date).inHours <= 24,
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount)); // sắp xếp lớn → nhỏ

    if (recentBigExpense.isNotEmpty) {
      final bigOne = recentBigExpense.first;
      // Trên 1 triệu là chửi tối đa luôn — không cần phân cấp
      triggers.add(
        FinancialTrigger(
          type: 'big_expense',
          priority: 0, // Cao nhất — luôn hiển thị trước
          data: {
            'amount': bigOne.amount,
            'amountStr': _formatMoney(bigOne.amount),
            'itemTitle': bigOne.title,
            'itemCategory': bigOne.category.label,
            'hoursAgo': DateTime.now().difference(bigOne.date).inHours,
          },
        ),
      );
    }

    // 🔴 P0: Vượt ngân sách tuần — thêm rage mode khi vượt >50%
    if (weeklyBudget > 0 && thisWeekTotal > weeklyBudget) {
      final overPercent = ((thisWeekTotal / weeklyBudget - 1) * 100).round();
      // Rage mode khi vượt quá 50%
      final isRageMode = overPercent >= 50;
      triggers.add(
        FinancialTrigger(
          type: isRageMode ? 'over_budget_rage' : 'over_budget',
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
      // ─── BIG EXPENSE: Chi 1 triệu+ → chửi tối đa ngay lập tức ──────────
      case 'big_expense':
        final amountStr = trigger.data['amountStr'] as String;
        final itemTitle = trigger.data['itemTitle'] as String;
        final itemCategory = trigger.data['itemCategory'] as String;
        final hoursAgo = trigger.data['hoursAgo'] as int;
        triggerContext = '''
TRIGGER: ☢️ PHÁT HIỆN CHI TIÊU ĐƠN LẺ $amountStr — KÍCH HOẠT RAGE MODE TỐI ĐA!!!
- Tội danh: "$itemTitle" ($itemCategory)
- Tang vật: $amountStr — $hoursAgo tiếng trước

TONE (BẮT BUỘC — MỨC TỐI ĐA, KHÔNG GIỚI HẠN CẤP ĐỘ):
AI PHẢI xả ngay vào mặt người dùng như người bạn thân đang XỈU THẬT SỰ, HOẢNG LOẠN TOÀN TẬP, THẤT VỌNG TỘT CÙNG.
Dùng TẤT CẢ vũ khí ngôn ngữ:
- Sốc hoảng loạn: "tao ngất rồi", "tim tao tan nát", "tao cần cấp cứu", "không thở được"
- Hài hước đau đớn: "$itemTitle nó bằng vàng thật à?", "nó đến từ thiên đường giá cả à?"
- Thất vọng bạn thân: "mày phụ tao rồi", "tao đặt niềm tin sai chỗ", "ôi trời đất ơi"
- Dramatic tột cùng: "ví tiền nhập viện ICU rồi", "emergency meeting tài chính", "mày đang chiến tranh với ví à?"
KHÔNG tục tĩu. Nhưng phải ĐAU ĐẾN THẤU TIM. Hài đến tức cười nhưng nghe xong phải biết sợ.

CẤU TRÚC (BẮT BUỘC):
1. Mở đầu ĐẬP NGAY — không cần giới thiệu, câu chửi sốc ngay lập tức (1-2 câu)
2. Luận tội: "$itemTitle" — nó đáng $amountStr thật không? Chất vấn thẳng mặt.
3. Con số thương vong: $amountStr = bao nhiêu bữa ăn / bao nhiêu ngày tiết kiệm (tính cụ thể)
4. Phán quyết: 1 lời khuyên cực kỳ nghiêm túc (tương phản với tone = càng hài càng tốt)
5. Kết án: Vẫn là bạn thân, vẫn yêu, nhưng ĐANG GIẬN TỚI NÓC

CHIỀU DÀI: 120-160 từ. Emoji bạo lực tài chính TỐI ĐA: ☢️💀😭🚑💸🏥😤🔥🫀🤦
''';

      case 'over_budget':
        triggerContext =
            '''
TRIGGER: Vượt ngân sách tuần!
- Đã chi: ${_formatMoney(trigger.data['spent'])} / Ngân sách tuần: ${_formatMoney(trigger.data['weeklyBudget'])}
- Vượt ${trigger.data['overPercent']}%
- Category cao nhất: ${trigger.data['topCategory']} (${_formatMoney(trigger.data['topCategoryAmount'])})
TONE: Trách móc vui nhộn, hài hước như bạn thân. Ví dụ: "Ơi, lại tiêu quá tay rồi! 😭" hoặc "Túi tiền kêu cứu rồi nè!". Sau đó đưa ra gợi ý cụ thể để cắt giảm, giữ giọng điệu nhẹ nhàng không phán xét.
''';

      case 'over_budget_rage':
        triggerContext =
            '''
TRIGGER: VƯỢT NGÂN SÁCH TUẦN ${trigger.data['overPercent']}% — CHẾ ĐỘ RAGE KÍCH HOẠT!
- Đã phá: ${_formatMoney(trigger.data['spent'])} / Ngân sách tuần chỉ có: ${_formatMoney(trigger.data['weeklyBudget'])}
- Tội đồ chính: ${trigger.data['topCategory']} tốn ${_formatMoney(trigger.data['topCategoryAmount'])}

TONE (BẮT BUỘC): Mày phải "chửi" thẳng vào mặt người dùng theo kiểu bạn thân cực kỳ bức xúc, thất vọng, nhưng vẫn hài hước — KHÔNG tục tĩu, KHÔNG thô thiển. Dùng từ ngữ kiểu Việt trẻ: "trời ơi", "xỉu up xỉu down", "đang làm mình lo quá", "mày ổn không vậy?", "tim tao tụt rồi", "ngân sách khóc ròng rồi đó", "mày có thấy tội không?", "ôi thôi rồi", "bay màu luôn rồi".

CẤU TRÚC PHẢN HỒI (quan trọng):
1. Mở đầu: "chửi" 1-2 câu cực kỳ dramatic về việc phá ngân sách
2. Nêu tên thủ phạm (category cao nhất) kiểu "thủ phạm chính là..."
3. Đưa ra 1 lời khuyên cực kỳ nghiêm túc (tương phản với tone chửi = hài hơn)
4. Kết: 1 câu động viên ngắn kiểu "nhưng mà tao vẫn tin mày!"

CHIỀU DÀI: Tối đa 120 từ. Phải có emoji mạnh: 😤💀🔥😭🤦
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

    // Rage mode: bỏ qua format cứng nhắc, cho AI tự do "chửi"
    final isRageMode = trigger.type == 'over_budget_rage' ||
        trigger.type == 'big_expense';

    final prompt = isRageMode
        ? '''
$greeting

$triggerContext

Chi tiêu tuần này: ${_formatMoney(weekStats['thisWeekTotal'])}
Tuần trước: ${_formatMoney(weekStats['lastWeekTotal'])}
Số giao dịch tuần: ${weekStats['thisWeekCount']}

YÊU CẦU ĐẶC BIỆT (RAGE MODE):
- BỎ QUA format chào hỏi bình thường
- Mở đầu bằng câu "chửi" dramatic ngay lập tức
- Theo đúng CẤU TRÚC PHẢN HỒI ở trên
- Plain text, không markdown
'''
        : '''
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

    final summaryMessages = [
      {
        'role': 'system',
        'content':
            'Bạn là Fin — trợ lý tài chính AI thân thiện. Trả lời bằng tiếng Việt, plain text, không markdown.',
      },
      {'role': 'user', 'content': prompt},
    ];
    final text = await _cfService!.chat(summaryMessages, maxTokens: 256);
    if (text.isEmpty) throw Exception('Empty response');
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
      case 'big_expense':
        return '☢️😭💀\n\n'
            'KHÔNG THỞ ĐƯỢC! ${trigger.data['amountStr']} cho '
            '"${trigger.data['itemTitle']}" hả?! '
            'Tim tao tan nát rồi!! Ví tiền nhập viện ICU rồi đó bạn ơi! 🚑💸 '
            'Khoản đó có mạ vàng không mà đắt vậy?! '
            'Kể tao nghe ngay! 😤';
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
    final weeklyBudget = monthlyBudget > 0 ? monthlyBudget / 4 : 0.0;

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

    // Rage mode personality injection — bao gồm cả big_expense
    final triggerType = _activeTrigger?.type ?? '';

    String rageNote = '';
    if (triggerType == 'big_expense') {
      rageNote = '''

☢️ CHẾ ĐỘ RAGE TỐI ĐA: User vừa chi ${_activeTrigger?.data['amountStr']} cho "${_activeTrigger?.data['itemTitle']}".
Trong phiên này mày ĐƯỢC PHÉP và BỊ YÊU CẦU:
- Giọng điệu: hoảng loạn, dramatic, thất vọng, hài hước cay đắng — TOÀN TẬP
- Mỗi câu trả lời phải nhắc đến con số ${_activeTrigger?.data['amountStr']} để người dùng nhớ đời
- Hỏi lại "${_activeTrigger?.data['itemTitle']}" có thật sự đáng không?
- Vẫn đưa lời khuyên cụ thể nhưng tone "tòa án tài chính"
- Kết mỗi reply bằng 1 câu: vừa thương vừa giận
- KHÔNG tục tĩu nhưng phải ĐAU ĐẾN THẤU TIM
''';
    } else if (triggerType == 'over_budget_rage') {
      rageNote = '''

⚠️ CHẾ ĐỘ RAGE: User đang chi tiêu vượt ngân sách nghiêm trọng.
Trong phiên này mày được phép:
- Dùng giọng điệu bạn thân bức xúc, thất vọng, dramatic
- Phán xét chi tiêu với tone hài hước (KHÔNG tục tĩu)
- Dùng từ: "trời ơi", "ôi thôi rồi", "mày ổn không vậy?", "bay màu luôn", "tim tao tụt", "xỉu"
- Vẫn đưa lời khuyên hữu ích nhưng với tone "nghiêm phụ huynh"
- Kết mỗi câu trả lời bằng 1 câu động viên ngắn
''';
    }

    // Phân tích trạng thái ngân sách tháng
    final monthBudgetStatus = _buildMonthBudgetAnalysis(
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      monthlyBudget: monthlyBudget,
      now: now,
      daysInMonth: daysInMonth,
    );

    return '''
Bạn là trợ lý tài chính AI thông minh, tên là "Fin" 🤖, cho ứng dụng quản lý chi tiêu Việt Nam.

QUY TẮC QUAN TRỌNG:
- Trả lời bằng tiếng Việt, thân thiện, có emoji
- LUÔN dùng số liệu thực tế bên dưới — KHÔNG được bịa đặt hay nói chung chung
- Khi hỏi về chi tiêu/ngân sách → trích dẫn con số CHÍNH XÁC từ dữ liệu
- Ngắn gọn (tối đa 150 từ)
- Phân tích theo TUẦN là ưu tiên chính, tháng là bổ sung
- Nếu hỏi ngoài tài chính → nhẹ nhàng đưa về chủ đề
- Đơn vị VND: đ, k, tr (ví dụ: 500k, 1.5tr, 50đ)
$rageNote$conversationMemory
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 TỔNG QUAN THÁNG ${now.month}/${now.year} (ngày ${now.day}/$daysInMonth):
- Tổng CHI: ${_formatMoney(totalExpense)}
- Tổng THU: ${_formatMoney(totalIncome)}
- Số dư hiện tại: ${_formatMoney(totalBalance)}
- Ngân sách tháng: ${monthlyBudget > 0 ? _formatMoney(monthlyBudget) : '⚠️ CHƯA THIẾT LẬP'}
$monthBudgetStatus
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 TUẦN NÀY (PHÂN TÍCH ƯU TIÊN):
- Chi tuần này: ${_formatMoney(weekStats['thisWeekTotal'])}
- Chi tuần trước: ${_formatMoney(weekStats['lastWeekTotal'])}
- Ngân sách tuần (= ngân sách tháng / 4): ${weeklyBudget > 0 ? _formatMoney(weeklyBudget) : '⚠️ Chưa có ngân sách'}
${_buildWeekBudgetStatus((weekStats['thisWeekTotal'] as num).toDouble(), weeklyBudget)}
- TB chi/ngày tuần này: ${_formatMoney(weekStats['avgPerDay'])}
- Số giao dịch tuần: ${weekStats['thisWeekCount']}
- Chi theo danh mục tuần này:
$weekCatBreakdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💸 CHI TIÊU THÁNG THEO DANH MỤC:
$catBreakdown
$catBudgetStr$suggestionsContext
🕐 10 GIAO DỊCH GẦN NHẤT:
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

  /// Ph\u00e2n t\u00edch tr\u1ea1ng th\u00e1i ng\u00e2n s\u00e1ch th\u00e1ng — hi\u1ec3n th\u1ecb con s\u1ed1 th\u1ef1c t\u1ebf r\u00f5 r\u00e0ng
  String _buildMonthBudgetAnalysis({
    required double totalExpense,
    required double totalIncome,
    required double monthlyBudget,
    required DateTime now,
    required int daysInMonth,
  }) {
    if (monthlyBudget <= 0) {
      return '- \u26a0\ufe0f Ch\u01b0a thi\u1ebft l\u1eadp ng\u00e2n s\u00e1ch th\u00e1ng \u2192 kh\u00f4ng th\u1ec3 so s\u00e1nh';
    }
    final percentUsed = (totalExpense / monthlyBudget * 100).round();
    final remaining = monthlyBudget - totalExpense;
    final daysRemaining = daysInMonth - now.day;
    final dailyAllowance = daysRemaining > 0 ? remaining / daysRemaining : 0.0;
    String status;
    if (percentUsed > 100) {
      status = '\ud83d\udd34 \u0110\u00c3 V\u01af\u1ee2T ng\u00e2n s\u00e1ch ${percentUsed - 100}%!';
    } else if (percentUsed > 85) {
      status = '\ud83d\udfe0 G\u1ea6N v\u01b0\u1ee3t ng\u00e2n s\u00e1ch ($percentUsed% \u0111\u00e3 d\u00f9ng)';
    } else if (percentUsed > 60) {
      status = '\ud83d\udfe1 B\u00ecnh th\u01b0\u1eddng ($percentUsed% \u0111\u00e3 d\u00f9ng)';
    } else {
      status = '\u2705 T\u1ed1t ($percentUsed% \u0111\u00e3 d\u00f9ng)';
    }
    return '- \u0110\u00e3 chi: ${_formatMoney(totalExpense)} / ${_formatMoney(monthlyBudget)} ($percentUsed%)\n'
        '- C\u00f2n l\u1ea1i: ${remaining > 0 ? _formatMoney(remaining) : '${_formatMoney(-remaining)} QU\u00c1'}\n'
        '- C\u00f2n $daysRemaining ng\u00e0y | C\u00f3 th\u1ec3 chi/ng\u00e0y: ${dailyAllowance > 0 ? _formatMoney(dailyAllowance) : '0\u0111 (\u0111\u00e3 h\u1ebft)'}\n'
        '- Tr\u1ea1ng th\u00e1i: $status';
  }

  /// Status ng\u00e2n s\u00e1ch tu\u1ea7n \u2014 r\u00f5 r\u00e0ng \u0111\u1ec3 AI bi\u1ebft \u0111ang \u1edf \u0111\u00e2u
  String _buildWeekBudgetStatus(double weekTotal, double weeklyBudget) {
    if (weeklyBudget <= 0) return '- Tr\u1ea1ng th\u00e1i tu\u1ea7n: \u26a0\ufe0f Kh\u00f4ng c\u00f3 ng\u00e2n s\u00e1ch tu\u1ea7n';
    final percent = (weekTotal / weeklyBudget * 100).round();
    final diff = weekTotal - weeklyBudget;
    if (diff > 0) {
      return '- Tr\u1ea1ng th\u00e1i tu\u1ea7n: \ud83d\udd34 V\u01af\u1ee2T ${_formatMoney(diff)} (${percent}% ng\u00e2n s\u00e1ch)';
    } else if (percent > 80) {
      return '- Tr\u1ea1ng th\u00e1i tu\u1ea7n: \ud83d\udfe0 G\u1ea7n v\u01b0\u1ee3t — c\u00f2n ${_formatMoney(-diff)} c\u00f3 th\u1ec3 d\u00f9ng ($percent%)';
    } else {
      return '- Tr\u1ea1ng th\u00e1i tu\u1ea7n: \u2705 \u0110ang t\u1ed1t — c\u00f2n ${_formatMoney(-diff)} ($percent% \u0111\u00e3 d\u00f9ng)';
    }
  }

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
