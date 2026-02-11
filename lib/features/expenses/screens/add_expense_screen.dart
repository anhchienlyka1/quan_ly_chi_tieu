import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
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
    
    // Format initial amount properly
    String initialAmount = '';
    if (widget.expense != null) {
      // Use formatter logic to format initial value
      final formatter = CurrencyInputFormatter();
      final val = TextEditingValue(text: widget.expense!.amount.toStringAsFixed(0));
      initialAmount = formatter.formatEditUpdate(TextEditingValue.empty, val).text;
    }

    _amountController = TextEditingController(text: initialAmount);
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
      // Remove non-digits to get raw number
      final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(cleanAmount) ?? 0;
      
      final existingId = widget.expense?.id;
      // Check if this is a mock/pending transaction that hasn't been synced to server yet
      final isMockId = existingId != null && existingId.startsWith('mock_');

      // Create updated or new model
      // If it's a mock ID, we clear it so the server assigns a new valid ID
      final expense = ExpenseModel(
        id: isMockId ? null : existingId,
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: widget.expense?.date ?? DateTime.now(), // Keep original date if editing
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        type: _selectedType,
        createdAt: widget.expense?.createdAt, // Keep original creation time
      );

      try {
        // If it's editing an existing valid expense, update it.
        // If it's a mock expense or new, add it.
        if (_isEditing && !isMockId) {
          try {
            await _repository.updateExpense(expense);
          } catch (e) {
            // If update fails because it's not found (404), try adding it as new
            if (e.toString().contains('404') || e.toString().contains('Status code: 404')) {
               // Create new expense without ID to force creation
               final newExpense = ExpenseModel(
                 title: expense.title,
                 amount: expense.amount,
                 category: expense.category,
                 date: expense.date,
                 note: expense.note,
                 type: expense.type,
                 createdAt: expense.createdAt,
               );
               await _repository.addExpense(newExpense);
            } else {
              rethrow;
            }
          }
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
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Amount input (Moved to top for better UX)
                  ProTextField(
                    controller: _amountController,
                    labelText: 'Số tiền',
                    hintText: '0',
                    // Use Text prefix instead of Icon for currency symbol
                    prefix: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '₫',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      return null;
                    },
                    autofocus: !_isEditing, // Autofocus only for new entries
                  ),
                  const Gap(16),

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
                  const Gap(16),

                  // Title
                  ProTextField(
                    controller: _titleController,
                    labelText: 'Tiêu đề',
                    hintText: _selectedType == TransactionType.expense 
                        ? 'VD: Ăn trưa, Đổ xăng...' 
                        : 'VD: Lương tháng 2...',
                    prefixIcon: Icons.edit_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),

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
                  const Gap(16),

                  // Note (Compact)
                  ProTextField(
                    controller: _noteController,
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'Thêm ghi chú...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 1, 
                    minLines: 1,
                  ),
                  const Gap(24),

                  // Save button
                  ProButton(
                    label: _isEditing 
                        ? 'Cập nhật' 
                        : (_selectedType == TransactionType.expense ? 'Lưu chi tiêu' : 'Lưu thu nhập'),
                    icon: _isEditing ? Icons.save_rounded : Icons.check_rounded,
                    backgroundColor: _selectedType == TransactionType.expense ? AppColors.primary : AppColors.success,
                    onPressed: _saveExpense,
                  ),
                  
                  // Bottom padding to avoid keyboard overlay issues
                  const Gap(24),
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
