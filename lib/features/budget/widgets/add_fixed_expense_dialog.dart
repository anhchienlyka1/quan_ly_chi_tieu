import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/fixed_expense_model.dart';
import '../../../data/providers/expense_provider.dart';
import '../../../data/services/fixed_expense_service.dart';

/// Bottom-sheet dialog to add or edit a fixed expense.
/// Usage:  await showAddFixedExpenseDialog(context: ctx, existing: item);
Future<void> showAddFixedExpenseDialog({
  required BuildContext context,
  FixedExpenseModel? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddFixedExpenseSheet(existing: existing),
  );
}

class _AddFixedExpenseSheet extends StatefulWidget {
  final FixedExpenseModel? existing;
  const _AddFixedExpenseSheet({this.existing});

  @override
  State<_AddFixedExpenseSheet> createState() => _AddFixedExpenseSheetState();
}

class _AddFixedExpenseSheetState extends State<_AddFixedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late ExpenseCategory _selectedCategory;
  late int _dayOfMonth;
  late bool _isActive;
  bool _isSaving = false;

  // Curated list of categories sensible for fixed expenses
  static const List<ExpenseCategory> _cats = [
    ExpenseCategory.bills,
    ExpenseCategory.food,
    ExpenseCategory.transport,
    ExpenseCategory.education,
    ExpenseCategory.health,
    ExpenseCategory.entertainment,
    ExpenseCategory.shopping,
    ExpenseCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(0) : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedCategory = e?.category ?? ExpenseCategory.bills;
    _dayOfMonth = e?.dayOfMonth ?? 1;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      isEdit ? 'Chỉnh sửa khoản cố định' : 'Thêm khoản cố định',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(20),

                    // Name field
                    TextFormField(
                      controller: _titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDec(
                        context,
                        label: 'Tên khoản chi',
                        hint: 'VD: Tiền thuê nhà, Điện nước...',
                        icon: Icons.label_outline_rounded,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const Gap(14),

                    // Amount field
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDec(
                        context,
                        label: 'Số tiền (₫)',
                        hint: 'VD: 3000000',
                        icon: Icons.payments_outlined,
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Số tiền không hợp lệ';
                        return null;
                      },
                    ),
                    const Gap(14),

                    // Category selector
                    Text(
                      'Danh mục',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Gap(8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cats.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (_, i) {
                          final cat = _cats[i];
                          final active = cat == _selectedCategory;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? cat.color.withOpacity(0.15)
                                    : context.colorScheme.surface.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? cat.color
                                      : context.colorScheme.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon, size: 16, color: cat.color),
                                  const Gap(6),
                                  Text(
                                    cat.label,
                                    style: context.textTheme.labelSmall?.copyWith(
                                      color: active ? cat.color : null,
                                      fontWeight: active ? FontWeight.w600 : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(16),

                    // Day of month
                    Row(
                      children: [
                        Text(
                          'Ngày thanh toán: ',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          'Ngày $_dayOfMonth hàng tháng',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        thumbColor: AppColors.primary,
                        inactiveTrackColor:
                            AppColors.primary.withOpacity(0.15),
                        overlayColor: AppColors.primary.withOpacity(0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _dayOfMonth.toDouble(),
                        min: 1,
                        max: 31,
                        divisions: 30,
                        onChanged: (v) =>
                            setState(() => _dayOfMonth = v.round()),
                      ),
                    ),
                    const Gap(8),

                    // Note field
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: _inputDec(
                        context,
                        label: 'Ghi chú (tuỳ chọn)',
                        hint: 'VD: Hóa đơn tháng trước',
                        icon: Icons.note_outlined,
                      ),
                    ),
                    const Gap(16),

                    // Active toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đang hoạt động',
                          style: context.textTheme.bodyMedium,
                        ),
                        Switch.adaptive(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const Gap(20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Lưu thay đổi' : 'Thêm khoản',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final provider = context.read<ExpenseProvider>();
    final amount = double.parse(_amountCtrl.text.trim());
    final note = _noteCtrl.text.trim();

    if (widget.existing != null) {
      await provider.updateFixedExpense(
        widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          amount: amount,
          category: _selectedCategory,
          dayOfMonth: _dayOfMonth,
          isActive: _isActive,
          note: note.isEmpty ? null : note,
        ),
      );
    } else {
      await provider.addFixedExpense(
        FixedExpenseModel(
          id: FixedExpenseService.generateId(),
          title: _titleCtrl.text.trim(),
          amount: amount,
          category: _selectedCategory,
          dayOfMonth: _dayOfMonth,
          isActive: _isActive,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  InputDecoration _inputDec(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: context.colorScheme.surface.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: context.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
