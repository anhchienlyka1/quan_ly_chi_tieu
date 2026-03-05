import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/services/local_storage_service.dart';
import '../../home/widgets/spending_by_category.dart';
import '../models/chart_data_point.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/period_comparison_card.dart';
import '../widgets/spending_forecast_card.dart';
import '../widgets/summary_header.dart';
import '../widgets/top_spending_list.dart';

// --- Period Filter Enum ---
enum StatsPeriod {
  week('Tuần'),
  month('Tháng'),
  year('Năm');

  const StatsPeriod(this.label);
  final String label;
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsPeriod _selectedPeriod = StatsPeriod.month;
  bool _isAiEnabled = true;

  // Current period stats
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _savingsRate = 0;
  Map<ExpenseCategory, double> _categoryExpenses = {};
  List<ChartDataPoint> _chartData = [];

  // Previous period stats (for comparison)
  double _prevIncome = 0;
  double _prevExpense = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateStats();
      _loadAiSetting();
    });
  }

  Future<void> _loadAiSetting() async {
    final storage = await LocalStorageService.getInstance();
    if (mounted) {
      setState(() => _isAiEnabled = storage.isAiAssistantEnabled());
    }
  }

  void _recalculateStats() {
    final provider = context.read<ExpenseProvider>();
    _calculateStats(provider.allExpensesSorted);
    if (mounted) setState(() {});
  }

  void _calculateStats(List<ExpenseModel> expenses) {
    final now = DateTime.now();

    // --- Determine date range for current & previous period ---
    final DateTimeRange current = _getPeriodRange(now, _selectedPeriod, 0);
    final DateTimeRange previous = _getPeriodRange(now, _selectedPeriod, -1);

    final currentExpenses = expenses
        .where((e) => _inRange(e.date, current))
        .toList();
    final previousExpenses = expenses
        .where((e) => _inRange(e.date, previous))
        .toList();

    // --- Current period totals ---
    _totalIncome = currentExpenses
        .where((e) => e.type == TransactionType.income)
        .fold(0, (sum, e) => sum + e.amount);

    _totalExpense = currentExpenses
        .where((e) => e.type == TransactionType.expense)
        .fold(0, (sum, e) => sum + e.amount);

    _savingsRate = _totalIncome > 0
        ? ((_totalIncome - _totalExpense) / _totalIncome).clamp(-1.0, 1.0)
        : 0;

    // --- Previous period totals ---
    _prevIncome = previousExpenses
        .where((e) => e.type == TransactionType.income)
        .fold(0, (sum, e) => sum + e.amount);

    _prevExpense = previousExpenses
        .where((e) => e.type == TransactionType.expense)
        .fold(0, (sum, e) => sum + e.amount);

    // --- Spending by Category (current period) ---
    _categoryExpenses = {};
    for (var e in currentExpenses.where(
      (e) => e.type == TransactionType.expense,
    )) {
      _categoryExpenses[e.category] =
          (_categoryExpenses[e.category] ?? 0) + e.amount;
    }

    // --- Chart data ---
    _chartData = _buildChartData(expenses, now, current);
  }

  // ---------------------------------------------------------------------------
  // Helper: period range
  // ---------------------------------------------------------------------------
  DateTimeRange _getPeriodRange(DateTime now, StatsPeriod period, int offset) {
    switch (period) {
      case StatsPeriod.week:
        final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(
          startOfThisWeek.year,
          startOfThisWeek.month,
          startOfThisWeek.day,
        ).add(Duration(days: offset * 7));
        return DateTimeRange(
          start: start,
          end: start.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          ),
        );

      case StatsPeriod.month:
        final y = now.year + (now.month + offset - 1) ~/ 12;
        final m = ((now.month + offset - 1) % 12) + 1;
        final start = DateTime(y, m, 1);
        final end = DateTime(y, m + 1, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);

      case StatsPeriod.year:
        final y = now.year + offset;
        return DateTimeRange(
          start: DateTime(y, 1, 1),
          end: DateTime(y, 12, 31, 23, 59, 59),
        );
    }
  }

  bool _inRange(DateTime date, DateTimeRange range) {
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  // ---------------------------------------------------------------------------
  // Helper: build chart data points per period
  // ---------------------------------------------------------------------------
  List<ChartDataPoint> _buildChartData(
    List<ExpenseModel> allExpenses,
    DateTime now,
    DateTimeRange current,
  ) {
    final List<ChartDataPoint> points = [];

    switch (_selectedPeriod) {
      // Week → 7 days
      case StatsPeriod.week:
        for (int i = 6; i >= 0; i--) {
          final day = current.start.add(Duration(days: i));
          final value = allExpenses
              .where(
                (e) =>
                    e.type == TransactionType.expense &&
                    e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day,
              )
              .fold<double>(0, (s, e) => s + e.amount);

          final isToday =
              day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;

          String label;
          if (isToday) {
            label = 'Nay';
          } else {
            const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
            label = days[(day.weekday - 1) % 7];
          }

          points.add(
            ChartDataPoint(label: label, value: value, isToday: isToday),
          );
        }
        break;

      // Month → 4 weeks
      case StatsPeriod.month:
        for (int week = 1; week <= 4; week++) {
          final weekStart = current.start.add(Duration(days: (week - 1) * 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final value = allExpenses
              .where(
                (e) =>
                    e.type == TransactionType.expense &&
                    !e.date.isBefore(weekStart) &&
                    !e.date.isAfter(weekEnd),
              )
              .fold<double>(0, (s, e) => s + e.amount);

          final isCurrentWeek =
              !now.isBefore(weekStart) && !now.isAfter(weekEnd);
          points.add(
            ChartDataPoint(
              label: 'T$week',
              value: value,
              isToday: isCurrentWeek,
            ),
          );
        }
        break;

      // Year → 12 months
      case StatsPeriod.year:
        const monthLabels = [
          'T1',
          'T2',
          'T3',
          'T4',
          'T5',
          'T6',
          'T7',
          'T8',
          'T9',
          'T10',
          'T11',
          'T12',
        ];
        for (int m = 1; m <= 12; m++) {
          final value = allExpenses
              .where(
                (e) =>
                    e.type == TransactionType.expense &&
                    e.date.year == current.start.year &&
                    e.date.month == m,
              )
              .fold<double>(0, (s, e) => s + e.amount);

          points.add(
            ChartDataPoint(
              label: monthLabels[m - 1],
              value: value,
              isToday: m == now.month && current.start.year == now.year,
            ),
          );
        }
        break;
    }

    return points;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final allExpenses = provider.allExpensesSorted;
        _calculateStats(allExpenses);

        final currentPeriodExpenses = allExpenses
            .where((e) => e.type == TransactionType.expense)
            .toList();

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
                onPressed: () => HapticFeedback.lightImpact(),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      const SliverGap(16),

                      // --- Period Selector ---
                      SliverToBoxAdapter(
                        child: _PeriodSelector(
                          selected: _selectedPeriod,
                          onChanged: (p) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedPeriod = p);
                          },
                        ).animate().fade(duration: 300.ms),
                      ),

                      const SliverGap(16),

                      // --- Summary Header ---
                      SliverToBoxAdapter(
                        child:
                            SummaryHeader(
                              income: _totalIncome,
                              expense: _totalExpense,
                              savingsRate: _savingsRate,
                              date: DateTime.now(),
                            ).animate().fade().slideY(
                              begin: 0.2,
                              end: 0,
                              duration: 500.ms,
                            ),
                      ),

                      const SliverGap(20),

                      // --- Period Comparison Card ---
                      SliverToBoxAdapter(
                        child:
                            Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: PeriodComparisonCard(
                                    currentIncome: _totalIncome,
                                    currentExpense: _totalExpense,
                                    prevIncome: _prevIncome,
                                    prevExpense: _prevExpense,
                                    period: _selectedPeriod,
                                  ),
                                )
                                .animate()
                                .fade(delay: 150.ms)
                                .slideY(begin: 0.1, end: 0),
                      ),

                      const SliverGap(20),

                      // --- Chart ---
                      SliverToBoxAdapter(
                        child:
                            Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: DailyBarChart(
                                    data: _chartData,
                                    period: _selectedPeriod,
                                  ),
                                )
                                .animate()
                                .fade(delay: 200.ms)
                                .slideX(begin: 0.1, end: 0),
                      ),

                      const SliverGap(20),

                      // --- Spending Forecast (only for month and when AI enabled) ---
                      if (_selectedPeriod == StatsPeriod.month && _isAiEnabled)
                        SliverToBoxAdapter(
                          child:
                              Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: SpendingForecastCard(
                                      currentExpense: _totalExpense,
                                      now: DateTime.now(),
                                    ),
                                  )
                                  .animate()
                                  .fade(delay: 300.ms)
                                  .slideY(begin: 0.1, end: 0),
                        ),

                      if (_selectedPeriod == StatsPeriod.month)
                        const SliverGap(20),

                      // --- Category Breakdown ---
                      if (_categoryExpenses.isNotEmpty)
                        SliverToBoxAdapter(
                          child:
                              Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: SpendingByCategory(
                                      categoryTotals: _categoryExpenses,
                                    ),
                                  )
                                  .animate()
                                  .fade(delay: 400.ms)
                                  .slideY(begin: 0.1, end: 0),
                        ),

                      const SliverGap(20),

                      // --- Top Spending ---
                      if (currentPeriodExpenses.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                            child:
                                TopSpendingList(expenses: currentPeriodExpenses)
                                    .animate(delay: 600.ms)
                                    .fade()
                                    .slideY(begin: 0.1, end: 0),
                          ),
                        ),

                      if (currentPeriodExpenses.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'Chưa có dữ liệu thống kê',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Period Selector Widget
// ---------------------------------------------------------------------------
class _PeriodSelector extends StatelessWidget {
  final StatsPeriod selected;
  final ValueChanged<StatsPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: StatsPeriod.values.map((period) {
            final isSelected = selected == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      period.label,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : context.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
