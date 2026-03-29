import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/fixed_expense_model.dart';
import '../../../data/providers/expense_provider.dart';
import '../widgets/add_fixed_expense_dialog.dart';
import '../widgets/fixed_expense_item.dart';

class FixedExpenseScreen extends StatelessWidget {
  const FixedExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final items = provider.fixedExpenses;
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildSummaryHeader(context, provider),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context)
                    : _buildList(context, provider, items),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddDialog(context, provider),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm khoản'),
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(BuildContext context, ExpenseProvider provider) {
    final totalFixed = provider.totalFixedExpenses;
    final totalIncome = provider.totalIncome;
    final available = provider.availableIncome;
    final pct = totalIncome > 0
        ? ((totalFixed / totalIncome) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.85),
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.repeat_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const Gap(6),
              Text(
                'Chi phí cố định tháng này',
                style: context.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  context,
                  label: 'Cố định',
                  value: _fmt(totalFixed),
                  icon: Icons.lock_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _summaryMetric(
                  context,
                  label: 'Thu nhập',
                  value: _fmt(totalIncome),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _summaryMetric(
                  context,
                  label: 'Còn lại',
                  value: _fmt(available),
                  icon: Icons.savings_rounded,
                  highlight: true,
                ),
              ),
            ],
          ),
          if (totalIncome > 0) ...[
            const Gap(14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct > 70 ? Colors.redAccent : Colors.white,
                ),
                minHeight: 6,
              ),
            ),
            const Gap(6),
            Text(
              'Chi cố định chiếm $pct% thu nhập',
              style: context.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: Colors.white60,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: highlight ? Colors.yellowAccent : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    ExpenseProvider provider,
    List<FixedExpenseModel> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      itemBuilder: (context, i) => FixedExpenseItem(
        item: items[i],
        onEdit: () => _openEditDialog(context, provider, items[i]),
        onDelete: () => _confirmDelete(context, provider, items[i]),
        onToggle: (value) {
          provider.updateFixedExpense(items[i].copyWith(isActive: value));
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat_rounded,
            size: 64,
            color: context.colorScheme.onSurface.withOpacity(0.2),
          ),
          const Gap(16),
          Text(
            'Chưa có khoản cố định',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const Gap(8),
          Text(
            'Nhấn "+" để thêm tiền nhà, điện nước...',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddDialog(
    BuildContext context,
    ExpenseProvider provider,
  ) async {
    HapticFeedback.lightImpact();
    await showAddFixedExpenseDialog(context: context);
  }

  Future<void> _openEditDialog(
    BuildContext context,
    ExpenseProvider provider,
    FixedExpenseModel item,
  ) async {
    HapticFeedback.lightImpact();
    await showAddFixedExpenseDialog(context: context, existing: item);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExpenseProvider provider,
    FixedExpenseModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khoản cố định?'),
        content: Text('Bạn có chắc muốn xóa "${item.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ExpenseProvider>().deleteFixedExpense(item.id);
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr₫';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K₫';
    }
    return '${amount.toStringAsFixed(0)}₫';
  }
}
