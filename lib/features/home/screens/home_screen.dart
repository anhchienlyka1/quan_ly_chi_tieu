import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/bank_notification_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/services/auto_expense_service.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/budget_service.dart';
import '../../../data/services/mock_data_service.dart';
import '../../../data/services/smart_alert_service.dart';
import '../../budget/widgets/budget_progress_card.dart';
import '../widgets/ai_assistant_popup.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/draggable_ai_fab.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/notification_bottom_sheet.dart';
import '../widgets/quick_shortcuts.dart';
import '../widgets/recent_transactions_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _isAiEnabled = true;
  bool _hasUrgentAlert = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // Initialize AutoExpenseService if needed
    await AutoExpenseService.getInstance();

    final storage = await LocalStorageService.getInstance();
    if (mounted) {
      final provider = context.read<ExpenseProvider>();
      bool urgentAlert = false;
      try {
        urgentAlert = _checkUrgentTrigger(
          provider.currentMonthExpenses,
          provider.budgetProgress,
        );
        // Show smart alert if trigger detected
        if (urgentAlert && mounted) {
          _showSmartAlertIfNeeded(provider);
        }
      } catch (_) {}

      setState(() {
        _isAiEnabled = storage.isAiAssistantEnabled();
        _hasUrgentAlert = urgentAlert;
      });
    }
  }

  /// Show smart in-app alert based on budget status
  void _showSmartAlertIfNeeded(ExpenseProvider provider) {
    final bp = provider.budgetProgress;
    if (bp == null || !bp.budget.isSet) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    final thisWeekTotal = provider.currentMonthExpenses
        .where(
          (e) =>
              e.type == TransactionType.expense &&
              e.date.isAfter(
                startOfWeekDate.subtract(const Duration(seconds: 1)),
              ),
        )
        .fold<double>(0, (s, e) => s + e.amount);

    final weeklyBudget = bp.budget.totalBudget / 4;
    if (weeklyBudget <= 0) return;

    final percentUsed = (thisWeekTotal / weeklyBudget * 100).round();
    final daysRemaining = 7 - now.weekday;

    if (thisWeekTotal > weeklyBudget) {
      // Over budget
      SmartAlertService.showOverBudgetAlert(
        context,
        category: '',
        spent: thisWeekTotal,
        budget: weeklyBudget,
      );
    } else if (percentUsed > 80 && daysRemaining > 2) {
      // Near budget
      SmartAlertService.showNearBudgetAlert(
        context,
        percentUsed: percentUsed,
        daysRemaining: daysRemaining,
      );
    }
  }

  void _showAiAssistantPopup() {
    final provider = context.read<ExpenseProvider>();
    showAiAssistantSheet(
      context,
      expenses: provider.currentMonthExpenses,
      totalBalance: provider.totalBalance,
      budgetProgress: provider.budgetProgress,
      goal: provider.goal,
      suggestions: provider.suggestions,
      onViewStatistics: () {
        Navigator.of(context).pushNamed(RouteNames.statistics);
      },
      onSetBudget: () {
        _navigateAndRefresh(RouteNames.budget);
      },
    );
  }

  /// Quick check if there's an urgent trigger (P0/P1) — runs locally, no AI call
  bool _checkUrgentTrigger(
    List<ExpenseModel> expenses,
    BudgetProgress? budgetProgress,
  ) {
    if (budgetProgress == null || !budgetProgress.budget.isSet) return false;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    final thisWeekTotal = expenses
        .where(
          (e) =>
              e.type == TransactionType.expense &&
              e.date.isAfter(
                startOfWeekDate.subtract(const Duration(seconds: 1)),
              ),
        )
        .fold<double>(0, (s, e) => s + e.amount);

    final weeklyBudget = budgetProgress.budget.totalBudget / 4;
    return weeklyBudget > 0 && thisWeekTotal > weeklyBudget * 0.8;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng! ☀️';
    if (hour < 18) return 'Chào buổi chiều! 🌤️';
    return 'Chào buổi tối! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: context.theme.scaffoldBackgroundColor,
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await provider.refresh();
                    await _initServices();
                  },
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // Custom App Bar
                      SliverToBoxAdapter(child: _buildHeader(context)),

                      // Content
                      SliverToBoxAdapter(
                        child: provider.isLoading
                            ? _buildLoadingState(context)
                            : _buildContent(context, provider, _isAiEnabled),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomNav(context),
            ),

            // Draggable AI Assistant FAB — topmost layer
            if (_isAiEnabled)
              DraggableAiFab(
                onTap: _showAiAssistantPopup,
                showAlertDot: _hasUrgentAlert,
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting and subtitle — long-press to seed mock data (debug)
          GestureDetector(
                onLongPress: () async {
                  HapticFeedback.heavyImpact();
                  try {
                    await MockDataService.seedAll();
                    if (mounted) {
                      await context.read<ExpenseProvider>().refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Mock data loaded!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Column(
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
                ),
              )
              .animate()
              .fade(duration: 500.ms)
              .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),

          // Notification Bell
          StreamBuilder<BankNotificationModel>(
            stream: AutoExpenseService.instance?.notificationStream,
            builder: (context, snapshot) {
              final pendingCount =
                  AutoExpenseService.instance?.pendingNotifications.length ?? 0;

              return _buildNotificationIcon(context, pendingCount);
            },
          ).animate().fade(duration: 500.ms, delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, int pendingCount) {
    final bool hasNotifications = pendingCount > 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showNotificationBottomSheet(
          context,
          onTransactionProcessed: () =>
              context.read<ExpenseProvider>().refresh(),
        ).then((shouldNavigate) {
          if (shouldNavigate) {
            context.pushNamed(RouteNames.autoExpense).then((_) {
              context.read<ExpenseProvider>().refresh();
              setState(() {}); // Refresh notification badge
            });
          }
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glow ring (visible when has notifications)
          if (hasNotifications)
            Positioned.fill(
              child:
                  Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(
                        begin: 0.5,
                        end: 1.0,
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      ),
            ),

          // Main icon container
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: hasNotifications
                  ? (context.isDarkMode
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.08))
                  : (context.isDarkMode
                        ? context.theme.cardTheme.color
                        : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: hasNotifications
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: hasNotifications
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.black.withOpacity(
                          context.isDarkMode ? 0.15 : 0.06,
                        ),
                  blurRadius: hasNotifications ? 14 : 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              hasNotifications
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              size: 22,
              color: hasNotifications
                  ? AppColors.primary
                  : context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),

          // Animated bell shake when has notifications
          if (hasNotifications)
            Positioned.fill(
              child:
                  Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(), delay: 2000.ms)
                      .shake(hz: 4, rotation: 0.08, duration: 600.ms)
                      .then(delay: 3000.ms),
            ),

          // Count Badge
          if (hasNotifications)
            Positioned(
              top: -5,
              right: -5,
              child:
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.isDarkMode
                            ? AppColors.surfaceDark
                            : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEE5A24).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
            ),
        ],
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

  Widget _buildContent(
    BuildContext context,
    ExpenseProvider provider,
    bool isAiEnabled,
  ) {
    final expenses = provider.currentMonthExpenses;
    final budgetProgress = provider.budgetProgress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          BalanceCard(
                totalBalance: provider.totalBalance,
                totalIncome: provider.totalIncome,
                totalExpense: provider.totalExpense,
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

          if (budgetProgress != null)
            BudgetProgressCard(
                  progress: budgetProgress,
                  onTap: () => _navigateAndRefresh(RouteNames.budget),
                )
                .animate()
                .fade(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const Gap(28),

          // Goal Progress Card
          const GoalProgressCard()
              .animate()
              .fade(duration: 500.ms, delay: 250.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const Gap(28),

          // AI Insight Card — chỉ hiển thị khi AI được bật
          if (isAiEnabled && provider.suggestions.isNotEmpty) ...[
            AiInsightCard(
                  suggestions: provider.suggestions,
                  onDismiss: (id) => provider.dismissSuggestion(id),
                  onOpenChat: _showAiAssistantPopup,
                  onActionTap: (route) async {
                    HapticFeedback.lightImpact();
                    await Navigator.of(context).pushNamed(route);
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      context.read<ExpenseProvider>().refresh();
                    }
                  },
                )
                .animate()
                .fade(duration: 500.ms, delay: 300.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            const Gap(28),
          ],

          // Quick Shortcuts
          QuickShortcuts(
            onActionCompleted: () => context.read<ExpenseProvider>().refresh(),
            isAiEnabled: isAiEnabled,
          ),
          const Gap(28),

          // Recent Transactions
          RecentTransactionsList(
            transactions: expenses.take(5).toList(),
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
      child:
          Container(
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
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              )
              .animate(delay: 600.ms)
              .fade()
              .scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.elasticOut,
                duration: 800.ms,
              ),
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
      onTap: () async {
        HapticFeedback.lightImpact();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            await context.pushNamed(RouteNames.expenseList);
            break;
          case 2:
            await context.pushNamed(RouteNames.statistics);
            break;
          case 3:
            await context.pushNamed(RouteNames.settings);
            break;
        }

        // Reset to Home tab and refresh when returning
        if (mounted && index != 0) {
          setState(() => _currentNavIndex = 0);
          // Refresh provider + AI FAB visibility
          context.read<ExpenseProvider>().refresh();
          final storage = await LocalStorageService.getInstance();
          if (mounted) {
            setState(() => _isAiEnabled = storage.isAiAssistantEnabled());
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
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
              style: context.textTheme.labelSmall!.copyWith(
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
    if (mounted) {
      await context.read<ExpenseProvider>().refresh();
    }
  }
}
