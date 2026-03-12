import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/gold_price_model.dart';

/// Displays the BTMC live gold price table.
/// Sử dụng ListView.builder để tránh overflow khi có nhiều rows (36+)
/// trong TabBarView với height cố định.
class GoldPriceTable extends StatelessWidget {
  final List<GoldPriceModel> prices;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const GoldPriceTable({
    super.key,
    required this.prices,
    required this.isLoading,
    this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && prices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.goldPrimary),
      );
    }

    if (error != null && prices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: context.colorScheme.onSurface.withOpacity(0.3),
            ),
            const Gap(12),
            Text(
              'Không thể tải giá vàng',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const Gap(8),
            Text(
              'Kiểm tra kết nối mạng',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const Gap(20),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    // index 0 = header, index 1+ = rows
    final itemCount = 1 + prices.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // ── Header ──────────────────────────────────────────────
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Loại Vàng',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _HeaderCell('Mua (/chỉ)'),
                  _HeaderCell('Bán (/chỉ)'),
                ],
              ),
            ),
          );
        }

        // ── Price row ───────────────────────────────────────────
        final idx = index - 1;
        final price = prices[idx];
        final isEven = idx % 2 == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isEven
                ? (context.isDarkMode
                      ? Colors.white.withOpacity(0.04)
                      : AppColors.goldPrimary.withOpacity(0.04))
                : (context.isDarkMode ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldPrimary.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.shortName,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurface,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (price.purity.isNotEmpty && price.purity != '0')
                      Text(
                        '${price.karat} • ${price.purity}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              _PriceCell(value: price.buyPrice, color: AppColors.info),
              _PriceCell(value: price.sellPrice, color: AppColors.success),
            ],
          ),
        );
      },
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  final double value;
  final Color color;
  const _PriceCell({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    // Format vi_VN: dấu ',' là phần thập phân, dấu '.' là phân cách nghìn
    final formatted = value >= 1000000
        ? '${(value / 1000000).toStringAsFixed(2).replaceAll('.', ',')}M'
        : value >= 1000
        ? '${(value / 1000).toStringAsFixed(0)}K'
        : value.toStringAsFixed(0);

    return Expanded(
      flex: 2,
      child: Text(
        formatted,
        textAlign: TextAlign.right,
        style: context.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
