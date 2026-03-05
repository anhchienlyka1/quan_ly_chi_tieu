import '../models/expense_model.dart';
import '../models/smart_suggestion_model.dart';

/// Service phân tích spending patterns và đưa ra gợi ý thông minh.
class SmartSuggestionService {
  /// Analyze spending patterns and return a list of actionable suggestions.
  static List<SmartSuggestion> analyzePatternsAndSuggest({
    required List<ExpenseModel> expenses,
    required double monthlyBudget,
  }) {
    final suggestions = <SmartSuggestion>[];
    final now = DateTime.now();

    final expensesOnly = expenses
        .where((e) => e.type == TransactionType.expense)
        .toList();
    if (expensesOnly.isEmpty) return suggestions;

    // ── Rule 1: Weekend Spending Spike ──
    _checkWeekendSpike(expensesOnly, suggestions, now);

    // ── Rule 2: Category Dominance ──
    _checkCategoryDominance(expensesOnly, suggestions, now);

    // ── Rule 3: Daily Trend (Increasing Spending) ──
    _checkDailyTrend(expensesOnly, suggestions, now);

    // ── Rule 4: Saving Opportunity ──
    _checkSavingOpportunity(expensesOnly, monthlyBudget, suggestions, now);

    // ── Rule 5: Recurring Expense Detection ──
    _checkRecurringExpenses(expensesOnly, suggestions, now);

    return suggestions;
  }

