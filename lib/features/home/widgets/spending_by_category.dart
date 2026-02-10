import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/expense_model.dart';

/// Displays spending by category with animated circular indicators.
class SpendingByCategory extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryTotals;

  const SpendingByCategory({
    super.key,
    required this.categoryTotals,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by amount descending
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalSpending = sorted.fold<double>(0, (sum, e) => sum + e.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.theme.cardTheme.color : Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiêu theo danh mục',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tháng này',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          ...sorted.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value.key;
            final amount = entry.value.value;
            final percentage =
                totalSpending > 0 ? (amount / totalSpending) : 0.0;

            return _CategoryRow(
              category: cat,
              amount: amount,
              percentage: percentage,
            )
                .animate(delay: Duration(milliseconds: 400 + (index * 100)))
                .fade(duration: 400.ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
          }),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 20,
            ),
          ),
          const Gap(12),

          // Category name + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.label,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      amount.toCurrency,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: percentage),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor:
                            category.color.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          category.color,
                        ),
                        minHeight: 6,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Gap(10),
          // Percentage
          SizedBox(
            width: 40,
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
