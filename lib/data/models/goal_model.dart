class FinancialGoal {
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;

  const FinancialGoal({
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
  });

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isAchieved => savedAmount >= targetAmount;
  double get remainingAmount => targetAmount - savedAmount;

  Map<String, dynamic> toJson() => {
    'title': title,
    'targetAmount': targetAmount,
    'savedAmount': savedAmount,
    'deadline': deadline?.toIso8601String(),
  };

  factory FinancialGoal.fromJson(Map<String, dynamic> json) => FinancialGoal(
    title: json['title'] as String,
    targetAmount: (json['targetAmount'] as num).toDouble(),
    savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
    deadline: json['deadline'] != null
        ? DateTime.tryParse(json['deadline'] as String)
        : null,
  );
}