  /// Rule 1: Weekend spending > 50% of total weekly spending
  static void _checkWeekendSpike(
    List<ExpenseModel> expenses,
    List<SmartSuggestion> suggestions,
    DateTime now,
  ) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    final thisWeek = expenses.where(
      (e) =>
          e.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1))),
    );

    if (thisWeek.isEmpty) return;

    final weekendSpend = thisWeek
        .where((e) => e.date.weekday >= 6)
        .fold<double>(0, (s, e) => s + e.amount);
    final weekdaySpend = thisWeek
        .where((e) => e.date.weekday < 6)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalWeek = weekendSpend + weekdaySpend;

    if (totalWeek > 0 && weekendSpend / totalWeek > 0.5) {
      final weekendPercent = ((weekendSpend / totalWeek) * 100).round();
      suggestions.add(
        SmartSuggestion(
          id: 'weekend_spike_${now.millisecondsSinceEpoch}',
          title: 'Chi tiêu cuối tuần cao',
          description:
              'Bạn chi $weekendPercent% vào T7-CN tuần này. Thử đặt budget riêng cho weekend nhé!',
          emoji: '📅',
          type: SuggestionType.warning,
          createdAt: now,
          actionLabel: 'Đặt ngân sách',
          actionRoute: '/budget',
        ),
      );
    }
  }

  /// Rule 2: One category > 40% of total spending
  static void _checkCategoryDominance(
    List<ExpenseModel> expenses,
    List<SmartSuggestion> suggestions,
    DateTime now,
  ) {
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    if (total <= 0) return;

    final categorySpending = <ExpenseCategory, double>{};
    for (final e in expenses) {
      categorySpending[e.category] =
          (categorySpending[e.category] ?? 0) + e.amount;
    }

    for (final entry in categorySpending.entries) {
      final percent = (entry.value / total * 100).round();
      if (percent > 40) {
        suggestions.add(
          SmartSuggestion(
            id: 'cat_dominance_${entry.key.name}_${now.millisecondsSinceEpoch}',
            title: '${entry.key.label} chiếm $percent% chi tiêu',
            description:
                'Danh mục "${entry.key.label}" đang chiếm phần lớn chi tiêu. Xem xét cắt giảm?',
            emoji: '📊',
            type: SuggestionType.insight,
            createdAt: now,
            actionLabel: 'Xem thống kê',
            actionRoute: '/statistics',
          ),
        );
        break; // Only show one dominant category suggestion
      }
    }
  }

  /// Rule 3: Daily spending is increasing over the past 5 days
  static void _checkDailyTrend(
    List<ExpenseModel> expenses,
    List<SmartSuggestion> suggestions,
    DateTime now,
  ) {
    final dailyTotals = <int, double>{}; // day offset -> total
    for (int i = 0; i < 5; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where(
        (e) =>
            e.date.year == targetDate.year &&
            e.date.month == targetDate.month &&
            e.date.day == targetDate.day,
      );
      dailyTotals[i] = dayExpenses.fold<double>(0, (s, e) => s + e.amount);
    }

    // Check if spending is consistently increasing (at least 3 consecutive increases)
    int increases = 0;
    for (int i = 4; i > 0; i--) {
      if ((dailyTotals[i - 1] ?? 0) > (dailyTotals[i] ?? 0)) {
        increases++;
      }
    }

    if (increases >= 3) {
      suggestions.add(
        SmartSuggestion(
          id: 'daily_trend_${now.millisecondsSinceEpoch}',
          title: 'Chi tiêu đang tăng dần',
          description:
              'Chi tiêu mỗi ngày đang tăng liên tục. Cẩn thận để không vượt ngân sách nhé!',
          emoji: '📈',
          type: SuggestionType.warning,
          createdAt: now,
        ),
      );
    }
  }

  /// Rule 4: Spent < 60% of budget → praise & encourage saving
  static void _checkSavingOpportunity(
    List<ExpenseModel> expenses,
    double monthlyBudget,
    List<SmartSuggestion> suggestions,
    DateTime now,
  ) {
    if (monthlyBudget <= 0) return;

    final totalSpent = expenses.fold<double>(0, (s, e) => s + e.amount);
    final percentUsed = (totalSpent / monthlyBudget * 100).round();
    final dayOfMonth = now.day;

    // Only trigger if we're past the 10th and still under 60%
    if (dayOfMonth >= 10 && percentUsed < 60) {
      final saved = monthlyBudget - totalSpent;
      suggestions.add(
        SmartSuggestion(
          id: 'saving_opp_${now.millisecondsSinceEpoch}',
          title: 'Tuyệt vời! Bạn đang tiết kiệm tốt 🎉',
          description:
              'Mới chi $percentUsed% ngân sách tháng. Cơ hội tiết kiệm thêm ${_formatMoney(saved)}!',
          emoji: '💰',
          type: SuggestionType.praise,
          createdAt: now,
          actionLabel: 'Xem mục tiêu',
          actionRoute: '/goals',
        ),
      );
    }
  }

  /// Rule 5: Detect recurring expenses (same title + amount ± 10%)
  static void _checkRecurringExpenses(
    List<ExpenseModel> expenses,
    List<SmartSuggestion> suggestions,
    DateTime now,
  ) {
    final titleGroups = <String, List<ExpenseModel>>{};
    for (final e in expenses) {
      final key = e.title.toLowerCase().trim();
      titleGroups.putIfAbsent(key, () => []).add(e);
    }

    for (final entry in titleGroups.entries) {
      if (entry.value.length >= 3) {
        // Found at least 3 transactions with same title
        final amounts = entry.value.map((e) => e.amount).toList();
        final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;

        // Check if amounts are within ±10% of average
        final isConsistent = amounts.every(
          (a) => (a - avgAmount).abs() / avgAmount <= 0.1,
        );

        if (isConsistent) {
          suggestions.add(
            SmartSuggestion(
              id: 'recurring_${entry.key}_${now.millisecondsSinceEpoch}',
              title: 'Chi tiêu lặp lại: "${entry.value.first.title}"',
              description:
                  'Phát hiện ${entry.value.length} lần chi ~${_formatMoney(avgAmount)} cho "${entry.value.first.title}". Đây có thể là subscription?',
              emoji: '🔄',
              type: SuggestionType.tip,
              createdAt: now,
            ),
          );
          break; // Only show one recurring suggestion
        }
      }
    }
  }

  static String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '${amount.toStringAsFixed(0)}đ';
  }
}
