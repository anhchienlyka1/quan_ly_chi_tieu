import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/services/budget_service.dart';

/// A premium card that shows monthly budget progress on the home screen.
/// Displays circular progress, remaining amount, daily budget, and category breakdown.
class BudgetProgressCard extends StatelessWidget {
  final BudgetProgress progress;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!progress.budget.isSet) {
      return _buildSetupPrompt(context);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon,
                    size: 20,
                    color: _statusColor,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngân sách tháng',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _statusMessage,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Percentage badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress.percentSpent * 100).toInt()}%',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Progress bar
            _buildProgressBar(context),
            const Gap(12),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Đã chi',
                    value: progress.totalSpent.toCurrency,
                    color: AppColors.error,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: context.colorScheme.onSurface.withOpacity(0.08),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Còn lại',
                    value: progress.remaining >= 0
                        ? progress.remaining.toCurrency
                        : '−${(-progress.remaining).toCurrency}',
                    color: progress.remaining >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: context.colorScheme.onSurface.withOpacity(0.08),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'TB/ngày',
                    value: progress.dailyBudgetRemaining.toCurrency,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),

            // Category breakdown (if any)
            if (progress.categoryProgress.isNotEmpty) ...[
              const Gap(16),
              Divider(
                color: context.colorScheme.onSurface.withOpacity(0.05),
              ),
              const Gap(8),
              _buildCategoryBreakdown(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final percent = progress.percentSpent.clamp(0.0, 1.5);
    final displayPercent = percent.clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Background
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Progress fill
              FractionallySizedBox(
                widthFactor: displayPercent,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: progress.isOverBudget
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : progress.isNearBudget
                              ? [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFD97706)
                                ]
                              : [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669)
                                ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Month progress indicator line
              Positioned(
                left: (MediaQuery.of(context).size.width - 80) *
                    progress.monthProgress,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: context.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 ₫',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
            Text(
              progress.budget.totalBudget.toCurrency,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final sorted = progress.categoryProgress.entries.toList()
      ..sort((a, b) => b.value.percentSpent.compareTo(a.value.percentSpent));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theo danh mục',
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const Gap(8),
        ...sorted.take(4).map((entry) {
          final cat = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(cat.category.icon, size: 16, color: cat.category.color),
                const Gap(8),
                Expanded(
                  flex: 3,
                  child: Text(
                    cat.category.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: cat.percentSpent.clamp(0.0, 1.0),
                      backgroundColor: cat.category.color.withOpacity(0.1),
                      color: cat.isOverBudget
                          ? AppColors.error
                          : cat.category.color,
                      minHeight: 6,
                    ),
                  ),
                ),
                const Gap(8),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${(cat.percentSpent * 100).toInt()}%',
                    textAlign: TextAlign.right,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cat.isOverBudget
                          ? AppColors.error
                          : context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSetupPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.pushNamed(RouteNames.budget);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.isDarkMode
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF1E293B).withOpacity(0.8)
                  ]
                : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.savings_rounded,
                color: Color(0xFF10B981),
                size: 28,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thiết lập ngân sách',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Đặt giới hạn chi tiêu hàng tháng để quản lý tài chính hiệu quả hơn',
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
                color: const Color(0xFF10B981),
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

  // Status helpers
  Color get _statusColor {
    if (progress.isOverBudget) return const Color(0xFFEF4444);
    if (progress.isNearBudget) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  IconData get _statusIcon {
    if (progress.isOverBudget) return Icons.warning_rounded;
    if (progress.isNearBudget) return Icons.info_rounded;
    return Icons.check_circle_rounded;
  }

  String get _statusMessage {
    if (progress.isOverBudget) {
      return 'Vượt ngân sách ${(-progress.remaining).toCurrency}!';
    }
    if (progress.isNearBudget) {
      return 'Sắp hết ngân sách - Hãy cẩn thận!';
    }
    final pct = (progress.percentSpent * 100).toInt();
    return 'Đang trong ngân sách ($pct% đã dùng)';
  }
}
