import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for json.decode and json.encode
import '../models/goal_model.dart'; // Added as per instruction
import '../models/fixed_expense_model.dart';
import 'ai_assistant_service.dart'; // Import for ChatMessage

/// Service for managing local key-value storage using SharedPreferences.
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyMonthlyBudget = 'monthly_budget';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyAutoExpenseEnabled = 'auto_expense_enabled';
  static const String _keyAutoExpenseHistory = 'auto_expense_history';
  static const String _keyAiFeaturesEnabled = 'ai_features_enabled';
  static const String _keyAiConversationSummary = 'ai_conversation_summary';
  static const String _keyAiConversationHistory = 'ai_conversation_history';
  static const String _keyAiFeedback = 'ai_feedback_stats';
  static const String _keyAiChatSessions = 'ai_chat_sessions';
  static const String _keyGoal = 'financial_goal';
  static const String _keyTodaySession = 'ai_today_session'; // session trong ngày
  static const String _keyFixedExpenses = 'fixed_expenses';
  static const String _keyLastFixedImportMonth = 'last_fixed_import_month';

  // Theme Mode
  Future<void> setThemeMode(String mode) async {
    await _preferences?.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _preferences?.getString(_keyThemeMode) ?? 'system';
  }

  // Monthly Budget
  Future<void> setMonthlyBudget(double budget) async {
    await _preferences?.setDouble(_keyMonthlyBudget, budget);
  }

  double getMonthlyBudget() {
    return _preferences?.getDouble(_keyMonthlyBudget) ?? 0.0;
  }

  // First Launch
  Future<void> setFirstLaunch(bool value) async {
    await _preferences?.setBool(_keyFirstLaunch, value);
  }

  bool isFirstLaunch() {
    return _preferences?.getBool(_keyFirstLaunch) ?? true;
  }

  // Auto Expense
  Future<void> setAutoExpenseEnabled(bool value) async {
    await _preferences?.setBool(_keyAutoExpenseEnabled, value);
  }

  bool isAutoExpenseEnabled() {
    return _preferences?.getBool(_keyAutoExpenseEnabled) ?? false;
  }

  Future<void> setAutoExpenseHistory(String jsonHistory) async {
    await _preferences?.setString(_keyAutoExpenseHistory, jsonHistory);
  }

  String getAutoExpenseHistory() {
    return _preferences?.getString(_keyAutoExpenseHistory) ?? '[]';
  }

  // Total Balance
  Future<void> setTotalBalance(double balance) async {
    await _preferences?.setDouble('total_balance', balance);
  }

  double getTotalBalance() {
    return _preferences?.getDouble('total_balance') ?? 0.0;
  }

  // AI Assistant
  Future<void> setAiAssistantEnabled(bool value) async {
    await _preferences?.setBool(
      _keyAiFeaturesEnabled,
      value,
    ); // Uses _keyAiFeaturesEnabled
  }

  bool isAiAssistantEnabled() {
    return _preferences?.getBool(_keyAiFeaturesEnabled) ??
        true; // Uses _keyAiFeaturesEnabled
  }

  // AI Conversation Memory (multi-session — keeps last 5 summaries)
  Future<void> saveConversationSummary(String summary) async {
    try {
      final history = getConversationHistory();
      history.add({
        'summary': summary,
        'timestamp': DateTime.now().toIso8601String(),
      });
      // Keep only last 5 sessions
      while (history.length > 5) {
        history.removeAt(0);
      }
      await _preferences?.setString(
        _keyAiConversationHistory,
        json.encode(history),
      );
    } catch (e) {
      // Fallback: save as single summary
      await _preferences?.setString(_keyAiConversationSummary, summary);
    }
  }

  /// Get all conversation summaries as structured list
  List<Map<String, dynamic>> getConversationHistory() {
    try {
      final historyJson = _preferences?.getString(_keyAiConversationHistory);
      if (historyJson != null && historyJson.isNotEmpty) {
        final decoded = json.decode(historyJson) as List;
        return decoded.cast<Map<String, dynamic>>().toList();
      }
    } catch (_) {}

    // Migration: if old single summary exists, convert it
    final oldSummary = _preferences?.getString(_keyAiConversationSummary);
    if (oldSummary != null && oldSummary.isNotEmpty) {
      return [
        {'summary': oldSummary, 'timestamp': DateTime.now().toIso8601String()},
      ];
    }
    return [];
  }

  /// Get combined summary string for AI context
  String? getConversationSummary() {
    final history = getConversationHistory();
    if (history.isEmpty) return null;

    final buffer = StringBuffer();
    for (final entry in history) {
      final ts = DateTime.tryParse(entry['timestamp'] ?? '');
      final label = ts != null ? formatTimeAgo(ts) : 'Trước đó';
      buffer.writeln('[$label]: ${entry['summary']}');
    }
    return buffer.toString().trim();
  }

  /// Format relative time label
  String formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}';
  }

  // --- Full Chat Sessions ---

  Future<void> saveChatSession(
    List<ChatMessage> messages,
    DateTime startTime,
    String summary,
  ) async {
    try {
      final sessions = getChatSessions();
      sessions.add({
        'startTime': startTime.toIso8601String(),
        'summary': summary,
        'messages': messages
            .map(
              (m) => {
                'text': m.text,
                'isUser': m.isUser,
                'timestamp': m.timestamp.toIso8601String(),
                'actions': m.actions.map((a) => a.name).toList(),
              },
            )
            .toList(),
      });
      // Keep only last 20 sessions for detailed view
      while (sessions.length > 20) {
        sessions.removeAt(0);
      }
      await _preferences?.setString(_keyAiChatSessions, json.encode(sessions));
    } catch (e) {
      print('🤖 Error saving chat session: $e');
    }
  }

  List<Map<String, dynamic>> getChatSessions() {
    try {
      final sessionsJson = _preferences?.getString(_keyAiChatSessions);
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final decoded = json.decode(sessionsJson) as List;
        return decoded.cast<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      print('🤖 Error loading chat sessions: $e');
    }
    return [];
  }

  Future<void> clearConversationSummary() async {
    await _preferences?.remove(_keyAiConversationHistory);
    await _preferences?.remove(_keyAiConversationSummary);
  }

  // ─── Today Session (lưu lịch sử hôm nay) ──────────────────────────────────

  /// Key theo ngày — mỗi ngày 1 bucket riêng
  String get _todayKey {
    final now = DateTime.now();
    return '${_keyTodaySession}_${now.year}_${now.month}_${now.day}';
  }

  /// Lưu toàn bộ session hôm nay (messages + systemPrompt + trigger)
  Future<void> saveTodaySession({
    required List<Map<String, String>> chatHistory,
    required String systemPrompt,
    required String triggerType,
  }) async {
    try {
      final data = {
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'savedAt': DateTime.now().toIso8601String(),
        'triggerType': triggerType,
        'systemPrompt': systemPrompt,
        'chatHistory': chatHistory,
      };
      await _preferences?.setString(_todayKey, json.encode(data));
    } catch (e) {
      print('💾 Error saving today session: $e');
    }
  }

  /// Load session hôm nay — trả null nếu chưa có hoặc không phải hôm nay
  Map<String, dynamic>? loadTodaySession() {
    try {
      final raw = _preferences?.getString(_todayKey);
      if (raw == null || raw.isEmpty) return null;
      final data = json.decode(raw) as Map<String, dynamic>;
      // Kiểm tra lại ngày (paranoid check)
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (data['date'] != today) return null;
      return data;
    } catch (e) {
      print('💾 Error loading today session: $e');
      return null;
    }
  }

  /// Xóa session hôm nay (dùng khi user muốn reset)
  Future<void> clearTodaySession() async {
    await _preferences?.remove(_todayKey);
  }

  /// Dọn session cũ (hơn 3 ngày) — gọi khi khởi động app
  Future<void> cleanOldSessions() async {
    final keys = _preferences?.getKeys() ?? {};
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    for (final key in keys) {
      if (!key.startsWith(_keyTodaySession)) continue;
      try {
        final raw = _preferences?.getString(key);
        if (raw == null) continue;
        final data = json.decode(raw) as Map<String, dynamic>;
        final date = DateTime.tryParse(data['date'] ?? '');
        if (date == null || date.isBefore(cutoff)) {
          await _preferences?.remove(key);
        }
      } catch (_) {}
    }
  }

  // --- AI Feedback Stats ---
  Future<void> saveFeedback({required bool isPositive}) async {
    final stats = getFeedbackStats();
    if (isPositive) {
      stats['positive'] = (stats['positive'] ?? 0) + 1;
    } else {
      stats['negative'] = (stats['negative'] ?? 0) + 1;
    }
    await _preferences?.setString(_keyAiFeedback, json.encode(stats));
  }

  Map<String, int> getFeedbackStats() {
    try {
      final jsonStr = _preferences?.getString(_keyAiFeedback);
      if (jsonStr != null) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        return {
          'positive': (decoded['positive'] as num?)?.toInt() ?? 0,
          'negative': (decoded['negative'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return {'positive': 0, 'negative': 0};
  }

  double get feedbackNegativeRate {
    final stats = getFeedbackStats();
    final total = (stats['positive'] ?? 0) + (stats['negative'] ?? 0);
    if (total == 0) return 0;
    return (stats['negative'] ?? 0) / total;
  }

  // --- Financial Goal ---
  FinancialGoal? getGoal() {
    final String? jsonStr = _preferences?.getString(
      _keyGoal,
    ); // Changed to _preferences?
    if (jsonStr == null) return null;
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return FinancialGoal.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveGoal(FinancialGoal? goal) async {
    if (goal == null) {
      await _preferences?.remove(_keyGoal); // Changed to _preferences?
    } else {
      await _preferences?.setString(
        _keyGoal,
        json.encode(goal.toJson()),
      ); // Changed to _preferences?
    }
  }

  // --- Fixed Expenses ---

  /// Save full list of fixed expenses.
  Future<void> saveFixedExpenses(List<FixedExpenseModel> items) async {
    final list = items.map((e) => e.toMap()).toList();
    await _preferences?.setString(_keyFixedExpenses, json.encode(list));
  }

  /// Load all fixed expenses (empty list if none saved).
  List<FixedExpenseModel> getFixedExpenses() {
    try {
      final raw = _preferences?.getString(_keyFixedExpenses);
      if (raw == null || raw.isEmpty) return [];
      final decoded = json.decode(raw) as List;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(FixedExpenseModel.fromMap)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// The month key ("yyyy-MM") of the last time fixed expenses were imported.
  String? getLastFixedImportMonth() {
    return _preferences?.getString(_keyLastFixedImportMonth);
  }

  Future<void> setLastFixedImportMonth(String monthKey) async {
    await _preferences?.setString(_keyLastFixedImportMonth, monthKey);
  }
}
