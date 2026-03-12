import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/gold_asset_model.dart';
import '../../../data/models/gold_price_model.dart';

/// Card for each gold asset showing purchase info + real-time P&L.
class GoldAssetCard extends StatelessWidget {
  final GoldAssetModel asset;
  final GoldProfitResult? profitResult;
  final GoldPriceModel? livePrice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GoldAssetCard({
    super.key,
    required this.asset,
    required this.profitResult,
    required this.livePrice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfit = profitResult != null;
    final isProfit = hasProfit && profitResult!.isProfit;
    final profitColor = isProfit ? AppColors.success : AppColors.error;
    final sold = asset.isSold;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sold
                ? AppColors.success.withOpacity(0.3)
                : AppColors.goldPrimary.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row ──────────────────────────────────────
            Row(
              children: [
                // Gold icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.goldTypeName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        '${asset.quantity} ${asset.unit.abbr} • ${DateFormat('dd/MM/yyyy').format(asset.purchaseDate)}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (sold)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      '✅ Đã bán',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  )
                else
                  // Delete button
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: context.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
              ],
            ),

            const Gap(14),
            Divider(height: 1, color: AppColors.goldPrimary.withOpacity(0.15)),
            const Gap(14),

            // ── Price Row ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PriceCell(
                    label: 'Giá Mua',
                    value: asset.pricePerUnit.toCurrency,
                    sub: '/ ${asset.unit.abbr}',
                  ),
                ),
                Expanded(
                  child: _PriceCell(
                    label: 'Giá Hiện Tại',
                    value: livePrice != null
                        ? livePrice!.buyPrice.toCurrency
                        : '--',
                    sub: '/ chỉ',
                    valueColor: AppColors.goldDark,
                  ),
                ),
                Expanded(
                  child: _PriceCell(
                    label: 'Tổng Vốn',
                    value: asset.totalCost.toCurrency,
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),

            // ── P&L Row ───────────────────────────────────────
            if (sold && asset.realizedProfit != null) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      (asset.realizedProfit! >= 0
                              ? AppColors.success
                              : AppColors.error)
                          .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (asset.realizedProfit! >= 0
                                ? AppColors.success
                                : AppColors.error)
                            .withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      asset.realizedProfit! >= 0
                          ? '📈 Lãi thực tế'
                          : '📉 Lỗ thực tế',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: asset.realizedProfit! >= 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${asset.realizedProfit! >= 0 ? '+' : ''}${asset.realizedProfit!.toCurrency}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: asset.realizedProfit! >= 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (asset.realizedProfitPercent != null)
                      Text(
                        '${asset.realizedProfit! >= 0 ? '+' : ''}${asset.realizedProfitPercent!.toStringAsFixed(2)}%',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: asset.realizedProfit! >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ] else if (hasProfit) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: profitColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isProfit ? '📈 Lãi' : '📉 Lỗ',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: profitColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${profitResult!.profitSign}${profitResult!.profit.toCurrency}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: profitColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${profitResult!.profitSign}${profitResult!.profitPercent.toStringAsFixed(2)}%',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: profitColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final TextAlign align;

  const _PriceCell({
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.45),
            fontSize: 10,
          ),
        ),
        const Gap(2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: valueColor ?? context.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sub != null) ...[
              const Gap(1),
              Text(
                sub!,
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
