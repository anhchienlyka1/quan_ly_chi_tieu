import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../app/routes/route_names.dart';

/// Card displayed on the home screen summarising fixed monthly expenses.
/// Only shown when at least one fixed expense has been set up.
class FixedExpenseSummaryCard extends StatelessWidget {
  const FixedExpenseSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.fixedExpenses.isEmpty) return const SizedBox.shrink();

        final totalFixed = provider.totalFixedExpenses;
        final totalIncome = provider.totalIncome;
        final available = provider.availableIncome;
        final pct =
            totalIncome > 0 ? (totalFixed / totalIncome * 100).round() : 0;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, RouteNames.budget),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1E1E2C)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(context.isDarkMode ? 0.15 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.repeat_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      'Khoản cố định tháng này',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
                const Gap(14),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalIncome > 0
                        ? (totalFixed / totalIncome).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor:
                        context.colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct > 70 ? Colors.redAccent : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const Gap(12),
                // Metrics row
                Row(
                  children: [
                    _metric(
                      context,
                      label: 'Cố định',
                      value: _fmt(totalFixed),
                      color: AppColors.error,
                    ),
                    const Spacer(),
                    _metric(
                      context,
                      label: 'Thu nhập',
                      value: _fmt(totalIncome),
                      color: AppColors.success,
                      align: CrossAxisAlignment.center,
                    ),
                    const Spacer(),
                    _metric(
                      context,
                      label: 'Còn lại',
                      value: _fmt(available),
                      color: available >= 0 ? AppColors.success : Colors.red,
                      align: CrossAxisAlignment.end,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _fmt(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr₫';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K₫';
    }
    return '${amount.toStringAsFixed(0)}₫';
  }
}
