import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/category_grid.dart';
import '../widgets/recent_expense_item.dart';
import '../widgets/couple_spending_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Mock data for UI demonstration
  List<ExpenseModel> get _mockExpenses => [
        ExpenseModel(
          id: '1',
          title: 'Đi chợ buổi sáng',
          amount: 185000,
          category: ExpenseCategory.food,
          date: DateTime.now(),
          spender: SpenderType.wife,
          paymentMethod: PaymentMethod.cash,
        ),
        ExpenseModel(
          id: '2',
          title: 'Đổ xăng xe máy',
          amount: 80000,
          category: ExpenseCategory.transport,
          date: DateTime.now(),
          spender: SpenderType.husband,
          paymentMethod: PaymentMethod.cash,
        ),
        ExpenseModel(
          id: '3',
          title: 'Tiền điện tháng 2',
          amount: 450000,
          category: ExpenseCategory.utilities,
          date: DateTime.now().subtract(const Duration(days: 1)),
          spender: SpenderType.husband,
          paymentMethod: PaymentMethod.bankTransfer,
        ),
        ExpenseModel(
          id: '4',
          title: 'Sữa và tã cho bé',
          amount: 320000,
          category: ExpenseCategory.children,
          date: DateTime.now().subtract(const Duration(days: 1)),
          spender: SpenderType.wife,
          paymentMethod: PaymentMethod.bankTransfer,
        ),
        ExpenseModel(
          id: '5',
          title: 'Tiền nhà tháng 2',
          amount: 5000000,
          category: ExpenseCategory.rent,
          date: DateTime.now().subtract(const Duration(days: 2)),
          spender: SpenderType.husband,
          paymentMethod: PaymentMethod.bankTransfer,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom header with greeting
            SliverToBoxAdapter(
              child: _buildHeader(context)
                  .animate()
                  .fade(duration: 500.ms)
                  .slideY(begin: -0.1, end: 0),
            ),

            // Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const ExpenseSummaryCard()
                    .animate(delay: 100.ms)
                    .fade(duration: 600.ms)
                    .slideY(begin: 0.15, end: 0),
              ),
            ),

            // Couple spending comparison
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: const CoupleSpendingBar(
                  husbandAmount: 5530000,
                  wifeAmount: 505000,
                ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
              ),
            ),

            // Category quick view
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Danh mục chi tiêu'),
                    const Gap(12),
                    const CategoryGrid(),
                  ],
                ).animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
              ),
            ),

            // Recent expenses header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: _buildSectionHeader(
                  context,
                  'Chi tiêu gần đây',
                  trailing: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Xem tất cả',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate(delay: 400.ms).fade(),
              ),
            ),

            // Recent expenses list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _mockExpenses.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(context))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return RecentExpenseItem(
                            expense: _mockExpenses[index],
                          ).animate(delay: (500 + index * 80).ms).fade().slideX(
                                begin: 0.1,
                                end: 0,
                              );
                        },
                        childCount: _mockExpenses.length,
                      ),
                    ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: Gap(100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'Chào buổi sáng';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều';
      emoji = '🌤️';
    } else {
      greeting = 'Chào buổi tối';
      emoji = '🌙';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          // Couple avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.coupleGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $emoji',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Gap(2),
                Text(
                  'Gia đình Minh 💕',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                Icons.notifications_outlined,
                color: context.colorScheme.onSurface.withOpacity(0.5),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ),
        if (trailing != null) trailing,
      ],
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const Gap(16),
          Text(
            'Chưa có chi tiêu nào',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(6),
          Text(
            'Nhấn + để ghi lại chi tiêu đầu tiên nhé! 🌱',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
