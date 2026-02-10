import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/expense_model.dart';

/// A single expense item in the recent expenses list.
/// Shows category icon, title, who paid, amount, and payment method.
class RecentExpenseItem extends StatelessWidget {
  final ExpenseModel expense;

  const RecentExpenseItem({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: expense.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                expense.category.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const Gap(14),

          // Title & meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Row(
                  children: [
                    // Spender tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: expense.spender.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expense.spender.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: expense.spender.color,
                        ),
                      ),
                    ),
                    const Gap(8),
                    // Payment method icon
                    Icon(
                      expense.paymentMethod.icon,
                      size: 12,
                      color: context.colorScheme.onSurface.withOpacity(0.35),
                    ),
                    const Gap(4),
                    // Date
                    Text(
                      expense.date.toRelativeDate(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color:
                            context.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '-${expense.amount.toCurrency}',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
