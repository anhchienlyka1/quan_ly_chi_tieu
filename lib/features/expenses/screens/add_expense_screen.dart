import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/pro_button.dart';
import '../../../core/widgets/pro_text_field.dart';
import '../../../data/models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thêm chi tiêu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount input
                  ProTextField(
                    controller: _amountController,
                    labelText: 'Số tiền',
                    hintText: '0 ₫',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),

                  // Title
                  ProTextField(
                    controller: _titleController,
                    labelText: 'Tiêu đề',
                    hintText: 'VD: Ăn trưa, Đổ xăng...',
                    prefixIcon: Icons.edit_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const Gap(20),

                  // Category selector
                  Text(
                    'Danh mục',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Gap(8),
                  _buildCategorySelector(context),
                  const Gap(20),

                  // Note
                  ProTextField(
                    controller: _noteController,
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'Thêm ghi chú...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const Gap(32),

                  // Save button
                  ProButton(
                    label: 'Lưu chi tiêu',
                    icon: Icons.check_rounded,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Save expense
                        context.pop();
                        context.showSnackBar('Đã lưu chi tiêu thành công!');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedCategory = category);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color.withOpacity(0.15)
                    : context.theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category.icon, size: 18, color: category.color),
                  const SizedBox(width: 6),
                  Text(
                    category.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? category.color
                          : context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
