import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../screens/statistics_screen.dart';

class PeriodComparisonCard extends StatelessWidget {
  final double currentIncome;
  final double currentExpense;
  final double prevIncome;
  final double prevExpense;
  final StatsPeriod period;

  const PeriodComparisonCard({
    super.key,
    required this.currentIncome,
    required this.currentExpense,
    required this.prevIncome,
    required this.prevExpense,
    required this.period,
  });

  String get _prevLabel {
    switch (period) {
      case StatsPeriod.week:
        return 'Tuần trước';
      case StatsPeriod.month:
        return 'Tháng trước';
      case StatsPeriod.year:
        return 'Năm trước';
    }
  }

  String get _currentLabel {
    switch (period) {
      case StatsPeriod.week:
        return 'Tuần này';
      case StatsPeriod.month:
        return 'Tháng này';
      case StatsPeriod.year:
        return 'Năm nay';
    }
  }

  double _pctChange(double current, double prev) {
    if (prev == 0) return 0;
    return ((current - prev) / prev) * 100;
  }

  @override
  Widget build(BuildContext context) {
    // Only show if we have some prior period data
    final hasPrevData = prevIncome > 0 || prevExpense > 0;
    if (!hasPrevData) return const SizedBox.shrink();

    final expenseChange = _pctChange(currentExpense, prevExpense);
    final incomeChange = _pctChange(currentIncome, prevIncome);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? context.theme.cardTheme.color
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const Gap(12),
              Text(
                'So sánh kỳ trước',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(16),

          // Column headers
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox.shrink()),
              Expanded(
                flex: 3,
                child: Text(
                  _prevLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _currentLabel,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Expanded(flex: 2, child: SizedBox.shrink()),
            ],
          ),

          const Gap(10),
          const Divider(height: 1),
          const Gap(10),

          // Income row
          _ComparisonRow(
            label: 'Thu nhập',
            icon: Icons.arrow_downward_rounded,
            iconColor: const Color(0xFF4ADE80),
            prevValue: prevIncome,
            currentValue: currentIncome,
            pctChange: incomeChange,
            positiveIsGood: true,
          ),

          const Gap(8),

          // Expense row
          _ComparisonRow(
            label: 'Chi tiêu',
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFFFB7185),
            prevValue: prevExpense,
            currentValue: currentExpense,
            pctChange: expenseChange,
            positiveIsGood: false,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final double prevValue;
  final double currentValue;
  final double pctChange;
  final bool positiveIsGood;

  const _ComparisonRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.prevValue,
    required this.currentValue,
    required this.pctChange,
    required this.positiveIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = pctChange >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final changeColor = isGood
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFB7185);
    final changeIcon = isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    final pctText = '${pctChange.abs().toStringAsFixed(1)}%';

    return Row(
      children: [
        // Label
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const Gap(4),
              Flexible(
                child: Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Prev value
        Expanded(
          flex: 3,
          child: Text(
            prevValue.toCurrency,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Current value
        Expanded(
          flex: 3,
          child: Text(
            currentValue.toCurrency,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Change badge
        Expanded(
          flex: 2,
          child: pctChange == 0
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(changeIcon, size: 12, color: changeColor),
                      Text(
                        pctText,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
