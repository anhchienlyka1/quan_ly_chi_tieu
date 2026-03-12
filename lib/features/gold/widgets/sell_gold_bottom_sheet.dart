import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/gold_asset_model.dart';
import '../../../data/providers/gold_provider.dart';

/// Bottom sheet for entering sell details when marking a gold asset as sold.
class SellGoldBottomSheet extends StatefulWidget {
  final GoldAssetModel asset;

  const SellGoldBottomSheet({super.key, required this.asset});

  static Future<bool?> show(BuildContext context, GoldAssetModel asset) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellGoldBottomSheet(asset: asset),
    );
  }

  @override
  State<SellGoldBottomSheet> createState() => _SellGoldBottomSheetState();
}

class _SellGoldBottomSheetState extends State<SellGoldBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _sellDate = DateTime.now();
  bool _isSubmitting = false;
  bool _didPrefill = false;
  double? _suggestedPrice; // live price per asset unit

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) return;
    _didPrefill = true;

    final provider = context.read<GoldProvider>();
    final live = provider.getLivePriceFor(widget.asset);
    if (live == null) return;

    // buyPrice is per chỉ from BTMC; convert to asset's unit
    final pricePerUnit = widget.asset.unit == GoldUnit.luong
        ? live.buyPrice * 10
        : live.buyPrice;

    _suggestedPrice = pricePerUnit;
    _priceController.text = pricePerUnit.round().toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sellDate,
      firstDate: widget.asset.purchaseDate,
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppColors.goldPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _sellDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final price =
        double.tryParse(
          _priceController.text.replaceAll(',', '').replaceAll('.', ''),
        ) ??
        0;

    try {
      await context.read<GoldProvider>().sellAsset(
        id: widget.asset.id,
        sellPricePerUnit: price,
        sellDate: _sellDate,
        sellNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sell_rounded,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghi Nhận Bán Vàng',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${a.quantity} ${a.unit.abbr}  •  ${a.goldTypeName}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(
                            0.55,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Sell Date picker
            Text(
              'Ngày bán',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.goldPrimary.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.goldPrimary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.goldPrimary,
                    ),
                    const Gap(10),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_sellDate),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: context.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Sell price
            Text(
              'Giá bán / ${a.unit.abbr}',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(6),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập giá bán...',
                suffixText: 'VNĐ',
                filled: true,
                fillColor: AppColors.goldPrimary.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.goldPrimary.withOpacity(0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.goldPrimary.withOpacity(0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.goldPrimary,
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập giá bán';
                final n = double.tryParse(
                  v.replaceAll(',', '').replaceAll('.', ''),
                );
                if (n == null || n <= 0) return 'Giá bán phải lớn hơn 0';
                return null;
              },
            ),
            // Live price hint chip
            if (_suggestedPrice != null) ...[
              const Gap(8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _priceController.text = _suggestedPrice!.round().toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.goldPrimary.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.goldPrimary,
                      ),
                      const Gap(5),
                      Text(
                        'BTMC mua vào: ${_suggestedPrice!.round().toCurrency}/${a.unit.abbr}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '• Nhấn để dùng',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(
                            0.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Gap(16),

            // Note
            Text(
              'Ghi chú (tuỳ chọn)',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(6),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Bán tại tiệm ABC...',
                filled: true,
                fillColor: AppColors.goldPrimary.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.goldPrimary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.goldPrimary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.goldPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const Gap(24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.black,
                      ),
                label: Text(
                  _isSubmitting ? 'Đang lưu...' : 'Xác Nhận Bán',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
