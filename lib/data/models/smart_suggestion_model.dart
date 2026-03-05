/// Type of smart suggestion
enum SuggestionType {
  warning, // ⚠️ Cảnh báo chi tiêu
  tip, // 💡 Mẹo tiết kiệm
  praise, // 🎉 Khen thưởng
  insight, // 📊 Insight thú vị
}

/// A smart suggestion generated from spending pattern analysis
class SmartSuggestion {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final SuggestionType type;
  final DateTime createdAt;
  final String? actionLabel; // e.g "Đặt budget" / "Xem chi tiết"
  final String? actionRoute; // route to navigate to

  const SmartSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.createdAt,
    this.actionLabel,
    this.actionRoute,
  });
}
