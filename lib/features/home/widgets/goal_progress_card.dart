import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/expense_provider.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final goal = provider.goal;

        if (goal == null) {
          return _buildSetupPrompt(context, provider);
        }

        return _buildGoalProgress(context, goal, provider);
      },
    );
  }

  Widget _buildGoalProgress(
    BuildContext context,
    FinancialGoal goal,
    ExpenseProvider provider,
  ) {
    final isDark = context.isDarkMode;
    final percent = goal.progress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.08),
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
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  size: 20,
                  color: AppColors.info,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mục tiêu: ${goal.title}',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      goal.isAchieved
                          ? 'Đã hoàn thành!'
                          : 'Còn ${goal.remainingAmount.toCurrency}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: goal.isAchieved
                            ? AppColors.success
                            : AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (goal.isAchieved ? AppColors.success : AppColors.info)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percent * 100).toInt()}%',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: goal.isAchieved ? AppColors.success : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: goal.isAchieved
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [
                                const Color(0xFF3B82F6),
                                const Color(0xFF2563EB),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.savedAmount.toCurrency,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                goal.targetAmount.toCurrency,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!goal.isAchieved) ...[
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddSavingsDialog(context, provider);
                },
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Thêm tiền tiết kiệm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  foregroundColor: AppColors.info,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context, ExpenseProvider provider) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSetGoalDialog(context, provider);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDarkMode
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF1E293B).withOpacity(0.8),
                  ]
                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFF3B82F6),
                size: 28,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mục tiêu tài chính',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Thiết lập mục tiêu để tiết kiệm hiệu quả hơn',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetGoalDialog(BuildContext context, ExpenseProvider provider) {
    String title = '';
    String amountStr = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thiết lập mục tiêu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên mục tiêu (VD: Mua xe máy)',
                hintText: 'Nhập tên mục tiêu',
              ),
              onChanged: (val) => title = val,
            ),
            const Gap(16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Số tiền mục tiêu',
                hintText: 'Nhập số tiền',
                suffixText: '₫',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => amountStr = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              final amount =
                  double.tryParse(
                    amountStr.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0;
              if (title.isNotEmpty && amount > 0) {
                provider.setGoal(
                  FinancialGoal(title: title, targetAmount: amount),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAddSavingsDialog(BuildContext context, ExpenseProvider provider) {
    String amountStr = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm tiền tiết kiệm'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Số tiền tiết kiệm thêm',
            hintText: 'Nhập số tiền',
            suffixText: '₫',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: (val) => amountStr = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              final amount =
                  double.tryParse(
                    amountStr.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0;
              if (amount > 0) {
                provider.addSavingsToGoal(amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
