import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';

/// Card showing expense summary (total, income, balance) for the current month.
class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Chi tiết →',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            '0 ₫',
            style: context.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(4),
          Text(
            'Tổng chi tiêu',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Thu nhập',
                  amount: '0 ₫',
                  iconColor: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.arrow_downward_rounded,
                  label: 'Chi tiêu',
                  amount: '0 ₫',
                  iconColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String amount,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const Gap(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              amount,
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
