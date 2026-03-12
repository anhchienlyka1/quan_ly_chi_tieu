import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/widgets/pro_button.dart';
import '../../../data/models/gold_asset_model.dart';
import '../../../data/models/gold_price_model.dart';
import '../../../data/providers/gold_provider.dart';

/// Form screen for adding or editing a gold asset.
class AddGoldScreen extends StatefulWidget {
  final GoldAssetModel? existingAsset; // null = add mode

  const AddGoldScreen({super.key, this.existingAsset});

  @override
  State<AddGoldScreen> createState() => _AddGoldScreenState();
}

class _AddGoldScreenState extends State<AddGoldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _feeController = TextEditingController();
  final _noteController = TextEditingController();

  GoldUnit _selectedUnit = GoldUnit.luong;
  DateTime _purchaseDate = DateTime.now();
  GoldPriceModel? _selectedGoldType;
  bool _isSaving = false;

  bool get isEditMode => widget.existingAsset != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final a = widget.existingAsset!;
      _quantityController.text = a.quantity.toString();
      _priceController.text = a.pricePerUnit.toFormattedNumber;
      _feeController.text = a.fee > 0 ? a.fee.toFormattedNumber : '';
      _noteController.text = a.note ?? '';
      _selectedUnit = a.unit;
      _purchaseDate = a.purchaseDate;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoldProvider>().fetchPrices();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────

  double _parseAmount(String text) {
    // Format vi_VN dùng '.' làm dấu phân cách nghìn (18.600.000)
    // → xóa tất cả dấu '.' và ',' trước khi parse
    final cleaned = text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  // ── Date Picker ────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.goldPrimary,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGoldType == null && !isEditMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn loại vàng')));
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<GoldProvider>();
      final quantity =
          double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0;
      final pricePerUnit = _parseAmount(_priceController.text);
      final fee = _parseAmount(_feeController.text);

      if (isEditMode) {
        final updated = widget.existingAsset!.copyWith(
          purchaseDate: _purchaseDate,
          unit: _selectedUnit,
          quantity: quantity,
          pricePerUnit: pricePerUnit,
          fee: fee,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
        await provider.updateAsset(updated);
      } else {
        final newAsset = GoldAssetModel(
          id: '', // will be set by local data source
          goldTypeName: _selectedGoldType!.shortName,
          goldMenuId: _selectedGoldType!.menuId,
          purchaseDate: _purchaseDate,
          unit: _selectedUnit,
          quantity: quantity,
          pricePerUnit: pricePerUnit,
          fee: fee,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          createdAt: DateTime.now(),
        );
        await provider.addAsset(newAsset);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEditMode) _buildGoldTypePicker(context),
                      if (!isEditMode) const Gap(20),
                      _buildDatePicker(context),
                      const Gap(20),
                      _buildUnitToggle(context),
                      const Gap(20),
                      _buildQuantityField(context),
                      const Gap(20),
                      _buildPriceField(context),
                      const Gap(20),
                      _buildFeeField(context),
                      const Gap(20),
                      _buildNoteField(context),
                      const Gap(28),
                      if (!isEditMode) _buildCurrentPriceHint(context),
                      const Gap(28),
                      ProButton(
                        onPressed: _save,
                        isLoading: _isSaving,
                        label: isEditMode ? 'Cập Nhật' : 'Lưu Thông Tin',
                        icon: Icons.check_rounded,
                        width: double.infinity,
                        backgroundColor: AppColors.goldPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              isEditMode ? '✏️ Chỉnh Sửa Vàng' : '🥇 Thêm Thông Tin Vàng',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildGoldTypePicker(BuildContext context) {
    return Consumer<GoldProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Loại Vàng *'),
            const Gap(8),
            if (provider.isPriceLoading && provider.livePrices.isEmpty)
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.goldPrimary.withOpacity(0.3),
                  ),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ),
              )
            else
              DropdownButtonFormField<GoldPriceModel>(
                initialValue: _selectedGoldType,
                isExpanded: true,
                decoration: InputDecoration(
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.savings_rounded,
                    color: AppColors.goldPrimary,
                  ),
                  hintText: provider.livePrices.isEmpty
                      ? 'Không thể tải dữ liệu loại vàng'
                      : 'Chọn loại vàng...',
                ),
                items: provider.livePrices
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.shortName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedGoldType = val),
                validator: (v) =>
                    v == null && !isEditMode ? 'Vui lòng chọn loại vàng' : null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Ngày Mua *'),
        const Gap(8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.goldPrimary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(14),
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.goldPrimary,
                  size: 20,
                ),
                const Gap(12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_purchaseDate),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Đơn Vị *'),
        const Gap(8),
        Row(
          children: GoldUnit.values.map((unit) {
            final isSelected = _selectedUnit == unit;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedUnit = unit),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: unit == GoldUnit.chi ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.goldGradient : null,
                    color: isSelected
                        ? null
                        : (context.isDarkMode
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.goldPrimary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    unit.label,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.black87
                          : context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(4),
        Text(
          '1 Lượng = 10 Chỉ = 37.5g',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Số Lượng *'),
        const Gap(8),
        TextFormField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: _inputDecoration(
            context,
            hint: 'VD: 2.5',
            suffix: _selectedUnit.abbr,
            prefix: Icons.balance_rounded,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Nhập số lượng';
            final qty = double.tryParse(v.replaceAll(',', '.'));
            if (qty == null || qty <= 0) return 'Số lượng không hợp lệ';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Giá Mua / ${_selectedUnit.abbr} (VNĐ) *'),
        const Gap(8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: _inputDecoration(
            context,
            hint: 'VD: 18.000.000',
            suffix: '₫',
            prefix: Icons.price_change_rounded,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Nhập giá mua';
            final price = _parseAmount(v);
            if (price <= 0) return 'Giá không hợp lệ';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFeeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Phí Mua (VNĐ) — Tuỳ chọn'),
        const Gap(8),
        TextFormField(
          controller: _feeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: _inputDecoration(
            context,
            hint: 'Phí gia công, phí dịch vụ...',
            suffix: '₫',
            prefix: Icons.receipt_long_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Ghi Chú — Tuỳ chọn'),
        const Gap(8),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: _inputDecoration(
            context,
            hint: 'Mua tại tiệm nào, thông tin khác...',
            prefix: Icons.sticky_note_2_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPriceHint(BuildContext context) {
    return Consumer<GoldProvider>(
      builder: (context, provider, _) {
        if (_selectedGoldType == null || provider.livePrices.isEmpty) {
          return const SizedBox.shrink();
        }
        final price = provider.livePrices.firstWhere(
          (p) => p.menuId == _selectedGoldType!.menuId,
          orElse: () => provider.livePrices.first,
        );
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.goldPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.goldPrimary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.goldPrimary,
                size: 18,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá BTMC hiện tại',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Tiệm Mua: ${price.buyPrice.toCurrency}  •  Tiệm Bán: ${price.sellPrice.toCurrency} /chỉ',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.goldDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    IconData? prefix,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.colorScheme.onSurface.withOpacity(0.35),
        fontSize: 14,
      ),
      prefixIcon: prefix != null
          ? Icon(prefix, color: AppColors.goldPrimary, size: 20)
          : null,
      suffixText: suffix,
      suffixStyle: TextStyle(
        color: AppColors.goldPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.goldPrimary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.goldPrimary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.goldPrimary, width: 2),
      ),
      filled: true,
      fillColor: context.isDarkMode
          ? Colors.white.withOpacity(0.04)
          : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }
}
