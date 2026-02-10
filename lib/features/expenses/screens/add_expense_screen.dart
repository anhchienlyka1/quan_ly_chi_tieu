import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/pro_button.dart';
import '../../../core/widgets/pro_text_field.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense; // If provided, we are in Edit mode
  final TransactionType? initialType;

  const AddExpenseScreen({
    super.key,
    this.expense,
    this.initialType,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ExpenseRepository();
  
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late ExpenseCategory _selectedCategory;
  late TransactionType _selectedType;
  
  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing, or defaults if adding
    _selectedType = widget.expense?.type ?? widget.initialType ?? TransactionType.expense;
    _selectedCategory = widget.expense?.category ?? ExpenseCategory.food;
    
    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(0) ?? '',
    );
    _titleController = TextEditingController(
      text: widget.expense?.title ?? '',
    );
    _noteController = TextEditingController(
      text: widget.expense?.note ?? '',
    );

    // If adding (not editing), ensure default category matches type
    if (!_isEditing) {
      _updateDefaultCategory();
    }
  }

  void _updateDefaultCategory() {
    setState(() {
      if (_selectedType == TransactionType.expense) {
        if (_selectedCategory.isIncome) {
          _selectedCategory = ExpenseCategory.food;
        }
      } else {
        if (!_selectedCategory.isIncome) {
          _selectedCategory = ExpenseCategory.salary;
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      
      // Create updated or new model
      final expense = ExpenseModel(
        id: widget.expense?.id, // Keep ID if editing
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: widget.expense?.date ?? DateTime.now(), // Keep original date if editing
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        type: _selectedType,
        createdAt: widget.expense?.createdAt, // Keep original creation time
      );

      try {
        if (_isEditing) {
          await _repository.updateExpense(expense);
        } else {
          await _repository.addExpense(expense);
        }

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          context.showSnackBar(
            _isEditing
                ? 'Đã cập nhật giao dịch!'
                : _selectedType == TransactionType.expense
                    ? 'Đã lưu chi tiêu thành công!'
                    : 'Đã lưu thu nhập thành công!',
          );
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Lỗi khi lưu: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _isEditing 
              ? 'Chỉnh sửa giao dịch' 
              : (_selectedType == TransactionType.expense ? 'Thêm chi tiêu' : 'Thêm thu nhập')
        ),
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
                  // Type Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            TransactionType.expense,
                            Icons.outbound_rounded,
                            AppColors.error,
                          ),
                        ),
                        Expanded(
                          child: _buildTypeButton(
                            TransactionType.income,
                            Icons.monetization_on_rounded,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

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
                    hintText: _selectedType == TransactionType.expense 
                        ? 'VD: Ăn trưa, Đổ xăng...' 
                        : 'VD: Lương tháng 2, Thưởng tết...',
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
                    label: _isEditing 
                        ? 'Cập nhật' 
                        : (_selectedType == TransactionType.expense ? 'Lưu chi tiêu' : 'Lưu thu nhập'),
                    icon: _isEditing ? Icons.save_rounded : Icons.check_rounded,
                    backgroundColor: _selectedType == TransactionType.expense ? AppColors.primary : AppColors.success,
                    onPressed: _saveExpense,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, IconData icon, Color activeColor) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _updateDefaultCategory();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : context.colorScheme.onSurface.withOpacity(0.4),
            ),
            const Gap(8),
            Text(
              type.label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : context.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final categories = ExpenseCategory.values.where((c) {
      if (_selectedType == TransactionType.expense) {
        return !c.isIncome;
      } else {
        return c.isIncome;
      }
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
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
