import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/providers/expense_provider.dart';

/// Shows a bottom-sheet dialog listing active fixed expenses to import.
/// Returns true if user committed an import, false/null otherwise.
Future<bool?> showMonthlyFixedImportDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MonthlyFixedImportSheet(),
  );
}

class _MonthlyFixedImportSheet extends StatefulWidget {
  const _MonthlyFixedImportSheet();

  @override
  State<_MonthlyFixedImportSheet> createState() =>
      _MonthlyFixedImportSheetState();
}

class _MonthlyFixedImportSheetState extends State<_MonthlyFixedImportSheet> {
  late List<bool> _selected;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    final items = context.read<ExpenseProvider>().fixedExpenses;
    _selected = items.map((e) => e.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final items = provider.fixedExpenses;
    final activeItems = items.where((e) => e.isActive).toList();

    if (activeItems.isEmpty) {
      Navigator.pop(context);
      return const SizedBox.shrink();
    }

    // Sync _selected length with actual items
    while (_selected.length < items.length) {
      _selected.add(true);
    }

    final selectedItems = [
      for (var i = 0; i < items.length; i++)
        if (_selected[i] && items[i].isActive) items[i],
    ];
    final total = selectedItems.fold<double>(0, (s, e) => s + e.amount);

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.repeat_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 Tháng mới bắt đầu!',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Thêm các khoản cố định vào chi tiêu tháng này?',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          // Select all
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn khoản để import',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final allSelected = _selected.every((s) => s);
                    setState(() {
                      for (var i = 0; i < _selected.length; i++) {
                        _selected[i] = !allSelected;
                      }
                    });
                  },
                  child: Text(
                    _selected.every((s) => s) ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Expense list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, i) {
                if (!items[i].isActive) return const SizedBox.shrink();
                final activeIdx = items.indexOf(items[i]);
                return CheckboxListTile(
                  value: _selected[activeIdx],
                  onChanged: (v) => setState(() => _selected[activeIdx] = v ?? false),
                  title: Text(items[i].title),
                  subtitle: Text(
                    '${items[i].amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫',
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: items[i].category.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      items[i].category.icon,
                      color: items[i].category.color,
                      size: 18,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  activeColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                );
              },
            ),
          ),
          // Total + action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                if (total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng sẽ thêm:',
                          style: context.textTheme.bodyMedium,
                        ),
                        Text(
                          '${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫',
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await provider.importFixedExpenses([], DateTime.now());
                          if (context.mounted) Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Bỏ qua tháng này'),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!_importing && selectedItems.isNotEmpty)
                            ? _import
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _importing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Thêm vào chi tiêu',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    HapticFeedback.lightImpact();

    final provider = context.read<ExpenseProvider>();
    final items = provider.fixedExpenses;
    final selectedItems = [
      for (var i = 0; i < items.length; i++)
        if (_selected[i] && items[i].isActive) items[i],
    ];

    await provider.importFixedExpenses(selectedItems, DateTime.now());

    if (mounted) {
      Navigator.pop(context, true);
      context.showSnackBar('Đã thêm ${selectedItems.length} khoản cố định 🎉');
    }
  }
}
