import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../widgets/expense_summary_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản Lý Chi Tiêu'),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pushNamed(RouteNames.settings);
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting
                _buildGreeting(context)
                    .animate()
                    .fade(duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),
                const Gap(24),

                // Summary Card
                const ExpenseSummaryCard()
                    .animate(delay: 100.ms)
                    .fade(duration: 600.ms)
                    .slideY(begin: 0.15, end: 0),
                const Gap(32),

                // Quick Actions
                _buildSectionTitle(context, 'Thao tác nhanh')
                    .animate(delay: 200.ms)
                    .fade(),
                const Gap(16),
                _buildQuickActions(context),
                const Gap(32),

                // Recent Expenses
                _buildSectionTitle(context, 'Chi tiêu gần đây')
                    .animate(delay: 400.ms)
                    .fade(),
                const Gap(16),
                _buildEmptyState(context)
                    .animate(delay: 500.ms)
                    .fade()
                    .scale(begin: const Offset(0.95, 0.95)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.pushNamed(RouteNames.addExpense);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm chi tiêu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ).animate(delay: 600.ms).fade().slideY(begin: 1, end: 0),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Chào buổi sáng! ☀️';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều! 🌤️';
    } else {
      greeting = 'Chào buổi tối! 🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const Gap(4),
        Text(
          'Quản lý tài chính thông minh',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.list_alt_rounded,
            label: 'Danh sách',
            color: AppColors.info,
            onTap: () => context.pushNamed(RouteNames.expenseList),
          ).animate(delay: 300.ms).fade().slideY(begin: 0.2, end: 0),
        ),
        const Gap(12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.bar_chart_rounded,
            label: 'Thống kê',
            color: AppColors.success,
            onTap: () => context.pushNamed(RouteNames.statistics),
          ).animate(delay: 350.ms).fade().slideY(begin: 0.2, end: 0),
        ),
        const Gap(12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.account_balance_wallet_rounded,
            label: 'Ngân sách',
            color: AppColors.warning,
            onTap: () {},
          ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: context.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Gap(10),
              Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: context.colorScheme.onSurface.withOpacity(0.2),
          ),
          const Gap(12),
          Text(
            'Chưa có chi tiêu nào',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const Gap(4),
          Text(
            'Nhấn nút + để thêm chi tiêu đầu tiên',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
