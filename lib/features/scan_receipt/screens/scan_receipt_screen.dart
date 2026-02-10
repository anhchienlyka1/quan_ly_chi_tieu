import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/services/receipt_scanner_service.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final ExpenseRepository _repository = ExpenseRepository();

  // State
  Uint8List? _imageBytes;
  String? _imageMimeType;
  ReceiptData? _receiptData;
  bool _isScanning = false;
  bool _isSaving = false;
  String? _error;
  ReceiptScannerService? _scanner;

  // Editing controllers (filled after scan)
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initScanner();
  }

  Future<void> _initScanner() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? '';
    setState(() {
      _scanner = ReceiptScannerService(apiKey: apiKey);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 
          (image.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');

      setState(() {
        _imageBytes = bytes;
        _imageMimeType = mimeType;
        _receiptData = null;
        _error = null;
      });

      // Automatically start scanning
      _scanReceipt();
    } catch (e) {
      setState(() {
        _error = 'Không thể chọn ảnh: $e';
      });
    }
  }

  Future<void> _scanReceipt() async {
    if (_imageBytes == null || _scanner == null) return;

    if (!_scanner!.isConfigured) {
      setState(() {
        _error = 'Vui lòng cấu hình Gemini API Key trong Cài đặt trước.';
      });
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final data = await _scanner!.scanReceipt(
        _imageBytes!,
        _imageMimeType ?? 'image/jpeg',
      );

      if (!mounted) return;

      final expense = data.toExpenseModel();
      setState(() {
        _receiptData = data;
        _titleController.text = expense.title;
        _amountController.text = expense.amount.toStringAsFixed(0);
        _noteController.text = expense.note ?? '';
        _selectedCategory = expense.category;
        _selectedDate = expense.date;
        _isScanning = false;
      });

      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      context.showSnackBar('Số tiền không hợp lệ', isError: true);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      context.showSnackBar('Vui lòng nhập tiêu đề', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final expense = ExpenseModel(
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await _repository.addExpense(expense);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.showSnackBar('Đã lưu chi tiêu thành công! 🎉');
      context.pop(true); // Return true to indicate saved
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showSnackBar('Lỗi khi lưu: $e', isError: true);
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
            ),
            const Gap(12),
            const Text('Cấu hình API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập Google Gemini API Key để sử dụng tính năng quét hóa đơn.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const Gap(16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('gemini_api_key', key);
                setState(() {
                  _scanner = ReceiptScannerService(apiKey: key);
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (_imageBytes != null) _scanReceipt();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quét hóa đơn'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showApiKeyDialog,
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: _imageBytes == null
            ? _buildPickerState(context)
            : _isScanning
                ? _buildScanningState(context)
                : _receiptData != null
                    ? _buildResultState(context)
                    : _buildPickerState(context),
      ),
    );
  }

  // ========== PICKER STATE: Choose image source ==========
  Widget _buildPickerState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Gap(32),
            // Hero illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 80,
                color: AppColors.primary.withOpacity(0.6),
              ),
            )
                .animate()
                .fade(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.easeOutCubic,
                ),
            const Gap(32),

            Text(
              'Quét hóa đơn thông minh',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fade().slideY(begin: 0.2),
            const Gap(8),
            Text(
              'Chụp hoặc chọn ảnh hóa đơn, AI sẽ tự động\ntrích xuất thông tin chi tiêu cho bạn',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.5),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fade().slideY(begin: 0.2),

            if (_error != null) ...[
              const Gap(20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Gap(48),

            // Camera button
            _buildSourceButton(
              context,
              icon: Icons.camera_alt_rounded,
              label: 'Chụp ảnh hóa đơn',
              subtitle: 'Sử dụng camera để chụp',
              gradient: AppColors.primaryGradient,
              textColor: Colors.white,
              onTap: () => _pickImage(ImageSource.camera),
            ).animate(delay: 300.ms).fade().slideY(begin: 0.3),
            const Gap(16),

            // Gallery button
            _buildSourceButton(
              context,
              icon: Icons.photo_library_rounded,
              label: 'Chọn từ thư viện',
              subtitle: 'Chọn ảnh có sẵn trong máy',
              gradient: null,
              textColor: context.colorScheme.onSurface,
              onTap: () => _pickImage(ImageSource.gallery),
            ).animate(delay: 400.ms).fade().slideY(begin: 0.3),

            const Gap(32),

            // Tips
            _buildTipsCard(context)
                .animate(delay: 500.ms)
                .fade()
                .slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required LinearGradient? gradient,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (context.isDarkMode
                    ? context.theme.cardTheme.color
                    : Colors.white)
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient != null
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: gradient != null ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gradient != null
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    color: gradient != null ? Colors.white : AppColors.primary,
                    size: 24),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: gradient != null
                            ? Colors.white.withOpacity(0.7)
                            : context.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: gradient != null
                    ? Colors.white.withOpacity(0.7)
                    : context.colorScheme.onSurface.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded,
                  color: AppColors.info, size: 20),
              const Gap(8),
              Text(
                'Mẹo chụp ảnh tốt',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const Gap(12),
          _buildTipItem(context, '📸', 'Chụp ảnh rõ nét, đủ sáng'),
          _buildTipItem(context, '📐', 'Đặt hóa đơn trên nền phẳng'),
          _buildTipItem(context, '✂️', 'Chụp toàn bộ hóa đơn, đặc biệt tổng tiền'),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SCANNING STATE: Animated loading ==========
  Widget _buildScanningState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image preview with scanning animation
          Stack(
            alignment: Alignment.center,
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(
                  _imageBytes!,
                  width: 250,
                  height: 320,
                  fit: BoxFit.cover,
                ),
              ),
              // Scanning overlay
              Container(
                width: 250,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              // Scanning line animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Positioned(
                    top: _pulseController.value * 280 + 20,
                    child: Container(
                      width: 210,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Scanning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 1000.ms,
                  ),
            ],
          ),
          const Gap(36),
          Text(
            'Đang phân tích hóa đơn...',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            'AI đang đọc và trích xuất thông tin',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Gap(24),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== RESULT STATE: Show extracted data ==========
  Widget _buildResultState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview + confidence
            _buildImagePreview(context)
                .animate()
                .fade(duration: 500.ms)
                .slideY(begin: 0.1),
            const Gap(20),

            // Confidence badge
            if (_receiptData != null)
              _buildConfidenceBadge(context)
                  .animate(delay: 100.ms)
                  .fade()
                  .slideX(begin: -0.1),
            const Gap(24),

            // Editable fields
            Text(
              'Thông tin chi tiêu',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate(delay: 200.ms).fade(),
            const Gap(16),

            // Title
            _buildEditField(
              context,
              label: 'Tiêu đề',
              controller: _titleController,
              icon: Icons.receipt_long_rounded,
            ).animate(delay: 250.ms).fade().slideY(begin: 0.1),
            const Gap(14),

            // Amount
            _buildEditField(
              context,
              label: 'Số tiền (₫)',
              controller: _amountController,
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ).animate(delay: 300.ms).fade().slideY(begin: 0.1),
            const Gap(14),

            // Category selector
            Text(
              'Danh mục',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
            ).animate(delay: 350.ms).fade(),
            const Gap(8),
            _buildCategorySelector(context)
                .animate(delay: 400.ms)
                .fade()
                .slideY(begin: 0.1),
            const Gap(14),

            // Date
            _buildDateSelector(context)
                .animate(delay: 450.ms)
                .fade()
                .slideY(begin: 0.1),
            const Gap(14),

            // Note
            _buildEditField(
              context,
              label: 'Ghi chú',
              controller: _noteController,
              icon: Icons.notes_rounded,
              maxLines: 4,
            ).animate(delay: 500.ms).fade().slideY(begin: 0.1),

            // Items breakdown
            if (_receiptData != null && _receiptData!.items.isNotEmpty) ...[
              const Gap(24),
              _buildItemsBreakdown(context)
                  .animate(delay: 550.ms)
                  .fade()
                  .slideY(begin: 0.1),
            ],

            const Gap(32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Quét lại',
                    icon: Icons.refresh_rounded,
                    isOutlined: true,
                    onTap: () {
                      setState(() {
                        _imageBytes = null;
                        _receiptData = null;
                        _error = null;
                      });
                    },
                  ),
                ),
                const Gap(14),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    context,
                    label: _isSaving ? 'Đang lưu...' : 'Lưu chi tiêu',
                    icon: Icons.check_rounded,
                    isOutlined: false,
                    onTap: _isSaving ? null : _saveExpense,
                  ),
                ),
              ],
            ).animate(delay: 600.ms).fade().slideY(begin: 0.2),

            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              _imageBytes!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          // Success badge
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 16),
                  const Gap(6),
                  Text(
                    'Quét thành công',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context) {
    final confidence = (_receiptData!.confidence * 100).toStringAsFixed(0);
    final color = _receiptData!.confidence > 0.7
        ? AppColors.success
        : _receiptData!.confidence > 0.4
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 16),
          const Gap(8),
          Text(
            'Độ chính xác: $confidence%',
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.theme.cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedCategory = category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withOpacity(0.15)
                  : (context.isDarkMode
                      ? context.theme.cardTheme.color
                      : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? category.color : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: category.color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 16, color: category.color),
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

  Widget _buildDateSelector(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? context.theme.cardTheme.color
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 20),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ngày',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Gap(2),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: context.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.theme.cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_bulleted_rounded,
                  color: AppColors.primary, size: 20),
              const Gap(8),
              Text(
                'Chi tiết hóa đơn',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(14),
          ..._receiptData!.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      Text(
                        'x${item.quantity}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const Gap(8),
                    ],
                    Text(
                      item.amount.toCurrency,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _receiptData!.amount.toCurrency,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isOutlined,
    VoidCallback? onTap,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: onTap != null ? AppColors.primaryGradient : null,
        color: onTap == null ? Colors.grey : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onTap != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: FilledButton.icon(
        onPressed: onTap != null
            ? () {
                HapticFeedback.mediumImpact();
                onTap.call();
              }
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
