import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';

/// Premium glassmorphism balance card showing total balance, income, expense.
class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String monthLabel;
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.monthLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF8B5CF6),
              Color(0xFFA78BFA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      monthLabel,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chi tiết',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Total balance label
            Text(
              'Tổng số dư',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(6),
            Text(
              totalBalance.toCurrency,
              style: context.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Gap(24),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            const Gap(20),

            // Income and expense row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.trending_up_rounded,
                    label: 'Thu nhập',
                    amount: totalIncome.toCurrency,
                    iconBgColor: AppColors.success.withOpacity(0.3),
                    iconColor: const Color(0xFF4ADE80),
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.trending_down_rounded,
                    label: 'Chi tiêu',
                    amount: totalExpense.toCurrency,
                    iconBgColor: AppColors.error.withOpacity(0.3),
                    iconColor: const Color(0xFFFB7185),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String amount,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const Gap(10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            const Gap(2),
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
