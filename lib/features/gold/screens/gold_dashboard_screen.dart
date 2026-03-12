import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/providers/gold_provider.dart';
import '../screens/gold_history_screen.dart';

import '../widgets/gold_asset_card.dart';
import '../widgets/gold_summary_card.dart';
import '../widgets/gold_price_table.dart';

class GoldDashboardScreen extends StatefulWidget {
  const GoldDashboardScreen({super.key});

  @override
  State<GoldDashboardScreen> createState() => _GoldDashboardScreenState();
}

class _GoldDashboardScreenState extends State<GoldDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GoldProvider>();
      provider.loadAssets();
      provider.fetchPrices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.of(context).pushNamed('/gold-add').then((_) {
      if (mounted) context.read<GoldProvider>().loadAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<GoldProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              color: AppColors.goldPrimary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // ── Header ─────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader(context, provider)),

                  // ── Summary Card ───────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: GoldSummaryCard(provider: provider),
                    ),
                  ),

                  // ── Tab Bar ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildTabBar(context),
                    ),
                  ),

                  // ── Tab Content ────────────────────────────
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAssetsList(context, provider),
                        _buildPriceTab(context, provider),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(BuildContext context, GoldProvider provider) {
    final apiTimestamp =
        provider.livePrices.isNotEmpty &&
            provider.livePrices.first.updatedAt != null
        ? DateFormat(
            'HH:mm dd/MM/yyyy',
          ).format(provider.livePrices.first.updatedAt!)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldGradient.createShader(bounds),
                child: Text(
                  '🥇 Danh Mục Vàng',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              const Spacer(),
              // History button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GoldHistoryScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.goldPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
              const Gap(8),
              // Refresh price button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<GoldProvider>().fetchPrices(force: true);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.goldPrimary.withOpacity(0.3),
                    ),
                  ),
                  child: provider.isPriceLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.goldPrimary,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.goldPrimary,
                        ),
                ),
              ),
            ],
          ),
          if (apiTimestamp != null) ...[
            const Gap(4),
            Text(
              'Cập nhật lúc: $apiTimestamp',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: context.colorScheme.onSurface.withOpacity(0.5),
        indicator: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Tài Sản Của Tôi'),
          Tab(text: 'Bảng Giá BTMC'),
        ],
      ),
    );
  }

  Widget _buildAssetsList(BuildContext context, GoldProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.goldPrimary),
      );
    }

    final active = provider.activeAssets;

    if (active.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: active.length,
      separatorBuilder: (_, _) => const Gap(12),
      itemBuilder: (context, index) {
        final asset = active[index];
        final profit = provider.getProfitFor(asset);
        final livePrice = provider.getLivePriceFor(asset);
        return GoldAssetCard(
              asset: asset,
              profitResult: profit,
              livePrice: livePrice,
              onTap: () => Navigator.of(
                context,
              ).pushNamed('/gold-detail', arguments: asset),
              onDelete: () => _confirmDelete(context, asset.id, provider),
            )
            .animate()
            .fade(duration: 400.ms, delay: (index * 60).ms)
            .slideY(
              begin: 0.15,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 400.ms,
            );
      },
    );
  }

  Widget _buildPriceTab(BuildContext context, GoldProvider provider) {
    return GoldPriceTable(
      prices: provider.livePrices,
      isLoading: provider.isPriceLoading,
      error: provider.priceError,
      onRefresh: () => provider.fetchPrices(force: true),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                child: const Icon(
                  Icons.savings_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const Gap(16),
              Text(
                'Chưa có tài sản vàng',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Text(
                'Nhấn + để thêm vàng bạn đang giữ',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Gap(32),
              FilledButton.icon(
                onPressed: () => _navigateToAdd(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm Vàng'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fade(duration: 600.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic);
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _navigateToAdd(context);
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldPrimary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
          ),
        )
        .animate(delay: 300.ms)
        .fade()
        .scale(
          begin: const Offset(0, 0),
          curve: Curves.elasticOut,
          duration: 800.ms,
        );
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
        title: const Text('Xoá tài sản?'),
        content: const Text('Bạn có chắc muốn xoá thông tin vàng này?'),
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
    if (confirmed == true && mounted) {
      await provider.deleteAsset(id);
    }
  }
}
