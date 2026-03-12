import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/providers/gold_provider.dart';

/// Summary card showing total portfolio value, invested, and P&L.
class GoldSummaryCard extends StatelessWidget {
  final GoldProvider provider;

  const GoldSummaryCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final hasData = provider.hasAssets;
    final profit = provider.totalProfit;
    final profitPct = provider.totalProfitPercent;
    final isProfit = profit >= 0;

    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: context.isDarkMode
                ? AppColors.goldCardGradient
                : LinearGradient(
                    colors: [
                      AppColors.goldPrimary.withOpacity(0.08),
                      AppColors.goldShimmer.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.goldPrimary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.goldGradient.createShader(b),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Tổng Quan Danh Mục',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Current value
              Text(
                hasData ? provider.totalCurrentValue.toCurrency : '₫ ---',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.isDarkMode
                      ? AppColors.goldShimmer
                      : AppColors.goldDark,
                  fontSize: 30,
                ),
              ),
              Text(
                'Giá trị hiện tại (giá tiệm thu mua)',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Gap(20),

              // Invested vs Profit row
              Row(
                children: [
                  Expanded(
                    child: _InfoCell(
                      label: 'Tổng Đầu Tư',
                      value: hasData
                          ? provider.totalInvested.toCurrency
                          : '₫ ---',
                      valueColor: context.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.goldPrimary.withOpacity(0.2),
                  ),
                  Expanded(
                    child: _InfoCell(
                      label: hasData
                          ? (isProfit
                                ? '📈 Lãi ${profitPct.toStringAsFixed(1)}%'
                                : '📉 Lỗ ${profitPct.abs().toStringAsFixed(1)}%')
                          : 'Lãi / Lỗ',
                      value: hasData
                          ? '${isProfit ? '+' : ''}${profit.toCurrency}'
                          : '₫ ---',
                      valueColor: hasData
                          ? (isProfit ? AppColors.success : AppColors.error)
                          : context.colorScheme.onSurface,
                      align: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fade(duration: 600.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final TextAlign align;

  const _InfoCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
