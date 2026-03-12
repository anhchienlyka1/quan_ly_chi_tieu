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
import '../widgets/sell_gold_bottom_sheet.dart';

/// Detailed view of a single gold asset showing full P&L breakdown.
class GoldDetailScreen extends StatelessWidget {
  final GoldAssetModel asset;

  const GoldDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<GoldProvider>(
          builder: (context, provider, _) {
            final profitResult = asset.isSold
                ? null
                : provider.getProfitFor(asset);
            final livePrice = asset.isSold
                ? null
                : provider.getLivePriceFor(asset);
            final isProfit = asset.isSold
                ? (asset.realizedProfit == null || asset.realizedProfit! >= 0)
                : (profitResult == null || profitResult.isProfit);
            final profitColor = isProfit ? AppColors.success : AppColors.error;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, provider, isProfit, profitColor),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Price Banner (only for active holdings)
                        if (livePrice != null)
                          _buildLivePriceBanner(
                            context,
                            livePrice.buyPrice,
                          ).animate().fade(duration: 500.ms, delay: 200.ms),
                        const Gap(20),

                        // Purchase info card
                        _buildInfoCard(context),
                        const Gap(16),

                        // Profit breakdown card
                        if (asset.isSold && asset.realizedProfit != null)
                          _buildRealizedProfitCard(context, profitColor)
                        else if (profitResult != null)
                          _buildProfitCard(context, profitResult, profitColor),
                        const Gap(24),

                        // Action buttons
                        _buildActions(context, provider),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GoldProvider provider,
    bool isProfit,
    Color profitColor,
  ) {
    final profitResult = provider.getProfitFor(asset);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: context.isDarkMode
            ? AppColors.goldCardGradient
            : LinearGradient(
                colors: [
                  AppColors.goldPrimary.withOpacity(0.1),
                  AppColors.goldShimmer.withOpacity(0.15),
                ],
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + sold badge row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (asset.isSold)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sell_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      Gap(6),
                      Text(
                        'Đã Bán',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(20),

          // Gold type name
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              asset.goldTypeName,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const Gap(4),
          Text(
            '${asset.quantity} ${asset.unit.abbr}  •  ${DateFormat('dd/MM/yyyy').format(asset.purchaseDate)}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const Gap(20),

          // Big value display
          Text(
            asset.isSold
                ? (asset.sellTotalRevenue?.toCurrency ??
                      asset.totalCost.toCurrency)
                : (profitResult != null
                      ? profitResult.currentValue.toCurrency
                      : asset.totalCost.toCurrency),
            style: context.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: context.isDarkMode
                  ? AppColors.goldShimmer
                  : AppColors.goldDark,
              fontSize: 34,
            ),
          ),
          Text(
            asset.isSold
                ? 'Tổng thu khi bán'
                : (profitResult != null
                      ? 'Giá trị hiện tại (Tiệm mua vào)'
                      : 'Tổng vốn đầu tư'),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),

          // Profit/Loss badge
          if (asset.isSold && asset.realizedProfit != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isProfit
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isProfit
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProfit
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: isProfit ? AppColors.success : AppColors.error,
                  ),
                  const Gap(6),
                  Text(
                    '${asset.realizedProfit! >= 0 ? '+' : ''}${asset.realizedProfit!.toCurrency}'
                    '  (${asset.realizedProfit! >= 0 ? '+' : ''}${asset.realizedProfitPercent?.toStringAsFixed(2) ?? '0.00'}%)',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isProfit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (profitResult != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isProfit
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isProfit
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProfit
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: isProfit ? AppColors.success : AppColors.error,
                  ),
                  const Gap(6),
                  Text(
                    '${profitResult.profitSign}${profitResult.profit.toCurrency}'
                    '  (${profitResult.profitSign}${profitResult.profitPercent.toStringAsFixed(2)}%)',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isProfit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildLivePriceBanner(BuildContext context, double currentPrice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: AppColors.goldPrimary,
            size: 18,
          ),
          const Gap(8),
          Text(
            'Giá thu mua BTMC hiện tại: ',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            '${currentPrice.toCurrency}/chỉ',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.goldDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final sold = asset.isSold;
    return _DetailCard(
      title: 'Thông Tin Mua',
      icon: Icons.shopping_bag_rounded,
      children: [
        _DetailRow(
          'Ngày mua',
          DateFormat('dd/MM/yyyy').format(asset.purchaseDate),
        ),
        _DetailRow('Số lượng', '${asset.quantity} ${asset.unit.abbr}'),
        _DetailRow(
          'Quy đổi',
          '${asset.quantityInLuong.toStringAsFixed(2)} lượng',
        ),
        _DetailRow(
          'Giá mua / ${asset.unit.abbr}',
          asset.pricePerUnit.toCurrency,
        ),
        if (asset.fee > 0) _DetailRow('Phí mua', asset.fee.toCurrency),
        _DetailRow('Tổng vốn', asset.totalCost.toCurrency, isHighlight: true),
        if (asset.note != null && asset.note!.isNotEmpty)
          _DetailRow('Ghi chú', asset.note!),
        // Sell info (when sold)
        if (sold) ...[
          const Divider(height: 1),
          const Gap(8),
          _DetailRow(
            'Ngày bán',
            DateFormat('dd/MM/yyyy').format(asset.sellDate!),
          ),
          _DetailRow(
            'Giá bán / ${asset.unit.abbr}',
            asset.sellPricePerUnit?.toCurrency ?? '--',
          ),
          _DetailRow(
            'Tổng thu',
            asset.sellTotalRevenue?.toCurrency ?? '--',
            isHighlight: true,
            highlightColor: AppColors.success,
          ),
          if (asset.sellNote != null && asset.sellNote!.isNotEmpty)
            _DetailRow('Ghi chú bán', asset.sellNote!),
        ],
      ],
    );
  }

  Widget _buildRealizedProfitCard(BuildContext context, Color profitColor) {
    final profit = asset.realizedProfit!;
    final isProfit = profit >= 0;
    return _DetailCard(
      title: isProfit ? '📈 Lãi Thực Tế' : '📉 Lỗ Thực Tế',
      icon: isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      iconColor: profitColor,
      children: [
        _DetailRow('Tổng vốn', asset.totalCost.toCurrency),
        _DetailRow(
          'Tổng thu',
          asset.sellTotalRevenue?.toCurrency ?? '--',
          isHighlight: true,
          highlightColor: AppColors.goldDark,
        ),
        const Divider(height: 1),
        const Gap(8),
        _DetailRow(
          isProfit ? 'Lãi tuyệt đối' : 'Lỗ tuyệt đối',
          '${profit >= 0 ? '+' : ''}${profit.toCurrency}',
          valueColor: profitColor,
          isBold: true,
        ),
        if (asset.realizedProfitPercent != null)
          _DetailRow(
            'Tỷ lệ',
            '${profit >= 0 ? '+' : ''}${asset.realizedProfitPercent!.toStringAsFixed(2)}%',
            valueColor: profitColor,
            isBold: true,
          ),
      ],
    );
  }

  Widget _buildProfitCard(
    BuildContext context,
    GoldProfitResult result,
    Color profitColor,
  ) {
    return _DetailCard(
      title: result.isProfit ? '📈 Phân Tích Lãi' : '📉 Phân Tích Lỗ',
      icon: result.isProfit
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded,
      iconColor: profitColor,
      children: [
        _DetailRow('Giá vốn', asset.totalCost.toCurrency),
        _DetailRow(
          'Giá trị hiện tại',
          result.currentValue.toCurrency,
          isHighlight: true,
          highlightColor: AppColors.goldDark,
        ),
        const Divider(height: 1),
        const Gap(8),
        _DetailRow(
          result.isProfit ? 'Lãi tuyệt đối' : 'Lỗ tuyệt đối',
          '${result.profitSign}${result.profit.toCurrency}',
          valueColor: profitColor,
          isBold: true,
        ),
        _DetailRow(
          'Tỷ lệ',
          '${result.profitSign}${result.profitPercent.toStringAsFixed(2)}%',
          valueColor: profitColor,
          isBold: true,
        ),
        _DetailRow(
          'Mỗi ${asset.unit.abbr}',
          '${result.profitSign}${(result.profit / asset.quantity).toCurrency}',
          valueColor: profitColor,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, GoldProvider provider) {
    if (asset.isSold) {
      // For sold assets: show Revert and Delete
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hoàn tác bán?'),
                    content: const Text(
                      'Chuyển tài sản trở lại trạng thái đang giữ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Huỷ'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldPrimary,
                        ),
                        child: const Text('Hoàn tác'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await provider.revertSell(asset.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Hoàn Tác'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldPrimary,
                side: const BorderSide(color: AppColors.goldPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xoá giao dịch?'),
                    content: const Text(
                      'Xoá hoàn toàn khỏi lịch sử? Không thể khôi phục.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Huỷ'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Xoá'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await provider.deleteAsset(asset.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Xoá'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Active asset: Edit | Sell | Delete
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(
                    context,
                  ).pushNamed('/gold-add', arguments: asset);
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Sửa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldPrimary,
                  side: const BorderSide(color: AppColors.goldPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xoá tài sản?'),
                      content: Text(
                        'Bạn có chắc muốn xoá "${asset.goldTypeName}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Huỷ'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Xoá'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await provider.deleteAsset(asset.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Xoá'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        // Sell button (full width)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final sold = await SellGoldBottomSheet.show(context, asset);
              if (sold == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.sell_rounded, size: 18, color: Colors.black),
            label: const Text(
              'Đánh Dấu Đã Bán',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldPrimary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? AppColors.goldPrimary),
              const Gap(8),
              Text(
                title,
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: iconColor ?? AppColors.goldPrimary,
                ),
              ),
            ],
          ),
          const Gap(14),
          const Divider(height: 1),
          const Gap(14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow(
    this.label,
    this.value, {
    this.isHighlight = false,
    this.highlightColor,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: (isHighlight || isBold)
                  ? FontWeight.w800
                  : FontWeight.w600,
              color:
                  valueColor ??
                  (isHighlight
                      ? (highlightColor ?? AppColors.goldDark)
                      : context.colorScheme.onSurface),
              fontSize: isHighlight ? 15 : null,
            ),
          ),
        ],
      ),
    );
  }
}
