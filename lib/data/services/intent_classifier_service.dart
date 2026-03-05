/// Offline Intent Classifier — phân loại ý định người dùng
/// từ message text mà không cần gọi API.
enum IntentType {
  addExpense,
  setBudget,
  showStats,
  viewExpenses,
  query, // fallback — gọi AI
}

class IntentClassifierService {
  IntentClassifierService._();

  /// Phân loại intent từ message text dùng fuzzy regex & scoring
  static IntentType classify(String userMessage) {
    final normalized = userMessage.toLowerCase().trim();

    // Điểm số cho từng intent
    final scores = <IntentType, int>{
      IntentType.addExpense: 0,
      IntentType.setBudget: 0,
      IntentType.showStats: 0,
      IntentType.viewExpenses: 0,
    };

    // ─── Add Expense ─────────────────────────────────────────
    scores[IntentType.addExpense] = _calculateScore(normalized, [
      r'th[eê]m.*chi',
      r'ghi.*ti[eê]u',
      r'ghi.*chi',
      r'th[eê]m.*kho[aả]n',
      r't[oố]n',
      r'mua',
      r'tr[aả].*ti[eề]n',
      r'thanh.*to[aá]n',
      r'm[aấ]t.*ti[eề]n',
      r'v[uừ]a.*chi',
    ]);

    // ─── Set Budget ──────────────────────────────────────────
    scores[IntentType.setBudget] = _calculateScore(normalized, [
      r'đ[aặ]t.*ng[aâ]n.*s[aá]ch',
      r'thi[eế]t.*l[aậ]p.*ng[aâ]n.*s[aá]ch',
      r'c[aà]i.*ng[aâ]n.*s[aá]ch',
      r'budget',
      r'm[uứ]c.*chi.*ti[eê]u',
    ]);

    // ─── Show Stats ──────────────────────────────────────────
    scores[IntentType.showStats] = _calculateScore(normalized, [
      r'xem.*th[oố]ng.*k[eê]',
      r'th[oố]ng.*k[eê]',
      r'b[aá]o.*c[aá]o',
      r'bi[eể]u.*đ[oồ]',
      r'chart',
      r'ph[aâ]n.*t[ií]ch',
    ]);

    // ─── View Expenses ───────────────────────────────────────
    scores[IntentType.viewExpenses] = _calculateScore(normalized, [
      r'xem.*giao.*d[iị]ch',
      r'xem.*chi.*ti[eê]u',
      r'l[iị]ch.*s[uử]',
      r'danh.*s[aá]ch',
      r'xem.*l[aạ]i',
    ]);

    // Tìm intent có điểm cao nhất
    int maxScore = 0;
    IntentType bestMatch = IntentType.query;

    scores.forEach((intent, score) {
      if (score > maxScore) {
        maxScore = score;
        bestMatch = intent;
      }
    });

    // Nếu không khớp từ khóa nào, gọi AI
    return bestMatch;
  }

  /// Tính điểm dựa trên số lượng Regex pattern khớp
  static int _calculateScore(String text, List<String> patterns) {
    int score = 0;
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        score += 1;
      }
    }
    return score;
  }

  /// Tạo message xác nhận cho từng intent
  static String confirmationMessage(IntentType intent) {
    switch (intent) {
      case IntentType.addExpense:
        return '📝 Đang mở form thêm chi tiêu cho bạn...';
      case IntentType.setBudget:
        return '💰 Đang mở trang thiết lập ngân sách...';
      case IntentType.showStats:
        return '📊 Đang mở trang thống kê cho bạn...';
      case IntentType.viewExpenses:
        return '📋 Đang mở danh sách giao dịch...';
      case IntentType.query:
        return '';
    }
  }

  /// Route name cho từng intent
  static String routeName(IntentType intent) {
    switch (intent) {
      case IntentType.addExpense:
        return '/add-expense';
      case IntentType.setBudget:
        return '/budget';
      case IntentType.showStats:
        return '/statistics';
      case IntentType.viewExpenses:
        return '/expenses';
      case IntentType.query:
        return '';
    }
  }
}
