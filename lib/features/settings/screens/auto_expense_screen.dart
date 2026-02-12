import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/bank_notification_model.dart';
import '../../../data/services/auto_expense_service.dart';
import '../../../data/services/bank_notification_parser.dart';
class AutoExpenseScreen extends StatefulWidget {
  const AutoExpenseScreen({super.key});

  @override
  State<AutoExpenseScreen> createState() => _AutoExpenseScreenState();
}

class _AutoExpenseScreenState extends State<AutoExpenseScreen>
    with TickerProviderStateMixin {
  AutoExpenseService? _service;
  bool _isLoading = true;
  bool _isEnabled = false;
  bool _hasPermission = false;
  StreamSubscription? _notificationSub;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _initService();
  }

  Future<void> _initService() async {
    final service = await AutoExpenseService.getInstance();
    final hasPermission = await service.hasPermission();
    if (!mounted) return;
    setState(() {
      _service = service;
      _isEnabled = service.isEnabled;
      _hasPermission = hasPermission;
      _isLoading = false;
    });

    // Listen for new notifications
    _notificationSub = service.notificationStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggleAutoExpense(bool value) async {
    if (value) {
      final result = await _service!.enable();
      if (!mounted) return;
      if (result) {
        setState(() {
          _isEnabled = true;
          _hasPermission = true;
        });
        HapticFeedback.mediumImpact();
        context.showSnackBar('Đã bật ghi chi tiêu tự động! 🎉');
      } else {
        context.showSnackBar(
          'Cần cấp quyền đọc thông báo để sử dụng tính năng này',
          isError: true,
        );
      }
    } else {
      await _service!.disable();
      if (!mounted) return;
      setState(() => _isEnabled = false);
      HapticFeedback.lightImpact();
      context.showSnackBar('Đã tắt ghi chi tiêu tự động');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMainToggleCard(context),
                            const Gap(16),
                            if (!_hasPermission && _isEnabled)
                              _buildPermissionWarning(context),
                            const Gap(16),
                            // Removed HowItWorksCard as per user request
                            _buildSupportedBanksCard(context),
                            const Gap(24),
                            _buildRecentTransactionsSection(context),
                            const Gap(32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFEC4899),
                  const Color(0xFFF472B6),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFFEC4899).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 40),
                child: Row(
                  children: [
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onDoubleTap: () {
                              _service?.generateMockData();
                              setState(() {});
                              context.showSnackBar('Đã tạo dữ liệu giả lập! 🧪');
                            },
                            child: Text(
                              'Ghi chi tiêu tự động',
                              style: context.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const Gap(6),
                          Text(
                            'Từ thông báo ngân hàng',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_mode_rounded,
                        color: Colors.white,
                        size: 28,
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

  Widget _buildMainToggleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isEnabled
                        ? [
                            const Color(0xFFEC4899).withOpacity(0.2),
                            const Color(0xFFF472B6).withOpacity(0.1),
                          ]
                        : [
                            Colors.grey.withOpacity(0.15),
                            Colors.grey.withOpacity(0.08),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: _isEnabled
                      ? const Color(0xFFEC4899)
                      : Colors.grey,
                  size: 26,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEnabled ? 'Đang bật' : 'Đang tắt',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isEnabled
                            ? const Color(0xFFEC4899)
                            : context.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _isEnabled
                          ? 'Tự động ghi nhận giao dịch từ ngân hàng'
                          : 'Bật để tự động ghi chi tiêu từ thông báo',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: _isEnabled,
                  onChanged: _toggleAutoExpense,
                  activeColor: const Color(0xFFEC4899),
                  activeTrackColor: const Color(0xFFEC4899).withOpacity(0.4),
                ),
              ),
            ],
          ),
          if (_isEnabled) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Đang lắng nghe thông báo ngân hàng...',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.wifi_tethering_rounded,
                    color: const Color(0xFF10B981),
                    size: 18,
                  ),
                ],
              ),
            ).animate(
              onPlay: (c) => c.repeat(reverse: true),
            ).shimmer(
              duration: 2000.ms,
              color: const Color(0xFF10B981).withOpacity(0.1),
            ),
          ],
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildApiKeyWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.key_rounded, color: AppColors.warning, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa cấu hình AI',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                const Gap(2),
                Text(
                  'Thêm Gemini API Key trong phần Quét hóa đơn để AI phân loại chính xác hơn',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideX(begin: -0.1);
  }

  Widget _buildPermissionWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
          const Gap(12),
          Expanded(
            child: Text(
              'Cần cấp quyền đọc thông báo trong Cài đặt hệ thống',
              style: context.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _service?.requestPermission(),
            child: const Text('Cấp quyền'),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideX(begin: -0.1);
  }

  Widget _buildHowItWorksCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.2),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const Gap(12),
              Text(
                'Cách hoạt động',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(20),
          _buildStepItem(
            context,
            step: '1',
            icon: Icons.notifications_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Nhận thông báo',
            description: 'App đọc notification từ ứng dụng ngân hàng',
          ),
          _buildStepConnector(context),
          _buildStepItem(
            context,
            step: '2',
            icon: Icons.analytics_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Phân tích nội dung',
            description: 'Trích xuất số tiền, nội dung chuyển khoản',
          ),
          _buildStepConnector(context),
          _buildStepItem(
            context,
            step: '3',
            icon: Icons.psychology_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'AI phân loại',
            description: 'Gemini AI xác định danh mục từ nội dung không dấu',
          ),
          _buildStepConnector(context),
          _buildStepItem(
            context,
            step: '4',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            title: 'Ghi tự động',
            description: 'Tự động thêm vào danh sách chi tiêu/thu nhập',
          ),
        ],
      ),
    ).animate().fade(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildStepItem(
    BuildContext context, {
    required String step,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const Gap(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(2),
              Text(
                description,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: Container(
        width: 2,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.colorScheme.onSurface.withOpacity(0.15),
              context.colorScheme.onSurface.withOpacity(0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportedBanksCard(BuildContext context) {
    // Get unique bank names from parser
    final uniqueBanks = BankNotificationParser.bankPackages.values.toSet().toList();
    uniqueBanks.sort(); // Sort alphabetically

    // Color mapping for known banks
    final Map<String, Color> bankColors = {
      'Vietcombank': const Color(0xFF006A4E),
      'BIDV': const Color(0xFF0051A5),
      'VietinBank': const Color(0xFF003DA5),
      'Techcombank': const Color(0xFFE4002B),
      'MB Bank': const Color(0xFF0066B3),
      'TPBank': const Color(0xFF6E2C8B),
      'ACB': const Color(0xFF005BA1),
      'Sacombank': const Color(0xFF0055A4),
      'VPBank': const Color(0xFF006B3F),
      'VIB': const Color(0xFF0066B3), // VIB Blue
      'Momo': const Color(0xFFAE2070),
      'ZaloPay': const Color(0xFF008FE5),
    };

    // Helper to get color
    Color getBankColor(String name) {
      if (bankColors.containsKey(name)) return bankColors[name]!;
      // Fallback: generate color from hash
      final colors = [
        Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.teal,
        Colors.indigo, Colors.pink, Colors.cyan
      ];
      return colors[name.hashCode.abs() % colors.length];
    }

    final banks = uniqueBanks.map((name) => _BankInfo(name, getBankColor(name))).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.2),
                      const Color(0xFF059669).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const Gap(12),
              Text(
                'Ngân hàng hỗ trợ',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${banks.length} apps',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: banks.map((bank) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bank.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: bank.color.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: bank.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      bank.name,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: bank.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fade(delay: 400.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    final pending = _service?.pendingNotifications ?? [];
    final all = _service?.allNotifications ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending section header
        Row(
          children: [
            Text(
              'Giao dịch chờ duyệt',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (pending.isNotEmpty) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pending.length}',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (all.isNotEmpty)
              TextButton(
                onPressed: () {
                  _service?.clearHistory();
                  setState(() {});
                },
                child: Text(
                  'Xóa tất cả',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
        const Gap(12),
        if (all.isEmpty)
          _buildEmptyState(context)
        else ...[
          // Pending transactions (chờ duyệt)
          if (pending.isNotEmpty) ...[
            ...pending.asMap().entries.map((entry) {
              final index = entry.key;
              final notification = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPendingTransactionCard(context, notification)
                    .animate(delay: Duration(milliseconds: 100 + index * 80))
                    .fade()
                    .slideX(begin: 0.1),
              );
            }),
          ],
          // Accepted transactions (đã duyệt)
          ..._buildAcceptedSection(context),
        ],
      ],
    );
  }

  List<Widget> _buildAcceptedSection(BuildContext context) {
    final accepted = (_service?.allNotifications ?? [])
        .where((n) => n.isAutoRecorded)
        .toList();
    if (accepted.isEmpty) return [];

    return [
      const Gap(20),
      Row(
        children: [
          Text(
            'Đã duyệt',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${accepted.length}',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
      const Gap(12),
      ...accepted.asMap().entries.map((entry) {
        final index = entry.key;
        final notification = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildAcceptedTransactionCard(context, notification)
              .animate(delay: Duration(milliseconds: 100 + index * 60))
              .fade()
              .slideX(begin: 0.05),
        );
      }),
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withOpacity(0.15)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: const Color(0xFFEC4899).withOpacity(0.4),
            ),
          ),
          const Gap(16),
          Text(
            'Chưa có giao dịch nào',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Gap(8),
          Text(
            _isEnabled
                ? 'Giao dịch sẽ tự động xuất hiện khi bạn\nnhận được thông báo từ ngân hàng'
                : 'Bật tính năng để bắt đầu ghi chi tiêu\ntự động từ thông báo ngân hàng',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.35),
              height: 1.4,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).scale(
          begin: const Offset(0.98, 0.98),
          curve: Curves.easeOutCubic,
        );
  }

  /// Card giao dịch chờ duyệt - Detailed Version (from Bottom Sheet)
  Widget _buildPendingTransactionCard(
    BuildContext context,
    BankNotificationModel notification,
  ) {
    final isIncome = notification.isIncoming;
    final amountColor = isIncome ? const Color(0xFF10B981) : AppColors.error;
    final amountPrefix = isIncome ? '+' : '-';
    final category = notification.category;

    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF252540) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon - Title - Amount
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    size: 20,
                    color: category.color,
                  ),
                ),
                const Gap(12),
                // Title & Time column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncome ? 'Nhận tiền' : 'Chuyển tiền',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 10,
                            color: context.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const Gap(4),
                          Text(
                            _formatTime(notification.timestamp),
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: context.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '$amountPrefix${notification.amount.toCompactCurrency}',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: context.colorScheme.onSurface.withOpacity(0.05),
            indent: 16,
            endIndent: 16,
          ),

          // 2. Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bank
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurface.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: 16,
                        color: context.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        notification.bankName,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                
                // Raw Content Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colorScheme.onSurface.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nội dung giao dịch',
                        style: context.textTheme.labelSmall?.copyWith(
                           color: context.colorScheme.onSurface.withOpacity(0.5),
                           fontSize: 10,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        notification.rawContent,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const Gap(12),

                // AI Category Detection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const Gap(8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: 'Loại giao dịch: ',
                                style: TextStyle(
                                  color: context.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              TextSpan(
                                text: category.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Từ chối',
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: () {
                       HapticFeedback.lightImpact();
                       _service?.rejectTransaction(notification.id);
                       setState(() {});
                       context.showSnackBar('Đã từ chối giao dịch');
                    },
                    isPrimary: false,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    label: 'Chấp nhận',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final success =
                          await _service?.acceptTransaction(notification.id) ??
                              false;
                      if (mounted) {
                        setState(() {});
                        context.showSnackBar(
                          success
                              ? 'Đã lưu vào chi tiêu! ✅'
                              : 'Lỗi khi lưu giao dịch',
                          isError: !success,
                        );
                      }
                    },
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary ? Colors.transparent : context.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isPrimary ? color : context.colorScheme.onSurface.withOpacity(0.6)
              ),
              const Gap(8),
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? color : context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card giao dịch đã duyệt - chỉ hiển thị thông tin
  Widget _buildAcceptedTransactionCard(
    BuildContext context,
    BankNotificationModel notification,
  ) {
    final isIncoming = notification.isIncoming;
    final accentColor = isIncoming
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      onDismissed: (_) {
        _service?.removeNotification(notification.id);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification.category.icon,
                color: notification.category.color,
                size: 20,
              ),
            ),
            const Gap(12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.parsedTitle.isNotEmpty
                        ? notification.parsedTitle
                        : notification.rawContent,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(3),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: const Color(0xFF10B981),
                      ),
                      const Gap(4),
                      Text(
                        'Đã duyệt',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        notification.bankName,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: context.colorScheme.onSurface.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(8),
            // Amount
            Text(
              '${isIncoming ? '+' : '-'}${notification.amount.toCurrency}',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _BankInfo {
  final String name;
  final Color color;
  _BankInfo(this.name, this.color);
}
