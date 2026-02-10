import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';

/// Horizontal comparison bar showing husband vs wife spending.
/// Emphasizes harmony — no judgment, just transparency.
class CoupleSpendingBar extends StatelessWidget {
  final double husbandAmount;
  final double wifeAmount;

  const CoupleSpendingBar({
    super.key,
    required this.husbandAmount,
    required this.wifeAmount,
  });

  @override
  Widget build(BuildContext context) {
    final total = husbandAmount + wifeAmount;
    final husbandRatio = total > 0 ? husbandAmount / total : 0.5;
    final wifeRatio = total > 0 ? wifeAmount / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.people_rounded,
                  size: 18, color: context.colorScheme.onSurface.withOpacity(0.5)),
              const Gap(8),
              Text(
                'Chi tiêu hai vợ chồng',
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const Gap(14),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: (husbandRatio * 100).round(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.husband,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    flex: (wifeRatio * 100).round(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.wife,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(14),

          // Legend
          Row(
            children: [
              _buildLegend(
                context,
                color: AppColors.husband,
                label: 'Chồng',
                amount: husbandAmount,
                percentage: (husbandRatio * 100).round(),
              ),
              const Gap(16),
              _buildLegend(
                context,
                color: AppColors.wife,
                label: 'Vợ',
                amount: wifeAmount,
                percentage: (wifeRatio * 100).round(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context, {
    required Color color,
    required String label,
    required double amount,
    required int percentage,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ($percentage%)',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                Text(
                  amount.toCurrency,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
