import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/widgets/pro_button.dart';
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
  SpenderType _selectedSpender = SpenderType.husband;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();

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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount input — prominent
                  _buildAmountInput(context)
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const Gap(20),

                  // Who paid selector
                  _buildSpenderSelector(context)
                      .animate(delay: 100.ms)
                      .fade()
                      .slideY(begin: 0.1, end: 0),
                  const Gap(20),

                  // Title input
                  _buildTitleInput(context)
                      .animate(delay: 150.ms)
                      .fade()
                      .slideY(begin: 0.1, end: 0),
                  const Gap(20),

                  // Category selector
                  _buildLabel(context, 'Danh mục'),
                  const Gap(10),
                  _buildCategorySelector(context)
                      .animate(delay: 200.ms)
                      .fade()
                      .slideY(begin: 0.1, end: 0),
                  const Gap(20),

                  // Date & Payment method row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(context)
                            .animate(delay: 250.ms)
                            .fade()
                            .slideY(begin: 0.1, end: 0),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _buildPaymentMethodSelector(context)
                            .animate(delay: 300.ms)
                            .fade()
                            .slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Note
                  _buildNoteInput(context)
                      .animate(delay: 350.ms)
                      .fade()
                      .slideY(begin: 0.1, end: 0),
                  const Gap(32),

                  // Save button
                  ProButton(
                    label: 'Lưu chi tiêu',
                    icon: Icons.check_rounded,
                    onPressed: _onSave,
                  ).animate(delay: 400.ms).fade().slideY(begin: 0.2, end: 0),

                  const Gap(20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Amount input in a gradient card ---
  Widget _buildAmountInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Số tiền chi tiêu',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const Gap(12),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
            decoration: InputDecoration(
              hintText: '0 ₫',
              hintStyle: context.textTheme.headlineLarge?.copyWith(
                color: Colors.white.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số tiền';
              }
              return null;
            },
          ),
          Text(
            'VND',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // --- Spender selector (Chồng / Vợ / Cả hai) ---
  Widget _buildSpenderSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, 'Ai chi?'),
        const Gap(10),
        Row(
          children: SpenderType.values.map((spender) {
            final isSelected = _selectedSpender == spender;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSpender = spender);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: spender != SpenderType.values.last ? 10 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? spender.color.withOpacity(0.12)
                        : context.theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? spender.color
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: spender.color.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        spender.icon,
                        color: isSelected
                            ? spender.color
                            : context.colorScheme.onSurface.withOpacity(0.3),
                        size: 22,
                      ),
                      const Gap(6),
                      Text(
                        spender.label,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? spender.color
                              : context.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Title input ---
  Widget _buildTitleInput(BuildContext context) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Tiêu đề',
        hintText: 'VD: Ăn trưa, Đổ xăng, Mua sữa...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.edit_rounded, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập tiêu đề';
        }
        return null;
      },
    );
  }

  // --- Category grid ---
  Widget _buildCategorySelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withOpacity(0.12)
                  : context.theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category.color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  category.label,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? category.color
                        : context.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Date picker ---
  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: context.theme.copyWith(
                colorScheme: context.colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.primary),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    _selectedDate.day == DateTime.now().day &&
                            _selectedDate.month == DateTime.now().month
                        ? 'Hôm nay'
                        : DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Payment method selector ---
  Widget _buildPaymentMethodSelector(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPaymentMethod =
              _selectedPaymentMethod == PaymentMethod.cash
                  ? PaymentMethod.bankTransfer
                  : PaymentMethod.cash;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(_selectedPaymentMethod.icon,
                size: 18, color: AppColors.primary),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hình thức',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    _selectedPaymentMethod.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.swap_horiz_rounded,
                size: 16,
                color: context.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // --- Note input ---
  Widget _buildNoteInput(BuildContext context) {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Ghi chú (tùy chọn)',
        hintText: 'Thêm ghi chú...',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12, bottom: 40),
          child: Icon(Icons.notes_rounded, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }

  // --- Label helper ---
  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save expense via repository
      context.pop();
      context.showSnackBar('Đã lưu thành công! ✨');
    }
  }
}
