import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/services/budget_service.dart';
import 'fixed_expense_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  final TextEditingController _totalBudgetController = TextEditingController();
  final Map<ExpenseCategory, TextEditingController> _categoryControllers = {};
  final Map<ExpenseCategory, bool> _categoryEnabled = {};

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasBudget = false; // true khi đã có ngân sách được thiết lập

  // Expense-only categories
  final List<ExpenseCategory> _expenseCategories =
      BudgetModel.expenseCategories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Initialize controllers for each expense category
    for (final cat in _expenseCategories) {
      _categoryControllers[cat] = TextEditingController();
      _categoryEnabled[cat] = false;
    }

    _loadBudget();
  }

  /// Lấy số thuần từ text có thể có dấu chấm phân cách
  double _parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0;
  }

  Future<void> _loadBudget() async {
    final budget = await _budgetService.getCurrentMonthBudget();
    if (mounted) {
      // Dùng CurrencyInputFormatter để format lại khi load
      final formatter = CurrencyInputFormatter();
      if (budget.totalBudget > 0) {
        final raw = budget.totalBudget.toInt().toString();
        _totalBudgetController.value = formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: raw),
        );
      }
      for (final entry in budget.categoryBudgets.entries) {
        final raw = entry.value.toInt().toString();
        _categoryControllers[entry.key]?.value = formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: raw),
        );
        _categoryEnabled[entry.key] = true;
      }
      setState(() => _isLoading = false);
      setState(() => _hasBudget = budget.totalBudget > 0);
      _animationController.forward();
    }
  }

  /// Tính tổng ngân sách các danh mục đang được bật
  double get _totalCategoryBudget {
    double sum = 0;
    for (final cat in _expenseCategories) {
      if (_categoryEnabled[cat] == true) {
        sum += _parseAmount(_categoryControllers[cat]?.text ?? '');
      }
    }
    return sum;
  }

  Future<void> _saveBudget() async {
    final total = _parseAmount(_totalBudgetController.text);

    if (total <= 0) {
      context.showSnackBar('Vui lòng nhập ngân sách tổng', isError: true);
      return;
    }

    // Validate từng danh mục không vượt ngân sách tổng
    for (final cat in _expenseCategories) {
      if (_categoryEnabled[cat] == true) {
        final amount = _parseAmount(_categoryControllers[cat]?.text ?? '');
        if (amount > total) {
          context.showSnackBar(
            'Ngân sách "${cat.label}" vượt quá ngân sách tổng!',
            isError: true,
          );
          return;
        }
      }
    }

    // Validate tổng các danh mục không vượt ngân sách tổng
    if (_totalCategoryBudget > total) {
      context.showSnackBar(
        'Tổng ngân sách các danh mục (${_totalCategoryBudget.toStringAsFixed(0)}₫) vượt quá ngân sách tổng!',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    final categoryBudgets = <ExpenseCategory, double>{};
    for (final cat in _expenseCategories) {
      if (_categoryEnabled[cat] == true) {
        final amount = _parseAmount(_categoryControllers[cat]?.text ?? '');
        if (amount > 0) {
          categoryBudgets[cat] = amount;
        }
      }
    }

    final budget = BudgetModel.forCurrentMonth(
      totalBudget: total,
      categoryBudgets: categoryBudgets,
    );

    await _budgetService.saveBudget(budget);

    if (mounted) {
      setState(() => _isSaving = false);
      HapticFeedback.mediumImpact();
      context.showSnackBar('Đã lưu ngân sách thành công! 🎉');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteBudget() async {
    // Hiện confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            Gap(12),
            Text('Xoá ngân sách?'),
          ],
        ),
        content: const Text(
          'Thành động này sẽ xóa toàn bộ ngân sách của tháng này, bao gồm cả ngân sách danh mục. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final now = DateTime.now();
      await _budgetService.deleteBudget(now.year, now.month);
      HapticFeedback.mediumImpact();
      context.showSnackBar('Đã xóa ngân sách thành công');
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _totalBudgetController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Container(
                color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF10B981),
                child: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                      text: 'Ngân sách',
                    ),
                    Tab(
                      icon: Icon(Icons.repeat_rounded, size: 18),
                      text: 'Cố định',
                    ),
                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Budget content
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _buildTotalBudgetCard(context),
                                        const Gap(24),
                                        _buildCategoryBudgetsSection(context),
                                        const Gap(24),
                                        _buildTipsCard(context),
                                        const Gap(32),
                                        _buildSaveButton(context),
                                        const Gap(12),
                                        if (_hasBudget) _buildDeleteButton(context),
                                        const Gap(20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    // Tab 2: Fixed expenses
                    const FixedExpenseScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngân sách hàng tháng',
                            style: context.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Thiết lập giới hạn chi tiêu',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBudgetCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngân sách tổng',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Tổng giới hạn chi tiêu trong tháng',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),

          // Total budget input
          Container(
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _totalBudgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
                suffixText: '₫',
                suffixStyle: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981).withOpacity(0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const Gap(12),

          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAmountChip(context, 3000000, '3Tr'),
              _buildQuickAmountChip(context, 5000000, '5Tr'),
              _buildQuickAmountChip(context, 7000000, '7Tr'),
              _buildQuickAmountChip(context, 10000000, '10Tr'),
              _buildQuickAmountChip(context, 15000000, '15Tr'),
              _buildQuickAmountChip(context, 20000000, '20Tr'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(BuildContext context, int amount, String label) {
    final currentAmount = _parseAmount(_totalBudgetController.text).toInt();
    final isSelected = currentAmount == amount;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final formatter = CurrencyInputFormatter();
        final formatted = formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: amount.toString()),
        );
        setState(() {
          _totalBudgetController.value = formatted;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981)
              : (context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFF10B981).withOpacity(0.08)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFF10B981).withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF10B981),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetsSection(BuildContext context) {
    final total = _parseAmount(_totalBudgetController.text);
    final catTotal = _totalCategoryBudget;
    final isOverTotal = total > 0 && catTotal > total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ngân sách theo danh mục',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tùy chọn',
                style: context.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Gap(8),
        Text(
          'Giới hạn chi tiêu cho từng danh mục cụ thể',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        if (isOverTotal) ...[
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 16,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Tổng ngân sách con (${catTotal.toStringAsFixed(0)}₫) đang vượt quá ngân sách tổng!',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const Gap(16),

        Container(
          decoration: BoxDecoration(
            color: context.theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: _expenseCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Column(
                children: [
                  _buildCategoryBudgetItem(context, category),
                  if (index < _expenseCategories.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 70),
                      child: Divider(
                        height: 1,
                        color: context.colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBudgetItem(
    BuildContext context,
    ExpenseCategory category,
  ) {
    final isEnabled = _categoryEnabled[category] ?? false;

    // Kiểm tra nếu ngân sách danh mục vượt ngân sách tổng
    final total = _parseAmount(_totalBudgetController.text);
    final catAmount = _parseAmount(_categoryControllers[category]?.text ?? '');
    final isOverLimit = isEnabled && total > 0 && catAmount > total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverLimit
                  ? Colors.red.withOpacity(0.15)
                  : category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.icon,
              size: 20,
              color: isOverLimit ? Colors.red : category.color,
            ),
          ),
          const Gap(14),

          // Category name
          Expanded(
            flex: 2,
            child: Text(
              category.label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOverLimit ? Colors.red : null,
              ),
            ),
          ),

          // Amount input field
          if (isEnabled) ...[
            Container(
              width: 130,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : (isOverLimit
                          ? Colors.red.withOpacity(0.05)
                          : category.color.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOverLimit
                      ? Colors.red.withOpacity(0.6)
                      : category.color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _categoryControllers[category],
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                textAlign: TextAlign.right,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isOverLimit ? Colors.red : category.color,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: '₫',
                  suffixStyle: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverLimit
                        ? Colors.red.withOpacity(0.7)
                        : category.color.withOpacity(0.7),
                  ),
                  hintStyle: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Gap(8), // Add some spacing before the switch
          ],

          // Toggle switch
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: isEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  _categoryEnabled[category] = value;
                  if (!value) {
                    _categoryControllers[category]?.clear();
                  }
                });
              },
              activeThumbColor: isOverLimit ? Colors.red : category.color,
              activeTrackColor: isOverLimit
                  ? Colors.red.withOpacity(0.3)
                  : category.color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final total = _parseAmount(_totalBudgetController.text);

    if (total <= 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyBudget = total / daysInMonth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDarkMode
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF1E293B).withOpacity(0.8),
                ]
              : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
              const Gap(10),
              Text(
                'Gợi ý thông minh',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const Gap(12),
          _buildTipRow(
            context,
            '📅',
            'Ngân sách mỗi ngày',
            dailyBudget.toCurrency,
          ),
          const Gap(8),
          _buildTipRow(
            context,
            '📊',
            'Ngân sách mỗi tuần',
            (total / 4).toCurrency,
          ),
          const Gap(8),
          _buildTipRow(
            context,
            '💡',
            'Quy tắc 50/30/20',
            'Cần thiết: ${(total * 0.5).toCurrency}',
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(
    BuildContext context,
    String emoji,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Text(emoji, style: context.textTheme.bodyLarge?.copyWith(fontSize: 16)),
        const Gap(10),
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _saveBudget,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.check_rounded, color: Colors.white, size: 24),
            const Gap(12),
            Text(
              _isSaving ? 'Đang lưu...' : 'Lưu ngân sách',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: _deleteBudget,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 22,
            ),
            const Gap(10),
            Text(
              'Xo\u00e1 ng\u00e2n s\u00e1ch',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
