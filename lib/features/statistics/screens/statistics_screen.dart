import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../home/widgets/spending_by_category.dart';
import '../models/chart_data_point.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/summary_header.dart';
import '../widgets/top_spending_list.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ExpenseRepository _repository = ExpenseRepository();
  bool _isLoading = true;
  List<ExpenseModel> _allExpenses = [];
  
  // Computed properties
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<ExpenseCategory, double> _categoryExpenses = {};
  List<ChartDataPoint> _weeklyData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _repository.getAllExpenses();
      
      if (mounted) {
        // Prepare data
        _calculateStats(expenses);
        setState(() {
          _allExpenses = expenses..sort((a, b) => b.date.compareTo(a.date));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showSnackBar('Lỗi tải dữ liệu: $e', isError: true);
      }
    }
  }

  void _calculateStats(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    
    // 1. Total Income & Expense (Current Month)
    final currentMonthExpenses = expenses.where((e) => 
      e.date.year == now.year && e.date.month == now.month
    ).toList();

    _totalIncome = currentMonthExpenses
        .where((e) => e.type == TransactionType.income)
        .fold(0, (sum, e) => sum + e.amount);

    _totalExpense = currentMonthExpenses
        .where((e) => e.type == TransactionType.expense)
        .fold(0, (sum, e) => sum + e.amount);

    // 2. Spending by Category (Current Month)
    _categoryExpenses = {};
    for (var e in currentMonthExpenses.where((e) => e.type == TransactionType.expense)) {
      _categoryExpenses[e.category] = (_categoryExpenses[e.category] ?? 0) + e.amount;
    }

    // 3. Weekly Activity (Last 7 days daily expense)
    _weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      
      // Sum expenses for this specific day
      final dayExpenses = expenses.where((e) => 
        e.date.year == day.year && 
        e.date.month == day.month && 
        e.date.day == day.day &&
        e.type == TransactionType.expense
      ).fold<double>(0, (sum, e) => sum + e.amount);

      String label;
      if (i == 0) {
        label = 'Nay';
      } else if (i == 1) {
        label = 'Qua';
      } else {
        label = '${day.day}/${day.month}';
      }

      _weeklyData.add(ChartDataPoint(
        label: label,
        value: dayExpenses,
        isToday: i == 0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Thống kê tài chính'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Future feature: detailed reports
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverGap(16),
                  
                  // 1. Summary Header
                  SliverToBoxAdapter(
                    child: SummaryHeader(
                      income: _totalIncome,
                      expense: _totalExpense,
                      date: DateTime.now(),
                    ).animate().fade().slideY(begin: 0.2, end: 0, duration: 500.ms),
                  ),

                  const SliverGap(24),

                  // 2. Weekly Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: DailyBarChart(data: _weeklyData),
                    ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0),
                  ),

                  const SliverGap(24),

                  // 3. Category Breakdown
                  if (_categoryExpenses.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SpendingByCategory(
                          categoryTotals: _categoryExpenses,
                        ),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    ),

                  const SliverGap(24),
                  
                  // 4. Top Spending Analysis (Replaces the raw list)
                  if (_allExpenses.where((e) => e.type == TransactionType.expense).isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        child: TopSpendingList(
                          expenses: _allExpenses
                              .where((e) => e.type == TransactionType.expense)
                              .toList(),
                        ).animate(delay: 600.ms).fade().slideY(begin: 0.1, end: 0),
                      ),
                    ),
                    
                  if (_allExpenses.where((e) => e.type == TransactionType.expense).isEmpty)
                     SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'Chưa có dữ liệu thống kê',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
