import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/expense_model.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _selectedFilter = 'Tất cả';
  SpenderType? _selectedSpenderFilter;

  // Mock data
  final List<ExpenseModel> _expenses = [
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
    ExpenseModel(
      id: '6',
      title: 'Đám cưới bạn An',
      amount: 500000,
      category: ExpenseCategory.ceremony,
      date: DateTime.now().subtract(const Duration(days: 3)),
      spender: SpenderType.both,
      paymentMethod: PaymentMethod.cash,
    ),
    ExpenseModel(
      id: '7',
      title: 'Ăn phở sáng',
      amount: 70000,
      category: ExpenseCategory.food,
      date: DateTime.now().subtract(const Duration(days: 3)),
      spender: SpenderType.husband,
      paymentMethod: PaymentMethod.cash,
    ),
  ];

  List<ExpenseModel> get _filteredExpenses {
    var list = _expenses;
    if (_selectedSpenderFilter != null) {
      list = list.where((e) => e.spender == _selectedSpenderFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Group by date
    final grouped = <String, List<ExpenseModel>>{};
    for (final expense in _filteredExpenses) {
      final key = expense.date.relativeDate;
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiêu',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tháng ${DateTime.now().month}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Spender filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildSpenderFilters(context),
              ),
            ),

            // Expense groups
            ...grouped.entries.map((entry) {
              final dateLabel = entry.key;
              final items = entry.value;
              final dayTotal = items.fold<double>(0, (s, e) => s + e.amount);

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(16),
                      // Date header with daily total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateLabel,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                          Text(
                            '-${dayTotal.toCurrency}',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Gap(10),
                      // Expense items
                      ...items.asMap().entries.map((itemEntry) {
                        return _buildExpenseItem(context, itemEntry.value)
                            .animate(delay: (itemEntry.key * 60).ms)
                            .fade()
                            .slideX(begin: 0.05, end: 0);
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: Gap(100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpenderFilters(BuildContext context) {
    return Row(
      children: [
        _buildFilterChip(context, 'Tất cả', null),
        const Gap(8),
        _buildFilterChip(context, 'Chồng', SpenderType.husband),
        const Gap(8),
        _buildFilterChip(context, 'Vợ', SpenderType.wife),
        const Gap(8),
        _buildFilterChip(context, 'Cả hai', SpenderType.both),
      ],
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, SpenderType? spender) {
    final isSelected = _selectedSpenderFilter == spender;
    final color = spender?.color ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedSpenderFilter = spender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : context.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? color
                : context.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseModel expense) {
    return Dismissible(
      key: Key(expense.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category emoji icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: expense.category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(expense.category.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const Gap(12),

            // Title & meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(3),
                  Row(
                    children: [
                      // Spender chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: expense.spender.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expense.spender.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: expense.spender.color,
                          ),
                        ),
                      ),
                      const Gap(6),
                      Icon(expense.paymentMethod.icon,
                          size: 11,
                          color: context.colorScheme.onSurface
                              .withOpacity(0.3)),
                      const Gap(4),
                      Text(
                        expense.category.label,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface
                              .withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '-${expense.amount.toCurrency}',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
