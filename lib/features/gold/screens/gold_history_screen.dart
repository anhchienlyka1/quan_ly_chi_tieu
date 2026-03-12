import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/gold_asset_model.dart';
import '../../../data/providers/gold_provider.dart';

/// Screen showing a full historical log of all sold gold transactions.
class GoldHistoryScreen extends StatelessWidget {
  const GoldHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<GoldProvider>(
          builder: (context, provider, _) {
            final sold = provider.soldAssets;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, provider)),
                if (sold.isEmpty)
                  SliverFillRemaining(child: _buildEmpty(context))
                else ...[
                  // Summary banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _buildSummaryBanner(context, provider),
                    ),
                  ),
                  // Transaction list
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final asset = sold[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child:
                            _SoldItemCard(
                                  asset: asset,
                                  onRevert: () =>
                                      _confirmRevert(context, asset, provider),
                                  onDelete: () => _confirmDelete(
                                    context,
                                    asset.id,
                                    provider,
                                  ),
                                )
                                .animate()
                                .fade(duration: 400.ms, delay: (index * 50).ms)
                                .slideY(
                                  begin: 0.12,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                  duration: 400.ms,
                                ),
                      );
                    }, childCount: sold.length),
                  ),
                  const SliverToBoxAdapter(child: Gap(80)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GoldProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              '📒 Lịch Sử Giao Dịch Vàng',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: -0.08, end: 0);
  }

  Widget _buildSummaryBanner(BuildContext context, GoldProvider provider) {
    final profit = provider.totalRealizedProfit;
    final isProfit = profit >= 0;
    final profitColor = isProfit ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.goldCardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Số giao dịch',
              value: '${provider.soldAssets.length}',
              icon: Icons.receipt_long_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: _SummaryItem(
              label: 'Tổng thu',
              value: provider.totalSellRevenue.toCurrency,
              icon: Icons.payments_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: _SummaryItem(
              label: isProfit ? 'Tổng lãi' : 'Tổng lỗ',
              value: profit.abs().toCurrency,
              icon: isProfit
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              valueColor: profitColor,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                child: const Icon(
                  Icons.history_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const Gap(16),
              Text(
                'Chưa có lịch sử bán vàng',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Text(
                'Ghi nhận bán vàng từ màn chi tiết tài sản',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
        .animate()
        .fade(duration: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic);
  }

  Future<void> _confirmRevert(
    BuildContext context,
    GoldAssetModel asset,
    GoldProvider provider,
  ) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn tác bán?'),
        content: Text('Chuyển "${asset.goldTypeName}" trở lại đang giữ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldPrimary),
            child: const Text('Hoàn tác'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.revertSell(asset.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    GoldProvider provider,
  ) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: const Text('Bạn có chắc muốn xoá giao dịch này khỏi lịch sử?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteAsset(id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.8)),
        const Gap(4),
        Text(
          value,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SoldItemCard extends StatelessWidget {
  final GoldAssetModel asset;
  final VoidCallback onRevert;
  final VoidCallback onDelete;

  const _SoldItemCard({
    required this.asset,
    required this.onRevert,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final profit = asset.realizedProfit;
    final isProfit = profit == null || profit >= 0;
    final profitColor = isProfit ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isProfit
              ? AppColors.success.withOpacity(0.25)
              : AppColors.error.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sell_rounded,
                  color: AppColors.success,
                  size: 20,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${asset.quantity} ${asset.unit.abbr}  •  Bán ${DateFormat('dd/MM/yyyy').format(asset.sellDate ?? asset.purchaseDate)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Sold badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: const Text(
                  '✅ Đã bán',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          Divider(height: 1, color: AppColors.goldPrimary.withOpacity(0.1)),
          const Gap(14),

          // Price info
          Row(
            children: [
              Expanded(
                child: _PriceCell(
                  label: 'Giá mua / ${asset.unit.abbr}',
                  value: asset.pricePerUnit.toCurrency,
                ),
              ),
              Expanded(
                child: _PriceCell(
                  label: 'Giá bán / ${asset.unit.abbr}',
                  value: asset.sellPricePerUnit?.toCurrency ?? '--',
                  valueColor: AppColors.goldDark,
                ),
              ),
              Expanded(
                child: _PriceCell(
                  label: 'Tổng thu',
                  value: asset.sellTotalRevenue?.toCurrency ?? '--',
                  align: TextAlign.right,
                ),
              ),
            ],
          ),

          // P&L row
          if (profit != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: profitColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: profitColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isProfit ? '📈 Lãi thực tế' : '📉 Lỗ thực tế',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}${profit.toCurrency}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (asset.realizedProfitPercent != null)
                    Text(
                      '${isProfit ? '+' : ''}${asset.realizedProfitPercent!.toStringAsFixed(2)}%',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: profitColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Note
          if (asset.sellNote != null) ...[
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 14,
                  color: context.colorScheme.onSurface.withOpacity(0.4),
                ),
                const Gap(6),
                Expanded(
                  child: Text(
                    asset.sellNote!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.55),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const Gap(14),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRevert,
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Hoàn tác'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
              const Gap(4),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Xoá'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextAlign align;

  const _PriceCell({
    required this.label,
    required this.value,
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
          textAlign: align,
        ),
        const Gap(2),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: valueColor ?? context.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
        ),
      ],
    );
  }
}
