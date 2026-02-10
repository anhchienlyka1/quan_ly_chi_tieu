import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../app/routes/route_names.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen>
    with TickerProviderStateMixin {
  final ExpenseRepository _repository = ExpenseRepository();
  List<ExpenseModel> _allExpenses = [];
  bool _isLoading = true;
  TransactionType? _filterType; // null = All

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _filterType = null;
              break;
            case 1:
              _filterType = TransactionType.expense;
              break;
            case 2:
              _filterType = TransactionType.income;
              break;
          }
        });
      }
    });
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _repository.getAllExpenses();
      expenses.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        setState(() {
          _allExpenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ExpenseModel> get _filteredExpenses {
    if (_filterType == null) return _allExpenses;
    return _allExpenses.where((e) => e.type == _filterType).toList();
  }

  double get _totalIncome => _allExpenses
      .where((e) => e.type == TransactionType.income)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _totalExpense => _allExpenses
      .where((e) => e.type == TransactionType.expense)
      .fold<double>(0, (sum, e) => sum + e.amount);

  /// Group expenses by date (day)
  Map<String, List<ExpenseModel>> get _groupedExpenses {
    final map = <String, List<ExpenseModel>>{};
    for (final e in _filteredExpenses) {
      final key = e.date.toShortDate;
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    if (expense.id == null) return;
    try {
      await _repository.deleteExpense(expense.id!);
      await _loadExpenses();
      if (mounted) {
        context.showSnackBar('Đã xóa "${expense.title}"');
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Lỗi khi xóa: $e', isError: true);
      }
    }
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
              // Custom AppBar
              SliverToBoxAdapter(child: _buildAppBar(context)),
              // Summary Card
              SliverToBoxAdapter(child: _buildSummaryCard(context)),
              // Filter Tabs
              SliverToBoxAdapter(child: _buildFilterTabs(context)),
              // Content
              if (_isLoading)
                SliverToBoxAdapter(child: _buildLoadingState(context))
              else if (_filteredExpenses.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(context))
              else
                SliverToBoxAdapter(child: _buildTransactionList(context)),
              // Bottom spacing
              const SliverToBoxAdapter(child: Gap(100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text(
            'Danh sách giao dịch',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildHeaderIconButton(
            context,
            icon: Icons.search_rounded,
            onTap: () {
              // TODO: search feature
            },
          ),
        ],
      ),
    )
        .animate()
        .fade(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic);
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
              color: Colors.black
                  .withOpacity(context.isDarkMode ? 0.15 : 0.06),
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

  Widget _buildSummaryCard(BuildContext context) {
    final balance = _totalIncome - _totalExpense;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Tổng quan',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(6),
            Text(
              balance.toCurrency,
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.arrow_downward_rounded,
                    label: 'Thu nhập',
                    amount: _totalIncome,
                    color: const Color(0xFF2ECC71),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.arrow_upward_rounded,
                    label: 'Chi tiêu',
                    amount: _totalExpense,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const Gap(6),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          amount.toCompactCurrency,
          style: context.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.theme.cardTheme.color
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: context.isDarkMode ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              context.colorScheme.onSurface.withOpacity(0.5),
          labelStyle: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          dividerHeight: 0,
          tabs: [
            Tab(
              height: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_rounded, size: 16),
                  const Gap(4),
                  Text('Tất cả (${_allExpenses.length})'),
                ],
              ),
            ),
            Tab(
              height: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 16),
                  const Gap(4),
                  Text(
                    'Chi (${_allExpenses.where((e) => e.type == TransactionType.expense).length})',
                  ),
                ],
              ),
            ),
            Tab(
              height: 38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_downward_rounded, size: 16),
                  const Gap(4),
                  Text(
                    'Thu (${_allExpenses.where((e) => e.type == TransactionType.income).length})',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildTransactionList(BuildContext context) {
    final grouped = _groupedExpenses;
    final keys = grouped.keys.toList();
    int animIndex = 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: keys.map((dateKey) {
          final items = grouped[dateKey]!;
          final dayTotal = items.fold<double>(0, (sum, e) {
            return e.type == TransactionType.income
                ? sum + e.amount
                : sum - e.amount;
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDateLabel(items.first.date),
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurface.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      dayTotal >= 0
                          ? '+${dayTotal.toCurrency}'
                          : dayTotal.toCurrency,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: dayTotal >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              // Transaction Items
              ...items.map((expense) {
                final idx = animIndex++;
                return _buildTransactionItem(context, expense, idx);
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    if (date.isToday) return '📅 Hôm nay';
    if (date.isYesterday) return '📅 Hôm qua';
    return '📅 ${date.toDayAndDate}';
  }

  Widget _buildTransactionItem(
      BuildContext context, ExpenseModel expense, int index) {
    final isIncome = expense.type == TransactionType.income;

    return Dismissible(
      key: Key(expense.id ?? expense.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Xác nhận xóa'),
            content: Text('Bạn muốn xóa "${expense.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteExpense(expense),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          final result = await context.pushNamed(
            RouteNames.addExpense,
            arguments: expense,
          );
          if (result == true) {
            _loadExpenses();
          }
        },
        child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.theme.cardTheme.color
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(context.isDarkMode ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: expense.category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                expense.category.icon,
                color: expense.category.color,
                size: 22,
              ),
            ),
            const Gap(14),

            // Title, Category, Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: expense.category.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.category.label,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: expense.category.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        expense.date.toTime,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurface
                              .withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isIncome
                      ? '+${expense.amount.toCurrency}'
                      : '-${expense.amount.toCurrency}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppColors.success : AppColors.error,
                  ),
                ),
                if (expense.note != null && expense.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: context.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    )
        .animate(delay: Duration(milliseconds: 300 + (index * 60)))
        .fade(duration: 350.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: context.colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
          const Gap(20),
          Text(
            _filterType == null
                ? 'Chưa có giao dịch nào'
                : _filterType == TransactionType.expense
                    ? 'Chưa có chi tiêu nào'
                    : 'Chưa có thu nhập nào',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          Text(
            'Nhấn nút + để thêm giao dịch mới',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fade().scale(
          begin: const Offset(0.95, 0.95),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await context.pushNamed(RouteNames.addExpense);
        _loadExpenses();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    )
        .animate(delay: 500.ms)
        .fade()
        .scale(
          begin: const Offset(0.5, 0.5),
          curve: Curves.elasticOut,
          duration: 800.ms,
        );
  }
}
