import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/services/budget_service.dart';
import '../../budget/widgets/budget_progress_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_shortcuts.dart';
import '../widgets/recent_transactions_list.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ExpenseRepository _repository = ExpenseRepository();
  final BudgetService _budgetService = BudgetService();
  List<ExpenseModel> _expenses = [];
  BudgetProgress? _budgetProgress;
  bool _isLoading = true;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final expenses = await _repository.getExpensesByMonth(now.year, now.month);
      expenses.sort((a, b) => b.date.compareTo(a.date));
      
      // Load budget progress
      final budgetProgress = await _budgetService.calculateProgress(
        expenses: expenses,
      );

      if (mounted) {
        setState(() {
          _expenses = expenses;
          _budgetProgress = budgetProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalExpense =>
      _expenses.where((e) => e.type == TransactionType.expense).fold<double>(0, (sum, e) => sum + e.amount);

  double get _totalIncome =>
      _expenses.where((e) => e.type == TransactionType.income).fold<double>(0, (sum, e) => sum + e.amount);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng! ☀️';
    if (hour < 18) return 'Chào buổi chiều! 🌤️';
    return 'Chào buổi tối! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExpenses,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Custom App Bar
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              // Content
              SliverToBoxAdapter(
                child: _isLoading
                    ? _buildLoadingState(context)
                    : _buildContent(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting and subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Gap(4),
              Text(
                'Quản lý tài chính',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          )
              .animate()
              .fade(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),

          // Profile + Notification
          Row(
            children: [
              _buildHeaderIconButton(
                context,
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
            ],
          ).animate().fade(duration: 500.ms, delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.theme.cardTheme.color
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 22,
          color: context.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Shimmer balance card
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3)),
          const Gap(24),
          // Shimmer chart
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: context.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          BalanceCard(
            totalBalance: _totalIncome - _totalExpense,
            totalIncome: _totalIncome,
            totalExpense: _totalExpense,
            monthLabel:
                'Tháng ${DateTime.now().month}/${DateTime.now().year}',
            onTap: () => context.pushNamed(RouteNames.expenseList),
          )
              .animate()
              .fade(duration: 600.ms, delay: 100.ms)
              .slideY(
                begin: 0.15,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 600.ms,
              ),
          const Gap(28),

          // Budget Progress Card
          if (_budgetProgress != null)
            BudgetProgressCard(
              progress: _budgetProgress!,
              onTap: () => _navigateAndRefresh(RouteNames.budget),
            )
                .animate()
                .fade(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const Gap(28),

          // Quick Shortcuts
          QuickShortcuts(
            onActionCompleted: _loadExpenses,
          ),
          const Gap(28),

          // Recent Transactions
          RecentTransactionsList(
            transactions: _expenses.take(5).toList(),
            onViewAll: () => _navigateAndRefresh(RouteNames.expenseList),
          ),
          const Gap(16),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // TODO: Implement voice to text feature
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
      )
          .animate(delay: 600.ms)
          .fade()
          .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 800.ms),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Trang chủ',
                index: 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.receipt_long_rounded,
                label: 'Chi tiêu',
                index: 1,
              ),
              _buildVoiceButton(context),
              _buildNavItem(
                context,
                icon: Icons.pie_chart_rounded,
                label: 'Thống kê',
                index: 2,
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_rounded,
                label: 'Cài đặt',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            context.pushNamed(RouteNames.expenseList);
            break;
          case 2:
            context.pushNamed(RouteNames.statistics);
            break;
          case 3:
            context.pushNamed(RouteNames.settings);
            break;
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                size: 24,
                color: isActive
                    ? AppColors.primary
                    : context.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const Gap(4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : context.colorScheme.onSurface.withOpacity(0.4),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateAndRefresh(String routeName) async {
    await context.pushNamed(routeName);
    _loadExpenses();
  }
}
